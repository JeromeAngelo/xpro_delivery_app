import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/transaction/domain/repo/transaction_repo.dart';
import 'package:x_pro_delivery_app/core/usecases/usecase.dart';
import 'package:x_pro_delivery_app/core/utils/typedefs.dart';

class DeleteTransactionUseCase extends UsecaseWithParams<void, String> {
  final TransactionRepo _repo;

  const DeleteTransactionUseCase(this._repo);

  @override
  ResultFuture<void> call(String params) async {
    return _repo.deleteTransaction(params);
  }
}
