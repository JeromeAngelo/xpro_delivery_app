import 'package:flutter/foundation.dart';
import 'package:objectbox/objectbox.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/trip/data/models/trip_models.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/cancelled_invoices/domain/entity/cancelled_invoice_entity.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_data/customer_data/data/model/customer_data_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/delivery_data/data/model/delivery_data_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_data/invoice_data/data/model/invoice_data_model.dart';
import 'package:x_pro_delivery_app/core/enums/undeliverable_reason.dart';
import 'package:x_pro_delivery_app/core/utils/typedefs.dart';

import '../../../../../../../enums/sync_status_enums.dart';

@Entity()
class CancelledInvoiceModel extends CancelledInvoiceEntity {
  @Id(assignable: true)
  int objectBoxId = 0;

  // --------------------------------------------------------------------------
  // CORE IDS
  // --------------------------------------------------------------------------

  @override
  @Property()
  String? id;

@Property()
  String pocketbaseId = '';

  
 @Property()
  String collectionName = '';

  @Property()
  String? collectionId;
  @Property()
  String? tripId;

  @Property()
  String? customerId;

  @Property()
  String? invoiceId;


   /// NEW: link to deliveryData
  @Property()
  String? deliveryDataId;


   /// NEW: link to deliveryData
  @Property()
  String? reasonString;

  // --------------------------------------------------------------------------
  // SYNC / METADATA
  // --------------------------------------------------------------------------

  @Property()
  String syncStatus = SyncStatus.pending.name;

  @Property()
  int retryCount = 0;

  @Property()
  DateTime? lastSyncAttemptAt;

  @Property()
  DateTime? nextRetryAt;

  @Property()
  String? lastSyncError;

  @Property()
  int version = 0;

  @Property()
  String? updatedBy;

  @Property()
  String? deviceId;

  // --------------------------------------------------------------------------
  // BASIC FIELDS (ENTITY OVERRIDES)
  // --------------------------------------------------------------------------

  @override
  @Property()
  UndeliverableReason? reason;

  @override
  @Property()
  String? image;

  @override
  @Property()
  DateTime? created;

  @override
  @Property()
  DateTime? updated;
/// Local timestamp for last local update (used to prefer local changes
  /// over incoming watched items that may be missing transient data)
  @Property(type: PropertyType.date)
  DateTime? lastLocalUpdatedAt;
  // --------------------------------------------------------------------------
  // RELATIONS
  // --------------------------------------------------------------------------

  final deliveryData = ToOne<DeliveryDataModel>();
  final trip = ToOne<TripModel>();
  final customer = ToOne<CustomerDataModel>();
  final invoice = ToOne<InvoiceDataModel>();
  final invoices = ToMany<InvoiceDataModel>();

  // --------------------------------------------------------------------------
  // CONSTRUCTOR
  // --------------------------------------------------------------------------

  CancelledInvoiceModel({
    this.id,
    this.reason,
    this.image,
    this.created,
    this.collectionId,
    this.updated,
      this.deliveryDataId,
this.tripId,
      this.customerId,
      this.invoiceId,
    this.collectionName = '',
    String? syncStatus, // nullable
  this.retryCount = 0,
  this.lastSyncAttemptAt,
  this.nextRetryAt,
  this.lastSyncError,
      this.lastLocalUpdatedAt,
this.reasonString,
    DeliveryDataModel? deliveryDataModel,
    TripModel? tripModel,
    CustomerDataModel? customerModel,
    InvoiceDataModel? invoiceModel,
    List<InvoiceDataModel>? invoicesList,
    this.objectBoxId = 0,
  }) {
    pocketbaseId = id ?? '';
   syncStatus = syncStatus ?? SyncStatus.pending.name; 
    tripId = tripModel?.id;
    customerId = customerModel?.id;
    invoiceId = invoiceModel?.id;

    if (deliveryDataModel != null) deliveryData.target = deliveryDataModel;
    if (tripModel != null) trip.target = tripModel;
    if (customerModel != null) customer.target = customerModel;
    if (invoiceModel != null) invoice.target = invoiceModel;
    if (invoicesList != null) invoices.addAll(invoicesList);
  }

  // --------------------------------------------------------------------------
  // DATE HELPERS (same as DeliveryDataModel)
  // --------------------------------------------------------------------------

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;

