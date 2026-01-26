import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/delivery_data/presentation/bloc/delivery_data_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/delivery_data/presentation/bloc/delivery_data_state.dart';
import 'package:x_pro_delivery_app/core/common/widgets/rounded_%20button.dart';

import '../../../../../../core/common/app/features/trip_ticket/delivery_data/domain/entity/delivery_data_entity.dart';
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
      // ✅ Rebuild only when the unloading flag for THIS delivery can change
      buildWhen: (prev, curr) {
        final prevUnloading = _extractIsUnloading(prev);
        final currUnloading = _extractIsUnloading(curr);

        // If state type changed (loading -> loaded), allow rebuild
        if (prev.runtimeType != curr.runtimeType) return true;

        // If unloading flag changed, allow rebuild
        return prevUnloading != currUnloading;
      },
      builder: (context, state) {
        final isUnloading = _extractIsUnloading(state);

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
              // ✅ Correct label logic
              label: isUnloading
                  ? 'Proceed to Order Summary'
                  : 'Waiting for Unloading...',
              onPressed: isUnloading ? () => _handleProceed(context) : null,
              buttonColour: isUnloading
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
              icon: Icon(
                isUnloading
                    ? Icons.check_circle_outline
                    : Icons.hourglass_empty,
                color: isUnloading
                    ? Theme.of(context).colorScheme.surface
                    : Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
              ),
            ),
          ),
        );
      },
    );
  }

  // ✅ Single source of truth: read unloading from whatever state holds the data
  bool _extractIsUnloading(DeliveryDataState state) {
    debugPrint('🔍 Checking unloading status for deliveryDataId=$deliveryDataId');

    DeliveryDataEntity? delivery;

    // ✅ Most common: list by trip
    if (state is DeliveryDataByTripLoaded) {
      final match = state.deliveryData.where((d) => d.id == deliveryDataId);
      if (match.isNotEmpty) {
        delivery = match.first;
        debugPrint('✅ Found in DeliveryDataByTripLoaded list');
      } else {
        debugPrint('⚠️ Not found in DeliveryDataByTripLoaded list');
      }
    }

    // ✅ Single delivery loaded by ID
    if (delivery == null && state is DeliveryDataLoaded) {
      final d = state.deliveryData;
      if (d.id == deliveryDataId) {
        delivery = d;
        debugPrint('✅ Found in DeliveryDataLoaded single entity');
      } else {
        debugPrint('⚠️ DeliveryDataLoaded does not match id');
      }
    }

    if (delivery == null) {
      debugPrint('❌ No matching delivery data found in current state');
      return false;
    }

    final isUnloading = delivery.isUnloading == true;

    debugPrint('   📦 DeliveryData ID: ${delivery.id}');
    debugPrint('   📤 isUnloading: ${delivery.isUnloading}');
    debugPrint('✅ Computed isUnloading = $isUnloading');

    return isUnloading;
  }

  void _handleProceed(BuildContext context) {
    debugPrint('🚀 Navigating to order summary');
    debugPrint('   🆔 Invoice ID: $invoiceId');
    debugPrint('   📦 Delivery Data ID: $deliveryDataId');
    debugPrint('   🔢 Invoice Number: $invoiceNumber');

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
