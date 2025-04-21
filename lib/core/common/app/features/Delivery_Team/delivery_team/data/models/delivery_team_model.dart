import 'package:objectbox/objectbox.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Delivery_Team/delivery_team/domain/entity/delivery_team_entity.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/trip/data/models/trip_models.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Delivery_Team/vehicle/data/model/vehicle_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Delivery_Team/personels/data/models/personel_models.dart';
import 'package:x_pro_delivery_app/core/common/app/features/checklist/data/model/checklist_model.dart';
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
    List<VehicleModel>? vehicleList,
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
          vehicle: vehicleList ?? [],
          trip: tripModel,
          activeDeliveries: activeDeliveries ?? 0,
          totalDelivered: totalDelivered ?? 0,
          undeliveredCustomers: undeliveredCustomers ?? 0,
          totalDistanceTravelled: totalDistanceTravelled ?? 0.0,
        );
factory DeliveryTeamModel.fromJson(dynamic json) {
  final expandedData = json['expand'] as Map<String, dynamic>?;

  // Handle personels expanded data
  final personelsList = (expandedData?['personels'] as List?)?.map((personel) {
    if (personel is RecordModel) {
      return PersonelModel.fromJson({
        'id': personel.id,
        'collectionId': personel.collectionId,
        'collectionName': personel.collectionName,
        ...personel.data,
      });
    }
    return PersonelModel.fromJson(personel as DataMap);
  }).toList() ?? [];

  // Handle checklist expanded data
  final checklistItems = (expandedData?['checklist'] as List?)?.map((checklist) {
    if (checklist is RecordModel) {
      return ChecklistModel.fromJson({
        'id': checklist.id,
        'collectionId': checklist.collectionId,
        'collectionName': checklist.collectionName,
        ...checklist.data,
      });
    }
    return ChecklistModel.fromJson(checklist as DataMap);
  }).toList() ?? [];

  // Handle vehicle expanded data
  final vehicleList = (expandedData?['vehicle'] as List?)?.map((vehicle) {
    if (vehicle is RecordModel) {
      return VehicleModel.fromJson({
        'id': vehicle.id,
        'collectionId': vehicle.collectionId,
        'collectionName': vehicle.collectionName,
        ...vehicle.data,
      });
    }
    return VehicleModel.fromJson(vehicle as DataMap);
  }).toList() ?? [];

  return DeliveryTeamModel(
    id: json['id']?.toString(),
    collectionId: json['collectionId']?.toString(),
    collectionName: json['collectionName']?.toString(),
    personels: personelsList,
    checklist: checklistItems,
    vehicleList: vehicleList,
    activeDeliveries: int.tryParse(json['activeDeliveries']?.toString() ?? '0'),
    totalDelivered: int.tryParse(json['totalDelivered']?.toString() ?? '0'),
    undeliveredCustomers: int.tryParse(json['undeliveredCustomers']?.toString() ?? '0'),
    totalDistanceTravelled: double.tryParse(json['totalDistanceTravelled']?.toString() ?? '0.0'),
    created: json['created'] != null ? DateTime.parse(json['created'].toString()) : null,
    updated: json['updated'] != null ? DateTime.parse(json['updated'].toString()) : null,
  );
}


  DataMap toJson() {
    return {
      'id': pocketbaseId,
      'collectionId': collectionId,
      'collectionName': collectionName,
      'personels': personels.map((p) => p.toJson()).toList(),
      'checklist': checklist.map((c) => c.toJson()).toList(),
      'vehicle': vehicle.map((v) => v.toJson()).toList(),
      'tripTicket': trip.target?.toJson(),
      'activeDeliveries': activeDeliveries,
      'totalDelivered': totalDelivered,
      'undeliveredCustomers': undeliveredCustomers,
      'totalDistanceTravelled': totalDistanceTravelled,
      'created': created?.toIso8601String(),
      'updated': updated?.toIso8601String(),
    };
  }

  DeliveryTeamModel copyWith({
    String? id,
    String? collectionId,
    String? collectionName,
    List<PersonelModel>? personels,
    List<ChecklistModel>? checklist,
    List<VehicleModel>? vehicleList,
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
      vehicleList: vehicleList ?? vehicle.toList(),
      tripModel: tripModel ?? trip.target,
      activeDeliveries: activeDeliveries ?? this.activeDeliveries,
      totalDelivered: totalDelivered ?? this.totalDelivered,
      undeliveredCustomers: undeliveredCustomers ?? this.undeliveredCustomers,
      totalDistanceTravelled: totalDistanceTravelled ?? this.totalDistanceTravelled,
      created: created ?? this.created,
      updated: updated ?? this.updated,
    );
  }
}
