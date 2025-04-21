import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/customer/domain/entity/customer_entity.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/invoice/domain/entity/invoice_entity.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/transaction/presentation/bloc/transaction_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/transaction/presentation/bloc/transaction_event.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/transaction/presentation/bloc/transaction_state.dart';
import 'package:x_pro_delivery_app/core/common/widgets/rounded_%20button.dart';
import 'package:x_pro_delivery_app/core/enums/invoice_status.dart';

class ConfirmBtn extends StatefulWidget {
  final List<InvoiceEntity> invoices;
  final CustomerEntity customer;

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
      child: BlocConsumer<TransactionBloc, TransactionState>(
        listener: (context, state) {
          if (state is PdfGenerated) {
            context.push(
              '/transaction/${widget.customer.id}',
              extra: {
                'customer': widget.customer,
                'selectedInvoices': widget.invoices,
                'generatedPdf': state.pdfBytes,
              },
            );
          }
          if (state is PdfGenerationError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          }
        },
        builder: (context, state) {
          final completedInvoices = widget.invoices
              .where((invoice) => invoice.status == InvoiceStatus.unloaded)
              .length;
          final totalInvoices = widget.invoices.length;
          final allInvoicesCompleted = completedInvoices == totalInvoices;

          return RoundedButton(
            label: state is PdfGenerating
                ? 'Generating PDF...'
                : 'Confirm Invoices ($completedInvoices/$totalInvoices)',
            onPressed: (!allInvoicesCompleted || state is PdfGenerating)
                ? () {} // Provide empty callback when disabled
                : () {
                    context.read<TransactionBloc>().add(
                          GenerateTransactionPdfEvent(
                            customer: widget.customer,
                            invoices: widget.invoices,
                          ),
                        );
                  },
            buttonColour: allInvoicesCompleted
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.errorContainer,
            icon: Icon(
              Icons.edit_document,
              color: Theme.of(context).colorScheme.surface,
            ),
          );
        },
      ),
    );
  }
}
