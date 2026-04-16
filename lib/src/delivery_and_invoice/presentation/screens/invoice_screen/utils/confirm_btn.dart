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
        // ✅ Only rebuild when latest status title for THIS customer can change
        builder: (context, deliveryDataState) {
          final canConfirm = _hasValidStatus(deliveryDataState);

          debugPrint('🔍 ConfirmBtn state check:');
          debugPrint('   📦 Customer ID: ${widget.customer.id}');
          debugPrint('   📋 Delivery Data State: ${deliveryDataState.runtimeType}');
          debugPrint('   📤 Can Confirm: $canConfirm');

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

              final canPress = canConfirm && !isGeneratingPdf;

              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  RoundedButton(
                    label: isGeneratingPdf
                        ? 'Generating PDF...'
                        : 'Confirm Invoices (${widget.invoices.length}/${widget.invoices.length})',
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

  // ✅ Check if latest delivery status title is "Unloading" or "mark as received"
  bool _hasValidStatus(DeliveryDataState state) {
    final id = (widget.customer.id ?? '').toString().trim();
    if (id.isEmpty) {
      debugPrint('⚠️ Customer id is empty, cannot check status');
      return false;
    }

    debugPrint('🔍 Checking latest status for deliveryDataId=$id');

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
      debugPrint('❌ No matching delivery in state → isUnloading=false');
      return false;
    }

    // Get the latest delivery update by time and check if its title is "Unloading"
    final updates = delivery.deliveryUpdates;
    if (updates.isEmpty) {
      debugPrint('❌ No delivery updates found → isUnloading=false');
      return false;
    }

    // Sort by time descending and get the latest
    final sortedUpdates = updates.toList()
      ..sort((a, b) {
        if (a.time == null && b.time == null) return 0;
        if (a.time == null) return 1;
        if (b.time == null) return -1;
        return b.time!.compareTo(a.time!);
      });

    final latestUpdate = sortedUpdates.first;
    final latestTitle = latestUpdate.title?.toLowerCase() ?? '';
    final isValidStatus = latestTitle == 'unloading' || latestTitle == 'mark as received';

    debugPrint('   📦 Delivery ID: ${delivery.id}');
    debugPrint('   📝 Latest status title: ${latestUpdate.title}');
    debugPrint('   🕐 Latest status time: ${latestUpdate.time}');
    debugPrint('✅ Computed canConfirm = $isValidStatus');

    return isValidStatus;
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
