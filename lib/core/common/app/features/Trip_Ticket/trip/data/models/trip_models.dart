import 'package:flutter/material.dart';
import 'package:objectbox/objectbox.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_team/delivery_team/data/models/delivery_team_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/trip/domain/entity/trip_entity.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/trip_updates/data/model/trip_update_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/update_timeline/data/models/update_timeline_models.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_team/vehicle/data/model/vehicle_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_team/personels/data/models/personel_models.dart';
import 'package:x_pro_delivery_app/core/common/app/features/checklist/data/model/checklist_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/end_trip_checklist/data/model/end_trip_checklist_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/end_trip_otp/data/model/end_trip_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/otp/data/models/otp_models.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/delivery_data/data/model/delivery_data_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/delivery_vehicle_data/data/model/delivery_vehicle_model.dart';
import 'package:x_pro_delivery_app/core/utils/typedefs.dart';
import 'package:x_pro_delivery_app/src/auth/data/models/auth_models.dart';

import '../../../../../../../enums/mismatched_personnel_reason_code.dart';

@Entity()
class TripModel extends TripEntity {
  @Id(assignable: true)
  int objectBoxId = 0;

  @Property()
  String? pocketbaseId;

  TripModel({
    super.id,
    super.collectionId,
    super.collectionName,
    super.tripNumberId,
    UpdateTimelineModel? timelineModel,
    List<PersonelModel>? personelsList,
    List<ChecklistModel>? checklistItems,
    List<VehicleModel>? vehicleList,
    List<EndTripChecklistModel>? endTripChecklistItems,
    List<DeliveryTeamModel>? deliveryTeamList,
    List<TripUpdateModel>? tripUpdateList,
    List<DeliveryDataModel>? deliveryDataList,
    super.deliveryVehicle,
    super.user,
    super.totalTripDistance,
    super.allowMismatchedPersonnels,
    super.mismatchedPersonnelReasonCode,
    super.otp,
    super.latitude,
    super.longitude,
    super.endTripOtp,
    super.deliveryTeam,
    super.timeAccepted,
    super.name,
    super.isEndTrip,
    super.deliveryDate,
    super.timeEndTrip,
    super.created,
    super.updated,
    super.qrCode,
    super.isAccepted,
    this.objectBoxId = 0,
  }) : super(
         tripUpdates: tripUpdateList,
        
         timeline: timelineModel,
         personels: personelsList,
         checklist: checklistItems,
         vehicle: vehicleList,
       
         endTripChecklist: endTripChecklistItems,
         deliveryData: deliveryDataList,
       );

