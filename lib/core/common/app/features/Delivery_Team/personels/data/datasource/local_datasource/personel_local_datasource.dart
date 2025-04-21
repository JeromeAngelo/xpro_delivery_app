import 'package:flutter/material.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Delivery_Team/personels/data/models/personel_models.dart';
import 'package:x_pro_delivery_app/core/enums/user_role.dart';
import 'package:x_pro_delivery_app/core/errors/exceptions.dart';
import 'package:x_pro_delivery_app/objectbox.g.dart';
abstract class PersonelLocalDatasource {
  Future<List<PersonelModel>> getPersonels();
  Future<void> setRole(String id, UserRole newRole);
  Future<List<PersonelModel>> loadPersonelsByTripId(String tripId);
  Future<List<PersonelModel>> loadPersonelsByDeliveryTeam(String deliveryTeamId);
}

class PersonelLocalDatasourceImpl implements PersonelLocalDatasource {
  final Box<PersonelModel> _personelBox;

  PersonelLocalDatasourceImpl(this._personelBox);

  @override
  Future<List<PersonelModel>> getPersonels() async {
    try {
      return _personelBox.getAll();
    } catch (e) {
      throw CacheException(message: e.toString());
    }
  }

  @override
  Future<void> setRole(String id, UserRole newRole) async {
    try {
      final query = _personelBox.query(PersonelModel_.pocketbaseId.equals(id)).build();
      final personel = query.findFirst();
      query.close();

      if (personel != null) {
        personel.role = newRole;
        _personelBox.put(personel);
      }
    } catch (e) {
      throw CacheException(message: e.toString());
    }
  }

  @override
  Future<List<PersonelModel>> loadPersonelsByTripId(String tripId) async {
    try {
      debugPrint('📱 Loading personnel for trip: $tripId');
      final query = _personelBox.query(PersonelModel_.tripId.equals(tripId)).build();
      final personels = query.find();
      query.close();
      
      debugPrint('✅ Found ${personels.length} personnel for trip');
      return personels;
    } catch (e) {
      debugPrint('❌ Error loading personnel by trip: ${e.toString()}');
      throw CacheException(message: e.toString());
    }
  }

  @override
  Future<List<PersonelModel>> loadPersonelsByDeliveryTeam(String deliveryTeamId) async {
    try {
      debugPrint('📱 Loading personnel for delivery team: $deliveryTeamId');
      final query = _personelBox.query(PersonelModel_.deliveryTeamId.equals(deliveryTeamId)).build();
      final personels = query.find();
      query.close();
      
      debugPrint('✅ Found ${personels.length} personnel for delivery team');
      return personels;
    } catch (e) {
      debugPrint('❌ Error loading personnel by delivery team: ${e.toString()}');
      throw CacheException(message: e.toString());
    }
  }
}
