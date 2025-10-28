# 🌐 Offline-First Architecture Guide

## Overview

Your X-Pro Delivery App now has **100% offline capability**! All operations are stored locally in ObjectBox and automatically synced to PocketBase when internet connection is available.

---

## 🎯 How It Works

### **Offline Mode:**
1. User performs actions (update delivery, add photos, etc.)
2. Operations are **queued locally** in SharedPreferences
3. Data is **saved to ObjectBox** (local database)
4. UI shows **sync status indicator** (orange banner)
5. App continues to work normally

### **Online Mode:**
1. Connection detected
2. **Automatic sync** starts
3. All queued operations sent to PocketBase
4. UI shows **syncing progress** (blue banner)
5. Success → Banner disappears
6. Failed operations → Retry automatically

---

## 📱 User Experience

### **What Users See:**

#### **Offline (No Internet):**
```
🟧 Working Offline - 5 pending
   All changes will sync when connected
   [5]
```

#### **Syncing (Uploading):**
```
🟦 Syncing...
   Synced 3/5 operations
   ████████░░ 60%
```

#### **All Synced:**
```
✅ All synced (banner disappears)
```

#### **Failed Operations:**
```
🟥 3 failed operations
   Some operations couldn't sync
   [Sync Now]
```

---

## 👨‍💻 How to Use in Your Code

### **1. Queue Operations (Create/Update/Delete)**

```dart
import 'package:x_pro_delivery_app/core/services/offline_sync_service.dart';
import 'package:uuid/uuid.dart';

final offlineSync = OfflineSyncService();

// Example: Update delivery status
Future<void> updateDeliveryStatus(String deliveryId, String status) async {
  try {
    // 1. Update local ObjectBox first
    await updateLocalDelivery(deliveryId, status);
    
    // 2. Queue operation for sync
    await offlineSync.queueOperation(
      OfflineOperation(
        id: const Uuid().v4(),
        type: OperationType.update,
        collection: 'delivery_data',
        recordId: deliveryId,
        data: {
          'status': status,
          'updated_at': DateTime.now().toIso8601String(),
        },
      ),
    );
    
    debugPrint('✅ Delivery status updated offline');
  } catch (e) {
    debugPrint('❌ Failed to update delivery: $e');
  }
}
```

### **2. Create New Record**

```dart
// Example: Add photo to delivery
Future<void> addDeliveryPhoto(String deliveryId, String photoPath) async {
  final photoId = const Uuid().v4();
  
  try {
    // 1. Save to local storage/ObjectBox
    await saveLocalPhoto(photoId, photoPath);
    
    // 2. Queue create operation
    await offlineSync.queueOperation(
      OfflineOperation(
        id: const Uuid().v4(),
        type: OperationType.create,
        collection: 'delivery_photos',
        recordId: photoId,
        data: {
          'id': photoId,
          'delivery': deliveryId,
          'photo': photoPath,
          'uploaded_at': DateTime.now().toIso8601String(),
        },
      ),
    );
    
    debugPrint('✅ Photo queued for upload');
  } catch (e) {
    debugPrint('❌ Failed to queue photo: $e');
  }
}
```

### **3. Delete Record**

```dart
// Example: Remove item
Future<void> removeItem(String itemId) async {
  try {
    // 1. Delete from local ObjectBox
    await deleteLocalItem(itemId);
    
    // 2. Queue delete operation
    await offlineSync.queueOperation(
      OfflineOperation(
        id: const Uuid().v4(),
        type: OperationType.delete,
        collection: 'invoice_items',
        recordId: itemId,
        data: {}, // Empty for delete
      ),
    );
    
    debugPrint('✅ Item deletion queued');
  } catch (e) {
    debugPrint('❌ Failed to queue deletion: $e');
  }
}
```

### **4. Upsert (Update or Create)**

```dart
// Example: Save trip coordinates
Future<void> saveTripCoordinate(String tripId, double lat, double lng) async {
  final coordId = const Uuid().v4();
  
  try {
    // 1. Save locally
    await saveLocalCoordinate(coordId, tripId, lat, lng);
    
    // 2. Queue upsert (will update if exists, create if not)
    await offlineSync.queueOperation(
      OfflineOperation(
        id: const Uuid().v4(),
        type: OperationType.upsert,
        collection: 'tripCoordinates',
        recordId: coordId,
        data: {
          'trip': tripId,
          'latitude': lat,
          'longitude': lng,
          'recordedAt': DateTime.now().toIso8601String(),
        },
      ),
    );
    
    debugPrint('✅ Coordinate queued');
  } catch (e) {
    debugPrint('❌ Failed to queue coordinate: $e');
  }
}
```

---

## 🔄 Manual Sync Control

### **Force Sync:**

```dart
// Trigger sync manually (e.g., on button press)
Future<void> handleSyncButtonPress() async {
  final result = await OfflineSyncService().syncAll();
  
  if (result.success) {
    print('✅ Synced ${result.processed} operations');
  } else {
    print('❌ Sync failed: ${result.message}');
    print('   Failed: ${result.failed} operations');
  }
}
```

### **Check Sync Status:**

