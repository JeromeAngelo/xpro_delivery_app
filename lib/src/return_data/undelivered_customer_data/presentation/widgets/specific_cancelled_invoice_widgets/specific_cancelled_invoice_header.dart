import 'package:flutter/material.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/cancelled_invoices/domain/entity/cancelled_invoice_entity.dart';

class CancelledInvoiceHeaderWidget extends StatelessWidget {
  final CancelledInvoiceEntity cancelledInvoice;
  final VoidCallback? onViewImagePressed;

  const CancelledInvoiceHeaderWidget({
    super.key,
    required this.cancelledInvoice,
    this.onViewImagePressed,
  });

  @override
  Widget build(BuildContext context) {
    final customerName = cancelledInvoice.customer?.name ?? 'Unknown Customer';
   

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row: Customer name + optional view image button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    customerName,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                if (cancelledInvoice.image != null &&
                    cancelledInvoice.image!.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.image),
                    tooltip: 'View Image',
                    onPressed: onViewImagePressed,
                    style: IconButton.styleFrom(
                      foregroundColor:
                          Theme.of(context).colorScheme.primary,
                    ),
                  ),
              ],
            ),


           
          ],
        ),
      ),
    );
  }

  /// Builds a colored chip for cancellation reason

}
