import 'package:flutter/material.dart';
import 'package:objectbox/objectbox.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Delivery_Team/delivery_team/data/models/delivery_team_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/completed_customer/data/models/completed_customer_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/invoice/data/models/invoice_models.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/return_product/data/model/return_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/transaction/data/model/transaction_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/trip/domain/entity/trip_entity.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/customer/data/model/customer_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/trip_updates/data/model/trip_update_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/undeliverable_customer/data/model/undeliverable_customer_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/update_timeline/data/models/update_timeline_models.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Delivery_Team/vehicle/data/model/vehicle_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Delivery_Team/personels/data/models/personel_models.dart';
import 'package:x_pro_delivery_app/core/common/app/features/checklist/data/model/checklist_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/end_trip_checklist/data/model/end_trip_checklist_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/end_trip_otp/data/model/end_trip_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/otp/data/models/otp_models.dart';
import 'package:x_pro_delivery_app/core/enums/mode_of_payment.dart';
import 'package:x_pro_delivery_app/core/enums/transaction_status.dart';
import 'package:x_pro_delivery_app/core/utils/typedefs.dart';
import 'package:x_pro_delivery_app/src/auth/data/models/auth_models.dart';

@Entity()
class TripModel extends TripEntity {
  @Id(assignable: true)
  int objectBoxId = 0;

  @Property()
  String? pocketbaseId;

  TripModel({
    super.id,
    super.collectionId,
    super.collectionName,
    super.tripNumberId,
    List<CustomerModel>? customersList,
    UpdateTimelineModel? timelineModel,
    List<PersonelModel>? personelsList,
    List<ChecklistModel>? checklistItems,
    List<VehicleModel>? vehicleList,
    List<CompletedCustomerModel>? completedCustomersList,
    List<ReturnModel>? returnsList,
    List<UndeliverableCustomerModel>? undeliverableCustomersList,
    List<TransactionModel>? transactionsList,
    List<EndTripChecklistModel>? endTripChecklistItems,
    List<DeliveryTeamModel>? deliveryTeamList,
    List<TripUpdateModel>? tripUpdateList,
    List<InvoiceModel>? invoicesList,
    super.user,
    super.totalTripDistance,
    super.otp,
     super.latitude,  // Added to constructor
    super.longitude, // Added to constructor
    super.endTripOtp,
    super.deliveryTeam,
    super.timeAccepted,
    super.isEndTrip,
    super.timeEndTrip,
    super.created,
    super.updated,
    super.qrCode,
    super.isAccepted,
    this.objectBoxId = 0,
  }) : super(
          tripUpdates: tripUpdateList,
          customers: customersList,
          invoices: invoicesList,
          timeline: timelineModel,
          personels: personelsList,
          checklist: checklistItems,
          vehicle: vehicleList,
          completedCustomers: completedCustomersList,
          returns: returnsList,
          undeliverableCustomers: undeliverableCustomersList,
          transactions: transactionsList,
          endTripChecklist: endTripChecklistItems,
        );

