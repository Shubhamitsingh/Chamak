# 🔧 PayPrime Dashboard Setup Guide

## ✅ **Keys Verified**

From your dashboard, I can see:
- **Public Key:** `payprime_5d4fidq343Inn2azi1h3s54lv2gdzpfj362i9fgp55m920wycv14` ✅
- **Secret Key:** `payprime_yghwthmlapg14vc4agw4t909iq0xw30bc6hpkz5pkavj0t19ph14` ✅
- **Mode:** Live Mode (ON) ✅

**These match your code!** ✅

---

## 📋 **NEXT STEP: Set IPN URL**

You need to configure the IPN (Instant Payment Notification) URL so PayPrime can send payment callbacks to your Cloud Function.

### **Where to Find IPN Settings:**

Based on your dashboard navigation, look for:

1. **Option 1: In Settings Section**
   - Click on **"Setting"** in the left sidebar (you're already there)
   - Look for tabs or sections like:
     - **"IPN Settings"**
     - **"Webhook Settings"**
     - **"Callback URL"**
     - **"Notification URL"**
     - **"Payment Settings"**

2. **Option 2: In Payment Links Section**
   - Click **"Payment Links"** in the left sidebar
   - Look for IPN/Callback settings there

3. **Option 3: In API Settings**
   - There might be an **"API Settings"** section
   - IPN URL might be configured there

---

## 🎯 **What to Set:**

Once you find the IPN/Callback URL field, set it to:

```
https://us-central1-chamak-39472.cloudfunctions.net/payprimeIPN
```

**⚠️ IMPORTANT:** 
- This URL will be available AFTER you deploy the Cloud Function
- If you haven't deployed yet, deploy first, then set this URL

---

## 📝 **Step-by-Step Instructions:**

### **Step 1: Deploy Cloud Function First**

```bash
# Navigate to your project
cd "C:\Users\Shubham Singh\Desktop\chamak"

# Set secret key (if not done yet)
firebase functions:secrets:set PAYPRIME_SECRET_KEY
# When prompted, paste: payprime_yghwthmlapg14vc4agw4t909iq0xw30bc6hpkz5pkavj0t19ph14

# Deploy the function
firebase deploy --only functions:payprimeIPN
```

**After deployment, you'll get a URL like:**
```
Function URL (payprimeIPN): https://us-central1-chamak-39472.cloudfunctions.net/payprimeIPN
```

### **Step 2: Find IPN Settings in PayPrime Dashboard**

1. **Look in the "Setting" section** (where you are now)
   - Check all tabs: Profile, Change Password, 2FA Security, Api Key
   - Look for additional tabs or sections below

2. **Check other sections:**
   - **Payment Links** → Settings
   - **Transactions** → Settings
   - **Dashboard** → Settings

3. **Look for fields like:**
   - "IPN URL"
   - "Webhook URL"
   - "Callback URL"
   - "Notification URL"
   - "Return URL"
   - "Success URL"

### **Step 3: Set the IPN URL**

1. **Paste your Cloud Function URL:**
   ```
   https://us-central1-chamak-39472.cloudfunctions.net/payprimeIPN
   ```

2. **Save/Update the settings**

3. **Verify it's saved** (some dashboards show a confirmation)

---

## 🔍 **What to Look For:**

The IPN URL field might look like:

```
┌─────────────────────────────────────────────────────────┐
│ IPN Callback URL                                        │
│ ┌─────────────────────────────────────────────────────┐ │
│ │ https://your-domain.com/payprime-ipn               │ │
│ └─────────────────────────────────────────────────────┘ │
│                                                         │
│ [Save] [Test IPN]                                       │
└─────────────────────────────────────────────────────────┘
```

Or it might be in a different format. Look for any field that accepts a URL.

---

## ⚠️ **If You Can't Find IPN Settings:**

**Option 1: Contact PayPrime Support**
- Click the **"Get Support"** button (top right)
- Ask: "Where do I configure the IPN callback URL?"
- They'll guide you to the right section

**Option 2: Check Documentation**
- Look for "API Documentation" or "Integration Guide"
- Search for "IPN" or "Webhook" in their docs

**Option 3: Check Payment Link Settings**
- If you create payment links, IPN might be set per link
- Check individual payment link settings

---

## ✅ **After Setting IPN URL:**

1. **Test the Connection:**
   - Some dashboards have a "Test IPN" button
   - Use it to verify the connection

2. **Make a Test Payment:**
   - Complete a small test payment
   - Check Cloud Function logs:
     ```bash
     firebase functions:log --only payprimeIPN
     ```
   - Should see: "✅ PayPrime IPN received"

3. **Verify Coins Credited:**
   - Check user's coin balance in app
   - Should increase automatically

---

## 📊 **Current Status:**

| Item | Status |
|------|--------|
| Public Key | ✅ Verified (matches code) |
| Secret Key | ✅ Verified (matches code) |
| Live Mode | ✅ ON |
| Cloud Function | ⚠️ Needs deployment |
| IPN URL | ⚠️ Needs configuration |

---

## 🎯 **Quick Action Items:**

1. ✅ **Keys Verified** - Your keys match the code
2. ⚠️ **Deploy Cloud Function** - Run deployment command
3. ⚠️ **Find IPN Settings** - Look in PayPrime dashboard
4. ⚠️ **Set IPN URL** - Paste Cloud Function URL
5. ⚠️ **Test Payment** - Make test payment and verify

---

## 💡 **Tips:**

- **IPN URL is different from Success/Cancel URLs:**
  - Success URL = Where user goes after payment (your app)
  - Cancel URL = Where user goes if they cancel (your app)
  - IPN URL = Where PayPrime sends payment confirmation (Cloud Function)

- **IPN is server-to-server:**
  - User doesn't see this URL
  - PayPrime calls it automatically after payment
  - Used to verify payment and credit coins

---

**Need Help Finding IPN Settings?**
- Check all tabs in the "Setting" section
- Look in "Payment Links" section
- Contact PayPrime support using "Get Support" button
- Check PayPrime documentation/help section

---

**Once you find the IPN URL field, paste your Cloud Function URL and save!** 🚀
