import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/cancelled_invoices/data/model/cancelled_invoice_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/cancelled_invoices/data/datasources/remote_datasource/cancelled_invoice_remote_impl/cancelled_invoice_remote_base.dart';
import 'package:x_pro_delivery_app/core/errors/exceptions.dart';

mixin LoadCancelledInvoicesByTripIdImpl on CancelledInvoiceRemoteBase {
  Future<List<CancelledInvoiceModel>> loadCancelledInvoicesByTripId(
    String tripId,
  ) async {
    try {
      // Extract trip ID if we received a JSON object
      String actualTripId;
      if (tripId.startsWith('{')) {
        final tripData = jsonDecode(tripId);
        actualTripId = tripData['id'];
      } else {
        actualTripId = tripId;
      }

      debugPrint('🔄 Loading cancelled invoices for trip: $actualTripId');

      // If actualTripId looks like a tripNumberId (starts with TRIP-),
      // we need to find the actual PocketBase record ID
      String pocketBaseTripId = actualTripId;

      if (actualTripId.startsWith('TRIP-')) {
        debugPrint(
          '🔍 Trip ID appears to be tripNumberId, finding PocketBase record ID...',
        );
        try {
          final tripResults = await pocketBaseClient
              .collection('tripticket')
              .getFullList(filter: 'id = "$actualTripId"');

          if (tripResults.isNotEmpty) {
            pocketBaseTripId = tripResults.first.id;
            debugPrint(
              '✅ Found PocketBase trip ID: $pocketBaseTripId for tripNumberId: $actualTripId',
            );
          } else {
            debugPrint('⚠️ No trip found with tripNumberId: $actualTripId');
          }
        } catch (e) {
          debugPrint('⚠️ Failed to resolve tripNumberId: $e');
        }
      }

      final records = await pocketBaseClient
          .collection('cancelledInvoice')
          .getFullList(
            filter: 'trip = "$pocketBaseTripId"',
            expand:
                'deliveryData,trip,invoice,invoices,invoices.products,invoices.customer,customer',
            sort: '-created',
          );

      debugPrint('✅ Retrieved ${records.length} cancelled invoices from API');

      List<CancelledInvoiceModel> cancelledInvoices = [];

      for (var record in records) {
        cancelledInvoices.add(processCancelledInvoiceRecord(record));
      }

      debugPrint(
        '✨ Successfully processed ${cancelledInvoices.length} cancelled invoices',
      );
      return cancelledInvoices;
    } catch (e) {
      debugPrint(
        '❌ Failed to load cancelled invoices by trip ID: ${e.toString()}',
      );
      throw ServerException(
        message: 'Failed to load cancelled invoices: ${e.toString()}',
        statusCode: '500',
      );
    }
  }
}
