import 'package:flutter/material.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/trip/domain/entity/trip_entity.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/trip/domain/repo/trip_repo.dart';
import 'package:x_pro_delivery_app/core/usecases/usecase.dart';
import 'package:x_pro_delivery_app/core/utils/typedefs.dart';

class ScanQRUsecase extends UsecaseWithParams<TripEntity, String> {
  final TripRepo _repo;

  const ScanQRUsecase(this._repo);

  @override
  ResultFuture<TripEntity> call(String params) async {
    debugPrint('🔍 Scanning QR code: $params');
    return _repo.scanTripByQR(params);
  }
}
