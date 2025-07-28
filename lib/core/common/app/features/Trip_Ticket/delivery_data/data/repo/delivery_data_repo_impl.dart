import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/delivery_data/data/datasource/remote_datasource/delivery_data_remote_datasource.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/delivery_data/domain/entity/delivery_data_entity.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/delivery_data/domain/repo/delivery_data_repo.dart';
import 'package:xpro_delivery_admin_app/core/errors/exceptions.dart';
import 'package:xpro_delivery_admin_app/core/errors/failures.dart';
import 'package:xpro_delivery_admin_app/core/typedefs/typedefs.dart';

class DeliveryDataRepoImpl implements DeliveryDataRepo {
  const DeliveryDataRepoImpl(this._remoteDataSource);

  final DeliveryDataRemoteDataSource _remoteDataSource;

  @override
  ResultFuture<List<DeliveryDataEntity>> getAllDeliveryData() async {
    try {
      debugPrint('🌐 Fetching all delivery data from remote');
      final remoteDeliveryData = await _remoteDataSource.getAllDeliveryData();
      debugPrint('✅ Retrieved ${remoteDeliveryData.length} delivery data records');
      return Right(remoteDeliveryData);
    } on ServerException catch (e) {
      debugPrint('⚠️ API Error: ${e.message}');
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } catch (e) {
      debugPrint('⚠️ Unexpected Error: ${e.toString()}');
      return Left(ServerFailure(message: e.toString(), statusCode: '500'));
    }
  }

  @override
  ResultFuture<List<DeliveryDataEntity>> getDeliveryDataByTripId(String tripId) async {
    try {
      debugPrint('🌐 Fetching delivery data for trip ID: $tripId from remote');
      final remoteDeliveryData = await _remoteDataSource.getDeliveryDataByTripId(tripId);
      debugPrint('✅ Retrieved ${remoteDeliveryData.length} delivery data records for trip ID: $tripId');
      return Right(remoteDeliveryData);
    } on ServerException catch (e) {
      debugPrint('⚠️ API Error: ${e.message}');
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } catch (e) {
      debugPrint('⚠️ Unexpected Error: ${e.toString()}');
      return Left(ServerFailure(message: e.toString(), statusCode: '500'));
    }
  }

  @override
  ResultFuture<DeliveryDataEntity> getDeliveryDataById(String id) async {
    try {
      debugPrint('🌐 Fetching delivery data with ID: $id from remote');
      final remoteDeliveryData = await _remoteDataSource.getDeliveryDataById(id);
      debugPrint('✅ Retrieved delivery data with ID: $id');
      return Right(remoteDeliveryData);
    } on ServerException catch (e) {
      debugPrint('⚠️ API Error: ${e.message}');
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } catch (e) {
      debugPrint('⚠️ Unexpected Error: ${e.toString()}');
      return Left(ServerFailure(message: e.toString(), statusCode: '500'));
    }
  }

    @override
  ResultFuture<bool> deleteDeliveryData(String id) async {
    try {
      debugPrint('🌐 Deleting delivery data with ID: $id from remote');
      final result = await _remoteDataSource.deleteDeliveryData(id);
      debugPrint('✅ Successfully deleted delivery data with ID: $id');
      return Right(result);
    } on ServerException catch (e) {
      debugPrint('⚠️ API Error: ${e.message}');
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } catch (e) {
      debugPrint('⚠️ Unexpected Error: ${e.toString()}');
      return Left(ServerFailure(message: e.toString(), statusCode: '500'));
    }
  }
  
  @override
ResultFuture<List<DeliveryDataEntity>> getAllDeliveryDataWithTrips() async {
  try {
    debugPrint('🌐 Fetching all delivery data with trips from remote');
    final remoteDeliveryData = await _remoteDataSource.getAllDeliveryDataWithTrips();
    debugPrint('✅ Retrieved ${remoteDeliveryData.length} delivery data records with trips');
    return Right(remoteDeliveryData);
  } on ServerException catch (e) {
    debugPrint('⚠️ API Error: ${e.message}');
    return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
  } catch (e) {
    debugPrint('⚠️ Unexpected Error: ${e.toString()}');
    return Left(ServerFailure(message: e.toString(), statusCode: '500'));
  }
}

  @override
  ResultFuture<bool> addDeliveryDataToTrip(String tripId) async {
    try {
      debugPrint('🌐 Adding delivery data to trip ID: $tripId from remote');
      final result = await _remoteDataSource.addDeliveryDataToTrip(tripId);
      debugPrint('✅ Successfully added delivery data to trip ID: $tripId');
      return Right(result);
    } on ServerException catch (e) {
      debugPrint('⚠️ API Error: ${e.message}');
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } catch (e) {
      debugPrint('⚠️ Unexpected Error: ${e.toString()}');
      return Left(ServerFailure(message: e.toString(), statusCode: '500'));
    }
  }

}
