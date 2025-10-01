import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/delivery_data/domain/entity/delivery_data_entity.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/delivery_data/presentation/bloc/delivery_data_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/delivery_data/presentation/bloc/delivery_data_state.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_data/invoice_data/domain/entity/invoice_data_entity.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_data/delivery_receipt/presentation/bloc/delivery_receipt_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_data/delivery_receipt/presentation/bloc/delivery_receipt_event.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_data/delivery_receipt/presentation/bloc/delivery_receipt_state.dart';
import 'package:x_pro_delivery_app/core/common/widgets/rounded_%20button.dart';
import 'package:x_pro_delivery_app/core/enums/invoice_status.dart';

class ConfirmBtn extends StatefulWidget {
  final List<InvoiceDataEntity> invoices;
  final DeliveryDataEntity customer;

  const ConfirmBtn({
    super.key,
    required this.invoices,
    required this.customer,
  });

  @override
  State<ConfirmBtn> createState() => _ConfirmBtnState();
}

class _ConfirmBtnState extends State<ConfirmBtn> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 5),
      child: BlocBuilder<DeliveryDataBloc, DeliveryDataState>(
        builder: (context, deliveryDataState) {
          final isUnloaded = _checkIfUnloaded(deliveryDataState);
          
          debugPrint('🔍 ConfirmBtn state check:');
          debugPrint('   📦 Customer ID: ${widget.customer.id}');
          debugPrint('   📋 Delivery Data State: ${deliveryDataState.runtimeType}');
          debugPrint('   📤 Is Unloaded: $isUnloaded');

          return BlocConsumer<DeliveryReceiptBloc, DeliveryReceiptState>(
            listener: (context, state) {
              if (state is DeliveryReceiptPdfGenerated) {
                debugPrint('✅ PDF generated successfully, navigating to transaction');
                _navigateToTransaction(context, state.pdfBytes);
              } else if (state is DeliveryReceiptError) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('PDF Generation Error: ${state.message}'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            builder: (context, receiptState) {
              final isGeneratingPdf = receiptState is DeliveryReceiptPdfGenerating;
              
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Show status message if not unloaded
                  if (!isUnloaded) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Theme.of(context).colorScheme.onPrimaryContainer,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _getStatusMessage(deliveryDataState),
                              style: Theme.of(context).textTheme.bodySmall!.copyWith(
                                color: Theme.of(context).colorScheme.onPrimaryContainer,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  
                  RoundedButton(
                    label: isGeneratingPdf 
                        ? 'Generating PDF...' 
                        : isUnloaded
                            ? 'Confirm Invoices (${widget.invoices.length}/${widget.invoices.length})'
                            : 'Waiting for Unloading to Complete...',
                    onPressed: (isGeneratingPdf || !isUnloaded) ? null : () => _handleConfirmInvoices(context),
                    buttonColour: (isGeneratingPdf || !isUnloaded)
                        ? Theme.of(context).colorScheme.surfaceVariant
                        : Theme.of(context).colorScheme.primary,
                    labelColour: (isGeneratingPdf || !isUnloaded)
                        ? Theme.of(context).colorScheme.onSurfaceVariant
                        : Theme.of(context).colorScheme.onPrimary,
                    isLoading: isGeneratingPdf,
                    icon: (isGeneratingPdf || !isUnloaded)
                        ? null 
                        : Icon(
                            Icons.edit_document,
                            color: Theme.of(context).colorScheme.onPrimary,
                          ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  bool _checkIfUnloaded(DeliveryDataState state) {
    debugPrint('🔍 Checking unloaded status for customer: ${widget.customer.id}');
    
    // Check if we have delivery data loaded (list)
    if (state is DeliveryDataLoaded) {
      final deliveryDataList = state.deliveryData;
      
      if (deliveryDataList.id == widget.customer.id) {
        final isUnloaded = deliveryDataList.invoiceStatus == InvoiceStatus.unloaded;
        debugPrint('✅ Found single delivery data with status: ${deliveryDataList.invoiceStatus?.name}');
        debugPrint('📤 Is unloaded: $isUnloaded');
        return isUnloaded;
      }
        }
    
    // Check if we have a single delivery data loaded by ID
    if (state is DeliveryDataLoaded && state.deliveryData.id == widget.customer.id) {
      final isUnloaded = state.deliveryData.invoiceStatus == InvoiceStatus.unloaded;
      debugPrint('✅ Found single delivery data with status: ${state.deliveryData.invoiceStatus?.name}');
      debugPrint('📤 Is unloaded: $isUnloaded');
      return isUnloaded;
    }
    
    // Check if invoice was just updated (could be set to unloaded)
    if (state is InvoiceSetToUnloading && state.deliveryDataId == widget.customer.id) {
      final isUnloaded = state.deliveryData.invoiceStatus == InvoiceStatus.unloaded;
      debugPrint('✅ Invoice status updated: $isUnloaded');
      return isUnloaded;
    }
    
    debugPrint('❌ No matching delivery data found or not in unloaded status');
    return false;
  }

  String _getStatusMessage(DeliveryDataState state) {
    if (state is DeliveryDataLoaded) {
      final deliveryDataList = state.deliveryData;
      
      if (deliveryDataList.id == widget.customer.id) {
        return _getMessageForStatus(deliveryDataList.invoiceStatus);
      }
        }
    
    return 'Please wait for the delivery to be unloaded before confirming invoices';
  }

  String _getMessageForStatus(InvoiceStatus? status) {
    switch (status) {
      case InvoiceStatus.none:
        return 'Invoice is pending processing';
      case InvoiceStatus.truck:
        return 'Invoice is in transit to destination';
      case InvoiceStatus.unloading:
        return 'Invoice is currently being unloaded';
      case InvoiceStatus.delivered:
        return 'Invoice has been completed';
      case InvoiceStatus.cancelled:
        return 'Invoice has been cancelled';
      default:
        return 'Waiting for unloading to complete';
    }
  }

  void _handleConfirmInvoices(BuildContext context) {
    final customerData = widget.customer;
    debugPrint('🔄 Starting invoice confirmation for customer: ${customerData.invoice}');
    debugPrint('📄 Generating PDF for delivery data: ${widget.customer.id}');
    
    // Generate PDF first using the delivery receipt BLoC
    context.read<DeliveryReceiptBloc>().add(
      GenerateDeliveryReceiptPdfEvent(widget.customer),
    );
  }

  void _navigateToTransaction(BuildContext context, pdfBytes) {
    final customerData = widget.customer;
    debugPrint('🚀 Navigating to transaction with generated PDF');
    
    context.push(
      '/transaction',
      extra: {
        'deliveryData': customerData,
        'generatedPdf': pdfBytes,
        'invoices': widget.invoices,
      },
    );
  }
}
