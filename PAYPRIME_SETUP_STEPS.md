# 🚀 PayPrime Payment Gateway - Step-by-Step Setup

## ✅ **Step 1: API Keys Added** ✓

Your PayPrime keys have been added to the code:
- ✅ Public Key: `payprime_6uyc03vi7r7xpki2v6mve97h3v8g80d7m0r7w6vb4qgae7k92f14`
- ✅ Secret Key: `payprime_6kye01824ivicbx7x7sn8ehl65nq8mpgy9ys6tuk6aq1fp8tmt14`

---

## 📋 **Step 2: Find Your PayPrime API Information**

You need to find these 3 things from your PayPrime dashboard or documentation:

### **A. API Base URL**
This is the main URL for PayPrime API. Common examples:
- `https://api.payprime.com`
- `https://payprime.com/api`
- `https://api.payprime.in` (if India-specific)

**Where to find it:**
1. Check PayPrime dashboard → API Documentation
2. Look for "Base URL" or "API Endpoint"
3. Check any API examples they provide

### **B. Create Order Endpoint**
This is the API path to create a payment order. Common examples:
- `/api/v1/create-order`
- `/payment/create`
- `/orders`
- `/api/orders/create`

**Where to find it:**
1. Check PayPrime API documentation
2. Look for "Create Payment" or "Create Order" endpoint
3. Usually shown as: `POST /api/v1/create-order`

### **C. Verify Payment Endpoint**
This is the API path to verify/check payment status. Common examples:
- `/api/v1/verify-payment`
- `/payment/verify`
- `/orders/verify`
- `/api/payment/status`

**Where to find it:**
1. Check PayPrime API documentation
2. Look for "Verify Payment" or "Check Status" endpoint
3. Usually shown as: `POST /api/v1/verify-payment`

---

## 🔍 **Step 3: Check PayPrime Dashboard**

1. **Login to PayPrime Dashboard**
2. **Look for these sections:**
   - "API Documentation"
   - "Developer Docs"
   - "Integration Guide"
   - "API Reference"
   - "Settings" → "API Settings"

3. **What to look for:**
   - Base URL
   - API endpoints list
   - Request/Response examples
   - Authentication method (how to send keys)

---

## 📝 **Step 4: Update the Code**

Once you have the API information, I'll help you update:

**File:** `lib/services/payment_gateway_api_service.dart`

**Update these 3 lines:**
```dart
// Line 18: Replace with your PayPrime base URL
static const String baseUrl = 'https://api.payprime.com'; // ← Your URL here

// Line 22: Replace with your create order endpoint
static const String createOrderEndpoint = '/api/v1/create-order'; // ← Your endpoint here

// Line 26: Replace with your verify endpoint
static const String verifyPaymentEndpoint = '/api/v1/verify-payment'; // ← Your endpoint here
```

---

## 🎯 **Step 5: Check API Request Format**

PayPrime might need specific request format. Check their documentation for:

### **Request Body Format:**
- What fields are required?
- Field names (e.g., `amount` vs `total_amount`)
- Currency format
- User information fields

### **Response Format:**
- What fields are returned?
- Payment URL field name (e.g., `payment_url`, `checkout_url`, `redirect_url`)
- Payment ID field name (e.g., `payment_id`, `transaction_id`, `id`)

---

## 📞 **What I Need From You:**

Please provide:

1. **API Base URL** (e.g., `https://api.payprime.com`)
2. **Create Order Endpoint** (e.g., `/api/v1/create-order`)
3. **Verify Payment Endpoint** (e.g., `/api/v1/verify-payment`)
4. **API Documentation Link** (if available)
5. **Request/Response Example** (if you have it)

---

## 🔄 **Alternative: If You Don't Have Documentation**

If you can't find the API documentation, we can:

1. **Test with common endpoints** - I'll set up common patterns
2. **Check console logs** - When you test, the app will show API errors
3. **Contact PayPrime support** - Ask them for API documentation

---

## ⚡ **Quick Test (After Setup)**

Once you provide the API info and I update the code:

1. Run the app: `flutter run`
2. Go to Wallet screen
3. Click any coin package
4. Check console logs for:
   - API request being sent
   - API response received
   - Any errors

---

## 📋 **Checklist:**

- [x] Step 1: API Keys added to code
- [ ] Step 2: Find API Base URL from PayPrime
- [ ] Step 3: Find Create Order Endpoint
- [ ] Step 4: Find Verify Payment Endpoint
- [ ] Step 5: Provide API information to me
- [ ] Step 6: I'll update the code
- [ ] Step 7: Test payment flow

---

## 🆘 **Need Help Finding API Info?**

**Option 1: Check PayPrime Dashboard**
- Login → Look for "API" or "Developer" section
- Check "Settings" → "API Settings"

**Option 2: Contact PayPrime Support**
- Email them asking for:
  - API Base URL
  - Create Payment endpoint
  - Verify Payment endpoint
  - Request/Response examples

**Option 3: Check Email/Onboarding**
- Check emails from PayPrime
- Look for integration guides they sent

---

**Once you provide the API information, I'll update everything and you'll be ready to test! 🚀**
