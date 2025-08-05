import 'package:flutter/foundation.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/delivery_data/data/model/delivery_data_model.dart';
import 'package:x_pro_delivery_app/core/errors/exceptions.dart';
import 'package:x_pro_delivery_app/objectbox.g.dart';

import '../../../../../../../../enums/invoice_status.dart';
import '../../../../delivery_update/data/models/delivery_update_model.dart';
import '../../../../trip/data/models/trip_models.dart';
import '../../../../customer_data/data/model/customer_data_model.dart';
import '../../../../invoice_data/data/model/invoice_data_model.dart';
import '../../../../invoice_items/data/model/invoice_items_model.dart';

abstract class DeliveryDataLocalDataSource {

   Future<void> syncDeliveryDataByTripId(String tripId, List<DeliveryDataModel> deliveryData);
  // Get all delivery data
  Future<List<DeliveryDataModel>> getAllDeliveryData();

  // Get all delivery data by trip ID
  Future<List<DeliveryDataModel>> getDeliveryDataByTripId(String tripId);

  // Get delivery data by ID
  Future<DeliveryDataModel> getDeliveryDataById(String id);

  // Cache delivery data
  Future<void> cacheDeliveryData(List<DeliveryDataModel> deliveryData);

  // Update delivery data
  Future<void> updateDeliveryData(DeliveryDataModel deliveryData);

  // Delete delivery data
  Future<bool> deleteDeliveryData(String id);

  Future<int> calculateDeliveryTimeByDeliveryId(String deliveryId);
}

class DeliveryDataLocalDataSourceImpl implements DeliveryDataLocalDataSource {
  final Box<DeliveryDataModel> _deliveryDataBox;
  List<DeliveryDataModel>? _cachedDeliveryData;
 final Store _store; // Add Store reference
  DeliveryDataLocalDataSourceImpl(this._deliveryDataBox, this._store);

   @override
Future<List<DeliveryDataModel>> getDeliveryDataByTripId(String tripId) async {
  try {
    debugPrint('📱 LOCAL: Fetching delivery data for trip ID: $tripId');

    final query = _deliveryDataBox.query(DeliveryDataModel_.tripId.equals(tripId));
    final deliveryDataList = query.build().find();

    debugPrint('📊 Storage Stats:');
    debugPrint('Total stored delivery data: ${_deliveryDataBox.count()}');
    debugPrint('Found delivery data for trip: ${deliveryDataList.length}');

    // Process each delivery data to ensure all relationships are loaded
    final processedDeliveryData = <DeliveryDataModel>[];
    
    for (var deliveryData in deliveryDataList) {
      // Check if delivery data has valid ID before processing
      if (deliveryData.id == null || deliveryData.id!.isEmpty) {
        debugPrint('⚠️ Skipping delivery data with null/empty ID');
        continue;
      }
      
      final processedData = await _loadCompleteDeliveryData(deliveryData);
      processedDeliveryData.add(processedData);
      
      debugPrint('🔍 Delivery ${processedDeliveryData.length}:');
      debugPrint('   📦 ID: ${processedData.id}');
      debugPrint('   📦 ObjectBox ID: ${processedData.objectBoxId}');
      debugPrint('   👤 Customer Target: ${processedData.customer.target != null ? "Loaded" : "null"}');
      debugPrint('   🏪 Customer Store Name: ${processedData.customer.target?.name ?? "null"}');
      debugPrint('   📍 Customer Address: ${processedData.customer.target?.province ?? "null"}');
      debugPrint('   📄 Invoice Target: ${processedData.invoice.target != null ? "Loaded" : "null"}');
      debugPrint('   💳 Payment Mode: ${processedData.paymentMode ?? "null"}');
      debugPrint('   💰 Payment Selection: ${processedData.paymentSelection?.name ?? "null"}');
      debugPrint('   📋 Invoice Status: ${processedData.invoiceStatus?.name ?? "null"}');
      debugPrint('   🚚 Delivery Number: ${processedData.deliveryNumber ?? "null"}');
      debugPrint('   ⏱️ Total Delivery Time: ${processedData.totalDeliveryTime ?? "null"}');
      debugPrint('   🔄 Delivery Updates: ${processedData.deliveryUpdates.length}');
      debugPrint('   📦 Invoice Items: ${processedData.invoiceItems.length}');
    }

    _cachedDeliveryData = processedDeliveryData;
    return processedDeliveryData;
  } catch (e) {
    debugPrint('❌ LOCAL: Query error: ${e.toString()}');
    throw CacheException(message: e.toString());
  }
}


