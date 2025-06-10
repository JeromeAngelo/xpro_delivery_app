import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/collection/domain/usecases/delete_collection.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/collection/domain/usecases/get_collection_by_id.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/collection/presentation/bloc/collections_event.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/collection/presentation/bloc/collections_state.dart';

import '../../domain/usecases/get_collection_by_trip_id.dart';

class CollectionsBloc extends Bloc<CollectionsEvent, CollectionsState> {
  final GetCollectionsByTripId _getCollectionsByTripId;
  final GetCollectionById _getCollectionById;
  final DeleteCollection _deleteCollection;

  CollectionsState? _cachedState;

  CollectionsBloc({
    required GetCollectionsByTripId getCollectionsByTripId,
    required GetCollectionById getCollectionById,
    required DeleteCollection deleteCollection,
  })  : _getCollectionsByTripId = getCollectionsByTripId,
        _getCollectionById = getCollectionById,
        _deleteCollection = deleteCollection,
        super(const CollectionsInitial()) {
    on<GetCollectionsByTripIdEvent>(_onGetCollectionsByTripId);
    on<GetLocalCollectionsByTripIdEvent>(_onGetLocalCollectionsByTripId);
    on<GetCollectionByIdEvent>(_onGetCollectionById);
    on<GetLocalCollectionByIdEvent>(_onGetLocalCollectionById);
    on<DeleteCollectionEvent>(_onDeleteCollection);
    on<RefreshCollectionsEvent>(_onRefreshCollections);
  }

  Future<void> _onGetCollectionsByTripId(
    GetCollectionsByTripIdEvent event,
    Emitter<CollectionsState> emit,
  ) async {
    debugPrint('🔄 BLoC: Fetching collections for trip: ${event.tripId}');
    
    emit(const CollectionsLoading());

    final result = await _getCollectionsByTripId(event.tripId);

    result.fold(
      (failure) {
        debugPrint('❌ BLoC: Failed to fetch collections: ${failure.message}');
        
        if (failure.message.contains('cache') || failure.message.contains('offline')) {
          emit(CollectionsError(
            message: 'Unable to load collections. Please check your connection.',
            errorCode: failure.statusCode,
          ));
        } else {
          emit(CollectionsError(
            message: failure.message,
            errorCode: failure.statusCode,
          ));
        }
      },
      (collections) {
        debugPrint('✅ BLoC: Successfully loaded ${collections.length} collections');
        
        if (collections.isEmpty) {
          emit(CollectionsEmpty(event.tripId));
        } else {
          final newState = CollectionsLoaded(
            collections: collections,
            isFromCache: false,
          );
          emit(newState);
          _cachedState = newState;
        }
      },
    );
  }

  Future<void> _onGetLocalCollectionsByTripId(
    GetLocalCollectionsByTripIdEvent event,
    Emitter<CollectionsState> emit,
  ) async {
    debugPrint('📦 BLoC: Fetching local collections for trip: ${event.tripId}');
    
    emit(const CollectionsLoading());

    final result = await _getCollectionsByTripId.loadFromLocal(event.tripId);

    result.fold(
      (failure) {
        debugPrint('❌ BLoC: Failed to fetch local collections: ${failure.message}');
        emit(CollectionsError(
          message: 'No offline data available',
          errorCode: failure.statusCode,
        ));
      },
      (collections) {
        debugPrint('✅ BLoC: Successfully loaded ${collections.length} local collections');
        
        if (collections.isEmpty) {
          emit(CollectionsEmpty(event.tripId));
        } else {
          emit(CollectionsOffline(
            collections: collections,
            message: 'Showing offline data',
          ));
        }
      },
    );
  }

  Future<void> _onGetCollectionById(
    GetCollectionByIdEvent event,
    Emitter<CollectionsState> emit,
  ) async {
    debugPrint('🔄 BLoC: Fetching collection by ID: ${event.collectionId}');
    
    emit(const CollectionsLoading());

    final result = await _getCollectionById(event.collectionId);

    result.fold(
      (failure) {
        debugPrint('❌ BLoC: Failed to fetch collection: ${failure.message}');
        emit(CollectionsError(
          message: failure.message,
          errorCode: failure.statusCode,
        ));
      },
      (collection) {
        debugPrint('✅ BLoC: Successfully loaded collection: ${collection.id}');
        emit(CollectionLoaded(
          collection: collection,
          isFromCache: false,
        ));
      },
    );
  }

  Future<void> _onGetLocalCollectionById(
    GetLocalCollectionByIdEvent event,
    Emitter<CollectionsState> emit,
  ) async {
    debugPrint('📦 BLoC: Fetching local collection by ID: ${event.collectionId}');
    
    emit(const CollectionsLoading());

    final result = await _getCollectionById.loadFromLocal(event.collectionId);

    result.fold(
      (failure) {
        debugPrint('❌ BLoC: Failed to fetch local collection: ${failure.message}');
        emit(CollectionsError(
          message: 'Collection not available offline',
          errorCode: failure.statusCode,
        ));
      },
      (collection) {
        debugPrint('✅ BLoC: Successfully loaded local collection: ${collection.id}');
        emit(CollectionLoaded(
          collection: collection,
          isFromCache: true,
        ));
      },
    );
  }

  Future<void> _onDeleteCollection(
    DeleteCollectionEvent event,
    Emitter<CollectionsState> emit,
  ) async {
    debugPrint('🗑️ BLoC: Deleting collection: ${event.collectionId}');
    
    emit(const CollectionsLoading());

    final result = await _deleteCollection(event.collectionId);

    result.fold(
      (failure) {
        debugPrint('❌ BLoC: Failed to delete collection: ${failure.message}');
        emit(CollectionsError(
          message: failure.message,
          errorCode: failure.statusCode,
        ));
      },
      (success) {
        debugPrint('✅ BLoC: Successfully deleted collection');
        emit(CollectionDeleted(event.collectionId));
      },
    );
  }

  Future<void> _onRefreshCollections(
    RefreshCollectionsEvent event,
    Emitter<CollectionsState> emit,
  ) async {
    debugPrint('🔄 BLoC: Refreshing collections for trip: ${event.tripId}');
    
    // Don't emit loading state for refresh to avoid UI flicker
    final result = await _getCollectionsByTripId(event.tripId);

    result.fold(
      (failure) {
        debugPrint('❌ BLoC: Refresh failed: ${failure.message}');
        // Keep current state if refresh fails
        if (_cachedState != null) {
          emit(_cachedState!);
        } else {
          emit(CollectionsError(
            message: failure.message,
            errorCode: failure.statusCode,
          ));
        }
      },
      (collections) {
        debugPrint('✅ BLoC: Successfully refreshed ${collections.length} collections');
        
        if (collections.isEmpty) {
          emit(CollectionsEmpty(event.tripId));
        } else {
          final newState = CollectionsLoaded(
            collections: collections,
            isFromCache: false,
          );
          emit(newState);
          _cachedState = newState;
        }
      },
    );
  }

  @override
  Future<void> close() {
    _cachedState = null;
    return super.close();
  }
}
