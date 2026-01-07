# 🔐 PayPrime Payment Gateway Setup Guide

## 📋 **STEP 1: Information Needed from PayPrime**

To complete the integration, I need the following information from your PayPrime account:

### **Required Credentials:**
1. **API Key** - Your PayPrime API key
2. **Secret Key** - Your PayPrime secret key (for webhook signature verification)
3. **Merchant ID** - Your PayPrime merchant ID

### **API Endpoints:**
4. **Payment Initiation URL** - The API endpoint to initiate a payment
   - Example: `https://api.payprime.in/v1/payment/initiate`
5. **Payment Verification URL** - The API endpoint to verify payment status
   - Example: `https://api.payprime.in/v1/payment/verify`

### **API Details:**
6. **Authentication Method** - How PayPrime authenticates requests
   - Is it Bearer token? API key in header? Something else?
7. **Request Format** - What fields are required in the payment initiation request?
   - Order ID format?
   - Required customer fields?
   - Currency codes supported?
8. **Response Format** - What does PayPrime return?
   - Where is the payment URL in the response?
   - What is the field name for transaction ID?
9. **Webhook Details:**
   - What is the webhook signature method?
   - Where is the signature sent? (Header? Body?)
   - What fields are in the webhook payload?
   - What are the status values? (success, failed, pending, etc.)

### **Optional but Helpful:**
10. **Test/Sandbox Credentials** - For testing before going live
11. **PayPrime API Documentation URL** - For reference

---

## 🔧 **STEP 2: Setting Up Firebase Secrets**

Once you provide the credentials, run these commands in your terminal:

```bash
# Navigate to your project root
cd "C:\Users\Shubham Singh\Desktop\chamak"

# Set PayPrime credentials as Firebase secrets
firebase functions:secrets:set PAYPRIME_API_KEY
firebase functions:secrets:set PAYPRIME_SECRET_KEY
firebase functions:secrets:set PAYPRIME_MERCHANT_ID

# Optional: Set custom API URLs if different from defaults
firebase functions:secrets:set PAYPRIME_API_URL
firebase functions:secrets:set PAYPRIME_VERIFY_URL
```

**Note:** When you run these commands, Firebase will prompt you to enter the values. Enter them securely.

---

## 📝 **STEP 3: What I've Already Implemented**

✅ **Backend Functions (Cloud Functions):**
- `initiatePayment` - Creates payment and returns payment URL
- `payprimeWebhook` - Receives and verifies webhooks from PayPrime
- `reconcilePayments` - Scheduled job to check stuck payments

✅ **Security:**
- All API keys stored as Firebase secrets (never in code)
- Authentication required for payment initiation
- Webhook signature verification
- Server-side payment verification

---

## 🎯 **NEXT STEPS**

1. **Provide PayPrime API Details** - Share the information listed above
2. **I'll Update the Code** - Adjust API calls based on PayPrime's actual format
3. **Set Up Secrets** - Configure Firebase secrets with your credentials
4. **Test Integration** - Test with PayPrime sandbox/test mode
5. **Deploy Functions** - Deploy to Firebase
6. **Configure Webhook** - Set webhook URL in PayPrime dashboard

---

## 📚 **PayPrime Dashboard Configuration**

After deployment, you'll need to configure in PayPrime dashboard:

1. **Webhook URL:** 
   ```
   https://us-central1-YOUR-PROJECT-ID.cloudfunctions.net/payprimeWebhook
   ```
   (Replace YOUR-PROJECT-ID with your Firebase project ID)

2. **Webhook Events:** Enable payment status change events

3. **Return URL:** (Optional, not used but may be required)
   ```
   https://chamak.app/payment/return
   ```

---

## ⚠️ **IMPORTANT NOTES**

- **Never share your API keys publicly**
- **Use test credentials first** before going live
- **Webhook URL must be HTTPS** (Firebase provides this automatically)
- **Test webhook delivery** after deployment

---

**Ready to proceed? Please provide the PayPrime API information listed above! 🚀**
