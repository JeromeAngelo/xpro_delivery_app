import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:objectbox/objectbox.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_data/delivery_update/data/models/delivery_update_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/trip/data/models/trip_models.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_data/customer_data/data/model/customer_data_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_data/invoice_data/data/model/invoice_data_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_data/invoice_items/data/model/invoice_items_model.dart';
import 'package:x_pro_delivery_app/core/enums/mode_of_payment.dart';
import 'package:x_pro_delivery_app/core/enums/invoice_status.dart';
import 'package:x_pro_delivery_app/core/utils/typedefs.dart';
import '../../../../../../../enums/sync_status_enums.dart';
import '../../domain/entity/delivery_data_entity.dart';

@Entity()
class DeliveryDataModel extends DeliveryDataEntity {
  @Id(assignable: true)
  int objectBoxId = 0;

  // --------------------------------------------------------------------------
  // FIELDS (TripModel-style clean overrides)
  // --------------------------------------------------------------------------

  @override
  @Property()
  String? id;


  @Property()
  String pocketbaseId = '';

  @Property()
  String? tripId;

  // ---- Boolean fields rewritten TripModel-style ----
  @Property()
  bool _hasTrip = false;

  @override
  @Property()
  bool? get hasTrip => _hasTrip;


  set hasTrip(bool? value) {
    _hasTrip = value ?? false;
  }


 // ---- Boolean fields rewritten TripModel-style ----
  @Property()
  bool _isUnloaded = false;

  @override
  @Property()
  bool? get isUnloaded => _isUnloaded;


  set isUnloaded(bool? value) {
    _isUnloaded = value ?? false;
  }


 // ---- Boolean fields rewritten TripModel-style ----
  @Property()
  bool _isUnloading = false;

  @override
  @Property()
  bool? get isUnloading => _isUnloading;


  set isUnloading(bool? value) {
    _isUnloading = value ?? false;
  }
   // ---- Boolean fields rewritten TripModel-style ----
  @Property()
  bool _hasPendingSync = false;

  @override
  @Property()
  bool? get hasPendingSync => _hasPendingSync;

  set hasPendingSync(bool? value) {
    _hasPendingSync = value ?? false;
  }
  // Sync state
@Property()
String syncStatus = SyncStatus.synced.name;

// Retry handling
@Property()
int retryCount = 0;

@Property()
DateTime? lastSyncAttemptAt;

@Property()
DateTime? nextRetryAt;

// Error tracking
@Property()
String? lastSyncError;

// Conflict resolution
@Property()
int version = 0;

// Optional audit
@Property()
String? updatedBy;

@Property()
String? deviceId;

  // --------------------------------------------------------------------------
  // BASIC FIELDS
  // --------------------------------------------------------------------------

  @override
  @Property()
  String? paymentMode;

  @override
  @Property()
  String? deliveryNumber;

  @override
  @Property()
  ModeOfPayment? paymentSelection;

  @override
  @Property()
  InvoiceStatus? invoiceStatus;

  @override
  @Property()
  String? totalDeliveryTime;

  @override
  @Property()
  String? storeName;

  @override
  @Property()
  String? ownerName;

  @override
  @Property()
  String? contactNumber;

  @override
  @Property()
  String? barangay;

  @override
  @Property()
  String? municipality;

  @override
  @Property()
  String? province;

  @override
  @Property()
  String? refID;

  @override
  @Property()
  DateTime? created;


  @override
  @Property()
  DateTime? lastLocalUpdatedAt;
  @override
  @Property()
  DateTime? updated;

  // --------------------------------------------------------------------------
  // RELATIONS
  // --------------------------------------------------------------------------

  final customer = ToOne<CustomerDataModel>();
  final invoice = ToOne<InvoiceDataModel>();
  final invoices = ToMany<InvoiceDataModel>();
  final trip = ToOne<TripModel>();
  final deliveryUpdates = ToMany<DeliveryUpdateModel>();
  final invoiceItems = ToMany<InvoiceItemsModel>();

  // --------------------------------------------------------------------------
  // CONSTRUCTOR
  // --------------------------------------------------------------------------

