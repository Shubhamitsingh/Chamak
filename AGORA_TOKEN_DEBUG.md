# 🔍 Agora Token Debugging Guide

## Current Status
- ✅ Secondary Certificate toggle is ON in Agora Console
- ✅ Token is being generated successfully
- ❌ Agora is rejecting token as "Invalid"

## Possible Causes

### 1. App Certificate Not Fully Enabled
Even though Secondary Certificate toggle is ON, **App Certificate itself** might need to be enabled separately.

**Check in Agora Console:**
- Look for "App Certificate" toggle/switch (separate from Secondary Certificate toggle)
- It should be **ENABLED** (blue/green)
- If disabled, **enable it** and wait 2-3 minutes

### 2. Certificate Mismatch
We're currently using **Primary Certificate** in Firebase Functions.
If Agora Console is using **Secondary Certificate** (toggle is ON), there might be a mismatch.

**Solution:** Try both certificates:
- **Primary:** `e1c46db9ee1e4e049a1c36943d87fd09` (currently set)
- **Secondary:** `c6347cbecf544627a16e766a9f65045e`

### 3. Token Generation Parameters
Verify token is generated with correct:
- ✅ Channel name: `chamakz`
- ✅ UID: `0`
- ✅ Role: `host` or `audience`
- ✅ App ID: `43bb5e13c835444595c8cf087a0ccaa4`

### 4. Token Usage
Make sure token is used correctly when joining:
- Token is passed to `joinChannel`
- UID matches (0)
- Channel name matches (`chamakz`)

---

## Test Steps

### Step 1: Try Primary Certificate (Current)
```bash
# Already set - test now
```

### Step 2: If Primary doesn't work, try Secondary
```bash
echo "c6347cbecf544627a16e766a9f65045e" | firebase functions:secrets:set AGORA_APP_CERTIFICATE
firebase deploy --only functions:generateAgoraToken
```

### Step 3: Check Agora Console
- Verify App Certificate is **ENABLED** (not just Secondary toggle)
- Check which certificate is actually being used for validation

### Step 4: Generate Temp Token in Console
- Click "Generate Temp Token" button in Agora Console
- Use channel: `chamakz`, UID: `0`
- Test if that token works
- If temp token works, our generated token should work too

---

## Next Action

**Try "Go Live" now** - I've switched to Primary Certificate. If it still fails, we'll try Secondary Certificate next.
























