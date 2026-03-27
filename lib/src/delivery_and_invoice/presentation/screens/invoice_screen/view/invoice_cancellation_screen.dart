import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../../core/common/app/features/trip_ticket/delivery_data/presentation/bloc/delivery_data_bloc.dart';
import '../../../../../../core/common/app/features/trip_ticket/delivery_data/presentation/bloc/delivery_data_event.dart';
import '../../../../../../core/common/app/features/trip_ticket/delivery_data/presentation/bloc/delivery_data_state.dart';
import '../../../../../../core/enums/invoice_cancellation_enums.dart';

class InvoiceCancellationScreen extends StatefulWidget {
  final String deliveryDataId;
  final String invoiceId;

  const InvoiceCancellationScreen({
    super.key,
    required this.deliveryDataId,
    required this.invoiceId,
  });

  @override
  State<InvoiceCancellationScreen> createState() =>
      _InvoiceCancellationScreenState();
}

class _InvoiceCancellationScreenState extends State<InvoiceCancellationScreen> {
  final TextEditingController _remarkController = TextEditingController();
  InvoiceCancellationReason _selectedReason = InvoiceCancellationReason.none;

  final List<String> _reasons = [
    'Customer Cancelled',
    'Out of Stock',
    'Wrong Order',
    'Delivery Failed',
  ];

  void _submitCancellation() {
    if (_selectedReason == InvoiceCancellationReason.none) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a reason'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    context.read<DeliveryDataBloc>().add(
      SetInvoiceIntoCancelledEvent(widget.deliveryDataId, widget.invoiceId),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<DeliveryDataBloc, DeliveryDataState>(
      listener: (context, state) {
        if (state is InvoiceSetToCancelled &&
            state.invoiceId == widget.invoiceId) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Invoice cancelled successfully'),
              backgroundColor: Colors.green,
            ),
          );
          context.pop(true);
        } else if (state is DeliveryDataError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to cancel invoice: ${state.message}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Cancel Invoice'), centerTitle: true),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// 🔹 INVOICE INFO
              Text(
                'Invoice ID: ${widget.invoiceId}',
                style: Theme.of(context).textTheme.titleMedium,
              ),

              const SizedBox(height: 16),

              _buildReasonDropdown(),

              const SizedBox(height: 16),

              /// 🔹 REMARK FIELD
              TextField(
                controller: _remarkController,
                decoration: InputDecoration(
                  labelText: 'Remarks (optional)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                maxLines: 3,
              ),

              const SizedBox(height: 24),

              /// 🔹 ACTION BUTTONS
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => context.pop(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  BlocBuilder<DeliveryDataBloc, DeliveryDataState>(
                    builder: (context, state) {
                      final isLoading = state is DeliveryDataLoading;

                      return ElevatedButton(
                        onPressed: isLoading ? null : _submitCancellation,
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              isLoading
                                  ? Colors.grey
                                  : Colors.red, // 🔥 cancel action color
                        ),
                        child:
                            isLoading
                                ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                                : const Text(
                                  'Cancel Invoice',
                                  style: TextStyle(color: Colors.white),
                                ),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Map enum to friendly display names
  String _getReasonDisplayName(InvoiceCancellationReason reason) {
    switch (reason) {
      case InvoiceCancellationReason.none:
        return 'Unspecified Reason';
      case InvoiceCancellationReason.customerRequest:
        return 'Customer Request';
      case InvoiceCancellationReason.duplicateInvoice:
        return 'Duplicate Invoice';
      case InvoiceCancellationReason.incorrectInvoice:
        return 'Incorrect Invoice';
      case InvoiceCancellationReason.other:
        return 'Other';
    }
  }

  Widget _buildReasonDropdown() {
    return DropdownButtonFormField<InvoiceCancellationReason>(
      value: _selectedReason,
      decoration: InputDecoration(
        labelText: 'Reason',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      items:
          InvoiceCancellationReason.values.map((reason) {
            return DropdownMenuItem(
              value: reason,
              child: Text(_getReasonDisplayName(reason)),
            );
          }).toList(),
      onChanged: (value) {
        if (value != null) {
          setState(() => _selectedReason = value);
        }
      },
    );
  }
}
