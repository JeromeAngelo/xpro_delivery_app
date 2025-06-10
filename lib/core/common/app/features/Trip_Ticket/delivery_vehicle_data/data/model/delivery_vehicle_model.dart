import 'package:objectbox/objectbox.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/delivery_vehicle_data/domain/enitity/delivery_vehicle_entity.dart';
import 'package:x_pro_delivery_app/core/utils/typedefs.dart';

@Entity()
class DeliveryVehicleModel extends DeliveryVehicleEntity {
  @Id()
  int objectBoxId = 0;
  
  @Property()
  String pocketbaseId;

  @Property()
  String tripId;

  DeliveryVehicleModel({
    super.dbId = 0,
    super.id,
    super.collectionId,
    super.collectionName,
    super.name,
    super.plateNo,
    super.make,
    super.type,
    super.wheels,
    super.volumeCapacity,
    super.weightCapacity,
    super.created,
    super.updated,
    this.objectBoxId = 0,
  }) : pocketbaseId = id ?? '', tripId = '';

  // Factory constructor to create a model from JSON data
  factory DeliveryVehicleModel.fromJson(DataMap json) {
    // Add safe date parsing
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

  // Create a copy of this model with given fields replaced with new values
  DeliveryVehicleModel copyWith({
    String? id,
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
    return 'DeliveryVehicleModel(id: $id, name: $name, plateNo: $plateNo)';
  }
}
