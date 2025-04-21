import 'dart:typed_data';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/customer/domain/entity/customer_entity.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/invoice/domain/entity/invoice_entity.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/transaction/domain/repo/transaction_repo.dart';
import 'package:x_pro_delivery_app/core/usecases/usecase.dart';
import 'package:x_pro_delivery_app/core/utils/typedefs.dart';

class GenerateTransactionPdf implements UsecaseWithParams<Uint8List, GeneratePdfParams> {
  const GenerateTransactionPdf(this._repo);

  final TransactionRepo _repo;

  @override
  ResultFuture<Uint8List> call(GeneratePdfParams params) async {
    return _repo.generateTransactionPdf(
      params.customer,
      params.invoices,
    );
  }
}

class GeneratePdfParams {
  final CustomerEntity customer;
  final List<InvoiceEntity> invoices;

  const GeneratePdfParams({
    required this.customer,
    required this.invoices,
  });
}
