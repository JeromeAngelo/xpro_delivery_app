import 'package:flutter/foundation.dart';
import 'package:objectbox/objectbox.dart';

import '../../../../../../../enums/mismatched_personnel_reason_code.dart';
import '../../../../otp/end_trip_otp/data/model/end_trip_model.dart';
import '../../../../otp/intransit_otp/data/models/otp_models.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_team/delivery_team/data/models/delivery_team_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_team/personels/data/models/personel_models.dart';
import 'package:x_pro_delivery_app/core/common/app/features/checklists/intransit_checklist/data/model/checklist_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/checklists/end_trip_checklist/data/model/end_trip_checklist_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/trip_updates/data/model/trip_update_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_team/delivery_vehicle_data/data/model/delivery_vehicle_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/users/auth/data/models/auth_models.dart';

import '../../../cancelled_invoices/data/model/cancelled_invoice_model.dart';
import '../../../delivery_collection/data/model/collection_model.dart';
import '../../../delivery_data/data/model/delivery_data_model.dart';
import '../../domain/entity/trip_entity.dart';

@Entity()
class TripModel extends TripEntity{
  @Id(assignable: true)
  int objectBoxId = 0;

  /// PocketBase ID as primary remote identifier
  @Property()
  String? pocketbaseId;

  // Basic trip fields
  @override
  @Property()
  String? id; // PocketBase id (duplicate storage sometimes useful)

  @override
  @Property()
  String? collectionId;

  @override
  @Property()
  String? collectionName;

  @override
  @Property()
  String? tripNumberId;

  @override
  @Property()
  String? qrCode;

  @override
  @Property()
  String? name;

  @override
  @Property()
  String? totalTripDistance;

  // Geographic
  @override
  @Property()
  double? latitude;

   @override
  @Property()
  String? source;

  @override
  @Property()
  double? longitude;

    @override
  @Property()
  double? accuracy;
 @override
  @Property()
  double? tripDistance;
  // Dates
  @override
  @Property(type: PropertyType.date)
  DateTime? timeAccepted;

  @override
  @Property(type: PropertyType.date)
  DateTime? timeEndTrip;

  @override
  @Property(type: PropertyType.date)
  DateTime? created;

  @override
  @Property(type: PropertyType.date)
  DateTime? updated;

  @override
  @Property(type: PropertyType.date)
  DateTime? deliveryDate;

// --- allowMismatchedPersonnels ---
  @Property()
  bool _allowMismatchedPersonnels = false;

  @override
  @Property()
  bool? get allowMismatchedPersonnels => _allowMismatchedPersonnels;

  @override
  set allowMismatchedPersonnels(bool? value) {
    _allowMismatchedPersonnels = value ?? false;
  }

  // --- isEndTrip ---
  @Property()
  bool _isEndTrip = false;

  @override
  @Property()
  bool? get isEndTrip => _isEndTrip;

  @override
  set isEndTrip(bool? value) {
    _isEndTrip = value ?? false;
  }

  // Enum stored as string internally
  @Property()
  String? _mismatchedPersonnelReasonCodeString;

  @override
  MismatchedPersonnelReasonCode? get mismatchedPersonnelReasonCode =>
      _mismatchedPersonnelReasonCodeString == null
          ? null
          : MismatchedPersonnelReasonCode.values.firstWhere(
              (e) => e.toString() == _mismatchedPersonnelReasonCodeString,
              orElse: () => MismatchedPersonnelReasonCode.none,
            );

  @override
  set mismatchedPersonnelReasonCode(MismatchedPersonnelReasonCode? code) {
    _mismatchedPersonnelReasonCodeString =
        code == null ? null : code.toString();
  }

  // -----------------------------
  // Relations (ObjectBox)
  // -----------------------------

  // One-to-one relations
  @override
  final deliveryVehicle = ToOne<DeliveryVehicleModel>();
  @override
  final user = ToOne<LocalUsersModel>();
  @override
  final otp = ToOne<OtpModel>();
  @override
  final endTripOtp = ToOne<EndTripOtpModel>();
  @override
  final deliveryTeam = ToOne<DeliveryTeamModel>();

