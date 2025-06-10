
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/customer_data/domain/entity/customer_data_entity.dart';
import 'package:x_pro_delivery_app/core/utils/typedefs.dart';

abstract class CustomerDataRepo {
  const CustomerDataRepo();

  // CRUD Operations
  ResultFuture<List<CustomerDataEntity>> getAllCustomerData();
  ResultFuture<CustomerDataEntity> getCustomerDataById(String id);
  ResultFuture<CustomerDataEntity> createCustomerData({
    required String name,
    required String refId,
    required String province,
    required String municipality,
    required String barangay,
    double? longitude,
    double? latitude,
  });
  ResultFuture<CustomerDataEntity> updateCustomerData({
    required String id,
    String? name,
    String? refId,
    String? province,
    String? municipality,
    String? barangay,
    double? longitude,
    double? latitude,
  });
  ResultFuture<bool> deleteCustomerData(String id);
  ResultFuture<bool> deleteAllCustomerData(List<String> ids);

  // Additional Operations
  ResultFuture<bool> addCustomerToDelivery({
    required String customerId,
    required String deliveryId,
  });
  ResultFuture<List<CustomerDataEntity>> getCustomersByDeliveryId(String deliveryId);

  
}
