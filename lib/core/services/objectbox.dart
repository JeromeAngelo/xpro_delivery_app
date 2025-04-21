import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:x_pro_delivery_app/core/common/app/features/Delivery_Team/delivery_team/data/models/delivery_team_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/completed_customer/data/models/completed_customer_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/delivery_update/data/models/delivery_update_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/invoice/data/models/invoice_models.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/products/data/model/product_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/return_product/data/model/return_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/transaction/data/model/transaction_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/trip/data/models/trip_models.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/trip_updates/data/model/trip_update_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/undeliverable_customer/data/model/undeliverable_customer_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/end_trip_checklist/data/model/end_trip_checklist_model.dart';
import 'package:x_pro_delivery_app/objectbox.g.dart';
import 'package:x_pro_delivery_app/src/auth/data/models/auth_models.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/customer/data/model/customer_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/update_timeline/data/models/update_timeline_models.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Delivery_Team/personels/data/models/personel_models.dart';
import 'package:x_pro_delivery_app/core/common/app/features/checklist/data/model/checklist_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Delivery_Team/vehicle/data/model/vehicle_model.dart';
class ObjectBoxStore {
  static ObjectBoxStore? _instance;
  final Store store;

  ObjectBoxStore._create(this.store) {
    debugPrint('📦 ObjectBox Store initialized');
  }

  static Future<ObjectBoxStore> create() async {
    if (_instance == null) {
      final docsDir = await getApplicationDocumentsDirectory();
      final store = await openStore(
        directory: p.join(docsDir.path, "objectbox"),
      );
      _instance = ObjectBoxStore._create(store);
      debugPrint('🏗️ Created new ObjectBox instance');
    }
    return _instance!;
  }

  Box<LocalUsersModel> get userBox {
    debugPrint('📦 Accessing UserBox');
    return Box<LocalUsersModel>(store);
  }

  Box<TripModel> get tripBox {
    debugPrint('📦 Accessing TripBox');
    return Box<TripModel>(store);
  }

  Box<CustomerModel> get customerBox {
    debugPrint('📦 Accessing CustomerBox');
    return Box<CustomerModel>(store);
  }

  Box<UpdateTimelineModel> get timelineBox {
    debugPrint('📦 Accessing TimelineBox');
    return Box<UpdateTimelineModel>(store);
  }

  Box<DeliveryTeamModel> get deliveryTeamBox {
    debugPrint('📦 Accessing DeliveryTeamBox');
    return Box<DeliveryTeamModel>(store);
  }

  Box<DeliveryUpdateModel> get deliveryUpdateBox {
    debugPrint('📦 Accessing DeliveryUpdateBox');
    return Box<DeliveryUpdateModel>(store);
  }

  Box<InvoiceModel> get invoiceBox {
    debugPrint('📦 Accessing InvoiceBox');
    return Box<InvoiceModel>(store);
  }

  Box<ProductModel> get productBox {
    debugPrint('📦 Accessing ProductBox');
    return Box<ProductModel>(store);
  }

  Box<PersonelModel> get personelBox {
    debugPrint('📦 Accessing PersonelBox');
    return Box<PersonelModel>(store);
  }

  Box<ChecklistModel> get checklistBox {
    debugPrint('📦 Accessing ChecklistBox');
    return Box<ChecklistModel>(store);
  }

  Box<VehicleModel> get vehicleBox {
    debugPrint('📦 Accessing VehicleBox');
    return Box<VehicleModel>(store);
  }

  Box<CompletedCustomerModel> get completedCustomerBox {
    debugPrint('📦 Accessing CompletedCustomerBox');
    return Box<CompletedCustomerModel>(store);
  }

  Box<TransactionModel> get transactionBox {
    debugPrint('📦 Accessing TransactionBox');
    return Box<TransactionModel>(store);
  }

  Box<ReturnModel> get returnBox {
    debugPrint('📦 Accessing ReturnBox');
    return Box<ReturnModel>(store);
  }

  Box<EndTripChecklistModel> get endTripChecklistBox {
    debugPrint('📦 Accessing EndTripChecklistBox');
    return Box<EndTripChecklistModel>(store);
  }

  Box<UndeliverableCustomerModel> get undeliverableCustomerBox {
    debugPrint('📦 Accessing UndeliverableCustomerBox');
    return Box<UndeliverableCustomerModel>(store);
  }

  Box<TripUpdateModel> get tripUpdatesBox {
    debugPrint('📦 Accessing TripUpdatesBox');
    return Box<TripUpdateModel>(store);
  }
}
