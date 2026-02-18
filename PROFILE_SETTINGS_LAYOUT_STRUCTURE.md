# Profile Settings Screen – Layout Structure

## How the layout is built (top to bottom)

### 1. **Root: `CustomScrollView` + slivers**

Everything is one vertical scroll. The body uses **slivers** so the header can collapse and the rest scrolls under it.

```
CustomScrollView
├── Sliver 1: _buildAppBar()        ← Cover image (SliverAppBar)
├── Sliver 2: _buildProfileInfoCard() ← White card (SliverToBoxAdapter)
└── Sliver 3: _buildContentArea()   ← Tabs content (SliverFillRemaining)
```

---

### 2. **Where the image “ends” and the next layer starts**

- **Image layer:** `SliverAppBar` with `expandedHeight: screenHeight * 0.35`.
  - The “image end” is at **35% of screen height** from the top.
  - Content of the bar is in `FlexibleSpaceBar` → `background: Stack` (cover image + buttons + page dots).

- **Content layer:** `SliverToBoxAdapter` with the white `Container`.
  - This sliver is placed **right after** the `SliverAppBar` in the list.
  - So in layout order:
    - From 0 to 35% height: AppBar (image).
    - After that: the white card starts (name, ID, stats, bio, Post, tabs).

So: **image end point = bottom of SliverAppBar**. The “other layer” (white card) starts at the next sliver, immediately below that point.

---

### 3. **What happens when the user scrolls up**

- `SliverAppBar` has `pinned: false`, `floating: false`, `snap: false`.
- So when you scroll **up**:
  - The app bar **scrolls away** with the list (it shrinks/collapses as the scroll offset increases).
  - The white card and the content below move up and **replace** the image area.
- There is **no overlap** in the current code: the white card starts exactly where the app bar ends. So when you scroll up, you see:
  1. Image getting pushed up and disappearing.
  2. White card (and tabs content) moving up into the space where the image was.

So “when user scrolls upward” the **overlap** you see is not a second layer drawn on top of the image; it’s the **next sliver (white card)** taking the place of the image as it scrolls off.

---

### 4. **How to implement “overlap of cover image” (card over image)**

If you want the **white card to overlap the bottom of the cover image** (card starts a bit higher, so it sits on top of the image):

- You **cannot** use negative margin (e.g. `margin: EdgeInsets.only(top: -30)`) on a `Container` – Flutter will throw (margin must be non‑negative).
- Correct way: keep the white card in `SliverToBoxAdapter`, but **shift it up** with **Transform.translate**:

```dart
// In _buildProfileInfoCard():
return SliverToBoxAdapter(
  child: Transform.translate(
    offset: const Offset(0, -30),  // Move content UP by 30px → overlaps image
    child: Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(40),
          topRight: Radius.circular(40),
        ),
      ),
      // ... rest of card
    ),
  ),
);
```

- **Layout order stays the same:** image ends at 35% height, next sliver (white card) still starts right after. But **visually** the card is drawn 30px higher, so it overlaps the bottom of the image.
- When the user **scrolls up**, the whole scroll view (including this translated card) moves up together, so the overlap scrolls away with the list.

So:
- **Image end point:** bottom of `SliverAppBar` (35% of screen height).
- **Content layer start:** first pixel of the next sliver (white card); with `Transform.translate(0, -30)` that content is **drawn** 30px higher, overlapping the image.

---

### 5. **Summary**

| Part | Widget | Role |
|------|--------|------|
| Cover image | `SliverAppBar` (expandedHeight: 35%) | Image from top until “image end point”. |
| Image end → content start | Next sliver after SliverAppBar | White card starts here in layout; use `Transform.translate(0, -30)` to overlap image. |
| White card | `SliverToBoxAdapter` + `Container` | Name, ID, stats, bio, Post button, tabs. |
| Tab content | `SliverFillRemaining` + `TabBarView` | Post / Sub / About / Fans content. |

**Scrolling:** One `CustomScrollView`; when user scrolls up, the app bar collapses and the white card + content move up. Overlap is only visual (translate); no extra “layer” logic needed for scroll.
