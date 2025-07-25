import 'package:xpro_delivery_admin_app/core/common/app/features/Delivery_Team/personels/domain/entity/personel_entity.dart';
import 'package:xpro_delivery_admin_app/core/enums/user_role.dart';
import 'package:xpro_delivery_admin_app/core/typedefs/typedefs.dart';

abstract class PersonelRepo {
  // Existing functions to keep
  ResultFuture<List<PersonelEntity>> getPersonels();
  ResultFuture<PersonelEntity> getPersonelById(String personelId);
  ResultFuture<void> setRole(String id, UserRole newRole);
  ResultFuture<List<PersonelEntity>> loadPersonelsByTripId(String tripId);
  ResultFuture<List<PersonelEntity>> loadPersonelsByDeliveryTeam(String deliveryTeamId);

  // New functions for managing personnel
  ResultFuture<PersonelEntity> createPersonel({
    required String name,
    required UserRole role,
    String? deliveryTeamId,
    String? tripId,
  });
  
  ResultFuture<bool> deletePersonel(String personelId);
  
  ResultFuture<bool> deleteAllPersonels(List<String> personelIds);
  
  ResultFuture<PersonelEntity> updatePersonel({
    required String personelId,
    String? name,
    UserRole? role,
    String? deliveryTeamId,
    String? tripId,
  });
  
 
}
