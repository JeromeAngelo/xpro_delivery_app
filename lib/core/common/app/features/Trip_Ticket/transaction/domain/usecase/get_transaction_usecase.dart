import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/transaction/domain/entity/transaction_entity.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/transaction/domain/repo/transaction_repo.dart';
import 'package:x_pro_delivery_app/core/usecases/usecase.dart';
import 'package:x_pro_delivery_app/core/utils/typedefs.dart';

class GetTransactionUseCase extends UsecaseWithParams<List<TransactionEntity>, String> {
  final TransactionRepo _repo;

  const GetTransactionUseCase(this._repo);

  @override
  ResultFuture<List<TransactionEntity>> call(String params) async {
    return _repo.getTransactions(params);
  }
}
