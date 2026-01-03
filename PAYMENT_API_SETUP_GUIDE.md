# 💳 Payment Gateway API Setup Guide

## 🎯 Quick Setup Steps

### **Step 1: Install HTTP Package**

Run this command in your terminal:
```bash
flutter pub get
```

The `http` package has already been added to your `pubspec.yaml`.

---

### **Step 2: Configure Your API**

Open the file: `lib/services/payment_gateway_api_service.dart`

Find these lines (around line 15-30) and update with YOUR API details:

```dart
// ========== CONFIGURE YOUR API HERE ==========

/// Your Payment Gateway API Base URL
static const String baseUrl = 'YOUR_API_BASE_URL_HERE';
// Example: 'https://api.yourpaymentgateway.com'
// Example: 'https://payment.example.com/api'

/// API Endpoint to create payment order
static const String createOrderEndpoint = '/api/v1/create-order';
// Change this to match your API endpoint
// Example: '/payment/create' or '/orders/new'

/// API Endpoint to verify payment
static const String verifyPaymentEndpoint = '/api/v1/verify-payment';
// Change this to match your API endpoint
// Example: '/payment/verify' or '/orders/verify'

/// Your API Key or Authorization Token
static const String apiKey = 'YOUR_API_KEY_HERE';
// Put your API key here (keep it secret!)
```

---

### **Step 3: Update API Headers**

In the same file, find the `_headers` getter (around line 35):

```dart
Map<String, String> get _headers => {
  'Content-Type': 'application/json',
  'Accept': 'application/json',
  // Add your API key or authorization header here
  // Uncomment and modify ONE of these based on your API:
  
  // Option 1: Bearer Token
  // 'Authorization': 'Bearer $apiKey',
  
  // Option 2: API Key Header
  // 'X-API-Key': apiKey,
  
  // Option 3: Custom Header
  // 'X-Auth-Token': apiKey,
  
  // Option 4: Basic Auth
  // 'Authorization': 'Basic ${base64Encode(utf8.encode('username:password'))}',
};
```

**Uncomment and use the format your API requires!**

---

### **Step 4: Customize Request Body**

Find the `createPaymentOrder` method (around line 70) and update the request body:

```dart
// Prepare request body for your API
// CUSTOMIZE THIS BASED ON YOUR API REQUIREMENTS
final requestBody = {
  'order_id': orderId,
  'amount': amount,
  'currency': 'INR',
  'user_id': currentUser.uid,
  'user_name': userName ?? '',
  'user_email': userEmail ?? currentUser.email ?? '',
  'user_phone': userPhone ?? '',
  'package_id': packageId,
  'coins': coins,
  'description': 'Purchase $coins coins',
  // Add any other fields your API requires
  // Example: 'callback_url': 'https://yourapp.com/callback',
  // Example: 'return_url': 'https://yourapp.com/return',
};
```

**Change field names to match what your API expects!**

---

### **Step 5: Customize Response Parsing**

Find where the API response is parsed (around line 100):

```dart
// CUSTOMIZE THIS BASED ON YOUR API RESPONSE STRUCTURE
final paymentId = responseData['payment_id'] ?? 
                 responseData['transaction_id'] ?? 
                 responseData['id'] ?? 
                 orderId;

final paymentUrl = responseData['payment_url'] ?? 
                   responseData['redirect_url'] ?? 
                   responseData['checkout_url'];

final paymentToken = responseData['token'] ?? 
                    responseData['payment_token'] ?? 
                    '';
```

**Update field names to match your API response!**

---

### **Step 6: Customize Payment Verification**

Find the `verifyPayment` method (around line 150) and update:

```dart
// CUSTOMIZE THIS BASED ON YOUR API RESPONSE STRUCTURE
final status = responseData['status'] ?? 
              responseData['payment_status'] ?? 
              responseData['state'];

final isSuccess = status == 'success' || 
                 status == 'completed' || 
                 status == 'paid' ||
                 status == 'captured' ||
                 (responseData['success'] == true);
```

**Update to match your API's success status values!**

---

## 📋 API Requirements Checklist

Your API should support:

