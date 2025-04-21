import 'package:flutter/material.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/completed_customer/domain/entity/completed_customer_entity.dart';
import 'package:x_pro_delivery_app/core/enums/mode_of_payment.dart';

class PaymentSorter {
  final List<CompletedCustomerEntity> customers;

  PaymentSorter(this.customers);

  Map<ModeOfPayment, double> getTotalsByPaymentMode() {
    final totals = <ModeOfPayment, double>{};
    
    for (var customer in customers) {
      debugPrint('Processing ${customer.storeName}: ${customer.paymentSelection}');
      
      final mode = customer.paymentSelection;
      final currentTotal = totals[mode] ?? 0.0;
      totals[mode] = currentTotal + (customer.totalAmount ?? 0.0);
    }

    return totals;
  }
}