```dart
// Get current sync status
void checkSyncStatus() {
  final status = OfflineSyncService().getCurrentStatus();
  
  print('Is Online: ${status.isOnline}');
  print('Is Syncing: ${status.isSyncing}');
  print('Queued Operations: ${status.queuedOperations}');
  print('Failed Operations: ${status.failedOperations}');
  print('Last Sync: ${status.lastSyncTime}');
}
```

### **Listen to Sync Status:**

```dart
// Listen to real-time sync updates
StreamSubscription? _syncSubscription;

void startListeningToSync() {
  _syncSubscription = OfflineSyncService()
      .syncStatusStream
      ?.listen((status) {
    print('Sync status changed:');
    print('  Online: ${status.isOnline}');
    print('  Syncing: ${status.isSyncing}');
    print('  Pending: ${status.queuedOperations}');
    
    if (status.message != null) {
      print('  Message: ${status.message}');
    }
    
    if (status.isSyncing && status.progress != null) {
      print('  Progress: ${(status.progress! * 100).toStringAsFixed(0)}%');
    }
  });
}

@override
void dispose() {
  _syncSubscription?.cancel();
  super.dispose();
}
```

---

## 🎨 UI Components

### **Sync Status Indicator (Top Banner)**

Already added to `main.dart`:
```dart
Column(
  children: [
    const OfflineBanner(),
    const SyncStatusIndicator(), // ← Shows sync status
    Expanded(child: child!),
  ],
)
```

### **Floating Sync Button (Optional)**

For pages where you want a prominent sync button:
```dart
import 'package:x_pro_delivery_app/core/common/widgets/sync_status_indicator.dart';

@override
Widget build(BuildContext context) {
  return Scaffold(
    body: Stack(
      children: [
        YourPageContent(),
        const SyncStatusButton(), // ← Floating button
      ],
    ),
  );
}
```

---

## 🔧 Advanced Features

### **Clear Queue (Admin Only)**

```dart
// Clear all pending operations (use with caution!)
await OfflineSyncService().clearQueue();
```

### **Clear Failed Operations**

```dart
// Clear failed operations after resolving issues
await OfflineSyncService().clearFailedOperations();
```

### **Retry Failed Operations**

Failed operations are automatically retried up to 3 times. After that, they're moved to the failed list. To retry them manually:

```dart
// Sync will retry all failed operations
await OfflineSyncService().syncAll();
```

---

## 📊 Monitoring & Debugging

### **Enable Debug Logs**

The system already prints detailed logs:
```
🔄 OfflineSyncService: Queuing operation: update delivery_data/abc123
✅ OfflineSyncService: Operation queued (5 total)
🔄 OfflineSyncService: Online - attempting immediate sync...
🚀 OfflineSyncService: Starting sync...
   📊 Queued operations: 5
🔄 OfflineSyncService: Processing 1/5: update delivery_data/abc123
✅ OfflineSyncService: Operation successful
✅ OfflineSyncService: Sync completed
   ✅ Processed: 5
   ❌ Failed: 0
   ⏱️ Duration: 2s
```

### **Monitor in Real-Time**

Add a debug screen to your app:
```dart
class SyncDebugScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sync Debug')),
      body: StreamBuilder<SyncStatus>(
        stream: OfflineSyncService().syncStatusStream,
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const CircularProgressIndicator();
          
          final status = snapshot.data!;
          
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildStatusCard('Connection', status.isOnline ? 'Online' : 'Offline'),
              _buildStatusCard('Syncing', status.isSyncing ? 'Yes' : 'No'),
              _buildStatusCard('Queued', '${status.queuedOperations}'),
              _buildStatusCard('Failed', '${status.failedOperations}'),
              _buildStatusCard('Last Sync', status.lastSyncTime?.toString() ?? 'Never'),
              if (status.message != null)
                _buildStatusCard('Message', status.message!),
            ],
          );
        },
      ),
    );
  }
  
  Widget _buildStatusCard(String label, String value) {
    return Card(
      child: ListTile(
        title: Text(label),
        trailing: Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }
}
```

---

## 🧪 Testing Offline Mode

### **Test Scenario 1: Basic Offline Operations**

1. **Turn off WiFi/Mobile Data**
2. Perform actions (update delivery, add notes, etc.)
3. Notice:
   - Orange "Working Offline" banner appears
   - Counter shows pending operations
   - App works normally
4. **Turn on WiFi/Mobile Data**
5. Notice:
   - Banner turns blue "Syncing..."
   - Progress bar shows sync progress
   - Banner disappears when done

### **Test Scenario 2: Long Offline Period**

1. **Turn off internet**
2. Perform 10-20 operations
3. Close app completely
4. Reopen app (still offline)
5. Notice:
   - Pending operations persisted
   - Counter shows correct number
6. **Turn on internet**
7. Watch automatic sync

### **Test Scenario 3: Sync Failure Recovery**

1. **Turn off internet**
2. Perform operation
3. **Turn on internet** (but with poor connection)
4. Notice:
   - Some operations may fail
   - Failed counter increases
   - Retry happens automatically
5. After 3 failed attempts:
   - Operation moves to "failed list"
   - Manual retry available

---

