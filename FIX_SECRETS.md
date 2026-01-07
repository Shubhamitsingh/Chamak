# 🔧 Fix Firebase Secrets - Correct Commands

## ❌ **What Went Wrong:**

You used the API key **value** as the secret **name** instead of using the secret name `PAYPRIME_API_KEY`.

**Wrong:**
```bash
firebase functions:secrets:set payprime_lsypar3mrsndjkq82qvhtcxglm2echynaqvxige0jijput1cal14
```

**Correct:**
```bash
firebase functions:secrets:set PAYPRIME_API_KEY
# Then enter the value when prompted
```

---

## ✅ **CORRECT STEPS:**

### **Step 1: Set PAYPRIME_API_KEY Secret**

```bash
firebase functions:secrets:set PAYPRIME_API_KEY
```

When prompted, enter:
```
payprime_lsypar3mrsndjkq82qvhtcxglm2echynaqvxige0jijput1cal14
```

### **Step 2: Set PAYPRIME_SECRET_KEY Secret**

```bash
firebase functions:secrets:set PAYPRIME_SECRET_KEY
```

When prompted, enter:
```
payprime_4dp8c4x31mmp029kmkp7532zmvamufzez67eyercai1b265tsz14
```

### **Step 3: Verify Secrets Are Set**

```bash
firebase functions:secrets:access PAYPRIME_API_KEY
firebase functions:secrets:access PAYPRIME_SECRET_KEY
```

### **Step 4: Deploy Functions**

```bash
firebase deploy --only functions
```

---

## 🗑️ **Optional: Clean Up Wrong Secret**

If you want to delete the incorrectly named secret:

```bash
firebase functions:secrets:destroy PAYPRIME_LSYPAR3MRSNDJKQ82QVHTCXGLM2ECHYNAQVXIGE0JIJPUT1CAL14
```

---

## 📝 **Summary:**

- **Secret Name:** `PAYPRIME_API_KEY` (the name we use in code)
- **Secret Value:** `payprime_lsypar3mrsndjkq82qvhtcxglm2echynaqvxige0jijput1cal14` (your actual API key)

The secret **name** is what we reference in code, the **value** is what you enter when prompted.
