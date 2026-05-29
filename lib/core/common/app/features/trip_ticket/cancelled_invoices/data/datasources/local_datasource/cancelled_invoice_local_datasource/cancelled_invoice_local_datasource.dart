import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/cancelled_invoices/data/model/cancelled_invoice_model.dart';
import 'package:x_pro_delivery_app/objectbox.g.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/cancelled_invoices/data/datasources/local_datasource/cancelled_invoice_local_impl/cancelled_invoice_local_base.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/cancelled_invoices/data/datasources/local_datasource/cancelled_invoice_local_impl/get_all_cancelled_invoices_impl.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/cancelled_invoices/data/datasources/local_datasource/cancelled_invoice_local_impl/force_load_cancelled_invoices_by_trip_id_impl.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/cancelled_invoices/data/datasources/local_datasource/cancelled_invoice_local_impl/load_cancelled_invoices_by_trip_id_impl.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/cancelled_invoices/data/datasources/local_datasource/cancelled_invoice_local_impl/load_cancelled_invoices_by_id_impl.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/cancelled_invoices/data/datasources/local_datasource/cancelled_invoice_local_impl/create_cancelled_invoice_impl.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/cancelled_invoices/data/datasources/local_datasource/cancelled_invoice_local_impl/delete_cancelled_invoice_impl.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/cancelled_invoices/data/datasources/local_datasource/cancelled_invoice_local_impl/cache_cancelled_invoices_impl.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/cancelled_invoices/data/datasources/local_datasource/cancelled_invoice_local_impl/update_cancelled_invoice_impl.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/cancelled_invoices/data/datasources/local_datasource/cancelled_invoice_local_impl/get_pending_sync_list_impl.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/cancelled_invoices/data/datasources/local_datasource/cancelled_invoice_local_impl/mark_failed_impl.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/cancelled_invoices/data/datasources/local_datasource/cancelled_invoice_local_impl/mark_synced_impl.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/cancelled_invoices/data/datasources/local_datasource/cancelled_invoice_local_impl/mark_syncing_impl.dart';

abstract class CancelledInvoiceLocalDataSource {
  /// 🆕 Background sync helper methods
  Future<void> markSyncing(CancelledInvoiceModel cancelledInvoice);
  Future<void> markSynced(CancelledInvoiceModel cancelledInvoice);
  Future<void> markFailed(CancelledInvoiceModel cancelledInvoice, String error);
  Future<List<CancelledInvoiceModel>> getPendingSyncList();
  // Get all cancelled invoices
  Future<List<CancelledInvoiceModel>> getAllCancelledInvoices();

  /// Load cancelled invoices by trip ID from local storage
  Future<List<CancelledInvoiceModel>> loadCancelledInvoicesByTripId(
    String tripId,
  );
  Future<List<CancelledInvoiceModel>> forceLoadCancelledInvoicesByTripId(
    String tripId,
  );

  /// Load cancelled invoice by ID from local storage (returns single item)
  Future<CancelledInvoiceModel> loadCancelledInvoicesById(String id);

  /// Create cancelled invoice by delivery data ID in local storage
  Future<CancelledInvoiceModel> createCancelledInvoice(
    CancelledInvoiceModel cancelledInvoice,
    String deliveryDataId,
  );

  /// Delete cancelled invoice from local storage
  Future<bool> deleteCancelledInvoice(String cancelledInvoiceId);

  /// Cache cancelled invoices to local storage
  Future<void> cacheCancelledInvoices(
    List<CancelledInvoiceModel> cancelledInvoices,
  );
  Box<CancelledInvoiceModel> get cancelledInvoiceBox;

  /// Update cancelled invoice in local storage
  Future<void> updateCancelledInvoice(CancelledInvoiceModel cancelledInvoice);
}

class CancelledInvoiceLocalDataSourceImpl extends CancelledInvoiceLocalBase
    with
        GetAllCancelledInvoicesImpl,
        ForceLoadCancelledInvoicesByTripIdImpl,
        LoadCancelledInvoicesByTripIdImpl,
        LoadCancelledInvoicesByIdImpl,
        CreateCancelledInvoiceImpl,
        DeleteCancelledInvoiceImpl,
        CacheCancelledInvoicesImpl,
        UpdateCancelledInvoiceImpl,
        GetPendingSyncListImpl,
        MarkFailedImpl,
        MarkSyncedImpl,
        MarkSyncingImpl
    implements CancelledInvoiceLocalDataSource {
  CancelledInvoiceLocalDataSourceImpl(super.objectBoxStore);
}

