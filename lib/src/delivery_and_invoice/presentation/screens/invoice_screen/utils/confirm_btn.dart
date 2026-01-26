import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/delivery_data/domain/entity/delivery_data_entity.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/delivery_data/presentation/bloc/delivery_data_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/delivery_data/presentation/bloc/delivery_data_state.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_data/invoice_data/domain/entity/invoice_data_entity.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_data/delivery_receipt/presentation/bloc/delivery_receipt_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_data/delivery_receipt/presentation/bloc/delivery_receipt_event.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_data/delivery_receipt/presentation/bloc/delivery_receipt_state.dart';
import 'package:x_pro_delivery_app/core/common/widgets/rounded_%20button.dart';

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
        // ✅ Only rebuild when "isUnloaded" for THIS customer can change
        buildWhen: (prev, curr) {
          final prevUnloaded = _extractIsUnloaded(prev);
          final currUnloaded = _extractIsUnloaded(curr);

          // if state type changes (loading -> loaded), rebuild
          if (prev.runtimeType != curr.runtimeType) return true;

          // if our computed flag changed, rebuild
          return prevUnloaded != currUnloaded;
        },
        builder: (context, deliveryDataState) {
          final isUnloaded = _extractIsUnloaded(deliveryDataState);

          debugPrint('🔍 ConfirmBtn state check:');
          debugPrint('   📦 Customer ID: ${widget.customer.id}');
          debugPrint('   📋 Delivery Data State: ${deliveryDataState.runtimeType}');
          debugPrint('   📤 Is Unloaded: $isUnloaded');

          return BlocConsumer<DeliveryReceiptBloc, DeliveryReceiptState>(
            listener: (context, state) {
              if (state is DeliveryReceiptPdfGenerated) {
                debugPrint(
                  '✅ PDF generated successfully, navigating to transaction',
                );
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
              final isGeneratingPdf =
                  receiptState is DeliveryReceiptPdfGenerating;

              // ✅ If unloaded is true, button must be usable again
              // The only disable condition should be "isGeneratingPdf"
              final canPress = isUnloaded && !isGeneratingPdf;

              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ✅ Show status message only while NOT unloaded
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
                            color: Theme.of(context)
                                .colorScheme
                                .onPrimaryContainer,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _getStatusMessage(deliveryDataState),
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall!
                                  .copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onPrimaryContainer,
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
                    onPressed: canPress ? () => _handleConfirmInvoices(context) : null,
                    buttonColour: canPress
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.surfaceVariant,
                    labelColour: canPress
                        ? Theme.of(context).colorScheme.onPrimary
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                    isLoading: isGeneratingPdf,
                    icon: canPress
                        ? Icon(
                            Icons.edit_document,
                            color: Theme.of(context).colorScheme.onPrimary,
                          )
                        : null,
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  // ✅ Robust read for isUnloaded based on current DeliveryDataBloc state
  bool _extractIsUnloaded(DeliveryDataState state) {
    final id = (widget.customer.id ?? '').toString().trim();
    if (id.isEmpty) {
      debugPrint('⚠️ Customer id is empty, cannot compute isUnloaded');
      return false;
    }

    debugPrint('🔍 Checking isUnloaded for deliveryDataId=$id');

    DeliveryDataEntity? delivery;

    // 1️⃣ Trip list state
    if (state is DeliveryDataByTripLoaded) {
      final match = state.deliveryData.where((d) => d.id == id);
      if (match.isNotEmpty) {
        delivery = match.first;
        debugPrint('✅ Found in DeliveryDataByTripLoaded list');
      } else {
        debugPrint('⚠️ Not found in DeliveryDataByTripLoaded list');
      }
    }

    // 2️⃣ Single loaded
    if (delivery == null && state is DeliveryDataLoaded) {
      if (state.deliveryData.id == id) {
        delivery = state.deliveryData;
        debugPrint('✅ Found in DeliveryDataLoaded single entity');
      } else {
        debugPrint('⚠️ DeliveryDataLoaded does not match id');
      }
    }

    // 3️⃣ Local/offline optimistic state you already emit
    if (delivery == null && state is InvoiceSetToUnloading) {
      if (state.deliveryDataId == id) {
        delivery = state.deliveryData;
        debugPrint('✅ Found in InvoiceSetToUnloading state');
      } else {
        debugPrint('⚠️ InvoiceSetToUnloading does not match id');
      }
    }

    if (delivery == null) {
      debugPrint('❌ No matching delivery in state → isUnloaded=false');
      return false;
    }

    final isUnloaded = delivery.isUnloaded == true;

    debugPrint('   📦 Delivery ID: ${delivery.id}');
    debugPrint('   📤 isUnloaded: ${delivery.isUnloaded}');
    debugPrint('✅ Computed isUnloaded = $isUnloaded');

    return isUnloaded;
  }

  String _getStatusMessage(DeliveryDataState state) {
    // Keep it simple + consistent with the same resolver
    final isUnloaded = _extractIsUnloaded(state);
    return isUnloaded
        ? 'Delivery has been unloaded. You may now confirm invoices.'
        : 'Waiting for unloading to complete.';
  }

  void _handleConfirmInvoices(BuildContext context) {
    final customerData = widget.customer;

    debugPrint('🔄 Starting invoice confirmation');
    debugPrint('   📦 deliveryDataId=${customerData.id}');
    debugPrint('   📄 invoicesCount=${widget.invoices.length}');

    context.read<DeliveryReceiptBloc>().add(
          GenerateDeliveryReceiptPdfEvent(customerData),
        );
  }

  void _navigateToTransaction(BuildContext context, pdfBytes) {
    final customerData = widget.customer;

    debugPrint('🚀 Navigating to transaction with generated PDF');
    debugPrint('   📦 deliveryDataId=${customerData.id}');
    debugPrint('   📄 invoicesCount=${widget.invoices.length}');

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
