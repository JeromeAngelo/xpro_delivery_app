import 'package:objectbox/objectbox.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_data/customer_data/domain/entity/customer_data_entity.dart';
import 'package:x_pro_delivery_app/core/utils/typedefs.dart';

@Entity()
class CustomerDataModel extends CustomerDataEntity {
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

  @override
  @Property()
  String? name;

  @override
  @Property()
  String? refId;

  @override
  @Property()
  String? province;

  @override
  @Property()
  String? municipality;

  @override
  @Property()
  String? barangay;

  @override
  @Property()
  String? ownerName;

  @override
  @Property()
  String? contactNumber;

  @override
  @Property()
  double? longitude;

  @override
  @Property()
  double? latitude;

  @override
  @Property()
  String? paymentMode;

  @override
  @Property()
  DateTime? created;

  @override
  @Property()
  DateTime? updated;

  /// --- Pocketbase ID (for convenience)
  @Property()
  String pocketbaseId;

  CustomerDataModel({
    this.id,
    this.collectionId,
    this.collectionName,
    this.name,
    this.refId,
    this.province,
    this.municipality,
    this.barangay,
    this.ownerName,
    this.contactNumber,
    this.longitude,
    this.latitude,
    this.paymentMode,
    this.created,
    this.updated,
    this.objectBoxId = 0,
  }) : pocketbaseId = id ?? '';

  /// --- From JSON ---
  factory CustomerDataModel.fromJson(dynamic json) {
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
      refId: json['refID']?.toString(),
      province: json['province']?.toString(),
      municipality: json['municipality']?.toString(),
      barangay: json['barangay']?.toString(),
      ownerName: json['ownerName']?.toString(),
      contactNumber: json['contactNumber']?.toString(),
      paymentMode: json['paymentMode']?.toString(),
      longitude: json['longitude'] != null ? double.tryParse(json['longitude'].toString()) : null,
      latitude: json['latitude'] != null ? double.tryParse(json['latitude'].toString()) : null,
      created: parseDate(json['created']),
      updated: parseDate(json['updated']),
    );
  }

  /// --- To JSON ---
  DataMap toJson() {
    return {
      'id': pocketbaseId,
      'collectionId': collectionId,
      'collectionName': collectionName,
      'name': name ?? '',
      'refId': refId ?? '',
      'province': province ?? '',
      'municipality': municipality ?? '',
      'barangay': barangay ?? '',
      'ownerName': ownerName ?? '',
      'contactNumber': contactNumber ?? '',
      'paymentMode': paymentMode ?? '',
      'longitude': longitude?.toString() ?? '',
      'latitude': latitude?.toString() ?? '',
      'created': created?.toIso8601String(),
      'updated': updated?.toIso8601String(),
    };
  }

  /// --- Copy With ---
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
      barangay: barangay ?? this.barangay,
      ownerName: ownerName ?? this.ownerName,
      contactNumber: contactNumber ?? this.contactNumber,
      longitude: longitude ?? this.longitude,
      latitude: latitude ?? this.latitude,
      paymentMode: paymentMode ?? this.paymentMode,
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
