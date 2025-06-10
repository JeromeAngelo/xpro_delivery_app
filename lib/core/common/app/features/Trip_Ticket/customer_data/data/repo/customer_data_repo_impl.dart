import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/customer_data/data/datasources/remote_datasource/customer_data_remote_datasource.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/customer_data/domain/entity/customer_data_entity.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/customer_data/domain/repo/customer_data_repo.dart';
import 'package:x_pro_delivery_app/core/errors/exceptions.dart';
import 'package:x_pro_delivery_app/core/errors/failures.dart';
import 'package:x_pro_delivery_app/core/utils/typedefs.dart';


class CustomerDataRepoImpl implements CustomerDataRepo {
  const CustomerDataRepoImpl(this._remoteDataSource);

  final CustomerDataRemoteDataSource _remoteDataSource;

  @override
  ResultFuture<List<CustomerDataEntity>> getAllCustomerData() async {
    try {
      debugPrint('🌐 Fetching all customer data from remote');
      final remoteCustomerData = await _remoteDataSource.getAllCustomerData();
      return Right(remoteCustomerData);
    } on ServerException catch (e) {
      debugPrint('⚠️ API Error: ${e.message}');
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    }
  }

  @override
  ResultFuture<CustomerDataEntity> getCustomerDataById(String id) async {
    try {
      debugPrint('🌐 Fetching customer data by ID: $id');
      final remoteCustomerData = await _remoteDataSource.getCustomerDataById(id);
      return Right(remoteCustomerData);
    } on ServerException catch (e) {
      debugPrint('⚠️ API Error: ${e.message}');
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    }
  }

  @override
  ResultFuture<CustomerDataEntity> createCustomerData({
    required String name,
    required String refId,
    required String province,
    required String municipality,
    required String barangay,
    double? longitude,
    double? latitude,
  }) async {
    try {
      debugPrint('🌐 Creating new customer data');
      final createdCustomerData = await _remoteDataSource.createCustomerData(
        name: name,
        refId: refId,
        province: province,
        municipality: municipality,
        barangay: barangay,
        longitude: longitude,
        latitude: latitude,
      );
      
      debugPrint('✅ Successfully created customer data with ID: ${createdCustomerData.id}');
      return Right(createdCustomerData);
    } on ServerException catch (e) {
      debugPrint('⚠️ API Error: ${e.message}');
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    }
  }

  @override
  ResultFuture<CustomerDataEntity> updateCustomerData({
    required String id,
    String? name,
    String? refId,
    String? province,
    String? municipality,
    String? barangay,
    double? longitude,
    double? latitude,
  }) async {
    try {
      debugPrint('🌐 Updating customer data: $id');
      
      final updatedCustomerData = await _remoteDataSource.updateCustomerData(
        id: id,
        name: name,
        refId: refId,
        province: province,
        municipality: municipality,
        barangay: barangay,
        longitude: longitude,
        latitude: latitude,
      );
      
      debugPrint('✅ Successfully updated customer data');
      return Right(updatedCustomerData);
    } on ServerException catch (e) {
      debugPrint('⚠️ API Error: ${e.message}');
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    }
  }

  @override
  ResultFuture<bool> deleteCustomerData(String id) async {
    try {
      debugPrint('🌐 Deleting customer data: $id');
      final result = await _remoteDataSource.deleteCustomerData(id);
      
      debugPrint('✅ Successfully deleted customer data');
      return Right(result);
    } on ServerException catch (e) {
      debugPrint('⚠️ API Error: ${e.message}');
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    }
  }

  @override
  ResultFuture<bool> deleteAllCustomerData(List<String> ids) async {
    try {
      debugPrint('🌐 Deleting multiple customer data records: ${ids.length} items');
      final result = await _remoteDataSource.deleteAllCustomerData(ids);
      
      debugPrint('✅ Successfully deleted all customer data');
      return Right(result);
    } on ServerException catch (e) {
      debugPrint('⚠️ API Error: ${e.message}');
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    }
  }

  @override
  ResultFuture<bool> addCustomerToDelivery({
    required String customerId,
    required String deliveryId,
  }) async {
    try {
      debugPrint('🌐 Adding customer $customerId to delivery $deliveryId');
      final result = await _remoteDataSource.addCustomerToDelivery(
        customerId: customerId,
        deliveryId: deliveryId,
      );
      
      debugPrint('✅ Successfully added customer to delivery');
      return Right(result);
    } on ServerException catch (e) {
      debugPrint('⚠️ API Error: ${e.message}');
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    }
  }

  @override
  ResultFuture<List<CustomerDataEntity>> getCustomersByDeliveryId(String deliveryId) async {
    try {
      debugPrint('🌐 Fetching customers for delivery: $deliveryId');
      final customers = await _remoteDataSource.getCustomersByDeliveryId(deliveryId);
      
      debugPrint('✅ Retrieved ${customers.length} customers for delivery');
      return Right(customers);
    } on ServerException catch (e) {
      debugPrint('⚠️ API Error: ${e.message}');
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    }
  }

}
