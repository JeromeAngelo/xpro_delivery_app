import 'package:flutter/material.dart';
import 'package:pocketbase/pocketbase.dart' show PocketBase, RecordModel;
import 'package:xpro_delivery_admin_app/core/common/app/features/vehicle/vehicle_profile/data/model/vehicle_profile_model.dart';

import '../../../../../../../../enums/vehicle_status.dart';
import '../../../../../../../../errors/exceptions.dart';
import '../../../../../Trip_Ticket/delivery_vehicle_data/data/model/delivery_vehicle_model.dart';
import '../../../../../Trip_Ticket/trip/data/models/trip_models.dart';

abstract class VehicleProfileRemoteDatasource {
  Future<List<VehicleProfileModel>> getVehicleProfiles();

  /// Fetch single vehicle profile by id
  Future<VehicleProfileModel> getVehicleProfileById(String id);

  /// Create a vehicle profile
  Future<VehicleProfileModel> createVehicleProfile(
    VehicleProfileModel vehicleProfile,
  );

  /// Update an existing vehicle profile
  Future<VehicleProfileModel> updateVehicleProfile(
    String id,
    VehicleProfileModel updatedVehicleProfile,
  );

  /// Delete a vehicle profile
  Future<void> deleteVehicleProfile(String id);
}

