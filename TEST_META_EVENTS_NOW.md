# 🚀 Test Meta App Events - Quick Commands

## ⚡ **Quick Test (Copy & Paste These Commands)**

### **Step 1: Clean and Build**

```bash
cd "C:\Users\Shubham Singh\Desktop\chamak"
flutter clean
flutter pub get
flutter run
```

### **Step 2: Open Your App**

1. App will launch automatically
2. Navigate through a few screens
3. Keep app open for 2-3 minutes

### **Step 3: Check Events Manager**

1. Go to: https://business.facebook.com/events_manager2
2. Select: "Chamakz-Live Video Chat&Dating"
3. **Wait 2-5 minutes** (events process in batches)
4. **Refresh page** (F5)
5. Check "Total events" - should show a number > 0

---

## ✅ **What You Should See**

**Before (Current):**
- Total events: 0
- Status: "Never received events"

**After Testing (Expected):**
- Total events: 5, 10, 15+ (increases with each app open)
- Status: "Receiving events" or similar
- Event graph showing activity

---

## ⏱️ **Timeline**

- **0-2 min:** Events may not appear yet (normal)
- **2-5 min:** Events should start appearing
- **5-10 min:** All events should be visible

**Be patient!** Meta processes events in batches.

---

## 🔍 **If Events Don't Appear**

### **Check 1: Internet Connection**
- Device must be online
- Events are sent to Meta servers

### **Check 2: Wait Longer**
- First events can take 5-10 minutes
- Refresh Events Manager page

### **Check 3: Verify Build**
- Make sure you ran `flutter clean` and `flutter pub get`
- Make sure app built successfully

---

## 📱 **Important Notes**

1. ✅ **Use Real Device** (not emulator) for best results
2. ✅ **Internet Required** - Events are sent online
3. ✅ **Wait 2-5 Minutes** - Events process in batches
4. ✅ **Refresh Page** - Events Manager doesn't auto-refresh

---

## 🎯 **Quick Checklist**

- [ ] Ran `flutter clean && flutter pub get && flutter run`
- [ ] Opened app on device
- [ ] Waited 2-5 minutes
- [ ] Refreshed Events Manager
- [ ] Checked "Total events" number

---

**Status:** Ready to Test!  
**Next:** Run the commands above, then check Events Manager!