  factory TripModel.fromJson(dynamic json) {
    debugPrint('🔄 MODEL: Creating TripModel from JSON');

    if (json is String) {
      debugPrint('⚠️ MODEL: JSON is String - $json');
      return TripModel(id: json);
    }

    final expandedData = json['expand'] as Map<String, dynamic>?;

    // Handle Customers
    final customersData = expandedData?['customers'] ?? json['customers'];
    List<CustomerModel> customersList = [];
    if (customersData != null) {
      if (customersData is List) {
        customersList = customersData.map((customer) {
          if (customer is String) {
            return CustomerModel(id: customer);
          }
          return CustomerModel.fromJson(customer);
        }).toList();
      } else if (customersData is Map<String, dynamic>) {
        customersList = [CustomerModel.fromJson(customersData)];
      }
    }

    // Handle delivery team data
    final deliveryTeamData = expandedData?['deliveryTeam'];
    DeliveryTeamModel? deliveryTeamModel;
    if (deliveryTeamData != null) {
      if (deliveryTeamData is RecordModel) {
        deliveryTeamModel = DeliveryTeamModel.fromJson({
          'id': deliveryTeamData.id,
          'collectionId': deliveryTeamData.collectionId,
          'collectionName': deliveryTeamData.collectionName,
          ...deliveryTeamData.data,
        });
      } else if (deliveryTeamData is Map) {
        deliveryTeamModel = DeliveryTeamModel.fromJson(
            deliveryTeamData as Map<String, dynamic>);
      }
    }

    final userData = expandedData?['user'];
    LocalUsersModel? usersModel;
    if (userData != null) {
      if (userData is RecordModel) {
        usersModel = LocalUsersModel.fromJson({
          'id': userData.id,
          'collectionId': userData.collectionId,
          'collectionName': userData.collectionName,
          ...userData.data
        });
      } else if (userData is Map) {
        usersModel = LocalUsersModel.fromJson(userData as DataMap);
      }
    }

    // Handle Personels
    final personelsData = expandedData?['personels'] ?? json['personels'];
    List<PersonelModel> personelsList = [];
    if (personelsData != null) {
      if (personelsData is List) {
        personelsList = personelsData.map((personel) {
          if (personel is String) {
            return PersonelModel(id: personel);
          }
          return PersonelModel.fromJson(personel);
        }).toList();
      } else if (personelsData is Map<String, dynamic>) {
        personelsList = [PersonelModel.fromJson(personelsData)];
      }
    }

    // Handle Vehicle
    final vehicleData = expandedData?['vehicle'] ?? json['vehicle'];
    List<VehicleModel> vehicleList = [];
    if (vehicleData != null) {
      if (vehicleData is List) {
        vehicleList = vehicleData.map((vehicle) {
          if (vehicle is String) {
            return VehicleModel(id: vehicle);
          }
          return VehicleModel.fromJson(vehicle);
        }).toList();
      } else if (vehicleData is Map<String, dynamic>) {
        vehicleList = [VehicleModel.fromJson(vehicleData)];
      }
    }

    // Handle Checklist
    final checklistData = expandedData?['checklist'] ?? json['checklist'];
    List<ChecklistModel> checklistItems = [];
    if (checklistData != null) {
      if (checklistData is List) {
        checklistItems = checklistData.map((item) {
          if (item is String) {
            return ChecklistModel(id: item);
          }
          return ChecklistModel.fromJson(item);
        }).toList();
      } else if (checklistData is Map<String, dynamic>) {
        checklistItems = [ChecklistModel.fromJson(checklistData)];
      }
    }

    // Handle CompletedCustomers
    final completedCustomersData =
        expandedData?['completedCustomers'] ?? json['completedCustomers'];
    List<CompletedCustomerModel> completedCustomersList = [];
    if (completedCustomersData != null) {
      if (completedCustomersData is List) {
        completedCustomersList = completedCustomersData.map((customer) {
          if (customer is String) {
            return CompletedCustomerModel(id: customer);
          }
          return CompletedCustomerModel.fromJson(customer);
        }).toList();
      } else if (completedCustomersData is Map<String, dynamic>) {
        completedCustomersList = [
          CompletedCustomerModel.fromJson(completedCustomersData)
        ];
      }
    }

    // Handle Returns
    final returnsData = expandedData?['returns'] ?? json['returns'];
    List<ReturnModel> returnsList = [];
    if (returnsData != null) {
      if (returnsData is List) {
        returnsList = returnsData.map((returnItem) {
          if (returnItem is String) {
            return ReturnModel(id: returnItem);
          }
          return ReturnModel.fromJson(returnItem);
        }).toList();
      } else if (returnsData is Map<String, dynamic>) {
        returnsList = [ReturnModel.fromJson(returnsData)];
      }
    }

    // Handle UndeliverableCustomers
    final undeliverableData = expandedData?['undeliverableCustomers'] ??
        json['undeliverableCustomers'];
    List<UndeliverableCustomerModel> undeliverableList = [];
    if (undeliverableData != null) {
      if (undeliverableData is List) {
        undeliverableList = undeliverableData.map((customer) {
          if (customer is String) {
            return UndeliverableCustomerModel(id: customer);
          }
          return UndeliverableCustomerModel.fromJson(customer);
        }).toList();
      } else if (undeliverableData is Map<String, dynamic>) {
        undeliverableList = [
          UndeliverableCustomerModel.fromJson(undeliverableData)
        ];
      }
    }

    // Handle Transactions
    final transactionsData =
        expandedData?['transactions'] ?? json['transactions'];
    List<TransactionModel> transactionsList = [];
    if (transactionsData != null) {
      if (transactionsData is List) {
        transactionsList = transactionsData.map((transaction) {
          if (transaction is String) {
            return TransactionModel(
                id: transaction,
                customerModel: null,
                customerName: '',
                totalAmount: '',
                deliveryNumber: '',
                collectionId: '',
                collectionName: '',
                refNumber: '',
                signature: null,
                customerImage: '',
                invoices: const [],
                transactionDate: null,
                transactionStatus: TransactionStatus.pending,
                createdAt: null,
                updatedAt: null,
                modeOfPayment: ModeOfPayment.cashOnDelivery,
                isCompleted: null,
                pdf: null,
                trip: null);
          }
          return TransactionModel.fromJson(transaction);
        }).toList();
      } else if (transactionsData is Map<String, dynamic>) {
        transactionsList = [TransactionModel.fromJson(transactionsData)];
      }
    }

    // Handle EndTripChecklist
    final endTripData =
        expandedData?['endTripChecklist'] ?? json['endTripChecklist'];
    List<EndTripChecklistModel> endTripList = [];
    if (endTripData != null) {
      if (endTripData is List) {
        endTripList = endTripData.map((item) {
          if (item is String) {
            return EndTripChecklistModel(id: item);
          }
          return EndTripChecklistModel.fromJson(item);
        }).toList();
      } else if (endTripData is Map<String, dynamic>) {
        endTripList = [EndTripChecklistModel.fromJson(endTripData)];
      }
    }

    final tripUpdatesData = expandedData?['tripUpdates'] as List?;
    List<TripUpdateModel> tripUpdatesList = [];
    if (tripUpdatesData != null) {
      tripUpdatesList = tripUpdatesData.map((update) {
        if (update is String) {
          return TripUpdateModel(id: update);
        }
        return TripUpdateModel.fromJson(update);
      }).toList();
    }

    return TripModel(
      id: json['id']?.toString(),
      collectionId: json['collectionId']?.toString(),
      collectionName: json['collectionName']?.toString(),
      tripNumberId: json['tripNumberId']?.toString(),
      qrCode: json['qrCode']?.toString(),
      customersList: customersList,
      deliveryTeam: deliveryTeamModel,
      user: usersModel,
      totalTripDistance: json['totalTripDistance']?.toString(),
       latitude: json['latitude'] != null ? double.tryParse(json['latitude'].toString()) : null,  // Parse latitude
      longitude: json['longitude'] != null ? double.tryParse(json['longitude'].toString()) : null, // Parse longitude
      personelsList: personelsList,
      vehicleList: vehicleList,
      checklistItems: checklistItems,
      completedCustomersList: completedCustomersList,
      returnsList: returnsList,
      undeliverableCustomersList: undeliverableList,
      transactionsList: transactionsList,
      endTripChecklistItems: endTripList,
      tripUpdateList: tripUpdatesList,
      timeAccepted: null,
      isEndTrip: json['isEndTrip'] as bool? ?? false,
      timeEndTrip: null,
      created: null,
      updated: null,
      isAccepted: json['isAccepted'] as bool? ?? false,
    );
  }

