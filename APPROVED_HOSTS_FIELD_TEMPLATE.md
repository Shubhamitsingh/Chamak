# 📋 **Quick Reference: `approvedHosts` Document Structure**

## 🎯 **Document Template**

When creating a document in `approvedHosts` collection, use this structure:

---

## 📝 **Field List (Copy-Paste Ready)**

```
Document ID: [USER_ID_FROM_USERS_COLLECTION]

Fields:
├── userId (string) = [USER_ID]
├── hostName (string) = [displayName OR name OR "Host"]
├── hostPhotoUrl (string) = [photoURL OR ""]
├── displayName (string) = [displayName OR name OR "Host"]
├── language (string) = [language OR ""]
├── country (string) = [country OR ""]
├── level (number) = [level OR 1]
├── approvedAt (timestamp) = [hostApprovedAt OR current time]
├── approvedBy (string) = [approvedBy OR "admin"]
├── isActive (boolean) = true
├── lastUpdated (timestamp) = [current time]
├── followersCount (number) = [followersCount OR 0]
├── followingCount (number) = [followingCount OR 0]
└── gender (string) = [gender OR ""]
```

---

## 🔄 **Example: Real Data**

### **From `users` Collection:**
```
Document ID: abc123xyz456
Fields:
- displayName: "John Doe"
- photoURL: "https://example.com/photo.jpg"
- language: "English"
- country: "USA"
- level: 5
- hostApprovedAt: 2024-01-15T10:30:00Z
- approvedBy: "admin"
- followersCount: 100
- followingCount: 50
- gender: "male"
- isHost: true
- isActive: true
```

### **To `approvedHosts` Collection:**
```
Document ID: abc123xyz456
Fields:
- userId: "abc123xyz456"
- hostName: "John Doe"
- hostPhotoUrl: "https://example.com/photo.jpg"
- displayName: "John Doe"
- language: "English"
- country: "USA"
- level: 5
- approvedAt: 2024-01-15T10:30:00Z
- approvedBy: "admin"
- isActive: true
- lastUpdated: [CURRENT_TIMESTAMP]
- followersCount: 100
- followingCount: 50
- gender: "male"
```

---

## ✅ **Quick Checklist**

When adding each host, make sure:

- [ ] Document ID = User ID (from `users` collection)
- [ ] `userId` field = Same as document ID
- [ ] `isActive` = `true` (boolean)
- [ ] `lastUpdated` = Current timestamp
- [ ] All 14 fields are present
- [ ] String fields use empty string `""` if data is missing
- [ ] Number fields use `0` or `1` if data is missing

---

## 🚀 **Quick Steps**

1. **Open Firestore Console** → `users` collection
2. **Find approved host** (`isHost: true`, `isActive: true`)
3. **Copy user ID** (document ID)
4. **Go to `approvedHosts` collection**
5. **Create new document** with same user ID
6. **Add all 14 fields** using the template above
7. **Save**
8. **Repeat for all approved hosts**

---

## 💡 **Pro Tips**

- **Document ID = User ID** - This is critical!
- **Use current timestamp** for `lastUpdated`
- **Set `isActive: true`** - Only for approved hosts
- **Copy exact values** from `users` collection
- **Use fallback values** if data is missing (see template)

---

**That's it!** Follow this template for each approved host. 🎯
