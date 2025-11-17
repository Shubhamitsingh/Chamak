# 🔍 Debug Event Images - Checklist

## ❗ **Before We Continue:**

I added debug logging to help us find the issue. But first, **please check your Firebase data:**

---

## 📋 **Step 1: Check Firebase Structure**

### **Go to Firebase Console:**

1. Open Firebase Console
2. Go to **Firestore Database**
3. Find the **`events`** collection
4. Click on your latest event

### **Check if you have this field:**

```
events/{eventId}/
{
  "title": "...",
  "description": "...",
  "date": "...",
  "time": "...",
  "imageURL": "https://..."  ← THIS FIELD MUST EXIST!
  "participants": "...",
  "color": ...,
  "isNew": true,
  "isActive": true,
  "createdAt": ...
}
```

---

## ❓ **Common Issues:**

### **Issue 1: Field Name is Wrong**

❌ **Wrong field names:**
- `imageUrl` (lowercase 'u')
- `image_url` (underscore)
- `image` 
- `posterURL`

✅ **Correct field name:**
- `imageURL` (capital 'URL')

---

### **Issue 2: Image URL is Empty/Null**

Check in Firebase:
```
"imageURL": ""          ← Empty string (won't show)
"imageURL": null        ← Null value (won't show)
"imageURL": "https://..." ← Valid URL (will show!)
```

---

### **Issue 3: Invalid Image URL**

The URL must be:
- ✅ Start with `http://` or `https://`
- ✅ Point to actual image file
- ✅ Be publicly accessible

**Example valid URLs:**
```
https://firebasestorage.googleapis.com/v0/b/yourapp.appspot.com/o/events%2Fposter.jpg?alt=media
https://example.com/images/event-poster.jpg
```

---

## 🔧 **Step 2: Run the App and Check Console**

After I added debug logging, restart your app and go to Event section.

**Look for these logs in the console:**

```
🎉 [EventScreen] Event 1:
   ID: abc123
   Title: New Year Party
   imageURL: https://...your-image-url...
   Has image: true

🖼️ [_buildEventPoster] Building poster:
   Title: New Year Party
   imageURL: https://...your-image-url...
   hasImage: true
```

---

## 📸 **Step 3: How to Upload Images Correctly**

### **Option A: Firebase Storage (Recommended)**

1. **Upload image to Firebase Storage:**
   ```
   Storage → Upload file → Select event poster
   ```

2. **Get download URL:**
   - Right-click uploaded file
   - Click "Get download URL"
   - Copy the URL (looks like `https://firebasestorage.googleapis.com/...`)

3. **Add to Firestore:**
   ```javascript
   {
     "title": "My Event",
     "imageURL": "https://firebasestorage.googleapis.com/v0/b/..." // Paste here
   }
   ```

---

### **Option B: External URL**

Use any public image URL:
```javascript
{
  "title": "My Event",
  "imageURL": "https://example.com/event-poster.jpg"
}
```

---

## 🧪 **Test with Sample URL:**

Try this test image URL in your Firebase:

```
https://images.unsplash.com/photo-1492684223066-81342ee5ff30?w=800
```

Create a test event with this imageURL and see if it shows.

---

## 🐛 **Troubleshooting:**

### **If Console Shows:**

```
imageURL: null
Has image: false
```

**Problem:** Field is missing or null in Firebase  
**Solution:** Add the `imageURL` field with valid URL

---

### **If Console Shows:**

```
imageURL: https://...
Has image: true
```

But image still doesn't show:

**Problem:** Image URL might be invalid or blocked  
**Solution:** 
1. Copy the URL and paste in browser to test
2. Check if image loads in browser
3. If not, URL is broken

---

### **If You See Red Error in Console:**

```
Failed to load network image
```

**Problem:** Image URL is not accessible  
**Solution:**
- Check Firebase Storage rules (should allow read)
- Make sure URL is publicly accessible
- Try a different image URL

---

## ✅ **Quick Fix Summary:**

1. ✅ Field name = `imageURL` (exactly)
2. ✅ Value = Valid image URL starting with `https://`
3. ✅ Image is publicly accessible
4. ✅ URL works in browser

---

## 📞 **What to Tell Me:**

After you check, please tell me:

1. **What's in your Firebase?**
   - Do you have `imageURL` field? (Yes/No)
   - What's the value? (Copy and paste the URL)

2. **What does console show?**
   - Copy the debug logs that start with 🎉 and 🖼️

3. **Does the URL work in browser?**
   - Paste the imageURL in browser
   - Does image load? (Yes/No)

---

**This will help me find the exact issue!** 🔍


