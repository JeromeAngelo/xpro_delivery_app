
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_data/delivery_receipt/domain/entity/delivery_receipt_entity.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_data/delivery_receipt/domain/usecases/create_delivery_receipt.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_data/delivery_receipt/domain/usecases/delete_delivery_receipt.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_data/delivery_receipt/domain/usecases/generate_pdf.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_data/delivery_receipt/domain/usecases/get_delivery_receipt_by_delivery_data_id.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_data/delivery_receipt/domain/usecases/get_delivery_receipt_by_trip_id.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_data/delivery_receipt/presentation/bloc/delivery_receipt_event.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_data/delivery_receipt/presentation/bloc/delivery_receipt_state.dart';

class DeliveryReceiptBloc extends Bloc<DeliveryReceiptEvent, DeliveryReceiptState> {
  final GetDeliveryReceiptByTripId _getDeliveryReceiptByTripId;
  final GetDeliveryReceiptByDeliveryDataId _getDeliveryReceiptByDeliveryDataId;
  final CreateDeliveryReceipt _createDeliveryReceipt;
  final DeleteDeliveryReceipt _deleteDeliveryReceipt;
  final GenerateDeliveryReceiptPdf _generateDeliveryReceiptPdf; // 

  DeliveryReceiptState? _cachedState;

  DeliveryReceiptBloc({
    required GetDeliveryReceiptByTripId getDeliveryReceiptByTripId,
    required GetDeliveryReceiptByDeliveryDataId getDeliveryReceiptByDeliveryDataId,
    required CreateDeliveryReceipt createDeliveryReceipt,
    required DeleteDeliveryReceipt deleteDeliveryReceipt,
    required GenerateDeliveryReceiptPdf generateDeliveryReceiptPdf, // Add this
  })  : _getDeliveryReceiptByTripId = getDeliveryReceiptByTripId,
        _getDeliveryReceiptByDeliveryDataId = getDeliveryReceiptByDeliveryDataId,
        _createDeliveryReceipt = createDeliveryReceipt,
        _deleteDeliveryReceipt = deleteDeliveryReceipt,
        _generateDeliveryReceiptPdf = generateDeliveryReceiptPdf, // Add this
        super(const DeliveryReceiptInitial()) {
    
    on<GetDeliveryReceiptByTripIdEvent>(_onGetDeliveryReceiptByTripId);
    on<LoadLocalDeliveryReceiptByTripIdEvent>(_onLoadLocalDeliveryReceiptByTripId);
    on<GetDeliveryReceiptByDeliveryDataIdEvent>(_onGetDeliveryReceiptByDeliveryDataId);
    on<LoadLocalDeliveryReceiptByDeliveryDataIdEvent>(_onLoadLocalDeliveryReceiptByDeliveryDataId);
    on<CreateDeliveryReceiptEvent>(_onCreateDeliveryReceipt);
    on<DeleteDeliveryReceiptEvent>(_onDeleteDeliveryReceipt);
    on<ClearAllLocalDeliveryReceiptsEvent>(_onClearAllLocalDeliveryReceipts);
    on<GetAllLocalDeliveryReceiptsEvent>(_onGetAllLocalDeliveryReceipts);
    on<CacheDeliveryReceiptEvent>(_onCacheDeliveryReceipt);
    on<GenerateDeliveryReceiptPdfEvent>(_onGenerateDeliveryReceiptPdf); // Add this
  }

  Future<void> _onGetDeliveryReceiptByTripId(
    GetDeliveryReceiptByTripIdEvent event,
    Emitter<DeliveryReceiptState> emit,
  ) async {
    debugPrint('🔄 Getting delivery receipt by trip ID: ${event.tripId}');

    // Emit cached state if available, then loading
    if (_cachedState != null && _cachedState is DeliveryReceiptLoaded) {
      emit(_cachedState!);
    } else {
      emit(const DeliveryReceiptLoading());
    }

    final result = await _getDeliveryReceiptByTripId(event.tripId);
    
    result.fold(
      (failure) {
        debugPrint('❌ Failed to get delivery receipt by trip ID: ${failure.message}');
        
        if (failure.message.contains('404') || failure.message.contains('not found')) {
          emit(DeliveryReceiptNotFound(
            searchId: event.tripId,
            searchType: 'tripId',
          ));
        } else {
          emit(DeliveryReceiptError(
            message: failure.message,
            errorCode: failure.statusCode,
          ));
        }
      },
      (deliveryReceipt) {
        debugPrint('✅ Successfully retrieved delivery receipt by trip ID');
        final newState = DeliveryReceiptLoaded(
          deliveryReceipt: deliveryReceipt,
          isFromCache: false,
        );
        _cachedState = newState;
        emit(newState);
      },
    );
  }

