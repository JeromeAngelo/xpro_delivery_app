import 'package:objectbox/objectbox.dart';

import '../../../../../../../utils/typedefs.dart';
import '../../domain/enitity/delivery_vehicle_entity.dart';


@Entity()
class DeliveryVehicleModel extends DeliveryVehicleEntity {
  @Id()
  int objectBoxId = 0;

  @Property()
  String pocketbaseId;

  @Property()
  String tripId;

  @Property()
  String? name;

  @Property()
  String? plateNo;

  @Property()
  String? make;

  @Property()
  String? type;

  DeliveryVehicleModel({
    super.dbId = 0,
    super.id,
    super.collectionId,
    super.collectionName,
    String? name,        // <-- capture name from PB
    String? plateNo,     // <-- capture plate
    String? type,        // <-- capture type
    super.make,
    super.wheels,
    super.volumeCapacity,
    super.weightCapacity,
    super.created,
    super.updated,
    this.objectBoxId = 0,
    String? pocketbaseId,
    String? tripId,
  })  : pocketbaseId = pocketbaseId ?? id ?? '',
        tripId = tripId ?? '',
        // IMPORTANT: assign local fields
        name = name,
        plateNo = plateNo,
        make = make,
        type = type;


  // Factory constructor to create a model from JSON
  factory DeliveryVehicleModel.fromJson(DataMap json) {
    DateTime? parseDate(dynamic value) {
      if (value == null || value.toString().isEmpty) return null;
      try {
        return DateTime.parse(value.toString());
      } catch (_) {
        return null;
      }
    }

    return DeliveryVehicleModel(
      id: json['id']?.toString(),
      pocketbaseId: json['id']?.toString(),
      collectionId: json['collectionId']?.toString(),
      collectionName: json['collectionName']?.toString(),
      name: json['name']?.toString(),
      plateNo: json['plateNo']?.toString(),
      make: json['make']?.toString(),
      type: json['type']?.toString(),
      wheels: json['wheels']?.toString(),
      volumeCapacity: json['volumeCapacity'] != null
          ? double.tryParse(json['volumeCapacity'].toString())
          : null,
      weightCapacity: json['weightCapacity'] != null
          ? double.tryParse(json['weightCapacity'].toString())
          : null,
      created: parseDate(json['created']),
      updated: parseDate(json['updated']),
    );
  }

  // Method to convert model to JSON
  DataMap toJson() {
    return {
      'id': pocketbaseId,
      'collectionId': collectionId,
      'collectionName': collectionName,
      'name': name ?? '',
      'plateNo': plateNo ?? '',
      'make': make ?? '',
      'type': type ?? '',
      'wheels': wheels ?? '',
      'volumeCapacity': volumeCapacity,
      'weightCapacity': weightCapacity,
      'created': created?.toIso8601String(),
      'updated': updated?.toIso8601String(),
    };
  }

  // Create a copy of this model with new values
  DeliveryVehicleModel copyWith({
    String? id,
    String? pocketbaseId,
    String? collectionId,
    String? collectionName,
    String? name,
    String? plateNo,
    String? make,
    String? type,
    String? wheels,
    double? volumeCapacity,
    double? weightCapacity,
    DateTime? created,
    DateTime? updated,
  }) {
    return DeliveryVehicleModel(
      id: id ?? this.id,
      collectionId: collectionId ?? this.collectionId,
      collectionName: collectionName ?? this.collectionName,
      name: name ?? this.name,
      plateNo: plateNo ?? this.plateNo,
      make: make ?? this.make,
      type: type ?? this.type,
      wheels: wheels ?? this.wheels,
      volumeCapacity: volumeCapacity ?? this.volumeCapacity,
      weightCapacity: weightCapacity ?? this.weightCapacity,
      created: created ?? this.created,
      updated: updated ?? this.updated,
      objectBoxId: objectBoxId,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DeliveryVehicleModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'DeliveryVehicleModel(id: $id, name: $name, plateNo: $plateNo, )';
  }
}