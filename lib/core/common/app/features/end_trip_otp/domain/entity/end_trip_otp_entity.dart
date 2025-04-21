import 'package:equatable/equatable.dart';
import 'package:objectbox/objectbox.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/trip/data/models/trip_models.dart';
import 'package:x_pro_delivery_app/core/enums/otp_type.dart';

@Entity()
class EndTripOtpEntity extends Equatable {
  @Id()
  int dbId = 0;

  String id;
  String otpCode;
  String? generatedCode;
  String? endTripOdometer;
  bool isVerified;
  DateTime createdAt;
  DateTime expiresAt;
  @Property()
  OtpType otpType;
  DateTime? verifiedAt;
  
  final ToOne<TripModel> trip = ToOne<TripModel>();

  EndTripOtpEntity({
    required this.id,
    required this.otpCode,
    this.endTripOdometer,
    this.generatedCode,
    required this.isVerified,
    required this.createdAt,
    required this.expiresAt,
    this.otpType = OtpType.endDelivery,
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
        endTripOdometer,
        isVerified,
        createdAt,
        expiresAt,
        otpType,
        verifiedAt,
        trip,
      ];
}