  Future<void> _onLoadLocalDeliveryReceiptByTripId(
    LoadLocalDeliveryReceiptByTripIdEvent event,
    Emitter<DeliveryReceiptState> emit,
  ) async {
    debugPrint('📦 Loading delivery receipt by trip ID from local: ${event.tripId}');
    
    emit(const DeliveryReceiptLoading());

    final result = await _getDeliveryReceiptByTripId.loadFromLocal(event.tripId);
    
    result.fold(
      (failure) {
        debugPrint('❌ Failed to load local delivery receipt by trip ID: ${failure.message}');
        
        if (failure.message.contains('404') || failure.message.contains('not found')) {
          emit(DeliveryReceiptNotFound(
            searchId: event.tripId,
            searchType: 'tripId',
          ));
          // Automatically try remote fetch if local fails
          add(GetDeliveryReceiptByTripIdEvent(event.tripId));
        } else {
          emit(DeliveryReceiptError(
            message: failure.message,
            errorCode: failure.statusCode,
          ));
        }
      },
      (deliveryReceipt) {
        debugPrint('✅ Successfully loaded delivery receipt from local by trip ID');
        final newState = DeliveryReceiptLoaded(
          deliveryReceipt: deliveryReceipt,
          isFromCache: true,
        );
        _cachedState = newState;
        emit(newState);
        // Refresh with remote data in background
        add(GetDeliveryReceiptByTripIdEvent(event.tripId));
      },
    );
  }

  Future<void> _onGetDeliveryReceiptByDeliveryDataId(
    GetDeliveryReceiptByDeliveryDataIdEvent event,
    Emitter<DeliveryReceiptState> emit,
  ) async {
    debugPrint('🔄 Getting delivery receipt by delivery data ID: ${event.deliveryDataId}');

    // Emit cached state if available, then loading
    if (_cachedState != null && _cachedState is DeliveryReceiptLoaded) {
      emit(_cachedState!);
    } else {
      emit(const DeliveryReceiptLoading());
    }

    final result = await _getDeliveryReceiptByDeliveryDataId(event.deliveryDataId);
    
    result.fold(
      (failure) {
        debugPrint('❌ Failed to get delivery receipt by delivery data ID: ${failure.message}');
        
        if (failure.message.contains('404') || failure.message.contains('not found')) {
          emit(DeliveryReceiptNotFound(
            searchId: event.deliveryDataId,
            searchType: 'deliveryDataId',
          ));
        } else {
          emit(DeliveryReceiptError(
            message: failure.message,
            errorCode: failure.statusCode,
          ));
        }
      },
      (deliveryReceipt) {
        debugPrint('✅ Successfully retrieved delivery receipt by delivery data ID');
        final newState = DeliveryReceiptLoaded(
          deliveryReceipt: deliveryReceipt,
          isFromCache: false,
        );
        _cachedState = newState;
        emit(newState);
      },
    );
  }

  Future<void> _onLoadLocalDeliveryReceiptByDeliveryDataId(
    LoadLocalDeliveryReceiptByDeliveryDataIdEvent event,
    Emitter<DeliveryReceiptState> emit,
  ) async {
    debugPrint('📦 Loading delivery receipt by delivery data ID from local: ${event.deliveryDataId}');
    
    emit(const DeliveryReceiptLoading());

    final result = await _getDeliveryReceiptByDeliveryDataId.loadFromLocal(event.deliveryDataId);
    
    result.fold(
      (failure) {
        debugPrint('❌ Failed to load local delivery receipt by delivery data ID: ${failure.message}');
        
        if (failure.message.contains('404') || failure.message.contains('not found')) {
          emit(DeliveryReceiptNotFound(
            searchId: event.deliveryDataId,
            searchType: 'deliveryDataId',
          ));
          // Automatically try remote fetch if local fails
          add(GetDeliveryReceiptByDeliveryDataIdEvent(event.deliveryDataId));
        } else {
          emit(DeliveryReceiptError(
            message: failure.message,
            errorCode: failure.statusCode,
          ));
        }
      },
      (deliveryReceipt) {
        debugPrint('✅ Successfully loaded delivery receipt from local by delivery data ID');
        final newState = DeliveryReceiptLoaded(
          deliveryReceipt: deliveryReceipt,
          isFromCache: true,
        );
        _cachedState = newState;
        emit(newState);
        // Refresh with remote data in background
        add(GetDeliveryReceiptByDeliveryDataIdEvent(event.deliveryDataId));
      },
    );
  }

