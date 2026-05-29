import 'package:x_pro_delivery_app/objectbox.g.dart';
import 'package:x_pro_delivery_app/core/common/app/features/otp/intransit_otp/data/models/otp_models.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/trip/data/models/trip_models.dart';

import '../../../../../../../../../services/objectbox.dart';

abstract class OtpLocalBase {
  final ObjectBoxStore objectBoxStore;
  Box<OtpModel> get otpBox => objectBoxStore.intransitOtpBox;
  Box<TripModel> get tripBox => objectBoxStore.tripBox;

  OtpLocalBase(this.objectBoxStore);
}
