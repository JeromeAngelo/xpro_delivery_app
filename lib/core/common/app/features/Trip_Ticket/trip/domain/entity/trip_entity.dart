import 'package:xpro_delivery_admin_app/core/common/app/features/Delivery_Team/delivery_team/data/models/delivery_team_model.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Delivery_Team/personels/data/models/personel_models.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/return_product/data/model/return_model.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/trip_updates/data/model/trip_update_model.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/checklist/data/model/checklist_model.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/general_auth/data/models/auth_models.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/end_trip_checklist/data/model/end_trip_checklist_model.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/end_trip_otp/data/model/end_trip_model.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/cancelled_invoices/domain/entity/cancelled_invoice_entity.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/otp/data/models/otp_models.dart';
import 'package:equatable/equatable.dart';

// New imports for the updated entity relationships
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/delivery_vehicle_data/domain/enitity/delivery_vehicle_entity.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/delivery_data/domain/entity/delivery_data_entity.dart';

import '../../../collection/domain/entity/collection_entity.dart';

class TripEntity extends Equatable {
  String? id;
  String? collectionId;
  String? collectionName;
  String? tripNumberId;
  String? name;
  final DeliveryTeamModel? deliveryTeam;
  final List<PersonelModel> personels;
  final List<ChecklistModel> checklist;

  // Updated: Changed from List<VehicleModel> to DeliveryVehicleEntity
  final DeliveryVehicleEntity? vehicle;

  // Added: New relationship for delivery data
  final List<DeliveryDataEntity> deliveryData;
  final List<CancelledInvoiceEntity>? cancelledInvoice; // New field>
  final List<CollectionEntity>? deliveryCollection; // New field>
  final List<ReturnModel> returns;
  final List<EndTripChecklistModel> endTripChecklist;
  final List<TripUpdateModel> tripUpdates;

  final OtpModel? otp;
  final EndTripOtpModel? endTripOtp;
  final GeneralUserModel? user;
  double? latitude;
  double? longitude;
  double? volumeRate;
  double? weightRate;
  double? averageFillRate;
  String? totalTripDistance;
  bool? isAccepted;
  bool? isEndTrip;
  DateTime? timeEndTrip;
  DateTime? timeAccepted;
   DateTime? deliveryDate;
  DateTime? created;
  DateTime? updated;
  String? qrCode;

  TripEntity({
    this.id,
    this.collectionId,
    this.collectionName,
    this.tripNumberId,
    this.deliveryTeam,
    this.deliveryDate,
    this.name,
    List<PersonelModel>? personels,
    List<ChecklistModel>? checklist,
    List<TripUpdateModel>? tripUpdates,
    this.vehicle, // Updated: Changed from List<VehicleModel> to DeliveryVehicleEntity
    List<DeliveryDataEntity>?
    deliveryData, // Added: New parameter for delivery data
    List<ReturnModel>? returns,
    List<EndTripChecklistModel>? endTripChecklist,
    this.deliveryCollection,
    this.otp,
    this.endTripOtp,
    this.volumeRate,
    this.weightRate,
    this.averageFillRate,
    this.user,
    this.totalTripDistance,
    this.cancelledInvoice,
    this.timeEndTrip,
    this.isEndTrip,
    this.timeAccepted,
    this.isAccepted,
    this.qrCode,
    this.created,
    this.updated,
    this.latitude,
    this.longitude,
  }) : personels = personels ?? [],
       checklist = checklist ?? [],
       
       deliveryData =
           deliveryData ?? [], // Added: Initialize delivery data list

       returns = returns ?? [],

       endTripChecklist = endTripChecklist ?? [],
       tripUpdates = tripUpdates ?? [];

  @override
  List<Object?> get props => [
    id,
    name,
    tripNumberId,
    deliveryTeam?.id,
    user?.id,
    totalTripDistance,
    personels,
    vehicle?.id, // Updated: Changed from vehicle to vehicle?.id
    deliveryData, // Added: Include deliveryData in props
    checklist,
    returns,
    endTripChecklist,
    volumeRate,
    weightRate,
    averageFillRate,
    tripUpdates,
    timeAccepted,
    cancelledInvoice,
    deliveryCollection,
    deliveryDate,
    otp?.id,
    endTripOtp?.id,
    timeEndTrip,
    isEndTrip,
    qrCode,
    isAccepted,
    created,
    updated,
    latitude,
    longitude,
  ];
}
