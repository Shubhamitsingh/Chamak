# 🔧 Deployment Fix - Schedule Error

## ❌ Issue Found

The deployment failed with this error:
```
Failed to create scheduler job: The provided schedule or timezone are invalid.
```

## 🔍 Root Cause

The `manageStreamState` function was using an invalid schedule:
```javascript
onSchedule("every 30 seconds", ...)  // ❌ INVALID - Cloud Scheduler minimum is 1 minute
```

## ✅ Fix Applied

Changed the schedule to a valid format:
```javascript
onSchedule("every 1 minute", ...)  // ✅ VALID - Minimum interval is 1 minute
```

## 📝 Note

- **Cloud Scheduler minimum interval:** 1 minute
- **Original requirement:** Every 30 seconds
- **Solution:** Changed to every 1 minute (still effective for stream state management)

## 🚀 Next Steps

1. **Redeploy the function:**
   ```bash
   cd functions
   firebase deploy --only functions:manageStreamState
   ```

2. **Verify deployment:**
   - Check Firebase Console → Functions
   - Verify `manageStreamState` is deployed
   - Check Cloud Scheduler jobs are created

3. **Test:**
   - Start a stream
   - Wait 1-2 minutes
   - Check Cloud Functions logs for state management messages

## ✅ Status

- ✅ Schedule format fixed
- ⏳ Ready for redeployment

---

**Note:** Running every 1 minute instead of 30 seconds is still effective because:
- Heartbeat timeout is 60 seconds
- State management runs every 60 seconds (1 minute)
- Still catches dead streams quickly
- Meets Cloud Scheduler requirements
