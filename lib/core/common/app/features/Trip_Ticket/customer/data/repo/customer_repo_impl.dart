import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/customer/data/datasource/local_datasource/customer_local_datasource.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/customer/data/datasource/remote_datasource/customer_remote_data_source.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/customer/data/model/customer_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/customer/domain/entity/customer_entity.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/customer/domain/repo/customer_repo.dart';
import 'package:x_pro_delivery_app/core/errors/exceptions.dart';
import 'package:x_pro_delivery_app/core/errors/failures.dart';
import 'package:x_pro_delivery_app/core/utils/typedefs.dart';
class CustomerRepoImpl extends CustomerRepo {
  const CustomerRepoImpl(this._remoteDataSource, this._localDataSource);

  final CustomerRemoteDataSource _remoteDataSource;
  final CustomerLocalDatasource _localDataSource;
@override
ResultFuture<List<CustomerEntity>> getCustomers(String tripId) async {
  try {
    debugPrint('🌐 Fetching customers from remote for trip: $tripId');
    final remoteCustomers = await _remoteDataSource.getCustomers(tripId);
    
    final validCustomers = remoteCustomers.where((customer) => 
      customer.id != null && 
      customer.storeName != null && 
      customer.deliveryNumber != null
    ).toList();
    
    await _localDataSource.cacheCustomers(validCustomers);
    debugPrint('💾 Cached ${validCustomers.length} customers locally');
    
    return Right(validCustomers);
  } on ServerException catch (e) {
    return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
  }
}

@override
ResultFuture<CustomerEntity> getCustomerLocation(String customerId) async {
  try {
    debugPrint('🌐 Fetching customer location from remote');
    final remoteCustomer = await _remoteDataSource.getCustomerLocation(customerId);
    await _localDataSource.updateCustomer(remoteCustomer);
    return Right(remoteCustomer);
  } on ServerException catch (e) {
    return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
  }
}

@override
ResultFuture<List<CustomerEntity>> loadLocalCustomers(String tripId) async {
  try {
    debugPrint('📱 Loading customers from local storage first');
    final localCustomers = await _localDataSource.getCustomers(tripId);
    debugPrint('✅ Found ${localCustomers.length} customers in local storage');

    try {
      debugPrint('🌐 Updating with remote data');
      final remoteCustomers = await _remoteDataSource.getCustomers(tripId);
      await _localDataSource.cacheCustomers(remoteCustomers);
      debugPrint('💾 Updated local storage with ${remoteCustomers.length} customers');
      return Right(remoteCustomers);
    } on ServerException {
      debugPrint('📦 Using cached customer data');
      return Right(localCustomers);
    }
  } on CacheException catch (e) {
    return Left(CacheFailure(message: e.message, statusCode: e.statusCode));
  }
}


@override
ResultFuture<CustomerEntity> loadLocalCustomerLocation(String customerId) async {
  try {
    debugPrint('📱 Loading customer location from local storage first');
    final localCustomer = await _localDataSource.getCustomerLocation(customerId);
    
    try {
      debugPrint('🌐 Updating with remote location data');
      final remoteCustomer = await _remoteDataSource.getCustomerLocation(customerId);
      await _localDataSource.updateCustomer(remoteCustomer);
      return Right(remoteCustomer);
    } on ServerException {
      debugPrint('📦 Using cached location data');
      return Right(localCustomer);
    }
  } on CacheException catch (e) {
    return Left(CacheFailure(message: e.message, statusCode: e.statusCode));
  }
}



  Future<Object> updateCustomer(CustomerEntity customer) async {
    try {
      // Update local first
      debugPrint('💾 Updating customer in local storage');
      await _localDataSource.updateCustomer(customer as CustomerModel);
      
      // Then update remote
      debugPrint('🌐 Syncing customer update to remote');
      await _remoteDataSource.updateCustomer(customer);
      
      return const Right(null);
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message, statusCode: e.statusCode));
    } on ServerException catch (e) {
      debugPrint('⚠️ Remote update failed, but local update succeeded');
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    }
  }
  
 @override
ResultFuture<String> calculateCustomerTotalTime(String customerId) async {
  try {
    debugPrint('🔄 Calculating customer total time');
    final remoteTime = await _remoteDataSource.calculateCustomerTotalTime(customerId);
    await _localDataSource.calculateCustomerTotalTime(customerId);
    return Right(remoteTime);
  } on ServerException {
    try {
      final localTime = await _localDataSource.calculateCustomerTotalTime(customerId);
      return Right(localTime);
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message, statusCode: e.statusCode));
    }
  }
}

}
