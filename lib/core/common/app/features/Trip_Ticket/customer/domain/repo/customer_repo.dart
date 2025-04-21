import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/customer/domain/entity/customer_entity.dart';
import 'package:x_pro_delivery_app/core/utils/typedefs.dart';



abstract class CustomerRepo {
  const CustomerRepo();

  ResultFuture<List<CustomerEntity>> getCustomers(String tripId);
  ResultFuture<CustomerEntity> getCustomerLocation(String customerId);
  ResultFuture<List<CustomerEntity>> loadLocalCustomers(String tripId);
  ResultFuture<CustomerEntity> loadLocalCustomerLocation(String customerId);
  ResultFuture<String> calculateCustomerTotalTime(String customerId);

}