   @override
  Future<void> syncDeliveryDataByTripId(String tripId, List<DeliveryDataModel> deliveryData) async {
    try {
      debugPrint('💾 LOCAL: Starting delivery data sync for trip: $tripId');
      debugPrint('📥 LOCAL: Received ${deliveryData.length} delivery data items to sync');

      // Clear existing delivery data for this trip
      await _cleanupDeliveryDataByTripId(tripId);

      // Prepare delivery data for storage
      final validDeliveryData = deliveryData.map((data) {
        // Ensure tripId is set if trip is assigned
        if (data.trip.target != null) {
          data.tripId = data.trip.target?.id;
        } else {
          data.tripId = tripId; // Set tripId directly if trip target is null
        }
        return data;
      }).toList();

      // Store synced delivery data
      _deliveryDataBox.putMany(validDeliveryData);

      final cachedCount = _deliveryDataBox
          .query(DeliveryDataModel_.tripId.equals(tripId))
          .build()
          .count();

      debugPrint('✅ LOCAL: Sync verification: $cachedCount delivery data items stored for trip: $tripId');
      debugPrint('📊 LOCAL: Sync Stats:');
      debugPrint('   📦 Total synced: ${validDeliveryData.length}');
      debugPrint('   ✅ Successfully stored: $cachedCount');
      debugPrint('   🎫 Trip ID: $tripId');

      // Update cached data
      _cachedDeliveryData = _deliveryDataBox.getAll();
      debugPrint('🔄 LOCAL: Cache memory updated with synced data');

    } catch (e) {
      debugPrint('❌ LOCAL: Sync failed for trip $tripId: ${e.toString()}');
      throw CacheException(message: e.toString());
    }
  }

Future<void> _cleanupDeliveryDataByTripId(String tripId) async {
    try {
      debugPrint('🧹 LOCAL: Cleaning up existing delivery data for trip: $tripId');
      
      final existingData = _deliveryDataBox
          .query(DeliveryDataModel_.tripId.equals(tripId))
          .build()
          .find();

      if (existingData.isNotEmpty) {
        final idsToRemove = existingData.map((data) => data.objectBoxId).toList();
        _deliveryDataBox.removeMany(idsToRemove);
        debugPrint('🗑️ LOCAL: Removed ${existingData.length} existing delivery data records for trip: $tripId');
      } else {
        debugPrint('ℹ️ LOCAL: No existing delivery data found for trip: $tripId');
      }
    } catch (e) {
      debugPrint('❌ LOCAL: Cleanup failed for trip $tripId: ${e.toString()}');
      throw CacheException(message: e.toString());
    }
  }

