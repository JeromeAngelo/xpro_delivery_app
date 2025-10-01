import 'package:objectbox/objectbox.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/trip/data/models/trip_models.dart';
import 'package:x_pro_delivery_app/core/common/app/features/otp/end_trip_otp/domain/entity/end_trip_otp_entity.dart';
import 'package:x_pro_delivery_app/core/enums/otp_type.dart';

@Entity()
class EndTripOtpModel extends EndTripOtpEntity {
  @override
  @Id()
  int dbId = 0;

  @override
  @Property()
  String id;

  @Property()
  String? tripId;

  @override
  @Property()
  String otpCode;

  @override
  @Property()
  String? generatedCode;

  @override
  @Property()
  bool isVerified;

  @override
  @Property(type: PropertyType.date)
  DateTime createdAt;

  @override
  @Property(type: PropertyType.date)
  DateTime expiresAt;

  @Property()
  String _otpTypeString = OtpType.endDelivery.toString();

  @override
  OtpType get otpType => OtpType.values.firstWhere(
    (type) => type.toString() == _otpTypeString,
    orElse: () => OtpType.endDelivery,
  );

  @override
  set otpType(OtpType type) {
    _otpTypeString = type.toString();
  }

  @override
  @Property(type: PropertyType.date)
  DateTime? verifiedAt;

  @override
  final ToOne<TripModel> trip = ToOne<TripModel>();

  EndTripOtpModel({
    String? id,
    String? otpCode,
    super.endTripOdometer,
    super.generatedCode,
    bool? isVerified,
    DateTime? createdAt,
    DateTime? expiresAt,
    OtpType? otpType,
    super.verifiedAt,
    TripModel? trip,
  }) : id = id ?? '',
       otpCode = otpCode ?? '',
       generatedCode = generatedCode,
       isVerified = isVerified ?? false,
       createdAt = createdAt ?? DateTime.now(),
       expiresAt = expiresAt ?? DateTime.now().add(const Duration(minutes: 5)),
       _otpTypeString = (otpType ?? OtpType.endDelivery).toString(),
       verifiedAt = verifiedAt,
       super(
          id: id ?? '',
          otpCode: otpCode ?? '',
          isVerified: isVerified ?? false,
          createdAt: createdAt ?? DateTime.now(),
          expiresAt: expiresAt ?? DateTime.now().add(const Duration(minutes: 5)),
          otpType: otpType ?? OtpType.endDelivery,
        ) {
    if (trip != null) this.trip.target = trip;
  }

  factory EndTripOtpModel.fromJson(Map<String, dynamic> json) {
    return EndTripOtpModel(
      id: json['id']?.toString(),
      otpCode: json['otpCode']?.toString(),
      endTripOdometer: json['endTripOdometer']?.toString(),
      generatedCode: json['generatedCode']?.toString(),
      isVerified: json['isVerified'] as bool?,
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt'].toString())
          : null,
      expiresAt: json['expiresAt'] != null
          ? DateTime.parse(json['expiresAt'].toString())
          : null,
      otpType: OtpType.values.firstWhere(
        (type) => type.toString() == json['otpType']?.toString(),
        orElse: () => OtpType.endDelivery,
      ),
      verifiedAt: json['verifiedAt'] != null
          ? DateTime.parse(json['verifiedAt'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'otpCode': otpCode,
      'endTripOdometer': endTripOdometer,
      'generatedCode': generatedCode,
      'isVerified': isVerified,
      'createdAt': createdAt.toIso8601String(),
      'expiresAt': expiresAt.toIso8601String(),
      'otpType': _otpTypeString,
      'verifiedAt': verifiedAt?.toIso8601String(),
      'trip': trip.target?.id,
    };
  }

  EndTripOtpModel copyWith({
    String? id,
    String? otpCode,
    String? endTripOdometer,
    String? generatedCode,
    bool? isVerified,
    DateTime? createdAt,
    DateTime? expiresAt,
    OtpType? otpType,
    DateTime? verifiedAt,
    TripModel? trip,
  }) {
    return EndTripOtpModel(
      id: id ?? this.id,
      otpCode: otpCode ?? this.otpCode,
      endTripOdometer: endTripOdometer ?? this.endTripOdometer,
      generatedCode: generatedCode ?? this.generatedCode,
      isVerified: isVerified ?? this.isVerified,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
      otpType: otpType ?? this.otpType,
      verifiedAt: verifiedAt ?? this.verifiedAt,
      trip: trip ?? this.trip.target,
    );
  }
}
