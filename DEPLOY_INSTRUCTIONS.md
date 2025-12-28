# 🚀 Deploy Agora Token Function - Final Steps

## ✅ What's Already Done

1. ✅ **Secrets Set:**
   - `AGORA_APP_ID` = `43bb5e13c835444595c8cf087a0ccaa4`
   - `AGORA_APP_CERTIFICATE` = `e1c46db9ee1e4e049a1c36943d87fd09` (Primary)

2. ✅ **Code Updated:**
   - Firebase Function created with secret access
   - Flutter service created
   - All hardcoded tokens replaced

## 📋 Final Steps to Deploy

### Step 1: Deploy Firebase Functions

Run this command to deploy the `generateAgoraToken` function:

```bash
firebase deploy --only functions:generateAgoraToken
```

Or deploy all functions:

```bash
firebase deploy --only functions
```

**Expected Output:**
```
✔  functions[generateAgoraToken(us-central1)] Successful create operation.
```

### Step 2: Verify Deployment

Check that the function is deployed:

```bash
firebase functions:list
```

You should see `generateAgoraToken` in the list.

### Step 3: Test the Function

1. **Run your Flutter app:**
   ```bash
   flutter run
   ```

2. **Test scenarios:**
   - Click "Go Live" button → Should generate token and start stream
   - Join a live stream → Should generate token and join as viewer

3. **Check logs:**
   ```bash
   firebase functions:log
   ```
   Look for `generateAgoraToken` calls and check for any errors.

## 🐛 Troubleshooting

### If deployment fails:
- Make sure you're logged in: `firebase login`
- Check Firebase project: `firebase projects:list`
- Verify secrets are set: `firebase functions:secrets:access AGORA_APP_ID`

### If token generation fails:
- Check Firebase Functions logs: `firebase functions:log`
- Verify App Certificate is enabled in Agora Console
- Make sure user is authenticated in the app

## ✅ Success Indicators

You'll know it's working when:
- ✅ "Go Live" button generates token and starts stream
- ✅ Viewers can join streams successfully
- ✅ No hardcoded token errors in console
- ✅ Firebase Functions logs show successful token generation

---

**Ready to deploy?** Run the deploy command above! 🚀
























