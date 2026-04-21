import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/delivery_data/domain/entity/delivery_data_entity.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/delivery_data/presentation/bloc/delivery_data_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/delivery_data/presentation/bloc/delivery_data_state.dart';

class CustomerSummaryDialog extends StatefulWidget {
  final DeliveryDataEntity deliveryData;

  const CustomerSummaryDialog({super.key, required this.deliveryData});

  @override
  State<CustomerSummaryDialog> createState() => _CustomerSummaryDialogState();
}

class _CustomerSummaryDialogState extends State<CustomerSummaryDialog> {
  late DeliveryDataEntity _currentDeliveryData;

  @override
  void initState() {
    super.initState();
    _currentDeliveryData = widget.deliveryData;
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DeliveryDataBloc, DeliveryDataState>(
      buildWhen:
          (previous, current) =>
              current is DeliveryTimeCalculated ||
              current is DeliveryDataByIdWatched ||
              current is DeliveryDataLoaded ||
              previous is! DeliveryTimeCalculated,
      builder: (context, state) {
        // Update current delivery data if watch emits new data
        if (state is DeliveryDataByIdWatched && state.deliveryData != null) {
          _currentDeliveryData = state.deliveryData!;
          debugPrint(
            '📦 Dialog: Received updated delivery data with totalDeliveryTime: ${_currentDeliveryData.totalDeliveryTime}',
          );
        }

        // Priority: Use calculated time if available, otherwise use stored time
        final latestTime =
            state is DeliveryTimeCalculated
                ? _formatDeliveryTime(state.deliveryTimeInMinutes)
                : (_currentDeliveryData.totalDeliveryTime ?? 'Calculating...');

        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Delivery Summary',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: Icon(
                    Icons.store,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  title: Text(_currentDeliveryData.storeName ?? 'N/A'),
                  subtitle: const Text('Store Name'),
                ),
                ListTile(
                  leading: Icon(
                    Icons.timer,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  title: Text(
                    latestTime,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      color:
                          latestTime == 'Calculating...'
                              ? Theme.of(context).colorScheme.outline
                              : null,
                    ),
                  ),
                  subtitle: const Text('Total Delivery Time'),
                ),
                ListTile(
                  leading: Icon(
                    Icons.receipt_long,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  title: Text('${_currentDeliveryData.invoiceItems.length}'),
                  subtitle: const Text('Total Invoice Items'),
                ),

                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed:
                      () => context.pushReplacement('/delivery-and-timeline'),
                  child: const Text('Close'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatDeliveryTime(int minutes) {
    if (minutes <= 0) return '0 secs';

    final hours = minutes ~/ 60;
    final mins = minutes % 60;

    final parts = <String>[];

    if (hours > 0) {
      parts.add('${hours} hr${hours > 1 ? 's' : ''}');
    }

    if (mins > 0) {
      parts.add('${mins} min${mins > 1 ? 's' : ''}');
    }

    return parts.join(' and ');
  }
}
