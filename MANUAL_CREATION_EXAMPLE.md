# 🎯 **Manual Creation: Simple Example**

## 📝 **Step-by-Step with Example**

Let me show you with a real example:

---

## 🔍 **Step 1: Find an Approved Host**

1. Go to **Firestore** → **`users`** collection
2. Find a user with:
   - `isHost: true`
   - `isActive: true`
3. **Example:** Let's say you find a user:
   - **Document ID:** `abc123xyz456`
   - **Fields:**
     - `displayName: "John Doe"`
     - `photoURL: "https://example.com/photo.jpg"`
     - `language: "English"`
     - `country: "USA"`
     - `level: 5`
     - `hostApprovedAt: [timestamp]`
     - `approvedBy: "admin"`
     - `followersCount: 100`
     - `followingCount: 50`
     - `gender: "male"`

---

## ➕ **Step 2: Create Collection**

1. Click **"+ Start collection"**
2. **Collection ID:** `approvedHosts`
3. Click **"Next"**

---

## 📄 **Step 3: Create Document**

### **3.1: Document ID**
- **Document ID:** `abc123xyz456` (same as user ID)
- Click **"Next"**

### **3.2: Add Fields (One by One)**

**Field 1: `userId`**
- Click **"+ Add field"**
- Field name: `userId`
- Type: **string**
- Value: `abc123xyz456`
- Click **"Save"**

**Field 2: `hostName`**
- Click **"+ Add field"**
- Field name: `hostName`
- Type: **string**
- Value: `John Doe`
- Click **"Save"**

**Field 3: `hostPhotoUrl`**
- Click **"+ Add field"**
- Field name: `hostPhotoUrl`
- Type: **string**
- Value: `https://example.com/photo.jpg`
- Click **"Save"**

**Field 4: `displayName`**
- Click **"+ Add field"**
- Field name: `displayName`
- Type: **string**
- Value: `John Doe`
- Click **"Save"**

**Field 5: `language`**
- Click **"+ Add field"**
- Field name: `language`
- Type: **string**
- Value: `English`
- Click **"Save"**

**Field 6: `country`**
- Click **"+ Add field"**
- Field name: `country`
- Type: **string**
- Value: `USA`
- Click **"Save"**

**Field 7: `level`**
- Click **"+ Add field"**
- Field name: `level`
- Type: **number**
- Value: `5`
- Click **"Save"**

**Field 8: `approvedAt`**
- Click **"+ Add field"**
- Field name: `approvedAt`
- Type: **timestamp**
- Value: Click **"Set to current time"** (or use timestamp from user)
- Click **"Save"**

**Field 9: `approvedBy`**
- Click **"+ Add field"**
- Field name: `approvedBy`
- Type: **string**
- Value: `admin`
- Click **"Save"**

**Field 10: `isActive`**
- Click **"+ Add field"**
- Field name: `isActive`
- Type: **boolean**
- Value: Check **"true"** ✅
- Click **"Save"**

**Field 11: `lastUpdated`**
- Click **"+ Add field"**
- Field name: `lastUpdated`
- Type: **timestamp**
- Value: Click **"Set to current time"**
- Click **"Save"**

**Field 12: `followersCount`**
- Click **"+ Add field"**
- Field name: `followersCount`
- Type: **number**
- Value: `100`
- Click **"Save"**

**Field 13: `followingCount`**
- Click **"+ Add field"**
- Field name: `followingCount`
- Type: **number**
- Value: `50`
- Click **"Save"**

**Field 14: `gender`**
- Click **"+ Add field"**
- Field name: `gender`
- Type: **string**
- Value: `male`
- Click **"Save"**

### **3.3: Save Document**
- After adding all 14 fields, click **"Save"** button
- Done! ✅

---

## 🔄 **Step 4: Repeat for Other Hosts**

For each approved host:
1. Click **"+ Add document"**
2. Use user ID as document ID
3. Add all 14 fields
4. Save

---

## ✅ **Final Result**

After creating documents, you'll have:

```
approvedHosts collection
├── abc123xyz456 (document)
│   ├── userId: "abc123xyz456"
│   ├── hostName: "John Doe"
│   ├── hostPhotoUrl: "https://example.com/photo.jpg"
│   ├── displayName: "John Doe"
│   ├── language: "English"
│   ├── country: "USA"
│   ├── level: 5
│   ├── approvedAt: [timestamp]
│   ├── approvedBy: "admin"
│   ├── isActive: true
│   ├── lastUpdated: [timestamp]
│   ├── followersCount: 100
│   ├── followingCount: 50
│   └── gender: "male"
└── [other approved hosts...]
```

---

## 🎯 **Quick Checklist**

For each document:
- [ ] Document ID = User ID
- [ ] All 14 fields added
- [ ] `isActive` = true
- [ ] `lastUpdated` = Current timestamp
- [ ] All string fields filled (or empty string "")
- [ ] All number fields filled (or 0)

---

## 💡 **Tips**

1. **Copy user ID** - To avoid typos
2. **Copy field values** - From user document
3. **Use "Set to current time"** - For timestamp fields
4. **Check `isActive: true`** - Important!
5. **Save after each field** - Or add all, then save

---

## ✅ **That's It!**

Once you create the first document, the `approvedHosts` collection will appear in Firestore. Then add all other approved hosts the same way!

**Good luck!** 🚀
