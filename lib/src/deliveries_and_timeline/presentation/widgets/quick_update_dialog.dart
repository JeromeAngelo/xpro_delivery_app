import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_data/delivery_update/presentation/bloc/delivery_update_event.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_data/delivery_update/presentation/bloc/delivery_update_state.dart';
import 'package:x_pro_delivery_app/core/common/widgets/status_icons.dart';
import '../../../../core/common/app/features/delivery_data/delivery_update/presentation/bloc/delivery_update_bloc.dart';

class QuickUpdateDialog extends StatelessWidget {
  final List<String> selectedDeliveryIds;

  const QuickUpdateDialog({super.key, required this.selectedDeliveryIds});

  @override
  Widget build(BuildContext context) {
    // Trigger bulk status choices load when dialog is built
    context.read<DeliveryUpdateBloc>().add(
      LoadLocalBulkDeliveryStatusChoicesEvent(selectedDeliveryIds),
    );
    context.read<DeliveryUpdateBloc>().add(
      GetBulkDeliveryStatusChoicesEvent(selectedDeliveryIds),
    );

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: BlocConsumer<DeliveryUpdateBloc, DeliveryUpdateState>(
        listenWhen:
            (previous, current) =>
                current is DeliveryStatusUpdateSuccess ||
                current is BulkDeliveryStatusUpdateSuccess ||
                current is DeliveryUpdateError,
        listener: (context, state) {
          if (state is DeliveryStatusUpdateSuccess ||
              state is BulkDeliveryStatusUpdateSuccess) {
            Navigator.of(context).pop(true); // ✅ close dialog on success
          }
          if (state is DeliveryUpdateError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Update failed: ${state.message}")),
            );
          }
        },
        buildWhen:
            (previous, current) =>
                current is BulkDeliveryStatusChoicesLoaded ||
                current is DeliveryUpdateLoading,
        builder: (context, state) {
          if (state is BulkDeliveryStatusChoicesLoaded) {
            final choicesMap = state.bulkStatusChoices;

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
                          context.read<DeliveryUpdateBloc>().add(
                            BulkUpdateDeliveryStatusEvent(
                              customerIds: selectedDeliveryIds,
                              statusId: status.id!, // ✅ bulk update params
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
