# Firestore Collections Structure

## 1. Jobs Collection
**Path:** `jobs/{jobId}`

```json
{
  "jobId": "string (auto-generated)",
  "customerId": "string (reference to customers collection)",
  "workerId": "string (reference to workers collection, nullable until assigned)",
  "serviceType": "string (Electrician, Plumber, Carpenter, etc.)",
  "title": "string (e.g., 'House Cleaning')",
  "description": "string (detailed job description)",
  "specialInstructions": "string (optional special notes)",
  "status": "string (pending, assigned, in_progress, completed, cancelled)",
  "priority": "string (low, medium, high, urgent)",
  
  // Location Details
  "location": {
    "address": "string",
    "city": "string",
    "region": "string",
    "latitude": "number",
    "longitude": "number"
  },
  
  // Scheduling
  "scheduledDate": "timestamp",
  "scheduledTime": "string (HH:MM format)",
  "estimatedDuration": "number (in minutes)",
  "actualDuration": "number (in minutes, set after completion)",
  
  // Pricing
  "estimatedPrice": "number",
  "finalPrice": "number (set after completion)",
  "currency": "string (default: USD)",
  
  // Ratings & Reviews
  "rating": "number (1-5, set after completion)",
  "review": "string (customer review)",
  "workerRating": "number (1-5, worker rates customer)",
  "workerReview": "string (worker review)",
  
  // Timestamps
  "createdAt": "timestamp",
  "updatedAt": "timestamp",
  "completedAt": "timestamp (nullable)",
  "cancelledAt": "timestamp (nullable)",
  "cancelReason": "string (nullable)"
}
```

---

## 2. Wallet Collection
**Path:** `wallets/{userId}`

```json
{
  "userId": "string (uid of customer or worker)",
  "userType": "string (customer or worker)",
  "balance": "number (current wallet balance)",
  "totalEarned": "number (for workers, total earnings)",
  "totalSpent": "number (for customers, total spent)",
  "currency": "string (default: USD)",
  
  // Payout Information (for workers)
  "payoutMethod": "string (bank_transfer, upi, card)",
  "payoutDetails": {
    "accountHolder": "string",
    "accountNumber": "string (encrypted)",
    "bankName": "string",
    "ifscCode": "string",
    "upiId": "string (if UPI)"
  },
  
  "nextPayoutDate": "timestamp",
  "lastPayoutDate": "timestamp (nullable)",
  "lastPayoutAmount": "number (nullable)",
  
  "createdAt": "timestamp",
  "updatedAt": "timestamp"
}
```

---

## 3. Transactions Collection
**Path:** `transactions/{transactionId}`

```json
{
  "transactionId": "string (auto-generated)",
  "userId": "string (uid of customer or worker)",
  "userType": "string (customer or worker)",
  "type": "string (credit, debit, refund, payout, service_fee)",
  "amount": "number",
  "currency": "string (default: USD)",
  
  // Transaction Details
  "description": "string (e.g., 'Payment for House Cleaning')",
  "jobId": "string (reference to jobs collection, nullable for non-job transactions)",
  "relatedUserId": "string (the other party in transaction - worker for customer, customer for worker)",
  
  // Payment Method
  "paymentMethod": "string (wallet, card, upi, bank_transfer)",
  "paymentStatus": "string (pending, completed, failed, refunded)",
  "paymentGatewayId": "string (reference to payment gateway, nullable)",
  
  // Breakdown (for job payments)
  "breakdown": {
    "serviceAmount": "number",
    "platformFee": "number",
    "tax": "number",
    "discount": "number (nullable)"
  },
  
  "createdAt": "timestamp",
  "completedAt": "timestamp (nullable)",
  "failureReason": "string (nullable)"
}
```

---

## 4. Ratings Collection
**Path:** `ratings/{ratingId}`

```json
{
  "ratingId": "string (auto-generated)",
  "jobId": "string (reference to jobs collection)",
  "raterId": "string (uid of person giving rating)",
  "raterType": "string (customer or worker)",
  "ratedUserId": "string (uid of person being rated)",
  "ratedUserType": "string (customer or worker)",
  
  // Rating Details
  "rating": "number (1-5)",
  "review": "string (review text)",
  "categories": {
    "professionalism": "number (1-5)",
    "communication": "number (1-5)",
    "timeliness": "number (1-5)",
    "quality": "number (1-5)"
  },
  
  "isAnonymous": "boolean",
  "helpful": "number (count of helpful votes)",
  "unhelpful": "number (count of unhelpful votes)",
  
  "createdAt": "timestamp",
  "updatedAt": "timestamp"
}
```

---

## 5. Reviews Collection (Alternative/Supplementary)
**Path:** `reviews/{reviewId}`

