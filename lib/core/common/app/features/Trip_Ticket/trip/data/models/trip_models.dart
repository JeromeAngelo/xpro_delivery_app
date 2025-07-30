import 'package:xpro_delivery_admin_app/core/common/app/features/Delivery_Team/delivery_team/data/models/delivery_team_model.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Delivery_Team/personels/data/models/personel_models.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/trip/domain/entity/trip_entity.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/trip_updates/data/model/trip_update_model.dart' show TripUpdateModel;
import 'package:xpro_delivery_admin_app/core/common/app/features/checklist/data/model/checklist_model.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/general_auth/data/models/auth_models.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/end_trip_checklist/data/model/end_trip_checklist_model.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/end_trip_otp/data/model/end_trip_model.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/cancelled_invoices/data/model/cancelled_invoice_model.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/otp/data/models/otp_models.dart';

import 'package:xpro_delivery_admin_app/core/typedefs/typedefs.dart';
import 'package:flutter/material.dart';
import 'package:pocketbase/pocketbase.dart';

// New imports for the updated model relationships
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/delivery_vehicle_data/data/model/delivery_vehicle_model.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/delivery_data/data/model/delivery_data_model.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/collection/data/model/collection_model.dart' as delivery_collection;

class TripModel extends TripEntity {
  String? pocketbaseId;

