import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/delivery_update/domain/repo/delivery_update_repo.dart';
import 'package:x_pro_delivery_app/core/usecases/usecase.dart';
import 'package:x_pro_delivery_app/core/utils/typedefs.dart';

class CheckEndDeliverStatus extends UsecaseWithParams<DataMap, String> {
  const CheckEndDeliverStatus(this._repo);

  final DeliveryUpdateRepo _repo;

  @override
  ResultFuture<DataMap> call(String params) => _repo.checkEndDeliverStatus(params);
  
  ResultFuture<DataMap> checkLocal(String tripId) => _repo.checkLocalEndDeliverStatus(tripId);
}

