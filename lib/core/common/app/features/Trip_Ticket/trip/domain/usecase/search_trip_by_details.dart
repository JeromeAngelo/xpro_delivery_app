import 'package:equatable/equatable.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/trip/domain/entity/trip_entity.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/trip/domain/repo/trip_repo.dart';
import 'package:x_pro_delivery_app/core/usecases/usecase.dart';
import 'package:x_pro_delivery_app/core/utils/typedefs.dart';

class SearchTrips extends UsecaseWithParams<List<TripEntity>, SearchTripsParams> {
  final TripRepo _repo;

  const SearchTrips(this._repo);

  @override
  ResultFuture<List<TripEntity>> call(SearchTripsParams params) async {
    return _repo.searchTrips(
      tripNumberId: params.tripNumberId,
      startDate: params.startDate,
      endDate: params.endDate,
      isAccepted: params.isAccepted,
      isEndTrip: params.isEndTrip,
      deliveryTeamId: params.deliveryTeamId,
      vehicleId: params.vehicleId,
      personnelId: params.personnelId,
    );
  }
}

class SearchTripsParams extends Equatable {
  final String? tripNumberId;
  final DateTime? startDate;
  final DateTime? endDate;
  final bool? isAccepted;
  final bool? isEndTrip;
  final String? deliveryTeamId;
  final String? vehicleId;
  final String? personnelId;

  const SearchTripsParams({
    this.tripNumberId,
    this.startDate,
    this.endDate,
    this.isAccepted,
    this.isEndTrip,
    this.deliveryTeamId,
    this.vehicleId,
    this.personnelId,
  });

  @override
  List<Object?> get props => [
        tripNumberId,
        startDate,
        endDate,
        isAccepted,
        isEndTrip,
        deliveryTeamId,
        vehicleId,
        personnelId,
      ];
}
