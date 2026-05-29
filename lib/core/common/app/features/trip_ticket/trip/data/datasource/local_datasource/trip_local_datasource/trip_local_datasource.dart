import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/trip/data/datasource/local_datasource/trip_local_impl/trip_local_base.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/trip/data/datasource/local_datasource/trip_local_impl/load_trip_impl.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/trip/data/datasource/local_datasource/trip_local_impl/search_trip_by_number_impl.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/trip/data/datasource/local_datasource/trip_local_impl/accept_trip_impl.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/trip/data/datasource/local_datasource/trip_local_impl/save_trip_impl.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/trip/data/datasource/local_datasource/trip_local_impl/auto_save_trip_impl.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/trip/data/datasource/local_datasource/trip_local_impl/calculate_total_trip_distance_impl.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/trip/data/datasource/local_datasource/trip_local_impl/get_tracking_id_impl.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/trip/data/datasource/local_datasource/trip_local_impl/check_end_trip_otp_status_impl.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/trip/data/datasource/local_datasource/trip_local_impl/get_trip_by_id_impl.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/trip/data/datasource/local_datasource/trip_local_impl/end_trip_impl.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/trip/data/datasource/local_datasource/trip_local_impl/update_trip_location_local_impl.dart';

import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/trip/data/models/trip_models.dart';

abstract class TripLocalDatasource {
  Future<TripModel> loadTrip();
  Future<TripModel> searchTripByNumber(String tripNumberId);
  Future<(TripModel, String)> acceptTrip(String tripId);
  Future<void> saveTrip(TripModel trip);
  Future<void> autoSaveTrip(TripModel trip);

  Future<String> calculateTotalTripDistance(String tripId);
  Future<String?> getTrackingId();
  Future<bool> checkEndTripOtpStatus(String tripId);
  Future<TripModel> getTripById(String id);
  Future<void> endTrip(String tripId);
  Future<TripModel> updateTripLocationLocal(
    String tripId,
    double latitude,
    double longitude, {
    double? accuracy,
    String? source,
    double? totalDistance,
  });
}

class TripLocalDatasourceImpl extends TripLocalBase
    with
        LoadTripImpl,
        SearchTripByNumberImpl,
        AcceptTripImpl,
        SaveTripImpl,
        AutoSaveTripImpl,
        CalculateTotalTripDistanceImpl,
        GetTrackingIdImpl,
        CheckEndTripOtpStatusImpl,
        GetTripByIdImpl,
        EndTripImpl,
        UpdateTripLocationLocalImpl
    implements TripLocalDatasource {
  TripLocalDatasourceImpl(super.objectBoxStore);
}
