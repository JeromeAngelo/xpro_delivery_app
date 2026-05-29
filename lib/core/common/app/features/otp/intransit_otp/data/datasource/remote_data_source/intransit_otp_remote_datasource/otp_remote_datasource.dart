import '../../../models/otp_models.dart';
import '../intransit_otp_remote_impl/otp_remote_base.dart';
import '../intransit_otp_remote_impl/verify_intransit_otp_impl.dart';
import '../intransit_otp_remote_impl/verify_end_delivery_otp_impl.dart';
import '../intransit_otp_remote_impl/get_generated_otp_impl.dart';
import '../intransit_otp_remote_impl/load_otp_by_trip_id_impl.dart';
import '../intransit_otp_remote_impl/load_otp_by_id_impl.dart';
import '../intransit_otp_remote_impl/verify_odo_status_impl.dart';

abstract class OtpRemoteDataSource {
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

  Future<String> getGeneratedOtp();

  Future<OtpModel> loadOtpByTripId(String tripId);

  Future<OtpModel> loadOtpById(String otpId);

  Future<bool> verifyOdoStatus({required String id, required bool noOdometer});
}

class OtpRemoteDataSourceImpl extends OtpRemoteBase
    with
        VerifyInTransitOtpImpl,
        VerifyEndDeliveryOtpImpl,
        GetGeneratedOtpImpl,
        LoadOtpByTripIdImpl,
        LoadOtpByIdImpl,
        VerifyOdoStatusImpl
    implements OtpRemoteDataSource {
  const OtpRemoteDataSourceImpl({required super.pocketBaseClient});
}
