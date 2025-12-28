# 🔧 Fix "Invalid Token" Error - Certificate Verification

## Current Status ✅
- ✅ Secondary Certificate is set in Firebase: `c6347cbecf544627a16e766a9f65045e`
- ✅ Function deployed successfully
- ✅ Token is being generated (seen in logs)

## ⚠️ Issue: Agora is rejecting the token

## Step-by-Step Fix

### Step 1: Verify App Certificate is ENABLED in Agora Console

1. Go to: https://console.agora.io/
2. Navigate to: **Projects** → **chamakz** → **App Certificate**
3. **IMPORTANT:** Check if **App Certificate is ENABLED**
   - Look for a toggle/switch that says "Enable App Certificate" or "App Certificate Status"
   - It should be **ON/ENABLED** (blue/green)
   - If it's OFF/DISABLED, **ENABLE IT**

### Step 2: Verify Which Certificate is Active

In Agora Console, check:
- **Primary Certificate:** `e1c46db9ee1e4e049a1c36943d87fd09`
- **Secondary Certificate:** `c6347cbecf544627a16e766a9f65045e` (Toggle is ON)

**If Secondary Certificate toggle is ON**, Agora uses Secondary Certificate for validation.
**We're currently using Secondary Certificate** ✅

### Step 3: Try Switching to Primary Certificate

If Secondary doesn't work, try Primary:

```bash
echo "e1c46db9ee1e4e049a1c36943d87fd09" | firebase functions:secrets:set AGORA_APP_CERTIFICATE
firebase deploy --only functions:generateAgoraToken
```

### Step 4: Check App Certificate Status

**In Agora Console:**
- Make sure App Certificate is **ENABLED** (not just Secondary toggle)
- If disabled, **enable it** and save
- Wait a few minutes for changes to propagate

### Step 5: Test Again

After enabling App Certificate:
1. Try "Go Live" again
2. Check Firebase Functions logs: `firebase functions:log`
3. Look for token generation success

---

## Common Issues

### Issue 1: App Certificate Not Enabled
**Symptom:** Invalid token error
**Fix:** Enable App Certificate in Agora Console

### Issue 2: Wrong Certificate
**Symptom:** Invalid token error
**Fix:** Match the certificate in Firebase Functions with the active one in Agora Console

### Issue 3: Certificate Mismatch
**Symptom:** Invalid token error
**Fix:** 
- Check which certificate toggle is ON in Agora Console
- Use that same certificate in Firebase Functions

---

## Quick Test

After enabling App Certificate, test:

1. Click "Go Live" in your app
2. Check logs: `firebase functions:log | Select-String "generateAgoraToken"`
3. Should see: `✅ Generated Agora token for channel: chamakz, UID: 0, Role: host`

If token is generated but still invalid, the issue is App Certificate not enabled or wrong certificate.

---

## Next Steps

1. **Check Agora Console** - Is App Certificate ENABLED?
2. **If disabled** - Enable it and wait 2-3 minutes
3. **Test again** - Try "Go Live"
4. **If still fails** - Try switching to Primary Certificate

Let me know what you find in Agora Console! 🔍
























