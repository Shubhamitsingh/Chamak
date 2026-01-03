# 🔑 PayPrime "Invalid API Key" Error - Fix Guide

## ❌ **Current Error:**
```
{"status":"error","message":["Invalid api key"]}
```

## ✅ **What This Means:**
- ✅ Field name is correct (`public_key` is being sent)
- ❌ PayPrime is rejecting the API key itself
- ❌ Key might be wrong, not activated, or test mode needs different keys

---

## 🔧 **Step-by-Step Fix:**

### **Step 1: Login to PayPrime Dashboard**
1. Go to: https://merchant.payprime.in (or your PayPrime merchant dashboard)
2. Login with your account credentials

### **Step 2: Check API Keys Section**
1. Navigate to: **Settings** → **API Keys** (or **Developer** → **API Keys**)
2. Look for:
   - **Public Key** (or **API Key**)
   - **Secret Key**
   - **Test Mode Keys** (might be separate)
   - **Live Mode Keys**

### **Step 3: Verify Your Keys**
**Your Current Keys:**
- Public Key: `payprime_6uyc03vi7r7xpki2v6mve97h3v8g80d7m0r7w6vb4qgae7k92f14`
- Secret Key: `payprime_6kye01824ivicbx7x7sn8ehl65nq8mpgy9ys6tuk6aq1fp8tmt14`

**Check:**
- ✅ Do these keys match EXACTLY in the dashboard? (copy-paste to verify)
- ✅ Are there any extra spaces or characters?
- ✅ Are the keys **activated/enabled**?

### **Step 4: Check Test Mode vs Live Mode**
**Current Setting:** `useTestMode = true` (TEST MODE)

**Important:** Test mode might need **different keys** than live mode!

**Check in Dashboard:**
- Is there a "Test Mode" section with separate keys?
- Are your keys marked as "Test" or "Live"?
- Do you need to generate test keys separately?

### **Step 5: Try These Solutions**

#### **Solution A: Use Test Mode Keys (If Separate)**
If dashboard shows separate test keys:
1. Copy the **Test Public Key** from dashboard
2. Update in code: `lib/services/payment_gateway_api_service.dart`
   ```dart
   static const String publicKey = 'YOUR_TEST_PUBLIC_KEY_HERE';
   ```

#### **Solution B: Try Live Mode**
If test keys don't exist, try live mode:
1. Open: `lib/services/payment_gateway_api_service.dart`
2. Change line 28:
   ```dart
   static const bool useTestMode = false; // Switch to LIVE mode
   ```
3. Make sure you're using **Live keys** (not test keys)

#### **Solution C: Regenerate Keys**
If keys are wrong:
1. In PayPrime dashboard, find "Regenerate API Keys" or "Create New Keys"
2. Generate new keys
3. Copy new keys to your code
4. Make sure to copy **Public Key** and **Secret Key** correctly

#### **Solution D: Activate Keys**
If keys exist but are inactive:
1. In dashboard, find "Activate" or "Enable" button for API keys
2. Activate the keys
3. Wait a few minutes for activation to complete

---

## 📋 **What to Check in PayPrime Dashboard:**

### ✅ **Checklist:**
- [ ] Keys match exactly (no spaces, no typos)
- [ ] Keys are **activated/enabled**
- [ ] Test mode has separate keys (if using test mode)
- [ ] Account is approved/verified
- [ ] API access is enabled for your account
- [ ] Keys are not expired

### 🔍 **Common Issues:**
1. **Keys Not Activated:** Dashboard might show "Inactive" status
2. **Wrong Keys:** Copied wrong keys (test vs live)
3. **Account Not Approved:** Account might need verification
4. **Test Mode Disabled:** Test mode might not be enabled for your account

---

## 🆘 **If Still Not Working:**

### **Contact PayPrime Support:**
1. Email: support@payprime.in (or check their website for support)
2. Ask them:
   - "My API keys are showing as invalid. Can you verify my account status?"
   - "Do I need separate test mode keys?"
   - "How do I activate my API keys?"
   - "Can you check if my account is approved for API access?"

### **Provide Them:**
- Your merchant account email/ID
- The error message: "Invalid api key"
- That you're using test mode endpoint: `/test/payment/initiate`

---

## 🧪 **Quick Test:**

Try switching to **LIVE mode** temporarily to see if it's a test mode issue:

1. Open: `lib/services/payment_gateway_api_service.dart`
2. Line 28: Change to:
   ```dart
   static const bool useTestMode = false; // Try LIVE mode
   ```
3. Make sure you're using **LIVE keys** (not test keys)
4. Run app and test

**Note:** Only do this if you're ready for real payments! Otherwise switch back to test mode.

---

## 📝 **Summary:**

The error "Invalid api key" means:
- ✅ Code is correct (field name is right)
- ❌ API key itself is wrong/not activated
- ❌ Might need test mode keys (separate from live keys)

**Next Steps:**
1. ✅ Check PayPrime dashboard
2. ✅ Verify keys match exactly
3. ✅ Check if keys are activated
4. ✅ Check if test mode needs separate keys
5. ✅ Contact PayPrime support if needed

---

**Last Updated:** After fixing field name to `public_key`
