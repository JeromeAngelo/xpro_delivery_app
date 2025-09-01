import 'package:equatable/equatable.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/trip/domain/repo/trip_repo.dart';
import 'package:x_pro_delivery_app/core/usecases/usecase.dart';
import 'package:x_pro_delivery_app/core/utils/typedefs.dart';

class SetMismatchedReason implements UsecaseWithParams<bool, SetMismatchedReasonParams> {
  final TripRepo _repo;

  const SetMismatchedReason(this._repo);

  @override
  ResultFuture<bool> call(SetMismatchedReasonParams params) async {
    return await _repo.setMismatchedReason(
      params.tripId,
      params.reasonCode,
    );
  }
}

class SetMismatchedReasonParams extends Equatable {
  final String tripId;
  final String reasonCode;

  const SetMismatchedReasonParams({
    required this.tripId,
    required this.reasonCode,
  });

  @override
  List<Object?> get props => [tripId, reasonCode];
}
