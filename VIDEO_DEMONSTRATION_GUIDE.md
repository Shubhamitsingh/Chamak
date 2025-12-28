# 🎥 Video Demonstration Guide for Play Store

## 📋 What is the Video Link For?

Google Play is asking for a **video demonstration** because your app uses the `FOREGROUND_SERVICE_MEDIA_PROJECTION` permission. This is a **sensitive permission** that Google requires you to justify with a video showing how your app uses it.

### Why This Permission?
The **Agora SDK** (which you use for live streaming) includes this permission for:
- **Screen sharing** during live streams
- **Media projection** (sharing device screen content)
- **Video streaming** capabilities

---

## 🎬 How to Create the Video

### Step 1: Record Your App in Action

**What to Show:**
1. **Open your app** on an Android phone
2. **Start a live stream** (go live feature)
3. **Show the live streaming working** - camera view, viewers joining
4. **If you have screen sharing:** Show that feature too
5. **Keep it short:** 30-60 seconds is enough

### Step 2: Upload to YouTube (Recommended)

**Why YouTube?**
- Free and easy
- Public or unlisted videos work
- Google Play accepts YouTube links

**Steps:**
1. **Record the video** using your phone's screen recorder or:
   - **Android:** Built-in screen recorder (swipe down → Screen Record)
   - **Or use:** AZ Screen Recorder app (free)

2. **Upload to YouTube:**
   - Go to https://www.youtube.com/upload
   - Upload your video
   - **Set visibility:** "Unlisted" (so only people with link can see)
   - **Title:** "Chamak App - Live Streaming Feature"
   - **Description:** "Demonstration of live streaming feature using Agora SDK"

3. **Copy the video URL** (e.g., `https://www.youtube.com/watch?v=xxxxx`)

### Alternative: Other Video Hosting

You can also use:
- **Google Drive** (make it shareable, copy link)
- **Vimeo** (unlisted video)
- **Any public video hosting service**

---

## 📝 What to Include in the Video

### Minimum Requirements:
✅ **Show the app launching**
✅ **Show going live** (click "Go Live" button)
✅ **Show live stream working** (camera view, streaming)
✅ **Show viewers joining** (if applicable)
✅ **Keep it under 2 minutes**

### Example Video Flow:
```
0:00 - 0:10 → Open app, navigate to "Go Live"
0:10 - 0:30 → Start live stream, show camera working
0:30 - 0:50 → Show live stream interface (viewers, chat, etc.)
0:50 - 1:00 → End stream
```

---

## 🔗 How to Submit the Video Link

### In Play Console:

1. **Paste the video URL** in the "Video link" field
   - Example: `https://www.youtube.com/watch?v=xxxxx`
   - Or: `https://drive.google.com/file/d/xxxxx/view`

2. **Make sure:**
   - ✅ Video is **publicly accessible** (or unlisted with link)
   - ✅ Video **shows the live streaming feature**
   - ✅ Video is **clear and easy to understand**

3. **Click "Save"**

---

## ⚠️ Important Notes

### If You Don't Use Screen Sharing:
- The permission might be added automatically by Agora SDK
- You can still submit the video showing **live streaming** (camera streaming)
- Explain in the form: "We use this permission for live video streaming via Agora SDK"

### If You Want to Remove the Permission:
- You would need to check Agora SDK documentation
- But **it's easier to just provide the video** - it's a one-time requirement

---

## ✅ Quick Checklist

- [ ] Record video showing live streaming feature
- [ ] Upload to YouTube (or other hosting)
- [ ] Make video unlisted/public
- [ ] Copy video URL
- [ ] Paste URL in Play Console
- [ ] Click "Save"

---

## 🎯 Example Video Description

**Title:** "Chamak - Live Streaming Feature Demo"

**Description:**
```
This video demonstrates the live streaming feature of Chamak app.
The app uses Agora SDK for real-time video streaming, which requires
FOREGROUND_SERVICE_MEDIA_PROJECTION permission for media projection
and screen sharing capabilities during live streams.
```

---

## 💡 Tips

1. **Keep it simple** - Don't overcomplicate the video
2. **Show the key feature** - Live streaming is what matters
3. **Good quality** - Make sure video is clear and visible
4. **Short and sweet** - 30-60 seconds is perfect
5. **Test the link** - Make sure the video link works before submitting

---

## 🚀 After Submitting

Once you submit the video:
1. ✅ Google will review it (usually within 24-48 hours)
2. ✅ If approved, the error will disappear
3. ✅ You can proceed with your release

---

**Need Help?** If you're stuck, I can help you create a script for the video or troubleshoot any issues! 🎬





















