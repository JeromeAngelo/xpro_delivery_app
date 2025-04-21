// import 'package:x_pro_delivery_app/core/common/app/features/otp/domain/repo/otp_repo.dart';
// import 'package:x_pro_delivery_app/core/usecases/usecase.dart';
// import 'package:x_pro_delivery_app/core/utils/typedefs.dart';

// class SaveOdometerReading extends UsecaseWithParams<void, SaveOdometerParams> {
//   const SaveOdometerReading(this._repo);

//   final OtpRepo _repo;

//   @override
//   ResultFuture<void> call(SaveOdometerParams params) => _repo.saveOdometerReading(
//         otpId: params.otpId,
//         odometerReading: params.odometerReading,
//       );
// }

// class SaveOdometerParams {
//   final String otpId;
//   final String odometerReading;

//   const SaveOdometerParams({
//     required this.otpId,
//     required this.odometerReading,
//   });
// }
