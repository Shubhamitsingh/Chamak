# ⚠️ CRITICAL: 2 Products Need ID Fixes

**Date:** February 4, 2026  
**Status:** 🔴 **2 Products Have Wrong IDs**

---

## 🚨 Problems Found

### **Product 1: "550 Coins"**
- ❌ **Current ID:** `coins550` (missing underscore)
- ✅ **Should be:** `coins_550` (with underscore)

### **Product 2: "90 Coins"**
- ❌ **Current ID:** `coins_9` (missing zero)
- ✅ **Should be:** `coins_90` (with zero)

**Both will cause purchases to FAIL!**

---

## 🔧 How to Fix Both Products

### **Fix Product 1: "550 Coins"**

**Step 1: Delete Current Product**
1. Go to Play Console → Products → One-time products
2. Find: **"550 Coins"** (ID: `coins550`)
3. Click on it to open
4. Click **"Delete"** or **"Deactivate"** → **"Delete"**
5. Confirm deletion

**Step 2: Create New Product**
1. Click **"Create one-time product"**
2. Fill in:
   - **Product ID:** `coins_550` ⚠️ **MUST have underscore!**
   - **Product Name:** `550 Coins`
   - **Description:** `Purchase 550 coins for your Chamak wallet.`
   - **Price:** ₹49.00 (for India)
3. Click **"Save as draft"**
4. Then click **"Activate"**

**Step 3: Verify**
- ✅ Product ID shows: `coins_550` (with underscore)
- ✅ Status: **"Active"**

---

### **Fix Product 2: "90 Coins"**

**Step 1: Delete Current Product**
1. Go to Play Console → Products → One-time products
2. Find: **"90 Coins"** (ID: `coins_9`)
3. Click on it to open
4. Click **"Delete"** or **"Deactivate"** → **"Delete"**
5. Confirm deletion

**Step 2: Create New Product**
1. Click **"Create one-time product"**
2. Fill in:
   - **Product ID:** `coins_90` ⚠️ **MUST have "90" not "9"!**
   - **Product Name:** `90 Coins`
   - **Description:** `Purchase 90 coins for your Chamak wallet.`
   - **Price:** ₹9.00 (for India)
3. Click **"Save as draft"**
4. Then click **"Activate"**

**Step 3: Verify**
- ✅ Product ID shows: `coins_90` (with "90")
- ✅ Status: **"Active"**

---

## 📋 Correct Product IDs Reference

**Copy-paste these EXACT IDs when creating:**

| Product Name | Correct Product ID | Wrong ID (Current) |
|--------------|-------------------|-------------------|
| 90 Coins | `coins_90` | ❌ `coins_9` |
| 550 Coins | `coins_550` | ❌ `coins550` |

**Important Rules:**
- ✅ Use **underscore** `_` between "coins" and number
- ✅ Use **lowercase** only
- ✅ Include **all digits** (90 not 9, 550 not 55)

---

## ✅ Verification Checklist

After fixing both products:

- [ ] ✅ "550 Coins" deleted
- [ ] ✅ "550 Coins" recreated with ID: `coins_550` (with underscore)
- [ ] ✅ "90 Coins" deleted
- [ ] ✅ "90 Coins" recreated with ID: `coins_90` (with "90")
- [ ] ✅ Both products show status: **"Active"**
- [ ] ✅ Both products have prices set
- [ ] ✅ All 12 products now have correct IDs

---

## 🎯 All 12 Correct Product IDs

**Use these EXACT IDs (for reference):**

```
coins_90       ← Fix: currently coins_9
coins_550      ← Fix: currently coins550
coins_1100
coins_1700
coins_2400
coins_3500
coins_7500
coins_13000
coins_28000
coins_45000
coins_80000
coins_175000
```

---

## ⚠️ Common Mistakes to Avoid

**When creating products, make sure:**

1. ❌ NOT: `coins550` (no underscore)
   ✅ YES: `coins_550` (with underscore)

2. ❌ NOT: `coins_9` (missing zero)
   ✅ YES: `coins_90` (with "90")

3. ❌ NOT: `Coins_90` (uppercase)
   ✅ YES: `coins_90` (lowercase)

4. ❌ NOT: `coins-90` (hyphen)
   ✅ YES: `coins_90` (underscore)

---

## 📊 Current Status

**Products Status:**
- ✅ 10 products: **Correct IDs** ✅
- ⚠️ 2 products: **Wrong IDs** - Need fixing

**Completion:** 83% (10/12 correct)

---

## 🚀 Action Plan

1. **Delete:** "550 Coins" (ID: `coins550`)
2. **Create:** "550 Coins" (ID: `coins_550`)
3. **Delete:** "90 Coins" (ID: `coins_9`)
4. **Create:** "90 Coins" (ID: `coins_90`)
5. **Verify:** All 12 products have correct IDs
6. **Test:** Try purchasing both packages in app

---

## ✅ Success Criteria

You've successfully fixed when:

- ✅ "550 Coins" shows ID: `coins_550` (with underscore)
- ✅ "90 Coins" shows ID: `coins_90` (with "90")
- ✅ Both products are **Active**
- ✅ All 12 products match code exactly

---

**Status:** 🔴 **Action Required** - Fix 2 Product IDs  
**Priority:** **HIGH** - Purchases won't work until fixed
