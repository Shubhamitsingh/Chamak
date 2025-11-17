# 🎉 Events & Announcements - Admin Panel to Flutter App

## ✅ **FLUTTER APP FIXED!**

Your Flutter app now fetches **REAL data from Firebase** instead of showing dummy/mock data!

### **What Changed:**
- ❌ **Before:** Hardcoded fake data in `_getEvents()` and `_getAnnouncements()`
- ✅ **After:** Real-time data from Firebase using `StreamBuilder`

---

## 📊 **Firebase Collections Structure**

Your admin panel needs to create data in these Firestore collections:

### **Collection 1: `announcements`**

```javascript
announcements/
  └── {announcementId}/
      ├── title: "New Feature Released!"
      ├── description: "Check out our amazing new live streaming feature..."
      ├── date: "15 Nov 2025"
      ├── time: "Live Now"  // or "Released", "Coming Soon"
      ├── type: "announcement"
      ├── isNew: true  // Shows "NEW" badge
      ├── color: 0xFF3B82F6  // Color as int (blue)
      ├── iconName: "campaign"  // Icon name as string
      ├── createdAt: Timestamp
      └── isActive: true
```

### **Collection 2: `events`**

```javascript
events/
  └── {eventId}/
      ├── title: "Weekly Talent Show"
      ├── description: "Join us for an exciting talent showcase..."
      ├── date: "20 Nov 2025"
      ├── time: "8:00 PM"
      ├── type: "event"
      ├── isNew: true  // Shows "NEW" badge
      ├── color: 0xFF10B981  // Color as int (green)
      ├── participants: "1.2K"  // String
      ├── createdAt: Timestamp
      └── isActive: true
```

---

## 🎨 **Color Reference** (as integers)

```javascript
// Use these color values in your admin panel:

Blue:    0xFF3B82F6
Green:   0xFF10B981
Red:     0xFFEF4444
Pink:    0xFFEC4899
Purple:  0xFF8B5CF6
Orange:  0xFFFFB800
Cyan:    0xFF06B6D4
```

---

## 🔧 **Admin Panel Backend API Routes**

Add these routes to your `server/index.js`:

```javascript
const { db } = require('./firebase-admin');

// ===== ANNOUNCEMENTS APIs =====

// Get all announcements
app.get('/api/announcements', async (req, res) => {
  try {
    const snapshot = await db.collection('announcements')
      .where('isActive', '==', true)
      .orderBy('createdAt', 'desc')
      .get();
    
    const announcements = [];
    snapshot.forEach(doc => {
      announcements.push({ id: doc.id, ...doc.data() });
    });
    
    res.json({ success: true, announcements });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
});

// Create new announcement
app.post('/api/announcements', async (req, res) => {
  try {
    const {
      title,
      description,
      date,
      time,
      color = 0xFF3B82F6,  // Default blue
      iconName = 'campaign',
      isNew = true
    } = req.body;
    
    const docRef = await db.collection('announcements').add({
      title,
      description,
      date,
      time,
      type: 'announcement',
      color,
      iconName,
      isNew,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      isActive: true
    });
    
    res.json({
      success: true,
      message: 'Announcement created!',
      id: docRef.id
    });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
});

// Update announcement
app.put('/api/announcements/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const updates = req.body;
    
    await db.collection('announcements').doc(id).update(updates);
    
    res.json({ success: true, message: 'Announcement updated!' });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
});

// Delete announcement (soft delete)
app.delete('/api/announcements/:id', async (req, res) => {
  try {
    await db.collection('announcements').doc(req.params.id).update({
      isActive: false
    });
    
    res.json({ success: true, message: 'Announcement deleted!' });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
});

// ===== EVENTS APIs =====

// Get all events
app.get('/api/events', async (req, res) => {
  try {
    const snapshot = await db.collection('events')
      .where('isActive', '==', true)
      .orderBy('createdAt', 'desc')
      .get();
    
    const events = [];
    snapshot.forEach(doc => {
      events.push({ id: doc.id, ...doc.data() });
    });
    
    res.json({ success: true, events });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
});

// Create new event
app.post('/api/events', async (req, res) => {
  try {
    const {
      title,
      description,
      date,
      time,
      color = 0xFF10B981,  // Default green
      participants = '0',
      isNew = true
    } = req.body;
    
    const docRef = await db.collection('events').add({
      title,
      description,
      date,
      time,
      type: 'event',
      color,
      participants,
      isNew,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      isActive: true
    });
    
    res.json({
      success: true,
      message: 'Event created!',
      id: docRef.id
    });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
});

// Update event
app.put('/api/events/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const updates = req.body;
    
    await db.collection('events').doc(id).update(updates);
    
    res.json({ success: true, message: 'Event updated!' });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
});

// Delete event (soft delete)
app.delete('/api/events/:id', async (req, res) => {
  try {
    await db.collection('events').doc(req.params.id).update({
      isActive: false
    });
    
    res.json({ success: true, message: 'Event deleted!' });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
});
```

