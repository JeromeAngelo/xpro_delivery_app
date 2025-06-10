import 'package:flutter/material.dart';
import 'package:objectbox/objectbox.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/cancelled_invoices/data/model/cancelled_invoice_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/delivery_data/data/model/delivery_data_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/trip/data/models/trip_models.dart';
import 'package:x_pro_delivery_app/core/errors/exceptions.dart';

import '../../../../../../../../../objectbox.g.dart';

abstract class CancelledInvoiceLocalDataSource {
  // Get all cancelled invoices
  Future<List<CancelledInvoiceModel>> getAllCancelledInvoices();

  /// Load cancelled invoices by trip ID from local storage
  Future<List<CancelledInvoiceModel>> loadCancelledInvoicesByTripId(
    String tripId,
  );

  /// Load cancelled invoice by ID from local storage (returns single item)
  Future<CancelledInvoiceModel> loadCancelledInvoicesById(String id);

  /// Create cancelled invoice by delivery data ID in local storage
  Future<CancelledInvoiceModel> createCancelledInvoice(
    CancelledInvoiceModel cancelledInvoice,
    String deliveryDataId,
  );

  /// Delete cancelled invoice from local storage
  Future<bool> deleteCancelledInvoice(String cancelledInvoiceId);

  /// Cache cancelled invoices to local storage
  Future<void> cacheCancelledInvoices(
    List<CancelledInvoiceModel> cancelledInvoices,
  );

  /// Update cancelled invoice in local storage
  Future<void> updateCancelledInvoice(CancelledInvoiceModel cancelledInvoice);
}