    try {
      if (value is DateTime) return value;

      if (value is int) return _timestampToDateTime(value);

      if (value is String && value.isNotEmpty) {
        try {
          return DateTime.parse(value);
        } catch (_) {}

        final numeric = int.tryParse(value);
        if (numeric != null) return _timestampToDateTime(numeric);
      }

      debugPrint('⚠️ [_parseDate] Could not parse date: $value');
      return null;
    } catch (e) {
      debugPrint('⚠️ [_parseDate] Error parsing date: $value → $e');
      return null;
    }
  }

  static DateTime _timestampToDateTime(int ts) {
    final isMs = ts > 1000000000000;
    return isMs
        ? DateTime.fromMillisecondsSinceEpoch(ts, isUtc: true)
        : DateTime.fromMillisecondsSinceEpoch(ts * 1000, isUtc: true);
  }

  // --------------------------------------------------------------------------
  // FROM JSON
  // --------------------------------------------------------------------------

  factory CancelledInvoiceModel.fromJson(dynamic json) {
    debugPrint('🔄 MODEL: Creating CancelledInvoiceModel from JSON');

    if (json is String) {
      return CancelledInvoiceModel(id: json);
    }

    final expanded = json['expand'] as Map<String, dynamic>?;

    // -----------------------------
    // Relations
    // -----------------------------

    DeliveryDataModel? deliveryDataModel;
    final dd = expanded?['deliveryData'] ?? json['deliveryData'];
    if (dd != null) {
      deliveryDataModel = dd is Map
          ? DeliveryDataModel.fromJson(dd)
          : DeliveryDataModel(id: dd.toString());
    }

    TripModel? tripModel;
    final t = expanded?['trip'] ?? json['trip'];
    if (t != null) {
      tripModel =
          t is Map ? TripModel.fromJson(t) : TripModel(id: t.toString());
    }

    
  // -----------------------------
  // Customer
  // -----------------------------
  CustomerDataModel? customerModel;
  final customerData = expanded?['customer'] ?? json['customer'];
  if (customerData != null) {
    if (customerData is Map<String, dynamic>) {
      debugPrint("👤 Using MAP to build customer");
      customerModel = CustomerDataModel.fromJson(customerData);
    } else if (customerData is CustomerDataModel) {
      debugPrint("👤 Using DIRECT MODEL for customer");
      customerModel = customerData;
    } else if (customerData is String && customerData.isNotEmpty) {
      debugPrint("👤 Only ID provided for customer: $customerData");
      customerModel = CustomerDataModel(id: customerData);
    } else {
      debugPrint("❌ Unsupported customer data type: ${customerData.runtimeType}");
    }
  }
    // -----------------------------
  // Invoice (single)
  // -----------------------------
  InvoiceDataModel? invoiceModel;
  final invoiceData = expanded?['invoice'] ?? json['invoice'];
  if (invoiceData != null) {
    if (invoiceData is Map<String, dynamic>) {
      invoiceModel = InvoiceDataModel.fromJson(invoiceData);
    } else if (invoiceData is InvoiceDataModel) {
      invoiceModel = invoiceData;
    } else if (invoiceData is String && invoiceData.isNotEmpty) {
      invoiceModel = InvoiceDataModel(id: invoiceData);
    } else {
      debugPrint("❌ Unsupported invoice data type: ${invoiceData.runtimeType}");
    }
  }
      // -----------------------------
  // Invoices list
  // -----------------------------
  List<InvoiceDataModel> invoicesList = [];
  final invoicesData = expanded?['invoices'] ?? json['invoices'];
  if (invoicesData != null) {
    if (invoicesData is List) {
      invoicesList = invoicesData
          .map((e) => e is Map<String, dynamic>
              ? InvoiceDataModel.fromJson(e)
              : e is InvoiceDataModel
                  ? e
                  : InvoiceDataModel(id: e.toString()))
          .toList();
    }
  }

    // -----------------------------
    // Reason enum
    // -----------------------------

    UndeliverableReason? parseReason(dynamic value) {
      if (value == null) return null;
      return UndeliverableReason.values.firstWhere(
        (e) => e.name == value.toString(),
        orElse: () => UndeliverableReason.none,
      );
    }

    return CancelledInvoiceModel(
      id: json['id']?.toString(),
      reason: parseReason(json['reason']),
      image: json['image']?.toString(),
      created: _parseDate(json['created']),
      updated: _parseDate(json['updated']),
      lastLocalUpdatedAt:
          _parseDate(json['lastLocalUpdatedAt']) ?? _parseDate(json['updated']),
      deliveryDataModel: deliveryDataModel,
      tripModel: tripModel,
      syncStatus: SyncStatus.pending.name,
      retryCount: 0,
      customerModel: customerModel,
      invoiceModel: invoiceModel,
      invoicesList: invoicesList,
      reasonString: json['reason']?.toString(),
      
    );
  }



  DataMap toJson() {
    return {
      'id': pocketbaseId,
      'collectionId': collectionId,
      'collectionName': collectionName,
      'reason': reason?.toString().split('.').last,
      'image': image,
      'deliveryData': deliveryData.target?.id,
      'trip': trip.target?.id,
      'customer': customer.target?.id,
      'invoice': invoice.target?.id,
            'lastLocalUpdatedAt': lastLocalUpdatedAt?.toIso8601String(),

      'invoices': invoices.map((invoice) => invoice.id).toList(),
      'created': created?.toIso8601String(),
      'updated': updated?.toIso8601String(),
    };
  }

 factory CancelledInvoiceModel.fromEntity(CancelledInvoiceEntity entity) {
  return CancelledInvoiceModel(
    id: entity.id,
    collectionId: entity.collectionId,
    collectionName: entity.collectionName ?? '',
    reason: entity.reason ?? UndeliverableReason.none,
    image: entity.image ?? '',
    created: entity.created,
    updated: entity.updated,
    
    // 🔥 include sync fields
    syncStatus: entity.syncStatus ,
    retryCount: entity.retryCount,
    lastSyncAttemptAt: entity.lastSyncAttemptAt,
    lastLocalUpdatedAt: entity.lastLocalUpdatedAt,
  );
}


  CancelledInvoiceModel copyWith({
    String? id,
    String? collectionId,
    String? collectionName,
    DeliveryDataModel? deliveryData,
    TripModel? trip,
    CustomerDataModel? customer,
    InvoiceDataModel? invoice,
    List<InvoiceDataModel>? invoices,
    UndeliverableReason? reason,
    String? image,
    DateTime? created,
    DateTime? updated,
    String? syncStatus,
    int? retryCount,
    DateTime? lastSyncAttemptAt,
    DateTime? nextRetryAt,
    String? lastSyncError,
  }) {
    final model = CancelledInvoiceModel(
      id: id ?? this.id,
      collectionId: collectionId ?? this.collectionId,
      collectionName: collectionName ?? this.collectionName,
      reason: reason ?? this.reason,
      image: image ?? this.image,
      created: created ?? this.created,
      updated: updated ?? this.updated,
      objectBoxId: objectBoxId,
      syncStatus: syncStatus ?? this.syncStatus,
      retryCount: retryCount ?? this.retryCount,
      lastSyncAttemptAt: lastSyncAttemptAt ?? this.lastSyncAttemptAt,
      nextRetryAt: nextRetryAt ?? this.nextRetryAt,
      lastSyncError: lastSyncError ?? this.lastSyncError,
    );
    
    // Handle deliveryData relation
    if (deliveryData != null) {
      model.deliveryData.target = deliveryData;
    } else if (this.deliveryData.target != null) {
      model.deliveryData.target = this.deliveryData.target;
    }
    
    // Handle trip relation
    if (trip != null) {
      model.trip.target = trip;
    } else if (this.trip.target != null) {
      model.trip.target = this.trip.target;
    }

    // Handle customer relation
    if (customer != null) {
      model.customer.target = customer;
    } else if (this.customer.target != null) {
      model.customer.target = this.customer.target;
    }

    // Handle invoice relation
    if (invoice != null) {
      model.invoice.target = invoice;
    } else if (this.invoice.target != null) {
      model.invoice.target = this.invoice.target;
    }

    // Handle invoices relation
    if (invoices != null) {
      model.invoices.clear();
      model.invoices.addAll(invoices);
    } else if (this.invoices.isNotEmpty) {
      model.invoices.clear();
      model.invoices.addAll(this.invoices);
    }
    
    return model;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CancelledInvoiceModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'CancelledInvoiceModel(id: $id, deliveryData: ${deliveryData.target?.id}, trip: ${trip.target?.id}, customer: ${customer.target?.id}, invoice: ${invoice.target?.id}, invoices: ${invoices.length}, reason: $reason, image: $image)';
  }
}
