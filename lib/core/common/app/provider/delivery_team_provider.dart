// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:x_pro_delivery_app/core/common/app/features/Delivery_Team/delivery_team/domain/entity/delivery_team_entity.dart';
// import 'package:x_pro_delivery_app/core/common/app/features/Delivery_Team/delivery_team/domain/usecase/load_delivery_team.dart';

// final deliveryTeamProvider = StateNotifierProvider<DeliveryTeamNotifier, AsyncValue<DeliveryTeamEntity?>>((ref) {
//   return DeliveryTeamNotifier(ref.read(loadDeliveryTeamProvider));
// });

// final loadDeliveryTeamProvider = Provider((ref) => LoadDeliveryTeam(ref.read(deliveryTeamRepoProvider)));

// class DeliveryTeamNotifier extends StateNotifier<AsyncValue<DeliveryTeamEntity?>> {
//   final LoadDeliveryTeam _loadDeliveryTeam;

//   DeliveryTeamNotifier(this._loadDeliveryTeam) : super(const AsyncValue.loading()) {
//     loadInitialData();
//   }

//   Future<void> loadInitialData() async {
//     // Load local data first for instant UI update
//     final localResult = await _loadDeliveryTeam.loadFromLocal();
//     localResult.fold(
//       (failure) => state = AsyncValue.error(failure.message, StackTrace.current),
//       (deliveryTeam) => state = AsyncValue.data(deliveryTeam),
//     );

//     // Then fetch remote data in background
//     final remoteResult = await _loadDeliveryTeam();
//     remoteResult.fold(
//       (failure) {
//         // Keep existing data if remote fetch fails
//         if (state is! AsyncData) {
//           state = AsyncValue.error(failure.message, StackTrace.current);
//         }
//       },
//       (deliveryTeam) => state = AsyncValue.data(deliveryTeam),
//     );
//   }

//   Future<void> refreshDeliveryTeam() async {
//     state = const AsyncValue.loading();
//     final result = await _loadDeliveryTeam();
//     result.fold(
//       (failure) => state = AsyncValue.error(failure.message, StackTrace.current),
//       (deliveryTeam) => state = AsyncValue.data(deliveryTeam),
//     );
//   }

//   // Additional methods for specific delivery team operations can be added here
//   Future<void> updateDeliveryTeam(DeliveryTeamEntity updatedTeam) async {
//     // Update local state immediately for responsive UI
//     state = AsyncValue.data(updatedTeam);
//     // Additional logic for persisting updates can be added here
//   }
// }