class CancelledInvoiceLocalDataSourceImpl
    implements CancelledInvoiceLocalDataSource {
  final Box<CancelledInvoiceModel> _cancelledInvoiceBox;
  final Box<DeliveryDataModel> _deliveryDataBox;
  final Box<TripModel> _tripBox;
  List<CancelledInvoiceModel>? _cachedCancelledInvoices;

  CancelledInvoiceLocalDataSourceImpl({
    required Box<CancelledInvoiceModel> cancelledInvoiceBox,
    required Box<DeliveryDataModel> deliveryDataBox,
    required Box<TripModel> tripBox,
  }) : _cancelledInvoiceBox = cancelledInvoiceBox,
       _deliveryDataBox = deliveryDataBox,
       _tripBox = tripBox;

  @override
  Future<List<CancelledInvoiceModel>> getAllCancelledInvoices() async {
    try {
      debugPrint('📱 LOCAL: Fetching all cancelled invoices');

      final cancelledInvoices = _cancelledInvoiceBox.getAll();

      debugPrint('📊 Storage Stats:');
      debugPrint('Total stored cancelled invoices: ${_cancelledInvoiceBox.count()}');
      debugPrint('Found cancelled invoices: ${cancelledInvoices.length}');

      // Set up relations for each cancelled invoice
      for (final cancelledInvoice in cancelledInvoices) {
        _setupRelations(cancelledInvoice);
      }

      _cachedCancelledInvoices = cancelledInvoices;
      return cancelledInvoices;
    } catch (e) {
      debugPrint('❌ LOCAL: Query error: ${e.toString()}');
      throw CacheException(message: e.toString());
    }
  }

  @override
  Future<List<CancelledInvoiceModel>> loadCancelledInvoicesByTripId(
    String tripId,
  ) async {
    try {
      debugPrint('📱 LOCAL: Fetching cancelled invoices for trip ID: $tripId');

      final query =
          _cancelledInvoiceBox
              .query(CancelledInvoiceModel_.tripId.equals(tripId))
              .build();

      final cancelledInvoices = query.find();

      debugPrint('📊 Storage Stats:');
      debugPrint(
        'Total stored cancelled invoices: ${_cancelledInvoiceBox.count()}',
      );
      debugPrint(
        'Found cancelled invoices for trip: ${cancelledInvoices.length}',
      );

      // Set up relations for each cancelled invoice
      for (final cancelledInvoice in cancelledInvoices) {
        _setupRelations(cancelledInvoice);
      }

      return cancelledInvoices;
    } catch (e) {
      debugPrint('❌ LOCAL: Query error: ${e.toString()}');
      throw CacheException(message: e.toString());
    }
  }

  @override
  Future<CancelledInvoiceModel> loadCancelledInvoicesById(
    String id,
  ) async {
    try {
      debugPrint('📱 LOCAL: Fetching cancelled invoice with ID: $id');

      final cancelledInvoice =
          _cancelledInvoiceBox
              .query(CancelledInvoiceModel_.pocketbaseId.equals(id))
              .build()
              .findFirst();

      if (cancelledInvoice != null) {
        debugPrint('✅ LOCAL: Found cancelled invoice in local storage');
        _setupRelations(cancelledInvoice);
        return cancelledInvoice;
      }

      debugPrint('⚠️ LOCAL: Cancelled invoice not found: $id');
      throw const CacheException(
        message: 'Cancelled invoice not found in local storage',
      );
    } catch (e) {
      debugPrint('❌ LOCAL: Query error: ${e.toString()}');
      throw CacheException(message: e.toString());
    }
  }

  @override
  Future<CancelledInvoiceModel> createCancelledInvoice(
    CancelledInvoiceModel cancelledInvoice,
    String deliveryDataId,
  ) async {
    try {
      debugPrint(
        '📱 LOCAL: Creating cancelled invoice for delivery data: $deliveryDataId',
      );
      debugPrint(
        '📝 LOCAL: Reason: ${cancelledInvoice.reason.toString().split('.').last}',
      );

      // Generate a temporary ID for local storage
      final tempId = 'temp_cancelled_${DateTime.now().millisecondsSinceEpoch}';

      // Create a new model with the temp ID and delivery data ID
      final newCancelledInvoice = CancelledInvoiceModel(
        id: tempId,
        collectionId: 'cancelled_invoices',
        collectionName: 'cancelledInvoice',
        reason: cancelledInvoice.reason,
        image: cancelledInvoice.image,
        created: DateTime.now(),
        updated: DateTime.now(),
      );

      // Try to find delivery data to set up relations (optional)
      final deliveryDataModel =
          _deliveryDataBox
              .query(DeliveryDataModel_.pocketbaseId.equals(deliveryDataId))
              .build()
              .findFirst();

      if (deliveryDataModel != null) {
        debugPrint('🚛 LOCAL: Found delivery data, setting up relations');
        newCancelledInvoice.deliveryData.target = deliveryDataModel;

        // Set trip relation if available
        if (deliveryDataModel.trip.target != null) {
          newCancelledInvoice.trip.target = deliveryDataModel.trip.target;
          newCancelledInvoice.tripId =
              deliveryDataModel.trip.target?.pocketbaseId;
          debugPrint('🚛 LOCAL: Found trip ID: ${newCancelledInvoice.tripId}');
        } else {
          debugPrint(
            '⚠️ LOCAL: No trip relation found in delivery data, proceeding without trip',
          );
        }
      } else {
        debugPrint(
          '⚠️ LOCAL: Delivery data not found in local storage, proceeding without relations',
        );
      }

      // Store in local database
      final storedId = _cancelledInvoiceBox.put(newCancelledInvoice);
      newCancelledInvoice.objectBoxId = storedId;

      debugPrint('✅ LOCAL: Created cancelled invoice with local ID: $storedId');
      debugPrint('✨ LOCAL: Successfully created and stored cancelled invoice');

      return newCancelledInvoice;
    } catch (e) {
      debugPrint(
        '❌ LOCAL: Failed to create cancelled invoice: ${e.toString()}',
      );
      throw CacheException(message: e.toString());
    }
  }

  @override
  Future<bool> deleteCancelledInvoice(String cancelledInvoiceId) async {
    try {
      debugPrint('📱 LOCAL: Deleting cancelled invoice: $cancelledInvoiceId');

      final cancelledInvoice =
          _cancelledInvoiceBox
              .query(
                CancelledInvoiceModel_.pocketbaseId.equals(cancelledInvoiceId),
              )
              .build()
              .findFirst();

      if (cancelledInvoice == null) {
        debugPrint(
          '⚠️ LOCAL: Cancelled invoice not found: $cancelledInvoiceId',
        );
        return false;
      }

      final success = _cancelledInvoiceBox.remove(cancelledInvoice.objectBoxId);

      if (success) {
        debugPrint('✅ LOCAL: Successfully deleted cancelled invoice');
      } else {
        debugPrint('❌ LOCAL: Failed to delete cancelled invoice');
      }

      return success;
    } catch (e) {
      debugPrint(
        '❌ LOCAL: Failed to delete cancelled invoice: ${e.toString()}',
      );
      throw CacheException(message: e.toString());
    }
  }

  @override
  Future<void> cacheCancelledInvoices(
    List<CancelledInvoiceModel> cancelledInvoices,
  ) async {
    try {
      debugPrint('💾 LOCAL: Starting cancelled invoices caching process...');
      debugPrint(
        '📥 LOCAL: Received ${cancelledInvoices.length} cancelled invoices to cache',
      );

      await _cleanupCancelledInvoices();
      await _autoSave(cancelledInvoices);

      final cachedCount = _cancelledInvoiceBox.count();
      debugPrint(
        '✅ LOCAL: Cache verification: $cachedCount cancelled invoices stored',
      );

      _cachedCancelledInvoices = cancelledInvoices;
      debugPrint('🔄 LOCAL: Cache memory updated');
    } catch (e) {
      debugPrint('❌ LOCAL: Caching failed: ${e.toString()}');
      throw CacheException(message: e.toString());
    }
  }

  @override
  Future<void> updateCancelledInvoice(
    CancelledInvoiceModel cancelledInvoice,
  ) async {
    try {
      debugPrint(
        '📱 LOCAL: Updating cancelled invoice: ${cancelledInvoice.pocketbaseId}',
      );

      // Ensure tripId and deliveryDataId are set if relations are assigned
      if (cancelledInvoice.trip.target != null) {
        cancelledInvoice.tripId = cancelledInvoice.trip.target?.pocketbaseId;
      }
      if (cancelledInvoice.deliveryData.target != null) {
        cancelledInvoice.deliveryDataId =
            cancelledInvoice.deliveryData.target?.pocketbaseId;
      }

      _cancelledInvoiceBox.put(cancelledInvoice);
      debugPrint('✅ LOCAL: Cancelled invoice updated in local storage');
    } catch (e) {
      debugPrint('❌ LOCAL: Update failed: ${e.toString()}');
      throw CacheException(message: e.toString());
    }
  }

  Future<void> _cleanupCancelledInvoices() async {
    try {
      debugPrint('🧹 LOCAL: Starting cancelled invoices cleanup process');
      final allCancelledInvoices = _cancelledInvoiceBox.getAll();

      // Create a map to track unique cancelled invoices by their PocketBase ID
      final Map<String?, CancelledInvoiceModel> uniqueCancelledInvoices = {};

      for (var invoice in allCancelledInvoices) {
        // Only keep valid cancelled invoices with required fields
        if (_isValidCancelledInvoice(invoice)) {
          // If duplicate found, keep the most recently updated one
          final existingInvoice = uniqueCancelledInvoices[invoice.pocketbaseId];
          if (existingInvoice == null ||
              (invoice.updated?.isAfter(
                    existingInvoice.updated ?? DateTime(0),
                  ) ??
                  false)) {
            uniqueCancelledInvoices[invoice.pocketbaseId] = invoice;
          }
        }
      }

      // Clear all and save only valid unique cancelled invoices
      _cancelledInvoiceBox.removeAll();
      _cancelledInvoiceBox.putMany(uniqueCancelledInvoices.values.toList());

      debugPrint('✨ LOCAL: Cleanup complete:');
      debugPrint('📊 Original count: ${allCancelledInvoices.length}');
      debugPrint('📊 After cleanup: ${uniqueCancelledInvoices.length}');
    } catch (e) {
      debugPrint('❌ LOCAL: Cleanup failed: ${e.toString()}');
      throw CacheException(message: e.toString());
    }
  }

  bool _isValidCancelledInvoice(CancelledInvoiceModel invoice) {
    return invoice.id != null && invoice.pocketbaseId.isNotEmpty;
  }

  Future<void> _autoSave(
    List<CancelledInvoiceModel> cancelledInvoicesList,
  ) async {
    try {
      debugPrint(
        '🔍 LOCAL: Processing ${cancelledInvoicesList.length} cancelled invoices',
      );

      final validCancelledInvoices =
          cancelledInvoicesList.map((invoice) {
            // Ensure tripId and deliveryDataId are set if relations are assigned
            if (invoice.trip.target != null) {
              invoice.tripId = invoice.trip.target?.pocketbaseId;
            }
            if (invoice.deliveryData.target != null) {
              invoice.deliveryDataId =
                  invoice.deliveryData.target?.pocketbaseId;
            }
            return invoice;
          }).toList();

      _cancelledInvoiceBox.putMany(validCancelledInvoices);
      _cachedCancelledInvoices = validCancelledInvoices;

      debugPrint('📊 LOCAL: Storage Stats:');
      debugPrint('Total Cancelled Invoices: ${validCancelledInvoices.length}');
      debugPrint(
        'Valid Cancelled Invoices: ${validCancelledInvoices.where((i) => i.id != null).length}',
      );
      debugPrint(
        'With Trip Data: ${validCancelledInvoices.where((i) => i.tripId != null).length}',
      );
      debugPrint(
                'With Delivery Data: ${validCancelledInvoices.where((i) => i.deliveryDataId != null).length}',
      );
      debugPrint(
        'With Images: ${validCancelledInvoices.where((i) => i.image != null && i.image!.isNotEmpty).length}',
      );

      // Debug each saved cancelled invoice
      for (var invoice in validCancelledInvoices) {
        debugPrint(
          '💾 Saved: ${invoice.pocketbaseId} - Reason: ${invoice.reason.toString().split('.').last} - Trip: ${invoice.tripId} - DeliveryData: ${invoice.deliveryDataId}',
        );
      }
    } catch (e) {
      debugPrint('❌ LOCAL: Save operation failed: ${e.toString()}');
      throw CacheException(message: e.toString());
    }
  }

  void _setupRelations(CancelledInvoiceModel cancelledInvoice) {
    try {
      debugPrint(
        '🔗 LOCAL: Setting up relations for cancelled invoice: ${cancelledInvoice.pocketbaseId}',
      );

      // Set up delivery data relation
      if (cancelledInvoice.deliveryDataId != null) {
        final deliveryData = _deliveryDataBox
            .query(
              DeliveryDataModel_.pocketbaseId.equals(
                cancelledInvoice.deliveryDataId!,
              ),
            )
            .build()
            .findFirst();

        if (deliveryData != null) {
          cancelledInvoice.deliveryData.target = deliveryData;
          debugPrint(
            '✅ LOCAL: Set delivery data relation: ${deliveryData.pocketbaseId}',
          );

          // Also set up nested relations from delivery data
          _setupDeliveryDataRelations(deliveryData);

          // If delivery data has trip relation, use it for cancelled invoice too
          if (deliveryData.trip.target != null) {
            cancelledInvoice.trip.target = deliveryData.trip.target;
            cancelledInvoice.tripId = deliveryData.trip.target?.pocketbaseId;
            debugPrint(
              '✅ LOCAL: Inherited trip relation from delivery data: ${cancelledInvoice.tripId}',
            );
          }
        } else {
          debugPrint(
            '⚠️ LOCAL: Delivery data not found for ID: ${cancelledInvoice.deliveryDataId}',
          );
        }
      }

      // Set up trip relation (if not already set from delivery data)
      if (cancelledInvoice.tripId != null && cancelledInvoice.trip.target == null) {
        final trip = _tripBox
            .query(TripModel_.pocketbaseId.equals(cancelledInvoice.tripId!))
            .build()
            .findFirst();

        if (trip != null) {
          cancelledInvoice.trip.target = trip;
          debugPrint(
            '✅ LOCAL: Set trip relation: ${trip.pocketbaseId} - ${trip.tripNumberId}',
          );
        } else {
          debugPrint(
            '⚠️ LOCAL: Trip not found for ID: ${cancelledInvoice.tripId}',
          );
        }
      }

      debugPrint('🔗 LOCAL: Relations setup complete for cancelled invoice');
    } catch (e) {
      debugPrint(
        '❌ LOCAL: Failed to setup relations for cancelled invoice: ${e.toString()}',
      );
      // Don't throw error as this is not critical for basic functionality
    }
  }

  void _setupDeliveryDataRelations(DeliveryDataModel deliveryData) {
    try {
      debugPrint(
        '🔗 LOCAL: Setting up delivery data relations: ${deliveryData.pocketbaseId}',
      );

      // Set up trip relation for delivery data if not already set
      if (deliveryData.tripId != null && deliveryData.trip.target == null) {
        final trip = _tripBox
            .query(TripModel_.pocketbaseId.equals(deliveryData.tripId!))
            .build()
            .findFirst();

        if (trip != null) {
          deliveryData.trip.target = trip;
          debugPrint(
            '✅ LOCAL: Set trip relation for delivery data: ${trip.pocketbaseId} - ${trip.tripNumberId}',
          );
        } else {
          debugPrint(
            '⚠️ LOCAL: Trip not found for delivery data trip ID: ${deliveryData.tripId}',
          );
        }
      }
    } catch (e) {
      debugPrint(
        '❌ LOCAL: Failed to setup delivery data relations: ${e.toString()}',
      );
      // Don't throw error as this is not critical
    }
  }

  // Helper method to get cached cancelled invoices
  List<CancelledInvoiceModel>? get cachedCancelledInvoices =>
      _cachedCancelledInvoices;

  // Helper method to clear cache
  void clearCache() {
    _cachedCancelledInvoices = null;
    debugPrint('🗑️ LOCAL: Cancelled invoices cache cleared');
  }

  // Helper method to get storage statistics
  Map<String, dynamic> getStorageStats() {
    final allInvoices = _cancelledInvoiceBox.getAll();
    final withTrip = allInvoices.where((i) => i.tripId != null).length;
    final withDeliveryData = allInvoices.where((i) => i.deliveryDataId != null).length;
    final withImages = allInvoices.where((i) => i.image != null && i.image!.isNotEmpty).length;

    return {
      'total': allInvoices.length,
      'withTrip': withTrip,
      'withDeliveryData': withDeliveryData,
      'withImages': withImages,
      'cached': _cachedCancelledInvoices?.length ?? 0,
    };
  }

  // Helper method to validate cancelled invoice data integrity
  Future<List<String>> validateDataIntegrity() async {
    final issues = <String>[];
    
    try {
      final allInvoices = _cancelledInvoiceBox.getAll();
      
      for (var invoice in allInvoices) {
        // Check for missing PocketBase ID
        if (invoice.pocketbaseId.isEmpty) {
          issues.add('Cancelled invoice ${invoice.objectBoxId} missing PocketBase ID');
        }
        
        // Check for orphaned delivery data references
        if (invoice.deliveryDataId != null) {
          final deliveryData = _deliveryDataBox
              .query(DeliveryDataModel_.pocketbaseId.equals(invoice.deliveryDataId!))
              .build()
              .findFirst();
          
          if (deliveryData == null) {
            issues.add('Cancelled invoice ${invoice.pocketbaseId} references non-existent delivery data: ${invoice.deliveryDataId}');
          }
        }
        
        // Check for orphaned trip references
        if (invoice.tripId != null) {
          final trip = _tripBox
              .query(TripModel_.pocketbaseId.equals(invoice.tripId!))
              .build()
              .findFirst();
          
          if (trip == null) {
            issues.add('Cancelled invoice ${invoice.pocketbaseId} references non-existent trip: ${invoice.tripId}');
          }
        }
      }
      
      debugPrint('🔍 LOCAL: Data integrity check complete. Found ${issues.length} issues.');
      
    } catch (e) {
      issues.add('Failed to validate data integrity: ${e.toString()}');
      debugPrint('❌ LOCAL: Data integrity validation failed: ${e.toString()}');
    }
    
    return issues;
  }

  // Helper method to repair broken relations
  Future<void> repairBrokenRelations() async {
    try {
      debugPrint('🔧 LOCAL: Starting relation repair process');
      
      final allInvoices = _cancelledInvoiceBox.getAll();
      int repairedCount = 0;
      
      for (var invoice in allInvoices) {
        bool needsUpdate = false;
        
        // Repair delivery data relation
        if (invoice.deliveryDataId != null && invoice.deliveryData.target == null) {
          final deliveryData = _deliveryDataBox
              .query(DeliveryDataModel_.pocketbaseId.equals(invoice.deliveryDataId!))
              .build()
              .findFirst();
          
          if (deliveryData != null) {
            invoice.deliveryData.target = deliveryData;
            needsUpdate = true;
            debugPrint('🔧 LOCAL: Repaired delivery data relation for ${invoice.pocketbaseId}');
          }
        }
        
        // Repair trip relation
        if (invoice.tripId != null && invoice.trip.target == null) {
          final trip = _tripBox
              .query(TripModel_.pocketbaseId.equals(invoice.tripId!))
              .build()
              .findFirst();
          
          if (trip != null) {
            invoice.trip.target = trip;
            needsUpdate = true;
            debugPrint('🔧 LOCAL: Repaired trip relation for ${invoice.pocketbaseId}');
          }
        }
        
        if (needsUpdate) {
          _cancelledInvoiceBox.put(invoice);
          repairedCount++;
        }
      }
      
      debugPrint('✅ LOCAL: Relation repair complete. Repaired $repairedCount cancelled invoices.');
      
    } catch (e) {
      debugPrint('❌ LOCAL: Relation repair failed: ${e.toString()}');
      throw CacheException(message: e.toString());
    }
  }
}