  DataMap toJson() {
    return {
      'id': id,
      'collectionId': collectionId,
      'collectionName': collectionName,
      'tripNumberId': tripNumberId,
      'qrCode': qrCode,
      'customers': customers.map((c) => c.toJson()).toList(),
      'checklist': checklist.map((c) => c.toJson()).toList(),
      'timeline': timeline.target?.toJson(),
      'deliveryTeam': deliveryTeam.target?.toJson(),
      'user': user.target?.toJson(),
      'personels': personels.map((p) => p.toJson()).toList(),
      'invoices': invoices.map((i) => i.toJson()).toList(),
      'vehicle': vehicle.map((v) => v.toJson()).toList(),
      'completedCustomers': completedCustomers.map((c) => c.toJson()).toList(),
      'returns': returns.map((r) => r.toJson()).toList(),
      'undeliverableCustomers':
          undeliverableCustomers.map((u) => u.toJson()).toList(),
      'transactions': transactions.map((t) => t.toJson()).toList(),
      'endTripChecklist': endTripChecklist.map((e) => e.toJson()).toList(),
      'created': created?.toIso8601String(),
      'updated': updated?.toIso8601String(),
      'timeAccepted': timeAccepted?.toIso8601String(),
      'totalTripDistance': totalTripDistance,
       'latitude': latitude?.toString(),  // Added latitude to JSON
      'longitude': longitude?.toString(), // Added longitude to JSON
      'isEndTrip': isEndTrip,
      'timeEndTrip': timeEndTrip?.toIso8601String(),
      'isAccepted': isAccepted,
      'otp': otp.target?.toJson(),
      'endTripOtp': endTripOtp.target?.toJson(),
    };
  }

