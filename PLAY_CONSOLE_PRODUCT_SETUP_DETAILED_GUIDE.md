# 🛒 Play Console In-App Product Setup - Detailed Step-by-Step Guide

**Problem:** "Your changes couldn't be saved" error when creating products  
**Solution:** Follow this exact step-by-step guide

---

## ⚠️ Common Causes of "Couldn't Save" Error

1. ❌ Missing **Product Name** or **Description**
2. ❌ Not setting **prices** for at least one country
3. ❌ Browser cache/cookies issues
4. ❌ Network connectivity problems
5. ❌ Not accepting terms and conditions
6. ❌ Missing required fields

---

## 📋 Pre-Setup Checklist

Before starting, ensure:

- [ ] ✅ You're logged into Play Console with **Admin** or **Owner** account
- [ ] ✅ Your app is already published (or at least created in Play Console)
- [ ] ✅ You have a stable internet connection
- [ ] ✅ Browser is updated (Chrome/Firefox recommended)
- [ ] ✅ Clear browser cache (Ctrl+Shift+Delete)

---

## 🎯 Step-by-Step: Create First Product

### **STEP 1: Navigate to Products**

1. Go to: **https://play.google.com/console**
2. Select your app: **"Chamak"** (or your app name)
3. In left sidebar, click: **Monetize** → **Products** → **In-app products**
4. If you see "Enable in-app products" button, click it first
5. Accept terms if prompted

---

### **STEP 2: Create Product - Basic Info**

1. Click **"Create product"** button (top right)
2. Select **"One-time product"** (NOT subscription)

**Fill in these fields EXACTLY:**

#### **Product ID:**
```
coins_90
```
⚠️ **IMPORTANT:** 
- Must be lowercase
- Use underscore `_` not hyphen `-`
- No spaces
- Must match code exactly: `coins_90`

#### **Product Name:**
```
90 Coins
```
- This is what users see in Play Store
- Keep it simple and clear

#### **Description:**
```
Purchase 90 coins for your Chamak wallet. Use coins to make calls and send gifts.
```
- Minimum 4 characters
- Describe what user gets
- Keep it clear and simple

---

### **STEP 3: Set Price - CRITICAL STEP**

**This is where most errors occur!**

#### **Option A: Set Default Price (Easiest)**

1. Look for **"Default price"** section at the top
2. Enter price: **₹9.00** (or **9.00 INR**)
3. Click **"Set default price"** or **"Apply to all"**

#### **Option B: Set Price for India Only (If Option A doesn't work)**

1. Scroll down to the country table
2. Find **"India"** in the list
3. Click the **pencil icon** ✏️ next to India
4. Enter price: **₹9.00**
5. Click **"Save"** or **"Apply"**

#### **Option C: Set Price for Multiple Countries**

1. Click **"Set prices"** button (top of table)
2. Select **"India"** (or your target countries)
3. Enter price: **₹9.00**
4. Click **"Save"**

---

### **STEP 4: Save Product**

**IMPORTANT:** Follow these steps in order:

1. **Scroll to bottom** of the page
2. Check that you see:
   - ✅ Product ID: `coins_90`
   - ✅ Product Name: `90 Coins`
   - ✅ Description: (your description)
   - ✅ At least ONE country has a price set (green checkmark)

3. Click **"Save as draft"** button (bottom right)
   - ⚠️ **DO NOT click "Activate" yet!**
   - Save as draft first to avoid errors

4. Wait for confirmation: **"Product saved"** or **"Draft saved"**

---

### **STEP 5: Activate Product**

**After saving as draft:**

1. You'll be redirected to product list
2. Find your product: **"coins_90"**
3. Click on it to open
4. Review all information
5. Click **"Activate"** button
6. Confirm activation

**Status should change to:** ✅ **"Active"**

---

## 📦 Create All 12 Products

Repeat Steps 2-5 for each product:

### **Product List:**

| # | Product ID | Name | Price (INR) | Description |
|---|------------|------|-------------|-------------|
| 1 | `coins_90` | 90 Coins | ₹9 | Purchase 90 coins for your Chamak wallet. |
| 2 | `coins_550` | 550 Coins | ₹49 | Purchase 550 coins for your Chamak wallet. |
| 3 | `coins_1100` | 1100 Coins | ₹99 | Purchase 1100 coins for your Chamak wallet. |
| 4 | `coins_1700` | 1700 Coins | ₹149 | Purchase 1700 coins for your Chamak wallet. |
| 5 | `coins_2400` | 2400 Coins | ₹199 | Purchase 2400 coins for your Chamak wallet. |
| 6 | `coins_3500` | 3500 Coins | ₹299 | Purchase 3500 coins for your Chamak wallet. |
| 7 | `coins_7500` | 7500 Coins | ₹599 | Purchase 7500 coins for your Chamak wallet. |
| 8 | `coins_13000` | 13000 Coins | ₹999 | Purchase 13000 coins for your Chamak wallet. |
| 9 | `coins_28000` | 28000 Coins | ₹1999 | Purchase 28000 coins for your Chamak wallet. |
| 10 | `coins_45000` | 45000 Coins | ₹2999 | Purchase 45000 coins for your Chamak wallet. |
| 11 | `coins_80000` | 80000 Coins | ₹4999 | Purchase 80000 coins for your Chamak wallet. |
| 12 | `coins_175000` | 175000 Coins | ₹9999 | Purchase 175000 coins for your Chamak wallet. |

---

## 🔧 Troubleshooting "Couldn't Save" Error

### **Error 1: "Your changes couldn't be saved"**

**Solutions:**

1. **Check Required Fields:**
   - ✅ Product ID filled? (must be unique)
   - ✅ Product Name filled? (minimum 1 character)
   - ✅ Description filled? (minimum 4 characters)
   - ✅ At least ONE price set?

