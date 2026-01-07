# 🔧 How to Enter Secret Value Correctly

## ❌ **The Problem:**

When you see this prompt:
```
✔ Enter a value for PAYPRIME_API_KEY:
```

You're probably just pressing **Enter** without typing anything. That's why you get:
```
Error: Secret Payload cannot be empty.
```

---

## ✅ **SOLUTION: Type the Value When Prompted**

### **Step-by-Step:**

1. **Run the command:**
   ```bash
   firebase functions:secrets:set PAYPRIME_API_KEY
   ```

2. **When you see this prompt:**
   ```
   ✔ Enter a value for PAYPRIME_API_KEY:
   ```

3. **TYPE or PASTE this value:**
   ```
   payprime_lsypar3mrsndjkq82qvhtcxglm2echynaqvxige0jijput1cal14
   ```

4. **Press Enter**

5. **You should see:**
   ```
   ✔ Created a new secret version...
   ```

---

## 🎯 **Alternative Method: Use Echo (PowerShell)**

If typing doesn't work, you can use this PowerShell command:

```powershell
echo "payprime_lsypar3mrsndjkq82qvhtcxglm2echynaqvxige0jijput1cal14" | firebase functions:secrets:set PAYPRIME_API_KEY
```

For the secret key:
```powershell
echo "payprime_4dp8c4x31mmp029kmkp7532zmvamufzez67eyercai1b265tsz14" | firebase functions:secrets:set PAYPRIME_SECRET_KEY
```

---

## 📝 **What You Need to Do:**

1. **For PAYPRIME_API_KEY:**
   - Run: `firebase functions:secrets:set PAYPRIME_API_KEY`
   - When prompted, TYPE: `payprime_lsypar3mrsndjkq82qvhtcxglm2echynaqvxige0jijput1cal14`
   - Press Enter

2. **For PAYPRIME_SECRET_KEY:**
   - Run: `firebase functions:secrets:set PAYPRIME_SECRET_KEY`
   - When prompted, TYPE: `payprime_4dp8c4x31mmp029kmkp7532zmvamufzez67eyercai1b265tsz14`
   - Press Enter

---

## ⚠️ **Important:**

- **Don't just press Enter** - you must TYPE or PASTE the value
- The value will be hidden as you type (for security) - that's normal
- Make sure you type the ENTIRE value correctly