  TripModel copyWith({
    String? id,
    String? collectionId,
    String? collectionName,
    String? tripNumberId,
    String? totalTripDistance,
    double? latitude,  // Added to copyWith
    double? longitude, // Added to copyWith
    String? qrCode,
    List<InvoiceModel>? invoicesList,
    List<CustomerModel>? customersList,
    UpdateTimelineModel? timelineModel,
    List<PersonelModel>? personelsList,
    List<ChecklistModel>? checklistItems,
    List<VehicleModel>? vehicleList,
    List<CompletedCustomerModel>? completedCustomersList,
    List<ReturnModel>? returnsList,
    List<UndeliverableCustomerModel>? undeliverableCustomersList,
    List<TransactionModel>? transactionsList,
    List<EndTripChecklistModel>? endTripChecklistItems,
    List<TripUpdateModel>? tripUpdateList,
    LocalUsersModel? user,
    OtpModel? otp,
    EndTripOtpModel? endTripOtp,
    bool? isEndTrip,
    DateTime? timeEndTrip,
    DateTime? created,
    DateTime? updated,
    DateTime? timeAccepted,
    bool? isAccepted,
  }) {
    return TripModel(
      id: id ?? this.id,
      totalTripDistance: totalTripDistance ?? this.totalTripDistance,
      collectionId: collectionId ?? this.collectionId,
      collectionName: collectionName ?? this.collectionName,
      tripNumberId: tripNumberId ?? this.tripNumberId,
      qrCode: qrCode ?? this.qrCode,
      customersList: customersList ?? customers.toList(),
      timelineModel: timelineModel ?? timeline.target,
      personelsList: personelsList ?? personels.toList(),
      checklistItems: checklistItems ?? checklist.toList(),
      vehicleList: vehicleList ?? vehicle.toList(),
      completedCustomersList:
          completedCustomersList ?? completedCustomers.toList(),
      returnsList: returnsList ?? returns.toList(),
      undeliverableCustomersList:
          undeliverableCustomersList ?? undeliverableCustomers.toList(),
      transactionsList: transactionsList ?? transactions.toList(),
      endTripChecklistItems: endTripChecklistItems ?? endTripChecklist.toList(),
      invoicesList: invoicesList ?? invoices.toList(),
      timeAccepted: timeAccepted ?? this.timeAccepted,
      created: created ?? this.created,
      updated: updated ?? this.updated,
      isAccepted: isAccepted ?? this.isAccepted,
      user: user ?? this.user.target,
      otp: otp ?? this.otp.target,
      endTripOtp: endTripOtp ?? this.endTripOtp.target,
      isEndTrip: isEndTrip ?? this.isEndTrip,
      timeEndTrip: timeEndTrip ?? this.timeEndTrip,
    );
  }
}
