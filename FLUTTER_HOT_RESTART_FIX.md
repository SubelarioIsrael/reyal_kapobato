# Flutter Hot Restart Black Screen Fix

## What Was Changed:
Added error handling and timeout protection to `initApp()` in `main.dart` to prevent hanging during hot restart.

## Root Cause:
When running `flutter run` while the app is already installed:
- Firebase/OneSignal try to re-initialize (causes conflicts)
- Supabase throws error if already initialized
- No timeout protection causes indefinite hanging
- Missing error boundaries cause black screen

## The Fix Applied:
1. ✅ Added timeout to Firebase initialization (10 seconds)
2. ✅ Added try-catch for OneSignal (continues if fails)
3. ✅ Added try-catch for Supabase (handles "already initialized" error)
4. ✅ Added global error handler (prevents crashes during init)
5. ✅ Added debug logging for troubleshooting

## Commands to Clear Issues:

### Option 1: Clean Build (Recommended)
```powershell
# Stop any running instances
flutter clean

# Clear build cache
Remove-Item -Recurse -Force build
Remove-Item -Recurse -Force android/app/build

# Rebuild
flutter pub get
flutter run
```

### Option 2: Full Uninstall & Reinstall
```powershell
# Find your package name
$packageName = "com.example.breathe_better"  # Update if different

# Uninstall from device
adb uninstall $packageName

# Clean build
flutter clean
flutter pub get
flutter run
```

### Option 3: Hot Restart Fix (Quick)
When you see black screen during `flutter run`:
```powershell
# In the Flutter console, press:
# R (capital R) - Hot restart
# or
# r (lowercase r) - Hot reload
```

### Option 4: Device Cache Clear
```powershell
# Clear app data on device without uninstalling
adb shell pm clear com.example.breathe_better

# Then hot restart
# Press 'R' in Flutter terminal
```

## Best Practices Going Forward:

### For Development:
1. **First run of the day**: Uninstall app from phone first
   ```powershell
   adb uninstall com.example.breathe_better
   flutter run
   ```

2. **During active development**: Use hot reload (`r`) instead of hot restart
   ```
   # In running Flutter app console:
   r  # Hot reload (faster, safer)
   R  # Hot restart (use sparingly)
   ```

3. **If black screen appears**:
   - Press `R` (hot restart) in Flutter console
   - If that fails, stop and `flutter run` again
   - If still fails, uninstall and reinstall

### Why Uninstall Works:
- Clears all cached app state
- Removes OneSignal/Firebase persistent data
- Resets Supabase client state
- Fresh initialization without conflicts

## Testing the Fix:

1. **First Test - Fresh Install:**
   ```powershell
   adb uninstall com.example.breathe_better
   flutter run
   # Should load properly ✅
   ```

2. **Second Test - Hot Restart:**
   ```powershell
   # Keep app running
   # Press 'R' in terminal
   # Should NOT show black screen anymore ✅
   ```

3. **Third Test - Reinstall Over Existing:**
   ```powershell
   # Stop Flutter
   flutter run
   # Should load faster than before with better error recovery ✅
   ```

## Debug Logging:

Check console output for:
```
✅ Firebase initialization timed out, continuing...
✅ OneSignal initialization error: ...
✅ Supabase initialization error (may already be initialized): ...
✅ Error during app initialization: ...
```

These are NORMAL and allow app to continue instead of hanging.

## If Issues Persist:

1. Check if multiple Flutter processes are running:
   ```powershell
   Get-Process flutter
   # Kill any old processes
   ```

2. Restart ADB:
   ```powershell
   adb kill-server
   adb start-server
   adb devices
   ```

3. Restart Android Studio/VS Code

4. Restart your phone

## Summary:
The code changes make your app resilient to hot restart conflicts. However, **for cleanest development workflow**:
- Uninstall before first `flutter run` each day
- Use hot reload (`r`) during development
- Only use hot restart (`R`) when necessary
