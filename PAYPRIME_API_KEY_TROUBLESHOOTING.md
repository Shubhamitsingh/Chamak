# 🔑 PayPrime API Key Troubleshooting Guide

## ❌ Current Error: "Invalid api key"

### ✅ **Step 1: Verify Field Name**

PayPrime API might use different field names. We've tried:
- ❌ `public_key` (original - got "Invalid api key" error)
- ✅ `api_key` (updated - try this first)

### ✅ **Step 2: Check Your Keys**

Your current keys:
- **Public Key:** `payprime_6uyc03vi7r7xpki2v6mve97h3v8g80d7m0r7w6vb4qgae7k92f14`
- **Secret Key:** `payprime_6kye01824ivicbx7x7sn8ehl65nq8mpgy9ys6tuk6aq1fp8tmt14`

**Verify in PayPrime Dashboard:**
1. Login to https://merchant.payprime.in (or your PayPrime dashboard)
2. Go to **API Settings** or **Developer Settings**
3. Check:
   - ✅ Keys are **activated/enabled**
   - ✅ Keys match exactly (no extra spaces)
   - ✅ Test mode keys vs Live mode keys (you might need separate keys)

### ✅ **Step 3: Test Mode vs Live Mode**

**Current Setting:** `useTestMode = true`

**Test Mode:**
- Endpoint: `/test/payment/initiate`
- Might need **test keys** (different from live keys)
- Check PayPrime dashboard for test API keys

**Live Mode:**
- Endpoint: `/payment/initiate`
- Uses your actual production keys

### ✅ **Step 4: Try Different Field Names**

If `api_key` doesn't work, try these field names (one at a time):

1. **`api_key`** ← Currently trying this
2. **`public_key`** ← Original (didn't work)
3. **`merchant_key`**
4. **`key`**
5. **`merchant_id`** + **`api_key`** (both fields)

### ✅ **Step 5: Check PayPrime API Documentation**

Visit: https://payprime.in/api-docs/

Look for:
- Exact field name for API key
- Test mode requirements
- Key format/prefix requirements

### ✅ **Step 6: Contact PayPrime Support**

If nothing works:
1. Contact PayPrime support
2. Ask for:
   - Correct field name for API key
   - Test mode API keys (if different)
   - API endpoint format
   - Sample request format

---

## 🔧 **Quick Fixes to Try:**

### Fix 1: Change Field Name to `api_key` ✅ (Already Done)
```dart
'api_key': publicKey, // Changed from 'public_key'
```

### Fix 2: Verify Keys in Code
Check `lib/services/payment_gateway_api_service.dart`:
- Line ~30: `publicKey` constant
- Make sure keys match exactly from dashboard

### Fix 3: Check Test Mode Keys
- Login to PayPrime dashboard
- Look for "Test Mode" or "Sandbox" section
- Get test API keys (might be different from live keys)

### Fix 4: Try Live Mode (if test keys don't exist)
```dart
static const bool useTestMode = false; // Try live mode
```

---

## 📋 **What to Check Next:**

1. ✅ Run app and check console logs
2. ✅ Look for: `🔑 Public Key being sent: ...`
3. ✅ Verify key matches dashboard exactly
4. ✅ Check if PayPrime dashboard shows test/live keys separately
5. ✅ Try the updated code with `api_key` field name

---

## 🆘 **Still Not Working?**

1. **Check PayPrime Dashboard:**
   - Are keys activated?
   - Are there separate test/live keys?
   - Is your account approved?

2. **Check API Documentation:**
   - Visit https://payprime.in/api-docs/
   - Find exact field names
   - Check request format examples

3. **Contact Support:**
   - PayPrime support email/phone
   - Ask for API integration help
   - Request test credentials

---

**Last Updated:** After changing field name to `api_key`
