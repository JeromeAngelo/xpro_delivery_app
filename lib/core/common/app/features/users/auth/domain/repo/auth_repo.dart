import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/trip/domain/entity/trip_entity.dart';
import 'package:x_pro_delivery_app/core/utils/typedefs.dart';
import 'package:x_pro_delivery_app/core/common/app/features/users/auth/domain/entity/users_entity.dart';

abstract class AuthRepo {
  const AuthRepo();

  ResultFuture<LocalUser> signIn(
      {required String email, required String password});

  ResultFuture<LocalUser> refreshUserData();
  // Add these powerful new functions
  ResultFuture<LocalUser> getUserById(String userId);
  ResultFuture<LocalUser> loadLocalUserById(String userId);
  ResultFuture<LocalUser> loadLocalUserData();
  ResultFuture<LocalUser> loadUser();


  // User Trip Functions
  ResultFuture<TripEntity> getUserTrip(String userId);
  ResultFuture<TripEntity> loadLocalUserTrip(String userId);


  // New sync methods
  ResultFuture<void> syncUserData(String userId);
  ResultFuture<void> syncUserTripData(String userId);

   // Add sign out method
  ResultFuture<void> signOut();
}
