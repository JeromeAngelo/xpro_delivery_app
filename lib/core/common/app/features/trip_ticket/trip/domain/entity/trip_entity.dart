import 'package:equatable/equatable.dart';
import 'package:objectbox/objectbox.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_team/delivery_team/data/models/delivery_team_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_team/personels/data/models/personel_models.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/trip_updates/data/model/trip_update_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/checklists/intransit_checklist/data/model/checklist_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/checklists/end_trip_checklist/data/model/end_trip_checklist_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/otp/end_trip_otp/data/model/end_trip_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/delivery_data/data/model/delivery_data_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_team/delivery_vehicle_data/data/model/delivery_vehicle_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/users/auth/data/models/auth_models.dart';

import '../../../../../../../enums/mismatched_personnel_reason_code.dart';
import '../../../../otp/intransit_otp/data/models/otp_models.dart';
import '../../../cancelled_invoices/data/model/cancelled_invoice_model.dart';
import '../../../delivery_collection/data/model/collection_model.dart' show CollectionModel;

@Entity()
class TripEntity extends Equatable {
  @Id()
  int dbId = 0;

  String? id;
  String? collectionId;
  String? collectionName;
  String? tripNumberId;
  String? name;
  final ToOne<DeliveryTeamModel> deliveryTeam = ToOne<DeliveryTeamModel>();
  final ToMany<PersonelModel> personels = ToMany<PersonelModel>();
  final ToMany<ChecklistModel> checklist = ToMany<ChecklistModel>();

  final ToMany<EndTripChecklistModel> endTripChecklist =
      ToMany<EndTripChecklistModel>();
  final ToMany<TripUpdateModel> tripUpdates = ToMany<TripUpdateModel>();
  final ToOne<OtpModel> otp = ToOne<OtpModel>();
  final ToOne<EndTripOtpModel> endTripOtp = ToOne<EndTripOtpModel>();
  final ToOne<LocalUsersModel> user = ToOne<LocalUsersModel>();
  // Added deliveryData relation
  final ToMany<DeliveryDataModel> deliveryData = ToMany<DeliveryDataModel>();
    final ToMany<CollectionModel> deliveryCollection = ToMany<CollectionModel>();
    final ToMany<CancelledInvoiceModel> cancelledInvoices = ToMany<CancelledInvoiceModel>();

  final ToOne<DeliveryVehicleModel> deliveryVehicle =
      ToOne<DeliveryVehicleModel>();

  double? latitude; // Added latitude field
  double? longitude; // Added longitude field
  double? accuracy;
  double? tripDistance;
  String? source;
  String? totalTripDistance;
  bool? allowMismatchedPersonnels;
  bool? isAccepted;
  bool? isEndTrip;
  MismatchedPersonnelReasonCode? mismatchedPersonnelReasonCode;
  DateTime? timeEndTrip;
  DateTime? timeAccepted;
  DateTime? created;
  DateTime? updated;
  DateTime? deliveryDate;
  String? qrCode;
  TripEntity({
    this.id,
    this.collectionId,
    this.collectionName,
    this.tripNumberId,
    this.name,
    this.deliveryDate,
    DeliveryTeamModel? deliveryTeam,
    List<PersonelModel>? personels,
    List<ChecklistModel>? checklist,
    List<TripUpdateModel>? tripUpdates,
    List<EndTripChecklistModel>? endTripChecklist,
    List<CollectionModel>? deliveryCollections,
    List<CancelledInvoiceModel>? cancelledInvoices,
    OtpModel? otp,
    EndTripOtpModel? endTripOtp,
    LocalUsersModel? user,
    List<DeliveryDataModel>? deliveryData, // Added parameter for deliveryData
    DeliveryVehicleModel? deliveryVehicle,
    this.latitude, // Added to constructor
    this.longitude, // Added to constructor
    this.totalTripDistance,
    this.mismatchedPersonnelReasonCode,
    this.timeEndTrip,
    this.allowMismatchedPersonnels,
    this.isEndTrip,
    this.timeAccepted,
    this.isAccepted,
    this.accuracy,
    this.tripDistance,
    this.source,

    this.qrCode,
    this.created,
    this.updated,
  }) {
    if (deliveryTeam != null) this.deliveryTeam.target = deliveryTeam;
    if (personels != null) this.personels.addAll(personels);
    if (checklist != null) this.checklist.addAll(checklist);
    if (deliveryVehicle != null) this.deliveryVehicle.target = deliveryVehicle;
    if (deliveryCollections != null) this.deliveryCollection.addAll(deliveryCollections);
    if (user != null) this.user.target = user;
    if (cancelledInvoices != null) this.cancelledInvoices.addAll(cancelledInvoices);
    if (endTripChecklist != null) {
      this.endTripChecklist.addAll(endTripChecklist);
    }
    if (tripUpdates != null) this.tripUpdates.addAll(tripUpdates);
    if (otp != null) this.otp.target = otp;
    if (endTripOtp != null) this.endTripOtp.target = endTripOtp;
    // Initialize deliveryData relation
    if (deliveryData != null) this.deliveryData.addAll(deliveryData);
  }

  factory TripEntity.empty() {
  final trip = TripEntity(
    id: '',
    collectionId: '',
    collectionName: '',
    tripNumberId: '',
    name: 'No Trip Assigned',
    deliveryDate: null,
    deliveryTeam: null,
    personels: const [],
    checklist: const [],
    tripUpdates: const [],
    endTripChecklist: const [],
    cancelledInvoices: const [],
    otp: null,
    endTripOtp: null,
    user: null,
    deliveryData: const [],
    deliveryVehicle: null,
    latitude: 0.0,
    longitude: 0.0,
    accuracy: 0.0,
    tripDistance: 0.0,
    deliveryCollections: const [],
    totalTripDistance: '0',
    source: '',
    mismatchedPersonnelReasonCode: null,
    allowMismatchedPersonnels: false,
    isEndTrip: false,
    isAccepted: false,
    qrCode: '',
    created: DateTime.now(),
    updated: DateTime.now(),
  );

  // Explicitly ensure all ToOne relations remain empty (null target)
  trip.deliveryTeam.target = null;
  trip.deliveryVehicle.target = null;
  trip.otp.target = null;
  trip.endTripOtp.target = null;
  trip.user.target = null;

  // ToMany lists are already initialized automatically by ObjectBox
  trip.personels.clear();
  trip.checklist.clear();
  trip.endTripChecklist.clear();
  trip.deliveryCollection.clear();
  trip.cancelledInvoices.clear();
  trip.tripUpdates.clear();
  trip.deliveryData.clear();

  return trip;
}


  @override
  List<Object?> get props => [
    id,
    tripNumberId,
    deliveryTeam.target?.id,
    user.target?.id,
    deliveryVehicle.target?.id,
    totalTripDistance,
    personels,
    checklist,
    endTripChecklist,
    tripUpdates,
    mismatchedPersonnelReasonCode,
    allowMismatchedPersonnels,
    timeAccepted,
    otp.target?.id,
    endTripOtp.target?.id,
    timeEndTrip,
    isEndTrip,
    name,
    deliveryDate,
    deliveryCollection,
    cancelledInvoices,
    qrCode,
    isAccepted,
    created,
    updated,
    latitude, // Added to props
    longitude, // Added to props
    accuracy,
    tripDistance,
    deliveryData, // Added to props
  ];
}
