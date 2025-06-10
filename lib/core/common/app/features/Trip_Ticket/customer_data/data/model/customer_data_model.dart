import 'package:objectbox/objectbox.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/customer_data/domain/entity/customer_data_entity.dart';
import 'package:x_pro_delivery_app/core/utils/typedefs.dart';

@Entity()
class CustomerDataModel extends CustomerDataEntity {
  @Id()
  int objectBoxId = 0;
  
  @Property()
  String pocketbaseId;

  CustomerDataModel({
    super.dbId = 0,
    super.id,
    super.collectionId,
    super.collectionName,
    super.name,
    super.refId,
    super.province,
    super.municipality,
    super.barangay,
    super.longitude,
    super.latitude,
    super.contactNumber,
    super.ownerName,
    super.created,
    super.paymentMode,
    super.updated,
    this.objectBoxId = 0,
  }) : pocketbaseId = id ?? '';

  factory CustomerDataModel.fromJson(DataMap json) {
    // Add safe date parsing
    DateTime? parseDate(dynamic value) {
      if (value == null || value.toString().isEmpty) return null;
      try {
        return DateTime.parse(value.toString());
      } catch (_) {
        return null;
      }
    }

    return CustomerDataModel(
      id: json['id']?.toString(),
      collectionId: json['collectionId']?.toString(),
      collectionName: json['collectionName']?.toString(),
      name: json['name']?.toString(),
      ownerName: json['ownerName']?.toString(),
      contactNumber: json['contactNumber']?.toString(),
      refId: json['refID']?.toString(),
      province: json['province']?.toString(),
      municipality: json['municipality']?.toString(),
      barangay: json['barangay']?.toString(),
      paymentMode: json['paymentMode']?.toString(),
      longitude: json['longitude'] != null ? double.tryParse(json['longitude'].toString()) : null,
      latitude: json['latitude'] != null ? double.tryParse(json['latitude'].toString()) : null,
      created: parseDate(json['created']),
      updated: parseDate(json['updated']),
    );
  }

  DataMap toJson() {
    return {
      'id': pocketbaseId,
      'collectionId': collectionId,
      'collectionName': collectionName,
      'name': name ?? '',
      'refId': refId ?? '',
      'province': province ?? '',
      'paymentMode': paymentMode ?? '',
      'municipality': municipality ?? '',
      'barangay': barangay ?? '',
      'ownerName': ownerName ?? '',
      'contactNumber': contactNumber ?? '',
      'longitude': longitude?.toString() ?? '',
      'latitude': latitude?.toString() ?? '',
      'created': created?.toIso8601String(),
      'updated': updated?.toIso8601String(),
    };
  }

  CustomerDataModel copyWith({
    String? id,
    String? collectionId,
    String? collectionName,
    String? name,
    String? refId,
    String? province,
    String? municipality,
    String? barangay,
    String? ownerName,
    String? contactNumber,
    double? longitude,
    double? latitude,
    String? paymentMode,
    DateTime? created,
    DateTime? updated,
  }) {
    return CustomerDataModel(
      id: id ?? this.id,
      collectionId: collectionId ?? this.collectionId,
      collectionName: collectionName ?? this.collectionName,
      name: name ?? this.name,
      refId: refId ?? this.refId,
      province: province ?? this.province,
      municipality: municipality ?? this.municipality,
      paymentMode: paymentMode ?? this.paymentMode,
      barangay: barangay ?? this.barangay,
      ownerName: ownerName ?? this.ownerName,
      contactNumber: contactNumber ?? this.contactNumber,
      longitude: longitude ?? this.longitude,
      latitude: latitude ?? this.latitude,
      created: created ?? this.created,
      updated: updated ?? this.updated,
      objectBoxId: objectBoxId,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CustomerDataModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
