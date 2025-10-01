import 'package:equatable/equatable.dart';
import 'package:objectbox/objectbox.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_team/delivery_team/data/models/delivery_team_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_team/personels/data/models/personel_models.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/trip_updates/data/model/trip_update_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/checklists/intransit_checklist/data/model/checklist_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/checklists/end_trip_checklist/data/model/end_trip_checklist_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/otp/end_trip_otp/data/model/end_trip_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/delivery_data/data/model/delivery_data_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_team/delivery_vehicle_data/data/model/delivery_vehicle_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/users/auth/data/models/auth_models.dart';

import '../../../../../../../enums/mismatched_personnel_reason_code.dart';
import '../../../../otp/intransit_otp/data/models/otp_models.dart';

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
  final ToOne<DeliveryVehicleModel> deliveryVehicle =
      ToOne<DeliveryVehicleModel>();

  double? latitude; // Added latitude field
  double? longitude; // Added longitude field
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
    this.qrCode,
    this.created,
    this.updated,
  }) {
    if (deliveryTeam != null) this.deliveryTeam.target = deliveryTeam;
    if (personels != null) this.personels.addAll(personels);
    if (checklist != null) this.checklist.addAll(checklist);
    if (deliveryVehicle != null) this.deliveryVehicle.target = deliveryVehicle;

    if (user != null) this.user.target = user;

    if (endTripChecklist != null) {
      this.endTripChecklist.addAll(endTripChecklist);
    }
    if (tripUpdates != null) this.tripUpdates.addAll(tripUpdates);
    if (otp != null) this.otp.target = otp;
    if (endTripOtp != null) this.endTripOtp.target = endTripOtp;
    // Initialize deliveryData relation
    if (deliveryData != null) this.deliveryData.addAll(deliveryData);
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
    qrCode,
    isAccepted,
    created,
    updated,
    latitude, // Added to props
    longitude, // Added to props
    deliveryData, // Added to props
  ];
}