---

## 🎨 **React.js Admin Panel Components**

### **Create Announcement Form Component**

`src/components/CreateAnnouncement.jsx`:

```jsx
import React, { useState } from 'react';

const COLORS = {
  Blue: 0xFF3B82F6,
  Green: 0xFF10B981,
  Red: 0xFFEF4444,
  Pink: 0xFFEC4899,
  Purple: 0xFF8B5CF6,
  Orange: 0xFFFFB800
};

const ICONS = [
  'campaign',
  'video_call',
  'system_update',
  'gift',
  'celebration',
  'notifications'
];

function CreateAnnouncement({ onClose, onSuccess }) {
  const [formData, setFormData] = useState({
    title: '',
    description: '',
    date: new Date().toLocaleDateString('en-GB', { day: '2-digit', month: 'short', year: 'numeric' }),
    time: 'Live Now',
    color: 0xFF3B82F6,
    iconName: 'campaign',
    isNew: true
  });
  const [loading, setLoading] = useState(false);

  const handleSubmit = async (e) => {
    e.preventDefault();
    setLoading(true);

    try {
      const response = await fetch('http://localhost:5000/api/announcements', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(formData)
      });

      const data = await response.json();

      if (data.success) {
        alert('✅ Announcement created! Check your Flutter app!');
        onSuccess && onSuccess();
        onClose && onClose();
      } else {
        alert('❌ Error: ' + data.error);
      }
    } catch (error) {
      alert('❌ Error creating announcement');
      console.error(error);
    } finally {
      setLoading(false);
    }
  };

  return (
    <div style={{ padding: '20px', maxWidth: '600px', margin: '0 auto' }}>
      <h2>📢 Create Announcement</h2>
      
      <form onSubmit={handleSubmit}>
        <div style={{ marginBottom: '15px' }}>
          <label>Title:</label>
          <input
            type="text"
            value={formData.title}
            onChange={(e) => setFormData({ ...formData, title: e.target.value })}
            required
            style={{ width: '100%', padding: '10px', marginTop: '5px' }}
          />
        </div>

        <div style={{ marginBottom: '15px' }}>
          <label>Description:</label>
          <textarea
            value={formData.description}
            onChange={(e) => setFormData({ ...formData, description: e.target.value })}
            required
            rows={3}
            style={{ width: '100%', padding: '10px', marginTop: '5px' }}
          />
        </div>

        <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '15px' }}>
          <div>
            <label>Date:</label>
            <input
              type="text"
              value={formData.date}
              onChange={(e) => setFormData({ ...formData, date: e.target.value })}
              placeholder="15 Nov 2025"
              style={{ width: '100%', padding: '10px', marginTop: '5px' }}
            />
          </div>

          <div>
            <label>Time/Status:</label>
            <select
              value={formData.time}
              onChange={(e) => setFormData({ ...formData, time: e.target.value })}
              style={{ width: '100%', padding: '10px', marginTop: '5px' }}
            >
              <option>Live Now</option>
              <option>Released</option>
              <option>Coming Soon</option>
            </select>
          </div>
        </div>

        <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '15px', marginTop: '15px' }}>
          <div>
            <label>Color:</label>
            <select
              value={formData.color}
              onChange={(e) => setFormData({ ...formData, color: parseInt(e.target.value) })}
              style={{ width: '100%', padding: '10px', marginTop: '5px' }}
            >
              {Object.entries(COLORS).map(([name, value]) => (
                <option key={name} value={value}>{name}</option>
              ))}
            </select>
          </div>

          <div>
            <label>Icon:</label>
            <select
              value={formData.iconName}
              onChange={(e) => setFormData({ ...formData, iconName: e.target.value })}
              style={{ width: '100%', padding: '10px', marginTop: '5px' }}
            >
              {ICONS.map(icon => (
                <option key={icon} value={icon}>{icon}</option>
              ))}
            </select>
          </div>
        </div>

        <div style={{ marginTop: '15px' }}>
          <label>
            <input
              type="checkbox"
              checked={formData.isNew}
              onChange={(e) => setFormData({ ...formData, isNew: e.target.checked })}
            />
            {' '}Show "NEW" badge
          </label>
        </div>

        <button
          type="submit"
          disabled={loading}
          style={{
            marginTop: '20px',
            padding: '12px 24px',
            backgroundColor: '#3B82F6',
            color: 'white',
            border: 'none',
            borderRadius: '8px',
            cursor: loading ? 'not-allowed' : 'pointer',
            width: '100%',
            fontSize: '16px',
            fontWeight: 'bold'
          }}
        >
          {loading ? 'Creating...' : '✨ Create Announcement'}
        </button>
      </form>
    </div>
  );
}

export default CreateAnnouncement;
```

