import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/undeliverable_customer/data/datasources/local_datasource/undeliverable_customer_local_customer.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/undeliverable_customer/data/datasources/remote_datasource/undeliverable_customer_remote_datasrc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/undeliverable_customer/data/model/undeliverable_customer_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/undeliverable_customer/domain/entity/undeliverable_customer_entity.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/undeliverable_customer/domain/repo/undeliverable_repo.dart';
import 'package:x_pro_delivery_app/core/enums/undeliverable_reason.dart';
import 'package:x_pro_delivery_app/core/errors/exceptions.dart';
import 'package:x_pro_delivery_app/core/errors/failures.dart';
import 'package:x_pro_delivery_app/core/utils/typedefs.dart';
class UndeliverableCustomerRepoImpl implements UndeliverableRepo {
  const UndeliverableCustomerRepoImpl({
    required UndeliverableCustomerRemoteDataSource remoteDataSource,
    required UndeliverableCustomerLocalDataSource localDataSource,
  })  : _remoteDataSource = remoteDataSource,
        _localDataSource = localDataSource;

  final UndeliverableCustomerRemoteDataSource _remoteDataSource;
  final UndeliverableCustomerLocalDataSource _localDataSource;

  @override
ResultFuture<List<UndeliverableCustomerEntity>> getUndeliverableCustomers(String tripId) async {
  try {
    final remoteCustomers = await _remoteDataSource.getUndeliverableCustomers(tripId);
    await Future.forEach(
      remoteCustomers,
      (customer) => _localDataSource.saveUndeliverableCustomer(
        customer,
        customer.customer?.id ?? '',
      ),
    );
    return Right(remoteCustomers);
  } on ServerException catch (e) {
    return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
  }
}


  @override
ResultFuture<UndeliverableCustomerEntity> getUndeliverableCustomerById(String customerId) async {
  try {
    final customer = await _remoteDataSource.getUndeliverableCustomerById(customerId);
    await _localDataSource.saveUndeliverableCustomer(customer, customerId);
    return Right(customer);
  } on ServerException catch (e) {
    return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
  }
}


 @override
ResultFuture<UndeliverableCustomerEntity> createUndeliverableCustomer(
  UndeliverableCustomerEntity undeliverableCustomer,
  String customerId,
) async {
  try {
    final customerModel = UndeliverableCustomerModel.fromJson(
      (undeliverableCustomer as UndeliverableCustomerModel).toJson(),
    );
    
    // Create locally first
    debugPrint('💾 Creating undeliverable customer in local storage');
    await _localDataSource.createUndeliverableCustomer(
      customerModel,
      customerId,
    );

    // Then sync with remote
    debugPrint('🌐 Syncing undeliverable customer to remote');
    final remoteCustomer = await _remoteDataSource.createUndeliverableCustomer(
      customerModel,
      customerId,
    );
    
    return Right(remoteCustomer);
  } on CacheException catch (e) {
    return Left(CacheFailure(message: e.message, statusCode: e.statusCode));
  } on ServerException catch (e) {
    debugPrint('⚠️ Remote creation failed, but local creation succeeded');
    return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
  }
}

  @override
  ResultFuture<List<UndeliverableCustomerEntity>> loadLocalUndeliverableCustomers(String tripId) async {
    try {
      final localCustomers = await _localDataSource.getUndeliverableCustomers(tripId);
      return Right(localCustomers);
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message, statusCode: e.statusCode));
    }
  }
@override
ResultFuture<void> saveUndeliverableCustomer(
  UndeliverableCustomerEntity undeliverableCustomer,
  String customerId,
) async {
  try {
    final customerModel = UndeliverableCustomerModel.fromJson(
      (undeliverableCustomer as UndeliverableCustomerModel).toJson(),
    );
    
    // Save locally first
    debugPrint('💾 Saving undeliverable customer to local storage');
    await _localDataSource.saveUndeliverableCustomer(customerModel, customerId);

    // Then sync with remote
    debugPrint('🌐 Syncing saved customer to remote');
    await _remoteDataSource.saveUndeliverableCustomer(customerModel, customerId);
    
    return const Right(null);
  } on CacheException catch (e) {
    return Left(CacheFailure(message: e.message, statusCode: e.statusCode));
  } on ServerException catch (e) {
    debugPrint('⚠️ Remote save failed, but local save succeeded');
    return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
  }
}

@override
ResultFuture<void> updateUndeliverableCustomer(
  UndeliverableCustomerEntity undeliverableCustomer,
  String tripId,
) async {
  try {
    final customerModel = UndeliverableCustomerModel.fromJson(
      (undeliverableCustomer as UndeliverableCustomerModel).toJson(),
    );
    
    // Update locally first
    debugPrint('💾 Updating undeliverable customer in local storage');
    await _localDataSource.updateUndeliverableCustomer(customerModel, tripId);

    // Then sync with remote
    debugPrint('🌐 Syncing update to remote');
    await _remoteDataSource.updateUndeliverableCustomer(customerModel, tripId);
    
    return const Right(null);
  } on CacheException catch (e) {
    return Left(CacheFailure(message: e.message, statusCode: e.statusCode));
  } on ServerException catch (e) {
    debugPrint('⚠️ Remote update failed, but local update succeeded');
    return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
  }
}


  @override
  ResultFuture<void> deleteUndeliverableCustomer(String undeliverableCustomerId) async {
    try {
      await _remoteDataSource.deleteUndeliverableCustomer(undeliverableCustomerId);
      await _localDataSource.deleteUndeliverableCustomer(undeliverableCustomerId);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    }
  }

  @override
  ResultFuture<void> setUndeliverableReason(String customerId, UndeliverableReason reason) async {
    try {
      await _remoteDataSource.setUndeliverableReason(customerId, reason);
      await _localDataSource.setUndeliverableReason(customerId, reason);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    }
  }
}
