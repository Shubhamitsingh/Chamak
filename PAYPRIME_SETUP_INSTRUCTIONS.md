# 🚀 PayPrime Setup Instructions

## ✅ **CODE UPDATED WITH PAYPRIME API FORMAT**

I've updated all the code to match PayPrime's actual API format based on their documentation: https://payprime.in/api-docs/

---

## 🔑 **STEP 1: Set Up Firebase Secrets**

Run these commands to set your PayPrime credentials:

```bash
cd "C:\Users\Shubham Singh\Desktop\chamak"

# Set PayPrime Public Key (API Key)
firebase functions:secrets:set PAYPRIME_API_KEY
# When prompted, enter: payprime_lsypar3mrsndjkq82qvhtcxglm2echynaqvxige0jijput1cal14

# Set PayPrime Secret Key
firebase functions:secrets:set PAYPRIME_SECRET_KEY
# When prompted, enter: payprime_4dp8c4x31mmp029kmkp7532zmvamufzez67eyercai1b265tsz14
```

**Note:** The secrets will be masked when you type them. This is normal for security.

---

## 📦 **STEP 2: Install Dependencies**

```bash
# Install Flutter dependencies
flutter pub get

# Install Cloud Functions dependencies
cd functions
npm install
cd ..
```

---

## 🚀 **STEP 3: Deploy Cloud Functions**

```bash
firebase deploy --only functions
```

This will deploy:
- `initiatePayment` - Creates payment and returns PayPrime payment URL
- `payprimeWebhook` - Receives webhooks from PayPrime
- `reconcilePayments` - Checks for stuck payments (runs every 10 minutes)

---

## 🔧 **STEP 4: Configure Webhook in PayPrime Dashboard**

1. Log in to your PayPrime merchant dashboard
2. Go to **Settings > API Settings** or **Webhook Configuration**
3. Set the webhook URL to:
   ```
   https://us-central1-YOUR-PROJECT-ID.cloudfunctions.net/payprimeWebhook
   ```
   (Replace `YOUR-PROJECT-ID` with your Firebase project ID)

4. Enable webhook notifications for payment status changes

**To find your Firebase project ID:**
- Check Firebase Console: https://console.firebase.google.com
- Or run: `firebase projects:list`

---

## 🧪 **STEP 5: Test the Integration**

### **Test Mode:**
Your API key starts with `payprime_` (not `test_`), so it's likely a production key. If you have test credentials, use those first.

### **Test Flow:**
1. Open your app
2. Go to Wallet screen
3. Select a recharge package
4. Click "Recharge" button
5. Payment WebView should open
6. Complete test payment
7. Webhook should update payment status
8. Coins should be added to wallet

---

## 📋 **WHAT'S BEEN IMPLEMENTED**

### **✅ Backend (Cloud Functions):**

1. **`initiatePayment` Function:**
   - ✅ Uses PayPrime's actual API format (`application/x-www-form-urlencoded`)
   - ✅ Sends correct parameters: `public_key`, `identifier`, `currency`, `amount`, `details`, `ipn_url`, `success_url`, `cancel_url`, `site_name`, `customer[first_name]`, etc.
   - ✅ Handles test mode (checks if API key starts with `test_`)
   - ✅ Returns `redirect_url` from PayPrime response

2. **`payprimeWebhook` Function:**
   - ✅ Receives PayPrime IPN (Instant Payment Notification)
   - ✅ Verifies signature using PayPrime's method: `HMAC-SHA256(amount + identifier, secret_key)` in UPPERCASE
   - ✅ Updates payment status in Firestore
   - ✅ Adds coins to user wallet on success

3. **`reconcilePayments` Function:**
   - ✅ Runs every 10 minutes
   - ✅ Marks payments older than 24 hours as FAILED (abandoned)
   - ✅ Increments retry count for recent pending payments

### **✅ Frontend (Flutter):**

1. **`PayPrimePaymentService`:**
   - ✅ Calls `initiatePayment` Cloud Function
   - ✅ Error handling with user-friendly messages

2. **`PayPrimePaymentWebViewScreen`:**
   - ✅ Opens PayPrime payment URL in WebView
   - ✅ Real-time Firestore listener for payment status
   - ✅ Auto-closes on payment completion
   - ✅ Shows success/failure messages

---

## 🔒 **SECURITY FEATURES**

✅ **API keys stored as Firebase Secrets** - Never in code  
✅ **Webhook signature verification** - Prevents fraud  
✅ **Authentication required** - Only logged-in users can initiate payments  
✅ **HTTPS only** - All communication encrypted  
✅ **Firestore security rules** - Users can only read their own payments  

---

## 📊 **PAYMENT FLOW**

```
1. User clicks recharge package
   ↓
2. App calls initiatePayment Cloud Function
   ↓
3. Cloud Function creates PENDING payment in Firestore
   ↓
4. Cloud Function calls PayPrime API (form-urlencoded)
   ↓
5. PayPrime returns redirect_url
   ↓
6. App opens redirect_url in WebView
   ↓
7. User completes payment in PayPrime checkout
   ↓
8. PayPrime sends webhook (IPN) to Cloud Function
   ↓
9. Cloud Function verifies signature
   ↓
10. Cloud Function updates payment status to SUCCESS/FAILED
   ↓
11. Firestore listener detects status change
   ↓
12. WebView auto-closes, coins added to wallet
```

---

## ⚠️ **IMPORTANT NOTES**

1. **Test Mode:** If your API key starts with `test_`, it will use test endpoint automatically
2. **Webhook URL:** Must be HTTPS (Firebase provides this)
3. **Signature Verification:** PayPrime uses `HMAC-SHA256(amount + identifier, secret_key)` in UPPERCASE
4. **Identifier:** PayPrime uses `identifier` (not `order_id`) to identify payments
5. **Form Data:** PayPrime requires `application/x-www-form-urlencoded` (not JSON)

---

## 🐛 **TROUBLESHOOTING**

### **Payment initiation fails:**
- Check Firebase Functions logs: `firebase functions:log`
- Verify API keys are set correctly: `firebase functions:secrets:access PAYPRIME_API_KEY`
- Check if using test/production endpoint correctly

### **Webhook not received:**
- Verify webhook URL in PayPrime dashboard
- Check Firebase Functions logs for webhook attempts
- Ensure webhook URL is accessible (HTTPS)

### **Signature verification fails:**
- Check that secret key is correct
- Verify signature calculation: `HMAC-SHA256(amount + identifier, secret_key)` in UPPERCASE
- Check webhook payload in logs

### **Payment stuck in PENDING:**
- Reconciliation job runs every 10 minutes
- Payments older than 24 hours are marked as FAILED
- Check Firestore for payment status updates

---

## 📚 **REFERENCE**

- **PayPrime API Docs:** https://payprime.in/api-docs/
- **Firebase Functions:** https://firebase.google.com/docs/functions
- **Firestore Security Rules:** https://firebase.google.com/docs/firestore/security

---

## ✅ **READY TO TEST!**

1. Set up Firebase secrets (Step 1)
2. Install dependencies (Step 2)
3. Deploy functions (Step 3)
4. Configure webhook in PayPrime dashboard (Step 4)
5. Test payment flow (Step 5)

**Everything is ready! 🚀**