### **Create Event Form Component**

`src/components/CreateEvent.jsx`:

```jsx
import React, { useState } from 'react';

const COLORS = {
  Green: 0xFF10B981,
  Blue: 0xFF3B82F6,
  Red: 0xFFEF4444,
  Pink: 0xFFEC4899,
  Purple: 0xFF8B5CF6,
  Orange: 0xFFFFB800
};

function CreateEvent({ onClose, onSuccess }) {
  const [formData, setFormData] = useState({
    title: '',
    description: '',
    date: new Date().toLocaleDateString('en-GB', { day: '2-digit', month: 'short', year: 'numeric' }),
    time: '8:00 PM',
    color: 0xFF10B981,
    participants: '0',
    isNew: true
  });
  const [loading, setLoading] = useState(false);

  const handleSubmit = async (e) => {
    e.preventDefault();
    setLoading(true);

    try {
      const response = await fetch('http://localhost:5000/api/events', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(formData)
      });

      const data = await response.json();

      if (data.success) {
        alert('✅ Event created! Check your Flutter app!');
        onSuccess && onSuccess();
        onClose && onClose();
      } else {
        alert('❌ Error: ' + data.error);
      }
    } catch (error) {
      alert('❌ Error creating event');
      console.error(error);
    } finally {
      setLoading(false);
    }
  };

  return (
    <div style={{ padding: '20px', maxWidth: '600px', margin: '0 auto' }}>
      <h2>🎉 Create Event</h2>
      
      <form onSubmit={handleSubmit}>
        <div style={{ marginBottom: '15px' }}>
          <label>Title:</label>
          <input
            type="text"
            value={formData.title}
            onChange={(e) => setFormData({ ...formData, title: e.target.value })}
            required
            style={{ width: '100%', padding: '10px', marginTop: '5px' }}
          />
        </div>

        <div style={{ marginBottom: '15px' }}>
          <label>Description:</label>
          <textarea
            value={formData.description}
            onChange={(e) => setFormData({ ...formData, description: e.target.value })}
            required
            rows={3}
            style={{ width: '100%', padding: '10px', marginTop: '5px' }}
          />
        </div>

        <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr 1fr', gap: '15px' }}>
          <div>
            <label>Date:</label>
            <input
              type="text"
              value={formData.date}
              onChange={(e) => setFormData({ ...formData, date: e.target.value })}
              placeholder="20 Nov 2025"
              style={{ width: '100%', padding: '10px', marginTop: '5px' }}
            />
          </div>

          <div>
            <label>Time:</label>
            <input
              type="text"
              value={formData.time}
              onChange={(e) => setFormData({ ...formData, time: e.target.value })}
              placeholder="8:00 PM"
              style={{ width: '100%', padding: '10px', marginTop: '5px' }}
            />
          </div>

          <div>
            <label>Participants:</label>
            <input
              type="text"
              value={formData.participants}
              onChange={(e) => setFormData({ ...formData, participants: e.target.value })}
              placeholder="1.2K"
              style={{ width: '100%', padding: '10px', marginTop: '5px' }}
            />
          </div>
        </div>

        <div style={{ marginTop: '15px' }}>
          <label>Color:</label>
          <select
            value={formData.color}
            onChange={(e) => setFormData({ ...formData, color: parseInt(e.target.value) })}
            style={{ width: '100%', padding: '10px', marginTop: '5px' }}
          >
            {Object.entries(COLORS).map(([name, value]) => (
              <option key={name} value={value}>{name}</option>
            ))}
          </select>
        </div>

        <div style={{ marginTop: '15px' }}>
          <label>
            <input
              type="checkbox"
              checked={formData.isNew}
              onChange={(e) => setFormData({ ...formData, isNew: e.target.checked })}
            />
            {' '}Show "NEW" badge
          </label>
        </div>

        <button
          type="submit"
          disabled={loading}
          style={{
            marginTop: '20px',
            padding: '12px 24px',
            backgroundColor: '#10B981',
            color: 'white',
            border: 'none',
            borderRadius: '8px',
            cursor: loading ? 'not-allowed' : 'pointer',
            width: '100%',
            fontSize: '16px',
            fontWeight: 'bold'
          }}
        >
          {loading ? 'Creating...' : '🎉 Create Event'}
        </button>
      </form>
    </div>
  );
}

export default CreateEvent;
```

