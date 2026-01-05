# Real-time Updates & Push Notifications Implementation

## ✅ What Has Been Implemented

### 1. Supabase Realtime Setup

**Tables Enabled for Realtime:**
- ✅ `counseling_appointments` - For appointment updates
- ✅ `user_notifications` - For notification updates  
- ✅ `messages` - For chat messages

**How to Enable in Supabase Dashboard:**
1. Go to **Database** → **Replication**
2. Find the `supabase_realtime` publication
3. Enable the tables listed above

---

### 2. Real-time Listeners Implemented

#### **For Students:**

**StudentNotificationButton** (`lib/components/student_notification_button.dart`)
- ✅ Auto-updates across ALL student pages
- ✅ Listens to `user_notifications` table filtered by user_id
- ✅ Updates notification count in real-time
- ✅ Works on all pages: Home, Appointments, Counselors, Journal, etc.

**StudentAppointments** (`lib/pages/student_new/student_appointments.dart`)
- ✅ Auto-updates when counselor accepts/rejects/completes appointment
- ✅ Listens to `counseling_appointments` table filtered by user_id
- ✅ No manual refresh needed

#### **For Counselors:**

**CounselorNotificationButton** (`lib/components/counselor_notification_button.dart`)
- ✅ Auto-updates when students book/cancel appointments
- ✅ Listens to `user_notifications` table filtered by user_id
- ✅ Updates notification count in real-time

**CounselorHome** (`lib/pages/counselor_new/counselor_home.dart`)
- ✅ Pending requests auto-appear when students book appointments
- ✅ Listens to `counseling_appointments` table filtered by counselor_id
- ✅ Triggers notification button refresh on new appointments

---

### 3. Push Notifications Implemented

All push notifications use **OneSignal** via Supabase Edge Function `send-notification`.

#### **For Students - Receive Push When:**

1. **Counselor Accepts Appointment**
   - Title: "Appointment Accepted"
   - Body: "Your appointment on [date] at [time] has been accepted."
   - Route: `/student_appointments`

2. **Counselor Rejects Appointment**
   - Title: "Appointment Rejected"
   - Body: "Your appointment on [date] at [time] has been rejected."
   - Route: `/student_appointments`

3. **Counselor Completes Session**
   - Title: "Appointment Completed"
   - Body: "Your appointment on [date] at [time] has been completed."
   - Route: `/student_appointments`

4. **Counselor Sends Chat Message**
   - Title: "New message from [Counselor Name]"
   - Body: [Message preview - first 50 characters]
   - Route: `/student_chat/[appointment_id]`

#### **For Counselors - Receive Push When:**

1. **Student Books New Appointment**
   - Title: "New Appointment Request"
   - Body: "[Student Name] booked an appointment with you on [date] at [time]."
   - Route: `/counselor-appointments`

2. **Student Cancels Appointment**
   - Title: "Appointment Cancelled"
   - Body: "Your appointment with [Student Name] on [date] at [time] has been cancelled."
   - Route: `/counselor_appointments`

3. **Student Sends Chat Message**
   - Title: "New message from [Student Name]"
   - Body: [Message preview - first 50 characters]
   - Route: `/counselor_chat/[appointment_id]`

---

### 4. In-App Notifications Created

All scenarios above also create in-app notifications in the `user_notifications` table:
- Stored with `is_read: false` initially
- Include `notification_type` for filtering
- Include `action_url` for navigation
- Auto-update in notification bell via real-time listener

---

## 🔧 Technical Implementation Details

### Real-time Channel Pattern
```dart
RealtimeChannel? _channel;

void _setupRealtimeListener() {
  final supabase = Supabase.instance.client;
  final userId = supabase.auth.currentUser?.id;

  if (userId != null) {
    _channel = supabase
        .channel('unique_channel_name')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'table_name',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'filter_column',
            value: userId,
          ),
          callback: (payload) {
            if (mounted) {
              _loadData(); // Refresh data
            }
          },
        )
        .subscribe();
  }
}

@override
void dispose() {
  _channel?.unsubscribe();
  super.dispose();
}
```

### Push Notification Pattern
```dart
await supabase.functions.invoke(
  'send-notification',
  body: {
    'user_id': targetUserId,
    'title': 'Notification Title',
    'body': 'Notification message',
    'data': {
      'type': 'notification_type',
      'route': '/target_route',
      // Additional custom data
    },
  },
);
```

---

## 📱 Student Notification Button - Special Implementation

