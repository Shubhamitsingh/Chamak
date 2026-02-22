# Coin Conversion & Host Commission – Current State & “Like Other Apps” (Chingari / Chamet / Zeeplive) Report

**Date:** February 2025  
**Purpose:** Document current coin→INR and commission logic in detail, then outline how to present “1 Lakh Coins = ₹900” with 25% host / 75% company commission (like competitor apps).  
**No code changes in this report – analysis and proposal only.**

---

## 1. Current Phase – Summary

| What | Value |
|------|--------|
| Your stated rate | 1000 coins = $0.05 ≈ ₹4.5 (e.g. at 90 INR/USD) |
| So 1 Lakh (1,00,000) coins | 100 × ₹4.5 = **₹450** (how hosts perceive it from display) |
| Competitor-style display | 1 Lakh = **₹900** (e.g. Chingari, Chamet, Zeeplive type positioning) |
| Your goal | Show 1 Lakh = ₹900 and frame as: **Host 25%**, **Company 75%** |

---

## 2. Current Implementation – In Detail

### 2.1 Source of truth: `lib/services/coin_conversion_service.dart`

| Constant / logic | Value | Meaning |
|------------------|--------|--------|
| `U_TO_C_RATIO` | **5** | 1 U Coin (user spends) → 5 C Coins (host earns) |
| `U_COIN_RUPEE_VALUE` | **1** | 1 U Coin = ₹1 (for internal calculation) |
| `HOST_SHARE` | **0.20** | Host gets 20% of U Coin value |
| `PLATFORM_COMMISSION` | **0.80** | Platform keeps 80% |

**Conversion:**

- User sends **100 U Coins** (₹100 value) → Host gets **500 C Coins**.
- **Actual withdrawal (host):**  
  `calculateHostWithdrawal(cCoins) = (cCoins / 5) × ₹1 × 20% = cCoins × 0.04`  
  So: **1 C Coin = ₹0.04** (actual payout).

So in the **backend**:

- 1,00,000 C Coins → **₹4,000** actual withdrawable (not ₹450).

The “₹450” you mentioned comes from the **display** (1000 = $0.05 ≈ ₹4.5), not from this formula.

---

### 2.2 Where “1000 = $0.05” is shown (display only)

**File:** `lib/screens/my_earning_screen.dart`

| Location | What’s shown | Implied rate |
|----------|----------------|--------------|
| **Conversion card** (~377–434) | “1000 Coin = $0.05” | 1000 C = $0.05 → at 90 INR/USD → 1000 C ≈ ₹4.5 → **1 Lakh C ≈ ₹450** |
| **Withdrawal input** (~477–478) | USD equivalent of entered coins using same rate | Same: 1 C = $0.00005 |

So **hosts see**: 1000 coins = $0.05 (≈ ₹4.5) → 1 Lakh = **₹450**.  
**Actual payout** from `CoinConversionService` is **1 C = ₹0.04** → 1 Lakh = **₹4,000**.

So currently:

- **Display** suggests a **lower** value (₹450 per 1 Lakh) than what the **backend** pays (₹4,000 per 1 Lakh).
- The “real” logic for payout is **1 C = ₹0.04** everywhere else (see below).

---

### 2.3 Where “1 C = ₹0.04” is used (actual payout & min withdrawal)

| File | Usage |
|------|--------|
| **coin_conversion_service.dart** | `calculateHostWithdrawal(cCoins)` → **cCoins × 0.04** (same as 1 C = ₹0.04). |
| **gift_service.dart** | `withdrawableAmount = CoinConversionService.calculateHostWithdrawal(totalCCoins)` → balance host can withdraw. |
| **my_earning_screen.dart** | `_coinToInrRate = 0.04`, `_minWithdrawalINR = 20` → min withdrawal = 500 C Coins (500 × 0.04 = ₹20). Used for “minimum X Coin”, “₹Y until withdrawal”, and INR↔C Coin in withdrawal form. |
| **withdrawal_service.dart** | When marking paid: amount stored in INR; C Coins to deduct = **amountInINR / 0.04**. Backward compat: old records (amount in C Coins) × 0.04 = INR. |
| **withdrawal_request_model.dart** | Old records: amount (C Coins) × **0.04** → INR. |
| **admin_panel_screen.dart** | Display: `cCoinsEquivalent = inrAmount / 0.04`. |

So across the app, **actual** host payout is consistently **1 C Coin = ₹0.04** (1 Lakh = **₹4,000**). The only place that suggests “₹450 per 1 Lakh” is the **conversion card** (1000 = $0.05).

---

### 2.4 User (viewer) side – U Coins purchase

**File:** `lib/screens/wallet_screen.dart` – recharge packages (e.g. ₹19→190 coins, ₹99→1100, ₹9999→175000).  
So users buy **U Coins** at roughly ~10–17.5 coins per rupee depending on pack.  
When they send gifts, **U Coins** are converted to **C Coins** for the host via `U_TO_C_RATIO = 5` and payout via **1 C = ₹0.04**.

---

## 3. Competitor-style framing (Chingari / Chamet / Zeeplive type)

You want:

1. **Display:** 1 Lakh coins = **₹900** (not ₹450).
2. **Story:** “Host commission 25%, company commission 75%.”

So we define a **display value** and a **commission** on that value.

---

### 3.1 Option A – Display 1 Lakh = ₹900, host gets 25% of that

- **Display value:** 1 C Coin = ₹0.009 (so 1,00,000 C = **₹900**).
- **Host share:** 25% of that → 0.009 × 0.25 = **₹0.00225 per C Coin**.
- So: **1 Lakh C → display ₹900 → host actually gets 25% = ₹225.**

