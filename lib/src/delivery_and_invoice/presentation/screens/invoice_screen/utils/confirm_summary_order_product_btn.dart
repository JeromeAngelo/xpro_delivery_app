import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/delivery_data/presentation/bloc/delivery_data_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/delivery_data/presentation/bloc/delivery_data_event.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/delivery_data/presentation/bloc/delivery_data_state.dart';
import 'package:x_pro_delivery_app/core/common/widgets/rounded_%20button.dart';

class ConfirmSummaryOrderProductBtn extends StatelessWidget {
  final String deliveryDataId;
  final String title;
  final String amount;

  const ConfirmSummaryOrderProductBtn({
    super.key,
    required this.deliveryDataId,
    required this.title,
    required this.amount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge!.copyWith(fontWeight: FontWeight.bold),
                ),
                Text(
                  amount,
                  style: Theme.of(context).textTheme.titleLarge!.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            RoundedButton(
              label: 'Confirm Order',
              onPressed: () {
                debugPrint(
                  '✅ Order confirmed, navigating back to delivery view',
                );
                debugPrint('   📦 Delivery Data ID: $deliveryDataId');

                // Get the current delivery data from the bloc state
                final deliveryDataState =
                    context.read<DeliveryDataBloc>().state;

                if (deliveryDataState is DeliveryDataLoaded) {
                  // Navigate back to delivery and invoice view with the delivery data

                  context.read<DeliveryDataBloc>().add(
                    SetInvoiceIntoUnloadedEvent(deliveryDataId),
                  );
                  context.go(
                    '/delivery-and-invoice/$deliveryDataId',
                    extra: deliveryDataState.deliveryData,
                  );

                  // Show success message
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Order confirmed successfully!'),
                      backgroundColor: Colors.green,
                      duration: Duration(seconds: 2),
                    ),
                  );
                } else {
                  // If no data available, navigate without extra and let the screen load data
                  debugPrint(
                    '⚠️ No delivery data available in state, navigating without extra',
                  );
                  context.go('/delivery-and-invoice/$deliveryDataId');

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Order confirmed! Loading delivery data...',
                      ),
                      backgroundColor: Colors.green,
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              },
              buttonColour: Theme.of(context).colorScheme.primary,
              icon: Icon(
                Icons.check_circle,
                color: Theme.of(context).colorScheme.surface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