2. **Clear Browser Cache:**
   ```
   - Press Ctrl+Shift+Delete
   - Select "Cached images and files"
   - Click "Clear data"
   - Refresh page (F5)
   ```

3. **Try Different Browser:**
   - If using Chrome, try Firefox
   - If using Firefox, try Chrome
   - Disable browser extensions

4. **Check Network:**
   - Ensure stable internet connection
   - Try different network (mobile hotspot)
   - Disable VPN if using

5. **Wait and Retry:**
   - Sometimes Play Console has temporary issues
   - Wait 5-10 minutes
   - Try again

6. **Check Product ID:**
   - Product ID must be unique
   - If `coins_90` already exists, try different name
   - Use format: `coins_90`, `coins_550`, etc.

---

### **Error 2: "Price required for at least one country"**

**Solution:**
1. Scroll to country table
2. Find **India** (or your country)
3. Click pencil icon ✏️
4. Enter price: **₹9.00** (or your price)
5. Click **Save**
6. You should see green checkmark ✅

---

### **Error 3: "Product ID already exists"**

**Solution:**
1. Check if product already created
2. Go to product list
3. If exists, edit it instead of creating new
4. Or use different Product ID

---

### **Error 4: "Invalid Product ID format"**

**Solution:**
- ✅ Use lowercase: `coins_90` (NOT `Coins_90`)
- ✅ Use underscore: `coins_90` (NOT `coins-90`)
- ✅ No spaces: `coins_90` (NOT `coins 90`)
- ✅ No special characters except underscore

---

## ✅ Verification Checklist

After creating each product, verify:

- [ ] ✅ Product ID matches exactly: `coins_90`, `coins_550`, etc.
- [ ] ✅ Product Name is set: "90 Coins", "550 Coins", etc.
- [ ] ✅ Description is filled (minimum 4 characters)
- [ ] ✅ Price is set for at least India (₹9, ₹49, etc.)
- [ ] ✅ Status is **"Active"** (not "Draft")
- [ ] ✅ No error messages visible

---

## 🎯 Quick Reference: All Products

**Copy-paste this for quick reference:**

```
Product 1:
- ID: coins_90
- Name: 90 Coins
- Price: ₹9
- Description: Purchase 90 coins for your Chamak wallet.

Product 2:
- ID: coins_550
- Name: 550 Coins
- Price: ₹49
- Description: Purchase 550 coins for your Chamak wallet.

Product 3:
- ID: coins_1100
- Name: 1100 Coins
- Price: ₹99
- Description: Purchase 1100 coins for your Chamak wallet.

Product 4:
- ID: coins_1700
- Name: 1700 Coins
- Price: ₹149
- Description: Purchase 1700 coins for your Chamak wallet.

Product 5:
- ID: coins_2400
- Name: 2400 Coins
- Price: ₹199
- Description: Purchase 2400 coins for your Chamak wallet.

Product 6:
- ID: coins_3500
- Name: 3500 Coins
- Price: ₹299
- Description: Purchase 3500 coins for your Chamak wallet.

Product 7:
- ID: coins_7500
- Name: 7500 Coins
- Price: ₹599
- Description: Purchase 7500 coins for your Chamak wallet.

Product 8:
- ID: coins_13000
- Name: 13000 Coins
- Price: ₹999
- Description: Purchase 13000 coins for your Chamak wallet.

Product 9:
- ID: coins_28000
- Name: 28000 Coins
- Price: ₹1999
- Description: Purchase 28000 coins for your Chamak wallet.

Product 10:
- ID: coins_45000
- Name: 45000 Coins
- Price: ₹2999
- Description: Purchase 45000 coins for your Chamak wallet.

Product 11:
- ID: coins_80000
- Name: 80000 Coins
- Price: ₹4999
- Description: Purchase 80000 coins for your Chamak wallet.

Product 12:
- ID: coins_175000
- Name: 175000 Coins
- Price: ₹9999
- Description: Purchase 175000 coins for your Chamak wallet.
```

---

## 📱 After Creating Products

### **Step 1: Verify All Products**

1. Go to: **Monetize** → **Products** → **In-app products**
2. You should see all 12 products listed
3. All should show status: ✅ **"Active"**

### **Step 2: Test Purchase (Optional)**

1. Add test account in Play Console
2. Install app on test device
3. Try purchasing smallest package (₹9)
4. Verify coins are added to wallet

---

## 🚨 Important Notes

1. **Product ID Must Match Code:**
   - Code uses: `coins_90`, `coins_550`, etc.
   - Play Console must use: `coins_90`, `coins_550`, etc.
   - **Case-sensitive!** Must be lowercase

2. **Prices Can Be Changed Later:**
   - You can update prices after creation
   - Changes take effect immediately

3. **Products Can't Be Deleted:**
   - Once created, products can't be deleted
   - You can deactivate them instead

4. **Activation Required:**
   - Products must be **"Active"** to work
   - Draft products won't appear in app

---

## 📞 Still Having Issues?

If you still see "Couldn't save" error:

1. **Screenshot the error** (exact message)
2. **Check browser console** (F12 → Console tab)
3. **Try incognito mode** (Ctrl+Shift+N)
4. **Contact Play Console support** if issue persists

---

## ✅ Success Criteria

You've successfully set up products when:

- ✅ All 12 products created
- ✅ All products show status: **"Active"**
- ✅ All products have prices set (at least for India)
- ✅ No error messages visible
- ✅ Product IDs match code exactly

---

**Status:** 📋 **Ready to Follow**  
**Next:** Follow Step 2-5 for each product  
**Total Products:** 12
