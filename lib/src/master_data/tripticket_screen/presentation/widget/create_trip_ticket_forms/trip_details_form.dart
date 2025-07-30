import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/customer_data/data/model/customer_data_model.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/customer_data/presentation/bloc/customer_data_bloc.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/customer_data/presentation/bloc/customer_data_event.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/delivery_data/data/model/delivery_data_model.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/invoice_data/data/model/invoice_data_model.dart';
import 'package:xpro_delivery_admin_app/core/common/widgets/create_screen_widgets/app_textfield.dart';
import 'package:xpro_delivery_admin_app/core/common/widgets/create_screen_widgets/form_title.dart';
import 'package:xpro_delivery_admin_app/src/master_data/tripticket_screen/presentation/widget/create_trip_ticket_forms/customer_invoice_table_result.dart';
import 'package:xpro_delivery_admin_app/src/master_data/tripticket_screen/presentation/widget/create_trip_ticket_forms/delivery_data_table.dart';
import 'package:xpro_delivery_admin_app/src/master_data/tripticket_screen/presentation/widget/create_trip_ticket_forms/invoice_preset_group_dialog.dart';

import 'customer_data_dialog.dart';

class TripDetailsForm extends StatefulWidget {
  final TextEditingController tripIdController;
  final TextEditingController qrCodeController;
  final TextEditingController tripNameController;
  final List<CustomerDataModel> selectedCustomers;
  final List<InvoiceDataModel> selectedInvoices;
  final List<DeliveryDataModel> selectedDeliveries;
  final Function(List<CustomerDataModel>) onCustomersChanged;
  final Function(List<InvoiceDataModel>) onInvoicesChanged;
  final Function(List<DeliveryDataModel>) onDeliveriesChanged;

  const TripDetailsForm({
    super.key,
    required this.tripIdController,
    required this.qrCodeController,
    required this.tripNameController,
    required this.selectedCustomers,
    required this.selectedInvoices,
    this.selectedDeliveries = const [],
    required this.onCustomersChanged,
    required this.onInvoicesChanged,
    required this.onDeliveriesChanged,
  });

  @override
  State<TripDetailsForm> createState() => _TripDetailsFormState();
}

class _TripDetailsFormState extends State<TripDetailsForm> {
  CustomerDataModel? _selectedCustomer;
  List<InvoiceDataModel> _selectedInvoices = [];
  List<DeliveryDataModel> _selectedDeliveries = [];

  @override
  void initState() {
    super.initState();
    // Load all customers when the form is initialized
    context.read<CustomerDataBloc>().add(GetAllUnassignedCustomerDataEvent());
    _selectedDeliveries = List.from(widget.selectedDeliveries);
  }

  void _showPresetGroupDialog() {
    showDialog(
      context: context,
      builder:
          (context) => InvoicePresetGroupDialog(
            deliveryId:
                _selectedDeliveries.isNotEmpty
                    ? _selectedDeliveries.first.id
                    : null,
            onPresetAdded: () {
              // Refresh delivery data after preset is added
              setState(() {
                // This will trigger a refresh of the delivery data table
              });
            },
          ),
    );
  }

