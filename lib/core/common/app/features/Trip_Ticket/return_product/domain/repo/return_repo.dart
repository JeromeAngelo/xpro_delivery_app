import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/return_product/domain/entity/return_entity.dart';
import 'package:x_pro_delivery_app/core/utils/typedefs.dart';

abstract class ReturnRepo {
  const ReturnRepo();

  ResultFuture<List<ReturnEntity>> getReturns(String tripId);
  ResultFuture<ReturnEntity> getReturnByCustomerId(String customerId);
  ResultFuture<List<ReturnEntity>> loadLocalReturns(String tripId);
}
