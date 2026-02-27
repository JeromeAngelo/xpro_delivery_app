import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/otp/domain/entity/otp_entity.dart';
import 'package:xpro_delivery_admin_app/core/common/widgets/app_structure/data_table_layout.dart';
import 'package:intl/intl.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/otp/presentation/bloc/otp_bloc.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/otp/presentation/bloc/otp_event.dart';

class TripOtpTable extends StatelessWidget {
  final List<OtpEntity> otps;
  final bool isLoading;
  final int currentPage;
  final int totalPages;
  final Function(int) onPageChanged;
  final String tripId; // Added tripId parameter

  const TripOtpTable({
    super.key,
    required this.otps,
    required this.isLoading,
    required this.currentPage,
    required this.totalPages,
    required this.onPageChanged,
    required this.tripId, // Required parameter
  });

  @override
  Widget build(BuildContext context) {
    return DataTableLayout(
      title: 'In-Transit OTP Data',
      onCreatePressed: () {
        // // Generate new OTP for this specific trip
        // context.read<OtpBloc>().add(GenerateOtpForTripEvent(tripId));
        // ScaffoldMessenger.of(context).showSnackBar(
        //   const SnackBar(
        //     content: Text('Generating new OTP for this trip...'),
        //     duration: Duration(seconds: 2),
        //   ),
        // );
      },
      createButtonText: 'Generate New OTP',
      columns: const [
       // DataColumn(label: Text('Id')),
        DataColumn(label: Text('OTP Code')),
        DataColumn(label: Text('Generated Code')),
        DataColumn(label: Text('Status')),
        DataColumn(label: Text('Odometer')),
        DataColumn(label: Text('Created')),
        DataColumn(label: Text('Expires')),
        DataColumn(label: Text('Actions')),
      ],
      rows:
          otps.map((otp) {
            return DataRow(
              cells: [
              //  DataCell(Text(otp.id)),
                // OTP Code cell with copy button
                DataCell(
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(otp.otpCode),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.copy, size: 16),
                        tooltip: 'Copy OTP Code',
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: otp.otpCode));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('OTP Code copied to clipboard'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                // Generated Code
                DataCell(Text(otp.generatedCode ?? 'N/A')),

                // OTP Type

                // Status
                DataCell(_buildStatusChip(otp.isVerified)),
                DataCell(Text(otp.intransitOdometer != null ? '${otp.intransitOdometer} km' : 'N/A')),

                // Created At
                DataCell(Text(_formatDate(otp.createdAt))),

                // Expires At
                DataCell(
                  Text(
                    _formatDate(otp.expiresAt),
                    style: TextStyle(
                      color: _isExpired(otp.expiresAt) ? Colors.red : null,
                      fontWeight:
                          _isExpired(otp.expiresAt) ? FontWeight.bold : null,
                    ),
                  ),
                ),

                // Actions
                DataCell(
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.visibility, color: Colors.blue),
                        tooltip: 'View Details',
                        onPressed: () {
                          // View OTP details
                          context.go('/otp/${otp.id}');
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.refresh, color: Colors.green),
                        tooltip: 'Regenerate OTP',
                        onPressed:
                            otp.isVerified
                                ? null // Disable if already verified
                                : () {
                                  // Show confirmation dialog before regenerating
                                  _showRegenerateConfirmationDialog(
                                    context,
                                    otp,
                                  );
                                },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        tooltip: 'Delete',
                        onPressed: () {
                          // Show confirmation dialog before deleting
                          _showDeleteConfirmationDialog(context, otp);
                        },
                      ),
                    ],
                  ),
                ),
              ],
            );
          }).toList(),
      currentPage: currentPage,
      totalPages: totalPages,
      onPageChanged: onPageChanged,
      isLoading: isLoading,
      onFiltered: () {
        // Show filter dialog
        _showFilterDialog(context);
      }, dataLength: '${otps.length}', onDeleted: () {  },
    );
  }

  // Widget _buildTypeChip(OtpType otpType) {
  //   Color chipColor;
  //   String label;

  //   switch (otpType) {
  //     case OtpType.inTransit:
  //       chipColor = Colors.blue;
  //       label = 'In-Transit';
  //       break;
  //     case OtpType.endDelivery:
  //       chipColor = Colors.green;
  //       label = 'End Trip';
  //       break;
  //   }

  //   return Chip(
  //     label: Text(
  //       label,
  //       style: const TextStyle(color: Colors.white, fontSize: 12),
  //     ),
  //     backgroundColor: chipColor,
  //     padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
  //     visualDensity: VisualDensity.compact,
  //   );
  // }

  Widget _buildStatusChip(bool isVerified) {
    return Chip(
      label: Text(
        isVerified ? 'Verified' : 'Pending',
        style: const TextStyle(color: Colors.white, fontSize: 12),
      ),
      backgroundColor: isVerified ? Colors.green : Colors.orange,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
      visualDensity: VisualDensity.compact,
    );
  }

  String _formatDate(DateTime date) {
    return DateFormat('MMM dd, yyyy hh:mm a').format(date);
  }

  bool _isExpired(DateTime expiryDate) {
    return DateTime.now().isAfter(expiryDate);
  }

  Future<void> _showRegenerateConfirmationDialog(
    BuildContext context,
    OtpEntity otp,
  ) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Regenerate OTP'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text(
                  'Are you sure you want to regenerate the OTP code ${otp.otpCode}?',
                ),
                const SizedBox(height: 10),
                const Text(
                  'This will invalidate the current OTP and create a new one.',
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            // TextButton(
            //   child: const Text('Regenerate', style: TextStyle(color: Colors.green)),
            //   onPressed: () {
            //     Navigator.of(dialogContext).pop();
            //     // Add regenerate OTP event
            //     context.read<OtpBloc>().add(RegenerateOtpEvent(otp.id));

            //     // Refresh the OTP list for this trip after a short delay
            //     Future.delayed(const Duration(milliseconds: 500), () {
            //       context.read<OtpBloc>().add(LoadOtpByTripIdEvent(tripId));
            //     });
            //   },
            // ),
          ],
        );
      },
    );
  }

  Future<void> _showDeleteConfirmationDialog(
    BuildContext context,
    OtpEntity otp,
  ) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Confirm Delete'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text(
                  'Are you sure you want to delete the OTP code ${otp.otpCode}?',
                ),
                const SizedBox(height: 10),
                const Text('This action cannot be undone.'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            TextButton(
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
              onPressed: () {
                Navigator.of(dialogContext).pop();
                // Add delete OTP event
                context.read<OtpBloc>().add(DeleteOtpEvent(otp.id));

                // Refresh the OTP list for this trip after a short delay
                Future.delayed(const Duration(milliseconds: 500), () {
                  context.read<OtpBloc>().add(LoadOtpByTripIdEvent(tripId));
                });
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _showFilterDialog(BuildContext context) async {
    bool? selectedVerificationStatus;
    DateTime? startDate;
    DateTime? endDate;

    return showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Filter OTP Codes'),
              content: SizedBox(
                width: 400,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Verification Status Filter
                    const Text('Verification Status:'),
                    DropdownButton<bool?>(
                      isExpanded: true,
                      value: selectedVerificationStatus,
                      hint: const Text('All Statuses'),
                      items: [
                        const DropdownMenuItem<bool?>(
                          value: null,
                          child: Text('All Statuses'),
                        ),
                        const DropdownMenuItem<bool?>(
                          value: true,
                          child: Text('Verified'),
                        ),
                        const DropdownMenuItem<bool?>(
                          value: false,
                          child: Text('Pending'),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() {
                          selectedVerificationStatus = value;
                        });
                      },
                    ),

                    const SizedBox(height: 16),

                    // Date Range Filter
                    const Text('Created Date Range:'),
                    Row(
                      children: [
                        Expanded(
                          child: TextButton.icon(
                            icon: const Icon(Icons.calendar_today),
                            label: Text(
                              startDate != null
                                  ? DateFormat('MM/dd/yyyy').format(startDate!)
                                  : 'Start Date',
                            ),
                            onPressed: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: startDate ?? DateTime.now(),
                                firstDate: DateTime(2020),
                                lastDate: DateTime.now(),
                              );
                              if (picked != null) {
                                setState(() {
                                  startDate = picked;
                                });
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextButton.icon(
                            icon: const Icon(Icons.calendar_today),
                            label: Text(
                              endDate != null
                                  ? DateFormat('MM/dd/yyyy').format(endDate!)
                                  : 'End Date',
                            ),
                            onPressed: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: endDate ?? DateTime.now(),
                                firstDate: DateTime(2020),
                                lastDate: DateTime.now().add(
                                  const Duration(days: 1),
                                ),
                              );
                              if (picked != null) {
                                setState(() {
                                  endDate = picked;
                                });
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: const Text('Reset'),
                  onPressed: () {
                    setState(() {
                      selectedVerificationStatus = null;
                      startDate = null;
                      endDate = null;
                    });
                  },
                ),
                TextButton(
                  child: const Text('Cancel'),
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                  },
                ),
                // TextButton(
                //   child: const Text('Apply'),
                //   onPressed: () {
                //     Navigator.of(dialogContext).pop();
                //     // Apply filters but still filter by trip ID
                //     context.read<OtpBloc>().add(
                //       FilterOtpsByTripIdEvent(
                //         tripId: tripId,
                //         isVerified: selectedVerificationStatus,
                //         startDate: startDate,
                //         endDate: endDate,
                //       ),
                //     );
                //   },
                // ),
              ],
            );
          },
        );
      },
    );
  }
}