  TripModel({
    super.id,
    super.collectionId,
    super.collectionName,
    super.tripNumberId,
    List<PersonelModel>? personelsList,
    List<ChecklistModel>? checklistItems,
    DeliveryVehicleModel? vehicleModel, // Updated: Changed from List<VehicleModel> to DeliveryVehicleModel
    List<DeliveryDataModel>? deliveryDataList, // Added: New parameter for delivery data
    List<EndTripChecklistModel>? endTripChecklistItems,
    List<DeliveryTeamModel>? deliveryTeamList,
    List<TripUpdateModel>? tripUpdateList,
    List<delivery_collection.CollectionModel>? deliveryCollectionList,
    List<CancelledInvoiceModel>? cancelledInvoiceList, 
    super.latitude,
    super.longitude,
    super.averageFillRate,
    super.volumeRate,
    super.weightRate,
    super.user,
    super.totalTripDistance,
    super.otp,
    super.endTripOtp,
    super.deliveryTeam,
    super.timeAccepted,
    super.isEndTrip,
    super.timeEndTrip,
    super.created,
    super.name,
    super.updated,
    super.qrCode,
    super.isAccepted,
  }) : super(
          tripUpdates: tripUpdateList,
          personels: personelsList ?? [],
          checklist: checklistItems ?? [],
          vehicle: vehicleModel, // Updated: Changed from vehicleList to vehicleModel
          deliveryData: deliveryDataList ?? [], // Added: Initialize delivery data list
          deliveryCollection: deliveryCollectionList ?? [], // Added: Initialize delivery collection list
          cancelledInvoice: cancelledInvoiceList ?? [], // Added: Initialize cancelled invoice list
          endTripChecklist: endTripChecklistItems ?? [],
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
            deliveryTeamData as Map<String, dynamic>);
      }
    }

    // Handle user data
    final userData = expandedData?['user'] ?? json['user'];
    GeneralUserModel? usersModel;
    if (userData != null) {
      debugPrint('✅ MODEL: Processing user data: $userData');
      if (userData is RecordModel) {
        usersModel = GeneralUserModel.fromJson({
          'id': userData.id,
          'collectionId': userData.collectionId,
          'collectionName': userData.collectionName,
          ...userData.data
        });
      } else if (userData is Map) {
        usersModel = GeneralUserModel.fromJson(userData as DataMap);
      } else if (userData is String) {
        // Handle case where user data comes as just an ID string
        usersModel = GeneralUserModel(id: userData);
        debugPrint('⚠️ MODEL: User data is just ID string: $userData');
      }
      debugPrint('✅ MODEL: User name: ${usersModel?.name}');
    } else {
      debugPrint('⚠️ MODEL: No user data found');
    }

    // Handle Personels
    final personelsData = expandedData?['personels'] ?? json['personels'];
    List<PersonelModel> personelsList = [];
    if (personelsData != null) {
      if (personelsData is List) {
        personelsList = personelsData.map((personel) {
          if (personel is String) {
            return PersonelModel(id: personel);
          }
          return PersonelModel.fromJson(personel);
        }).toList();
      } else if (personelsData is Map<String, dynamic>) {
        personelsList = [PersonelModel.fromJson(personelsData)];
      }
    }

    // Handle Vehicle - Updated to handle a single DeliveryVehicleModel
    final vehicleData = expandedData?['deliveryVehicle'] ?? json['deliveryVehicle'];
    DeliveryVehicleModel? vehicleModel;
    if (vehicleData != null) {
      if (vehicleData is String) {
        vehicleModel = DeliveryVehicleModel(id: vehicleData);
      } else if (vehicleData is Map<String, dynamic>) {
        vehicleModel = DeliveryVehicleModel.fromJson(vehicleData);
      } else if (vehicleData is RecordModel) {
        vehicleModel = DeliveryVehicleModel.fromJson({
          'id': vehicleData.id,
          'collectionId': vehicleData.collectionId,
          'collectionName': vehicleData.collectionName,
          ...vehicleData.data,
        });
      }
    }

    // Handle DeliveryData - New relationship
    final deliveryDataList = expandedData?['deliveryData'] ?? json['deliveryData'];
    List<DeliveryDataModel> deliveryDataModels = [];
    if (deliveryDataList != null) {
      if (deliveryDataList is List) {
        deliveryDataModels = deliveryDataList.map((data) {
          if (data is String) {
            return DeliveryDataModel(id: data);
          }
          return DeliveryDataModel.fromJson(data);
        }).toList();
      } else if (deliveryDataList is Map<String, dynamic>) {
        deliveryDataModels = [DeliveryDataModel.fromJson(deliveryDataList)];
      }
    }

    final deliveryCollectionList = expandedData?['deliveryCollection'] ?? json['deliveryCollection'];
    List<delivery_collection.CollectionModel> deliveryCollectionModels = [];
    if (deliveryCollectionList != null) {
      if (deliveryCollectionList is List) {
        deliveryCollectionModels = deliveryCollectionList.map((data) {
          if (data is String) {
            return delivery_collection.CollectionModel(id: data);
          }
          return delivery_collection.CollectionModel.fromJson(data);
        }).toList();    
          }else if (deliveryCollectionList is Map<String, dynamic>) {
            deliveryCollectionModels = [delivery_collection.CollectionModel.fromJson(deliveryCollectionList)];
          }
        }

        final cancelledInvoiceList = expandedData?['cancelledInvoice'] ?? json['cancelledInvoice'];
        List<CancelledInvoiceModel> cancelledInvoiceModels = [];
        if (cancelledInvoiceList != null) {
          if (cancelledInvoiceList is List) {
            cancelledInvoiceModels = cancelledInvoiceList.map((data) {
              if (data is String) {
                return CancelledInvoiceModel(id: data);
              }
              return CancelledInvoiceModel.fromJson(data);
            }).toList();
          } else if (cancelledInvoiceList is Map<String, dynamic>) {
            cancelledInvoiceModels = [CancelledInvoiceModel.fromJson(cancelledInvoiceList)];
          }
        }
      
    

    // Handle Checklist
    final checklistData = expandedData?['checklist'] ?? json['checklist'];
    List<ChecklistModel> checklistItems = [];
    if (checklistData != null) {
      if (checklistData is List) {
        checklistItems = checklistData.map((item) {
          if (item is String) {
            return ChecklistModel(id: item);
          }
          return ChecklistModel.fromJson(item);
        }).toList();
      } else if (checklistData is Map<String, dynamic>) {
        checklistItems = [ChecklistModel.fromJson(checklistData)];
      }
    }

   
    // Handle EndTripChecklist
    final endTripData =
        expandedData?['endTripChecklist'] ?? json['endTripChecklist'];
    List<EndTripChecklistModel> endTripList = [];
    if (endTripData != null) {
      if (endTripData is List) {
        endTripList = endTripData.map((item) {
          if (item is String) {
            return EndTripChecklistModel(id: item);
          }
          return EndTripChecklistModel.fromJson(item);
        }).toList();
      } else if (endTripData is Map<String, dynamic>) {
        endTripList = [EndTripChecklistModel.fromJson(endTripData)];
      }
    }

        // Handle Trip Updates
    final tripUpdatesData =
        expandedData?['trip_update_list'] ?? json['trip_update_list'];
    List<TripUpdateModel> tripUpdatesList = [];
    if (tripUpdatesData != null) {
      if (tripUpdatesData is List) {
        tripUpdatesList = tripUpdatesData.map((update) {
          if (update is String) {
            return TripUpdateModel(id: update);
          }
          return TripUpdateModel.fromJson(update);
        }).toList();
      } else if (tripUpdatesData is Map<String, dynamic>) {
        tripUpdatesList = [TripUpdateModel.fromJson(tripUpdatesData)];
      }
    }

    // Handle OTP
    final otpData = expandedData?['otp'] ?? json['otp'];
    OtpModel? otpModel;
    if (otpData != null) {
      if (otpData is String) {
        otpModel = OtpModel(id: otpData);
      } else if (otpData is Map<String, dynamic>) {
        otpModel = OtpModel.fromJson(otpData);
      }
    }

    // Handle End Trip OTP
    final endTripOtpData = expandedData?['endTripOtp'] ?? json['endTripOtp'];
    EndTripOtpModel? endTripOtpModel;
    if (endTripOtpData != null) {
      if (endTripOtpData is String) {
        endTripOtpModel = EndTripOtpModel(id: endTripOtpData);
      } else if (endTripOtpData is Map<String, dynamic>) {
        endTripOtpModel = EndTripOtpModel.fromJson(endTripOtpData);
      }
    }

  

    return TripModel(
      id: json['id']?.toString(),
      collectionId: json['collectionId']?.toString(),
      collectionName: json['collectionName']?.toString(),
      tripNumberId: json['tripNumberId']?.toString(),
      name: json['name']?.toString(),
      personelsList: personelsList,
      checklistItems: checklistItems,
      vehicleModel: vehicleModel, // Updated: Changed from vehicleList to vehicleModel
      deliveryDataList: deliveryDataModels, // Added: Initialize delivery data list
      endTripChecklistItems: endTripList,
      cancelledInvoiceList: cancelledInvoiceModels,
      deliveryCollectionList: deliveryCollectionModels,
      tripUpdateList: tripUpdatesList,
      latitude: json['latitude'] != null
          ? double.tryParse(json['latitude'].toString())
          : null,
      longitude: json['longitude'] != null
          ? double.tryParse(json['longitude'].toString())
          : null,
       volumeRate: json['volumeRate'] != null ? double.tryParse(json['volumeRate'].toString()) : null,
       weightRate: json['weightRate'] != null ? double.tryParse(json['weightRate'].toString()) : null,
       averageFillRate: json['averageFillRate'] != null ? double.tryParse(json['averageFillRate'].toString()) : null,   
      user: usersModel,
      totalTripDistance: json['totalTripDistance']?.toString(),
      otp: otpModel,
      endTripOtp: endTripOtpModel,
      deliveryTeam: deliveryTeamModel,
      timeAccepted: json['timeAccepted'] != null
          ? _parseDateTime(json['timeAccepted'])
          : null,
      isEndTrip: json['isEndTrip'] as bool?,
      timeEndTrip: json['timeEndTrip'] != null
          ? _parseDateTime(json['timeEndTrip'])
          : null,
      created: json['created'] != null
          ? _parseDateTime(json['created'])
          : null,
      updated: json['updated'] != null
          ? _parseDateTime(json['updated'])
          : null,
      qrCode: json['qrCode']?.toString(),
      isAccepted: json['isAccepted'] as bool?,
    );
  }

  // Helper method for safe date parsing
  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    
    // If value is already a DateTime, return it directly
    if (value is DateTime) {
      return value;
    }
    
    try {
      return DateTime.parse(value.toString());
    } catch (e) {
      debugPrint('⚠️ TripModel date parsing failed: $e for value: ${value.toString()}');
      return null;
    }
  }

  DataMap toJson() {
    return {
      'id': id,
      'name': name,
      'collectionId': collectionId,
      'collectionName': collectionName,
      'tripNumberId': tripNumberId,
      'personels': personels.map((personel) => personel.id).toList(),
      'checklist': checklist.map((item) => item.id).toList(),
      'deliveryVehicle': vehicle?.id, // Updated: Changed from vehicle.map to vehicle?.id
      'deliveryData': deliveryData.map((data) => data.id).toList(), // Added: Map deliveryData to IDs
     'deliveryCollection': deliveryCollection!.map((collection) => collection.id).toList(),
      'cancelledInvoice': cancelledInvoice!.map((invoice) => invoice.id).toList(),
      'returns': returns.map((returnItem) => returnItem.id).toList(),
     
      'endTripChecklist':
          endTripChecklist.map((item) => item.id).toList(),
      'trip_update_list': tripUpdates.map((update) => update.id).toList(),
      'latitude': latitude,
      'longitude': longitude,
      'volumeRate': volumeRate,
      'weightRate': weightRate,
      'averageFillRate': averageFillRate,
      'user': user?.id,
      'totalTripDistance': totalTripDistance,
      'otp': otp?.id,
      'endTripOtp': endTripOtp?.id,
      'deliveryTeam': deliveryTeam?.id,
      'timeAccepted': timeAccepted?.toIso8601String(),
      'isEndTrip': isEndTrip,
      'timeEndTrip': timeEndTrip?.toIso8601String(),
      'created': created?.toIso8601String(),
      'updated': updated?.toIso8601String(),
      'qrCode': qrCode,
      'isAccepted': isAccepted,
    };
  }

  factory TripModel.fromEntity(TripEntity entity) {
    return TripModel(
      id: entity.id,
      collectionId: entity.collectionId,
      collectionName: entity.collectionName,
      name: entity.name,
      tripNumberId: entity.tripNumberId,
      personelsList: entity.personels,
      checklistItems: entity.checklist,
      vehicleModel: entity.vehicle as DeliveryVehicleModel?, // Updated: Changed from vehicleList to vehicleModel
      deliveryDataList: entity.deliveryData.cast<DeliveryDataModel>(), // Added: Cast deliveryData to DeliveryDataModel
      endTripChecklistItems: entity.endTripChecklist,
      tripUpdateList: entity.tripUpdates,
      latitude: entity.latitude,
      longitude: entity.longitude,
      volumeRate: entity.volumeRate,
      weightRate: entity.weightRate,
      averageFillRate: entity.averageFillRate,
      user: entity.user,
      totalTripDistance: entity.totalTripDistance,
      otp: entity.otp,
      endTripOtp: entity.endTripOtp,
      deliveryTeam: entity.deliveryTeam,
      timeAccepted: entity.timeAccepted,
      isEndTrip: entity.isEndTrip,
      timeEndTrip: entity.timeEndTrip,
      created: entity.created,
      updated: entity.updated,
      qrCode: entity.qrCode,
      isAccepted: entity.isAccepted,
    );
  }

  TripModel copyWith({
    String? id,
    String? collectionId,
    String? collectionName,
    String? tripNumberId,
    String? name,
    List<PersonelModel>? personelsList,
    List<ChecklistModel>? checklistItems,
    DeliveryVehicleModel? vehicleModel, // Updated: Changed from List<VehicleModel> to DeliveryVehicleModel
    List<DeliveryDataModel>? deliveryDataList, // Added: New parameter for delivery data
    List<EndTripChecklistModel>? endTripChecklistItems,
    List<TripUpdateModel>? tripUpdateList,
    List<delivery_collection.CollectionModel>? deliveryCollection, // Added: New parameter for delivery collection>
    List<CancelledInvoiceModel>? cancelledInvoice, // Added: New parameter for cancelled invoice>
    double? latitude,
    double? longitude,
    double? volumeRate,
    double? weightRate,
    double? averageFillRate,
    GeneralUserModel? user,
    String? totalTripDistance,
    OtpModel? otp,
    EndTripOtpModel? endTripOtp,
    DeliveryTeamModel? deliveryTeam,
    DateTime? timeAccepted,
    bool? isEndTrip,
    DateTime? timeEndTrip,
    DateTime? created,
    DateTime? updated,
    String? qrCode,
    bool? isAccepted,
    int? objectBoxId,
  }) {
    return TripModel(
      id: id ?? this.id,
      name: name ?? this.name,
      collectionId: collectionId ?? this.collectionId,
      collectionName: collectionName ?? this.collectionName,
      tripNumberId: tripNumberId ?? this.tripNumberId,
      personelsList: personelsList ?? personels,
      checklistItems: checklistItems ?? checklist,
      vehicleModel: vehicleModel ?? vehicle as DeliveryVehicleModel?, // Updated: Changed from vehicleList to vehicleModel
      deliveryDataList: deliveryDataList ?? deliveryData.cast<DeliveryDataModel>(), // Added: Cast deliveryData to DeliveryDataModel
      cancelledInvoiceList: cancelledInvoice ?? cancelledInvoice!.cast<CancelledInvoiceModel>(),
      deliveryCollectionList: deliveryCollection ?? deliveryCollection!.cast<delivery_collection.CollectionModel>(),
      endTripChecklistItems: endTripChecklistItems ?? endTripChecklist,
      tripUpdateList: tripUpdateList ?? tripUpdates,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      volumeRate: volumeRate ?? this.volumeRate,
      weightRate: weightRate ?? this.weightRate,
      averageFillRate: averageFillRate ?? this.averageFillRate,
      user: user ?? this.user,
      totalTripDistance: totalTripDistance ?? this.totalTripDistance,
      otp: otp ?? this.otp,
      endTripOtp: endTripOtp ?? this.endTripOtp,
      deliveryTeam: deliveryTeam ?? this.deliveryTeam,
      timeAccepted: timeAccepted ?? this.timeAccepted,
      isEndTrip: isEndTrip ?? this.isEndTrip,
      timeEndTrip: timeEndTrip ?? this.timeEndTrip,
      created: created ?? this.created,
      updated: updated ?? this.updated,
      qrCode: qrCode ?? this.qrCode,
      isAccepted: isAccepted ?? this.isAccepted,
    );
  }
}

