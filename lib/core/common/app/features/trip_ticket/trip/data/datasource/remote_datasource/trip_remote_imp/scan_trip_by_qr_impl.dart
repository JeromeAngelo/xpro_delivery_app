import 'package:flutter/foundation.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/trip/data/models/trip_models.dart';
import 'package:x_pro_delivery_app/core/errors/exceptions.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/trip/data/datasource/remote_datasource/trip_remote_imp/trip_remote_base.dart';

mixin ScanTripByQRImpl on TripRemoteBase {
  Future<TripModel> scanTripByQR(String qrData) async {
    try {
      debugPrint('🔍 REMOTE: Scanning QR code data: $qrData');

      final records = await pocketBaseClient
          .collection('tripticket')
          .getFullList(
            filter: 'qrCode = "$qrData"',
            expand:
                'customers,customers.invoices,customers.deliveryStatus,'
                'deliveryTeam,deliveryTeam.personels,deliveryTeam.vehicle,'
                'personels,vehicle,checklist,'
                'returnList,completedCustomer,undeliverableCustomer,'
                'tripUpdates,endTripChecklist,'
                'deliveryData,deliveryData.customer,deliveryData.invoice,'
                'deliveryData.deliveryUpdates,deliveryData.deliveryReceipt,'
                'invoices,invoices.products,invoices.customer,'
                'transactions,transactions.customer,transactions.invoices,'
                'user,deliveryVehicle,'
                'otp,endTripOtp',
          );

      if (records.isEmpty) {
        throw ServerException(
          message: 'No trip found for QR code: $qrData',
          statusCode: '404',
        );
      }

      final record = records.first;

      // DEBUG: Print RAW record data BEFORE any mapping
      debugPrint('🔔🔔🔔 RAW POCKETBASE RECORD DEBUG 🔔🔔🔔');
      debugPrint('📌 record.id = ${record.id}');
      debugPrint('📌 record.id type = ${record.id.runtimeType}');
      debugPrint('📌 record.collectionId = ${record.collectionId}');
      debugPrint('📌 record.collectionName = ${record.collectionName}');
      debugPrint('📌 record.data keys = ${record.data.keys.toList()}');
      debugPrint(
        '📌 record.data[tripNumberId] = ${record.data['tripNumberId']}',
      );
      debugPrint(
        '📌 record.data[tripNumberId] type = ${record.data['tripNumberId'].runtimeType}',
      );
      debugPrint('📌 record.data[qrCode] = ${record.data['qrCode']}');
      debugPrint(
        '📌 record.data[qrCode] type = ${record.data['qrCode'].runtimeType}',
      );
      debugPrint('📌 record.data[name] = ${record.data['name']}');
      debugPrint('📌 record.data[id] = ${record.data['id']}');
      debugPrint('📌 Full record.data = ${record.data}');
      debugPrint('🔔🔔🔔 END RAW DEBUG 🔔🔔🔔');

      if (record.data['isAccepted'] == true ||
          record.data['isEndTrip'] == true) {
        throw const ServerException(
          message: 'Trip has already been accepted by another user',
          statusCode: '403',
        );
      }

      // Map record to TripModel using the helper
      debugPrint('🔔 Mapping record to TripModel using helper...');
      final trip = mapRecordToTripModel(record);

      // Debug top-level fields
      debugPrint('✅ Trip mapping completed:');
      debugPrint('   Trip ID: ${trip.id}');
      debugPrint('   Trip Number ID: ${trip.tripNumberId}');
      debugPrint('   QR Code: ${trip.qrCode}');
      debugPrint('   Delivery Data Count: ${trip.deliveryData.length}');
      debugPrint('   Personnel Count: ${trip.personels.length}');
      debugPrint('   Checklist Count: ${trip.checklist.length}');

      // Validate critical fields
      if (trip.id == null || trip.tripNumberId == null) {
        debugPrint('❌ Trip data invalid: Missing ID or tripNumberId');
        throw ServerException(
          message: 'Trip data invalid: Missing ID or tripNumberId',
          statusCode: '500',
        );
      }

      return trip;
    } catch (e, stackTrace) {
      debugPrint('❌ REMOTE: QR scan error: ${e.toString()}');
      debugPrint(stackTrace.toString());
      throw ServerException(
        message: 'Failed to scan QR code: ${e.toString()}',
        statusCode: '500',
      );
    }
  }
}
