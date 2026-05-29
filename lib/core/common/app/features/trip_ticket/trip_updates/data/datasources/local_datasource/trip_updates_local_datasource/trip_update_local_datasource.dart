import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/trip_updates/data/model/trip_update_model.dart';
import 'package:x_pro_delivery_app/core/enums/trip_update_status.dart';
import 'package:x_pro_delivery_app/objectbox.g.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/trip_updates/data/datasources/local_datasource/trip_updates_local_impl/trip_update_local_base.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/trip_updates/data/datasources/local_datasource/trip_updates_local_impl/get_trip_updates_impl.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/trip_updates/data/datasources/local_datasource/trip_updates_local_impl/create_trip_update_impl.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/trip_updates/data/datasources/local_datasource/trip_updates_local_impl/cache_trip_updates_impl.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/trip_updates/data/datasources/local_datasource/trip_updates_local_impl/get_pending_trip_updates_impl.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/trip_updates/data/datasources/local_datasource/trip_updates_local_impl/mark_trip_update_syncing_impl.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/trip_updates/data/datasources/local_datasource/trip_updates_local_impl/mark_trip_update_synced_impl.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/trip_updates/data/datasources/local_datasource/trip_updates_local_impl/mark_trip_update_failed_impl.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/trip_updates/data/datasources/local_datasource/trip_updates_local_impl/get_pending_sync_list_impl.dart';

abstract class TripUpdateLocalDatasource {
  Future<List<TripUpdateModel>> getTripUpdates(String tripId);
  Future<void> createTripUpdate({
    required String tripId,
    required String description,
    required String image,
    required String latitude,
    required String longitude,
    required TripUpdateStatus status,
  });
  Future<void> cacheTripUpdates(List<TripUpdateModel> updates);
  Box<TripUpdateModel> get tripUpdateBox;
}

class TripUpdateLocalDatasourceImpl extends TripUpdateLocalBase
    with
        GetTripUpdatesImpl,
        CreateTripUpdateImpl,
        CacheTripUpdatesImpl,
        GetPendingTripUpdatesImpl,
        MarkTripUpdateSyncingImpl,
        MarkTripUpdateSyncedImpl,
        MarkTripUpdateFailedImpl,
        GetPendingSyncListImpl
    implements TripUpdateLocalDatasource {
  TripUpdateLocalDatasourceImpl(super.objectBoxStore);
}