  @override
  Future<List<DeliveryDataModel>> getAllDeliveryData() async {
    try {
      debugPrint('📱 LOCAL: Fetching all delivery data');

      final query =
          _deliveryDataBox
              .query(DeliveryDataModel_.pocketbaseId.equals('id'))
              .build();
      final deliveryData = query.find();

      debugPrint('📊 Storage Stats:');
      debugPrint('Total stored delivery data: ${_deliveryDataBox.count()}');
      debugPrint('Found unassigned delivery data: ${deliveryData.length}');

      _cachedDeliveryData = deliveryData;
      return deliveryData;
    } catch (e) {
      debugPrint('❌ LOCAL: Query error: ${e.toString()}');
      throw CacheException(message: e.toString());
    }
  }
Future<DeliveryDataModel> _loadCompleteDeliveryData(DeliveryDataModel deliveryData) async {
    try {
      debugPrint('🔄 Loading complete delivery data for: ${deliveryData.id}');
      
      // Load customer data if not already loaded
      if (deliveryData.customer.target == null && deliveryData.customer.targetId > 0) {
        final customerBox = _store.box<CustomerDataModel>();
        final customer = customerBox.get(deliveryData.customer.targetId);
        if (customer != null) {
          deliveryData.customer.target = customer;
          debugPrint('✅ Loaded customer: ${customer.name}');
        } else {
          debugPrint('⚠️ Customer not found in local storage: ${deliveryData.customer.targetId}');
        }
      } else if (deliveryData.customer.targetId <= 0) {
        debugPrint('⚠️ Invalid customer targetId: ${deliveryData.customer.targetId}');
      }
      
      // Load invoice data if not already loaded
      if (deliveryData.invoice.target == null && deliveryData.invoice.targetId > 0) {
        final invoiceBox = _store.box<InvoiceDataModel>();
        final invoice = invoiceBox.get(deliveryData.invoice.targetId);
        if (invoice != null) {
          deliveryData.invoice.target = invoice;
          debugPrint('✅ Loaded invoice: ${invoice.name}');
        } else {
          debugPrint('⚠️ Invoice not found in local storage: ${deliveryData.invoice.targetId}');
        }
      } else if (deliveryData.invoice.targetId <= 0) {
        debugPrint('⚠️ Invalid invoice targetId: ${deliveryData.invoice.targetId}');
      }
      
      // Load trip data if not already loaded
      if (deliveryData.trip.target == null && deliveryData.trip.targetId > 0) {
        final tripBox = _store.box<TripModel>();
        final trip = tripBox.get(deliveryData.trip.targetId);
        if (trip != null) {
          deliveryData.trip.target = trip;
          debugPrint('✅ Loaded trip: ${trip.tripNumberId}');
        } else {
          debugPrint('⚠️ Trip not found in local storage: ${deliveryData.trip.targetId}');
        }
      } else if (deliveryData.trip.targetId <= 0) {
        debugPrint('⚠️ Invalid trip targetId: ${deliveryData.trip.targetId}');
      }
      
      // Load delivery updates if not already loaded
      if (deliveryData.deliveryUpdates.isEmpty) {
        final deliveryUpdateBox = _store.box<DeliveryUpdateModel>();
        
        // Query delivery updates by customer field (which should match delivery data pocketbaseId)
        if (deliveryData.pocketbaseId.isNotEmpty) {
          final updates = deliveryUpdateBox.query(
            DeliveryUpdateModel_.customer.equals(deliveryData.pocketbaseId)
          ).build().find();
          
          if (updates.isNotEmpty) {
            deliveryData.deliveryUpdates.addAll(updates);
            debugPrint('✅ Loaded ${updates.length} delivery updates for customer: ${deliveryData.pocketbaseId}');
          } else {
            debugPrint('⚠️ No delivery updates found for customer: ${deliveryData.pocketbaseId}');
          }
        } else {
          debugPrint('⚠️ Empty pocketbaseId for delivery data: ${deliveryData.id}');
        }
      }
      
      // Load invoice items if not already loaded
      if (deliveryData.invoiceItems.isEmpty && deliveryData.invoice.target != null) {
        final invoiceItemsBox = _store.box<InvoiceItemsModel>();
        
        // Only query if we have a valid invoice pocketbaseId
        if (deliveryData.invoice.target!.pocketbaseId.isNotEmpty) {
          final items = invoiceItemsBox.query(
            InvoiceItemsModel_.pocketbaseId.equals(deliveryData.invoice.target!.pocketbaseId)
          ).build().find();
          
          if (items.isNotEmpty) {
            deliveryData.invoiceItems.addAll(items);
            debugPrint('✅ Loaded ${items.length} invoice items');
          }
        } else {
          debugPrint('⚠️ Empty invoice pocketbaseId for delivery data: ${deliveryData.id}');
        }
      }
      
      // Set delivery number if missing
      if (deliveryData.deliveryNumber == null || deliveryData.deliveryNumber!.isEmpty) {
        if (deliveryData.pocketbaseId.isNotEmpty) {
          deliveryData.deliveryNumber = 'DEL-${deliveryData.pocketbaseId.substring(0, 8).toUpperCase()}';
          debugPrint('✅ Generated delivery number: ${deliveryData.deliveryNumber}');
        } else {
          deliveryData.deliveryNumber = 'DEL-${DateTime.now().millisecondsSinceEpoch}';
          debugPrint('✅ Generated fallback delivery number: ${deliveryData.deliveryNumber}');
        }
      }
      
      // Set default invoice status if missing
      if (deliveryData.invoiceStatus == null) {
        deliveryData.invoiceStatus = InvoiceStatus.none;
        debugPrint('✅ Set default invoice status: ${deliveryData.invoiceStatus!.name}');
      }
      
      // Save the updated delivery data only if it has a valid objectBoxId
      if (deliveryData.objectBoxId > 0) {
        _deliveryDataBox.put(deliveryData);
        debugPrint('✅ Updated delivery data saved to ObjectBox');
      } else {
        debugPrint('⚠️ Cannot save delivery data with invalid objectBoxId: ${deliveryData.objectBoxId}');
      }
      
      debugPrint('✅ Complete delivery data loaded for: ${deliveryData.id}');
      return deliveryData;
      
    } catch (e) {
      debugPrint('❌ Failed to load complete delivery data: $e');
      debugPrint('   - Delivery ID: ${deliveryData.id}');
      debugPrint('   - ObjectBox ID: ${deliveryData.objectBoxId}');
      debugPrint('   - Customer targetId: ${deliveryData.customer.targetId}');
      debugPrint('   - Invoice targetId: ${deliveryData.invoice.targetId}');
      debugPrint('   - Trip targetId: ${deliveryData.trip.targetId}');
      
      // Return original data if loading fails to prevent crashes
      return deliveryData;
    }
  }

