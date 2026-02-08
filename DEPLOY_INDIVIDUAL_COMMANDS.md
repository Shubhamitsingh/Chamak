# 🔧 Individual Function Deployment Commands

## ✅ **VERIFIED: All Function Names Are Correct**

All function names match exactly with the exports in `functions/index.js`:
- ✅ `reconcilePayments` (line 1299)
- ✅ `sendChatNotification` (line 323)
- ✅ `sendLiveStreamNotification` (line 1911)

---

## 📋 **Commands to Run One by One**

Run these commands **individually** in PowerShell. Wait for each to complete before running the next one.

---

## **Step 1: Navigate to Project Directory**

```powershell
cd "C:\Users\Shubham Singh\Desktop\chamak"
```

---

## **Step 2: Deploy Functions Individually**

### **Function 1: reconcilePayments**

```powershell
firebase deploy --only functions:reconcilePayments
```

**Wait for this to complete before moving to the next one.**

**Expected output:**
```
✔  functions[reconcilePayments(us-central1)] Successful update operation.
```

---

### **Function 2: sendChatNotification**

```powershell
firebase deploy --only functions:sendChatNotification
```

**Wait for this to complete before moving to the next one.**

**Expected output:**
```
✔  functions[sendChatNotification(us-central1)] Successful update operation.
```

---

### **Function 3: sendLiveStreamNotification**

```powershell
firebase deploy --only functions:sendLiveStreamNotification
```

**Wait for this to complete.**

**Expected output:**
```
✔  functions[sendLiveStreamNotification(us-central1)] Successful update operation.
```

---

## **Step 3: Verify Deployment**

After deploying all functions, verify they're deployed:

```powershell
firebase functions:list
```

You should see all three functions listed as active.

---

## 📝 **Notes**

- **Run commands one at a time** - Don't run them all at once
- **Wait for each to complete** - Each deployment takes 1-2 minutes
- **If one fails**, note which one and try again after waiting 5 minutes
- **If all fail**, it's likely a quota issue - wait 10-15 minutes and retry

---

## 🔄 **If Functions Still Fail**

If individual deployments still fail, try:

1. **Wait 10-15 minutes** (quota might reset)
2. **Check Firebase logs:**
   ```powershell
   firebase functions:log
   ```
3. **Try deploying all functions again:**
   ```powershell
   firebase deploy --only functions
   ```
