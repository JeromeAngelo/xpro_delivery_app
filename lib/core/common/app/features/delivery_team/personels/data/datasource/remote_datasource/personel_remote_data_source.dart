import 'package:pocketbase/pocketbase.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_team/personels/data/models/personel_models.dart';
import 'package:x_pro_delivery_app/core/enums/user_role.dart';
abstract class PersonelRemoteDataSource {
  Future<List<PersonelModel>> getPersonels();
  Future<void> setRole(String id, UserRole newRole);
  Future<List<PersonelModel>> loadPersonelsByTripId(String tripId);
  Future<List<PersonelModel>> loadPersonelsByDeliveryTeam(String deliveryTeamId);
}

class PersonelRemoteDataSourceImpl implements PersonelRemoteDataSource {
  final PocketBase _pocketBaseClient;

  PersonelRemoteDataSourceImpl({required PocketBase pocketBaseClient})
      : _pocketBaseClient = pocketBaseClient;

  @override
  Future<List<PersonelModel>> getPersonels() async {
    final records = await _pocketBaseClient.collection('personels').getFullList();
    return records.map((record) {
      final data = record.toJson();
      return PersonelModel.fromJson(data);
    }).toList();
  }

  @override
  Future<void> setRole(String id, UserRole newRole) async {
    final roleValue = newRole == UserRole.teamLeader ? 'team_leader' : 'helper';
    await _pocketBaseClient.collection('personels').update(
      id,
      body: {'role': roleValue},
    );
  }

  @override
  Future<List<PersonelModel>> loadPersonelsByTripId(String tripId) async {
    final records = await _pocketBaseClient.collection('personels').getFullList(
      filter: 'trip = "$tripId"',
      expand: 'trip,deliveryTeam',
    );
    
    return records.map((record) => PersonelModel.fromJson(record.toJson())).toList();
  }

  @override
  Future<List<PersonelModel>> loadPersonelsByDeliveryTeam(String deliveryTeamId) async {
    final records = await _pocketBaseClient.collection('personels').getFullList(
      filter: 'deliveryTeam = "$deliveryTeamId"',
      expand: 'trip,deliveryTeam',
    );
    
    return records.map((record) => PersonelModel.fromJson(record.toJson())).toList();
  }
}