class VehicleProfileRemoteDatasourceImpl
    implements VehicleProfileRemoteDatasource {
  VehicleProfileRemoteDatasourceImpl({required PocketBase pocketBaseClient})
    : _pocketBaseClient = pocketBaseClient;

  final PocketBase _pocketBaseClient;

  @override
  Future<VehicleProfileModel> createVehicleProfile(
    VehicleProfileModel vehicleProfile,
  ) async {
    try {
      debugPrint('🆕 Creating Vehicle Profile...');

      // ------------------------------
      // BUILD FORM DATA
      // ------------------------------
      final formData = <String, dynamic>{};

      // Relations
      if (vehicleProfile.deliveryVehicleId != null &&
          vehicleProfile.deliveryVehicleId!.isNotEmpty) {
        formData['deliveryVehicleData'] = vehicleProfile.deliveryVehicleId;
      }

      if (vehicleProfile.assignedTripIds != null &&
          vehicleProfile.assignedTripIds!.isNotEmpty) {
        formData['assignedTrips'] = vehicleProfile.assignedTripIds;
      }

      // Status
      if (vehicleProfile.status != null) {
        formData['status'] = vehicleProfile.status!.name;
      }

      // Attachments
      if (vehicleProfile.attachments != null &&
          vehicleProfile.attachments!.isNotEmpty) {
        formData['attachments'] = vehicleProfile.attachments;
      }

      debugPrint('📦 Payload to PocketBase: $formData');

      // ------------------------------
      // SEND TO POCKETBASE
      // ------------------------------
      final record = await _pocketBaseClient
          .collection('vehicleProfile')
          .create(body: formData);

      debugPrint('✅ Vehicle Profile Created Successfully');
      debugPrint('🆔 ID: ${record.id}');

      // ------------------------------
      // RETURN MODEL
      // ------------------------------
      return _mapRecordToVehicleProfileModel(record);
    } catch (e) {
      debugPrint('❌ Error creating vehicle profile: $e');
      throw ServerException(
        message: 'Failed to create vehicle profile: ${e.toString()}',
        statusCode: '500',
      );
    }
  }

  @override
  Future<void> deleteVehicleProfile(String id) async {
    try {
      debugPrint('🗑 Deleting Vehicle Profile with ID: $id');

      await _pocketBaseClient.collection('vehicleProfile').delete(id);

      debugPrint('✅ Vehicle Profile deleted successfully: $id');
    } catch (e) {
      debugPrint('❌ Error deleting vehicle profile: $e');
      throw ServerException(
        message: 'Failed to delete vehicle profile: ${e.toString()}',
        statusCode: '500',
      );
    }
  }

  @override
  Future<VehicleProfileModel> getVehicleProfileById(String id) async {
    try {
      debugPrint(
        '🔄 [VEHICLE PROFILE] Start fetching profile for deliveryVehicleData ID: $id',
      );

      // Query vehicleProfile by deliveryVehicleData field
      final records = await _pocketBaseClient
          .collection('vehicleProfile')
          .getFullList(
            filter: 'deliveryVehicleData="$id"',
            expand: 'deliveryVehicleData,assignedTrips,assignedTrips.personels',
            sort: '-created',
          );

      debugPrint(
        'ℹ️ [VEHICLE PROFILE] Number of records fetched: ${records.length}',
      );

      if (records.isEmpty) {
        debugPrint(
          '⚠️ [VEHICLE PROFILE] No Vehicle Profile found for deliveryVehicleData ID: $id',
        );
        throw ServerException(
          message: 'Vehicle profile not found for deliveryVehicleData: $id',
          statusCode: '404',
        );
      }

      final vehicleProfile = _mapRecordToVehicleProfileModel(records.first);

      debugPrint(
        '✅ [VEHICLE PROFILE] Successfully mapped VehicleProfileModel:',
      );
      debugPrint('   ID: ${vehicleProfile.id}');
      debugPrint('   Delivery Vehicle ID: ${vehicleProfile.deliveryVehicleId}');
      debugPrint('   Status: ${vehicleProfile.status?.name}');
      debugPrint(
        '   Assigned Trips Count: ${vehicleProfile.assignedTrips?.length ?? 0}',
      );
      debugPrint(
        '   Attachment Files: ${vehicleProfile.attachmentFiles?.join(', ') ?? 'None'}',
      );
      debugPrint('   Created At: ${vehicleProfile.created}');
      debugPrint('   Updated At: ${vehicleProfile.updated}');

      return vehicleProfile;
    } catch (e, stackTrace) {
      debugPrint(
        '❌ [VEHICLE PROFILE] Error fetching vehicle profile for ID: $id',
      );
      debugPrint('   Error: $e');
      debugPrint('   StackTrace: $stackTrace');
      throw ServerException(
        message: 'Failed to fetch vehicle profile: ${e.toString()}',
        statusCode: '500',
      );
    }
  }

  @override
  Future<List<VehicleProfileModel>> getVehicleProfiles() async {
    try {
      debugPrint('🔄 Fetching all vehicle profiles');

      // Fetch all records from vehicleProfile collection
      final records = await _pocketBaseClient
          .collection('vehicleProfile')
          .getFullList(expand: 'deliveryVehicleData,assignedTrips');

      debugPrint('✅ Successfully fetched ${records.length} vehicle profiles');

      // Convert to VehicleProfileModel list
      return records.map((r) => _mapRecordToVehicleProfileModel(r)).toList();
    } catch (e) {
      debugPrint('❌ Error fetching vehicle profiles: $e');
      throw ServerException(
        message: 'Failed to fetch vehicle profiles: ${e.toString()}',
        statusCode: '500',
      );
    }
  }

  @override
  Future<VehicleProfileModel> updateVehicleProfile(
    String deliveryVehicleId,
    VehicleProfileModel updatedVehicleProfile,
  ) async {
    try {
      debugPrint(
        '🔄 Updating vehicle profile for deliveryVehicleId: $deliveryVehicleId',
      );

      // First, find the vehicleProfile record that matches the deliveryVehicleData id
      final records = await _pocketBaseClient
          .collection('vehicleProfile')
          .getFullList(
            filter: 'deliveryVehicleData="$deliveryVehicleId"',
            expand: 'deliveryVehicleData,assignedTrips',
          );

      if (records.isEmpty) {
        throw ServerException(
          message:
              'Vehicle profile with deliveryVehicleData id $deliveryVehicleId not found',
          statusCode: '404',
        );
      }

      final profileRecord = records.first;
      final String profileId = profileRecord.id;

      // Prepare the updated data
      final updatedData = updatedVehicleProfile.toJson();

      // Update the vehicleProfile record
      final updatedRecord = await _pocketBaseClient
          .collection('vehicleProfile')
          .update(profileId, body: updatedData);

      debugPrint('✅ Vehicle profile updated successfully: $profileId');

      return _mapRecordToVehicleProfileModel(updatedRecord);
    } catch (e) {
      debugPrint('❌ Error updating vehicle profile: $e');
      throw ServerException(
        message: 'Failed to update vehicle profile: ${e.toString()}',
        statusCode: '500',
      );
    }
  }

  // -----------------------------
  // HELPER: Map RecordModel to VehicleProfileModel
  // -----------------------------
  VehicleProfileModel _mapRecordToVehicleProfileModel(RecordModel record) {
    try {
      debugPrint('🔄 Mapping record to VehicleProfileModel: ${record.id}');

      // DELIVERY VEHICLE (expanded)
      DeliveryVehicleModel? deliveryVehicle;
      final dvData = _mapExpandedItem(record.expand['deliveryVehicleData']);
      if (dvData != null) {
        try {
          deliveryVehicle = DeliveryVehicleModel.fromJson(dvData);
        } catch (_) {}
      }

      // ASSIGNED TRIPS (expanded)
      List<TripModel> assignedTripsList = [];
      final tripsExpand = record.expand['assignedTrips'];
      if (tripsExpand != null) {
        for (var t in tripsExpand) {
          assignedTripsList.add(_mapRecordToTripModel(t));
        }
      }

      // ATTACHMENTS
      List<String> attachmentsList = [];
      final attachmentsData = record.data['attachments'];
      if (attachmentsData != null && attachmentsData is List) {
        attachmentsList = attachmentsData.map((e) => e.toString()).toList();
      }

      // STATUS ENUM
      VehicleStatus status = VehicleStatus.goodCondition;
      final statusVal = record.data['status']?.toString();
      if (statusVal != null) {
        status = VehicleStatus.values.firstWhere(
          (s) => s.name == statusVal,
          orElse: () => VehicleStatus.goodCondition,
        );
      }

      DateTime? created;
      if (record.data['created'] != null) {
        try {
          created = DateTime.parse(record.data['expectedReturnDate']);
          debugPrint('✅ Parsed expectedReturnDate: $created');
        } catch (e) {
          debugPrint('❌ Failed to parse expectedReturnDate: ${e.toString()}');
        }
      }

      DateTime? updated;
      if (record.data['creupdatedated'] != null) {
        try {
          updated = DateTime.parse(record.data['expectedReturnDate']);
          debugPrint('✅ Parsed expectedReturnDate: $updated');
        } catch (e) {
          debugPrint('❌ Failed to parse expectedReturnDate: ${e.toString()}');
        }
      }

      return VehicleProfileModel(
        id: record.id,
        collectionId: record.collectionId,
        collectionName: record.collectionName,
        deliveryVehicleData: deliveryVehicle,
        assignedTrips: assignedTripsList,
        attachments: attachmentsList,
        deliveryVehicleId: record.data['deliveryVehicleData']?.toString(),

        status: status,
        created: created,
        updated: updated,
      );
    } catch (e) {
      debugPrint('❌ Error mapping VehicleProfileModel: $e');
      throw ServerException(
        message: 'Failed to map record to VehicleProfileModel: $e',
        statusCode: '500',
      );
    }
  }

  // -----------------------------
  // HELPER: Expanded item mapping
  // -----------------------------
  Map<String, dynamic>? _mapExpandedItem(dynamic record) {
    if (record == null) return null;

    if (record is List && record.isNotEmpty) {
      final item = record.first;
      if (item is RecordModel) {
        return {
          'id': item.id,
          'collectionId': item.collectionId,
          'collectionName': item.collectionName,
          ...Map<String, dynamic>.from(item.data),
          'created': item.created,
          'updated': item.updated,
        };
      }
    } else if (record is RecordModel) {
      return {
        'id': record.id,
        'collectionId': record.collectionId,
        'collectionName': record.collectionName,
        ...Map<String, dynamic>.from(record.data),
        'created': record.created,
        'updated': record.updated,
      };
    }
    return null;
  }

  // -----------------------------
  // HELPER: Map RecordModel to TripModel
  // -----------------------------
  TripModel _mapRecordToTripModel(RecordModel record) {
    // Map expanded personnels
    List<Map<String, dynamic>>? personnelsList = [];
    final personnelsExpand = record.expand['personels'];

    if (personnelsExpand != null) {
      personnelsList =
          personnelsExpand
              .map((p) {
                return {'id': p.id, ...Map<String, dynamic>.from(p.data)};
              })
              .cast<Map<String, dynamic>>()
              .toList();
    }

    return TripModel.fromJson({
      'id': record.id,
      'collectionId': record.collectionId,
      'collectionName': record.collectionName,
      ...record.data,
      'personels': personnelsList,
      'otp': _mapExpandedItem(record.expand['otp']),
      'created': record.created,
      'updated': record.updated,
    });
  }
}
