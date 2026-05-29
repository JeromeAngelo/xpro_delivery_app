import '../../../models/otp_models.dart';
import '../intransit_otp_local_impl/otp_local_base.dart';
import '../intransit_otp_local_impl/verify_intransit_otp_impl.dart';
import '../intransit_otp_local_impl/verify_end_delivery_otp_impl.dart';
import '../intransit_otp_local_impl/verify_odo_status_impl.dart';
import '../intransit_otp_local_impl/get_otp_by_id_impl.dart';
import '../intransit_otp_local_impl/get_otp_by_trip_id_impl.dart';

abstract class OtpLocalDatasource {
  Future<OtpModel?> getOtpById(String id);

  Future<OtpModel?> getOtpByTripId(String tripId);

  Future<bool> verifyInTransitOtp({
    required String enteredOtp,
    required String generatedOtp,
    required String tripId,
    required String otpId,
    required String odometerReading,
    bool noOdometer = false,
  });

  Future<bool> verifyEndDeliveryOtp({
    required String enteredOtp,
    required String generatedOtp,
  });

  Future<bool> verifyOdoStatus({required String id, required bool noOdometer});
}

class OtpLocalDatasourceImpl extends OtpLocalBase
    with
        VerifyInTransitOtpImpl,
        VerifyEndDeliveryOtpImpl,
        VerifyOdoStatusImpl,
        GetOtpByIdImpl,
        GetOtpByTripIdImpl
    implements OtpLocalDatasource {
  OtpLocalDatasourceImpl(super.objectBoxStore);
}
