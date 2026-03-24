/**
 * Firebase Cloud Functions for Servico App
 * 
 * These functions handle push notifications for:
 * 1. Worker notifications (delay reports, penalties, job requests)
 * 2. Customer notifications (worker status updates, rescue job assignments)
 */

const functions = require('firebase-functions');
const admin = require('firebase-admin');

admin.initializeApp();

const db = admin.firestore();
const messaging = admin.messaging();

// ==================== WORKER NOTIFICATIONS ====================

/**
 * Triggered when a new worker notification is created
 * Sends FCM push notification to the worker's device
 */
exports.sendWorkerNotification = functions.firestore
    .document('worker_notifications/{notificationId}')
    .onCreate(async (snap, context) => {
        const notification = snap.data();
        const workerId = notification.workerId;

        if (!workerId) {
            console.log('No workerId in notification');
            return null;
        }

        try {
            // Get worker's FCM token
            const workerDoc = await db.collection('workers').doc(workerId).get();

            if (!workerDoc.exists) {
                console.log(`Worker ${workerId} not found`);
                return null;
            }

            const workerData = workerDoc.data();
            const fcmToken = workerData.fcmToken;

            if (!fcmToken) {
                console.log(`No FCM token for worker ${workerId}`);
                return null;
            }

            // Prepare the message
            const message = {
                token: fcmToken,
                notification: {
                    title: notification.title || 'Servico Notification',
                    body: notification.message || '',
                },
                data: {
                    type: notification.type || 'general',
                    bookingId: notification.bookingId || '',
                    notificationId: context.params.notificationId,
                    click_action: 'FLUTTER_NOTIFICATION_CLICK',
                },
                android: {
                    priority: 'high',
                    notification: {
                        channelId: 'servico_high_importance',
                        sound: 'default',
                        priority: 'high',
                    },
                },
                apns: {
                    payload: {
                        aps: {
                            sound: 'default',
                            badge: 1,
                        },
                    },
                },
            };

            // Send the notification
            const response = await messaging.send(message);
            console.log(`✅ Worker notification sent: ${response}`);

            // Mark notification as sent
            await snap.ref.update({ isSent: true, sentAt: admin.firestore.FieldValue.serverTimestamp() });

            return response;
        } catch (error) {
            console.error(`❌ Error sending worker notification: ${error}`);

            // If token is invalid, remove it
            if (error.code === 'messaging/invalid-registration-token' ||
                error.code === 'messaging/registration-token-not-registered') {
                await db.collection('workers').doc(workerId).update({ fcmToken: null });
                console.log(`Removed invalid FCM token for worker ${workerId}`);
            }

            return null;
        }
    });

// ==================== CUSTOMER NOTIFICATIONS ====================

/**
 * Triggered when a new customer notification is created
 * Sends FCM push notification to the customer's device
 */
exports.sendCustomerNotification = functions.firestore
    .document('customer_notifications/{notificationId}')
    .onCreate(async (snap, context) => {
        const notification = snap.data();
        const customerId = notification.customerId;

        if (!customerId) {
            console.log('No customerId in notification');
            return null;
        }

        try {
            // Get customer's FCM token
            const customerDoc = await db.collection('customers').doc(customerId).get();

            if (!customerDoc.exists) {
                console.log(`Customer ${customerId} not found`);
                return null;
            }

            const customerData = customerDoc.data();
            const fcmToken = customerData.fcmToken;

            if (!fcmToken) {
                console.log(`No FCM token for customer ${customerId}`);
                return null;
            }

            // Prepare the message
            const message = {
                token: fcmToken,
                notification: {
                    title: notification.title || 'Servico Update',
                    body: notification.body || notification.message || '',
                },
                data: {
                    type: notification.type || 'general',
                    bookingId: notification.bookingId || '',
                    notificationId: context.params.notificationId,
                    click_action: 'FLUTTER_NOTIFICATION_CLICK',
                },
                android: {
                    priority: 'high',
                    notification: {
                        channelId: 'servico_high_importance',
                        sound: 'default',
                        priority: 'high',
                    },
                },
                apns: {
                    payload: {
                        aps: {
                            sound: 'default',
                            badge: 1,
                        },
                    },
                },
            };

            // Send the notification
            const response = await messaging.send(message);
            console.log(`✅ Customer notification sent: ${response}`);

            // Mark notification as sent
            await snap.ref.update({ isSent: true, sentAt: admin.firestore.FieldValue.serverTimestamp() });

            return response;
        } catch (error) {
            console.error(`❌ Error sending customer notification: ${error}`);

            // If token is invalid, remove it
            if (error.code === 'messaging/invalid-registration-token' ||
                error.code === 'messaging/registration-token-not-registered') {
                await db.collection('customers').doc(customerId).update({ fcmToken: null });
                console.log(`Removed invalid FCM token for customer ${customerId}`);
            }

            return null;
        }
    });

