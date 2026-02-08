# 📝 **Manual Creation: Step-by-Step Guide**

## 🎯 **How to Manually Create `approvedHosts` Collection**

Follow these steps to manually create the collection and add approved hosts:

---

## 📋 **Step 1: Open Firestore Console**

1. Go to **Firebase Console**: https://console.firebase.google.com
2. Select your project: **chamak-39472**
3. Click **Firestore Database** in the left sidebar
4. You'll see your collections list

---

## 📋 **Step 2: Find Approved Hosts in `users` Collection**

1. In the collections list, click on **`users`** collection
2. Look for users where:
   - `isHost` = `true` (boolean)
   - `isActive` = `true` (boolean)
3. **Note down the user IDs** (document IDs) of approved hosts
4. **For each approved host, note these fields:**
   - `displayName` or `name`
   - `photoURL`
   - `language`
   - `country`
   - `level`
   - `hostApprovedAt` (timestamp)
   - `approvedBy`
   - `followersCount`
   - `followingCount`
   - `gender`

---

## 📋 **Step 3: Create `approvedHosts` Collection**

1. In Firestore, click **"+ Start collection"** button (top left)
2. **Collection ID:** Type `approvedHosts` (exactly as shown)
3. Click **"Next"**

---

## 📋 **Step 4: Create First Document**

### **4.1: Set Document ID**

1. **Document ID:** Use the **user ID** from `users` collection
   - Example: If user ID is `abc123xyz`, use `abc123xyz` as document ID
   - **Important:** Document ID must match user ID exactly!
2. Click **"Next"**

### **4.2: Add Fields**

Add these fields one by one (click "+ Add field" for each):

| Field Name | Type | Value |
|------------|------|-------|
| `userId` | **string** | Same as document ID |
| `hostName` | **string** | `displayName` or `name` from user (or "Host" if empty) |
| `hostPhotoUrl` | **string** | `photoURL` from user (or "" if empty) |
| `displayName` | **string** | `displayName` or `name` from user (or "Host" if empty) |
| `language` | **string** | `language` from user (or "" if empty) |
| `country` | **string** | `country` from user (or "" if empty) |
| `level` | **number** | `level` from user (or 1 if empty) |
| `approvedAt` | **timestamp** | `hostApprovedAt` from user (or current time) |
| `approvedBy` | **string** | `approvedBy` from user (or "admin") |
| `isActive` | **boolean** | `true` |
| `lastUpdated` | **timestamp** | Click "Set to current time" |
| `followersCount` | **number** | `followersCount` from user (or 0 if empty) |
| `followingCount` | **number** | `followingCount` from user (or 0 if empty) |
| `gender` | **string** | `gender` from user (or "" if empty) |

### **4.3: Example - How to Add Each Field**

**For `userId` field:**
1. Click "+ Add field"
2. Field name: `userId`
3. Type: Select **"string"**
4. Value: Paste the user ID (same as document ID)
5. Click **"Save"**

**For `hostName` field:**
1. Click "+ Add field"
2. Field name: `hostName`
3. Type: Select **"string"**
4. Value: Copy `displayName` or `name` from user document
5. Click **"Save"**

**For `isActive` field:**
1. Click "+ Add field"
2. Field name: `isActive`
3. Type: Select **"boolean"**
4. Value: Select **"true"** (checkbox)
5. Click **"Save"**

**For `lastUpdated` field:**
1. Click "+ Add field"
2. Field name: `lastUpdated`
3. Type: Select **"timestamp"**
4. Value: Click **"Set to current time"** button
5. Click **"Save"**

**For `level` field:**
1. Click "+ Add field"
2. Field name: `level`
3. Type: Select **"number"**
4. Value: Enter the number (e.g., `5`)
5. Click **"Save"**

### **4.4: Save Document**

1. After adding all 14 fields, click **"Save"** button
2. The document will be created in `approvedHosts` collection

---

## 📋 **Step 5: Add More Approved Hosts**

Repeat **Step 4** for each approved host:

1. Click **"+ Add document"** in `approvedHosts` collection
2. Use the user ID as document ID
3. Add all 14 fields
4. Save

---

## 📋 **Step 6: Verify**

1. **Check collection:**
   - `approvedHosts` collection should be visible
   - All approved hosts should be there

2. **Check each document:**
   - Document ID = User ID ✅
   - All 14 fields present ✅
   - `isActive` = `true` ✅
   - `lastUpdated` = Current timestamp ✅

3. **Test in app:**
   - Open your app
   - Go to Home → Explore tab
   - All approved hosts should appear! ✅

---

## 🎯 **Quick Reference: Field Types**

| Type | How to Add |
|------|------------|
| **string** | Select "string", type text |
| **number** | Select "number", enter number |
| **boolean** | Select "boolean", check/uncheck |
| **timestamp** | Select "timestamp", click "Set to current time" |

---

## 💡 **Pro Tips**

1. **Copy-paste user IDs** - To avoid typos
2. **Use same document ID** - Must match user ID exactly
3. **Set `isActive: true`** - For all approved hosts
4. **Use current timestamp** - For `lastUpdated` field
5. **Check empty fields** - Use empty string `""` or `0` if data is missing

---

## ⚠️ **Important Notes**

- ✅ **Document ID = User ID** - This is critical!
- ✅ **All 14 fields required** - Don't skip any
- ✅ **`isActive: true`** - Only for approved hosts
- ✅ **Use exact field names** - Case-sensitive

---

## ✅ **Summary**

1. Open Firestore → `users` collection
2. Find approved hosts (`isHost: true`, `isActive: true`)
3. Create `approvedHosts` collection
4. For each host:
   - Create document with user ID
   - Add all 14 fields
   - Save
5. Verify and test

**That's it!** 🚀
