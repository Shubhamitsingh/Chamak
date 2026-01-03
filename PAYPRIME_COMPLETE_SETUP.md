# 🎉 PayPrime Payment Gateway - Complete Setup Guide

## ✅ **What's Already Done:**

1. ✅ **API Keys Added** - Your PayPrime keys are in the code
2. ✅ **Service File Updated** - Matches PayPrime API format exactly
3. ✅ **Base URL Configured** - `https://merchant.payprime.in`
4. ✅ **Test/Live Mode** - Currently set to TEST mode
5. ✅ **Request Format** - Using form-urlencoded (as PayPrime requires)
6. ✅ **Signature Verification** - HMAC SHA256 implemented

---

## 📋 **What You Need to Configure:**

### **Step 1: Update IPN URLs** (Important!)

Open: `lib/services/payment_gateway_api_service.dart`

Find these lines (around line 100-105):

```dart
'ipn_url': 'https://your-backend.com/payprime/ipn', // TODO: Replace with your IPN URL
'success_url': 'https://your-app.com/payment/success', // TODO: Replace with your success URL
'cancel_url': 'https://your-app.com/payment/cancel', // TODO: Replace with your cancel URL
```

**Replace with YOUR URLs:**

1. **IPN URL** - Where PayPrime sends payment confirmation
   - Example: `https://your-backend-server.com/api/payprime/ipn`
   - This must be a public URL that PayPrime can POST to
   - You'll need a backend server to receive this

2. **Success URL** - Where user goes after successful payment
   - Example: `https://yourapp.com/payment/success` or `chamak://payment/success`
   - Can be a deep link to your app

3. **Cancel URL** - Where user goes if they cancel payment
   - Example: `https://yourapp.com/payment/cancel` or `chamak://payment/cancel`
   - Can be a deep link to your app

---

### **Step 2: Switch to Live Mode (When Ready)**

In `lib/services/payment_gateway_api_service.dart`, find:

```dart
static const bool useTestMode = true; // Change to false for live payments
```

**For Production:**
```dart
static const bool useTestMode = false; // Live payments
```

**Note:** In test mode, use test keys (with `test_` prefix). In live mode, use your actual keys.

---

## 🔄 **How PayPrime Payment Flow Works:**

### **Step 1: User Clicks Package**
- App calls `createPaymentOrder()`
- Creates order in Firestore
- Calls PayPrime API: `POST https://merchant.payprime.in/test/payment/initiate`
- Sends form data with payment details

### **Step 2: PayPrime Response**
- PayPrime returns `redirect_url`
- App opens this URL in browser
- User completes payment on PayPrime page

### **Step 3: Payment Verification**
- **Option A: IPN (Recommended)**
  - PayPrime sends POST to your `ipn_url`
  - Your backend receives: `status`, `identifier`, `signature`, `data`
  - Backend verifies signature and calls `verifyPaymentFromIPN()`
  - Coins are added automatically

- **Option B: Manual Check**
  - User clicks "I have completed payment" in app
  - App checks order status in Firestore
  - If IPN already processed, coins are added

---

## 🛠️ **Backend Setup (For IPN)**

You need a backend server to receive PayPrime IPN callbacks.

### **Example Backend Endpoint (Node.js/Express):**

```javascript
app.post('/api/payprime/ipn', async (req, res) => {
  const { status, identifier, signature, data } = req.body;
  
  // Verify signature
  const amount = data.amount;
  const customKey = amount + identifier;
  const secret = 'YOUR_SECRET_KEY';
  const expectedSignature = crypto
    .createHmac('sha256', secret)
    .update(customKey)
    .digest('hex')
    .toUpperCase();
  
  if (signature.toUpperCase() !== expectedSignature) {
    return res.status(400).send('Invalid signature');
  }
  
  // Call your Flutter app's verification method
  // Or update Firestore directly
  // Then call your app's API to add coins
  
  res.status(200).send('OK');
});
```

### **Or Use Firebase Cloud Functions:**

