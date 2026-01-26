import 'package:flutter/material.dart';
import 'package:objectbox/objectbox.dart';

import '../../../../../../../utils/typedefs.dart';
import '../../../../trip_ticket/trip/data/models/trip_models.dart';
import '../../../../checklists/intransit_checklist/data/model/checklist_model.dart';
import '../../../delivery_vehicle_data/data/model/delivery_vehicle_model.dart';
import '../../../personels/data/models/personel_models.dart';
import '../../domain/entity/delivery_team_entity.dart';


@Entity()

class DeliveryTeamModel extends DeliveryTeamEntity {
  @Id(assignable: true)
  int objectBoxId = 0;

  @override
  @Property()
  String? id;

  @override
  @Property()
  String? collectionId;

  @override
  @Property()
  String? collectionName;

  @Property()
  String pocketbaseId = '';

  @Property()
  String? tripId;

  @override
  @Property()
  int? activeDeliveries;

  @override
  @Property()
  int? totalDelivered;

  @override
  @Property()
  double? totalDistanceTravelled;

  @override
  @Property()
  int? undeliveredCustomers;

  // --- Relations ---
  @override
  final personels = ToMany<PersonelModel>();
  @override
  final checklist = ToMany<ChecklistModel>();
  @override
  final trip = ToOne<TripModel>();
  @override
  final deliveryVehicle = ToOne<DeliveryVehicleModel>();

  DeliveryTeamModel({
    this.id,
    this.collectionId,
    this.collectionName,
    this.pocketbaseId = '',
    this.tripId,
    List<PersonelModel>? personelsList,
    List<ChecklistModel>? checklistItems,
    TripModel? tripModel,
    DeliveryVehicleModel? deliveryVehicleModel,
    this.activeDeliveries,
    this.totalDelivered,
    this.totalDistanceTravelled,
    this.undeliveredCustomers,
  }) {
    if (personelsList != null) personels.addAll(personelsList);
    if (checklistItems != null) checklist.addAll(checklistItems);
    if (tripModel != null) trip.target = tripModel;
    if (deliveryVehicleModel != null) deliveryVehicle.target = deliveryVehicleModel;
  }




  /// --- From JSON ---
  factory DeliveryTeamModel.fromJson(dynamic json) {
    debugPrint('🔄 MODEL: Creating DeliveryTeamModel from JSON');

    final expandedData = json['expand'] as Map<String, dynamic>?;

    TripModel? tripModel;
    final tripData = expandedData?['trip'] ?? json['trip'];
    if (tripData != null && tripData is Map<String, dynamic>) {
      tripModel = TripModel.fromJson(tripData);
    }

    DeliveryVehicleModel? deliveryVehicleModel;
    final deliveryVehicleData = expandedData?['deliveryVehicle'] ?? json['deliveryVehicle'];
    if (deliveryVehicleData != null && deliveryVehicleData is Map<String, dynamic>) {
      deliveryVehicleModel = DeliveryVehicleModel.fromJson(deliveryVehicleData);
    }

    List<PersonelModel> personelsList = [];
    final personelsData = expandedData?['personels'] ?? json['personels'];
    if (personelsData != null) {
      if (personelsData is List) {
        personelsList = personelsData.map((p) => p is String ? PersonelModel(id: p) : PersonelModel.fromJson(p)).toList();
      } else if (personelsData is Map<String, dynamic>) {
        personelsList = [PersonelModel.fromJson(personelsData)];
      }
    }

    List<ChecklistModel> checklistItems = [];
    final checklistData = expandedData?['checklist'] ?? json['checklist'];
    if (checklistData != null) {
      if (checklistData is List) {
        checklistItems = checklistData.map((c) => c is String ? ChecklistModel(id: c) : ChecklistModel.fromJson(c)).toList();
      } else if (checklistData is Map<String, dynamic>) {
        checklistItems = [ChecklistModel.fromJson(checklistData)];
      }
    }

    final deliveryTeam = DeliveryTeamModel(
      id: json['id']?.toString(),
      collectionId: json['collectionId']?.toString(),
      collectionName: json['collectionName']?.toString(),
      pocketbaseId: json['id']?.toString() ?? '',
      tripId: tripModel?.id,
      activeDeliveries: int.tryParse(json['activeDeliveries']?.toString() ?? '0'),
      totalDelivered: int.tryParse(json['totalDelivered']?.toString() ?? '0'),
      undeliveredCustomers: int.tryParse(json['undeliveredCustomers']?.toString() ?? '0'),
      totalDistanceTravelled: double.tryParse(json['totalDistanceTravelled']?.toString() ?? '0.0'),
      tripModel: tripModel,
      deliveryVehicleModel: deliveryVehicleModel,
      personelsList: personelsList,
      checklistItems: checklistItems,
    );

    debugPrint('✅ MODEL: DeliveryTeam parsed - id:${deliveryTeam.id}, DeliveryVehicle ID:${deliveryTeam.deliveryVehicle.target?.id}');
    return deliveryTeam;
  }

  /// --- To JSON ---
  DataMap toJson() {
    return {
      'id': id,
      'collectionId': collectionId,
      'collectionName': collectionName,
      'pocketbaseId': pocketbaseId,
      'tripId': tripId,
      'activeDeliveries': activeDeliveries,
      'totalDelivered': totalDelivered,
      'undeliveredCustomers': undeliveredCustomers,
      'totalDistanceTravelled': totalDistanceTravelled,
      'personels': personels.map((p) => p.id).toList(),
      'checklist': checklist.map((c) => c.id).toList(),
      'trip': trip.target?.id,
      'deliveryVehicle': deliveryVehicle.target?.id,
    };
  }

  /// --- Copy With ---
  DeliveryTeamModel copyWith({
    String? id,
    String? collectionId,
    String? collectionName,
    String? pocketbaseId,
    String? tripId,
    List<PersonelModel>? personelsList,
    List<ChecklistModel>? checklistItems,
    TripModel? tripModel,
    DeliveryVehicleModel? deliveryVehicleModel,
    int? activeDeliveries,
    int? totalDelivered,
    int? undeliveredCustomers,
    double? totalDistanceTravelled,
  }) {
    final newTeam = DeliveryTeamModel(
      id: id ?? this.id,
      collectionId: collectionId ?? this.collectionId,
      collectionName: collectionName ?? this.collectionName,
      pocketbaseId: pocketbaseId ?? this.pocketbaseId,
      tripId: tripId ?? this.tripId,
      personelsList: personelsList ?? personels.toList(),
      checklistItems: checklistItems ?? checklist.toList(),
      tripModel: tripModel ?? trip.target,
      deliveryVehicleModel: deliveryVehicleModel ?? deliveryVehicle.target,
      activeDeliveries: activeDeliveries ?? this.activeDeliveries,
      totalDelivered: totalDelivered ?? this.totalDelivered,
      undeliveredCustomers: undeliveredCustomers ?? this.undeliveredCustomers,
      totalDistanceTravelled: totalDistanceTravelled ?? this.totalDistanceTravelled,
    );

    return newTeam;
  }
}
