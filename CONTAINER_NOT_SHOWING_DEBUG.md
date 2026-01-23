# 🔍 Container Not Showing - Debug Guide

**Issue:** Chamakz Team container not showing in Messages screen

---

## ✅ Code Check

### Container is Added to Body:
```dart
body: Column(
  children: [
    // Chamakz Team Container (Below AppBar)
    _buildChamakzTeamContainer(),  // ✅ This is added
    // Search Bar (only if not hidden)
    if (!widget.hideSearchBar) _buildSearchBar(),
    // Messages List
    Expanded(
      child: _buildMessagesList(),
    ),
  ],
),
```

### Container Method Exists:
- ✅ `_buildChamakzTeamContainer()` method exists at line 155
- ✅ Returns a Widget with Material, InkWell, Container
- ✅ Has minimum height: `constraints: const BoxConstraints(minHeight: 64)`

---

## 🐛 Possible Issues & Fixes

### Issue 1: StreamBuilder Waiting for Data
**Symptom:** Container doesn't show during loading

**Fix:** StreamBuilder should always show container (already handled with defaults)

### Issue 2: Image Asset Not Found
**Symptom:** Container shows but logo is broken

**Check:**
- Does `assets/images/logopink.png` exist?
- Is it added to `pubspec.yaml`?

**Fix:**
```yaml
# pubspec.yaml
flutter:
  assets:
    - assets/images/logopink.png
```

### Issue 3: Column Layout Issue
**Symptom:** Container hidden behind other widgets

**Check:** Verify Column layout is correct

---

## 🔍 Debug Steps

### Step 1: Check Console Output
Run the app and check console for:
- `📨 Team messages snapshot: X messages`
- `❌ Team messages container error: ...`
- `❌ Unread count container error: ...`

### Step 2: Check if Container Renders
Add a simple test container:

```dart
body: Column(
  children: [
    // TEST: Simple container to verify layout
    Container(
      height: 64,
      color: Colors.red,
      child: Center(child: Text('TEST CONTAINER')),
    ),
    // Chamakz Team Container (Below AppBar)
    _buildChamakzTeamContainer(),
    // ...
  ],
),
```

If red container shows → layout is fine, issue is with Chamakz container  
If red container doesn't show → layout issue

### Step 3: Verify Image Asset
Check if logo image exists:
- Path: `assets/images/logopink.png`
- File exists? ✅/❌
- Added to `pubspec.yaml`? ✅/❌

### Step 4: Test Without StreamBuilder
Temporarily replace StreamBuilder with simple container:

```dart
Widget _buildChamakzTeamContainer() {
  return Container(
    height: 64,
    color: Colors.pink.withOpacity(0.2),
    child: Center(
      child: Text('Chamakz Team'),
    ),
  );
}
```

If this shows → Issue is with StreamBuilder  
If this doesn't show → Issue is with layout/Column

---

## ✅ Quick Fix: Always Show Container

The container should always show. Current code handles this, but if it's still not showing, try this:

```dart
Widget _buildChamakzTeamContainer() {
  // Always show container, even if StreamBuilder is loading
  return StreamBuilder<List<TeamMessageModel>>(
    stream: _teamMessageService.getTeamMessagesStream(),
    initialData: <TeamMessageModel>[],  // ✅ Add initial data
    builder: (context, messagesSnapshot) {
      return StreamBuilder<int>(
        stream: _teamMessageService.getUnreadTeamMessagesCount(),
        initialData: 0,  // ✅ Add initial data
        builder: (context, unreadSnapshot) {
          // ... rest of code
        },
      );
    },
  );
}
```

---

## 📋 Checklist

- [ ] Container method `_buildChamakzTeamContainer()` exists
- [ ] Container is added to body Column
- [ ] Image asset `assets/images/logopink.png` exists
- [ ] Image is added to `pubspec.yaml`
- [ ] No console errors when opening Messages screen
- [ ] StreamBuilder is working (check console output)
- [ ] Container has minimum height (64px)

---

## 🎯 Most Likely Issue

**90% of the time:** Image asset not found or not added to `pubspec.yaml`

**Check:**
1. Does file exist? `assets/images/logopink.png`
2. Is it in `pubspec.yaml`?
3. Run `flutter clean` then `flutter pub get`

---

## 🚀 Quick Test

Replace the container temporarily with this simple test:

```dart
Widget _buildChamakzTeamContainer() {
  return Container(
    height: 64,
    width: double.infinity,
    color: Colors.pink.withOpacity(0.2),
    padding: EdgeInsets.all(16),
    child: Row(
      children: [
        Icon(Icons.business, color: Color(0xFFFF1B7C), size: 24),
        SizedBox(width: 12),
        Text(
          'Chamakz Team',
          style: TextStyle(
            color: Color(0xFFFF1B7C),
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Spacer(),
        Icon(Icons.chevron_right, color: Color(0xFFFF1B7C)),
      ],
    ),
  );
}
```

**If this shows** → Original code has an issue (probably StreamBuilder or image)  
**If this doesn't show** → Layout/Column issue

---

**Check these and report what you find!**