  // One-to-many relations
  @override
  final personels = ToMany<PersonelModel>();
  final deliveryCollection = ToMany<CollectionModel>();
  final cancelledInvoices = ToMany<CancelledInvoiceModel>();
  @override
  final checklist = ToMany<ChecklistModel>();
  @override
  final endTripChecklist = ToMany<EndTripChecklistModel>();
  @override
  final tripUpdates = ToMany<TripUpdateModel>();
  @override
  final deliveryData = ToMany<DeliveryDataModel>();
TripModel({
  this.id,
  String? collectionId,
  String? collectionName,
  String? tripNumberId,
  String? qrCode,
  String? name,
  String? totalTripDistance,
  this.objectBoxId = 0,
  DateTime? timeAccepted,
  DateTime? timeEndTrip,
  DateTime? created,
  DateTime? updated,
  DateTime? deliveryDate,
  double? latitude,
  double? accuracy,
  double? tripDistance,
  String? source,
  this.longitude,
  bool? isAccepted,
  bool? isEndTrip,
  bool? allowMismatchedPersonnels,
  MismatchedPersonnelReasonCode? mismatchedPersonnelReasonCode,
  // relations supplied as targets (optional)
  DeliveryVehicleModel? deliveryVehicleModel,
  LocalUsersModel? userModel,
  OtpModel? otpModel,
  EndTripOtpModel? endTripOtpModel,
  DeliveryTeamModel? deliveryTeamModel,
  List<PersonelModel>? personelsList,
  List<ChecklistModel>? checklistItems,
  List<CancelledInvoiceModel>? cancelledInvoices,
  List<CollectionModel>? deliveryCollections,
  List<EndTripChecklistModel>? endTripChecklistItems,
  List<TripUpdateModel>? tripUpdateList,
  List<DeliveryDataModel>? deliveryDataList,
}) : super(
      id: id,
      tripNumberId: tripNumberId,
      qrCode: qrCode,
      name: name,
      collectionId: collectionId,
      collectionName: collectionName,
      totalTripDistance: totalTripDistance,
      timeAccepted: timeAccepted,
      timeEndTrip: timeEndTrip,
      created: created,
      updated: updated,
      deliveryDate: deliveryDate,
      latitude: latitude,
      longitude: longitude,
      accuracy: accuracy,
      tripDistance: tripDistance,
      source: source,
      isAccepted: isAccepted,
      isEndTrip: isEndTrip,
      allowMismatchedPersonnels: allowMismatchedPersonnels,
      mismatchedPersonnelReasonCode: mismatchedPersonnelReasonCode,
      deliveryVehicle: deliveryVehicleModel,
      user: userModel,
      otp: otpModel,
      endTripOtp: endTripOtpModel,
      deliveryTeam: deliveryTeamModel,
      personels: personelsList,
      cancelledInvoices: cancelledInvoices,
      deliveryCollections: deliveryCollections,
      checklist: checklistItems,
      endTripChecklist: endTripChecklistItems,
      tripUpdates: tripUpdateList,
      deliveryData: deliveryDataList,
    ) {
  // --- IMPORTANT: assign subclass (overriding) fields so they are not left null ---
  this.collectionId = collectionId;
  this.collectionName = collectionName;
  this.tripNumberId = tripNumberId;
  this.qrCode = qrCode;
  this.name = name;
  this.totalTripDistance = totalTripDistance;
  
  this.timeAccepted = timeAccepted;
  this.timeEndTrip = timeEndTrip;
  this.created = created;
  this.updated = updated;
  this.deliveryDate = deliveryDate;

  this.latitude = latitude;
  this.longitude = longitude;
  this.accuracy = accuracy;
  this.tripDistance = tripDistance;
  this.source = source;

  this.isAccepted = isAccepted ?? false;
  this.isEndTrip = isEndTrip ?? false;
  this.allowMismatchedPersonnels = allowMismatchedPersonnels ?? false;
  this.mismatchedPersonnelReasonCode = mismatchedPersonnelReasonCode;

  // Set relations if provided (ToOne relations need explicit assignment to target)
  if (deliveryVehicleModel != null) deliveryVehicle.target = deliveryVehicleModel;
  if (userModel != null) user.target = userModel;
  if (otpModel != null) otp.target = otpModel;
  if (endTripOtpModel != null) endTripOtp.target = endTripOtpModel;
  if (deliveryTeamModel != null) deliveryTeam.target = deliveryTeamModel;

  if (personelsList != null && personelsList.isNotEmpty) {
    personels.clear();
    personels.addAll(personelsList);
  }
  if (deliveryCollections != null && deliveryCollections.isNotEmpty) {
    deliveryCollection.clear();
    deliveryCollection.addAll(deliveryCollections);
  }
  if (cancelledInvoices != null && cancelledInvoices.isNotEmpty) {
    cancelledInvoices.clear();
    cancelledInvoices.addAll(cancelledInvoices);
  }
  if (checklistItems != null && checklistItems.isNotEmpty) {
    checklist.clear();
    checklist.addAll(checklistItems);
  }
  if (endTripChecklistItems != null && endTripChecklistItems.isNotEmpty) {
    endTripChecklist.clear();
    endTripChecklist.addAll(endTripChecklistItems);
  }
  if (tripUpdateList != null && tripUpdateList.isNotEmpty) {
    tripUpdates.clear();
    tripUpdates.addAll(tripUpdateList);
  }
  if (deliveryDataList != null && deliveryDataList.isNotEmpty) {
    deliveryData.clear();
    deliveryData.addAll(deliveryDataList);
  }
}



// /// Convert numeric timestamp (s or ms) to DateTime
// static DateTime _timestampToDateTime(int ts) {
//   try {
//     // Detect if timestamp is in milliseconds or seconds
//     final isMilliseconds = ts > 1000000000000; // ~2001-09-09
//     return isMilliseconds
//         ? DateTime.fromMillisecondsSinceEpoch(ts, isUtc: true)
//         : DateTime.fromMillisecondsSinceEpoch(ts * 1000, isUtc: true);
//   } catch (e) {
//     debugPrint('⚠️ [_timestampToDateTime] Invalid timestamp: $ts → $e');
//     return DateTime.now().toUtc();
//   }
// }


