import 'package:flutter/material.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:objectbox/objectbox.dart';

import 'package:x_pro_delivery_app/objectbox.g.dart';

import '../../../../../delivery_vehicle_data/data/model/delivery_vehicle_model.dart';
import '../../../../../../trip_ticket/trip/data/models/trip_models.dart';
import '../../../../../personels/data/models/personel_models.dart';
import '../../../models/delivery_team_model.dart';

abstract class DeliveryTeamRemoteBase {
  final PocketBase pocketBaseClient;
  final Box<DeliveryTeamModel> deliveryTeamBox;

  const DeliveryTeamRemoteBase({
    required this.pocketBaseClient,
    required this.deliveryTeamBox,
  });

  DeliveryTeamModel processDeliveryTeamRecord(RecordModel record) {
    // Process personels data
    List<PersonelModel> personelsList = [];
    if (record.expand['personels'] != null) {
      final personelsData = record.expand['personels'];
      if (personelsData is List) {
        personelsList =
            personelsData!.map((personnel) {
              final personnelRecord = personnel;
              debugPrint('🧑‍💼 Processing team member: ${personnelRecord.id}');

              return PersonelModel.fromJson({
                'id': personnelRecord.id,
                'collectionId': personnelRecord.collectionId,
                'collectionName': personnelRecord.collectionName,
                'name': personnelRecord.data['name'] ?? 'Unnamed',
                'role': personnelRecord.data['role'],
                'created': personnelRecord.created,
                'updated': personnelRecord.updated,
              });
            }).toList();
      }
    } else if (record.data['personels'] != null) {
      personelsList =
          (record.data['personels'] as List)
              .map((id) => PersonelModel(id: id.toString()))
              .toList();
    }

    // FIXED: Process delivery vehicle data with proper null handling
    DeliveryVehicleModel? deliveryVehicleModel;
    if (record.expand['deliveryVehicle'] != null) {
      final deliveryVehicleData = record.expand['deliveryVehicle'];
      if (deliveryVehicleData is List && deliveryVehicleData!.isNotEmpty) {
        final vehicleRecord = deliveryVehicleData[0];
        debugPrint(
          '🚛 Processing delivery vehicle from list: ${vehicleRecord.id}',
        );
        debugPrint('🚛 Vehicle data from list: ${vehicleRecord.data}');

        deliveryVehicleModel = DeliveryVehicleModel.fromJson({
          'id': vehicleRecord.id,
          'collectionId': vehicleRecord.collectionId,
          'collectionName': vehicleRecord.collectionName,
          'plate_no': vehicleRecord.data['plate_no']?.toString(),
          'make': vehicleRecord.data['make']?.toString(),
          'name': vehicleRecord.data['name']?.toString(),
          'model': vehicleRecord.data['model']?.toString(),
          'type': vehicleRecord.data['type']?.toString(),
          'wheels': vehicleRecord.data['wheels']?.toString(),
          'volumeCapacity': vehicleRecord.data['volumeCapacity']?.toString(),
          'weightCapacity': vehicleRecord.data['weightCapacity']?.toString(),
          'year': vehicleRecord.data['year']?.toString(),
          'capacity': vehicleRecord.data['capacity']?.toString(),
          'fuelType': vehicleRecord.data['fuelType']?.toString(),
          'status': vehicleRecord.data['status']?.toString(),
          'created': vehicleRecord.created,
          'updated': vehicleRecord.updated,
        });
        debugPrint(
          '✅ Delivery vehicle processed from list: ${deliveryVehicleModel.plateNo}',
        );
      }
    } else if (record.data['deliveryVehicle'] != null) {
      debugPrint(
        '⚠️ Delivery vehicle ID found but not expanded: ${record.data['deliveryVehicle']}',
      );
      // Create a minimal model with just the ID
      deliveryVehicleModel = DeliveryVehicleModel(
        id: record.data['deliveryVehicle'].toString(),
      );
    }

    // Process trip data
    TripModel? tripModel;
    if (record.expand['tripTicket'] != null) {
      final tripData = record.expand['tripTicket'];
      if (tripData is List && tripData!.isNotEmpty) {
        final tripRecord = tripData[0];
        debugPrint('🎫 Processing trip from list: ${tripRecord.id}');
        tripModel = TripModel.fromJson({
          'id': tripRecord.id,
          'collectionId': tripRecord.collectionId,
          'collectionName': tripRecord.collectionName,
          'tripNumberId': tripRecord.data['tripNumberId'],
          'qrCode': tripRecord.data['qrCode'],
          'isAccepted': tripRecord.data['isAccepted'],
          'isEndTrip': tripRecord.data['isEndTrip'],
        });
      }
    } else if (record.data['tripTicket'] != null) {
      tripModel = TripModel(id: record.data['tripTicket'].toString());
    }

    // FIXED: Safe type conversion for numeric fields
    return DeliveryTeamModel(
      id: record.id,
      collectionId: record.collectionId,
      collectionName: record.collectionName,
      personelsList: personelsList,
      deliveryVehicleModel: deliveryVehicleModel,
      tripModel: tripModel,
      activeDeliveries: safeParseInt(record.data['activeDeliveries']),
      totalDelivered: safeParseInt(record.data['totalDelivered']),
      undeliveredCustomers: safeParseInt(record.data['undeliveredCustomers']),
      totalDistanceTravelled: safeParseDouble(
        record.data['totalDistanceTraveled'],
      ),
    );
  }

  int? safeParseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) {
      return int.tryParse(value);
    }
    if (value is double) return value.toInt();
    return null;
  }

  double? safeParseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      return double.tryParse(value);
    }
    return null;
  }
}
