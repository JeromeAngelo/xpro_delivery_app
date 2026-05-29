import 'package:x_pro_delivery_app/core/enums/trip_update_status.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/trip_updates/data/model/trip_update_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/trip_updates/data/datasources/remote_datasource/trip_update_remote_impl/trip_update_remote_base.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/trip_updates/data/datasources/remote_datasource/trip_update_remote_impl/get_trip_updates_impl.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/trip_updates/data/datasources/remote_datasource/trip_update_remote_impl/create_trip_update_impl.dart';

abstract class TripUpdateRemoteDatasource {
  Future<List<TripUpdateModel>> getTripUpdates(String tripId);
  Future<String> createTripUpdate({
    required String tripId,
    required String description,
    required String image,
    required String latitude,
    required String longitude,
    required TripUpdateStatus status,
  });
}

class TripUpdateRemoteDatasourceImpl extends TripUpdateRemoteBase
    with GetTripUpdatesImpl, CreateTripUpdateImpl
    implements TripUpdateRemoteDatasource {
  const TripUpdateRemoteDatasourceImpl({required super.pocketBaseClient});
}
