import 'package:equatable/equatable.dart';

abstract class CollectionsEvent extends Equatable {
  const CollectionsEvent();

  @override
  List<Object?> get props => [];
}

class GetCollectionsByTripIdEvent extends CollectionsEvent {
  final String tripId;

  const GetCollectionsByTripIdEvent(this.tripId);

  @override
  List<Object?> get props => [tripId];
}

class GetLocalCollectionsByTripIdEvent extends CollectionsEvent {
  final String tripId;

  const GetLocalCollectionsByTripIdEvent(this.tripId);

  @override
  List<Object?> get props => [tripId];
}

class GetCollectionByIdEvent extends CollectionsEvent {
  final String collectionId;

  const GetCollectionByIdEvent(this.collectionId);

  @override
  List<Object?> get props => [collectionId];
}

class GetLocalCollectionByIdEvent extends CollectionsEvent {
  final String collectionId;

  const GetLocalCollectionByIdEvent(this.collectionId);

  @override
  List<Object?> get props => [collectionId];
}

class DeleteCollectionEvent extends CollectionsEvent {
  final String collectionId;

  const DeleteCollectionEvent(this.collectionId);

  @override
  List<Object?> get props => [collectionId];
}

class RefreshCollectionsEvent extends CollectionsEvent {
  final String tripId;

  const RefreshCollectionsEvent(this.tripId);

  @override
  List<Object?> get props => [tripId];
}
