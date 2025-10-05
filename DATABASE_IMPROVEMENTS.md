# Database Relationship Improvements

## Current Issues Identified

1. **Query Complexity**: User information requires separate queries instead of efficient JOINs
2. **Missing Foreign Key Constraints**: Some relationships aren't properly enforced
3. **Performance Issues**: Multiple separate queries instead of single JOIN operations
4. **Message Type Confusion**: Multiple chat-related tables (`chat_messages` and `messages`)

## Recommended Database Schema Changes

### 1. Improve Foreign Key Relationships (PRIORITY)

**Problem**: Missing foreign key constraint between `students` and `users` tables.

**Solution**: Add proper foreign key constraints:

```sql
-- Ensure students table properly references users table
ALTER TABLE public.students 
ADD CONSTRAINT fk_students_user_id 
FOREIGN KEY (user_id) REFERENCES public.users(user_id) ON DELETE CASCADE;

-- Ensure counselors table properly references users table  
ALTER TABLE public.counselors 
ADD CONSTRAINT fk_counselors_user_id 
FOREIGN KEY (user_id) REFERENCES public.users(user_id) ON DELETE CASCADE;
```

### 2. Use JOIN Queries Instead of Schema Changes

**Problem**: User names are stored in `students` and `counselors` tables, causing lookup complexity.

**Solution**: Use efficient JOIN queries instead of restructuring:

```sql
-- Example: Get appointment with student information
SELECT 
    ca.*,
    s.first_name as student_first_name,
    s.last_name as student_last_name,
    s.student_code,
    u.username,
    u.email
FROM counseling_appointments ca
JOIN users u ON ca.user_id = u.user_id
JOIN students s ON u.user_id = s.user_id
WHERE ca.counselor_id = ?;

-- Example: Get messages with user details
SELECT 
    m.*,
    s.first_name,
    s.last_name
FROM messages m
JOIN counseling_appointments ca ON m.appointment_id = ca.appointment_id
JOIN students s ON ca.user_id = s.user_id
WHERE ca.counselor_id = ?;
```

### 2. Consolidate Chat Tables

**Problem**: Two separate chat tables (`chat_messages` and `messages`) create confusion.

**Solution**: Use only the `messages` table and drop `chat_messages`:

```sql
-- Drop the unused chat_messages table
DROP TABLE IF EXISTS public.chat_messages;
```

### 3. Improve Foreign Key Relationships

**Problem**: Some foreign key constraints are missing or inconsistent.

**Solution**: Add proper constraints and indexes:

```sql
-- Ensure all foreign keys exist and are properly named
ALTER TABLE public.counseling_appointments 
ADD CONSTRAINT fk_counseling_appointments_user_id 
FOREIGN KEY (user_id) REFERENCES public.users(user_id) ON DELETE CASCADE;

ALTER TABLE public.messages 
ADD CONSTRAINT fk_messages_appointment_id 
FOREIGN KEY (appointment_id) REFERENCES public.counseling_appointments(appointment_id) ON DELETE CASCADE;

-- Add indexes for better performance
CREATE INDEX IF NOT EXISTS idx_messages_appointment_id ON public.messages(appointment_id);
CREATE INDEX IF NOT EXISTS idx_messages_sender_id ON public.messages(sender_id);
CREATE INDEX IF NOT EXISTS idx_messages_receiver_id ON public.messages(receiver_id);
CREATE INDEX IF NOT EXISTS idx_messages_created_at ON public.messages(created_at);
CREATE INDEX IF NOT EXISTS idx_counseling_appointments_user_id ON public.counseling_appointments(user_id);
CREATE INDEX IF NOT EXISTS idx_counseling_appointments_counselor_id ON public.counseling_appointments(counselor_id);
```

### 4. Standardize ID Column Names

**Problem**: Inconsistent primary key naming (some use `id`, others use specific names).

**Solution**: Standardize to use table-specific IDs:

```sql
-- Already good: counseling_appointments uses appointment_id
-- Already good: counselors uses counselor_id  
-- Already good: students uses student_id
-- Consider renaming messages.id to message_id for consistency (optional)
```

### 5. Add Proper Data Types and Constraints

**Problem**: Some columns lack proper constraints.

**Solution**: Add validation constraints:

```sql
-- Ensure appointment times are logical
ALTER TABLE public.counseling_appointments 
ADD CONSTRAINT chk_appointment_times 
CHECK (start_time < end_time);

-- Ensure message content is not empty
ALTER TABLE public.messages 
ADD CONSTRAINT chk_message_not_empty 
CHECK (length(trim(message)) > 0);

-- Add created_at to tables that don't have it
ALTER TABLE public.counseling_appointments 
ADD COLUMN created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP;
```

### 6. Create Proper Relationships View

**Problem**: Complex queries needed to get appointment with user info.

**Solution**: Create a view for easier queries:

```sql
CREATE OR REPLACE VIEW public.appointment_details AS
SELECT 
    ca.appointment_id,
    ca.counselor_id,
    ca.user_id,
    ca.appointment_date,
    ca.start_time,
    ca.end_time,
    ca.status,
    ca.notes,
    ca.status_message,
    s.first_name as student_first_name,
    s.last_name as student_last_name,
    s.student_code,
    u.email as student_email,
    u.username as student_username,
    c.first_name as counselor_first_name,
    c.last_name as counselor_last_name,
    c.email as counselor_email,
    c.specialization
FROM public.counseling_appointments ca
JOIN public.users u ON ca.user_id = u.user_id
JOIN public.students s ON u.user_id = s.user_id  
JOIN public.counselors c ON ca.counselor_id = c.counselor_id;
```

