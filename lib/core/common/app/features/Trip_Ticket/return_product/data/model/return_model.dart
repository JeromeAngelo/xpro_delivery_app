import 'package:objectbox/objectbox.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/customer/data/model/customer_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/invoice/data/models/invoice_models.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/return_product/domain/entity/return_entity.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/trip/data/models/trip_models.dart';
import 'package:x_pro_delivery_app/core/enums/product_return_reason.dart';
import 'package:x_pro_delivery_app/core/utils/typedefs.dart';
@Entity()
class ReturnModel extends ReturnEntity {
  @Id()
  int objectBoxId = 0;

  @Property()
  String pocketbaseId;

   @Property()
  String? tripId;

  ReturnModel({
    super.id,
    super.collectionId,
    super.collectionName,
    super.productName,
    super.productDescription,
    super.reason,
    super.returnDate,
    super.productQuantityCase,
    super.productQuantityPcs,
    super.productQuantityPack,
    super.productQuantityBox,
    super.isCase,
    super.isPcs,
    super.isBox,
    super.isPack,
    super.invoice,
    super.customer,
    super.trip,
  }) : pocketbaseId = id ?? '';

  factory ReturnModel.fromJson(DataMap json) {
    final expandedData = json['expand'] as Map<String, dynamic>?;

    final invoice = expandedData?['invoice'] != null
        ? InvoiceModel.fromJson(expandedData!['invoice'] is RecordModel
            ? {
                'id': expandedData['invoice'].id,
                'collectionId': expandedData['invoice'].collectionId,
                'collectionName': expandedData['invoice'].collectionName,
                ...expandedData['invoice'].data,
              }
            : expandedData['invoice'] as DataMap)
        : null;

    final customer = expandedData?['customer'] != null
        ? CustomerModel.fromJson(expandedData!['customer'] is RecordModel
            ? {
                'id': expandedData['customer'].id,
                'collectionId': expandedData['customer'].collectionId,
                'collectionName': expandedData['customer'].collectionName,
                ...expandedData['customer'].data,
              }
            : expandedData['customer'] as DataMap)
        : null;

    final trip = expandedData?['trip'] != null
        ? TripModel.fromJson(expandedData!['trip'] is RecordModel
            ? {
                'id': expandedData['trip'].id,
                'collectionId': expandedData['trip'].collectionId,
                'collectionName': expandedData['trip'].collectionName,
                ...expandedData['trip'].data,
              }
            : expandedData['trip'] as DataMap)
        : null;

    return ReturnModel(
      id: json['id']?.toString(),
      collectionId: json['collectionId']?.toString(),
      collectionName: json['collectionName']?.toString(),
      productName: json['productName']?.toString(),
      productDescription: json['productDescription']?.toString(),
      productQuantityCase: int.tryParse(json['productQuantityCase']?.toString() ?? '0'),
      productQuantityPcs: int.tryParse(json['productQuantityPcs']?.toString() ?? '0'),
      productQuantityPack: int.tryParse(json['productQuantityPack']?.toString() ?? '0'),
      productQuantityBox: int.tryParse(json['productQuantityBox']?.toString() ?? '0'),
      isCase: json['isCase'] as bool?,
      isPcs: json['isPcs'] as bool?,
      isBox: json['isBox'] as bool?,
      isPack: json['isPack'] as bool?,
      reason: json['reason'] != null 
          ? ProductReturnReason.values.firstWhere(
              (r) => r.toString() == json['reason'],
              orElse: () => ProductReturnReason.damaged,
            )
          : null,
      returnDate: json['returnDate'] != null 
          ? DateTime.parse(json['returnDate'].toString())
          : null,
      invoice: invoice,
      customer: customer,
      trip: trip,
    );
  }

  DataMap toJson() {
    return {
      'id': pocketbaseId,
      'collectionId': collectionId,
      'collectionName': collectionName,
      'productName': productName,
      'productDescription': productDescription,
      'productQuantityCase': productQuantityCase,
      'productQuantityPcs': productQuantityPcs,
      'productQuantityPack': productQuantityPack,
      'productQuantityBox': productQuantityBox,
      'isCase': isCase,
      'isPcs': isPcs,
      'isBox': isBox,
      'isPack': isPack,
      'reason': reason?.toString(),
      'returnDate': returnDate?.toIso8601String(),
      'invoice': invoice?.toJson(),
      'customer': customer?.toJson(),
      'trip': trip?.toJson(),
    };
  }
}
