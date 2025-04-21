import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/completed_customer/data/datasource/local_datasource/completed_local_data_source.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/completed_customer/data/datasource/remote_datasource/completed_customer_remote_datasource.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/completed_customer/domain/entity/completed_customer_entity.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/completed_customer/domain/repo/completed_customer_repo.dart';
import 'package:x_pro_delivery_app/core/errors/exceptions.dart';
import 'package:x_pro_delivery_app/core/errors/failures.dart';
import 'package:x_pro_delivery_app/core/utils/typedefs.dart';

class CompletedCustomerRepoImpl extends CompletedCustomerRepo {
   CompletedCustomerRepoImpl(this._remoteDataSource, this._localDataSource);

  final CompletedCustomerRemoteDatasource _remoteDataSource;
  final CompletedCustomerLocalDatasource _localDataSource;

    @override
  ResultFuture<List<CompletedCustomerEntity>> getCompletedCustomers(String tripId) async {
    try {
      debugPrint('🔄 Fetching completed customers from remote source...');
      final remoteCustomers = await _remoteDataSource.getCompletedCustomers(tripId);
      
      debugPrint('📥 Starting sync for ${remoteCustomers.length} remote completed customers');
      
      for (var customer in remoteCustomers) {
        debugPrint('💾 Syncing completed customer: ${customer.storeName}');
        await _localDataSource.updateCompletedCustomer(customer);
      }
      
      return Right(remoteCustomers);
      
    } on ServerException catch (e) {
      debugPrint('⚠️ API Error: ${e.message}');
      
      try {
        final localCustomers = await _localDataSource.getCompletedCustomers(tripId);
        if (localCustomers.isNotEmpty) {
          debugPrint('📦 Using ${localCustomers.length} completed customers from cache');
          return Right(localCustomers);
        }
      } catch (cacheError) {
        debugPrint('❌ Cache Error: $cacheError');
      }
      
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    }
  }


  @override
  ResultFuture<CompletedCustomerEntity> getCompletedCustomerById(String customerId) async {
    try {
      debugPrint('🌐 Fetching completed customer data from remote: $customerId');
      final remoteCustomer = await _remoteDataSource.getCompletedCustomerById(customerId);
      
      await _localDataSource.updateCompletedCustomer(remoteCustomer);
      
      debugPrint('📦 Remote data synced for completed customer:');
      debugPrint('   🏪 Store: ${remoteCustomer.storeName}');
      debugPrint('   🧾 Invoices: ${remoteCustomer.invoicesList.length}');
      debugPrint('   📝 Status Updates: ${remoteCustomer.deliveryStatus.length}');
      
      return Right(remoteCustomer);
    } on ServerException {
      debugPrint('⚠️ Remote fetch failed, attempting local cache retrieval');
      try {
        final localCustomer = await _localDataSource.getCompletedCustomerById(customerId);
        debugPrint('💾 Retrieved from local cache:');
        debugPrint('   🏪 Store: ${localCustomer.storeName}');
        debugPrint('   🧾 Invoices: ${localCustomer.invoicesList.length}');
        return Right(localCustomer);
      } on CacheException catch (e) {
        debugPrint('❌ Local cache retrieval failed: ${e.message}');
        return Left(CacheFailure(message: e.message, statusCode: e.statusCode));
      }
    }
  }
  
 
@override
ResultFuture<List<CompletedCustomerEntity>> loadLocalCompletedCustomers(String tripId) async {
  try {
    debugPrint('📱 Loading completed customers from local storage');
    final localCustomers = await _localDataSource.getCompletedCustomers(tripId);
    
    if (localCustomers.isNotEmpty) {
      debugPrint('✅ Found ${localCustomers.length} completed customers in local storage');
      return Right(localCustomers);
    }
    
    debugPrint('⚠️ No completed customers found in local storage');
    return const Right([]);
    
  } catch (e) {
    debugPrint('❌ Local storage error: ${e.toString()}');
    return Left(CacheFailure(
      message: 'Failed to load local completed customers',
      statusCode: '500',
    ));
  }
}

  @override
ResultFuture<CompletedCustomerEntity> loadLocalCompletedCustomerById(String customerId) async {
  try {
    debugPrint('📱 Loading completed customer from local storage');
    final localCustomer = await _localDataSource.getCompletedCustomerById(customerId);
    
    debugPrint('✅ Found completed customer in local storage');
    debugPrint('   🏪 Store: ${localCustomer.storeName}');
    debugPrint('   📦 Updates: ${localCustomer.deliveryStatus.length}');
    debugPrint('   🧾 Invoices: ${localCustomer.invoicesList.length}');
    
    return Right(localCustomer);
    
  } catch (e) {
    debugPrint('❌ Local storage error: ${e.toString()}');
    return Left(CacheFailure(
      message: 'Failed to load local completed customer',
      statusCode: '500',
    ));
  }
}

 
}
