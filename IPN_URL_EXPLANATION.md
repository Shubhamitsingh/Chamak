# 🔔 IPN URL - Complete Explanation

## ❓ **What is IPN URL?**

**IPN** = **Instant Payment Notification**

An **IPN URL** is a webhook endpoint (a URL on your server) where PayPrime automatically sends payment status updates **after** a user completes or cancels a payment.

---

## 🎯 **How It Works:**

### **Payment Flow with IPN:**

```
1. User clicks package in app
   ↓
2. App creates payment order with PayPrime
   ↓
3. PayPrime returns redirect_url
   ↓
4. User is redirected to PayPrime payment page
   ↓
5. User completes payment (or cancels)
   ↓
6. PayPrime sends POST request to your IPN URL
   ↓
7. Your server receives payment status
   ↓
8. Your server verifies signature and adds coins
```

---

## 📋 **What PayPrime Sends to Your IPN URL:**

When payment is completed, PayPrime sends a **POST request** to your IPN URL with:

```json
{
  "status": "success",           // Payment status
  "identifier": "ABC123XYZ",      // Your order identifier
  "signature": "HMAC_SHA256...",  // Security signature
  "data": {                       // Payment details
    "amount": "99.00",
    "currency": "INR",
    "payment_transaction_id": "...",
    ...
  }
}
```

---

## 🔧 **Why You Need IPN URL:**

### **Without IPN URL:**
- ❌ You won't know when payment is completed
- ❌ Coins won't be added automatically
- ❌ You have to manually check payment status
- ❌ User might pay but not get coins

### **With IPN URL:**
- ✅ Automatic payment verification
- ✅ Coins added automatically when payment succeeds
- ✅ Secure (signature verification)
- ✅ Reliable (works even if user closes app)

---

## 🌐 **What Should Your IPN URL Be?**

Your IPN URL should be:
- ✅ A **public URL** (PayPrime needs to access it)
- ✅ A **backend server endpoint** (not your Flutter app)
- ✅ **HTTPS** (secure connection)
- ✅ **Always accessible** (24/7)

### **Examples:**

**Good IPN URLs:**
```
https://your-backend-server.com/api/payprime/ipn
https://api.yourapp.com/payment/ipn
https://yourdomain.com/webhook/payprime
```

**Bad IPN URLs:**
```
❌ http://localhost:3000/ipn (not accessible from internet)
❌ chamak://payment/ipn (app deep link - won't work)
❌ file:///path/to/file (not a web URL)
```

---

## 🛠️ **How to Set Up IPN URL:**

### **Option 1: Backend Server (Recommended)**

You need a backend server (Node.js, PHP, Python, etc.) that:

1. **Receives POST request** from PayPrime
2. **Verifies signature** (security check)
3. **Calls your app's verification method** or updates Firestore directly

**Example Backend Endpoint (Node.js/Express):**

```javascript
app.post('/api/payprime/ipn', async (req, res) => {
  const { status, identifier, signature, data } = req.body;
  
  // Verify signature
  const crypto = require('crypto');
  const customKey = data.amount + identifier;
  const secret = 'YOUR_SECRET_KEY';
  const mySignature = crypto
    .createHmac('sha256', secret)
    .update(customKey)
    .digest('hex')
    .toUpperCase();
  
  if (status === 'success' && signature === mySignature) {
    // Payment verified - add coins to user
    // Update Firestore or call your app's method
    // ...
  }
  
  res.status(200).send('OK');
});
```

### **Option 2: Firebase Cloud Functions**

You can use Firebase Cloud Functions as your IPN endpoint:

```javascript
// functions/index.js
const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp();

exports.payprimeIPN = functions.https.onRequest(async (req, res) => {
  if (req.method !== 'POST') {
    return res.status(405).send('Method Not Allowed');
  }
  
  const { status, identifier, signature, data } = req.body;
  
  // Verify signature and process payment
  // ...
  
  res.status(200).send('OK');
});
```

**Your IPN URL would be:**
```
https://YOUR_REGION-YOUR_PROJECT.cloudfunctions.net/payprimeIPN
```

### **Option 3: Third-Party Webhook Service**

Use services like:
- **Zapier** (has webhook triggers)
- **n8n** (self-hosted automation)
- **Make.com** (formerly Integromat)

---

## 📝 **Current Setup in Your Code:**

In `lib/services/payment_gateway_api_service.dart`, line ~154:

```dart
'ipn_url': 'https://your-backend.com/payprime/ipn', // TODO: Replace with your IPN URL
```

**You need to replace this with your actual IPN URL!**

---

## ✅ **What to Do:**

### **Step 1: Choose Your Backend Solution**
- Do you have a backend server? → Use that
- Using Firebase? → Use Cloud Functions
- No backend? → Set up one (Node.js, PHP, Python, etc.)

### **Step 2: Create IPN Endpoint**
- Create a POST endpoint that receives PayPrime callbacks
- Verify signature (security)
- Process payment (add coins, update Firestore)

### **Step 3: Update Code**
Replace the IPN URL in your code:
```dart
'ipn_url': 'https://your-actual-backend.com/api/payprime/ipn',
```

### **Step 4: Test**
- Make a test payment
- Check if your IPN endpoint receives the callback
- Verify coins are added automatically

---

## 🔒 **Security: Signature Verification**

**IMPORTANT:** Always verify the signature PayPrime sends!

```dart
// In your IPN handler
final customKey = data['amount'] + identifier;
final expectedSignature = HMAC_SHA256(customKey, secretKey);

if (signature == expectedSignature) {
  // Payment is legitimate - process it
} else {
  // Invalid signature - reject payment
}
```

---

## 📚 **Other URLs You Need:**

### **Success URL:**
Where user goes **after successful payment**
- Can be app deep link: `chamak://payment/success`
- Or web URL: `https://yourapp.com/success`

### **Cancel URL:**
Where user goes **if they cancel payment**
- Can be app deep link: `chamak://payment/cancel`
- Or web URL: `https://yourapp.com/cancel`

---

## 🆘 **Quick Setup Options:**

### **If You Don't Have Backend Yet:**

1. **Use Firebase Cloud Functions** (easiest if using Firebase)
2. **Use a simple Node.js server** (Heroku, Railway, etc.)
3. **Use a webhook service** (Zapier, Make.com)

---

## 📖 **Summary:**

- **IPN URL** = Webhook endpoint where PayPrime sends payment status
- **Purpose** = Automatically verify payments and add coins
- **Required** = Yes, for automatic payment processing
- **Format** = HTTPS public URL to your backend server
- **Security** = Always verify signature

**Next Step:** Set up your backend IPN endpoint and update the URL in your code!

---

**Need help setting up a backend?** Let me know what technology you prefer (Node.js, PHP, Python, Firebase Functions, etc.) and I can help you create the IPN endpoint!