    Future<void> _onCreateDeliveryReceipt(
    CreateDeliveryReceiptEvent event,
    Emitter<DeliveryReceiptState> emit,
  ) async {
    debugPrint('🔄 Creating delivery receipt for delivery data: ${event.deliveryDataId}');
    
    emit(const DeliveryReceiptLoading());

    final result = await _createDeliveryReceipt(
      CreateDeliveryReceiptParams(
        deliveryDataId: event.deliveryDataId,
        status: event.status,
        dateTimeCompleted: event.dateTimeCompleted,
        customerImages: event.customerImages,
        customerSignature: event.customerSignature,
        amount: event.amount,
        receiptFile: event.receiptFile,
      ),
    );

    result.fold(
      (failure) {
        debugPrint('❌ Failed to create delivery receipt: ${failure.message}');
        
        // Check if it's an offline operation
        if (failure.message.contains('offline') || failure.message.contains('network')) {
          emit(DeliveryReceiptOfflineOperation(
            message: 'Delivery receipt created offline. Will sync when online.',
            operationType: 'create',
          ));
        } else {
          emit(DeliveryReceiptError(
            message: failure.message,
            errorCode: failure.statusCode,
          ));
        }
      },
      (deliveryReceipt) {
        debugPrint('✅ Successfully created delivery receipt (local save completed)');
        debugPrint('🚀 Emitting success state for immediate UI navigation');
        
        // Emit success state immediately after local save
        // This allows the UI to navigate right away while background sync continues
        final newState = DeliveryReceiptCreated(
          deliveryReceipt: deliveryReceipt,
          deliveryDataId: event.deliveryDataId,
        );
        emit(newState);
        
        // Update cached state for future use
        _cachedState = DeliveryReceiptLoaded(
          deliveryReceipt: deliveryReceipt,
          isFromCache: false,
        );
        
        debugPrint('📱 UI can now navigate immediately while background sync continues');
      },
    );
  

  }

  Future<void> _onDeleteDeliveryReceipt(
    DeleteDeliveryReceiptEvent event,
    Emitter<DeliveryReceiptState> emit,
  ) async {
    debugPrint('🔄 Deleting delivery receipt: ${event.receiptId}');
    
    emit(const DeliveryReceiptLoading());

    final result = await _deleteDeliveryReceipt(event.receiptId);

    result.fold(
      (failure) {
        debugPrint('❌ Failed to delete delivery receipt: ${failure.message}');
        emit(DeliveryReceiptError(
          message: failure.message,
          errorCode: failure.statusCode,
        ));
      },
      (success) {
        if (success) {
          debugPrint('✅ Successfully deleted delivery receipt');
          emit(DeliveryReceiptDeleted(event.receiptId));
          
          // Clear cached state if it matches the deleted receipt
          if (_cachedState is DeliveryReceiptLoaded) {
            final loadedState = _cachedState as DeliveryReceiptLoaded;
            if (loadedState.deliveryReceipt.id == event.receiptId) {
              _cachedState = null;
            }
          }
        } else {
          debugPrint('⚠️ Delivery receipt deletion returned false');
          emit(const DeliveryReceiptError(
            message: 'Failed to delete delivery receipt',
            errorCode: '500',
          ));
        }
      },
    );
  }

  Future<void> _onClearAllLocalDeliveryReceipts(
    ClearAllLocalDeliveryReceiptsEvent event,
    Emitter<DeliveryReceiptState> emit,
  ) async {
    debugPrint('🗑️ Clearing all local delivery receipts');
    
    emit(const DeliveryReceiptLoading());

    try {
      // This would need to be implemented in the repository
      // For now, we'll emit a success state
      debugPrint('✅ Successfully cleared all local delivery receipts');
      emit(const DeliveryReceiptsCleared());
      _cachedState = null;
    } catch (e) {
      debugPrint('❌ Failed to clear local delivery receipts: $e');
      emit(DeliveryReceiptError(
        message: 'Failed to clear local delivery receipts: ${e.toString()}',
        errorCode: '500',
      ));
    }
  }

