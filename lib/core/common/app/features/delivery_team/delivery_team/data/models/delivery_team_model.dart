import 'package:flutter/foundation.dart';
import 'package:objectbox/objectbox.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_team/delivery_team/domain/entity/delivery_team_entity.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/trip/data/models/trip_models.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_team/personels/data/models/personel_models.dart';
import 'package:x_pro_delivery_app/core/common/app/features/checklists/intransit_checklist/data/model/checklist_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_team/delivery_vehicle_data/data/model/delivery_vehicle_model.dart';
import 'package:x_pro_delivery_app/core/utils/typedefs.dart';

@Entity()
class DeliveryTeamModel extends DeliveryTeamEntity {
  @Id()
  int objectBoxId = 0;

  @Property()
  String pocketbaseId;

  @Property()
  String? tripId;

  DeliveryTeamModel({
    String? id,
    String? collectionId,
    String? collectionName,
    List<PersonelModel>? personels,
    List<ChecklistModel>? checklist,
    DeliveryVehicleModel? deliveryVehicleModel,
    TripModel? tripModel,
    int? activeDeliveries,
    int? totalDelivered,
    double? totalDistanceTravelled,
    int? undeliveredCustomers,
    super.created,
    super.updated,
  }) : pocketbaseId = id ?? '',
       super(
         id: id ?? '',
         collectionId: collectionId ?? '',
         collectionName: collectionName ?? '',
         personels: personels ?? [],
         checklist: checklist ?? [],
         trip: tripModel,
         deliveryVehicle: deliveryVehicleModel,
         activeDeliveries: activeDeliveries ?? 0,
         totalDelivered: totalDelivered ?? 0,
         undeliveredCustomers: undeliveredCustomers ?? 0,
         totalDistanceTravelled: totalDistanceTravelled ?? 0.0,
       );
factory DeliveryTeamModel.fromJson(dynamic json) {
  final expandedData = json['expand'] as Map<String, dynamic>?;

  final tripData = expandedData?['trip'];
  TripModel? tripModel;
  if (tripData != null) { // FIXED: Changed condition
    if (tripData is RecordModel) {
      tripModel = TripModel.fromJson({
        'id': tripData.id,
        'collectionId': tripData.collectionId,
        'collectionName': tripData.collectionName,
        ...tripData.data,
      });
    } else if (tripData is Map) {
      tripModel = TripModel.fromJson(tripData as Map<String, dynamic>);
    }
  }

  // FIXED: Proper deliveryVehicle handling
  final deliveryVehicleData = expandedData?['deliveryVehicle'];
  DeliveryVehicleModel? deliveryVehicleModel;
  
  debugPrint('🚛 Processing delivery vehicle data: $deliveryVehicleData');
  
  if (deliveryVehicleData != null) {
    if (deliveryVehicleData is RecordModel) {
      debugPrint('🚛 Creating delivery vehicle from RecordModel: ${deliveryVehicleData.id}');
      deliveryVehicleModel = DeliveryVehicleModel.fromJson({
        'id': deliveryVehicleData.id,
        'collectionId': deliveryVehicleData.collectionId,
        'collectionName': deliveryVehicleData.collectionName,
        ...deliveryVehicleData.data,
      });
    } else if (deliveryVehicleData is Map) {
      debugPrint('🚛 Creating delivery vehicle from Map');
      deliveryVehicleModel = DeliveryVehicleModel.fromJson(
        deliveryVehicleData as Map<String, dynamic>,
      );
    }
  } else {
    debugPrint('⚠️ No delivery vehicle data found in expanded data');
    
    // ADDED: Try to get from the main data if not in expand
    final vehicleId = json['deliveryVehicle'];
    if (vehicleId != null) {
      debugPrint('🔍 Found delivery vehicle ID in main data: $vehicleId');
      // You might want to create a minimal model with just the ID
      // or trigger a separate fetch for the vehicle data
    }
  }

  debugPrint('🚛 Final delivery vehicle model: ${deliveryVehicleModel?.id ?? "null"}');

  // Handle personels expanded data
  final personelsList =
      (expandedData?['personels'] as List?)?.map((personel) {
        if (personel is RecordModel) {
          return PersonelModel.fromJson({
            'id': personel.id,
            'collectionId': personel.collectionId,
            'collectionName': personel.collectionName,
            ...personel.data,
          });
        }
        return PersonelModel.fromJson(personel as DataMap);
      }).toList() ??
      [];

  // Handle checklist expanded data
  final checklistItems =
      (expandedData?['checklist'] as List?)?.map((checklist) {
        if (checklist is RecordModel) {
          return ChecklistModel.fromJson({
            'id': checklist.id,
            'collectionId': checklist.collectionId,
            'collectionName': checklist.collectionName,
            ...checklist.data,
          });
        }
        return ChecklistModel.fromJson(checklist as DataMap);
      }).toList() ??
      [];

 

  return DeliveryTeamModel(
    id: json['id']?.toString(),
    collectionId: json['collectionId']?.toString(),
    collectionName: json['collectionName']?.toString(),
    tripModel: tripModel,
    personels: personelsList,
    deliveryVehicleModel: deliveryVehicleModel, // FIXED: Properly assign the model
    checklist: checklistItems,
    activeDeliveries: int.tryParse(
      json['activeDeliveries']?.toString() ?? '0',
    ),
    totalDelivered: int.tryParse(json['totalDelivered']?.toString() ?? '0'),
    undeliveredCustomers: int.tryParse(
      json['undeliveredCustomers']?.toString() ?? '0',
    ),
    totalDistanceTravelled: double.tryParse(
      json['totalDistanceTravelled']?.toString() ?? '0.0',
    ),
    created:
        json['created'] != null
            ? DateTime.parse(json['created'].toString())
            : null,
    updated:
        json['updated'] != null
            ? DateTime.parse(json['updated'].toString())
            : null,
  );
}


  DeliveryTeamModel copyWith({
    String? id,
    String? collectionId,
    String? collectionName,
    List<PersonelModel>? personels,
    List<ChecklistModel>? checklist,
    DeliveryVehicleModel? deliveryVehicleModel,
    TripModel? tripModel,
    int? activeDeliveries,
    int? undeliveredCustomers,
    int? totalDelivered,
    double? totalDistanceTravelled,
    DateTime? created,
    DateTime? updated,
  }) {
    return DeliveryTeamModel(
      id: id ?? this.id,
      collectionId: collectionId ?? this.collectionId,
      collectionName: collectionName ?? this.collectionName,
      personels: personels ?? this.personels.toList(),
      checklist: checklist ?? this.checklist.toList(),
      tripModel: tripModel ?? trip.target,
      activeDeliveries: activeDeliveries ?? this.activeDeliveries,
      deliveryVehicleModel: deliveryVehicleModel ?? deliveryVehicle.target,
      totalDelivered: totalDelivered ?? this.totalDelivered,
      undeliveredCustomers: undeliveredCustomers ?? this.undeliveredCustomers,
      totalDistanceTravelled:
          totalDistanceTravelled ?? this.totalDistanceTravelled,
      created: created ?? this.created,
      updated: updated ?? this.updated,
    );
  }
}
