import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/transaction/domain/entity/transaction_entity.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/transaction/domain/repo/transaction_repo.dart';
import 'package:x_pro_delivery_app/core/usecases/usecase.dart';
import 'package:x_pro_delivery_app/core/utils/typedefs.dart';

class UpdateTransactionUseCase extends UsecaseWithParams<void, TransactionEntity> {
  final TransactionRepo _repo;

  const UpdateTransactionUseCase(this._repo);

  @override
  ResultFuture<void> call(TransactionEntity params) async {
    return _repo.updateTransaction(params);
  }
}
