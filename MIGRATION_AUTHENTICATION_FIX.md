# 🔧 Migration Script - Authentication Fix

## ❌ Error
```
Error: Unable to detect a Project Id in the current environment.
```

## ✅ Solution

The migration script needs Firebase authentication. Use one of these methods:

### **Method 1: Use Firebase CLI (Easiest)**

```bash
cd functions
firebase login
firebase use chamak-39472
node migrateApprovedHosts.js
```

### **Method 2: Set Environment Variable**

**PowerShell:**
```powershell
cd functions
$env:GCLOUD_PROJECT="chamak-39472"
$env:GOOGLE_APPLICATION_CREDENTIALS=""  # Use default credentials
node migrateApprovedHosts.js
```

### **Method 3: Use Application Default Credentials**

```bash
cd functions
gcloud auth application-default login
node migrateApprovedHosts.js
```

---

## 📝 Updated Script

The script now:
1. ✅ Automatically reads project ID from `.firebaserc`
2. ✅ Falls back to environment variable
3. ✅ Uses default project ID `chamak-39472`
4. ✅ Handles composite index errors (filters in code if needed)

---

## 🚀 Quick Fix

**Just run these commands:**

```bash
cd functions
firebase login
firebase use chamak-39472
node migrateApprovedHosts.js
```

This will authenticate you and set the project, then run the migration! ✅
