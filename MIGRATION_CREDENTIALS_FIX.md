# 🔧 Migration Script - Credentials Fix

## ❌ Error
```
Error: Could not load the default credentials.
```

## ✅ Solution

The script needs Google Cloud credentials. Use one of these methods:

### **Method 1: Use Application Default Credentials (Recommended)**

```bash
cd functions
gcloud auth application-default login
node migrateApprovedHosts.js
```

If `gcloud` is not installed, install it:
- Download: https://cloud.google.com/sdk/docs/install

### **Method 2: Use Firebase Service Account**

1. Go to **Firebase Console** → **Project Settings** → **Service Accounts**
2. Click **Generate New Private Key**
3. Save the JSON file
4. Set environment variable:

**PowerShell:**
```powershell
cd functions
$env:GOOGLE_APPLICATION_CREDENTIALS="C:\path\to\service-account-key.json"
node migrateApprovedHosts.js
```

### **Method 3: Skip Migration (Cloud Function Will Handle It)**

**You don't need to run migration manually!** The Cloud Functions will automatically sync approved hosts when:
- Admin approves a new host
- Admin updates an existing host

**Just test the app** - when admin approves hosts, they'll automatically appear in `approvedHosts` collection.

---

## 🎯 **Recommended: Skip Migration**

Since your Cloud Functions are already deployed and working, you can **skip the migration script**. The functions will automatically sync approved hosts going forward.

**To test:**
1. Admin approves a host (sets `isActive=true`)
2. Check `approvedHosts` collection in Firestore
3. Host should appear automatically!

---

## ✅ **Quick Test**

1. **Deploy Firestore Rules:**
   ```bash
   firebase deploy --only firestore:rules
   ```

2. **Test in App:**
   - Open app
   - Go to Explore tab
   - All approved hosts should appear (from `approvedHosts` collection)

3. **Test Auto-Sync:**
   - Admin approves a new host
   - Check `approvedHosts` collection
   - Host should appear automatically!

---

## 💡 **Note**

The migration script is **optional**. The Cloud Functions will handle syncing automatically. You only need the migration script if you want to migrate existing approved hosts immediately.
