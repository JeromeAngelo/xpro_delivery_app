import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/invoice_preset_group/domain/entity/invoice_preset_group_entity.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/invoice_preset_group/presentation/bloc/invoice_preset_group_bloc.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/invoice_preset_group/presentation/bloc/invoice_preset_group_event.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/invoice_preset_group/presentation/bloc/invoice_preset_group_state.dart';
import 'package:xpro_delivery_admin_app/core/common/widgets/create_screen_widgets/dynamic_table.dart';
import 'package:xpro_delivery_admin_app/src/master_data/tripticket_screen/presentation/widget/create_trip_ticket_forms/processing_loading_widget.dart';

class InvoicePresetGroupTable extends StatefulWidget {
  final List<InvoicePresetGroupEntity> presetGroups;
  final String? deliveryId;

  const InvoicePresetGroupTable({
    super.key,
    required this.presetGroups,
    this.deliveryId,
  });

  @override
  State<InvoicePresetGroupTable> createState() =>
      _InvoicePresetGroupTableState();
}

class _InvoicePresetGroupTableState extends State<InvoicePresetGroupTable> {
  // Track multiple selected preset groups
  final Set<String> _selectedPresetGroupIds = {};

  @override
  void initState() {
    super.initState();
    // Debug print to verify data received
    debugPrint(
      '📊 InvoicePresetGroupTable initialized with ${widget.presetGroups.length} groups',
    );
  }

  @override
  Widget build(BuildContext context) {
    final headerStyle = TextStyle(
      fontWeight: FontWeight.bold,
      color: Colors.black, // or any color you prefer
    );
    // Add debug print to verify data at build time
    debugPrint(
      '🏗️ Building table with ${widget.presetGroups.length} preset groups',
    );

    return BlocBuilder<InvoicePresetGroupBloc, InvoicePresetGroupState>(
      builder: (context, state) {
        // Show loading widget when processing invoices to delivery
        if (state is InvoiceProcessingToDelivery) {
          return ProcessingLoadingWidget(
            message: 'Processing invoices to delivery...',
            currentInvoiceId: state.currentInvoiceId,
            currentProcessMessage: state.currentProcessMessage,
            currentIndex: state.currentIndex,
            totalInvoices: state.totalInvoices,
            onCancel: () {
              // Add cancel logic here if needed
            },
          );
        }

        return Column(
          children: [
            Expanded(
              child:
                  widget.presetGroups.isEmpty
                      ? const Center(
                        child: Text(
                          'No unassigned invoice preset groups found',
                        ),
                      )
                      : DynamicDataTable<InvoicePresetGroupEntity>(
                        data: widget.presetGroups,
                        isLoading: false,
                        columnBuilder:
                            (context) => [
                              DataColumn(
                                label: Text('Select', style: headerStyle),
                              ),
                              DataColumn(
                                label: Text('Ref ID', style: headerStyle),
                              ),
                              DataColumn(
                                label: Text('Name', style: headerStyle),
                              ),
                              DataColumn(
                                label: Text(
                                  'Invoice Count',
                                  style: headerStyle,
                                ),
                              ),
                              DataColumn(
                                label: Text('Created Date', style: headerStyle),
                              ),
                            ],
                        rowBuilder: (presetGroup, index) {
                          final isSelected = _selectedPresetGroupIds.contains(
                            presetGroup.id,
                          );

                          return DataRow(
                            selected: isSelected,
                            cells: [
                              DataCell(
                                Checkbox(
                                  value: isSelected,
                                  onChanged: (value) {
                                    setState(() {
                                      if (value == true) {
                                        _selectedPresetGroupIds.add(
                                          presetGroup.id!,
                                        );
                                      } else {
                                        _selectedPresetGroupIds.remove(
                                          presetGroup.id!,
                                        );
                                      }
                                    });
                                  },
                                ),
                              ),
                              DataCell(Text(presetGroup.refId ?? 'N/A')),
                              DataCell(Text(presetGroup.name ?? 'N/A')),
                              DataCell(
                                Text(presetGroup.invoices.length.toString()),
                              ),
                              DataCell(
                                Text(
                                  presetGroup.created != null
                                      ? '${presetGroup.created!.day}/${presetGroup.created!.month}/${presetGroup.created!.year}'
                                      : 'N/A',
                                ),
                              ),
                            ],
                          );
                        },
                        emptyMessage: 'No preset groups found',
                      ),
            ),
            const SizedBox(height: 16),
            BlocBuilder<InvoicePresetGroupBloc, InvoicePresetGroupState>(
              builder: (context, buttonState) {
                final isLoading =
                    buttonState is InvoicePresetGroupLoading ||
                    buttonState is InvoiceProcessingToDelivery;

                return ElevatedButton.icon(
                  onPressed:
                      (_selectedPresetGroupIds.isNotEmpty && !isLoading)
                          ? () {
                            debugPrint(
                              '🔘 Adding ${_selectedPresetGroupIds.length} preset groups to delivery ${widget.deliveryId}',
                            );

                            // Process each selected preset group
                            for (final presetGroupId
                                in _selectedPresetGroupIds) {
                              // Use the bloc to dispatch the event
                              context.read<InvoicePresetGroupBloc>().add(
                                AddAllInvoicesToDeliveryEvent(
                                  presetGroupId: presetGroupId,
                                  deliveryId: widget.deliveryId ?? '',
                                ),
                              );
                            }

                            // Clear selections after processing
                            setState(() {
                              _selectedPresetGroupIds.clear();
                            });
                          }
                          : null,
                  icon:
                      isLoading
                          ? Container(
                            width: 24,
                            height: 24,
                            padding: const EdgeInsets.all(2.0),
                            child: const CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 3,
                            ),
                          )
                          : const Icon(Icons.add_circle_outline),
                  label: Text(
                    isLoading
                        ? 'Processing...'
                        : 'Add Selected Presets to Delivery',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(
                      double.infinity,
                      48,
                    ), // Full width button
                    disabledBackgroundColor: Colors.grey.shade300,
                    disabledForegroundColor: Colors.grey.shade600,
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }
}
