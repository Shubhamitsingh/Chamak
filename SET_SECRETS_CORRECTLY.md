# ✅ CORRECT WAY TO SET SECRETS

## ❌ **WRONG (What you did):**
```bash
firebase functions:secrets:set payprime_lsypar3mrsndjkq82qvhtcxglm2echynaqvxige0jijput1cal14
```
This uses the API key VALUE as the secret name!

---

## ✅ **CORRECT (What you should do):**

### **Step 1: Set API Key Secret**

Run this command (from project root, NOT functions folder):
```bash
cd "C:\Users\Shubham Singh\Desktop\chamak"
firebase functions:secrets:set PAYPRIME_API_KEY
```

**When it asks:** `✔ Enter a value for PAYPRIME_API_KEY:`

**Paste this and press Enter:**
```
payprime_lsypar3mrsndjkq82qvhtcxglm2echynaqvxige0jijput1cal14
```

---

### **Step 2: Set Secret Key**

Run this command:
```bash
firebase functions:secrets:set PAYPRIME_SECRET_KEY
```

**When it asks:** `✔ Enter a value for PAYPRIME_SECRET_KEY:`

**Paste this and press Enter:**
```
payprime_4dp8c4x31mmp029kmkp7532zmvamufzez67eyercai1b265tsz14
```

---

## 📝 **KEY POINTS:**

1. **Secret NAME** = `PAYPRIME_API_KEY` (what we use in code)
2. **Secret VALUE** = `payprime_lsypar3mrsndjkq82qvhtcxglm2echynaqvxige0jijput1cal14` (your actual key)

3. **Command format:**
   ```bash
   firebase functions:secrets:set SECRET_NAME
   ```
   Then enter the VALUE when prompted.

4. **Run from project root** (not functions folder):
   ```bash
   cd "C:\Users\Shubham Singh\Desktop\chamak"
   ```

---

## ✅ **After Setting Secrets:**

1. Verify they're set:
   ```bash
   firebase functions:secrets:access PAYPRIME_API_KEY
   firebase functions:secrets:access PAYPRIME_SECRET_KEY
   ```

2. Deploy functions:
   ```bash
   firebase deploy --only functions
   ```
