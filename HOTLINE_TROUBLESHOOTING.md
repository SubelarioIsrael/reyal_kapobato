# Troubleshooting Hotline Profile Pictures

## Common Issues and Solutions

### Issue: Profile pictures not saving to database

This usually happens when the Supabase Storage bucket is not properly configured.

### Step-by-Step Solution

#### 1. Create Storage Bucket in Supabase Dashboard

1. Go to your Supabase project dashboard
2. Navigate to **Storage** in the left sidebar
3. Click **Create Bucket**
4. Set the following:
   - **Bucket Name**: `hotline-profiles`
   - **Public Bucket**: ✅ **Enable** (Check this box)
   - **File Size Limit**: Leave default or set to 5MB
5. Click **Create Bucket**

#### 2. Configure Storage Policies

After creating the bucket, you need to set up Row Level Security (RLS) policies:

1. In the Storage section, click on your `hotline-profiles` bucket
2. Click on **Policies** tab
3. Add the following policies:

**Policy 1: Allow Public Reads**
- **Policy Name**: `Allow public downloads`
- **Allowed Operation**: `SELECT`
- **Target Roles**: `public`
- **Policy**: `true` (or leave empty)

**Policy 2: Allow Authenticated Uploads**
- **Policy Name**: `Allow authenticated uploads`
- **Allowed Operation**: `INSERT`
- **Target Roles**: `authenticated`
- **Policy**: `true` (or leave empty)

**Policy 3: Allow Authenticated Updates**
- **Policy Name**: `Allow authenticated updates`
- **Allowed Operation**: `UPDATE`
- **Target Roles**: `authenticated`
- **Policy**: `true` (or leave empty)

**Policy 4: Allow Authenticated Deletes**
- **Policy Name**: `Allow authenticated deletes`
- **Allowed Operation**: `DELETE`
- **Target Roles**: `authenticated`
- **Policy**: `true` (or leave empty)

#### 3. Test the Storage Connection

1. In the app, go to **Admin Dashboard** → **Manage Hotlines**
2. Look for the cloud upload icon (☁️📤) in the top-right corner of the app bar
3. Tap it to run a storage connection test
4. You should see either:
   - ✅ "Storage connection test successful!" (Green message)
   - ❌ "Storage test failed: [error message]" (Red message)

#### 4. Check Your Supabase URL and Anon Key

Make sure your `.env` file or configuration has the correct:
- `SUPABASE_URL`
- `SUPABASE_ANON_KEY`

These should match your project settings in the Supabase dashboard.

### Debugging Steps

#### Enable Debug Mode
The app now includes detailed logging. Check the console/debug output for:
```
Starting image upload: [filename]
Upload response: [response]
Generated public URL: [url]
Database insert response: [response]
```

#### Common Error Messages

**"Storage bucket not configured"**
- Solution: Follow Step 1 above to create the bucket

**"403 Forbidden" or "Unauthorized"**
- Solution: Check your policies (Step 2) and ensure the bucket is public

**"404 Not Found"**
- Solution: Verify bucket name is exactly `hotline-profiles`

**"Failed to upload image: StorageException"**
- Solution: Check your internet connection and Supabase project status

#### Manual Test SQL Query

You can test if the database column exists by running this in your Supabase SQL editor:

```sql
-- Check if profile_picture column exists
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'mental_health_hotlines' 
AND column_name = 'profile_picture';

-- Check current hotlines and their profile pictures
SELECT hotline_id, name, profile_picture 
FROM mental_health_hotlines 
ORDER BY created_at DESC;
```

### Quick Fix Checklist

- [ ] Storage bucket `hotline-profiles` exists
- [ ] Bucket is set to **public**
- [ ] RLS policies are configured for public read, authenticated write
- [ ] Database has `profile_picture` column (TEXT type)
- [ ] Supabase URL and keys are correct
- [ ] Internet connection is stable
- [ ] Test storage connection shows success

### Still Having Issues?

1. **Check Supabase Logs**: Go to your Supabase dashboard → Logs → Storage
2. **Check Database Logs**: Go to your Supabase dashboard → Logs → Database
3. **Verify Project Status**: Ensure your Supabase project is active and not paused
4. **Test with Different Image**: Try a smaller image (under 1MB)

### Contact Support

If none of these solutions work, please provide:
1. The exact error message from the debug console
2. Screenshot of your Storage bucket configuration
3. Screenshot of your Storage policies
4. Result of the storage connection test