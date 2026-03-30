import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_status_choices/domain/entity/delivery_status_choices_entity.dart';

import '../../../../../../core/common/app/features/delivery_data/delivery_update/domain/entity/delivery_update_entity.dart';
import '../../../../../../core/common/app/features/delivery_status_choices/presentation/bloc/delivery_status_choices_bloc.dart';
import '../../../../../../core/common/app/features/delivery_status_choices/presentation/bloc/delivery_status_choices_event.dart';
import '../../../../../../core/common/app/features/delivery_status_choices/presentation/bloc/delivery_status_choices_state.dart';
import '../../../../../../core/common/app/features/trip_ticket/delivery_data/domain/entity/delivery_data_entity.dart';

class RevertDeliveryStatusScreen extends StatefulWidget {
  final DeliveryDataEntity deliveryData;
  final DeliveryStatusChoicesEntity? deliveryStatus;
  final bool embedInParent;

  const RevertDeliveryStatusScreen({
    super.key,
    required this.deliveryData,
    this.deliveryStatus,
    this.embedInParent = false,
  });

  @override
  State<RevertDeliveryStatusScreen> createState() =>
      _RevertDeliveryStatusScreenState();
}

class _RevertDeliveryStatusScreenState
    extends State<RevertDeliveryStatusScreen> {
  String? _selectedStatus;
  final TextEditingController _reasonController = TextEditingController();

  bool _hasRequestedStatuses = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAssignedStatuses();
    });
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  String _getCurrentDeliveryStatus(DeliveryDataEntity deliveryData) {
    if (deliveryData.deliveryUpdates.isEmpty) return 'N/A';

    final sortedUpdates = List<DeliveryUpdateEntity>.from(
      deliveryData.deliveryUpdates,
    );

    sortedUpdates.sort((a, b) {
      final timeA = a.time ?? a.created ?? DateTime(0);
      final timeB = b.time ?? b.created ?? DateTime(0);
      return timeB.compareTo(timeA);
    });

    return sortedUpdates.first.title ?? 'N/A';
  }

  List<String> _getRevertStatuses(DeliveryDataEntity deliveryData) {
    final sortedUpdates = List<DeliveryUpdateEntity>.from(
      deliveryData.deliveryUpdates,
    );

    sortedUpdates.sort((a, b) {
      final timeA = a.time ?? a.created ?? DateTime(0);
      final timeB = b.time ?? b.created ?? DateTime(0);
      return timeB.compareTo(timeA);
    });

    if (sortedUpdates.length < 2) {
      return [];
    }

    final secondLatest = sortedUpdates[1].title;
    return secondLatest != null && secondLatest.isNotEmpty
        ? [secondLatest]
        : [];
  }

  void _loadAssignedStatuses() {
    if (_hasRequestedStatuses) return;
    if (widget.deliveryData.id == null) return;

    _hasRequestedStatuses = true;

    context.read<DeliveryStatusChoicesBloc>().add(
      GetAllAssignedDeliveryStatusChoicesEvent(widget.deliveryData.id!),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tripName = widget.deliveryData.trip.target?.name ?? 'N/A';
    final customerName = widget.deliveryData.storeName ?? 'N/A';
    final currentStatus = _getCurrentDeliveryStatus(widget.deliveryData);

    final content = SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// 🔷 DASHBOARD CARD
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _infoRow(Icons.tag, 'Picklist ID', tripName),
                  const SizedBox(height: 10),
                  _infoRow(Icons.description, 'Picklist Name', customerName),
                  const SizedBox(height: 10),
                  _infoRow(Icons.info, 'Current Status', currentStatus),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          /// 🔷 DROPDOWN
          Text(
            'Revert to status',
            style: theme.textTheme.titleMedium!.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),

          BlocBuilder<DeliveryStatusChoicesBloc, DeliveryStatusChoicesState>(
            builder: (context, state) {
              final isLoading = state is DeliveryStatusChoicesLoading;

              final historyStatuses = _getRevertStatuses(widget.deliveryData);

              return DropdownButtonFormField<String>(
                value: _selectedStatus,
                decoration: InputDecoration(
                  hintText: isLoading ? 'Loading...' : currentStatus,
                  prefixIcon: const Icon(Icons.swap_vert),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                items:
                    historyStatuses
                        .map(
                          (e) => DropdownMenuItem<String>(
                            value: e,
                            child: Text(e),
                          ),
                        )
                        .toList(),
                onChanged: (value) {
                  setState(() => _selectedStatus = value);
                },
              );
            },
          ),

          const SizedBox(height: 24),

          /// 🔷 REASON
          Text(
            'Reason for status change',
            style: theme.textTheme.titleMedium!.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),

          TextField(
            controller: _reasonController,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: 'Enter reason...',
              prefixIcon: const Icon(Icons.edit_note),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),

          const SizedBox(height: 24),

          /// 🔷 ACTIONS
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => context.pop(),
                child: const Text('Cancel'),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: () {
                  debugPrint(
                    'Revert → $_selectedStatus | reason: ${_reasonController.text}',
                  );

                  // TODO: call bloc here
                },
                icon: const Icon(Icons.history),
                label: const Text('Revert Status'),
              ),
            ],
          ),
        ],
      ),
    );

    if (widget.embedInParent) {
      return content;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Revert Delivery Status'),
        centerTitle: true,
      ),
      body: content,
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Icon(icon, color: theme.colorScheme.primary),
        const SizedBox(width: 10),
        Expanded(
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: '$label: ',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                TextSpan(text: value),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
