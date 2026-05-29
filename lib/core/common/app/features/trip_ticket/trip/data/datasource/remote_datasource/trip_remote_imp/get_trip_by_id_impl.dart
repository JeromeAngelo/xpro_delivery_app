import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/trip/data/models/trip_models.dart';
import 'package:x_pro_delivery_app/core/errors/exceptions.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/trip/data/datasource/remote_datasource/trip_remote_imp/trip_remote_base.dart';

mixin GetTripByIdImpl on TripRemoteBase {
  Future<TripModel> getTripById(String id) async {
    try {
      debugPrint('🔄 Fetching trip by ID: $id');
      final record = await pocketBaseClient
          .collection('tripticket')
          .getOne(
            id,
            expand:
                'customers,customers.deliveryUpdates,customers.invoices(customer),customers.invoices.productList,personels,vehicle,checklist,invoices,invoices.productList,deliveryTeam,deliveryData,deliveryVehicle',
          );

      final mappedData = {
        'id': record.id,
        'collectionId': record.collectionId,
        'collectionName': record.collectionName,
        ...record.data,
        'deliveryData':
            (record.expand['deliveryData'] as List?)?.map((c) {
              final customerData = c as RecordModel;
              final deliveryStatus =
                  customerData.expand['deliveryStatus'] as List? ?? [];

              return {
                ...customerData.data,
                'id': customerData.id,
                'deliveryUpdates':
                    deliveryStatus.map((status) => status.data).toList(),
              };
            }).toList() ??
            [],
        'customers':
            (record.expand['customers'] as List?)?.map((c) {
              final customerData = c as RecordModel;
              final deliveryStatus =
                  customerData.expand['deliveryUpdates'] as List? ?? [];
              final invoices = customerData.expand['invoices'] as List? ?? [];

              return {
                ...customerData.data,
                'id': customerData.id,
                'deliveryUpdates':
                    deliveryStatus.map((status) => status.data).toList(),
                'invoices':
                    invoices.map((invoice) {
                      final products =
                          invoice.expand['productList'] as List? ?? [];
                      return {
                        ...invoice.data,
                        'id': invoice.id,
                        'productList':
                            products.map((product) => product.data).toList(),
                      };
                    }).toList(),
              };
            }).toList() ??
            [],
        'invoices':
            (record.expand['invoices'] as List?)?.map((invoice) {
              final invoiceData = invoice as RecordModel;
              return {
                ...invoiceData.data,
                'id': invoiceData.id,
                'productList':
                    invoiceData.expand['productList']
                        ?.map((product) => product.data)
                        .toList() ??
                    [],
              };
            }).toList() ??
            [],
        'trip_update_list': mapTripUpdates(record),
        'personels': mapPersonels(record),
        'checklist': mapChecklist(record),
        'isAccepted': record.data['isAccepted'],
        'deliveryVehicle': record.data['deliveryVehicle'],
        'timeAccepted': record.data['timeAccepted'],
        'name': record.data['name'],
        'deliveryDate': record.data['deliveryDate'],
        'longitude': record.data['longitude'],
        'latitude': record.data['latitude'],
      };

      debugPrint('✅ Trip data retrieved successfully');
      return TripModel.fromJson(mappedData);
    } catch (e) {
      debugPrint('❌ Error fetching trip: $e');
      throw ServerException(
        message: 'Failed to fetch trip: $e',
        statusCode: '500',
      );
    }
  }
}