  DeliveryDataModel({
    this.id,
    this.paymentMode,
    this.deliveryNumber,
    bool? hasTrip,
    bool? hasPendingSync,
    bool? isUnloaded,
    bool? isUnloading,
    this.totalDeliveryTime,
    this.paymentSelection,
    this.invoiceStatus,
    this.storeName,
    this.ownerName,
    this.contactNumber,
    this.barangay,
    this.municipality,
    this.province,
    this.refID,
    this.lastLocalUpdatedAt,
    this.created,
    this.updated,
   String? tripId,
    CustomerDataModel? customerData,
    InvoiceDataModel? invoiceData,
    List<InvoiceDataModel>? invoicesList,
    TripModel? tripData,
    List<DeliveryUpdateModel>? deliveryUpdatesList,
    List<InvoiceItemsModel>? invoiceItemsList,
    this.objectBoxId = 0,
  }) {
    pocketbaseId = id ?? '';
    tripId = tripId;
    this.hasPendingSync = hasPendingSync ?? false;
    this.hasTrip = hasTrip ?? false;
    this.isUnloading = isUnloading ?? false;
    this.isUnloaded = isUnloaded ?? false;

    if (customerData != null) customer.target = customerData;
    if (invoiceData != null) invoice.target = invoiceData;
    if (invoicesList != null) invoices.addAll(invoicesList);
    if (tripData != null) trip.target = tripData;
    if (deliveryUpdatesList != null) deliveryUpdates.addAll(deliveryUpdatesList);
    if (invoiceItemsList != null) invoiceItems.addAll(invoiceItemsList);
  }

  
// -----------------------------
  // JSON parsing helpers
  // -----------------------------
/// Safely parse any date field into DateTime
static DateTime? _parseDate(dynamic value) {
  if (value == null) return null;

  try {
    // 1️⃣ If it's already a DateTime, return as is
    if (value is DateTime) return value;

    // 2️⃣ If numeric (seconds or milliseconds)
    if (value is int) return _timestampToDateTime(value);

    // 3️⃣ If string
    if (value is String && value.isNotEmpty) {
      // Try ISO8601 first
      try {
        return DateTime.parse(value);
      } catch (_) {}

      // Try common non-ISO formats
      final possibleFormats = [
        'yyyy-MM-dd HH:mm:ss',
        'yyyy/MM/dd HH:mm:ss',
        'yyyy-MM-dd',
        'yyyy/MM/dd',
        'MM/dd/yyyy',
        'MM-dd-yyyy',
        'dd/MM/yyyy',
        'dd-MM-yyyy',
        'dd MMM yyyy',
        'MMM dd, yyyy',
      ];

      for (final format in possibleFormats) {
        try {
          final dt = DateFormat(format).parse(value, true);
          return dt;
        } catch (_) {}
      }

      // Try numeric string as timestamp
      final numeric = int.tryParse(value);
      if (numeric != null) return _timestampToDateTime(numeric);
    }

    // fallback
    debugPrint('⚠️ [_parseDate] Could not parse date: $value');
    return null;
  } catch (e) {
    debugPrint('⚠️ [_parseDate] Error parsing date: $value → $e');
    return null;
  }
}

/// Convert numeric timestamp (s or ms) to DateTime
static DateTime _timestampToDateTime(int ts) {
  try {
    // Detect if timestamp is in milliseconds or seconds
    final isMilliseconds = ts > 1000000000000; // ~2001-09-09
    return isMilliseconds
        ? DateTime.fromMillisecondsSinceEpoch(ts, isUtc: true)
        : DateTime.fromMillisecondsSinceEpoch(ts * 1000, isUtc: true);
  } catch (e) {
    debugPrint('⚠️ [_timestampToDateTime] Invalid timestamp: $ts → $e');
    return DateTime.now().toUtc();
  }
}

/// --- From JSON ---
factory DeliveryDataModel.fromJson(dynamic json) {
  debugPrint('🔄 MODEL: Creating DeliveryDataModel from JSON');

  if (json is String) {
    debugPrint("🆔 Only ID provided: $json");
    return DeliveryDataModel(id: json);
  }

  final expandedData = json['expand'] as Map<String, dynamic>?;

  // -----------------------------
  // Customer
  // -----------------------------
  CustomerDataModel? customerModel;
  final customerData = expandedData?['customer'] ?? json['customer'];
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
  final invoiceData = expandedData?['invoice'] ?? json['invoice'];
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
  final invoicesData = expandedData?['invoices'] ?? json['invoices'];
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
  // Trip
  // -----------------------------
  TripModel? tripModel;
  final tripData = expandedData?['trip'] ?? json['trip'];
  if (tripData != null) {
    if (tripData is Map<String, dynamic>) {
      tripModel = TripModel.fromJson(tripData);
    } else if (tripData is TripModel) {
      tripModel = tripData;
    } else if (tripData is String && tripData.isNotEmpty) {
      tripModel = TripModel(id: tripData);
    } else {
      debugPrint("❌ Unsupported trip data type: ${tripData.runtimeType}");
    }
  }

  // -----------------------------
  // Delivery Updates
  // -----------------------------
  List<DeliveryUpdateModel> deliveryUpdatesList = [];
  final updatesData = expandedData?['deliveryUpdates'] ?? json['deliveryUpdates'];
  if (updatesData != null) {
    if (updatesData is List) {
      deliveryUpdatesList = updatesData
          .map((e) => e is Map<String, dynamic>
              ? DeliveryUpdateModel.fromJson(e)
              : e is DeliveryUpdateModel
                  ? e
                  : DeliveryUpdateModel(id: e.toString()))
          .toList();
    }
  }

  // -----------------------------
  // Invoice Items
  // -----------------------------
  List<InvoiceItemsModel> invoiceItemsList = [];
  final invoiceItemsData = expandedData?['invoiceItems'] ?? json['invoiceItems'];
  if (invoiceItemsData != null) {
    if (invoiceItemsData is List) {
      invoiceItemsList = invoiceItemsData
          .map((e) => e is Map<String, dynamic>
              ? InvoiceItemsModel.fromJson(e)
              : e is InvoiceItemsModel
                  ? e
                  : InvoiceItemsModel(id: e.toString()))
          .toList();
    }
  }

  // -----------------------------
  // Main fields
  // -----------------------------
  ModeOfPayment? parsePayment(dynamic value) {
    switch (value?.toString().toLowerCase()) {
      case 'banktransfer':
        return ModeOfPayment.bankTransfer;
      case 'cashondelivery':
        return ModeOfPayment.cashOnDelivery;
      case 'cheque':
        return ModeOfPayment.cheque;
      case 'ewallet':
        return ModeOfPayment.eWallet;
      default:
        return null;
    }
  }

  return DeliveryDataModel(
    id: json['id']?.toString(),
    paymentMode: json['paymentMode'],
    deliveryNumber: json['deliveryNumber'],
    hasTrip: json['hasTrip'] ?? false,
    hasPendingSync: json['hasPendingSync'] ?? false,
    totalDeliveryTime: json['totalDeliveryTime'],
    paymentSelection: parsePayment(json['paymentSelection']),
    invoiceStatus: InvoiceStatus.values.firstWhere(
      (e) => e.name == (json['invoiceStatus'] ?? 'none'),
      orElse: () => InvoiceStatus.none,
    ),
    isUnloaded: json['isUnloaded'] ?? false,
    isUnloading: json['isUnloading'] ?? false,
    storeName: json['storeName'],
    ownerName: json['ownerName'] ?? json['customer']?['name']?.toString(),
    contactNumber: json['contactNumber'],
    barangay: json['barangay'],
    municipality: json['municipality'],
    province: json['province'],
    refID: json['refID'],
    lastLocalUpdatedAt: _parseDate(json['lastLocalUpdatedAt']),
    created: _parseDate(json['created']),
    updated: _parseDate(json['updated']),
    tripId: json['trip']?.toString(),
    customerData: customerModel,
    invoiceData: invoiceModel,
    invoicesList: invoicesList,
    tripData: tripModel,
    deliveryUpdatesList: deliveryUpdatesList,
    invoiceItemsList: invoiceItemsList,
  );
}