### **1. Create Order Endpoint**
- **Method:** POST
- **URL:** `{baseUrl}{createOrderEndpoint}`
- **Request Body:** Order details (amount, coins, user info)
- **Response:** Should return `payment_id` and `payment_url` (or similar)

### **2. Verify Payment Endpoint**
- **Method:** POST
- **URL:** `{baseUrl}{verifyPaymentEndpoint}`
- **Request Body:** `order_id`, `payment_id`
- **Response:** Should return payment status (success/failed)

---

## 🔍 Testing Your Setup

### **Test 1: Check API Connection**

1. Open wallet screen
2. Click on any coin package
3. Check console logs for:
   - `📤 Creating payment order with API...`
   - `📥 API Response Status: 200`
   - `📥 API Response Body: {...}`

### **Test 2: Test Payment Flow**

1. Click package → Should call your API
2. If `payment_url` returned → Browser opens
3. Complete payment in browser
4. Click "I have completed payment"
5. App verifies payment → Coins should be added

---

## 🐛 Common Issues & Solutions

### **Issue 1: "Request timeout"**
- **Solution:** Check your API URL is correct
- **Solution:** Check internet connection
- **Solution:** Increase timeout in code (currently 30 seconds)

### **Issue 2: "401 Unauthorized"**
- **Solution:** Check API key is correct
- **Solution:** Check authorization header format
- **Solution:** Verify API key has correct permissions

### **Issue 3: "404 Not Found"**
- **Solution:** Check API endpoint URLs are correct
- **Solution:** Verify base URL doesn't have trailing slash

### **Issue 4: "Field not found in response"**
- **Solution:** Check console logs for actual API response
- **Solution:** Update field names in response parsing code

### **Issue 5: "Coins not adding after payment"**
- **Solution:** Check Firestore permissions
- **Solution:** Verify `verifyPayment` returns success
- **Solution:** Check console logs for errors=flutter

---

## 📝 Example API Request/Response

### **Create Order Request:**
```json
POST /api/v1/create-order
Headers:
  Content-Type: application/json
  Authorization: Bearer YOUR_API_KEY

Body:
{
  "order_id": "abc123",
  "amount": 999,
  "currency": "INR",
  "user_id": "user123",
  "user_name": "John Doe",
  "user_email": "john@example.com",
  "user_phone": "9876543210",
  "package_id": "package_3_13000_999",
  "coins": 13000,
  "description": "Purchase 13000 coins"
}
```

### **Create Order Response (Expected):**
```json
{
  "success": true,
  "payment_id": "pay_xyz789",
  "payment_url": "https://paymentgateway.com/checkout/pay_xyz789",
  "order_id": "abc123",
  "message": "Order created successfully"
}
```

### **Verify Payment Request:**
```json
POST /api/v1/verify-payment
Headers:
  Content-Type: application/json
  Authorization: Bearer YOUR_API_KEY

Body:
{
  "order_id": "abc123",
  "payment_id": "pay_xyz789"
}
```

### **Verify Payment Response (Expected):**
```json
{
  "success": true,
  "status": "completed",
  "payment_id": "pay_xyz789",
  "order_id": "abc123",
  "message": "Payment verified successfully"
}
```

---

## 🔒 Security Best Practices

1. **Never commit API keys to Git**
   - Use environment variables
   - Or use a backend server to handle API calls

2. **Use HTTPS only**
   - Never use HTTP for payment APIs
   - Ensure your API uses SSL certificate

3. **Verify payments server-side**
   - Don't trust client-side verification only
   - Use webhooks if your API supports them

---

## ✅ Final Checklist

Before going live:

- [ ] API base URL configured
- [ ] API endpoints configured
- [ ] API key added (securely)
- [ ] Request body matches your API
- [ ] Response parsing matches your API
- [ ] Payment verification works
- [ ] Coins are adding correctly
- [ ] Error handling tested
- [ ] Tested with real payment (small amount)

---

## 🆘 Need Help?

If you're stuck:

1. **Check console logs** - They show API requests/responses
2. **Test API with Postman** - Verify API works outside app
3. **Check API documentation** - Ensure you're using correct format
4. **Review error messages** - They often tell you what's wrong

---

**Good luck! 🚀**
