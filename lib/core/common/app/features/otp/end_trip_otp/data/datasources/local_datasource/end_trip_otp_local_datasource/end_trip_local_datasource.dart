import 'package:x_pro_delivery_app/core/common/app/features/otp/end_trip_otp/data/model/end_trip_model.dart';
import '../end_trip_otp_local_impl/end_trip_otp_local_base.dart';
import '../end_trip_otp_local_impl/get_end_trip_otp_by_id_impl.dart';
import '../end_trip_otp_local_impl/cache_end_trip_otp_impl.dart';
import '../end_trip_otp_local_impl/verify_end_trip_otp_impl.dart';
import '../end_trip_otp_local_impl/verify_odo_status_impl.dart';
import '../end_trip_otp_local_impl/get_end_trip_otp_by_trip_id_impl.dart';

abstract class EndTripOtpLocalDatasource {
  Future<EndTripOtpModel> getEndTripOtpById(String otpId);
  Future<EndTripOtpModel?> getEndTripOtpByTripId(String tripId);

  Future<void> cacheEndTripOtp(EndTripOtpModel otp);
  Future<bool> verifyEndTripOtp({
    required String enteredOtp,
    required String generatedOtp,
    required String tripId,
    required String otpId,
    required String odometerReading,
    bool noOdometer = false,
  });

  Future<bool> verifyOdoStatus({required String id, required bool noOdometer});
}

class EndTripOtpLocalDatasourceImpl extends EndTripOtpLocalBase
    with
        GetEndTripOtpByIdImpl,
        CacheEndTripOtpImpl,
        VerifyEndTripOtpImpl,
        VerifyOdoStatusImpl,
        GetEndTripOtpByTripIdImpl
    implements EndTripOtpLocalDatasource {
  EndTripOtpLocalDatasourceImpl(super.objectBoxStore);
}
