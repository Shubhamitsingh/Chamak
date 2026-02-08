# 📝 **Manual Migration Guide: Adding Approved Hosts to `approvedHosts` Collection**

## 🎯 **Purpose**

This guide shows you how to manually add existing approved hosts (with `isActive: true`) from the `users` collection to the new `approvedHosts` collection in Firestore Console.

---

## 📋 **Step-by-Step Instructions**

### **Step 1: Open Firestore Console**

1. Go to **Firebase Console**: https://console.firebase.google.com
2. Select your project: **chamak-39472**
3. Click on **Firestore Database** in the left sidebar

---

### **Step 2: Find Approved Hosts in `users` Collection**

1. In Firestore, you'll see your collections
2. Click on the **`users`** collection
3. Look for users where:
   - `isHost` = `true`
   - `isActive` = `true`

**Tip:** You can use the filter/search in Firestore Console to find these users.

---

### **Step 3: Create `approvedHosts` Collection (if it doesn't exist)**

1. Click **"Start collection"** (if `approvedHosts` doesn't exist)
2. Collection ID: **`approvedHosts`**
3. Click **"Next"**

**OR** if collection already exists, skip to Step 4.

---

### **Step 4: Add Each Approved Host**

For each approved host in the `users` collection:

#### **4.1: Create New Document**

1. Click **"Add document"** in `approvedHosts` collection
2. **Document ID:** Use the **same user ID** from `users` collection
   - Example: If user ID is `abc123xyz`, use `abc123xyz` as document ID
3. Click **"Next"**

#### **4.2: Add Fields**

Add the following fields one by one:

| Field Name | Type | Value (from `users` collection) |
|------------|------|--------------------------------|
| `userId` | **string** | Same as document ID |
| `hostName` | **string** | `displayName` or `name` from user (or "Host" if empty) |
| `hostPhotoUrl` | **string** | `photoURL` from user (or "" if empty) |
| `displayName` | **string** | `displayName` or `name` from user (or "Host" if empty) |
| `language` | **string** | `language` from user (or "" if empty) |
| `country` | **string** | `country` from user (or "" if empty) |
| `level` | **number** | `level` from user (or `1` if empty) |
| `approvedAt` | **timestamp** | `hostApprovedAt` from user (or current time) |
| `approvedBy` | **string** | `approvedBy` from user (or "admin") |
| `isActive` | **boolean** | `true` |
| `lastUpdated` | **timestamp** | Current timestamp (click "Set to current time") |
| `followersCount` | **number** | `followersCount` from user (or `0` if empty) |
| `followingCount` | **number** | `followingCount` from user (or `0` if empty) |
| `gender` | **string** | `gender` from user (or "" if empty) |

#### **4.3: Example Field Values**

**From `users` collection:**
```
Document ID: abc123xyz
displayName: "John Doe"
photoURL: "https://example.com/photo.jpg"
language: "English"
country: "USA"
level: 5
hostApprovedAt: [timestamp]
approvedBy: "admin"
followersCount: 100
followingCount: 50
gender: "male"
```

**To `approvedHosts` collection:**
```
Document ID: abc123xyz
userId: "abc123xyz"
hostName: "John Doe"
hostPhotoUrl: "https://example.com/photo.jpg"
displayName: "John Doe"
language: "English"
country: "USA"
level: 5
approvedAt: [same timestamp from hostApprovedAt]
approvedBy: "admin"
isActive: true
lastUpdated: [current timestamp]
followersCount: 100
followingCount: 50
gender: "male"
```

#### **4.4: Save Document**

1. After adding all fields, click **"Save"**
2. Repeat for each approved host

---

## 🔄 **Quick Copy-Paste Method (Faster)**

### **Option A: Export/Import (Recommended for Many Hosts)**

1. **Export `users` collection:**
   - In Firestore Console, use the **Export** feature
   - Or use Firebase CLI: `firebase firestore:export`

2. **Filter approved hosts** (in Excel/Google Sheets):
   - Filter: `isHost = true` AND `isActive = true`

3. **Create documents** in `approvedHosts` with the structure above

### **Option B: Use Firestore Console Bulk Import**

1. Prepare a JSON file with all approved hosts
2. Use Firestore Console import feature (if available)
3. Or use Firebase CLI import

---

## ✅ **Verification Checklist**

After adding hosts, verify:

- [ ] All approved hosts (`isHost: true`, `isActive: true`) are in `approvedHosts`
- [ ] Each document ID matches the user ID
- [ ] `isActive` field is set to `true` for all documents
- [ ] All required fields are present (see table above)
- [ ] `lastUpdated` timestamp is recent

---

## 🧪 **Test in App**

1. **Open your app**
2. **Go to Home → Explore tab**
3. **Check if all approved hosts appear in the grid**

If hosts appear, migration is successful! ✅

---

## 📊 **Field Mapping Reference**

| `users` Collection Field | `approvedHosts` Collection Field | Notes |
|-------------------------|--------------------------------|-------|
| `[document ID]` | `userId` | Same value |
| `displayName` or `name` | `hostName` | Use `displayName` first, fallback to `name`, or "Host" |
| `photoURL` | `hostPhotoUrl` | Use empty string if null |
| `displayName` or `name` | `displayName` | Same as `hostName` |
| `language` | `language` | Use empty string if null |
| `country` | `country` | Use empty string if null |
| `level` | `level` | Use `1` if null |
| `hostApprovedAt` | `approvedAt` | Use current timestamp if null |
| `approvedBy` | `approvedBy` | Use "admin" if null |
| `[always true]` | `isActive` | Always set to `true` |
| `[current time]` | `lastUpdated` | Set to current timestamp |
| `followersCount` | `followersCount` | Use `0` if null |
| `followingCount` | `followingCount` | Use `0` if null |
| `gender` | `gender` | Use empty string if null |

---

## ⚠️ **Important Notes**

1. **Document ID must match user ID** - This is critical for the sync to work correctly
2. **Set `isActive: true`** - Only add hosts that are approved
3. **Use current timestamp for `lastUpdated`** - This helps track when data was migrated
4. **Don't skip fields** - All fields should be present (use empty values if data is missing)

---

## 🚀 **After Migration**

Once you've added all approved hosts:

1. ✅ **Test the app** - Check if hosts appear in Explore tab
2. ✅ **Future hosts** - The Cloud Functions will automatically add new approved hosts
3. ✅ **Updates** - The Cloud Functions will automatically keep data in sync

---

## 💡 **Pro Tip**

If you have many hosts (10+), consider:
- Using the migration script (if you have authentication set up)
- Or doing it in batches (5-10 hosts at a time)

---

## ❓ **Troubleshooting**

**Q: Hosts not showing in app?**
- Check if `isActive: true` in `approvedHosts`
- Check if document ID matches user ID
- Check if all required fields are present

**Q: Can I skip some fields?**
- No, all fields should be present (use empty values if needed)

**Q: What if I make a mistake?**
- You can edit documents in Firestore Console
- Or delete and recreate them

---

## ✅ **Summary**

1. Open Firestore Console
2. Find approved hosts in `users` collection (`isHost: true`, `isActive: true`)
3. Create documents in `approvedHosts` collection with same user ID
4. Copy all fields according to the mapping table
5. Set `isActive: true` and `lastUpdated` to current time
6. Save and repeat for all approved hosts
7. Test in app!

**Good luck!** 🚀
