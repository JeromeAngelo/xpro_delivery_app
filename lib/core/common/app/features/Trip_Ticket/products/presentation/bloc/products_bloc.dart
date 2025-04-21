import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/products/domain/usecase/add_to_return_usecase.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/products/domain/usecase/confirm_delivery_products.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/products/domain/usecase/get_product.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/products/domain/usecase/get_products_by_invoice_id.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/products/domain/usecase/update_product_quantities.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/products/domain/usecase/update_return_reason_usecase.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/products/domain/usecase/update_status_product.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/products/presentation/bloc/products_event.dart';

import 'products_state.dart';

class ProductsBloc extends Bloc<ProductsEvent, ProductsState> {
  ProductsBloc({
    required GetProduct getProduct,
    required GetProductsByInvoice getProductsByInvoice,
    required UpdateStatusProduct updateStatusProduct,
    required ConfirmDeliveryProducts confirmDeliveryProducts,
    required AddToReturnUsecase addToReturn,
    required UpdateReturnReasonUsecase updateReturnReason,
    required UpdateProductQuantities updateProductQuantities,
  })  : _getProduct = getProduct,
        _getProductsByInvoice = getProductsByInvoice,
        _updateStatusProduct = updateStatusProduct,
        _confirmDeliveryProducts = confirmDeliveryProducts,
        _addToReturn = addToReturn,
        _updateReturnReason = updateReturnReason,
        _updateProductQuantities = updateProductQuantities,
        super(const ProductsInitial()) {
    on<GetProductsEvent>(_onGetProductHandler);
    on<GetProductsByInvoiceIdEvent>(_onGetProductsByInvoiceIdHandler);
    on<LoadLocalProductsByInvoiceIdEvent>(_onLoadLocalProductsByInvoiceIdHandler);
    on<UpdateProductStatusEvent>(_onUpdateProductStatusHandler);
    on<ConfirmDeliveryProductsEvent>(_onConfirmDeliveryProductsHandler);
    on<AddToReturnEvent>(_onAddToReturnHandler);
    on<UpdateReturnReasonEvent>(_onUpdateReturnReasonHandler);
    on<UpdateProductQuantitiesEvent>(_onUpdateProductQuantitiesHandler);
  }

  final GetProduct _getProduct;
  final GetProductsByInvoice _getProductsByInvoice;
  final UpdateStatusProduct _updateStatusProduct;
  final ConfirmDeliveryProducts _confirmDeliveryProducts;
  final AddToReturnUsecase _addToReturn;
  final UpdateReturnReasonUsecase _updateReturnReason;
  final UpdateProductQuantities _updateProductQuantities;

   Future<void> _onGetProductsByInvoiceIdHandler(
    GetProductsByInvoiceIdEvent event,
    Emitter<ProductsState> emit,
  ) async {
    emit(const ProductsLoading());
    debugPrint('🔄 Loading products for invoice: ${event.invoiceId}');

    final result = await _getProductsByInvoice(event.invoiceId);
    result.fold(
      (failure) => emit(ProductsError(failure.message)),
      (products) {
        debugPrint('✅ Loaded ${products.length} products');
        emit(InvoiceProductsLoaded(products, event.invoiceId));
      },
    );
  }

 Future<void> _onLoadLocalProductsByInvoiceIdHandler(
  LoadLocalProductsByInvoiceIdEvent event,
  Emitter<ProductsState> emit,
) async {
  emit(const ProductsLoading());
  debugPrint('📱 Loading local products for invoice: ${event.invoiceId}');

  final result = await _getProductsByInvoice.loadFromLocal(event.invoiceId);
  
  await result.fold(
    (failure) async => emit(ProductsError(failure.message)),
    (localProducts) async {
      // Emit local products immediately
      emit(InvoiceProductsLoaded(localProducts, event.invoiceId, ));
      debugPrint('✅ Loaded ${localProducts.length} local products');

      // Keep state after updates
      if (localProducts.isEmpty) {
        // Try remote fetch if local is empty
        final remoteResult = await _getProductsByInvoice(event.invoiceId);
        remoteResult.fold(
          (failure) => debugPrint('🔄 Remote sync skipped: ${failure.message}'),
          (remoteProducts) {
            if (!emit.isDone) {
              emit(InvoiceProductsLoaded(remoteProducts, event.invoiceId));
              debugPrint('🔄 Updated with ${remoteProducts.length} remote products');
            }
          },
        );
      }
    },
  );
}



