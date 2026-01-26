import 'package:equatable/equatable.dart';
import 'package:objectbox/objectbox.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/trip/data/models/trip_models.dart';
import 'package:x_pro_delivery_app/core/enums/otp_type.dart';

@Entity()
class OtpEntity extends Equatable {
  @Id()
  int dbId = 0;

  String id;
  String otpCode;
  String? generatedCode;
  String? intransitOdometer;
  bool isVerified;
  DateTime createdAt;
  DateTime expiresAt;
  @Property()
  OtpType otpType;
  DateTime? verifiedAt;
  
  // Add trip relationship
  final ToOne<TripModel> trip = ToOne<TripModel>();

  OtpEntity({
    required this.id,
    required this.otpCode,
    this.generatedCode,
    this.intransitOdometer,
    required this.isVerified,
    required this.createdAt,
    required this.expiresAt,
    this.otpType = OtpType.inTransit,
    this.verifiedAt,
    TripModel? trip,
  }) {
    if (trip != null) this.trip.target = trip;
  }

  @override
  List<Object?> get props => [
        id,
        otpCode,
        generatedCode,
        intransitOdometer,
        isVerified,
        createdAt,
        expiresAt,
        otpType,
        verifiedAt,
        trip,
      ];
}