  // Helper method to store related entities



  @override
  Future<DeliveryDataModel> getDeliveryDataById(String id) async {
    try {
      debugPrint('📱 LOCAL: Fetching delivery data with ID: $id');

      final deliveryData =
          _deliveryDataBox
              .query(DeliveryDataModel_.pocketbaseId.equals(id))
              .build()
              .findFirst();

      if (deliveryData != null) {
        debugPrint('✅ LOCAL: Found delivery data in local storage');
        
        // Load complete delivery data with all relationships
        final completeDeliveryData = await _loadCompleteDeliveryData(deliveryData);
        debugPrint('✅ LOCAL: Loaded complete delivery data with relationships');
        
        return completeDeliveryData;
      }

      throw const CacheException(
        message: 'Delivery data not found in local storage',
      );
    } catch (e) {
      debugPrint('❌ LOCAL: Query error: ${e.toString()}');
      throw CacheException(message: e.toString());
    }
  }

  @override
  Future<int> calculateDeliveryTimeByDeliveryId(String deliveryId) async {
    try {
      debugPrint(
        '📱 LOCAL: Calculating delivery time for delivery data: $deliveryId',
      );

      final deliveryData =
          _deliveryDataBox
              .query(DeliveryDataModel_.pocketbaseId.equals(deliveryId))
              .build()
              .findFirst();

      if (deliveryData == null) {
        throw const CacheException(
          message: 'Delivery data not found in local storage',
        );
      }

      final updates = deliveryData.deliveryUpdates.toList();
      if (updates.isEmpty) {
        debugPrint(
          '⚠️ LOCAL: No delivery updates found for delivery data: $deliveryId',
        );
        return 0;
      }

      // Sort updates by time
      updates.sort((a, b) => a.time!.compareTo(b.time!));

      // Find the "arrived" status
      final arrivedIndex = updates.indexWhere(
        (update) => update.title?.toLowerCase().trim() == 'arrived',
      );

      if (arrivedIndex == -1) {
        debugPrint(
          '⚠️ LOCAL: No "arrived" status found for delivery data: $deliveryId',
        );
        return 0;
      }

      // Check for undelivered status
      final undeliveredIndex = updates.indexWhere(
        (update) => update.title?.toLowerCase().trim() == 'mark as undelivered',
      );

      // Get end delivery status
      final endDeliveryIndex = updates.indexWhere(
        (update) => update.title?.toLowerCase().trim() == 'end delivery',
      );

      // Get mark as received status
      final receivedIndex = updates.indexWhere(
        (update) => update.title?.toLowerCase().trim() == 'mark as received',
      );

      // Determine relevant updates based on delivery scenario
      List<DeliveryUpdateModel> relevantUpdates;
      if (undeliveredIndex != -1) {
        // Undelivered scenario - calculate until mark as undelivered
        relevantUpdates =
            updates.sublist(arrivedIndex, undeliveredIndex + 1)
                as List<DeliveryUpdateModel>;
        debugPrint('📊 LOCAL: Calculating time for undelivered scenario');
      } else if (receivedIndex != -1) {
        // Received scenario - calculate until mark as received
        relevantUpdates =
            updates.sublist(arrivedIndex, undeliveredIndex + 1)
                as List<DeliveryUpdateModel>;
        debugPrint('📊 LOCAL: Calculating time for received scenario');
      } else if (endDeliveryIndex != -1) {
        // Normal delivery - include end delivery
        relevantUpdates =
            updates.sublist(arrivedIndex, undeliveredIndex + 1)
                as List<DeliveryUpdateModel>;
        debugPrint('📊 LOCAL: Calculating time for normal delivery scenario');
      } else {
        // Fallback to all updates from arrived
        relevantUpdates =
            updates.sublist(arrivedIndex, undeliveredIndex + 1)
                as List<DeliveryUpdateModel>;
        debugPrint('📊 LOCAL: Calculating time for ongoing delivery scenario');
      }

      double totalSeconds = 0;
      for (int i = 0; i < relevantUpdates.length - 1; i++) {
        final currentTime = relevantUpdates[i].time!;
        final nextTime = relevantUpdates[i + 1].time!;
        final diffInSeconds = nextTime.difference(currentTime).inSeconds;
        totalSeconds += diffInSeconds;

        debugPrint(
          'LOCAL: Status: ${relevantUpdates[i].title} -> ${relevantUpdates[i + 1].title}',
        );
        debugPrint(
          'LOCAL: Time: ${_formatTime(currentTime)} -> ${_formatTime(nextTime)}',
        );
        debugPrint(
          'LOCAL: Difference: ${diffInSeconds ~/ 60} minutes ${diffInSeconds % 60} seconds\n',
        );
      }

      final totalMinutes = (totalSeconds / 60).round();

      debugPrint(
        '✅ LOCAL: Total delivery time calculated: $totalMinutes minutes ($totalSeconds seconds)',
      );

      // Cache the calculated time in the delivery data model
      deliveryData.totalDeliveryTime =
          '${totalMinutes ~/ 60}h ${totalMinutes % 60}m';
      _deliveryDataBox.put(deliveryData);

      return totalMinutes;
    } catch (e) {
      debugPrint('❌ LOCAL: Failed to calculate delivery time: $e');
      throw CacheException(message: e.toString());
    }
  }

