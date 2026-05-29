import 'package:x_pro_delivery_app/core/common/app/features/otp/end_trip_otp/data/model/end_trip_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/trip/data/models/trip_models.dart';
import 'package:x_pro_delivery_app/objectbox.g.dart';
import 'package:x_pro_delivery_app/core/services/objectbox.dart';

abstract class EndTripOtpLocalBase {
  final ObjectBoxStore objectBoxStore;

  EndTripOtpLocalBase(this.objectBoxStore);

  Box<EndTripOtpModel> get endTripOtpBox => objectBoxStore.endTripOtpBox;
  Box<TripModel> get tripBox => objectBoxStore.tripBox;
}