  factory TripModel.fromJson(dynamic json) {
    debugPrint('🔄 MODEL: Creating TripModel from JSON');

    if (json is String) {
      debugPrint('⚠️ MODEL: JSON is String - $json');
      return TripModel(id: json);
    }

    final expandedData = json['expand'] as Map<String, dynamic>?;

  

    // Handle delivery team data
    final deliveryTeamData = expandedData?['deliveryTeam'];
    DeliveryTeamModel? deliveryTeamModel;
    if (deliveryTeamData != null) {
      if (deliveryTeamData is RecordModel) {
        deliveryTeamModel = DeliveryTeamModel.fromJson({
          'id': deliveryTeamData.id,
          'collectionId': deliveryTeamData.collectionId,
          'collectionName': deliveryTeamData.collectionName,
          ...deliveryTeamData.data,
        });
      } else if (deliveryTeamData is Map) {
        deliveryTeamModel = DeliveryTeamModel.fromJson(
          deliveryTeamData as Map<String, dynamic>,
        );
      }
    }

    final userData = expandedData?['user'];
    LocalUsersModel? usersModel;
    if (userData != null) {
      if (userData is RecordModel) {
        usersModel = LocalUsersModel.fromJson({
          'id': userData.id,
          'collectionId': userData.collectionId,
          'collectionName': userData.collectionName,
          ...userData.data,
        });
      } else if (userData is Map) {
        usersModel = LocalUsersModel.fromJson(userData as DataMap);
      }
    }

    final deliveryVehicleData = expandedData?['deliveryVehicle'];
    DeliveryVehicleModel? deliveryVehicleModel;
    if (deliveryVehicleData != null) {
      if (deliveryVehicleData is RecordModel) {
        deliveryVehicleModel = DeliveryVehicleModel.fromJson({
          'id': deliveryVehicleData.id,
          'collectionId': deliveryVehicleData.collectionId,
          'collectionName': deliveryVehicleData.collectionName,
          ...deliveryVehicleData.data,
        });
      } else if (deliveryVehicleData is Map) {
        deliveryVehicleModel = DeliveryVehicleModel.fromJson(
          deliveryVehicleData as Map<String, dynamic>,
        );
      }
    }

    // Handle Personels
    final personelsData = expandedData?['personels'] ?? json['personels'];
    List<PersonelModel> personelsList = [];
    if (personelsData != null) {
      if (personelsData is List) {
        personelsList =
            personelsData.map((personel) {
              if (personel is String) {
                return PersonelModel(id: personel);
              }
              return PersonelModel.fromJson(personel);
            }).toList();
      } else if (personelsData is Map<String, dynamic>) {
        personelsList = [PersonelModel.fromJson(personelsData)];
      }
    }

    // Handle Vehicle
    final vehicleData = expandedData?['vehicle'] ?? json['vehicle'];
    List<VehicleModel> vehicleList = [];
    if (vehicleData != null) {
      if (vehicleData is List) {
        vehicleList =
            vehicleData.map((vehicle) {
              if (vehicle is String) {
                return VehicleModel(id: vehicle);
              }
              return VehicleModel.fromJson(vehicle);
            }).toList();
      } else if (vehicleData is Map<String, dynamic>) {
        vehicleList = [VehicleModel.fromJson(vehicleData)];
      }
    }

    // Handle Checklist
    final checklistData = expandedData?['checklist'] ?? json['checklist'];
    List<ChecklistModel> checklistItems = [];
    if (checklistData != null) {
      if (checklistData is List) {
        checklistItems =
            checklistData.map((item) {
              if (item is String) {
                return ChecklistModel(id: item);
              }
              return ChecklistModel.fromJson(item);
            }).toList();
      } else if (checklistData is Map<String, dynamic>) {
        checklistItems = [ChecklistModel.fromJson(checklistData)];
      }
    }

   

   

  

    // Handle Transactions
   

    // Handle EndTripChecklist
    final endTripData =
        expandedData?['endTripChecklist'] ?? json['endTripChecklist'];
    List<EndTripChecklistModel> endTripList = [];
    if (endTripData != null) {
      if (endTripData is List) {
        endTripList =
            endTripData.map((item) {
              if (item is String) {
                return EndTripChecklistModel(id: item);
              }
              return EndTripChecklistModel.fromJson(item);
            }).toList();
      } else if (endTripData is Map<String, dynamic>) {
        endTripList = [EndTripChecklistModel.fromJson(endTripData)];
      }
    }

    final tripUpdatesData = expandedData?['tripUpdates'] as List?;
    List<TripUpdateModel> tripUpdatesList = [];
    if (tripUpdatesData != null) {
      tripUpdatesList =
          tripUpdatesData.map((update) {
            if (update is String) {
              return TripUpdateModel(id: update);
            }
            return TripUpdateModel.fromJson(update);
          }).toList();
    }

    // Handle DeliveryData
    final deliveryDataData =
        expandedData?['deliveryData'] ?? json['deliveryData'];
    List<DeliveryDataModel> deliveryDataList = [];
    if (deliveryDataData != null) {
      if (deliveryDataData is List) {
        deliveryDataList =
            deliveryDataData.map((data) {
              if (data is String) {
                return DeliveryDataModel(id: data);
              }
              return DeliveryDataModel.fromJson(data);
            }).toList();
      } else if (deliveryDataData is Map<String, dynamic>) {
        deliveryDataList = [DeliveryDataModel.fromJson(deliveryDataData)];
      }
    }

    // Parse payment selection enum
    MismatchedPersonnelReasonCode? parseReasonSelection(dynamic value) {
      if (value == null || value.toString().isEmpty) return null;
      try {
        final enumValue = value.toString().toLowerCase();
        switch (enumValue) {
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
            debugPrint('⚠️ Unknown payment mode: $enumValue');
            return null;
        }
      } catch (e) {
        debugPrint('❌ Error parsing payment selection: $e');
        return null;
      }
    }

    return TripModel(
      id: json['id']?.toString(),
      collectionId: json['collectionId']?.toString(),
      collectionName: json['collectionName']?.toString(),
      tripNumberId: json['tripNumberId']?.toString(),
      name: json['name']?.toString(),
      qrCode: json['qrCode']?.toString(),
      deliveryTeam: deliveryTeamModel,
      mismatchedPersonnelReasonCode: parseReasonSelection(json['mismatchedPersonnelReasonCode']),
      allowMismatchedPersonnels: json['allowMismatchedPersonnels'] as bool? ?? false,
      user: usersModel,
      totalTripDistance: json['totalTripDistance']?.toString(),
      personelsList: personelsList,
      deliveryVehicle: deliveryVehicleModel,
      vehicleList: vehicleList,
      checklistItems: checklistItems,
      endTripChecklistItems: endTripList,
      tripUpdateList: tripUpdatesList,
      deliveryDataList: deliveryDataList,
      latitude:
          json['latitude'] != null
              ? double.tryParse(json['latitude'].toString())
              : null,
      longitude:
          json['longitude'] != null
              ? double.tryParse(json['longitude'].toString())
              : null,
      timeAccepted:
          json['timeAccepted'] != null
              ? DateTime.parse(json['timeAccepted'].toString())
              : null,
               deliveryDate:
          json['deliveryDate'] != null
              ? DateTime.parse(json['deliveryDate'].toString())
              : null,
      isEndTrip: json['isEndTrip'] as bool? ?? false,
      timeEndTrip:
          json['timeEndTrip'] != null
              ? DateTime.parse(json['timeEndTrip'].toString())
              : null,
      created:
          json['created'] != null
              ? DateTime.parse(json['created'].toString())
              : null,
      updated:
          json['updated'] != null
              ? DateTime.parse(json['updated'].toString())
              : null,
      isAccepted: json['isAccepted'] as bool? ?? false,
    );
  }

