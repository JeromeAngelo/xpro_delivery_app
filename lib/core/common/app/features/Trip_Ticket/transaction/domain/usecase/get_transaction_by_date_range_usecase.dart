import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/transaction/domain/entity/transaction_entity.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/transaction/domain/repo/transaction_repo.dart';
import 'package:x_pro_delivery_app/core/usecases/usecase.dart';
import 'package:x_pro_delivery_app/core/utils/typedefs.dart';

class GetTransactionByDateRangeParams {
  final DateTime startDate;
  final DateTime endDate;
  final String customerId;

  const GetTransactionByDateRangeParams({
    required this.startDate,
    required this.endDate,
    required this.customerId,
  });
}

class GetTransactionByDateRangeUseCase extends UsecaseWithParams<List<TransactionEntity>, GetTransactionByDateRangeParams> {
  final TransactionRepo _repo;

  const GetTransactionByDateRangeUseCase(this._repo);

  @override
  ResultFuture<List<TransactionEntity>> call(GetTransactionByDateRangeParams params) async {
    return _repo.getTransactionsByDateRange(
      params.startDate,
      params.endDate,
      params.customerId,
    );
  }
}