## 🔒 Data Consistency

### **Conflict Resolution**

The system uses **"Last Write Wins"** strategy:
- Latest update overwrites previous data
- Timestamps determine recency
- No merge conflicts (simple approach)

### **Data Integrity**

1. **Local First:**
   - All data saved to ObjectBox immediately
   - UI updates instantly
   
2. **Queue Second:**
   - Operation queued for sync
   - Persisted to SharedPreferences
   
3. **Sync Third:**
   - When online, sync to PocketBase
   - Failed operations retry automatically

---

## ⚙️ Configuration

### **Sync Interval**

Edit `lib/core/services/offline_sync_service.dart`:

```dart
// Change periodic sync interval (default: 5 minutes)
_periodicSyncTimer = Timer.periodic(
  const Duration(minutes: 5), // ← Change this
  (timer) async {
    if (_isOnline && !_isSyncing && _operationQueue.isNotEmpty) {
      await syncAll();
    }
  },
);
```

### **Retry Attempts**

```dart
// Change max retry attempts (default: 3)
if (operation.retryCount >= 3) { // ← Change this
  debugPrint('⚠️ Max retries reached');
  newFailedOps.add(operation);
}
```

### **Sync Delay**

```dart
// Change delay between operations (default: 100ms)
await Future.delayed(const Duration(milliseconds: 100)); // ← Change this
```

---

## 📋 Required Dependencies

Already added to `pubspec.yaml`:

```yaml
dependencies:
  connectivity_plus: ^5.0.0  # Network monitoring
  shared_preferences: ^2.2.0 # Persist queue
  pocketbase: ^0.18.0        # Backend sync
  objectbox: ^2.3.0          # Local database
  uuid: ^4.0.0               # Generate IDs
```

---

## 🚀 Best Practices

### **1. Always Update Local First**

```dart
// ✅ CORRECT
await updateLocalData(id, data);
await queueSyncOperation(id, data);

// ❌ WRONG
await queueSyncOperation(id, data);
// Missing local update!
```

### **2. Use Unique IDs**

```dart
// ✅ CORRECT - Generate ID first
final id = const Uuid().v4();
await saveLocal(id, data);
await queueOperation(id, data);

// ❌ WRONG - Auto-generated ID won't match
await saveLocal(autoId, data);
await queueOperation(differentId, data);
```

### **3. Handle Errors Gracefully**

```dart
try {
  await updateLocalData(id, data);
  await queueSyncOperation(id, data);
} catch (e) {
  // Show user-friendly error
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('Failed to save: $e')),
  );
}
```

### **4. Provide User Feedback**

```dart
// Show loading indicator
showDialog(context: context, builder: (_) => LoadingDialog());

try {
  await updateLocalData(id, data);
  await queueSyncOperation(id, data);
  
  Navigator.pop(context); // Close loading
  
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('✅ Saved offline')),
  );
} catch (e) {
  Navigator.pop(context);
  // Show error
}
```

---

## 📝 Example: Complete Delivery Update Flow

Here's a complete example showing offline-first delivery update:

```dart
import 'package:x_pro_delivery_app/core/services/offline_sync_service.dart';
import 'package:uuid/uuid.dart';

class DeliveryService {
  final _offlineSync = OfflineSyncService();
  
  /// Update delivery status (works offline!)
  Future<void> updateDeliveryStatus({
    required String deliveryId,
    required String status,
    String? notes,
    List<String>? photoUrls,
  }) async {
    try {
      // 1. Update local ObjectBox immediately
      final delivery = await getLocalDelivery(deliveryId);
      delivery.status = status;
      delivery.notes = notes;
      delivery.photoUrls = photoUrls;
      delivery.updatedAt = DateTime.now();
      await saveLocalDelivery(delivery);
      
      // 2. Queue operation for PocketBase sync
      await _offlineSync.queueOperation(
        OfflineOperation(
          id: const Uuid().v4(),
          type: OperationType.update,
          collection: 'delivery_data',
          recordId: deliveryId,
          data: {
            'status': status,
            if (notes != null) 'notes': notes,
            if (photoUrls != null) 'photo_urls': photoUrls,
            'updated_at': DateTime.now().toIso8601String(),
          },
        ),
      );
      
      debugPrint('✅ Delivery $deliveryId updated to $status (offline-capable)');
      
      // 3. Create status history entry
      await _createStatusHistory(deliveryId, status);
      
    } catch (e, st) {
      debugPrint('❌ Failed to update delivery: $e\n$st');
      rethrow;
    }
  }
  
  /// Create status history entry
  Future<void> _createStatusHistory(String deliveryId, String status) async {
    final historyId = const Uuid().v4();
    
    try {
      // Save locally
      await saveLocalHistory(historyId, deliveryId, status);
      
      // Queue for sync
      await _offlineSync.queueOperation(
        OfflineOperation(
          id: const Uuid().v4(),
          type: OperationType.create,
          collection: 'delivery_history',
          recordId: historyId,
          data: {
            'id': historyId,
            'delivery': deliveryId,
            'status': status,
            'timestamp': DateTime.now().toIso8601String(),
          },
        ),
      );
    } catch (e) {