  String _formatTime(DateTime time) {
    return '${time.hour}:${time.minute.toString().padLeft(2, '0')}:${time.second.toString().padLeft(2, '0')}';
  }

  @override
  Future<void> cacheDeliveryData(List<DeliveryDataModel> deliveryData) async {
    try {
      debugPrint('💾 LOCAL: Starting delivery data caching process...');
      debugPrint(
        '📥 LOCAL: Received ${deliveryData.length} delivery data items to cache',
      );

      await _cleanupDeliveryData();
      await _autoSave(deliveryData);

      final cachedCount = _deliveryDataBox.count();
      debugPrint(
        '✅ LOCAL: Cache verification: $cachedCount delivery data items stored',
      );

      _cachedDeliveryData = deliveryData;
      debugPrint('🔄 LOCAL: Cache memory updated');
    } catch (e) {
      debugPrint('❌ LOCAL: Caching failed: ${e.toString()}');
      throw CacheException(message: e.toString());
    }
  }

  @override
  Future<void> updateDeliveryData(DeliveryDataModel deliveryData) async {
    try {
      debugPrint('📱 LOCAL: Updating delivery data: ${deliveryData.id}');

      // Ensure tripId is set if trip is assigned
      if (deliveryData.trip.target != null) {
        deliveryData.tripId = deliveryData.trip.target?.id;
      }

      _deliveryDataBox.put(deliveryData);
      debugPrint('✅ LOCAL: Delivery data updated in local storage');
    } catch (e) {
      debugPrint('❌ LOCAL: Update failed: ${e.toString()}');
      throw CacheException(message: e.toString());
    }
  }