  void _showCustomerDialog() {
    showDialog(
      context: context,
      builder:
          (context) => CustomerDataDialog(
            onCustomersSelected: (customers) {
              if (customers.isNotEmpty) {
                setState(() {
                  // For single customer selection, take the first one
                  // Or you can modify this to handle multiple customers
                  _selectedCustomer = customers.first as CustomerDataModel?;
                  // Clear previously selected invoices when customer changes
                  _selectedInvoices = [];
                });
              }
            },
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const FormSectionTitle(title: 'Trip Details'),

        // Trip ID and QR Code in a row
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left column: Trip ID and Trip Name
            Expanded(
              flex: 2,
              child: Column(
                children: [
                  // Trip ID field
                  AppTextField(
                    label: 'Trip ID',
                    controller: widget.tripIdController,
                    readOnly: true, // Auto-generated, so read-only
                  ),
                  
                  // Trip Name field
                  AppTextField(
                    label: 'Trip Name',
                    controller: widget.tripNameController,
                    hintText: 'Enter trip name (optional)',
                    required: false,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 24),

            // QR Code display
            Expanded(
              flex: 1,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text(
                    'Trip QR Code',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.2),
                          spreadRadius: 1,
                          blurRadius: 3,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(12),
                    child: QrImageView(
                      data: widget.qrCodeController.text,
                      version: QrVersions.auto,
                      size: 150,
                      backgroundColor: Colors.white,
                      errorStateBuilder: (context, error) {
                        return const Center(
                          child: Text(
                            'Error generating QR code',
                            style: TextStyle(color: Colors.red),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'QR Code Value: ${widget.qrCodeController.text}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 24),
        // Replace lines 149-166 with this code:
        SizedBox(
          width: 755,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Preset Group label
              SizedBox(
                width: 200,
                child: Padding(
                  padding: const EdgeInsets.only(top: 12.0),
                  child: RichText(
                    text: TextSpan(
                      text: 'Preset Group',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ),
                ),
              ),

              // Custom dropdown that shows dialog instead of dropdown items
              Expanded(
                child: InkWell(
                  onTap: _showPresetGroupDialog,
                  child: Container(
                    height: 56,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade400),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Select Preset Group',
                          style: TextStyle(color: Colors.grey),
                        ),
                        Icon(
                          Icons.arrow_drop_down,
                          color: Colors.grey.shade600,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Customer dropdown and tables in a row
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left column: Customer dropdown and Invoice table
            Expanded(
              flex: 1,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Customers dropdown
                  _buildCustomerDropdown(),

                  const SizedBox(height: 24),

                  // Invoices table
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 450,
                        child:
                            _selectedCustomer != null
                                ? CustomerInvoiceDataTableResult(
                                  customerId: _selectedCustomer!.id!,
                                  selectedInvoices: _selectedInvoices,
                                  onInvoicesChanged: (invoices) {
                                    setState(() {
                                      _selectedInvoices =
                                          invoices.map((invoice) {
                                            if (invoice is InvoiceDataModel) {
                                              return invoice;
                                            } else {
                                              return InvoiceDataModel(
                                                id: invoice.id,
                                                name: invoice.name,
                                                refId: invoice.refId,
                                                totalAmount:
                                                    invoice.totalAmount,
                                                documentDate:
                                                    invoice.documentDate,
                                                customer:
                                                    invoice.customer
                                                            is CustomerDataModel
                                                        ? invoice.customer
                                                            as CustomerDataModel
                                                        : null,
                                              );
                                            }
                                          }).toList();
                                    });

                                    widget.onInvoicesChanged(_selectedInvoices);
                                  },
                                )
                                : Card(
                                  child: Center(
                                    child: Text(
                                      'Select a customer to view invoices',
                                      style: TextStyle(color: Colors.grey[600]),
                                    ),
                                  ),
                                ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(width: 30),

            // Right column: Delivery Data table
            Expanded(
              flex: 1,
              child: Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Column(
                  children: [
                    DeliveryDataTable(
                      selectedDeliveries: _selectedDeliveries,
                      onDeliveriesChanged: (deliveries) {
                        setState(() {
                          _selectedDeliveries = deliveries;
                        });
                        widget.onDeliveriesChanged(deliveries);
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCustomerDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Customer', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        // Custom dropdown that shows dialog instead of dropdown items
        InkWell(
          onTap: _showCustomerDialog,
          child: Container(
            height: 56,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade400),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    _selectedCustomer?.name ?? 'Select Customer',
                    style: TextStyle(
                      color:
                          _selectedCustomer != null
                              ? Colors.black
                              : Colors.grey,
                    ),
                  ),
                ),
                Icon(Icons.arrow_drop_down, color: Colors.grey.shade600),
              ],
            ),
          ),
        ),
        if (_selectedCustomer != null) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Selected Customer Details:',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text('Ref ID: ${_selectedCustomer!.refId ?? 'N/A'}'),
                Text(
                  'Location: ${_selectedCustomer!.municipality ?? ''}, ${_selectedCustomer!.province ?? ''}',
                ),
                if (_selectedCustomer!.barangay != null)
                  Text('Barangay: ${_selectedCustomer!.barangay}'),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