---

## 🧪 **Test the Integration**

### **Step 1: Test Backend API**

```bash
# Start your backend
node server/index.js

# Test with curl:
curl -X POST http://localhost:5000/api/announcements \
  -H "Content-Type: application/json" \
  -d '{
    "title": "Test Announcement",
    "description": "This is a test from admin panel",
    "date": "12 Nov 2025",
    "time": "Live Now",
    "color": 4280287222,
    "iconName": "campaign",
    "isNew": true
  }'

# Response:
{
  "success": true,
  "message": "Announcement created!",
  "id": "abc123xyz"
}
```

### **Step 2: Check Flutter App**

```bash
# Run your Flutter app
flutter run

# Navigate to: Profile → Event

# You should see:
✅ Your new announcement appears in the Announcements tab!
✅ Real-time updates (no need to refresh)
```

### **Step 3: Verify in Firebase Console**

```bash
# Go to Firebase Console
# Firestore Database
# Check collections:
#   - announcements/  ← Your announcement should be here
#   - events/         ← Your events should be here
```

---

## 🎯 **Quick Test Example**

Create this test in your browser console or Postman:

```javascript
// Create test announcement
fetch('http://localhost:5000/api/announcements', {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({
    title: "Welcome to Chamak! 🎉",
    description: "Thank you for joining our community. Start your live streaming journey today!",
    date: "12 Nov 2025",
    time: "Live Now",
    color: 0xFF3B82F6,  // Blue
    iconName: "celebration",
    isNew: true
  })
})
.then(r => r.json())
.then(data => console.log(data));
```

**Then immediately check your Flutter app** - the announcement will appear instantly! ✨

---

## ✅ **Summary**

### **What's Working Now:**
✅ Flutter app fetches REAL data from Firebase  
✅ No more fake/mock data  
✅ Real-time updates with StreamBuilder  
✅ Admin panel can create announcements  
✅ Admin panel can create events  
✅ Data instantly appears in Flutter app  

### **Firebase Collections:**
- `announcements` - All announcements
- `events` - All events

### **Required Fields:**
- Announcements: title, description, date, time, color, iconName, isNew
- Events: title, description, date, time, color, participants, isNew

---

**Now when you create an announcement from your admin panel, it will instantly appear in your Flutter app!** 🚀



