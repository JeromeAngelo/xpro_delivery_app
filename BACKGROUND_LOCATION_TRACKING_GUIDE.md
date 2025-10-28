# 📍 Background Location Tracking Guide

## Problem Statement

Your current implementation has limitations:
- ❌ WorkManager only runs every 15 minutes (Android system limit)
- ❌ Doesn't work reliably when device sleeps
- ❌ App terminates tracking when closed
- ❌ No persistent notification for foreground service

## Solution: Foreground Service + WorkManager

For **accurate, continuous background tracking** even when app is closed/device sleeps, you need:

1. **Foreground Service** (primary) - Continuous tracking
2. **WorkManager** (backup) - Periodic checks when foreground service stops

---

## 🚀 Step 1: Add Required Packages

Update your `pubspec.yaml`:

```yaml
dependencies:
  geolocator: ^10.1.0
  workmanager: ^0.5.2
  # Add these for true background tracking:
  flutter_foreground_task: ^6.1.0  # For Android foreground service
  permission_handler: ^11.0.1       # For comprehensive permissions
  shared_preferences: ^2.2.2
  pocketbase: ^0.18.0
```

Then run:
```bash
flutter pub get
```

---

## 📱 Step 2: Update Android Configuration

### **A. Update `android/app/src/main/AndroidManifest.xml`**

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <application
        android:label="xpro_delivery"
        android:name="${applicationName}"
        android:icon="@mipmap/ic_launcher">
        
        <!-- ... existing activity ... -->
        
        <!-- ========================================= -->
        <!-- FOREGROUND SERVICE CONFIGURATION -->
        <!-- ========================================= -->
        
        <!-- Foreground service for background location -->
        <service
            android:name="com.pravera.flutter_foreground_task.service.ForegroundService"
            android:foregroundServiceType="location"
            android:exported="false" />
            
        <!-- WorkManager receiver -->
        <receiver
            android:name="androidx.work.impl.background.systemalarm.ConstraintProxy$NetworkStateProxyReceiver"
            android:enabled="true"
            android:exported="false"
            tools:replace="android:enabled">
            <intent-filter>
                <action android:name="android.intent.action.BATTERY_OKAY"/>
                <action android:name="android.intent.action.BATTERY_LOW"/>
            </intent-filter>
        </receiver>
    </application>

    <!-- ========================================= -->
    <!-- PERMISSIONS FOR BACKGROUND LOCATION -->
    <!-- ========================================= -->
    
    <!-- Normal location permissions -->
    <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
    <uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
    
    <!-- Background location (Android 10+) -->
    <uses-permission android:name="android.permission.ACCESS_BACKGROUND_LOCATION" />
    
    <!-- Foreground service -->
    <uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
    <uses-permission android:name="android.permission.FOREGROUND_SERVICE_LOCATION" />
    
    <!-- Wake lock to keep service alive -->