Create a Cloud Function to receive IPN:

```javascript
exports.payprimeIPN = functions.https.onRequest(async (req, res) => {
  if (req.method !== 'POST') {
    return res.status(405).send('Method not allowed');
  }
  
  const { status, identifier, signature, data } = req.body;
  
  // Verify signature
  // Update Firestore order
  // Add coins to user account
  
  res.status(200).send('OK');
});
```

---

## 🧪 **Testing Steps:**

### **1. Test Payment Creation:**

1. Run app: `flutter run`
2. Go to Wallet screen
3. Click any coin package
4. Check console logs:
   ```
   📤 Creating payment order with PayPrime API...
   📥 PayPrime API Response Status: 200
   📥 PayPrime API Response Body: {...}
   ```

### **2. Test Payment Flow:**

1. Click package → Should open PayPrime payment page
2. Complete test payment (use test card numbers)
3. After payment, check if coins are added

### **3. Test IPN (If Backend Ready):**

1. Complete payment
2. Check backend logs for IPN callback
3. Verify coins are added to account

---

## 📝 **PayPrime API Details:**

Based on [PayPrime Documentation](https://payprime.in/api-docs/):

### **Request Format:**
- **Method:** POST
- **Content-Type:** `application/x-www-form-urlencoded`
- **URL:** 
  - Test: `https://merchant.payprime.in/test/payment/initiate`
  - Live: `https://merchant.payprime.in/payment/initiate`

### **Required Fields:**
- `public_key` - Your public key
- `identifier` - Unique order identifier (max 20 chars)
- `currency` - Currency code (e.g., "INR")
- `amount` - Payment amount (as decimal string)
- `details` - Payment description
- `ipn_url` - Your IPN callback URL
- `success_url` - Success redirect URL
- `cancel_url` - Cancel redirect URL
- `site_name` - Your site name
- `customer[first_name]` - Customer first name
- `customer[last_name]` - Customer last name
- `customer[email]` - Customer email
- `customer[mobile]` - Customer mobile

### **Response Format:**
```json
{
  "status": "success",
  "message": ["Payment initiated"],
  "redirect_url": "https://example.com/payment/checkout?payment_trx=..."
}
```

### **IPN Callback Format:**
PayPrime sends POST to your `ipn_url` with:
- `status` - Payment status ("success" or "error")
- `identifier` - Your order identifier
- `signature` - HMAC SHA256 signature
- `data` - Payment data (JSON object)

---

## 🔒 **Security Notes:**

1. **Never expose Secret Key** - Keep it in backend only
2. **Always verify signature** - Don't trust IPN without verification
3. **Use HTTPS** - All URLs must be HTTPS
4. **Test thoroughly** - Test in test mode before going live

---

## ✅ **Final Checklist:**

- [x] API keys added
- [x] Base URL configured
- [x] Request format matches PayPrime
- [ ] IPN URL configured (need backend)
- [ ] Success URL configured
- [ ] Cancel URL configured
- [ ] Test payment flow
- [ ] Backend IPN handler ready (optional)
- [ ] Switch to live mode when ready

---

## 🆘 **Troubleshooting:**

### **Issue: "Invalid api key"**
- **Solution:** Check if you're using test keys in test mode
- **Solution:** Ensure public key is correct

### **Issue: "Missing required fields"**
- **Solution:** Check all required fields are sent
- **Solution:** Verify customer information is provided

### **Issue: "No redirect URL received"**
- **Solution:** Check PayPrime response in console logs
- **Solution:** Verify API call was successful

### **Issue: "Coins not adding"**
- **Solution:** Check IPN is being received
- **Solution:** Verify signature verification
- **Solution:** Check Firestore permissions

---

## 🚀 **You're Ready!**

1. **Update IPN URLs** in the service file
2. **Test with a small amount** in test mode
3. **Set up backend** for IPN (optional but recommended)
4. **Switch to live mode** when ready

**Everything else is already configured!** 🎉

---

**Need help? Check the console logs - they show all API requests and responses!**