  /// --- From JSON ---
factory TripModel.fromJson(dynamic json) {

   DateTime? safeParseDate(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  if (value is! String) return null;

  final v = value.trim();
  if (v.isEmpty) return null;                          // <-- FIX empty strings
  if (!RegExp(r'\d{4}-\d{2}-\d{2}').hasMatch(v)) return null; // <-- FIX invalid format

  try {
    return DateTime.parse(v);
  } catch (_) {
    return null;
  }
}
  debugPrint('🔄 MODEL: Creating TripModel from JSON');

  final expandedData = json['expand'] as Map<String, dynamic>?;
// -----------------------------
// Delivery Vehicle
// -----------------------------
DeliveryVehicleModel? deliveryVehicleModel;
final deliveryVehicleData = expandedData?['deliveryVehicle'] ?? json['deliveryVehicle'];
if (deliveryVehicleData != null) {
  if (deliveryVehicleData is Map<String, dynamic>) {
    // Full object received
    debugPrint("🚗 Using MAP to build vehicle");
    deliveryVehicleModel = DeliveryVehicleModel.fromJson(deliveryVehicleData);
  } else if (deliveryVehicleData is DeliveryVehicleModel) {
    // Already parsed model
    debugPrint("🚗 Using DIRECT MODEL for vehicle");
    deliveryVehicleModel = deliveryVehicleData;
  } else if (deliveryVehicleData is String && deliveryVehicleData.isNotEmpty) {
    // Only ID string received
    debugPrint("🚗 Only ID provided for vehicle: $deliveryVehicleData");
    deliveryVehicleModel = DeliveryVehicleModel(id: deliveryVehicleData);
  } else {
    debugPrint("❌ Unsupported vehicle data type: ${deliveryVehicleData.runtimeType}");
  }
}

// -----------------------------
// User
// -----------------------------
LocalUsersModel? userModel;
final userData = expandedData?['user'] ?? json['user'];
if (userData != null) {
  if (userData is Map<String, dynamic>) {
    debugPrint("👤 Using MAP to build user");
    userModel = LocalUsersModel.fromJson(userData);
  } else if (userData is LocalUsersModel) {
    debugPrint("👤 Using DIRECT MODEL for user");
    userModel = userData;
  } else if (userData is String && userData.isNotEmpty) {
    debugPrint("👤 Only ID provided for user: $userData");
    userModel = LocalUsersModel(id: userData);
  } else {
    debugPrint("❌ Unsupported user data type: ${userData.runtimeType}");
  }
}

// -----------------------------
// Delivery Team
// -----------------------------
DeliveryTeamModel? deliveryTeamModel;
final deliveryTeamData = expandedData?['deliveryTeam'] ?? json['deliveryTeam'];
if (deliveryTeamData != null) {
  if (deliveryTeamData is Map<String, dynamic>) {
    debugPrint("👥 Using MAP to build deliveryTeam");
    deliveryTeamModel = DeliveryTeamModel.fromJson(deliveryTeamData);
  } else if (deliveryTeamData is DeliveryTeamModel) {
    debugPrint("👥 Using DIRECT MODEL for deliveryTeam");
    deliveryTeamModel = deliveryTeamData;
  } else if (deliveryTeamData is String && deliveryTeamData.isNotEmpty) {
    debugPrint("👥 Only ID provided for deliveryTeam: $deliveryTeamData");
    deliveryTeamModel = DeliveryTeamModel(id: deliveryTeamData);
  } else {
    debugPrint("❌ Unsupported deliveryTeam data type: ${deliveryTeamData.runtimeType}");
  }
}

dynamic _firstFromList(dynamic v) {
  if (v is List && v.isNotEmpty) return v.first;
  return v;
}

// OTP
OtpModel? otpModel;
dynamic otpData = expandedData?['otp'] ?? json['otp'];

// ✅ normalize if list
otpData = _firstFromList(otpData);

if (otpData != null) {
  if (otpData is Map<String, dynamic>) {
    otpModel = OtpModel.fromJson(otpData);
  } else if (otpData is OtpModel) {
    otpModel = otpData;
  } else if (otpData is String && otpData.trim().isNotEmpty) {
    otpModel = OtpModel(id: otpData.trim());
  } else if (otpData.runtimeType.toString() == 'RecordModel') {
    // ✅ PocketBase RecordModel support (avoid import issues)
    final rec = otpData as dynamic;
    otpModel = OtpModel.fromJson({
      'id': rec.id,
      ...Map<String, dynamic>.from(rec.data),
    });
  } else {
    debugPrint("❌ Unsupported OTP data type: ${otpData.runtimeType}");
  }
}

// End Trip OTP
EndTripOtpModel? endTripOtpModel;
dynamic endTripOtpData = expandedData?['endTripOtp'] ?? json['endTripOtp'];

// ✅ normalize if list
endTripOtpData = _firstFromList(endTripOtpData);

if (endTripOtpData != null) {
  if (endTripOtpData is Map<String, dynamic>) {
    endTripOtpModel = EndTripOtpModel.fromJson(endTripOtpData);
  } else if (endTripOtpData is EndTripOtpModel) {
    endTripOtpModel = endTripOtpData;
  } else if (endTripOtpData is String && endTripOtpData.trim().isNotEmpty) {
    endTripOtpModel = EndTripOtpModel(id: endTripOtpData.trim());
  } else if (endTripOtpData.runtimeType.toString() == 'RecordModel') {
    final rec = endTripOtpData as dynamic;
    endTripOtpModel = EndTripOtpModel.fromJson({
      'id': rec.id,
      ...Map<String, dynamic>.from(rec.data),
    });
  } else {
    debugPrint(
      "❌ Unsupported End Trip OTP data type: ${endTripOtpData.runtimeType}",
    );
  }
}


  // -----------------------------
  // Personnels
  // -----------------------------
  List<PersonelModel> personelsList = [];
  final personelsData = expandedData?['personels'] ?? json['personels'];
  if (personelsData != null) {
    if (personelsData is List) {
      personelsList = personelsData
          .map((p) => p is String ? PersonelModel(id: p) : PersonelModel.fromJson(p))
          .toList();
    } else if (personelsData is Map<String, dynamic>) {
      personelsList = [PersonelModel.fromJson(personelsData)];
    }
  }

  // -----------------------------
  // Checklist
  // -----------------------------
  List<ChecklistModel> checklistItems = [];
  final checklistData = expandedData?['checklist'] ?? json['checklist'];
  if (checklistData != null) {
    if (checklistData is List) {
      checklistItems = checklistData.map((c) {
  if (c is String) {
    return ChecklistModel(id: c)..pocketbaseId = c; // IMPORTANT
  }
  return ChecklistModel.fromJson(c);
}).toList();

    } else if (checklistData is Map<String, dynamic>) {
      checklistItems = [ChecklistModel.fromJson(checklistData)];
    }
  }

  // -----------------------------
  // End Trip Checklist
  // -----------------------------
  List<EndTripChecklistModel> endTripList = [];
  final endTripData = expandedData?['endTripChecklists'] ?? json['endTripChecklists'];
  if (endTripData != null) {
    if (endTripData is List) {
      endTripList = endTripData
          .map((e) => e is String ? EndTripChecklistModel(id: e) : EndTripChecklistModel.fromJson(e))
          .toList();
    } else if (endTripData is Map<String, dynamic>) {
      endTripList = [EndTripChecklistModel.fromJson(endTripData)];
    }
  }

  // -----------------------------
  // End Trip Checklist
  // -----------------------------
  List<CollectionModel> collectionList = [];
  final collectionData = expandedData?['deliveryCollection'] ?? json['deliveryCollection'];
  if (collectionData != null) {
    if (collectionData is List) {
      collectionList = collectionData
          .map((e) => e is String ? CollectionModel(id: e) : CollectionModel.fromJson(e))
          .toList();
    } else if (collectionData is Map<String, dynamic>) {
      collectionList = [CollectionModel.fromJson(collectionData)];
    }
  }

   // -----------------------------
  // End Trip Checklist
  // -----------------------------
  List<CancelledInvoiceModel> cancelledInvoiceList = [];
  final cancelledInvoiceData = expandedData?['cancelledInvoices'] ?? json['cancelledInvoices'];
  if (cancelledInvoiceData != null) {
    if (cancelledInvoiceData is List) {
      cancelledInvoiceList = cancelledInvoiceData
          .map((e) => e is String ? CancelledInvoiceModel(id: e) : CancelledInvoiceModel.fromJson(e))
          .toList();
    } else if (cancelledInvoiceData is Map<String, dynamic>) {
      cancelledInvoiceList = [CancelledInvoiceModel.fromJson(cancelledInvoiceData)];
    }
  }
  // -----------------------------
  // Trip Updates
  // -----------------------------
  List<TripUpdateModel> tripUpdatesList = [];
  final tripUpdatesData = expandedData?['tripUpdates'] ?? json['tripUpdates'];
  if (tripUpdatesData != null) {
    if (tripUpdatesData is List) {
      tripUpdatesList = tripUpdatesData
          .map((t) => t is String ? TripUpdateModel(id: t) : TripUpdateModel.fromJson(t))
          .toList();
    } else if (tripUpdatesData is Map<String, dynamic>) {
      tripUpdatesList = [TripUpdateModel.fromJson(tripUpdatesData)];
    }
  }

  // -----------------------------
// Delivery Data
// -----------------------------
List<DeliveryDataModel> deliveryDataList = [];

final expandedDeliveryData = expandedData?['deliveryData'];
final rawDeliveryData = json['deliveryData'];

// PRIORITY: expanded version (contains nested customer, invoices, updates)
if (expandedDeliveryData is List) {
  deliveryDataList = expandedDeliveryData
      .map((d) => DeliveryDataModel.fromJson(d))
      .toList();
}
// FALLBACK: raw version (IDs only, no expand)
else if (rawDeliveryData is List) {
  deliveryDataList = rawDeliveryData
      .map((d) => d is String ? DeliveryDataModel(id: d) : DeliveryDataModel.fromJson(d))
      .toList();
}
// Single map case
else if (expandedDeliveryData is Map<String, dynamic>) {
  deliveryDataList = [DeliveryDataModel.fromJson(expandedDeliveryData)];
} else if (rawDeliveryData is Map<String, dynamic>) {
  deliveryDataList = [DeliveryDataModel.fromJson(rawDeliveryData)];
}


  // -----------------------------
  // Enum parser
  // -----------------------------
  MismatchedPersonnelReasonCode? parseReason(dynamic value) {
    if (value == null) return null;
    switch (value.toString().toLowerCase()) {
      case 'absent':
        return MismatchedPersonnelReasonCode.absent;
      case 'late':
        return MismatchedPersonnelReasonCode.late_;
      case 'leave':
        return MismatchedPersonnelReasonCode.leave;
      case 'none':
        return MismatchedPersonnelReasonCode.none;
      case 'others':
        return MismatchedPersonnelReasonCode.other;
      default:
        return null;
    }
  }

  final trip = TripModel(
  id: json['id']?.toString(),
  collectionId: json['collectionId']?.toString(),
  collectionName: json['collectionName']?.toString(),
  tripNumberId: json['tripNumberId']?.toString(),
  name: json['name']?.toString(),
  qrCode: json['qrCode']?.toString(),
  totalTripDistance: json['totalTripDistance']?.toString(),

  allowMismatchedPersonnels:
      json['allowMismatchedPersonnels'] as bool? ?? false,
  mismatchedPersonnelReasonCode:
      parseReason(json['mismatchedPersonnelReasonCode']),

  latitude: json['latitude'] != null
      ? double.tryParse(json['latitude'].toString())
      : null,
  longitude: json['longitude'] != null
      ? double.tryParse(json['longitude'].toString())
      : null,

  // ✅ FIXED DATE FIELDS — ALL USING _parseDate()
  timeAccepted: safeParseDate(json['timeAccepted']),
  deliveryDate: safeParseDate(json['deliveryDate']),
  timeEndTrip: safeParseDate(json['timeEndTrip']),
  created: safeParseDate(json['created']),
  updated: safeParseDate(json['updated']),
  // If you have dispatchDate:
  // dispatchDate: _parseDate(json['dispatchDate']),

  // relations
  deliveryVehicleModel: deliveryVehicleModel,
  deliveryTeamModel: deliveryTeamModel,
  userModel: userModel,
  otpModel: otpModel,
  endTripOtpModel: endTripOtpModel,
  personelsList: personelsList,
  checklistItems: checklistItems,
  endTripChecklistItems: endTripList,
  deliveryCollections: collectionList,
  tripUpdateList: tripUpdatesList,
  deliveryDataList: deliveryDataList,
  cancelledInvoices: cancelledInvoiceList,
);

  // -----------------------------
  // Assign relations
  // -----------------------------
  if (deliveryVehicleModel != null) trip.deliveryVehicle.target = deliveryVehicleModel;
  if (otpModel != null) trip.otp.target = otpModel;
  if (endTripOtpModel != null) trip.endTripOtp.target = endTripOtpModel;
  if (deliveryTeamModel != null) trip.deliveryTeam.target = deliveryTeamModel;
  if (userModel != null) trip.user.target = userModel;

 
  debugPrint(
      '✅ MODEL: Trip parsed - id:${trip.id}, name:${trip.name}, vehicle:${trip.deliveryVehicle.target?.name}, '
      'personnels:${trip.personels.length}, deliveryData:${trip.deliveryData.length}');
  return trip;
}

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'collectionId': collectionId,
      'collectionName': collectionName,
      'tripNumberId': tripNumberId,
      'qrCode': qrCode,
      'name': name,
      'totalTripDistance': totalTripDistance,
      'timeAccepted': timeAccepted?.toIso8601String(),
      'timeEndTrip': timeEndTrip?.toIso8601String(),
      'created': created?.toIso8601String(),
      'updated': updated?.toIso8601String(),
      'deliveryDate': deliveryDate?.toIso8601String(),
      'latitude': latitude?.toString(),
      'longitude': longitude?.toString(),
      'isAccepted': isAccepted,
      'isEndTrip': isEndTrip,
      'deliveryCollection': deliveryCollection.map((c) => c.id).toList(),
      'allowMismatchedPersonnels': allowMismatchedPersonnels,
      'mismatchedPersonnelReasonCode': _mismatchedPersonnelReasonCodeString,
      // relations as IDs (for push to server)
      'deliveryVehicle': deliveryVehicle.target?.id,
      'user': user.target?.id,
      'otp': otp.target?.id,
      'endTripOtp': endTripOtp.target?.id,
      'deliveryTeam': deliveryTeam.target?.id,
      'personels': personels.map((p) => p.id).toList(),
      'checklist': checklist.map((c) => c.id).toList(),
      'cancelledInvoices': cancelledInvoices.map((c) => c.id).toList(),
      'endTripChecklist': endTripChecklist.map((e) => e.id).toList(),
      'tripUpdates': tripUpdates.map((t) => t.id).toList(),
      'deliveryData': deliveryData.map((d) => d.id).toList(),
    };
  }

  TripModel copyWith({
    int? objectBoxId,
    String? pocketbaseId,
    String? id,
    String? collectionId,
    String? collectionName,
    String? tripNumberId,
    String? qrCode,
    String? name,
    String? totalTripDistance,
    DateTime? timeAccepted,
    DateTime? timeEndTrip,
    DateTime? created,
    DateTime? updated,
    DateTime? deliveryDate,
    double? latitude,
    double? longitude,
    bool? isAccepted,
    bool? isEndTrip,
    bool? allowMismatchedPersonnels,
    MismatchedPersonnelReasonCode? mismatchedPersonnelReasonCode,
    DeliveryVehicleModel? deliveryVehicleModel,
    LocalUsersModel? userModel,
    OtpModel? otpModel,
    EndTripOtpModel? endTripOtpModel,
    DeliveryTeamModel? deliveryTeamModel,
    List<PersonelModel>? personelsList,
    List<ChecklistModel>? checklistItems,
    List<EndTripChecklistModel>? endTripChecklistItems,
    List<TripUpdateModel>? tripUpdateList,
    List<CollectionModel>? deliveryCollections,
    List<DeliveryDataModel>? deliveryDataList,
    List<CancelledInvoiceModel>? cancelledInvoices,
  }) {
    final result = TripModel(
      id: id ?? this.id,
      collectionId: collectionId ?? this.collectionId,
      collectionName: collectionName ?? this.collectionName,
      tripNumberId: tripNumberId ?? this.tripNumberId,
      qrCode: qrCode ?? this.qrCode,
      name: name ?? this.name,
      totalTripDistance: totalTripDistance ?? this.totalTripDistance,
      timeAccepted: timeAccepted ?? this.timeAccepted,
      timeEndTrip: timeEndTrip ?? this.timeEndTrip,
      created: created ?? this.created,
      updated: updated ?? this.updated,
      deliveryDate: deliveryDate ?? this.deliveryDate,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      isAccepted: isAccepted ?? this.isAccepted,
      isEndTrip: isEndTrip ?? this.isEndTrip,
      allowMismatchedPersonnels: allowMismatchedPersonnels ?? this.allowMismatchedPersonnels,
      mismatchedPersonnelReasonCode: mismatchedPersonnelReasonCode ?? this.mismatchedPersonnelReasonCode,
      deliveryVehicleModel: deliveryVehicleModel ?? deliveryVehicle.target,
      userModel: userModel ?? user.target,
      otpModel: otpModel ?? otp.target,
      endTripOtpModel: endTripOtpModel ?? endTripOtp.target,
      deliveryTeamModel: deliveryTeamModel ?? deliveryTeam.target,
      personelsList: personelsList ?? personels.toList(),
      deliveryCollections: deliveryCollections ?? deliveryCollection.toList(),
      checklistItems: checklistItems ?? checklist.toList(),
      endTripChecklistItems: endTripChecklistItems ?? endTripChecklist.toList(),
      tripUpdateList: tripUpdateList ?? tripUpdates.toList(),
      cancelledInvoices: cancelledInvoices ?? this.cancelledInvoices.toList(),
      deliveryDataList: deliveryDataList ?? deliveryData.toList(),
      objectBoxId: objectBoxId ?? this.objectBoxId,
    );

    return result;
  }

  @override
  String toString() {
    return 'TripModel(id: $id, tripNumberId: $tripNumberId, name: $name, objectBoxId: $objectBoxId)';
  }
}
