# 🔔 Firebase Cloud Functions - PayPrime IPN Setup Guide

## ✅ **What's Done:**

I've created a Firebase Cloud Function (`payprimeIPN`) that will:
- ✅ Receive payment callbacks from PayPrime
- ✅ Verify payment signature (security)
- ✅ Add coins to user account automatically
- ✅ Update order status in Firestore
- ✅ Record payment in payments collection

---

## 📋 **Step-by-Step Setup:**

### **Step 1: Set PayPrime Secret Key as Firebase Secret**

The Cloud Function needs your PayPrime secret key. Set it as a Firebase secret:

```bash
# Open terminal in your project root
cd functions

# Set the secret key (replace with your actual secret key)
firebase functions:secrets:set PAYPRIME_SECRET_KEY

# When prompted, paste your secret key:
# payprime_6kye01824ivicbx7x7sn8ehl65nq8mpgy9ys6tuk6aq1fp8tmt14
```

**Or set it directly:**
```bash
echo "payprime_6kye01824ivicbx7x7sn8ehl65nq8mpgy9ys6tuk6aq1fp8tmt14" | firebase functions:secrets:set PAYPRIME_SECRET_KEY
```

---

### **Step 2: Deploy the Cloud Function**

```bash
# Make sure you're in the project root
cd "c:\Users\Shubham Singh\Desktop\chamak"

# Deploy only the PayPrime IPN function
firebase deploy --only functions:payprimeIPN
```

**Or deploy all functions:**
```bash
firebase deploy --only functions
```

---

### **Step 3: Get Your IPN URL**

After deployment, Firebase will show you the function URL. It will look like:

```
https://YOUR_REGION-YOUR_PROJECT.cloudfunctions.net/payprimeIPN
```

**To find it:**
1. Go to [Firebase Console](https://console.firebase.google.com)
2. Select your project
3. Go to **Functions** → **payprimeIPN**
4. Copy the **Trigger URL**

**Or check deployment output:**
```
✔  functions[payprimeIPN(us-central1)] Successful create operation.
Function URL: https://us-central1-YOUR_PROJECT.cloudfunctions.net/payprimeIPN
```

---

### **Step 4: Update IPN URL in Your Code**

Open: `lib/services/payment_gateway_api_service.dart`

Find line ~155 and update:

```dart
'ipn_url': 'https://YOUR_REGION-YOUR_PROJECT.cloudfunctions.net/payprimeIPN',
```

**Replace with your actual Cloud Function URL!**

---

### **Step 5: Update Success and Cancel URLs (Optional)**

You can also update these URLs to deep link back to your app:

```dart
'success_url': 'chamak://payment/success', // Deep link to app
'cancel_url': 'chamak://payment/cancel',   // Deep link to app
```

Or use web URLs:
```dart
'success_url': 'https://yourapp.com/payment/success',
'cancel_url': 'https://yourapp.com/payment/cancel',
```

---

## 🧪 **Testing:**

### **Test the Cloud Function:**

1. **Deploy the function** (Step 2)
2. **Make a test payment** in your app
3. **Check Firebase Functions logs:**
   ```bash
   firebase functions:log --only payprimeIPN
   ```
4. **Check Firestore:**
   - Order status should change to "completed"
   - User's coins should increase
   - Payment should be recorded in `payments` collection

---

## 🔍 **Troubleshooting:**

### **Error: Secret key not configured**
```bash
# Make sure you set the secret:
firebase functions:secrets:set PAYPRIME_SECRET_KEY
```

### **Error: Function not found**
```bash
# Redeploy the function:
firebase deploy --only functions:payprimeIPN
```

### **Check Function Logs:**
```bash
firebase functions:log --only payprimeIPN
```

### **Test Function Manually:**
You can test the function by sending a POST request:

```bash
curl -X POST https://YOUR_REGION-YOUR_PROJECT.cloudfunctions.net/payprimeIPN \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "status=success" \
  -d "identifier=TEST123" \
  -d "signature=TEST_SIG" \
  -d "data={\"amount\":\"99.00\"}"
```

---

## 📝 **What the Function Does:**

1. **Receives POST request** from PayPrime with payment status
2. **Verifies signature** using HMAC SHA256 (security check)
3. **Finds order** in Firestore by identifier
4. **Checks payment status** (must be "success")
5. **Prevents duplicates** (checks if already processed)
6. **Adds coins** to user account in `users` collection
7. **Updates wallet** balance in `wallets` collection
8. **Updates order** status to "completed"
9. **Records payment** in `payments` collection
10. **Records transaction** in user's transactions subcollection

---

## ✅ **Summary:**

1. ✅ Cloud Function created (`payprimeIPN`)
2. ⏳ Set secret key: `firebase functions:secrets:set PAYPRIME_SECRET_KEY`
3. ⏳ Deploy function: `firebase deploy --only functions:payprimeIPN`
4. ⏳ Get function URL from Firebase Console
5. ⏳ Update IPN URL in `payment_gateway_api_service.dart`
6. ⏳ Test with a payment

---

**Next Steps:** Follow the steps above to complete the setup!
