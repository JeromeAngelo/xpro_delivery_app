import 'package:objectbox/objectbox.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/customer/data/model/customer_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/invoice/data/models/invoice_models.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/products/domain/entity/product_entity.dart';
import 'package:x_pro_delivery_app/core/enums/product_return_reason.dart';
import 'package:x_pro_delivery_app/core/enums/product_unit.dart';
import 'package:x_pro_delivery_app/core/enums/products_status.dart';
import 'package:x_pro_delivery_app/core/utils/typedefs.dart';

@Entity()
class ProductModel extends ProductEntity {
  @Id()
  int objectBoxId = 0;

  @Property()
  String pocketbaseId;

  @Property()
  String? invoiceId;

  @Property()
  String? customerId;

  // final ToOne<InvoiceModel> invoice = ToOne<InvoiceModel>();
  // final ToOne<CustomerModel> customer = ToOne<CustomerModel>();

  ProductModel({
    super.id,
    super.name,
    super.description,
    super.totalAmount,
    super.case_,
    super.pcs,
    super.pack,
    super.box,
    super.pricePerCase,
    super.pricePerPc,
    super.primaryUnit,
    super.secondaryUnit,
    super.image,
    InvoiceModel? invoiceModel,
    CustomerModel? customerModel,
    super.isCase,
    super.isPc,
    super.isPack,
    super.isBox,
    super.unloadedProductCase,
    super.unloadedProductPc,
    super.unloadedProductPack,
    super.unloadedProductBox,
    super.status,
    super.hasReturn,
    super.returnReason,
    this.invoiceId,
    this.customerId,
  }) : pocketbaseId = id ?? '' {
    if (invoiceModel != null) invoice.target = invoiceModel;
    if (customerModel != null) customer.target = customerModel;
  }

  factory ProductModel.fromJson(DataMap json) {
    final expandedData = json['expand'] as Map<String, dynamic>?;

    return ProductModel(
      id: json['id']?.toString(),
      name: json['name']?.toString(),
      description: json['description']?.toString(),
      totalAmount: double.tryParse(json['totalAmount']?.toString() ?? '0'),
      case_: int.tryParse(json['case']?.toString() ?? '0'),
      pcs: int.tryParse(json['pcs']?.toString() ?? '0'),
      pack: int.tryParse(json['pack']?.toString() ?? '0'),
      box: int.tryParse(json['box']?.toString() ?? '0'),
      pricePerCase: double.tryParse(json['pricePerCase']?.toString() ?? '0'),
      pricePerPc: double.tryParse(json['pricePerPc']?.toString() ?? '0'),
      primaryUnit: ProductUnit.values.firstWhere(
        (e) => e.name == (json['primaryUnit'] ?? 'case'),
        orElse: () => ProductUnit.cases,
      ),
      secondaryUnit: ProductUnit.values.firstWhere(
        (e) => e.name == (json['secondaryUnit'] ?? 'pc'),
        orElse: () => ProductUnit.pc,
      ),
      image: json['image']?.toString(),
      hasReturn: json['hasReturn'] as bool? ?? false,
      isCase: json['isCase'] as bool? ?? false,
      isPc: json['isPc'] as bool? ?? false,
      isPack: json['isPack'] as bool? ?? false,
      isBox: json['isBox'] as bool? ?? false,
      unloadedProductCase: int.tryParse(json['unloadedProductCase']?.toString() ?? '0'),
      unloadedProductPc: int.tryParse(json['unloadedProductPc']?.toString() ?? '0'),
      unloadedProductPack: int.tryParse(json['unloadedProductPack']?.toString() ?? '0'),
      unloadedProductBox: int.tryParse(json['unloadedProductBox']?.toString() ?? '0'),
      status: ProductsStatus.values.firstWhere(
        (e) => e.name == (json['status'] ?? 'truck'),
        orElse: () => ProductsStatus.truck,
      ),
      returnReason: ProductReturnReason.values.firstWhere(
        (e) => e.name == (json['returnReason'] ?? 'none'),
        orElse: () => ProductReturnReason.none,
      ),
      invoiceId: json['invoice']?.toString(),
      customerId: json['customer']?.toString(),
      invoiceModel: expandedData?['invoice'] != null 
          ? InvoiceModel.fromJson(expandedData!['invoice']) 
          : null,
      customerModel: expandedData?['customer'] != null 
          ? CustomerModel.fromJson(expandedData!['customer']) 
          : null,
    );
  }

  DataMap toJson() {
    return {
      'id': pocketbaseId,
      'name': name,
      'description': description,
      'totalAmount': totalAmount,
      'case': case_,
      'pcs': pcs,
      'pack': pack,
      'box': box,
      'pricePerCase': pricePerCase,
      'pricePerPc': pricePerPc,
      'primaryUnit': primaryUnit?.toString().split('.').last,
      'secondaryUnit': secondaryUnit?.toString().split('.').last,
      'image': image,
      'invoice': invoice.target?.id,
      'customer': customer.target?.id,
      'hasReturn': hasReturn,
      'isCase': isCase,
      'isPc': isPc,
      'isPack': isPack,
      'isBox': isBox,
      'unloadedProductCase': unloadedProductCase,
      'unloadedProductPc': unloadedProductPc,
      'unloadedProductPack': unloadedProductPack,
      'unloadedProductBox': unloadedProductBox,
      'status': status?.toString().split('.').last,
      'returnReason': returnReason?.toString().split('.').last,
    };
  }

  ProductModel copyWith({
    String? id,
    String? name,
    String? description,
    double? totalAmount,
    int? case_,
    int? pcs,
    int? pack,
    int? box,
    double? pricePerCase,
    double? pricePerPc,
    ProductUnit? primaryUnit,
    ProductUnit? secondaryUnit,
    String? image,
    InvoiceModel? invoiceModel,
    CustomerModel? customerModel,
    bool? isCase,
    bool? isPc,
    bool? isPack,
    bool? isBox,
    int? unloadedProductCase,
    int? unloadedProductPc,
    int? unloadedProductPack,
    int? unloadedProductBox,
    ProductsStatus? status,
    bool? hasReturn,
    ProductReturnReason? returnReason,
    String? invoiceId,
    String? customerId,
  }) {
    return ProductModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      totalAmount: totalAmount ?? this.totalAmount,
      case_: case_ ?? this.case_,
      pcs: pcs ?? this.pcs,
      pack: pack ?? this.pack,
      box: box ?? this.box,
      pricePerCase: pricePerCase ?? this.pricePerCase,
      pricePerPc: pricePerPc ?? this.pricePerPc,
      primaryUnit: primaryUnit ?? this.primaryUnit,
      secondaryUnit: secondaryUnit ?? this.secondaryUnit,
      image: image ?? this.image,
      invoiceModel: invoiceModel ?? invoice.target,
      customerModel: customerModel ?? customer.target,
      isCase: isCase ?? this.isCase,
      isPc: isPc ?? this.isPc,
      isPack: isPack ?? this.isPack,
      isBox: isBox ?? this.isBox,
      unloadedProductCase: unloadedProductCase ?? this.unloadedProductCase,
      unloadedProductPc: unloadedProductPc ?? this.unloadedProductPc,
      unloadedProductPack: unloadedProductPack ?? this.unloadedProductPack,
      unloadedProductBox: unloadedProductBox ?? this.unloadedProductBox,
      status: status ?? this.status,
      hasReturn: hasReturn ?? this.hasReturn,
      returnReason: returnReason ?? this.returnReason,
      invoiceId: invoiceId ?? this.invoiceId,
      customerId: customerId ?? this.customerId,
    );
  }
}
