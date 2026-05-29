import 'package:pocketbase/pocketbase.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/trip/data/models/trip_models.dart';
import 'package:x_pro_delivery_app/core/errors/exceptions.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/trip/data/datasource/remote_datasource/trip_remote_imp/trip_remote_base.dart';

mixin LoadTripImpl on TripRemoteBase {
  Future<TripModel> loadTrip() async {
    try {
      final records = await pocketBaseClient
          .collection('tripticket')
          .getList(expand: 'customers,personels,checklist,');

      // In the loadTrip method

      if (records.items.isEmpty) {
        throw const ServerException(
          message: 'No trip found',
          statusCode: '404',
        );
      }

      final record = records.items.first;
      final mappedData = {
        'id': record.id,
        ...record.data,
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
        'personels':
            (record.expand['personels'] as List?)
                ?.map((p) => p is RecordModel ? p.data : p)
                .toList() ??
            [],
        'checklist':
            (record.expand['checklist'] as List?)
                ?.map((c) => c is RecordModel ? c.data : c)
                .toList() ??
            [],
        'isAccepted': record.data['isAccepted'],
      };

      return TripModel.fromJson(mappedData);
    } catch (e) {
      throw ServerException(
        message: 'Failed to load trip: $e',
        statusCode: '500',
      );
    }
  }
}
