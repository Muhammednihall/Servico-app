# Earnings Page Real Data Implementation

## What Was Updated

### File: `lib/screens/earnings_payments_screen.dart`

#### 1. **Added Real Data Loading**
- Integrated `WorkerService` to fetch data from Firebase
- Added state variables to store:
  - `_totalBalance` - Current wallet balance
  - `_totalEarned` - Total earnings from all jobs
  - `_nextPayoutDate` - Next scheduled payout date
  - `_transactions` - List of recent transactions
  - `_isLoading` - Loading state

#### 2. **Updated Initialization**
- `initState()` now calls `_loadEarningsData()`
- Fetches worker ID from current user
- Loads wallet and transaction data from Firebase

#### 3. **Real-Time Data Display**

**Total Balance Card:**
- Shows actual wallet balance instead of hardcoded `$1,234.56`
- Displays: `$_totalBalance.toStringAsFixed(2)`

**Payout Details:**
- Next Payout: Shows actual next payout date from wallet
- Total Earned: Shows total earnings from all jobs
- Format: `MM/DD/YYYY`

**Recent Transactions:**
- Displays all transactions from Firebase
- Shows loading spinner while fetching
- Shows "No transactions yet" if empty
- For each transaction displays:
  - Service description
  - Transaction date
  - Amount (+ for credit, - for debit)
  - Transaction type icon

#### 4. **Data Mapping**
Each transaction is mapped to display:
```dart
{
  'service': transaction['description'],
  'date': formatted date from transaction['createdAt'],
  'amount': formatted amount with +/- prefix,
  'isCredit': transaction['type'] == 'credit',
  'icon': add_circle for credit, remove_circle for debit
}
```

## Data Flow

```
Worker Opens Earnings Page
    ↓
initState() → _loadEarningsData()
    ↓
Fetch from WorkerService:
  - getWorkerWallet() → balance, totalEarned, nextPayoutDate
  - getWorkerTransactions() → list of transactions
    ↓
setState() updates UI with real data
    ↓
Display:
  - Total Balance Card
  - Payout Details
  - Recent Transactions List
```

## Firebase Collections Used

1. **wallets/{userId}**
   - balance
   - totalEarned
   - nextPayoutDate

2. **transactions/{transactionId}**
   - userId
   - type (credit/debit)
   - amount
   - description
   - createdAt

## Features

✅ Real-time balance display
✅ Total earnings calculation
✅ Next payout date display
✅ Transaction history with dates
✅ Loading state handling
✅ Empty state message
✅ Proper date formatting
✅ Credit/Debit differentiation

## Testing

1. **New Worker:**
   - Register worker
   - Wallet created with $0.00 balance
   - Earnings page shows $0.00

2. **Add Transactions (Manual in Firebase):**
   - Create transaction documents in `transactions` collection
   - Earnings page should display them

3. **Update Wallet:**
   - Manually update wallet balance in Firebase
   - Refresh page to see updated balance

## Example Transaction Document

```json
{
  "userId": "worker_uid",
  "type": "credit",
  "amount": 50.00,
  "description": "House Cleaning Service",
  "jobId": "job_123",
  "paymentMethod": "wallet",
  "paymentStatus": "completed",
  "createdAt": "2026-01-15T10:30:00Z"
}
```

## Example Wallet Document

```json
{
  "userId": "worker_uid",
  "userType": "worker",
  "balance": 150.00,
  "totalEarned": 500.00,
  "totalSpent": 0.00,
  "currency": "USD",
  "nextPayoutDate": "2026-01-22T00:00:00Z",
  "lastPayoutDate": "2026-01-15T00:00:00Z",
  "lastPayoutAmount": 350.00
}
```

## Next Steps

1. **Create Jobs** - Implement job creation and assignment
2. **Job Completion** - Create transactions when jobs are completed
3. **Payout System** - Implement actual payout processing
4. **Transaction Details** - Add ability to view individual transaction details
5. **Filters** - Add date range and type filters for transactions
