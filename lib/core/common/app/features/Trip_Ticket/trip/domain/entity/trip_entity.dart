import 'package:equatable/equatable.dart';
import 'package:objectbox/objectbox.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Delivery_Team/delivery_team/data/models/delivery_team_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Delivery_Team/personels/data/models/personel_models.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Delivery_Team/vehicle/data/model/vehicle_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/completed_customer/data/models/completed_customer_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/customer/data/model/customer_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/invoice/data/models/invoice_models.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/return_product/data/model/return_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/transaction/data/model/transaction_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/trip_updates/data/model/trip_update_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/undeliverable_customer/data/model/undeliverable_customer_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/update_timeline/data/models/update_timeline_models.dart';
import 'package:x_pro_delivery_app/core/common/app/features/checklist/data/model/checklist_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/end_trip_checklist/data/model/end_trip_checklist_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/end_trip_otp/data/model/end_trip_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/otp/data/models/otp_models.dart';
import 'package:x_pro_delivery_app/src/auth/data/models/auth_models.dart';

@Entity()
class TripEntity extends Equatable {
  @Id()
  int dbId = 0;

  String? id;
  String? collectionId;
  String? collectionName;
  String? tripNumberId;
  final ToMany<CustomerModel> customers = ToMany<CustomerModel>();
  final ToOne<UpdateTimelineModel> timeline = ToOne<UpdateTimelineModel>();
  final ToOne<DeliveryTeamModel> deliveryTeam = ToOne<DeliveryTeamModel>();
  final ToMany<PersonelModel> personels = ToMany<PersonelModel>();
  final ToMany<ChecklistModel> checklist = ToMany<ChecklistModel>();
  final ToMany<VehicleModel> vehicle = ToMany<VehicleModel>();
  final ToMany<CompletedCustomerModel> completedCustomers =
      ToMany<CompletedCustomerModel>();
  final ToMany<ReturnModel> returns = ToMany<ReturnModel>();
  final ToMany<UndeliverableCustomerModel> undeliverableCustomers =
      ToMany<UndeliverableCustomerModel>();
  final ToMany<TransactionModel> transactions = ToMany<TransactionModel>();
  final ToMany<EndTripChecklistModel> endTripChecklist =
      ToMany<EndTripChecklistModel>();
  final ToMany<TripUpdateModel> tripUpdates = ToMany<TripUpdateModel>();
  final ToOne<OtpModel> otp = ToOne<OtpModel>();
  final ToOne<EndTripOtpModel> endTripOtp = ToOne<EndTripOtpModel>();
  final ToOne<LocalUsersModel> user = ToOne<LocalUsersModel>();
 double? latitude;  // Added latitude field
  double? longitude; // Added longitude field
  String? totalTripDistance;
  bool? isAccepted;
  bool? isEndTrip;
  DateTime? timeEndTrip;
  DateTime? timeAccepted;
  DateTime? created;
  DateTime? updated;
  String? qrCode;
  final ToMany<InvoiceModel> invoices = ToMany<InvoiceModel>();
  TripEntity({
    this.id,
    this.collectionId,
    this.collectionName,
    this.tripNumberId,
    List<CustomerModel>? customers,
    UpdateTimelineModel? timeline,
    DeliveryTeamModel? deliveryTeam,
    List<PersonelModel>? personels,
    List<ChecklistModel>? checklist,
    List<TripUpdateModel>? tripUpdates,
    List<VehicleModel>? vehicle,
    List<CompletedCustomerModel>? completedCustomers,
    List<ReturnModel>? returns,
    List<UndeliverableCustomerModel>? undeliverableCustomers,
    List<TransactionModel>? transactions,
    List<EndTripChecklistModel>? endTripChecklist,
    OtpModel? otp,
    List<InvoiceModel>? invoices,
    EndTripOtpModel? endTripOtp,
    LocalUsersModel? user,
    this.latitude,  // Added to constructor
    this.longitude, // Added to constructor
    this.totalTripDistance,
    this.timeEndTrip,
    this.isEndTrip,
    this.timeAccepted,
    this.isAccepted,
    this.qrCode,
    this.created,
    this.updated,
  }) {
    if (customers != null) this.customers.addAll(customers);
    if (timeline != null) this.timeline.target = timeline;
    if (invoices != null) this.invoices.addAll(invoices);
    if (deliveryTeam != null) this.deliveryTeam.target = deliveryTeam;
    if (personels != null) this.personels.addAll(personels);
    if (checklist != null) this.checklist.addAll(checklist);
    if (vehicle != null) this.vehicle.addAll(vehicle);
    if (user != null) this.user.target = user;
    if (completedCustomers != null) {
      this.completedCustomers.addAll(completedCustomers);
    }
    if (returns != null) this.returns.addAll(returns);
    if (undeliverableCustomers != null) {
      this.undeliverableCustomers.addAll(undeliverableCustomers);
    }
    if (transactions != null) this.transactions.addAll(transactions);
    if (endTripChecklist != null) {
      this.endTripChecklist.addAll(endTripChecklist);
    }
    if (tripUpdates != null) this.tripUpdates.addAll(tripUpdates);
    if (otp != null) this.otp.target = otp;
    if (endTripOtp != null) this.endTripOtp.target = endTripOtp;
  }

  @override
  List<Object?> get props => [
        id,
        tripNumberId,
        customers,
        timeline.target?.id,
        deliveryTeam.target?.id,
        user.target?.id,
        totalTripDistance,
        invoices,
        personels,
        vehicle,
        checklist,
        completedCustomers,
        returns,
        undeliverableCustomers,
        transactions,
        endTripChecklist,
        tripUpdates,
        timeAccepted,
        otp.target?.id,
        endTripOtp.target?.id,
        timeEndTrip,
        isEndTrip,
        qrCode,
        isAccepted,
        created,
        updated,
        latitude,  // Added to props
        longitude, // Added to props
      ];
}