  Future<void> _onGetProductHandler(
    GetProductsEvent event,
    Emitter<ProductsState> emit,
  ) async {
    emit(const ProductsLoading());
    final result = await _getProduct();
    result.fold(
      (failure) => emit(ProductsError(failure.message)),
      (products) => emit(ProductsLoaded(products)),
    );
  }

  Future<void> _onUpdateProductStatusHandler(
    UpdateProductStatusEvent event,
    Emitter<ProductsState> emit,
  ) async {
    final params = UpdateStatusParams(
      productId: event.productId,
      status: event.status,
    );

    final result = await _updateStatusProduct(params);
    result.fold(
      (failure) => emit(ProductsError(failure.message)),
      (_) => emit(ProductStatusUpdated(
        productId: event.productId,
        status: event.status,
      )),
    );
  }

// products_bloc.dart
Future<void> _onConfirmDeliveryProductsHandler(
  ConfirmDeliveryProductsEvent event,
  Emitter<ProductsState> emit,
) async {
  final params = (event.invoiceId, event.confirmTotalAmount, event.customerId);
  final result = await _confirmDeliveryProducts(params);
  
  result.fold(
    (failure) => emit(ProductsError(failure.message)),
    (_) => emit(DeliveryProductsConfirmed(
      invoiceId: event.invoiceId,
      confirmTotalAmount: event.confirmTotalAmount,
      customerId: event.customerId,
    )),
  );
}


  Future<void> _onAddToReturnHandler(
    AddToReturnEvent event,
    Emitter<ProductsState> emit,
  ) async {
    final params = AddToReturnParams(
      productId: event.productId,
      reason: event.reason,
      returnProductCase: event.returnProductCase,
      returnProductPc: event.returnProductPc,
      returnProductPack: event.returnProductPack,
      returnProductBox: event.returnProductBox,
    );

    final result = await _addToReturn(params);
    result.fold(
      (failure) => emit(ProductsError(failure.message)),
      (_) => emit(ProductAddedToReturn(
        productId: event.productId,
        reason: event.reason,
        returnProductCase: event.returnProductCase,
        returnProductPc: event.returnProductPc,
        returnProductPack: event.returnProductPack,
        returnProductBox: event.returnProductBox,
      )),
    );
  }

  Future<void> _onUpdateReturnReasonHandler(
    UpdateReturnReasonEvent event,
    Emitter<ProductsState> emit,
  ) async {
    final params = UpdateReasonParams(
      productId: event.productId,
      reason: event.reason,
      returnProductCase: event.returnProductCase,
      returnProductPc: event.returnProductPc,
      returnProductPack: event.returnProductPack,
      returnProductBox: event.returnProductBox,
    );

    final result = await _updateReturnReason(params);
    result.fold(
      (failure) => emit(ProductsError(failure.message)),
      (_) => emit(ProductReturnReasonUpdated(
        productId: event.productId,
        reason: event.reason,
        returnProductCase: event.returnProductCase,
        returnProductPc: event.returnProductPc,
        returnProductPack: event.returnProductPack,
        returnProductBox: event.returnProductBox,
      )),
    );
  }

  Future<void> _onUpdateProductQuantitiesHandler(
    UpdateProductQuantitiesEvent event,
    Emitter<ProductsState> emit,
  ) async {
    debugPrint('🔄 Bloc received quantities:');
    debugPrint('Product ID: ${event.productId}');
    debugPrint('Case: ${event.unloadedProductCase}');
    debugPrint('PC: ${event.unloadedProductPc}');

    final params = UpdateProductQuantitiesParams(
      productId: event.productId,
      unloadedProductCase: event.unloadedProductCase,
      unloadedProductPc: event.unloadedProductPc,
      unloadedProductPack: event.unloadedProductPack,
      unloadedProductBox: event.unloadedProductBox,
    );

    final result = await _updateProductQuantities(params);
    result.fold(
      (failure) => emit(ProductsError(failure.message)),
      (_) => emit(ProductQuantitiesUpdated(
        productId: event.productId,
        unloadedProductCase: event.unloadedProductCase,
        unloadedProductPc: event.unloadedProductPc,
        unloadedProductPack: event.unloadedProductPack,
        unloadedProductBox: event.unloadedProductBox,
      )),
    );
  }
}
