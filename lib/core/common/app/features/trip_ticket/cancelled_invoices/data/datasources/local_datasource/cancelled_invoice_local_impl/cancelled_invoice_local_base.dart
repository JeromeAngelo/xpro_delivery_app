import 'package:flutter/material.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/cancelled_invoices/data/model/cancelled_invoice_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/delivery_data/data/model/delivery_data_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/trip/data/models/trip_models.dart';
import 'package:x_pro_delivery_app/core/errors/exceptions.dart';
import 'package:x_pro_delivery_app/objectbox.g.dart';
import '../../../../../../../../../services/objectbox.dart';
import '../../../../../../delivery_data/customer_data/data/model/customer_data_model.dart';
import '../../../../../../delivery_data/invoice_data/data/model/invoice_data_model.dart';

abstract class CancelledInvoiceLocalBase {
  final ObjectBoxStore objectBoxStore;
  List<CancelledInvoiceModel>? cachedCancelledInvoicesList;

  CancelledInvoiceLocalBase(this.objectBoxStore);

  // ================================================================
  // BOX GETTERS
  // ================================================================
  Box<DeliveryDataModel> get deliveryDataBox => objectBoxStore.deliveryDataBox;
  Box<TripModel> get tripBox => objectBoxStore.tripBox;
  Box<CustomerDataModel> get customerBox => objectBoxStore.customerBox;
  Box<InvoiceDataModel> get invoiceBox => objectBoxStore.invoiceBox;
  Box<CancelledInvoiceModel> get cancelledInvoiceBox =>
      objectBoxStore.cancelledInvoiceBox;

  // ================================================================
  // HELPER METHODS (formerly private, now public for mixin access)
  // ================================================================

