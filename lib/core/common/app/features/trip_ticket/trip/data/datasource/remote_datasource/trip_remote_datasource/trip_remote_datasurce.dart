import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/trip/data/models/trip_models.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/trip/data/datasource/remote_datasource/trip_remote_imp/trip_remote_base.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/trip/data/datasource/remote_datasource/trip_remote_imp/load_trip_impl.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/trip/data/datasource/remote_datasource/trip_remote_imp/get_trip_by_id_impl.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/trip/data/datasource/remote_datasource/trip_remote_imp/search_trip_by_number_impl.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/trip/data/datasource/remote_datasource/trip_remote_imp/scan_trip_by_qr_impl.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/trip/data/datasource/remote_datasource/trip_remote_imp/accept_trip_impl.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/trip/data/datasource/remote_datasource/trip_remote_imp/check_end_trip_otp_status_impl.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/trip/data/datasource/remote_datasource/trip_remote_imp/search_trips_impl.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/trip/data/datasource/remote_datasource/trip_remote_imp/get_trips_by_date_range_impl.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/trip/data/datasource/remote_datasource/trip_remote_imp/calculate_total_trip_distance_impl.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/trip/data/datasource/remote_datasource/trip_remote_imp/end_trip_impl.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/trip/data/datasource/remote_datasource/trip_remote_imp/update_trip_location_impl.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/trip/data/datasource/remote_datasource/trip_remote_imp/check_trip_personnels_impl.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/trip/data/datasource/remote_datasource/trip_remote_imp/set_mismatched_reason_impl.dart';

abstract class TripRemoteDatasurce {
  Future<TripModel> loadTrip();
  Future<TripModel> getTripById(String id);
  Future<TripModel> searchTripByNumber(String tripNumberId);
  Future<TripModel> scanTripByQR(String qrData);
  Future<(TripModel, String)> acceptTrip(String tripId);
  Future<bool> checkEndTripOtpStatus(String tripId);
  Future<List<TripModel>> searchTrips({
    String? tripNumberId,
    DateTime? startDate,
    DateTime? endDate,
    bool? isAccepted,
    bool? isEndTrip,
    String? deliveryTeamId,
    String? vehicleId,
    String? personnelId,
  });
  Future<List<TripModel>> getTripsByDateRange(
    DateTime startDate,
    DateTime endDate,
  );
  Future<String> calculateTotalTripDistance(String tripId);
  Future<TripModel> endTrip(String tripId);
  Future<TripModel> updateTripLocation(
    String tripId,
    double latitude,
    double longitude, {
    double? accuracy,
    String? source,
    double? totalDistance,
  });
  Future<List<String>> checkTripPersonnels(String tripId);
  Future<bool> setMismatchedReason(String tripId, String reasonCode);
}

class TripRemoteDatasurceImpl extends TripRemoteBase
    with
        LoadTripImpl,
        GetTripByIdImpl,
        SearchTripByNumberImpl,
        ScanTripByQRImpl,
        AcceptTripImpl,
        CheckEndTripOtpStatusImpl,
        SearchTripsImpl,
        GetTripsByDateRangeImpl,
        CalculateTotalTripDistanceImpl,
        EndTripImpl,
        UpdateTripLocationImpl,
        CheckTripPersonnelsImpl,
        SetMismatchedReasonImpl
    implements TripRemoteDatasurce {
  TripRemoteDatasurceImpl({
    required super.pocketBaseClient,
    required super.tripLocalDatasource,
  });
}