```json
{
  "reviewId": "string (auto-generated)",
  "jobId": "string (reference to jobs collection)",
  "customerId": "string (uid of customer)",
  "workerId": "string (uid of worker)",
  
  // Customer Review of Worker
  "customerRating": "number (1-5)",
  "customerReview": "string",
  "customerReviewDate": "timestamp",
  
  // Worker Review of Customer
  "workerRating": "number (1-5)",
  "workerReview": "string",
  "workerReviewDate": "timestamp",
  
  "createdAt": "timestamp",
  "updatedAt": "timestamp"
}
```

---

## 6. Locations Collection (Reference Data)
**Path:** `locations/{locationId}`

```json
{
  "locationId": "string (auto-generated)",
  "city": "string",
  "region": "string",
  "country": "string",
  "latitude": "number",
  "longitude": "number",
  "serviceTypes": ["array of available service types"],
  "workerCount": "number (count of available workers)",
  "isActive": "boolean",
  "createdAt": "timestamp"
}
```

---

## 7. Disputes Collection
**Path:** `disputes/{disputeId}`

```json
{
  "disputeId": "string (auto-generated)",
  "jobId": "string (reference to jobs collection)",
  "customerId": "string",
  "workerId": "string",
  "initiatedBy": "string (customer or worker)",
  
  "reason": "string (quality_issue, payment_issue, no_show, other)",
  "description": "string (detailed description)",
  "status": "string (open, in_review, resolved, closed)",
  "resolution": "string (nullable, how it was resolved)",
  
  "evidence": ["array of image/document URLs"],
  "messages": ["array of dispute messages"],
  
  "createdAt": "timestamp",
  "resolvedAt": "timestamp (nullable)",
  "updatedAt": "timestamp"
}
```

---

## 8. Notifications Collection
**Path:** `notifications/{notificationId}`

```json
{
  "notificationId": "string (auto-generated)",
  "userId": "string (uid of recipient)",
  "type": "string (job_assigned, job_completed, payment_received, rating_received, etc.)",
  "title": "string",
  "message": "string",
  "data": {
    "jobId": "string (nullable)",
    "relatedUserId": "string (nullable)"
  },
  
  "isRead": "boolean",
  "readAt": "timestamp (nullable)",
  "createdAt": "timestamp"
}
```

---

## Collection Relationships

```
customers/
├── {customerId}
│   └── Jobs (via customerId in jobs collection)
│   └── Wallet (wallets/{customerId})
│   └── Transactions (via userId in transactions collection)
│   └── Ratings (via ratedUserId in ratings collection)

workers/
├── {workerId}
│   └── Jobs (via workerId in jobs collection)
│   └── Wallet (wallets/{workerId})
│   └── Transactions (via userId in transactions collection)
│   └── Ratings (via ratedUserId in ratings collection)

jobs/
├── {jobId}
│   └── Ratings (via jobId in ratings collection)
│   └── Reviews (via jobId in reviews collection)
│   └── Transactions (via jobId in transactions collection)
│   └── Disputes (via jobId in disputes collection)

locations/
├── {locationId}
│   └── Reference data for job locations
```

---

## Firestore Rules (Security)

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Jobs collection
    match /jobs/{jobId} {
      allow read: if request.auth.uid == resource.data.customerId || 
                     request.auth.uid == resource.data.workerId;
      allow create: if request.auth.uid == request.resource.data.customerId;
      allow update: if request.auth.uid == resource.data.customerId || 
                       request.auth.uid == resource.data.workerId;
    }
    
    // Wallets collection
    match /wallets/{userId} {
      allow read, write: if request.auth.uid == userId;
    }
    
    // Transactions collection
    match /transactions/{transactionId} {
      allow read: if request.auth.uid == resource.data.userId || 
                     request.auth.uid == resource.data.relatedUserId;
      allow create: if request.auth.uid == request.resource.data.userId;
    }
    
    // Ratings collection
    match /ratings/{ratingId} {
      allow read: if true;
      allow create: if request.auth.uid == request.resource.data.raterId;
      allow update: if request.auth.uid == resource.data.raterId;
    }
    
    // Notifications collection
    match /notifications/{notificationId} {
      allow read: if request.auth.uid == resource.data.userId;
      allow write: if false; // Only backend can write
    }
  }
}
```

---

## Indexes to Create

1. **jobs collection:**
   - `status, createdAt DESC`
   - `workerId, status`
   - `customerId, status`
   - `city, status, createdAt DESC`

2. **transactions collection:**
   - `userId, createdAt DESC`
   - `jobId, type`

3. **ratings collection:**
   - `ratedUserId, createdAt DESC`
   - `jobId`

4. **notifications collection:**
   - `userId, isRead, createdAt DESC`
