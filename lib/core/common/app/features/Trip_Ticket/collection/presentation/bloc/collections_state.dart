import 'package:equatable/equatable.dart';

import '../../domain/entity/collection_entity.dart';

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

class CollectionLoadedByTrip extends CollectionsState {
  final String tripId;
  final List<CollectionEntity> collections;
  const CollectionLoadedByTrip(this.tripId, {required this.collections});

  @override
  List<Object?> get props => [tripId];
}

class CollectionLoaded extends CollectionsState {
  final CollectionEntity collection;
  final bool isFromCache;

  const CollectionLoaded({required this.collection, this.isFromCache = false});

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

  const CollectionsError({required this.message, this.errorCode});

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

  const CollectionsOffline({required this.collections, required this.message});

  @override
  List<Object?> get props => [collections, message];
}

class AllCollectionsLoaded extends CollectionsState {
  final List<CollectionEntity> collections;
  final bool isFromCache;

  const AllCollectionsLoaded({
    required this.collections,
    this.isFromCache = false,
  });

  @override
  List<Object?> get props => [collections, isFromCache];
}

class CollectionsFilteredByDate extends CollectionsState {
  final List<CollectionEntity> collections;
  final DateTime startDate;
  final DateTime endDate;
  final bool isFromCache;

  const CollectionsFilteredByDate({
    required this.collections,
    required this.startDate,
    required this.endDate,
    this.isFromCache = false,
  });

  @override
  List<Object?> get props => [collections, startDate, endDate, isFromCache];
}