Comparison with **current**:

- Current: 1 Lakh C = **₹4,000** (1 C = ₹0.04).
- Option A: 1 Lakh C = **₹225** (1 C = ₹0.00225).

So Option A means **reducing** host payout from ₹4,000 to ₹225 per 1 Lakh (and framing it as “25% of ₹900”).  
That is a big cut unless you currently overpay vs your intended economics.

---

### 3.2 Option B – Keep current payout, only change “display story”

- **Keep** actual payout: 1 C = ₹0.04 (1 Lakh = ₹4,000).
- **Display** “1 Lakh = ₹900” and “You get 25%” as **informational/marketing** only.
- Then “25% of ₹900” = ₹225, but you’d still be paying ₹4,000 per 1 Lakh – i.e. you’d be paying **more** than what the displayed “25%” suggests. So this is only a “display lie” and not consistent with a real 25/75 split.

---

### 3.3 Option C – Make display and commission consistent (recommended if you want 25/75)

- **Display:** 1 Lakh coins = **₹900** (1 C = ₹0.009).
- **Host 25%:** 0.009 × 0.25 = **₹0.00225 per C** → 1 Lakh = **₹225**.
- **Company 75%:** 0.009 × 0.75 = ₹0.00675 per C.

So you would:

- Change **actual** conversion from **1 C = ₹0.04** to **1 C = ₹0.00225** (25% of ₹0.009).
- Update **all** places that use 0.04 (withdrawal, min withdrawal, admin, etc.) to use the new rate.
- Update **all** display strings to show “1 Lakh = ₹900” and “Host 25% / Platform 75%”.

Result: Hosts see “1 Lakh = ₹900, I get 25% = ₹225,” and that’s exactly what they get.  
This matches competitor **positioning** (high coin value + commission) but **reduces** payout from current (₹4,000 → ₹225 per 1 Lakh).

---

## 4. Calculation summary table (for your decision)

| Scenario | Display: 1 Lakh C = | Host share | Host actual per 1 Lakh | 1 C = (INR) | Your current |
|----------|----------------------|------------|-------------------------|-------------|---------------|
| **Current (backend)** | — | 20% of U value | ₹4,000 | ₹0.04 | ✅ Live now |
| **Current (card)** | ≈ ₹450 (via $0.05) | — | ₹4,000 | — | Inconsistent |
| **Option A / C** (25% of ₹900) | ₹900 | 25% | ₹225 | ₹0.00225 | New design |
| **If you kept payout, only display** | ₹900 | “25%” (display only) | ₹4,000 | ₹0.04 | Overpay vs story |

So:

- **Correct and consistent “25% / 75%” and “1 Lakh = ₹900”** → use **Option C** (change rate to ₹0.00225 per C, update all 0.04 and all UI).
- If you want to **keep** current payout (₹4,000 per 1 Lakh), you cannot truthfully say “1 Lakh = ₹900 and host gets 25%” unless you treat it as marketing only and accept that you pay more than that 25%.

---

## 5. Files to touch for any change (no edits in this report)

- **lib/services/coin_conversion_service.dart** – U_TO_C_RATIO, HOST_SHARE, PLATFORM_COMMISSION, U_COIN_RUPEE_VALUE, `calculateHostWithdrawal`, and any new “display value” constant (e.g. 1 C = ₹0.009 for “1 Lakh = 900”).
- **lib/screens/my_earning_screen.dart** – Conversion card (“1000 Coin = …”), withdrawal USD/INR display, `_coinToInrRate`, `_minWithdrawalINR`, min coin messages, any “25% / 75%” text.
- **lib/services/withdrawal_service.dart** – C Coins deduction from INR (replace 0.04 with new rate).
- **lib/services/gift_service.dart** – Only via `CoinConversionService.calculateHostWithdrawal` (no change if only conversion service changes).
- **lib/models/withdrawal_request_model.dart** – Backward compat: old C Coins × (new rate) for INR.
- **lib/screens/admin_panel_screen.dart** – Any C Coins ↔ INR display (e.g. inrAmount / rate).
- **Any other screen** that shows “X coins = ₹Y” or “minimum X coins” (search for 0.04 and “coin”/“Coin”).

---

## 6. Recommendation (for implementation later)

1. **Decide** whether you want:
   - **Real 25/75 and 1 Lakh = ₹900** → implement Option C (new rate **1 C = ₹0.00225**, 1 Lakh = ₹225 host payout; display 1 Lakh = ₹900 and “Host 25%, Platform 75%”), **or**
   - **Keep current payout** and only change **display** to “1 Lakh = ₹900” and “25%” as messaging (and accept that actual payout is higher than that 25% of ₹900).
2. **Single source of truth:** Put the “display value” (e.g. 1 C = ₹0.009) and “host commission %” (25%) and “actual payout per C” (0.00225) in **coin_conversion_service.dart** (or one config), and use these constants everywhere (withdrawal, min withdrawal, my_earning_screen, admin).
3. **Replace all hardcoded 0.04** with the chosen rate from that service/config.
4. **Update conversion card** from “1000 Coin = $0.05” to an INR-based line, e.g. “1,00,000 Coins = ₹900 (Your share 25%)” or per 1000: “1000 Coins = ₹9 (Your share ₹2.25)”.

Once you confirm which option you want (A/C vs display-only), the exact constant values and UI strings can be implemented in code step by step.

---

**End of report. No code was changed.**