// ==================== BOOKING STATUS NOTIFICATIONS ====================

/**
 * Triggered when a booking status changes
 * Sends appropriate notifications to both worker and customer
 */
exports.onBookingStatusChange = functions.firestore
    .document('booking_requests/{bookingId}')
    .onUpdate(async (change, context) => {
        const before = change.before.data();
        const after = change.after.data();
        const bookingId = context.params.bookingId;

        // Check if status changed
        if (before.status === after.status && before.workerStatus === after.workerStatus) {
            return null; // No status change
        }

        const customerId = after.customerId;
        const workerId = after.workerId;
        const workerName = after.workerName || 'Worker';
        const serviceName = after.serviceName || 'Service';

        try {
            // Handle worker status changes (on_the_way, arrived, working)
            if (before.workerStatus !== after.workerStatus) {
                if (after.workerStatus === 'on_the_way' && customerId) {
                    const eta = after.estimatedArrivalMinutes || 15;
                    await db.collection('customer_notifications').add({
                        customerId: customerId,
                        title: `🚗 ${workerName} is on the way!`,
                        body: `Your ${serviceName} worker is heading to your location. ETA: ${eta} minutes.`,
                        type: 'worker_on_the_way',
                        bookingId: bookingId,
                        isRead: false,
                        createdAt: admin.firestore.FieldValue.serverTimestamp(),
                    });
                }

                if (after.workerStatus === 'arrived' && customerId) {
                    await db.collection('customer_notifications').add({
                        customerId: customerId,
                        title: `📍 ${workerName} has arrived!`,
                        body: 'Your worker is at your location. Please let them in.',
                        type: 'worker_arrived',
                        bookingId: bookingId,
                        isRead: false,
                        createdAt: admin.firestore.FieldValue.serverTimestamp(),
                    });
                }
            }

            // Handle booking status changes
            if (before.status !== after.status) {
                // Booking accepted
                if (after.status === 'accepted' && customerId) {
                    await db.collection('customer_notifications').add({
                        customerId: customerId,
                        title: '✅ Booking Confirmed!',
                        body: `${workerName} has accepted your ${serviceName} booking.`,
                        type: 'booking_confirmed',
                        bookingId: bookingId,
                        isRead: false,
                        createdAt: admin.firestore.FieldValue.serverTimestamp(),
                    });
                }

                // Job completed
                if (after.status === 'completed' && customerId) {
                    await db.collection('customer_notifications').add({
                        customerId: customerId,
                        title: '🎉 Job Completed!',
                        body: `Your ${serviceName} has been completed. Please leave a review!`,
                        type: 'job_completed',
                        bookingId: bookingId,
                        isRead: false,
                        createdAt: admin.firestore.FieldValue.serverTimestamp(),
                    });
                }

                // Job cancelled
                if (after.status === 'cancelled') {
                    if (customerId) {
                        await db.collection('customer_notifications').add({
                            customerId: customerId,
                            title: '❌ Booking Cancelled',
                            body: `Your ${serviceName} booking has been cancelled.`,
                            type: 'booking_cancelled',
                            bookingId: bookingId,
                            isRead: false,
                            createdAt: admin.firestore.FieldValue.serverTimestamp(),
                        });
                    }
                }
            }

            // Handle rescue job assignment
            if (after.isRescueJob && !before.isRescueJob && customerId) {
                const discount = after.customerDiscountPercentage || 0;
                const discountAmount = after.customerDiscount || 0;
                const discountText = discount > 0
                    ? ` You'll receive a ${Math.round(discount * 100)}% discount (₹${Math.round(discountAmount)} off)!`
                    : '';

                await db.collection('customer_notifications').add({
                    customerId: customerId,
                    title: '🦸 New Worker Assigned!',
                    body: `Good news! ${workerName} has been assigned to your ${serviceName}.${discountText}`,
                    type: 'rescue_worker_assigned',
                    bookingId: bookingId,
                    isRead: false,
                    createdAt: admin.firestore.FieldValue.serverTimestamp(),
                });
            }

            console.log(`✅ Booking status notifications processed for ${bookingId}`);
            return null;
        } catch (error) {
            console.error(`❌ Error processing booking status change: ${error}`);
            return null;
        }
    });

// ==================== DELAY REPORT NOTIFICATIONS ====================

/**
 * Triggered when a delay is reported
 * Sends urgent notification to the worker
 */
