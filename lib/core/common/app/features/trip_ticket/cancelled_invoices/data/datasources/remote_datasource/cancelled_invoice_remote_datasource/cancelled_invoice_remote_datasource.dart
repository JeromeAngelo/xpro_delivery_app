import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/cancelled_invoices/data/model/cancelled_invoice_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/cancelled_invoices/data/datasources/remote_datasource/cancelled_invoice_remote_impl/cancelled_invoice_remote_base.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/cancelled_invoices/data/datasources/remote_datasource/cancelled_invoice_remote_impl/get_all_cancelled_invoices_impl.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/cancelled_invoices/data/datasources/remote_datasource/cancelled_invoice_remote_impl/load_cancelled_invoices_by_trip_id_impl.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/cancelled_invoices/data/datasources/remote_datasource/cancelled_invoice_remote_impl/load_cancelled_invoice_by_id_impl.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/cancelled_invoices/data/datasources/remote_datasource/cancelled_invoice_remote_impl/create_cancelled_invoice_impl.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/cancelled_invoices/data/datasources/remote_datasource/cancelled_invoice_remote_impl/delete_cancelled_invoice_impl.dart';

abstract class CancelledInvoiceRemoteDataSource {
  /// Get all cancelled invoices
  Future<List<CancelledInvoiceModel>> getAllCancelledInvoices();

  /// Load cancelled invoices by trip ID
  Future<List<CancelledInvoiceModel>> loadCancelledInvoicesByTripId(
    String tripId,
  );

  /// Load cancelled invoice by ID
  Future<CancelledInvoiceModel> loadCancelledInvoiceById(String id);

  /// Create cancelled invoice
  Future<CancelledInvoiceModel> createCancelledInvoice(
    CancelledInvoiceModel cancelledInvoice,
    String deliveryDataId,
  );

  /// Delete cancelled invoice
  Future<bool> deleteCancelledInvoice(String cancelledInvoiceId);
}

class CancelledInvoiceRemoteDataSourceImpl extends CancelledInvoiceRemoteBase
    with
        GetAllCancelledInvoicesImpl,
        LoadCancelledInvoicesByTripIdImpl,
        LoadCancelledInvoiceByIdImpl,
        CreateCancelledInvoiceImpl,
        DeleteCancelledInvoiceImpl
    implements CancelledInvoiceRemoteDataSource {
  const CancelledInvoiceRemoteDataSourceImpl({required super.pocketBaseClient});
}
