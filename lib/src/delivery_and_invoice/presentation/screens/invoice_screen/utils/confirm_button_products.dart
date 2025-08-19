import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/delivery_data/presentation/bloc/delivery_data_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/delivery_data/presentation/bloc/delivery_data_state.dart';
import 'package:x_pro_delivery_app/core/common/widgets/rounded_%20button.dart';

import '../../../../../../core/common/app/features/Trip_Ticket/delivery_data/domain/entity/delivery_data_entity.dart';

class ConfirmButtonProducts extends StatelessWidget {
  final String invoiceId;
  final String deliveryDataId;
  final String invoiceNumber;

  const ConfirmButtonProducts({
    super.key,
    required this.invoiceId,
    required this.deliveryDataId,
    required this.invoiceNumber,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DeliveryDataBloc, DeliveryDataState>(
      builder: (context, state) {
        final isUnloading = _checkIfUnloading(state);

        debugPrint('🔍 Button state check:');
        debugPrint('   🆔 Invoice ID: $invoiceId');
        debugPrint('   📦 Delivery Data ID: $deliveryDataId');
        debugPrint('   🔢 Invoice Number: $invoiceNumber');
        debugPrint('   📋 Current State: ${state.runtimeType}');
        debugPrint('   🚛 Is Unloading: $isUnloading');

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: SafeArea(
            child: RoundedButton(
              label:
                  isUnloading
                      ? 'Proceed to Order Summary'
                      : 'Waiting for Unloading...',
              onPressed: isUnloading ? () => _handleProceed(context) : null,
              buttonColour:
                  isUnloading
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.3),
              icon: Icon(
                isUnloading
                    ? Icons.check_circle_outline
                    : Icons.hourglass_empty,
                color:
                    isUnloading
                        ? Theme.of(context).colorScheme.surface
                        : Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.5),
              ),
            ),
          ),
        );
      },
    );
  }

  bool _checkIfUnloading(DeliveryDataState state) {
    debugPrint(
      '🔍 Checking unloading status for delivery data: $deliveryDataId',
    );

    // Check if we have delivery data loaded (list)
    if (state is DeliveryDataLoaded) {
      // Check if deliveryDataList is a List
      if (state.deliveryData is List<DeliveryDataEntity>) {
        final deliveryDataList = state.deliveryData as List<DeliveryDataEntity>;
        try {
          final deliveryData = deliveryDataList.firstWhere(
            (data) => data.id == deliveryDataId,
          );

          final isUnloading = _hasUnloadingStatus(deliveryData);
          debugPrint('✅ Found delivery data in list');
          debugPrint('🚛 Has unloading status: $isUnloading');
          return isUnloading;
        } catch (e) {
          debugPrint('⚠️ Delivery data not found in loaded list: $e');
        }
      } else {
        // If it's a single entity, check if it matches our ID
        final deliveryData = state.deliveryData;
        if (deliveryData.id == deliveryDataId) {
          final isUnloading = _hasUnloadingStatus(deliveryData);
          debugPrint('✅ Found single delivery data');
          debugPrint('🚛 Has unloading status: $isUnloading');
          return isUnloading;
        }
      }
    }

    // Check if we have a single delivery data loaded by ID
    if (state is DeliveryDataLoaded &&
        state.deliveryData.id == deliveryDataId) {
      final isUnloading = _hasUnloadingStatus(state.deliveryData);
      debugPrint('✅ Found single delivery data by ID');
      debugPrint('🚛 Has unloading status: $isUnloading');
      return isUnloading;
    }

    // Check if invoice was just set to unloading

    debugPrint('❌ No matching delivery data found or not in unloading status');
    return false;
  }

  bool _hasUnloadingStatus(DeliveryDataEntity deliveryData) {
    debugPrint('🔍 Checking delivery updates for unloading status');
    debugPrint(
      '   📦 Number of delivery updates: ${deliveryData.deliveryUpdates.length}',
    );

    // Check if any delivery update has "Unloading" status
    for (int i = 0; i < deliveryData.deliveryUpdates.length; i++) {
      final update = deliveryData.deliveryUpdates[i];
      final title = update.title?.toLowerCase().trim();
      debugPrint(
        '   📋 Update ${i + 1}: "${update.title}" (normalized: "$title")',
      );

      if (title == 'unloading') {
        debugPrint('✅ Found unloading status in delivery updates');
        return true;
      }
    }

    // Also check the latest delivery update
    if (deliveryData.deliveryUpdates.isNotEmpty) {
      final latestUpdate = deliveryData.deliveryUpdates.last;
      final latestTitle = latestUpdate.title?.toLowerCase().trim();
      debugPrint(
        '📍 Latest delivery update: "${latestUpdate.title}" (normalized: "$latestTitle")',
      );

      if (latestTitle == 'unloading') {
        debugPrint('✅ Latest update is unloading');
        return true;
      }
    }

    debugPrint('❌ No unloading status found in delivery updates');
    return false;
  }

  void _handleProceed(BuildContext context) {
    debugPrint('🚀 Navigating to order summary');
    debugPrint('   🆔 Invoice ID: $invoiceId');
    debugPrint('   📦 Delivery Data ID: $deliveryDataId');
    debugPrint('   🔢 Invoice Number: $invoiceNumber');

    // Navigate to confirmation screen with updated route
    context.push(
      '/confirm-order/$invoiceId/$deliveryDataId',
      extra: {
        'invoiceId': invoiceId,
        'deliveryDataId': deliveryDataId,
        'invoiceNumber': invoiceNumber,
      },
    );
  }
}
