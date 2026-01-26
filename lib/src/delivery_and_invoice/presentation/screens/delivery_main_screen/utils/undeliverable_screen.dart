import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/cancelled_invoices/presentation/bloc/cancelled_invoice_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/cancelled_invoices/presentation/bloc/cancelled_invoice_event.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/cancelled_invoices/presentation/bloc/cancelled_invoice_state.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/delivery_data/domain/entity/delivery_data_entity.dart';
import 'package:x_pro_delivery_app/core/enums/undeliverable_reason.dart';

import '../../../../../../core/common/app/features/delivery_status_choices/domain/entity/delivery_status_choices_entity.dart';
import '../../../../../../core/common/app/features/delivery_status_choices/presentation/bloc/delivery_status_choices_bloc.dart';
import '../../../../../../core/common/app/features/delivery_status_choices/presentation/bloc/delivery_status_choices_event.dart';

class UndeliverableScreen extends StatefulWidget {
  final DeliveryDataEntity customer;
  final DeliveryStatusChoicesEntity statusId;

  const UndeliverableScreen({
    super.key,
    required this.customer,
    required this.statusId,
  });

  @override
  State<UndeliverableScreen> createState() => _UndeliverableScreenState();
}

class _UndeliverableScreenState extends State<UndeliverableScreen> {
  final List<XFile> _images = [];
  final ImagePicker _picker = ImagePicker();
  UndeliverableReason _selectedReason = UndeliverableReason.none;

  bool _isFormValid() {
    return _images.isNotEmpty && _selectedReason != UndeliverableReason.none;
  }

  // ------------------------------------------------------------
  // 📷 PICK IMAGE (CAMERA ONLY)
  // ------------------------------------------------------------
  Future<void> _pickImages() async {
    try {
      final XFile? photo = await _picker.pickImage(source: ImageSource.camera);
      if (photo != null) {
        setState(() => _images.add(photo));
      }
    } catch (e) {
      debugPrint('❌ Image pick error: $e');
    }
  }

  // ------------------------------------------------------------
  // 💾 SAVE UNDELIVERED (CREATE + UPDATE STATUS)
  // ------------------------------------------------------------
  void _saveUndeliveredInvoice() {
    final deliveryDataId = widget.customer.id;

    if (deliveryDataId == null) {
      _showError('Missing delivery data ID');
      return;
    }

    debugPrint('📝 Creating cancelled invoice');
    debugPrint('📋 Reason: $_selectedReason');
    debugPrint('📷 Images: ${_images.length}');

    context.read<CancelledInvoiceBloc>().add(
      CreateCancelledInvoiceByDeliveryDataIdEvent(
        deliveryDataId: deliveryDataId,
        reason: _selectedReason,
        image: _images.first.path,
      ),
    );
  }

  // ------------------------------------------------------------
  // 🔄 UPDATE DELIVERY STATUS
  // ------------------------------------------------------------
  void _updateDeliveryStatus() {
    context.read<DeliveryStatusChoicesBloc>().add(
      UpdateCustomerStatusEvent(
        deliveryDataId: widget.customer.id ?? '',
        status: widget.statusId,
      ),
    );
  }

  // ------------------------------------------------------------
  // 🚀 NAVIGATION
  // ------------------------------------------------------------
  void _navigateBack() {
    context.go(
      '/delivery-and-invoice/${widget.customer.id}',
      extra: widget.customer,
    );
  }

  // ------------------------------------------------------------
  // ❌ ERROR UI
  // ------------------------------------------------------------
  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(backgroundColor: Colors.red, content: Text(message)),
    );
  }

  // ------------------------------------------------------------
  // 🖼 IMAGE UI
  // ------------------------------------------------------------
  Widget _buildImageContainer() {
    return Container(
      height: 200,
      width: double.infinity,
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).colorScheme.outline),
        borderRadius: BorderRadius.circular(12),
      ),
      child:
          _images.isEmpty
              ? InkWell(
                onTap: _pickImages,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.add_a_photo, size: 48),
                      SizedBox(height: 8),
                      Text('Add Photo'),
                    ],
                  ),
                ),
              )
              : ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _images.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.all(8),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(
                        File(_images[index].path),
                        width: 180,
                        height: 180,
                        fit: BoxFit.cover,
                      ),
                    ),
                  );
                },
              ),
    );
  }

  Widget _buildReasonDropdown() {
    return DropdownButtonFormField<UndeliverableReason>(
      value: _selectedReason,
      decoration: const InputDecoration(labelText: 'Reason'),
      items:
          UndeliverableReason.values.map((reason) {
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

  /// Map enum to friendly display names
  String _getReasonDisplayName(UndeliverableReason reason) {
    switch (reason) {
      case UndeliverableReason.storeClosed:
        return 'Store Closed';
      case UndeliverableReason.customerNotAvailable:
        return 'Customer Not Available';
      case UndeliverableReason.environmentalIssues:
        return 'Environmental Issues';
      case UndeliverableReason.wrongInvoice:
        return 'Wrong Invoice';
      case UndeliverableReason.none:
        return 'Unspecified Reason';
    }
  }

  // ------------------------------------------------------------
  // 🧱 BUILD
  // ------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return BlocListener<CancelledInvoiceBloc, CancelledInvoiceState>(
      listener: (context, state) {
        if (state is CancelledInvoiceCreated) {
          debugPrint('✅ Cancelled invoice created');

          _updateDeliveryStatus();
          _navigateBack();
        }

        if (state is CancelledInvoiceError) {
          _showError(state.message);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Mark as Undelivered'),
          centerTitle: true,
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.customer.customer.target?.name ?? 'Customer',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              _buildImageContainer(),
              const SizedBox(height: 16),
              _buildReasonDropdown(),
              SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _navigateBack,
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  BlocBuilder<CancelledInvoiceBloc, CancelledInvoiceState>(
                    builder: (context, state) {
                      final isLoading = state is CancelledInvoiceLoading;

                      return ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              Theme.of(context).colorScheme.primary,
                        ),
                        onPressed:
                            _isFormValid() && !isLoading
                                ? _saveUndeliveredInvoice
                                : null,
                        child:
                            isLoading
                                ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                                : Text(
                                  'Save',
                                  style: const TextStyle(color: Colors.white),
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
}
