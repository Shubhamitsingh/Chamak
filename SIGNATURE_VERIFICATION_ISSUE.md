# ⚠️ PayPrime Signature Verification Issue

## 🔍 **Problem Identified**

From the Cloud Function logs, signature verification is **FAILING**:

```
❌ Invalid signature - payment verification failed
```

### **Log Analysis:**

**Example 1:**
- Custom Key: `99.0000000080TJmatccAS94SedGMxn`
- Expected: `EC425C9B1D13A4AC70ACEAC6D32461B0F9476E240982C3F78319844CAE0EDBB0`
- Received: `19A24C33777E526B8D1E04DA88E582A88138231D26034EEFCD0C54F4F3862960`
- **Status:** ❌ **MISMATCH**

**Example 2:**
- Custom Key: `99.00000000wwaEaTt7vJaapXYvRhnR`
- Expected: `8F595B246C171776EF4C49F0E3FB6A5460735901A078DBD524C8E641146F0AC9`
- Received: `535EFFC01F0FEF16091B4EF0AA074BC5EE813BA59DB598AD68E6957FA187CFE1`
- **Status:** ❌ **MISMATCH**

---

## 🔎 **Root Cause Analysis**

### **Possible Issues:**

1. **Wrong Secret Key** ⚠️
   - The secret key in Firebase Secrets might not match PayPrime dashboard
   - PayPrime might use different secret for IPN vs API calls

2. **Secret Key Format** ⚠️
   - PayPrime secret keys start with `payprime_` prefix
   - Maybe PayPrime expects the key without prefix for IPN?

3. **Different Secret for IPN** ⚠️
   - Some payment gateways use separate secrets for:
     - API calls (payment initiation)
     - IPN callbacks (payment verification)

4. **Signature Formula** ✅
   - Our formula matches PayPrime API docs: `HMAC_SHA256(amount + identifier, secretKey)`
   - This is correct

---

## 🔧 **Solutions to Try**

### **Solution 1: Verify Secret Key**

Check if the secret key in Firebase Secrets matches PayPrime dashboard:

1. **Check PayPrime Dashboard:**
   - Login to PayPrime dashboard
   - Go to Settings → API Key
   - Verify the **Secret Key** shown there

2. **Check Firebase Secrets:**
   ```bash
   firebase functions:secrets:access PAYPRIME_SECRET_KEY --project chamak-39472
   ```

3. **Compare:**
   - They should match exactly
   - If different, update Firebase Secret

---

### **Solution 2: Check for IPN-Specific Secret**

Some payment gateways have separate secrets for IPN. Check PayPrime dashboard for:

- **IPN Secret Key** (separate from API Secret Key)
- **Webhook Secret**
- **Callback Secret**

If found, use that instead of the API secret key.

---

### **Solution 3: Try Secret Key Without Prefix**

PayPrime secret keys have `payprime_` prefix. Try using the key without prefix:

**Current:** `payprime_yghwthmlapg14vc4agw4t909iq0xw30bc6hpkz5pkavj0t19ph14`  
**Try:** `yghwthmlapg14vc4agw4t909iq0xw30bc6hpkz5pkavj0t19ph14`

---

### **Solution 4: Contact PayPrime Support**

If none of the above work, contact PayPrime support and ask:

1. "What secret key should I use for IPN signature verification?"
2. "Is the IPN secret key different from the API secret key?"
3. "Can you verify the signature formula for IPN callbacks?"

---

## 📝 **Next Steps**

1. ✅ **Added debug logging** to Cloud Function (shows secret key info)
2. ⚠️ **Verify secret key** matches PayPrime dashboard
3. ⚠️ **Check for IPN-specific secret** in PayPrime dashboard
4. ⚠️ **Test with secret key without prefix** (if applicable)
5. ⚠️ **Contact PayPrime support** if issue persists

---

## 🔍 **Debug Information**

After redeploying with debug logging, check logs for:

```
🔑 Secret Key Info:
   Length: XX
   First 10 chars: payprime_y...
   Last 10 chars: ...t19ph14
```

This will help verify:
- Secret key is loaded correctly
- Secret key format matches PayPrime dashboard

---

## ⚠️ **Important Note**

**Signature verification is CRITICAL for security!**

- ❌ **Don't disable signature verification** (security risk)
- ✅ **Fix the secret key** to match PayPrime
- ✅ **Verify signature formula** matches PayPrime docs
- ✅ **Test thoroughly** before production

---

**Status:** 🔴 **CRITICAL ISSUE** - Payments are being rejected due to signature mismatch
