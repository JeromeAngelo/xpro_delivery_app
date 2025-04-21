import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/completed_customer/domain/entity/completed_customer_entity.dart';
import 'package:x_pro_delivery_app/core/utils/typedefs.dart';

abstract class CompletedCustomerRepo {
  ResultFuture<List<CompletedCustomerEntity>> getCompletedCustomers(String tripId);
  ResultFuture<CompletedCustomerEntity> getCompletedCustomerById(String customerId);
  ResultFuture<List<CompletedCustomerEntity>> loadLocalCompletedCustomers(String tripId);
  ResultFuture<CompletedCustomerEntity> loadLocalCompletedCustomerById(String customerId);

}
