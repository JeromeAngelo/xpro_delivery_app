import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/trip/domain/entity/trip_entity.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/trip/domain/repo/trip_repo.dart';
import 'package:xpro_delivery_admin_app/core/typedefs/typedefs.dart';
import 'package:xpro_delivery_admin_app/core/usecases/usecase.dart';
import 'package:equatable/equatable.dart';

class SearchTripTickets extends UsecaseWithParams<List<TripEntity>, SearchTripTicketsParams> {
  final TripRepo _repo;

  const SearchTripTickets(this._repo);

  @override
  ResultFuture<List<TripEntity>> call(SearchTripTicketsParams params) {
    return _repo.searchTripTickets(
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

class SearchTripTicketsParams extends Equatable {
  final String? tripNumberId;
  final DateTime? startDate;
  final DateTime? endDate;
  final bool? isAccepted;
  final bool? isEndTrip;
  final String? deliveryTeamId;
  final String? vehicleId;
  final String? personnelId;
  final String? name;

  const SearchTripTicketsParams({
    this.tripNumberId,
    this.startDate,
    this.endDate,
    this.isAccepted,
    this.isEndTrip,
    this.name,
    this.deliveryTeamId,
    this.vehicleId,
    this.personnelId,
  });

  @override
  List<Object?> get props => [
    tripNumberId,
    startDate,
    endDate,
    name,
    isAccepted,
    isEndTrip,
    deliveryTeamId,
    vehicleId,
    personnelId,
  ];
}