exports.onDelayReported = functions.firestore
    .document('booking_requests/{bookingId}')
    .onUpdate(async (change, context) => {
        const before = change.before.data();
        const after = change.after.data();
        const bookingId = context.params.bookingId;

        // Check if delay was just reported
        if (before.delayReported === true || !after.delayReported) {
            return null;
        }

        const workerId = after.workerId;
        const customerName = after.customerName || 'Customer';

        if (!workerId) {
            return null;
        }

        try {
            // Send urgent notification to worker
            await db.collection('worker_notifications').add({
                workerId: workerId,
                title: '⚠️ Customer Waiting!',
                message: `${customerName} has reported that you're delayed. Please update your status or contact them immediately.`,
                type: 'delay_reported',
                bookingId: bookingId,
                isRead: false,
                createdAt: admin.firestore.FieldValue.serverTimestamp(),
            });

            console.log(`✅ Delay notification sent to worker ${workerId}`);
            return null;
        } catch (error) {
            console.error(`❌ Error sending delay notification: ${error}`);
            return null;
        }
    });

// ==================== NEW BOOKING NOTIFICATIONS ====================

/**
 * Triggered when a new booking request is created
 * Notifies the assigned worker (or potentially all workers in category if broadcast)
 */
exports.onNewBookingRequest = functions.firestore
    .document('booking_requests/{bookingId}')
    .onCreate(async (snap, context) => {
        const booking = snap.data();
        const bookingId = context.params.bookingId;
        const workerId = booking.workerId;
        const customerName = booking.customerName || 'A customer';
        const serviceName = booking.serviceName || 'a service';

        if (!workerId) {
            console.log(`Booking ${bookingId} has no workerId yet (broadcast mode).`);
            // Here you could implement logic to notify all workers in the category
            return null;
        }

        try {
            // Get worker's FCM token
            const workerDoc = await db.collection('workers').doc(workerId).get();
            if (!workerDoc.exists) return null;

            const fcmToken = workerDoc.data().fcmToken;
            if (!fcmToken) return null;

            // Prepare the FCM message
            const message = {
                token: fcmToken,
                notification: {
                    title: '🆕 New Job Request!',
                    body: `${customerName} is requesting ${serviceName}.`,
                },
                data: {
                    type: 'new_job_request',
                    bookingId: bookingId,
                    click_action: 'FLUTTER_NOTIFICATION_CLICK',
                },
                android: {
                    priority: 'high',
                    notification: {
                        channelId: 'servico_high_importance',
                        sound: 'default',
                    },
                },
                apns: {
                    payload: {
                        aps: {
                            sound: 'default',
                            badge: 1,
                        },
                    },
                },
            };

            await messaging.send(message);
            console.log(`✅ New job notification sent to worker ${workerId}`);

            // Also create a notification document in worker_notifications for history
            await db.collection('worker_notifications').add({
                workerId: workerId,
                title: '🆕 New Job Request!',
                message: `${customerName} is requesting ${serviceName}.`,
                type: 'new_job_request',
                bookingId: bookingId,
                isRead: false,
                isSent: true,
                createdAt: admin.firestore.FieldValue.serverTimestamp(),
            });

            return null;
        } catch (error) {
            console.error(`❌ Error sending new booking notification: ${error}`);
            return null;
        }
    });

// ==================== BROADCAST NOTIFICATIONS ====================

/**
 * Triggered when a new broadcast notification is created
 * Sends FCM push notification to a topic (all, workers, or customers)
 */
exports.sendBroadcastNotification = functions.firestore
    .document('broadcast_notifications/{notificationId}')
    .onCreate(async (snap, context) => {
        const broadcast = snap.data();
        const topic = broadcast.targetTopic || 'all';

        try {
            const message = {
                topic: topic,
                notification: {
                    title: broadcast.title || 'Servico Announcement',
                    body: broadcast.body || '',
                },
                data: {
                    type: 'broadcast',
                    notificationId: context.params.notificationId,
                    click_action: 'FLUTTER_NOTIFICATION_CLICK',
                },
                android: {
                    priority: 'high',
                    notification: {
                        channelId: 'servico_high_importance',
                        sound: 'default',
                    },
                },
                apns: {
                    payload: {
                        aps: {
                            sound: 'default',
                            badge: 1,
                        },
                    },
                },
            };

            // Add image if available
            if (broadcast.imageUrl) {
                message.notification.imageUrl = broadcast.imageUrl;
            }

            const response = await messaging.send(message);
            console.log(`✅ Broadcast sent to topic ${topic}: ${response}`);

            // Mark as sent
            await snap.ref.update({
                isSent: true,
                sentAt: admin.firestore.FieldValue.serverTimestamp(),
            });

            return response;
        } catch (error) {
            console.error(`❌ Error sending broadcast: ${error}`);
            return null;
        }
    });
