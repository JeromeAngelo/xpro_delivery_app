import 'dart:typed_data';

import 'package:equatable/equatable.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/delivery_receipt/domain/entity/delivery_receipt_entity.dart';

abstract class DeliveryReceiptState extends Equatable {
  const DeliveryReceiptState();

  @override
  List<Object?> get props => [];
}

/// Initial state
class DeliveryReceiptInitial extends DeliveryReceiptState {
  const DeliveryReceiptInitial();
}

/// Loading state
class DeliveryReceiptLoading extends DeliveryReceiptState {
  const DeliveryReceiptLoading();
}

/// State when delivery receipt is loaded successfully
class DeliveryReceiptLoaded extends DeliveryReceiptState {
  final DeliveryReceiptEntity deliveryReceipt;
  final bool isFromCache;

  const DeliveryReceiptLoaded({
    required this.deliveryReceipt,
    this.isFromCache = false,
  });

  @override
  List<Object?> get props => [deliveryReceipt, isFromCache];
}

/// State when multiple delivery receipts are loaded
class DeliveryReceiptsLoaded extends DeliveryReceiptState {
  final List<DeliveryReceiptEntity> deliveryReceipts;
  final bool isFromCache;

  const DeliveryReceiptsLoaded({
    required this.deliveryReceipts,
    this.isFromCache = false,
  });

  @override
  List<Object?> get props => [deliveryReceipts, isFromCache];
}

/// State when delivery receipt is created successfully
class DeliveryReceiptCreated extends DeliveryReceiptState {
  final DeliveryReceiptEntity deliveryReceipt;
  final String deliveryDataId;

  const DeliveryReceiptCreated({
    required this.deliveryReceipt,
    required this.deliveryDataId,
  });

  @override
  List<Object?> get props => [deliveryReceipt, deliveryDataId];
}

/// State when delivery receipt is deleted successfully
class DeliveryReceiptDeleted extends DeliveryReceiptState {
  final String receiptId;

  const DeliveryReceiptDeleted(this.receiptId);

  @override
  List<Object?> get props => [receiptId];
}

/// State when delivery receipt is cached successfully
class DeliveryReceiptCached extends DeliveryReceiptState {
  final String receiptId;

  const DeliveryReceiptCached(this.receiptId);

  @override
  List<Object?> get props => [receiptId];
}

/// State when all local delivery receipts are cleared
class DeliveryReceiptsCleared extends DeliveryReceiptState {
  const DeliveryReceiptsCleared();
}

/// Error state
class DeliveryReceiptError extends DeliveryReceiptState {
  final String message;
  final String? errorCode;

  const DeliveryReceiptError({
    required this.message,
    this.errorCode,
  });

  @override
  List<Object?> get props => [message, errorCode];
}

/// State when no delivery receipt is found
class DeliveryReceiptNotFound extends DeliveryReceiptState {
  final String searchId;
  final String searchType; // 'tripId' or 'deliveryDataId'

  const DeliveryReceiptNotFound({
    required this.searchId,
    required this.searchType,
  });

  @override
  List<Object?> get props => [searchId, searchType];
}

/// State when operation is successful but with warnings
class DeliveryReceiptOperationSuccess extends DeliveryReceiptState {
  final String message;
  final DeliveryReceiptEntity? deliveryReceipt;

  const DeliveryReceiptOperationSuccess({
    required this.message,
    this.deliveryReceipt,
  });

  @override
  List<Object?> get props => [message, deliveryReceipt];
}

/// State for offline operations
class DeliveryReceiptOfflineOperation extends DeliveryReceiptState {
  final String message;
  final DeliveryReceiptEntity? deliveryReceipt;
  final String operationType; // 'create', 'update', 'delete'

  const DeliveryReceiptOfflineOperation({
    required this.message,
    required this.operationType,
    this.deliveryReceipt,
  });

  @override
  List<Object?> get props => [message, operationType, deliveryReceipt];
}

class DeliveryReceiptSynced extends DeliveryReceiptState {
  final DeliveryReceiptEntity deliveryReceipt;
  final String deliveryDataId;

  const DeliveryReceiptSynced({
    required this.deliveryReceipt,
    required this.deliveryDataId,
  });

  @override
  List<Object> get props => [deliveryReceipt, deliveryDataId];
}


class DeliveryReceiptPdfGenerated extends DeliveryReceiptState {
  final Uint8List pdfBytes;
  final String deliveryDataId;

  const DeliveryReceiptPdfGenerated({
    required this.pdfBytes,
    required this.deliveryDataId,
  });

  @override
  List<Object?> get props => [pdfBytes, deliveryDataId];
}

/// State when PDF generation is in progress
class DeliveryReceiptPdfGenerating extends DeliveryReceiptState {
  final String deliveryDataId;

  const DeliveryReceiptPdfGenerating(this.deliveryDataId);

  @override
  List<Object?> get props => [deliveryDataId];
}
