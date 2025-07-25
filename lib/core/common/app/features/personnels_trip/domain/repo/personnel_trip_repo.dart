import 'package:xpro_delivery_admin_app/core/common/app/features/personnels_trip/domain/entity/personnel_trip_entity.dart';
import 'package:xpro_delivery_admin_app/core/typedefs/typedefs.dart';

abstract class PersonnelTripRepo {
  const PersonnelTripRepo();

  // CRUD Operations
  ResultFuture<List<PersonnelTripEntity>> getAllPersonnelTrips();
  ResultFuture<PersonnelTripEntity> getPersonnelTripById(String id);
  
  // Additional Operations
  ResultFuture<List<PersonnelTripEntity>> getPersonnelTripsByPersonnelId(String personnelId);
  ResultFuture<List<PersonnelTripEntity>> getPersonnelTripsByTripId(String tripId);
}