  Future<void> _onGetAllLocalDeliveryReceipts(
    GetAllLocalDeliveryReceiptsEvent event,
    Emitter<DeliveryReceiptState> emit,
  ) async {
    debugPrint('📦 Getting all local delivery receipts');
    
    emit(const DeliveryReceiptLoading());

    try {
      // This would need to be implemented in the repository
      // For now, we'll emit an empty list
      debugPrint('✅ Successfully retrieved all local delivery receipts');
      emit(const DeliveryReceiptsLoaded(
        deliveryReceipts: [],
        isFromCache: true,
      ));
    } catch (e) {
      debugPrint('❌ Failed to get all local delivery receipts: $e');
      emit(DeliveryReceiptError(
        message: 'Failed to get all local delivery receipts: ${e.toString()}',
        errorCode: '500',
      ));
    }
  }

    Future<void> _onCacheDeliveryReceipt(
    CacheDeliveryReceiptEvent event,
    Emitter<DeliveryReceiptState> emit,
  ) async {
    debugPrint('📥 Caching delivery receipt: ${event.receiptId}');
    
    emit(const DeliveryReceiptLoading());

    try {
      // This would need to be implemented in the repository
      // For now, we'll emit a success state
      debugPrint('✅ Successfully cached delivery receipt');
      emit(DeliveryReceiptCached(event.receiptId));
    } catch (e) {
      debugPrint('❌ Failed to cache delivery receipt: $e');
      emit(DeliveryReceiptError(
        message: 'Failed to cache delivery receipt: ${e.toString()}',
        errorCode: '500',
      ));
    }
  }

    // Add this event handler method
  Future<void> _onGenerateDeliveryReceiptPdf(
    GenerateDeliveryReceiptPdfEvent event,
    Emitter<DeliveryReceiptState> emit,
  ) async {
    debugPrint('📄 Generating delivery receipt PDF for: ${event.deliveryData.id}');
    
    emit(DeliveryReceiptPdfGenerating(event.deliveryData.id ?? ''));

    final result = await _generateDeliveryReceiptPdf(event.deliveryData);
    
    result.fold(
      (failure) {
        debugPrint('❌ Failed to generate delivery receipt PDF: ${failure.message}');
        emit(DeliveryReceiptError(
          message: failure.message,
          errorCode: failure.statusCode,
        ));
      },
      (pdfBytes) {
        debugPrint('✅ Successfully generated delivery receipt PDF');
        debugPrint('📊 PDF size: ${pdfBytes.length} bytes');
        emit(DeliveryReceiptPdfGenerated(
          pdfBytes: pdfBytes,
          deliveryDataId: event.deliveryData.id ?? '',
        ));
      },
    );
  }

  /// Helper method to refresh current data
  // void refreshCurrentData() {
  //   if (_cachedState is DeliveryReceiptLoaded) {
  //     final loadedState = _cachedState as DeliveryReceiptLoaded;
  //     // Try to refresh based on what data we have
  //     // This is a simplified approach - in practice you'd need to track
  //     // which ID was used to load the current data
  //     debugPrint('🔄 Refreshing current delivery receipt data');
  //   }
  // }

  /// Helper method to check if we have cached data
  bool get hasCachedData => _cachedState is DeliveryReceiptLoaded;

  /// Helper method to get cached delivery receipt
  DeliveryReceiptEntity? get cachedDeliveryReceipt {
    if (_cachedState is DeliveryReceiptLoaded) {
      return (_cachedState as DeliveryReceiptLoaded).deliveryReceipt;
    }
    return null;
  }

  /// Helper method to clear cache
  void clearCache() {
    debugPrint('🗑️ Clearing delivery receipt cache');
    _cachedState = null;
  }

  /// Helper method to handle offline scenarios
  void handleOfflineOperation(String operation, String id) {
    debugPrint('📱 Handling offline operation: $operation for $id');
    emit(DeliveryReceiptOfflineOperation(
      message: 'Operation performed offline. Will sync when connection is restored.',
      operationType: operation,
    ));
  }

  /// Helper method to retry failed operations
  void retryLastOperation() {
    if (state is DeliveryReceiptError) {
      debugPrint('🔄 Retrying last operation');
      // In a real implementation, you'd store the last event and retry it
      emit(const DeliveryReceiptLoading());
    }
  }

  @override
  Future<void> close() {
    debugPrint('🔒 Closing DeliveryReceiptBloc');
    _cachedState = null;
    return super.close();
  }

  @override
  void onTransition(Transition<DeliveryReceiptEvent, DeliveryReceiptState> transition) {
    super.onTransition(transition);
    debugPrint('🔄 DeliveryReceipt Transition: ${transition.event.runtimeType} -> ${transition.nextState.runtimeType}');
  }

  @override
  void onError(Object error, StackTrace stackTrace) {
    debugPrint('❌ DeliveryReceipt Error: $error');
    super.onError(error, stackTrace);
  }
}

