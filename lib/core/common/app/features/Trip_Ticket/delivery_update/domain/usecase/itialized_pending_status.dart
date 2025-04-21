import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/delivery_update/domain/repo/delivery_update_repo.dart';
import 'package:x_pro_delivery_app/core/usecases/usecase.dart';
import 'package:x_pro_delivery_app/core/utils/typedefs.dart';

class InitializePendingStatus extends UsecaseWithParams<void, List<String>> {
  const InitializePendingStatus(this._repo);

  final DeliveryUpdateRepo _repo;

  @override
  ResultFuture<void> call(List<String> params) async {
    return _repo.initializePendingStatus(params);
  }
}