  // --------------------------------------------------------------------------
  // TO JSON
  // --------------------------------------------------------------------------

  DataMap toJson() {
    return {
      'id': pocketbaseId,
      'collectionId': collectionId,
      'collectionName': collectionName,
      'paymentMode': paymentMode,
      'deliveryNumber': deliveryNumber,
      'hasTrip': hasTrip ?? false,
      'isUnloaded': isUnloaded ?? false,
      'isUnloading': isUnloading ?? false,
      'totalDeliveryTime': totalDeliveryTime,
      'paymentSelection': paymentSelection?.name,
      'invoiceStatus': invoiceStatus?.name,
      'customer': customer.target?.id,
      'invoice': invoice.target?.id,
      'invoices': invoices.map((e) => e.id).toList(),
      'trip': trip.target?.id,
      'deliveryUpdates': deliveryUpdates.map((e) => e.id).toList(),
      'invoiceItems': invoiceItems.map((e) => e.id).toList(),
      'storeName': storeName,
      'ownerName': ownerName,
      'hasPendingSync': hasPendingSync,
      'lastLocalUpdatedAt': lastLocalUpdatedAt?.toIso8601String(),
      'contactNumber': contactNumber,
      'barangay': barangay,
      'municipality': municipality,
      'province': province,
      'refID': refID,
      'created': created?.toIso8601String(),
      'updated': updated?.toIso8601String(),
    };
  }

