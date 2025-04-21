import 'package:equatable/equatable.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/undeliverable_customer/domain/repo/undeliverable_repo.dart';
import 'package:x_pro_delivery_app/core/enums/undeliverable_reason.dart';
import 'package:x_pro_delivery_app/core/usecases/usecase.dart';
import 'package:x_pro_delivery_app/core/utils/typedefs.dart';

class SetUndeliverableReason implements UsecaseWithParams<void, SetUndeliverableReasonParams> {
  const SetUndeliverableReason(this._repo);

  final UndeliverableRepo _repo;

  @override
  ResultFuture<void> call(SetUndeliverableReasonParams params) async {
    return _repo.setUndeliverableReason(params.customerId, params.reason);
  }
}

class SetUndeliverableReasonParams extends Equatable {
  const SetUndeliverableReasonParams({
    required this.customerId,
    required this.reason,
  });

  final String customerId;
  final UndeliverableReason reason;

  @override
  List<Object?> get props => [customerId, reason];
}
