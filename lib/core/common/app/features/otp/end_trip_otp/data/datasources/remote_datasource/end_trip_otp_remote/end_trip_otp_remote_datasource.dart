import '../../../model/end_trip_model.dart';
import '../end_trip_otp_remote_impl/verify_end_trip_otp_impl.dart';
import '../end_trip_otp_remote_impl/verify_odo_status_impl.dart';
import '../end_trip_otp_remote_impl/get_end_generated_otp_impl.dart';
import '../end_trip_otp_remote_impl/load_end_trip_otp_by_trip_id_impl.dart';
import '../end_trip_otp_remote_impl/load_end_trip_otp_by_id_impl.dart';
import '../end_trip_otp_remote_impl/end_trip_otp_remote_base.dart';

abstract class EndTripOtpRemoteDataSource {
  Future<String> getEndGeneratedOtp();
  Future<EndTripOtpModel> loadEndTripOtpByTripId(String tripId);
  Future<EndTripOtpModel> loadEndTripOtpById(String otpId);
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

class EndTripOtpRemoteDataSourceImpl extends EndTripOtpRemoteBase
    with
        VerifyEndTripOtpImpl,
        VerifyOdoStatusImpl,
        GetEndGeneratedOtpImpl,
        LoadEndTripOtpByTripIdImpl,
        LoadEndTripOtpByIdImpl
    implements EndTripOtpRemoteDataSource {
  const EndTripOtpRemoteDataSourceImpl({required super.pocketBaseClient});
}
