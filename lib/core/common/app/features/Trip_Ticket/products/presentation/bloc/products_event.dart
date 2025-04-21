import 'package:equatable/equatable.dart';
import 'package:x_pro_delivery_app/core/enums/product_return_reason.dart';
import 'package:x_pro_delivery_app/core/enums/products_status.dart';
abstract class ProductsEvent extends Equatable {
  const ProductsEvent();
  
  @override
  List<Object> get props => [];
}
  
class GetProductsEvent extends ProductsEvent {
  const GetProductsEvent();
}

class UpdateProductStatusEvent extends ProductsEvent {
  const UpdateProductStatusEvent({
    required this.productId,
    required this.status,
  });
  
  final String productId;
  final ProductsStatus status;
  
  @override
  List<Object> get props => [productId, status];
}

// products_event.dart
class ConfirmDeliveryProductsEvent extends ProductsEvent {
  final String invoiceId;
  final double confirmTotalAmount;
  final String customerId;
  
  const ConfirmDeliveryProductsEvent({
    required this.invoiceId,
    required this.confirmTotalAmount,
    required this.customerId,
  });
  
  @override
  List<Object> get props => [invoiceId, confirmTotalAmount, customerId];
}


class AddToReturnEvent extends ProductsEvent {
  final String productId;
  final ProductReturnReason reason;
  final int returnProductCase;
  final int returnProductPc;
  final int returnProductPack;
  final int returnProductBox;
  
  const AddToReturnEvent({
    required this.productId,
    required this.reason,
    required this.returnProductCase,
    required this.returnProductPc,
    required this.returnProductPack,
    required this.returnProductBox,
  });
  
  @override
  List<Object> get props => [
    productId, 
    reason, 
    returnProductCase, 
    returnProductPc,
    returnProductPack,
    returnProductBox,
  ];
}

class UpdateReturnReasonEvent extends ProductsEvent {
  final String productId;
  final ProductReturnReason reason;
  final int returnProductCase;
  final int returnProductPc;
  final int returnProductPack;
  final int returnProductBox;
  
  const UpdateReturnReasonEvent({
    required this.productId,
    required this.reason,
    required this.returnProductCase,
    required this.returnProductPc,
    required this.returnProductPack,
    required this.returnProductBox,
  });
  
  @override
  List<Object> get props => [
    productId, 
    reason,
    returnProductCase,
    returnProductPc,
    returnProductPack,
    returnProductBox,
  ];
}

class UpdateProductQuantitiesEvent extends ProductsEvent {
  final String productId;
  final int unloadedProductCase;
  final int unloadedProductPc;
  final int unloadedProductPack;
  final int unloadedProductBox;

  const UpdateProductQuantitiesEvent({
    required this.productId,
    required this.unloadedProductCase,
    required this.unloadedProductPc,
    required this.unloadedProductPack,
    required this.unloadedProductBox,
  });

  @override
  List<Object> get props => [
    productId, 
    unloadedProductCase, 
    unloadedProductPc,
    unloadedProductPack,
    unloadedProductBox,
  ];
}

// Add these new events
class GetProductsByInvoiceIdEvent extends ProductsEvent {
  final String invoiceId;
  
  const GetProductsByInvoiceIdEvent(this.invoiceId);
  
  @override
  List<Object> get props => [invoiceId];
}

class LoadLocalProductsByInvoiceIdEvent extends ProductsEvent {
  final String invoiceId;
  
  const LoadLocalProductsByInvoiceIdEvent(this.invoiceId);
  
  @override
  List<Object> get props => [invoiceId];
}