  DataMap toJson() {
     String? reasonSelectionString;
    if (mismatchedPersonnelReasonCode != null) {
      switch (mismatchedPersonnelReasonCode!) {
        case  MismatchedPersonnelReasonCode.absent:
          reasonSelectionString = 'absent';
          break;
        case  MismatchedPersonnelReasonCode.late_:
          reasonSelectionString = 'late';
           case  MismatchedPersonnelReasonCode.managementApproved:
          reasonSelectionString = 'managementApproved';
          break;
        case  MismatchedPersonnelReasonCode.leave:
          reasonSelectionString = 'leave';
          break;
        case  MismatchedPersonnelReasonCode.none:
          reasonSelectionString = 'none';
          break;
           case  MismatchedPersonnelReasonCode.other:
          reasonSelectionString = 'other';
          break;
      }
    }
    return {
      'id': id,
      'collectionId': collectionId,
      'collectionName': collectionName,
      'tripNumberId': tripNumberId,
      'qrCode': qrCode,
      'checklist': checklist.map((c) => c.id).toList(),
      'deliveryTeam': deliveryTeam.target?.id,
      'user': user.target?.id,
      'deliveryVehicle': deliveryVehicle.target?.id,
      'personels': personels.map((p) => p.id).toList(),
      'vehicle': vehicle.map((v) => v.id).toList(),
      'mismatchedPersonnelReasonCode': reasonSelectionString,
      'endTripChecklist': endTripChecklist.map((e) => e.id).toList(),
      'deliveryData': deliveryData.map((d) => d.id).toList(),
      'created': created?.toIso8601String(),
      'updated': updated?.toIso8601String(),
      'timeAccepted': timeAccepted?.toIso8601String(),
      'totalTripDistance': totalTripDistance,
      'latitude': latitude?.toString(),
      'longitude': longitude?.toString(),
      'isEndTrip': isEndTrip,
      'timeEndTrip': timeEndTrip?.toIso8601String(),
      'name':name,
      'deliveryDate': deliveryDate?.toIso8601String(),
      'isAccepted': isAccepted,
      'allowMismatchedPersonnels' : allowMismatchedPersonnels,
      'otp': otp.target?.id,
      'endTripOtp': endTripOtp.target?.id,
    };
  }

  TripModel copyWith({
    String? id,
    String? collectionId,
    String? collectionName,
    String? tripNumberId,
    String? totalTripDistance,
    String? qrCode,
  MismatchedPersonnelReasonCode? mismatchedPersonnelReasonCode,
    List<PersonelModel>? personelsList,
    List<ChecklistModel>? checklistItems,
    List<VehicleModel>? vehicleList,
  String? name,
    List<EndTripChecklistModel>? endTripChecklistItems,
    List<TripUpdateModel>? tripUpdateList,
    List<DeliveryDataModel>? deliveryDataList,
    DeliveryVehicleModel? deliveryVehicle,
    LocalUsersModel? user,
    OtpModel? otp,
    EndTripOtpModel? endTripOtp,
    double? latitude,
    double? longitude,
    bool? isEndTrip,
    DateTime? timeEndTrip,
    DateTime? created,
    DateTime? updated,
    DateTime? timeAccepted,
    DateTime? deliveryDate,
    bool? isAccepted,
  }) {
    return TripModel(
      id: id ?? this.id,
      totalTripDistance: totalTripDistance ?? this.totalTripDistance,
      collectionId: collectionId ?? this.collectionId,
      collectionName: collectionName ?? this.collectionName,
      tripNumberId: tripNumberId ?? this.tripNumberId,
      qrCode: qrCode ?? this.qrCode,
      personelsList: personelsList ?? personels.toList(),
      checklistItems: checklistItems ?? checklist.toList(),
      vehicleList: vehicleList ?? vehicle.toList(),
      allowMismatchedPersonnels: allowMismatchedPersonnels ?? allowMismatchedPersonnels,
      mismatchedPersonnelReasonCode: mismatchedPersonnelReasonCode ?? this.mismatchedPersonnelReasonCode,
      endTripChecklistItems: endTripChecklistItems ?? endTripChecklist.toList(),
      deliveryDataList: deliveryDataList ?? deliveryData.toList(),
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      timeAccepted: timeAccepted ?? this.timeAccepted,
      deliveryDate: deliveryDate ?? this.deliveryDate,
      name: name ?? this.name,
      created: created ?? this.created,
      updated: updated ?? this.updated,
      isAccepted: isAccepted ?? this.isAccepted,
      user: user ?? this.user.target,
      deliveryVehicle: deliveryVehicle ?? this.deliveryVehicle.target,
      otp: otp ?? this.otp.target,
      endTripOtp: endTripOtp ?? this.endTripOtp.target,
      isEndTrip: isEndTrip ?? this.isEndTrip,
      timeEndTrip: timeEndTrip ?? this.timeEndTrip,
      objectBoxId: objectBoxId,
    );
  }
}
