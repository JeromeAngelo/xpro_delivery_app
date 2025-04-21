import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/undeliverable_customer/domain/entity/undeliverable_customer_entity.dart';
import 'package:x_pro_delivery_app/core/enums/undeliverable_reason.dart';
import 'package:x_pro_delivery_app/core/utils/typedefs.dart';

abstract class UndeliverableRepo {
  const UndeliverableRepo();

  ResultFuture<List<UndeliverableCustomerEntity>> getUndeliverableCustomers(String tripId);
  ResultFuture<UndeliverableCustomerEntity> getUndeliverableCustomerById(String customerId);
  ResultFuture<UndeliverableCustomerEntity> createUndeliverableCustomer(
    UndeliverableCustomerEntity undeliverableCustomer,
    String customerId,
  );
  ResultFuture<List<UndeliverableCustomerEntity>> loadLocalUndeliverableCustomers(String tripId);
  ResultFuture<void> saveUndeliverableCustomer(
    UndeliverableCustomerEntity undeliverableCustomer,
    String customerId,
  );
  ResultFuture<void> updateUndeliverableCustomer(
    UndeliverableCustomerEntity undeliverableCustomer,
    String tripId,
  );
  ResultFuture<void> deleteUndeliverableCustomer(String undeliverableCustomerId);
  ResultFuture<void> setUndeliverableReason(String customerId, UndeliverableReason reason);
}