The `StudentNotificationButton` widget appears on **multiple pages**:
- Student Home
- Student Appointments
- Student Counselors
- Student Journal
- Student Daily Check-in
- Student Wellness Resources
- Student Support Contacts
- Student Chatbot
- And more...

**How it auto-updates across all pages:**
1. Each instance is a `StatefulWidget`
2. Each instance sets up its own real-time listener in `initState()`
3. All instances listen to the same `user_notifications` table
4. When a new notification arrives, ALL instances receive the event
5. Each instance calls `setState()` to update its UI
6. Notification count badge updates on all pages simultaneously

**No special stream or singleton needed** - Supabase Realtime broadcasts to all active subscriptions!

---

## 🧪 Testing the Implementation

### Test Real-time Updates:

1. **Student Side:**
   - Open app on student account
   - Navigate to Appointments page
   - From another device/browser, login as counselor
   - Accept a student's pending appointment
   - **Expected:** Student's appointment status updates automatically without refresh

2. **Counselor Side:**
   - Open app on counselor account
   - Stay on Home page (view pending requests)
   - From another device, login as student
   - Book a new appointment
   - **Expected:** Counselor sees new pending request appear automatically
   - **Expected:** Notification bell count increases automatically

3. **Notification Bell (Multi-page):**
   - Login as student
   - Navigate between different pages (Home → Appointments → Journal)
   - From counselor account, accept an appointment
   - **Expected:** Notification badge updates on ALL pages without refresh

### Test Push Notifications:

1. **Prerequisites:**
   - Ensure OneSignal is initialized (`main.dart`)
   - Device must have push notification permission
   - App can be in background or closed

2. **Test Scenarios:**
   - Student books appointment → Counselor receives push
   - Counselor accepts appointment → Student receives push
   - Either party sends chat message → Other receives push
   - Student cancels appointment → Counselor receives push

---

## 🐛 Troubleshooting

### Real-time not working?

1. **Check Supabase Dashboard:**
   - Database → Replication
   - Verify `counseling_appointments` and `user_notifications` are in publication

2. **Check Console Logs:**
   - Look for "Setting up real-time listener" messages
   - Verify subscription success logs appear

3. **Check RLS Policies:**
   - Ensure Row Level Security allows SELECT for your user_id
   - Real-time events are blocked if RLS denies access

### Push notifications not working?

1. **Check OneSignal Setup:**
   - Verify app ID in `main.dart` is correct
   - Check device registered in `device_push_tokens` table

2. **Check Edge Function:**
   - Test `send-notification` function exists in Supabase
   - Check function logs for errors

3. **Check Device Token:**
   - Run app and check if `onesignal_player_id` is stored
   - Query: `SELECT * FROM device_push_tokens WHERE user_id = '[your-user-id]'`

### Notification bell not updating on all pages?

1. **Verify Real-time Enabled:**
   - Check `user_notifications` table has Realtime enabled

2. **Check Widget Implementation:**
   - Each page should use `const StudentNotificationButton()` OR `StudentNotificationButton()`
   - Don't use singleton/static instances

---

## 📝 Files Modified

### Controllers:
- `lib/controllers/counselor_appointments_controller.dart` - Added push notifications on status update
- `lib/controllers/student_appointments_controller.dart` - Added push notifications on cancel
- `lib/controllers/student_counselors_controller.dart` - Already had push on booking

### Components:
- `lib/components/counselor_notification_button.dart` - Real-time listener + proper cleanup
- `lib/components/student_notification_button.dart` - Real-time listener + proper cleanup

### Pages:
- `lib/pages/counselor_new/counselor_home.dart` - Real-time listener for appointments
- `lib/pages/student_new/student_appointments.dart` - Real-time listener for appointments
- `lib/pages/chat/appointment_chat.dart` - Push notifications on message send

---

## ✨ What This Achieves

### User Experience:
- ✅ **Zero manual refresh needed** - Everything updates automatically
- ✅ **Instant feedback** - See changes as they happen
- ✅ **Background notifications** - Get notified even when app is closed
- ✅ **Consistent experience** - Notification badge stays in sync across all pages

### Technical Benefits:
- ✅ **Real-time collaboration** - Student and counselor see updates simultaneously
- ✅ **Reduced server load** - No polling, only push updates
- ✅ **Better engagement** - Users stay informed via push notifications
- ✅ **Proper cleanup** - Channels unsubscribe on page disposal

---

## 🚀 Ready to Use!

The implementation is **complete and ready for production**. Just ensure:
1. Supabase Realtime is enabled on the required tables
2. OneSignal app ID is configured correctly
3. Edge Function `send-notification` is deployed

Hot restart your app and test it out! 🎉