  @override
  Future<bool> deleteDeliveryData(String id) async {
    try {
      debugPrint('📱 LOCAL: Deleting delivery data with ID: $id');

      final deliveryData =
          _deliveryDataBox
              .query(DeliveryDataModel_.pocketbaseId.equals(id))
              .build()
              .findFirst();

      if (deliveryData == null) {
        throw const CacheException(
          message: 'Delivery data not found in local storage',
        );
      }

      // Check if this delivery data is associated with a trip
      if (deliveryData.tripId != null && deliveryData.tripId!.isNotEmpty) {
        debugPrint(
          '⚠️ LOCAL: Cannot delete delivery data that is assigned to a trip',
        );
        throw const CacheException(
          message:
              'Cannot delete delivery data that is assigned to a trip. Please unassign it first.',
        );
      }

      _deliveryDataBox.remove(deliveryData.objectBoxId);
      debugPrint('✅ LOCAL: Successfully deleted delivery data');
      return true;
    } catch (e) {
      debugPrint('❌ LOCAL: Deletion failed: ${e.toString()}');
      throw CacheException(message: e.toString());
    }
  }

  Future<void> _cleanupDeliveryData() async {
    try {
      debugPrint('🧹 LOCAL: Starting delivery data cleanup process');
      final allDeliveryData = _deliveryDataBox.getAll();

      // Create a map to track unique delivery data by their PocketBase ID
      final Map<String?, DeliveryDataModel> uniqueDeliveryData = {};

      for (var data in allDeliveryData) {
        // Only keep valid delivery data with required fields
        if (_isValidDeliveryData(data)) {
          // If duplicate found, keep the most recently updated one
          final existingData = uniqueDeliveryData[data.pocketbaseId];
          if (existingData == null ||
              (data.updated?.isAfter(existingData.updated ?? DateTime(0)) ??
                  false)) {
            uniqueDeliveryData[data.pocketbaseId] = data;
          }
        }
      }

      // Clear all and save only valid unique delivery data
      _deliveryDataBox.removeAll();
      _deliveryDataBox.putMany(uniqueDeliveryData.values.toList());

      debugPrint('✨ LOCAL: Cleanup complete:');
      debugPrint('📊 Original count: ${allDeliveryData.length}');
      debugPrint('📊 After cleanup: ${uniqueDeliveryData.length}');
    } catch (e) {
      debugPrint('❌ LOCAL: Cleanup failed: ${e.toString()}');
      throw CacheException(message: e.toString());
    }
  }

  bool _isValidDeliveryData(DeliveryDataModel data) {
    return data.id != null && data.pocketbaseId.isNotEmpty;
  }

  Future<void> _autoSave(List<DeliveryDataModel> deliveryDataList) async {
    try {
      debugPrint(
        '🔍 LOCAL: Processing ${deliveryDataList.length} delivery data items',
      );

      final validDeliveryData =
          deliveryDataList.map((data) {
            // Ensure tripId is set if trip is assigned
            if (data.trip.target != null) {
              data.tripId = data.trip.target?.id;
            }
            return data;
          }).toList();

      _deliveryDataBox.putMany(validDeliveryData);
      _cachedDeliveryData = validDeliveryData;

      debugPrint('📊 LOCAL: Storage Stats:');
      debugPrint('Total Delivery Data: ${validDeliveryData.length}');
      debugPrint(
        'Valid Delivery Data: ${validDeliveryData.where((d) => d.id != null).length}',
      );
    } catch (e) {
      debugPrint('❌ LOCAL: Save operation failed: ${e.toString()}');
      throw CacheException(message: e.toString());
    }
  }
  
 
}
