import 'package:equatable/equatable.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/delivery_collection/domain/entity/collection_entity.dart';

abstract class CollectionsState extends Equatable {
  const CollectionsState();

  @override
  List<Object?> get props => [];
}

class CollectionsInitial extends CollectionsState {
  const CollectionsInitial();
}

class CollectionsLoading extends CollectionsState {
  const CollectionsLoading();
}

class CollectionsLoaded extends CollectionsState {
  final List<CollectionEntity> collections;
  final bool isFromCache;

  const CollectionsLoaded({
    required this.collections,
    this.isFromCache = false,
  });

  @override
  List<Object?> get props => [collections, isFromCache];
}

class CollectionLoaded extends CollectionsState {
  final CollectionEntity collection;
  final bool isFromCache;

  const CollectionLoaded({
    required this.collection,
    this.isFromCache = false,
  });

  @override
  List<Object?> get props => [collection, isFromCache];
}

class CollectionDeleted extends CollectionsState {
  final String collectionId;

  const CollectionDeleted(this.collectionId);

  @override
  List<Object?> get props => [collectionId];
}

class CollectionsError extends CollectionsState {
  final String message;
  final String? errorCode;

  const CollectionsError({
    required this.message,
    this.errorCode,
  });

  @override
  List<Object?> get props => [message, errorCode];
}

class CollectionsEmpty extends CollectionsState {
  final String tripId;

  const CollectionsEmpty(this.tripId);

  @override
  List<Object?> get props => [tripId];
}

class CollectionsOffline extends CollectionsState {
  final List<CollectionEntity> collections;
  final String message;

  const CollectionsOffline({
    required this.collections,
    required this.message,
  });

  @override
  List<Object?> get props => [collections, message];
}
