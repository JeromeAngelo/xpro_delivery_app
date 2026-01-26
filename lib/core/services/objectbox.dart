
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:x_pro_delivery_app/core/common/app/features/delivery_data/customer_data/data/model/customer_data_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_data/invoice_data/data/model/invoice_data_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_team/delivery_team/data/models/delivery_team_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_data/delivery_update/data/models/delivery_update_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/otp/end_trip_otp/data/model/end_trip_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/otp/intransit_otp/data/models/otp_models.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/trip/data/models/trip_models.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/trip_updates/data/model/trip_update_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/checklists/end_trip_checklist/data/model/end_trip_checklist_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/delivery_data/data/model/delivery_data_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_data/delivery_receipt/data/model/delivery_receipt_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_data/delivery_receipt_items/data/model/delivery_receipt_items_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_team/delivery_vehicle_data/data/model/delivery_vehicle_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/users/user_performance/data/model/user_performance_model.dart';
import 'package:x_pro_delivery_app/objectbox.g.dart';
import 'package:x_pro_delivery_app/core/common/app/features/users/auth/data/models/auth_models.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_team/personels/data/models/personel_models.dart';
import 'package:x_pro_delivery_app/core/common/app/features/checklists/intransit_checklist/data/model/checklist_model.dart';

import '../common/app/features/delivery_data/invoice_items/data/model/invoice_items_model.dart';
import '../common/app/features/delivery_status_choices/data/model/delivery_status_choices_model.dart' show DeliveryStatusChoicesModel;
import '../common/app/features/trip_ticket/cancelled_invoices/data/model/cancelled_invoice_model.dart';
import '../common/app/features/trip_ticket/delivery_collection/data/model/collection_model.dart';
import '../common/app/features/trip_ticket/return_items/data/model/return_items_model.dart';

class ObjectBoxStore {
  static ObjectBoxStore? _instance;
  final Store store;

  ObjectBoxStore._create(this.store) {
    debugPrint('📦 ObjectBox Store initialized');
  }

  static Future<ObjectBoxStore> create() async {
    if (_instance != null) return _instance!;

    final docsDir = await getApplicationDocumentsDirectory();
    final dir = p.join(docsDir.path, "objectbox");

    try {
      final store = await openStore(directory: dir);
      _instance = ObjectBoxStore._create(store);
      debugPrint('🏗️ Created new ObjectBox instance');
      return _instance!;
    } on ObjectBoxException catch (e) {
      debugPrint('❌ ObjectBox openStore failed: $e');
      debugPrint('🧹 Deleting ObjectBox DB due to schema UID mismatch...');

      // delete database dir then retry
      await Directory(dir).delete(recursive: true);

      final store = await openStore(directory: dir);
      _instance = ObjectBoxStore._create(store);
      debugPrint('✅ ObjectBox recreated after cleanup');
      return _instance!;
    }
  }


  Box<LocalUsersModel> get userBox {
    debugPrint('📦 Accessing UserBox');
    return Box<LocalUsersModel>(store);
  }

   Box<UserPerformanceModel> get userPerformanceBox {
    debugPrint('📦 Accessing UserBox');
    return Box<UserPerformanceModel>(store);
  }

  Box<TripModel> get tripBox {
    debugPrint('📦 Accessing TripBox');
    return Box<TripModel>(store);
  }

 

  Box<DeliveryTeamModel> get deliveryTeamBox {
    debugPrint('📦 Accessing DeliveryTeamBox');
    return Box<DeliveryTeamModel>(store);
  }

  Box<DeliveryUpdateModel> get deliveryUpdateBox {
    debugPrint('📦 Accessing DeliveryUpdateBox');
    return Box<DeliveryUpdateModel>(store);
  }

   Box<DeliveryStatusChoicesModel> get deliveryStatusBox {
    debugPrint('📦 Accessing DeliveryUpdateBox');
    return Box<DeliveryStatusChoicesModel>(store);
  }



  Box<PersonelModel> get personelBox {
    debugPrint('📦 Accessing PersonelBox');
    return Box<PersonelModel>(store);
  }

  Box<ChecklistModel> get checklistBox {
    debugPrint('📦 Accessing ChecklistBox');
    return Box<ChecklistModel>(store);
  }



  Box<EndTripChecklistModel> get endTripChecklistBox {
    debugPrint('📦 Accessing EndTripChecklistBox');
    return Box<EndTripChecklistModel>(store);
  }


  Box<TripUpdateModel> get tripUpdatesBox {
    debugPrint('📦 Accessing TripUpdatesBox');
    return Box<TripUpdateModel>(store);
  }

  // New boxes for the added entities
  Box<DeliveryDataModel> get deliveryDataBox {
    debugPrint('📦 Accessing DeliveryDataBox');
    return Box<DeliveryDataModel>(store);
  }

  Box<CustomerDataModel> get customerBox {
    debugPrint('📦 Accessing DeliveryDataBox');
    return Box<CustomerDataModel>(store);
  }
   Box<CancelledInvoiceModel> get cancelledInvoiceBox {
    debugPrint('📦 Accessing CancelledInvoiceBox');
    return Box<CancelledInvoiceModel>(store);
  }

   Box<InvoiceDataModel> get invoiceBox {
    debugPrint('📦 Accessing DeliveryDataBox');
    return Box<InvoiceDataModel>(store);
  }
Box<InvoiceItemsModel> get invoiceItemsBox {
    debugPrint('📦 Accessing InvoiceItemsBox');
    return Box<InvoiceItemsModel>(store);
  }
 // New boxes for the added entities
  Box<OtpModel> get intransitOtpBox {
    debugPrint('📦 Accessing DeliveryDataBox');
    return Box<OtpModel>(store);
  }

   Box<EndTripOtpModel> get endTripOtpBox {
    debugPrint('📦 Accessing DeliveryDataBox');
    return Box<EndTripOtpModel>(store);
  }

  Box<DeliveryVehicleModel> get deliveryVehicleBox {
    debugPrint('📦 Accessing DeliveryVehicleBox');
    return Box<DeliveryVehicleModel>(store);
  }

  

Box<DeliveryReceiptModel> get deliveryReceiptBox {
    debugPrint('📦 Accessing DeliveryVehicleBox');
    return Box<DeliveryReceiptModel>(store);
  }
 

Box<DeliveryReceiptItemsModel> get deliveryReceiptItemsBox {
    debugPrint('📦 Accessing DeliveryVehicleBox');
    return Box<DeliveryReceiptItemsModel>(store);
  }

  Box<CollectionModel> get deliveryCollectonBox {
    debugPrint('📦 Accessing DeliveryVehicleBox');
    return Box<CollectionModel>(store);
  }


  Box<ReturnItemsModel> get returnItems {
    debugPrint('📦 Accessing DeliveryVehicleBox');
    return Box<ReturnItemsModel>(store);
  }
}
