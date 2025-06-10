import 'package:x_pro_delivery_app/core/common/app/features/delivery_team/personels/domain/entity/personel_entity.dart';
import 'package:x_pro_delivery_app/core/enums/user_role.dart';
import 'package:x_pro_delivery_app/core/utils/typedefs.dart';

abstract class PersonelRepo {
  // Existing functions
  ResultFuture<List<PersonelEntity>> getPersonels();
  ResultFuture<void> setRole(String id, UserRole newRole);

  // New remote functions
  ResultFuture<List<PersonelEntity>> loadPersonelsByTripId(String tripId);
  ResultFuture<List<PersonelEntity>> loadPersonelsByDeliveryTeam(String deliveryTeamId);

  // New local functions
  ResultFuture<List<PersonelEntity>> loadLocalPersonelsByTripId(String tripId);
  ResultFuture<List<PersonelEntity>> loadLocalPersonelsByDeliveryTeam(String deliveryTeamId);
}
