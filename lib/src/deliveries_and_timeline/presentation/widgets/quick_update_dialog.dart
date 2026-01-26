import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_status_choices/presentation/bloc/delivery_status_choices_event.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_status_choices/presentation/bloc/delivery_status_choices_state.dart';
import 'package:x_pro_delivery_app/core/common/widgets/status_icons.dart';
import '../../../../core/common/app/features/delivery_status_choices/presentation/bloc/delivery_status_choices_bloc.dart';

class QuickUpdateDialog extends StatelessWidget {
  final List<String> selectedDeliveryIds;

  const QuickUpdateDialog({super.key, required this.selectedDeliveryIds});

  @override
  Widget build(BuildContext context) {
    // Trigger bulk status choices load when dialog is built (offline-first)
    context.read<DeliveryStatusChoicesBloc>().add(
      GetAllBulkDeliveryStatusChoicesEvent(selectedDeliveryIds),
    );

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: BlocConsumer<
        DeliveryStatusChoicesBloc,
        DeliveryStatusChoicesState
      >(
        listenWhen:
            (previous, current) =>
                current is DeliveryStatusUpdated ||
                current is BulkDeliveryStatusUpdated ||
                current is DeliveryStatusChoicesError,
        listener: (context, state) {
          if (state is DeliveryStatusUpdated ||
              state is BulkDeliveryStatusUpdated) {
            Navigator.of(context).pop(true); // ✅ close dialog on success
          }
          if (state is DeliveryStatusChoicesError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Update failed: ${state.message}")),
            );
          }
        },
        buildWhen:
            (previous, current) =>
                current is BulkAssignedDeliveryStatusChoicesLoaded ||
                current is DeliveryStatusChoicesLoading,
        builder: (context, state) {
          if (state is BulkAssignedDeliveryStatusChoicesLoaded) {
            final choicesMap = state.choicesByCustomer;

            if (choicesMap.isEmpty) {
              return const Padding(
                padding: EdgeInsets.all(24.0),
                child: Center(child: Text("No statuses available")),
              );
            }

            // For bulk update, we only need the list of statuses (they are usually the same for each customer)
            // So take the first customer's statuses as the options
            final statuses = choicesMap.values.first;

            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "Bulk Update Status",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  ListView.separated(
                    shrinkWrap: true,
                    itemCount: statuses.length,
                    separatorBuilder: (_, __) => const Divider(),
                    itemBuilder: (context, index) {
                      final status = statuses[index];
                      return ListTile(
                        leading: Icon(
                          StatusIcons.getStatusIcon(status.title ?? ''),
                          color: Theme.of(context).colorScheme.primary,
                          size: 28,
                        ),
                        title: Text(status.title ?? 'N/A'),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () {
                          context.read<DeliveryStatusChoicesBloc>().add(
                            BulkUpdateDeliveryStatusEvent(
                              deliveryDataIds: selectedDeliveryIds,
                              status: status,
                            ),
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            );
          }

          // Default loading state
          return const Padding(
            padding: EdgeInsets.all(24.0),
            child: Center(child: CircularProgressIndicator()),
          );
        },
      ),
    );
  }
}