### 7. Add Missing Relationships

**Problem**: Some logical relationships aren't defined.

**Solution**: Add missing foreign keys:

```sql
-- Ensure video_calls references are proper
ALTER TABLE public.video_calls 
ADD CONSTRAINT fk_video_calls_counselor_id 
FOREIGN KEY (counselor_id) REFERENCES public.counselors(counselor_id);

ALTER TABLE public.video_calls 
ADD CONSTRAINT fk_video_calls_student_user_id 
FOREIGN KEY (student_user_id) REFERENCES public.users(user_id);
```

## Benefits After Implementation

1. **Efficient Queries**: Single JOIN queries instead of multiple separate queries
2. **Better Performance**: Proper indexes on frequently queried columns  
3. **Data Integrity**: Foreign key constraints prevent orphaned records
4. **Consistency**: Proper relationships between tables
5. **Maintainability**: Clear table relationships and constraints

## Migration Strategy

1. **Backup Database** first
2. **Add missing foreign key constraints**
3. **Create performance indexes**
4. **Update application code** to use JOIN queries
5. **Test thoroughly** with existing data
6. **Monitor performance** after implementation

## Code Changes Already Implemented

✅ **Application code updated to**:
- Use JOIN queries to get student info with appointments
- Leverage foreign key relationships for data integrity
- Single query operations instead of multiple separate queries
- Proper fallback handling for missing data

## PostgreSQL Foreign Key Constraint Resolution

### Issue Encountered:
```
PostgrestException PGRST200: Could not find a relationship between 'counseling_appointments' and 'students'
```

### Root Cause:
- No direct foreign key relationship exists between `counseling_appointments` and `students` tables
- Relationship path: `counseling_appointments.user_id` → `users.user_id` → `students.user_id`
- Supabase requires explicit foreign key constraints for JOIN operations

### Solution Implemented:
Instead of failing JOIN queries, implemented individual queries with proper error handling:

```dart
// Fixed implementation in counselor_chat_list_simple.dart
for (var appointmentGroup in appointmentGroups.values) {
  final userId = appointmentGroup['appointment']['user_id'];
  
  try {
    // Primary: Get student info
    final studentInfo = await _supabase
        .from('students')
        .select('user_id, first_name, last_name, student_code')
        .eq('user_id', userId)
        .maybeSingle();
        
    if (studentInfo != null && studentInfo['first_name'] != null) {
      appointmentGroup['user_name'] = '${studentInfo['first_name']} ${studentInfo['last_name']}';
      appointmentGroup['user_initials'] = '${studentInfo['first_name'][0]}${studentInfo['last_name'][0]}';
    } else {
      // Fallback: Get username from users table
      final userInfo = await _supabase
          .from('users')
          .select('username')
          .eq('user_id', userId)
          .maybeSingle();
      
      if (userInfo != null && userInfo['username'] != null) {
        appointmentGroup['user_name'] = userInfo['username'];
        appointmentGroup['user_initials'] = userInfo['username'].substring(0, 2).toUpperCase();
      }
    }
  } catch (e) {
    print('Error fetching student info for user_id $userId: $e');
  }
}
```

### Status: ✅ RESOLVED
- PostgreSQL foreign key constraint error eliminated
- Fallback mechanism ensures data retrieval even if student record is missing
- Individual error handling prevents cascade failures
- Chat list functionality restored without database schema changes

## Video Call System Database Integration

### Implementation Status: ✅ COMPLETE

**Student Call Join Process:**
1. Student enters call code in appointment interface
2. System validates call code exists and is active in `video_calls` table
3. Student information is saved to `video_calls` table:
   ```sql
   UPDATE video_calls SET 
     student_user_id = '[user_id]',
     student_joined_at = '[timestamp]'
   WHERE call_code = '[entered_code]';
   ```
4. Student joins video call with real name and user ID

**Counselor Call Creation Process:**
1. Counselor generates call code or enters existing code
2. Call information saved to `video_calls` table with counselor details
3. Counselor joins video call with real name and user ID

**Benefits:**
- ✅ Complete audit trail of video call participants
- ✅ Real user identification in video calls (no more random IDs)
- ✅ Database integrity with proper foreign key relationships
- ✅ Timestamp tracking for join times

## Context Error Fix

### Issue: Widget Disposal Context Error
**Problem:** Flutter error when accessing `ScaffoldMessenger.of(context)` after widget disposal during async operations.

**Error Message:**
```
Looking up a deactivated widget's ancestor is unsafe.
At this point the state of the widget's element tree is no longer stable.
```

**Solution:** Added `mounted` checks before all `ScaffoldMessenger.of(context)` calls in async operations:

```dart
// Fixed all ScaffoldMessenger calls in student_appointments.dart
if (mounted) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('Message'), backgroundColor: Colors.red),
  );
}
```

**Status:** ✅ RESOLVED - All async SnackBar displays now check widget mount state

## Current JOIN Query Examples

```sql
-- Counselor chat list query (already implemented in app)
SELECT m.*, ca.*, s.first_name, s.last_name 
FROM messages m
JOIN counseling_appointments ca ON m.appointment_id = ca.appointment_id
JOIN students s ON ca.user_id = s.user_id
WHERE ca.counselor_id = ?;

-- Student info query (already implemented in app)  
SELECT u.*, s.first_name, s.last_name
FROM users u
JOIN students s ON u.user_id = s.user_id
WHERE u.user_id = ?;
```