  /// Set up relations for a cancelled invoice
  void setupRelations(CancelledInvoiceModel cancelledInvoice) {
    try {
      debugPrint(
        '🔗 LOCAL: Setting up relations for cancelled invoice: ${cancelledInvoice.id}',
      );

      // Set up delivery data relation
      if (cancelledInvoice.deliveryData.target?.id != null) {
        final deliveryData =
            deliveryDataBox
                .query(
                  DeliveryDataModel_.pocketbaseId.equals(
                    cancelledInvoice.deliveryData.target!.id!,
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
          setupDeliveryDataRelations(deliveryData);

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
            '⚠️ LOCAL: Delivery data not found for ID: ${cancelledInvoice.deliveryData.target?.id}',
          );
        }
      }

      // Set up trip relation (if not already set from delivery data)
      if (cancelledInvoice.tripId != null &&
          cancelledInvoice.trip.target == null) {
        final trip =
            tripBox
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

  /// Set up delivery data relations
  void setupDeliveryDataRelations(DeliveryDataModel deliveryData) {
    try {
      debugPrint(
        '🔗 LOCAL: Setting up delivery data relations: ${deliveryData.pocketbaseId}',
      );

      // Set up trip relation for delivery data if not already set
      if (deliveryData.tripId != null && deliveryData.trip.target == null) {
        final trip =
            tripBox
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

  /// Link cancelled invoice to trip
  Future<void> linkCancelledInvoiceToTrip(
    TripModel trip,
    CancelledInvoiceModel invoice,
  ) async {
    final localTripBox = objectBoxStore.tripBox;

    // Prevent duplicate linking (important after restart)
    final alreadyLinked = trip.cancelledInvoices.any(
      (e) => e.objectBoxId == invoice.objectBoxId,
    );

    if (!alreadyLinked) {
      trip.cancelledInvoices.add(invoice);
      localTripBox.put(trip);

      debugPrint(
        '🔗 CancelledInvoice linked → Trip: ${trip.id}, '
        'Total cancelled: ${trip.cancelledInvoices.length}',
      );
    } else {
      debugPrint('ℹ️ CancelledInvoice already linked → Trip: ${trip.id}');
    }

    await cleanCancelledInvoices();
  }

  /// Clean CancelledInvoice table:
  /// Remove items with NULL / EMPTY PocketBase ID and duplicates
  Future<void> cleanCancelledInvoices() async {
    try {
      debugPrint('🧹 Starting CancelledInvoice cleanup');

      final allCancelled = cancelledInvoiceBox.getAll();

      final seen = <String, CancelledInvoiceModel>{};

      for (final ci in allCancelled) {
        final pbId = (ci.id ?? '').trim();

        // Remove invalid (no PB ID)
        if (pbId.isEmpty) {
          debugPrint(
            '🗑️ Removing INVALID CancelledInvoice → '
            'Reason: ${ci.reason}, OBX: ${ci.objectBoxId}',
          );
          cancelledInvoiceBox.remove(ci.objectBoxId);
          continue;
        }

        // Remove duplicates
        if (seen.containsKey(pbId)) {
          debugPrint(
            '⚠️ Duplicate CancelledInvoice → Removing '
            'PB: $pbId (OBX: ${ci.objectBoxId})',
          );
          cancelledInvoiceBox.remove(ci.objectBoxId);
          continue;
        }

        // First valid occurrence
        seen[pbId] = ci;
      }

      debugPrint(
        '🟢 CancelledInvoice cleanup complete — '
        '${allCancelled.length - seen.length} invalid/duplicate records removed.',
      );
    } catch (e, st) {
      debugPrint('❌ cleanCancelledInvoices error: $e\n$st');
    }
  }

  /// Cleanup cancelled invoices (deduplication)
  Future<void> cleanupCancelledInvoices() async {
    try {
      debugPrint('🧹 LOCAL: Starting cancelled invoices cleanup process');
      final allCancelledInvoices = cancelledInvoiceBox.getAll();

      // Create a map to track unique cancelled invoices by their PocketBase ID
      final Map<String?, CancelledInvoiceModel> uniqueCancelledInvoices = {};

      for (var invoice in allCancelledInvoices) {
        // Only keep valid cancelled invoices with required fields
        if (isValidCancelledInvoice(invoice)) {
          // If duplicate found, keep the most recently updated one
          final existingInvoice = uniqueCancelledInvoices[invoice.id];
          if (existingInvoice == null ||
              (invoice.updated?.isAfter(
                    existingInvoice.updated ?? DateTime(0),
                  ) ??
                  false)) {
            uniqueCancelledInvoices[invoice.id] = invoice;
          }
        }
      }

      // Clear all and save only valid unique cancelled invoices
      cancelledInvoiceBox.removeAll();
      cancelledInvoiceBox.putMany(uniqueCancelledInvoices.values.toList());

      debugPrint('✨ LOCAL: Cleanup complete:');
      debugPrint('📊 Original count: ${allCancelledInvoices.length}');
      debugPrint('📊 After cleanup: ${uniqueCancelledInvoices.length}');
    } catch (e) {
      debugPrint('❌ LOCAL: Cleanup failed: ${e.toString()}');
      throw CacheException(message: e.toString());
    }
  }

  /// Validate cancelled invoice
  bool isValidCancelledInvoice(CancelledInvoiceModel invoice) {
    return invoice.id != null && invoice.id!.isNotEmpty;
  }

  /// Auto-save cancelled invoices list
  Future<void> autoSave(
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
              invoice.deliveryData.target?.pocketbaseId;
            }
            return invoice;
          }).toList();

      cancelledInvoiceBox.putMany(validCancelledInvoices);
      cachedCancelledInvoicesList = validCancelledInvoices;

      debugPrint('📊 LOCAL: Storage Stats:');
      debugPrint('Total Cancelled Invoices: ${validCancelledInvoices.length}');
      debugPrint(
        'Valid Cancelled Invoices: ${validCancelledInvoices.where((i) => i.id != null).length}',
      );
      debugPrint(
        'With Trip Data: ${validCancelledInvoices.where((i) => i.tripId != null).length}',
      );
      debugPrint(
        'With Delivery Data: ${validCancelledInvoices.where((i) => i.deliveryData.target?.id != null).length}',
      );
      debugPrint(
        'With Images: ${validCancelledInvoices.where((i) => i.image != null && i.image!.isNotEmpty).length}',
      );

      // Debug each saved cancelled invoice
      for (var invoice in validCancelledInvoices) {
        debugPrint(
          '💾 Saved: ${invoice.id} - Reason: ${invoice.reason.toString().split('.').last} - Trip: ${invoice.tripId} - DeliveryData: ${invoice.deliveryData.target?.id}',
        );
      }
    } catch (e) {
      debugPrint('❌ LOCAL: Save operation failed: ${e.toString()}');
      throw CacheException(message: e.toString());
    }
  }

  // ================================================================
  // ABSTRACT METHODS (called by other mixins)
  // ================================================================
  Future<List<CancelledInvoiceModel>> loadCancelledInvoicesByTripId(
    String tripId,
  );
}
