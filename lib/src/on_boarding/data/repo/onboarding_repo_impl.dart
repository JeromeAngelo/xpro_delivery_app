import 'package:dartz/dartz.dart';
import 'package:x_pro_delivery_app/core/errors/exceptions.dart';
import 'package:x_pro_delivery_app/core/errors/failures.dart';
import 'package:x_pro_delivery_app/core/utils/typedefs.dart';
import 'package:x_pro_delivery_app/src/on_boarding/data/local_datasource/onboarding_local_datasource.dart';
import 'package:x_pro_delivery_app/src/on_boarding/domain/repo/onboarding_repo.dart';

class OnboardingRepoImpl extends OnboardingRepo {
  final OnboardingLocalDatasource _localDatasource;
  OnboardingRepoImpl(this._localDatasource);

  @override
  ResultFuture<void> cacheFirstTimer() async {
    try {
      await _localDatasource.cacheFirstTimer();
      return const Right(null);
    } on CacheException catch (e) {
      return Left(
          CacheFailure(message: e.toString(), statusCode: e.statusCode));
    }
  }

  @override
  ResultFuture<bool> checkIfUserIsFirstTimer() async {
    try {
      final result = await _localDatasource.checkIfUserIsFirstTimer();
      return Right(result);
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message, statusCode: e.statusCode));
    }
  }
}