  // --------------------------------------------------------------------------
  // COPY WITH
  // --------------------------------------------------------------------------

  DeliveryDataModel copyWith({
    String? id,
    String? collectionId,
    String? collectionName,
    CustomerDataModel? customerData,
    InvoiceDataModel? invoiceData,
    List<InvoiceDataModel>? invoicesList,
    TripModel? tripData,
    List<DeliveryUpdateModel>? deliveryUpdatesList,
    List<InvoiceItemsModel>? invoiceItemsList,
    String? paymentMode,
    String? deliveryNumber,
    bool? hasTrip,
    bool? hasPendingSync,
    bool? isUnloaded,
    bool? isUnloading,
    String? totalDeliveryTime,
    ModeOfPayment? paymentSelection,
    InvoiceStatus? invoiceStatus,
    String? storeName,
    String? ownerName,
    String? contactNumber,
    String? barangay,
    String? municipality,
    String? province,
    String? refID,
    DateTime? created,
    DateTime? lastLocalUpdatedAt,
    DateTime? updated,
  }) {
    final model = DeliveryDataModel(
      id: id ?? this.id,
      
      customerData: customerData ?? this.customer.target,
      invoiceData: invoiceData ?? this.invoice.target,
      invoicesList: invoicesList ?? this.invoices.toList(),
      tripData: tripData ?? this.trip.target,
      deliveryUpdatesList: deliveryUpdatesList ,
      invoiceItemsList: invoiceItemsList ?? this.invoiceItems.toList(),
      paymentMode: paymentMode ?? this.paymentMode,
      deliveryNumber: deliveryNumber ?? this.deliveryNumber,
      hasTrip: hasTrip ?? this.hasTrip,
      isUnloaded: isUnloaded ?? this.isUnloaded,
      isUnloading: isUnloading ?? this.isUnloading,
      hasPendingSync: hasPendingSync ?? this.hasPendingSync,
      lastLocalUpdatedAt: lastLocalUpdatedAt ?? this.lastLocalUpdatedAt,
      totalDeliveryTime: totalDeliveryTime ?? this.totalDeliveryTime,
      paymentSelection: paymentSelection ?? this.paymentSelection,
      invoiceStatus: invoiceStatus ?? this.invoiceStatus,
      storeName: storeName ?? this.storeName,
      ownerName: ownerName ?? this.ownerName,
      contactNumber: contactNumber ?? this.contactNumber,
      barangay: barangay ?? this.barangay,
      municipality: municipality ?? this.municipality,
      province: province ?? this.province,
      refID: refID ?? this.refID,
      created: created ?? this.created,
      updated: updated ?? this.updated,
      objectBoxId: objectBoxId,
    );

    return model;
  }

  // --------------------------------------------------------------------------
  // OVERRIDES
  // --------------------------------------------------------------------------

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is DeliveryDataModel && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
