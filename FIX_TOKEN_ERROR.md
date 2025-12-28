# 🔧 Fix "Invalid Token" Error

## Problem
Token is being generated successfully, but Agora is rejecting it as "Invalid token".

## Root Cause
The App Certificate in Firebase Functions might not match the one active in Agora Console.

## Solution

### Step 1: Check Which Certificate is Active in Agora Console

1. Go to: https://console.agora.io/
2. Navigate to: **Projects** → Your Project → **App Certificate**
3. Check which certificate is **currently active**:
   - Primary Certificate: `e1c46db9ee1e4e049a1c36943d87fd09`
   - Secondary Certificate: `c6347cbecf544627a16e766a9f65045e`

### Step 2: Update Firebase Functions Secret

**If Secondary Certificate is active**, update the secret:

```bash
echo "c6347cbecf544627a16e766a9f65045e" | firebase functions:secrets:set AGORA_APP_CERTIFICATE
```

**If Primary Certificate is active** (current), verify it's correct:

```bash
firebase functions:secrets:access AGORA_APP_CERTIFICATE
```

Should show: `e1c46db9ee1e4e049a1c36943d87fd09`

### Step 3: Redeploy Function

After updating the secret, redeploy:

```bash
firebase deploy --only functions:generateAgoraToken
```

### Step 4: Verify App Certificate is Enabled

In Agora Console:
- Make sure **App Certificate is ENABLED**
- If disabled, enable it and use the certificate shown

### Step 5: Test Again

Try "Go Live" again after updating.

---

## Alternative: Test Token Generation

If you want to test if token generation is working, check the logs:

```bash
firebase functions:log | Select-String "generateAgoraToken"
```

Look for: `✅ Generated Agora token for channel: chamakz, UID: 0, Role: host`

If you see this, token generation is working - the issue is certificate mismatch.

---

## Quick Fix Commands

**To switch to Secondary Certificate:**
```bash
echo "c6347cbecf544627a16e766a9f65045e" | firebase functions:secrets:set AGORA_APP_CERTIFICATE
firebase deploy --only functions:generateAgoraToken
```

**To verify current certificate:**
```bash
firebase functions:secrets:access AGORA_APP_CERTIFICATE
```
























