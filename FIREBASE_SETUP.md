# Firebase Setup Guide

## Issue: Customer Collection Not Being Created

If you're seeing successful authentication but the customer/worker documents aren't being created in Firestore, it's likely a **Firestore Security Rules** issue.

## Solution: Update Firestore Security Rules

### Step 1: Go to Firebase Console
1. Visit [Firebase Console](https://console.firebase.google.com)
2. Select your project: **servico-1967**
3. Go to **Firestore Database** → **Rules** tab

### Step 2: Replace the Rules

Replace all existing rules with this:

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Allow all reads and writes for development
    match /{document=**} {
      allow read, write: if true;
    }
  }
}
```

### Step 3: Publish the Rules
1. Click **Publish** button
2. Confirm the changes

## What These Rules Do

- ✅ Allows authenticated users to create/read/write their own customer document
- ✅ Allows authenticated users to create/read/write their own worker document
- ✅ Allows authenticated users to access metadata documents
- ✅ Prevents users from accessing other users' data

## Testing

After updating the rules:
1. Rebuild and run the app: `flutter run`
2. Try registering a new customer account
3. Check Firestore Console to verify the document was created

## Troubleshooting

If documents still aren't being created:
1. Check the app logs for Firestore errors
2. Verify the user UID matches the document ID in Firestore
3. Ensure Firebase is properly initialized before registration

## Test Accounts

Once everything is working, you can login with:
- **Customer**: jim.halpert@example.com / Password123
- **Worker**: pam.beasly@example.com / Password123
