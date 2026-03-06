import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:file_selector/file_selector.dart';
import 'package:flutter/rendering.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/trip/domain/entity/trip_entity.dart';
import 'package:xpro_delivery_admin_app/core/common/widgets/app_structure/data_dashboard.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shimmer/shimmer.dart';
import 'show_print_qr_dialog.dart';

class TripDashboardWidget extends StatefulWidget {
  final TripEntity? trip;
  final bool isLoading;
  final VoidCallback? onEditTrip;

  const TripDashboardWidget({
    super.key,
    required this.trip,
    this.isLoading = false,
    this.onEditTrip,
  });

  @override
  State<TripDashboardWidget> createState() => _TripDashboardWidgetState();
}

class _TripDashboardWidgetState extends State<TripDashboardWidget> {
  bool _isQrExpanded = false;
  bool _isQrVisible = true;
  final GlobalKey _qrBoundaryKey = GlobalKey();

  Future<void> _saveQrAsPng({
    required BuildContext context,
    required String fileNameBase, // e.g. trip number
  }) async {
    try {
      final boundary =
          _qrBoundaryKey.currentContext?.findRenderObject()
              as RenderRepaintBoundary?;

      if (boundary == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('QR image is not ready yet. Please try again.'),
          ),
        );
        return;
      }

      // Higher pixelRatio = sharper image
      final ui.Image image = await boundary.toImage(pixelRatio: 4.0);

      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) throw Exception('Failed to convert image to PNG.');

      final Uint8List pngBytes = byteData.buffer.asUint8List();

      final suggestedName = '$fileNameBase-qr.png'.replaceAll(
        RegExp(r'[\\/:*?"<>|]'),
        '_',
      );

      final FileSaveLocation? saveLocation = await getSaveLocation(
        suggestedName: suggestedName,
        acceptedTypeGroups: const [
          XTypeGroup(label: 'PNG Image', extensions: ['png']),
        ],
      );

      if (saveLocation == null) return; // user canceled

      final XFile xfile = XFile.fromData(
        pngBytes,
        mimeType: 'image/png',
        name: suggestedName,
      );

      await xfile.saveTo(saveLocation.path);

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Saved: ${saveLocation.path}')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to save QR image: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isLoading) {
      return _buildLoadingSkeleton(context);
    }

    String formatDateTime(DateTime? dateTime) {
      if (dateTime == null) return 'N/A';

      final hour24 = dateTime.hour;
      final hour12 =
          hour24 == 0
              ? 12
              : hour24 > 12
              ? hour24 - 12
              : hour24;

      final amPm = hour24 >= 12 ? 'PM' : 'AM';

      final month = dateTime.month.toString().padLeft(2, '0');
      final day = dateTime.day.toString().padLeft(2, '0');
      final year = dateTime.year;

      return '$month/$day/$year '
          '${hour12.toString().padLeft(2, '0')}:'
          '${dateTime.minute.toString().padLeft(2, '0')} $amPm';
    }

    String dateFormat(DateTime? date) {
      if (date == null) return 'Not set';
      return DateFormat('MM/dd/yyyy').format(date);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // QR Code Display Section
        if (widget.trip?.qrCode != null && widget.trip!.qrCode!.isNotEmpty)
          Card(
            margin: const EdgeInsets.only(bottom: 16),
            elevation: 2,
            child: Column(
              children: [
                // Header with toggle buttons
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    children: [
                      const Icon(Icons.qr_code, size: 20),
                      const SizedBox(width: 8),
                      const Text(
                        'Trip QR Code',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      // Toggle visibility button
                      IconButton(
                        icon: Icon(
                          _isQrVisible
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                        tooltip: _isQrVisible ? 'Hide QR Code' : 'Show QR Code',
                        onPressed: () {
                          setState(() {
                            _isQrVisible = !_isQrVisible;
                          });
                        },
                      ),
                      // Toggle size button
                      IconButton(
                        icon: Icon(
                          _isQrExpanded ? Icons.compress : Icons.expand,
                        ),
                        tooltip:
                            _isQrExpanded
                                ? 'Minimize QR Code'
                                : 'Maximize QR Code',
                        onPressed: () {
                          setState(() {
                            _isQrExpanded = !_isQrExpanded;
                          });
                        },
                      ),
                    ],
                  ),
                ),

                // QR Code content (conditionally visible)
                if (_isQrVisible)
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // QR Code
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade300),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withValues(alpha: 0.2),
                                spreadRadius: 1,
                                blurRadius: 3,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.all(12),
                          child: RepaintBoundary(
                            key: _qrBoundaryKey,
                            child: QrImageView(
                              data: widget.trip!.qrCode!,
                              version: QrVersions.auto,
                              size: _isQrExpanded ? 250 : 150,
                              backgroundColor: Colors.white,
                            ),
                          ),
                        ),

                        const SizedBox(width: 24),

                        // QR Code Info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'QR Code Value: ${widget.trip!.qrCode}',
                                style: const TextStyle(fontSize: 14),
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'Scan this QR code with the X-Pro Delivery mobile app to quickly access this trip.',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  ElevatedButton.icon(
                                    icon: const Icon(Icons.print),
                                    label: const Text('Print QR Code'),
                                    onPressed: () {
                                      showPrintQrDialog(context, widget.trip!);
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.blue,
                                      foregroundColor: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  OutlinedButton.icon(
                                    icon: const Icon(Icons.save_alt),
                                    label: const Text('Save as Image'),
                                    onPressed: () {
                                      final tripNo =
                                          widget.trip?.tripNumberId ??
                                          widget.trip?.id ??
                                          'trip';
                                      _saveQrAsPng(
                                        context: context,
                                        fileNameBase: tripNo.toString(),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),

        // Trip Actions Section
        Card(
          margin: const EdgeInsets.only(bottom: 16),
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                const Icon(Icons.settings, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Trip Actions',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: widget.onEditTrip,
                  icon: const Icon(Icons.edit),
                  label: const Text('Edit Trip'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
                SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.settings),
                  label: const Text('Others'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),

        // Original Dashboard Summary
        DashboardSummary(
          items: [
            DashboardInfoItem(
              icon: Icons.numbers,
              value: widget.trip?.tripNumberId ?? 'N/A',
              label: 'Trip Number',
            ),
            DashboardInfoItem(
              icon: Icons.numbers,
              value: widget.trip?.name ?? 'N/A',
              label: 'Route Name',
            ),
            DashboardInfoItem(
              icon: Icons.people,
              value: widget.trip?.deliveryData.length.toString() ?? '0',
              label: 'Deliveries',
            ),
            DashboardInfoItem(
              icon: Icons.play_circle_filled,
              value: dateFormat(widget.trip?.deliveryDate),
              label: 'Delivery Date',
            ),
            DashboardInfoItem(
              icon: Icons.date_range,
              value: dateFormat(widget.trip?.expectedReturnDate),
              label: 'Expected Return Date',
            ),
            DashboardInfoItem(
              icon: Icons.local_shipping,
              value: formatDateTime(widget.trip?.otp?.verifiedAt),
              label: 'Dispatch Time',
            ),
            DashboardInfoItem(
              icon: Icons.play_circle_filled,
              value: formatDateTime(widget.trip?.timeAccepted),
              label: 'Start of Trip',
            ),
            DashboardInfoItem(
              icon: Icons.stop_circle,
              value: formatDateTime(widget.trip?.timeEndTrip),
              label: 'End of Trip',
            ),
            DashboardInfoItem(
              icon: Icons.check_circle,
              value: () {
                final deliveryCollectionLength =
                    widget.trip?.deliveryCollection?.length;
                debugPrint(
                  '📊 Dashboard - DeliveryCollection length: $deliveryCollectionLength',
                );
                debugPrint(
                  '📊 Dashboard - DeliveryCollection data: ${widget.trip?.deliveryCollection}',
                );
                debugPrint('📊 Dashboard - Trip ID: ${widget.trip?.id}');
                return deliveryCollectionLength?.toString() ?? '0';
              }(),
              label: 'Completed Deliveries',
            ),
            DashboardInfoItem(
              icon: Icons.cancel,
              value: widget.trip?.cancelledInvoice?.length.toString() ?? '0',
              label: 'Undelivered',
            ),
            DashboardInfoItem(
              icon: Icons.route,
              value: widget.trip?.totalTripDistance ?? '0 km',
              label: 'Total Distance in KM',
            ),
            DashboardInfoItem(
              icon: Icons.person,
              value: widget.trip?.dispatcher ?? 'N/A',
              label: 'Dispatched By',
            ),
            DashboardInfoItem(
              icon: Icons.calendar_view_day,
              value: formatDateTime(widget.trip?.created),
              label: 'Created At',
            ),
            DashboardInfoItem(
              icon: Icons.update_outlined,
              value: formatDateTime(widget.trip?.updated),
              label: 'Updated At',
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLoadingSkeleton(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // QR Code skeleton
        Card(
          margin: const EdgeInsets.only(bottom: 16),
          elevation: 2,
          child: Column(
            children: [
              // Header skeleton
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  children: [
                    Shimmer.fromColors(
                      baseColor: Colors.grey[300]!,
                      highlightColor: Colors.grey[100]!,
                      child: Container(
                        width: 20,
                        height: 20,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Shimmer.fromColors(
                      baseColor: Colors.grey[300]!,
                      highlightColor: Colors.grey[100]!,
                      child: Container(
                        width: 120,
                        height: 18,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                    const Spacer(),
                    // Fake toggle buttons
                    Shimmer.fromColors(
                      baseColor: Colors.grey[300]!,
                      highlightColor: Colors.grey[100]!,
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Shimmer.fromColors(
                      baseColor: Colors.grey[300]!,
                      highlightColor: Colors.grey[100]!,
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // QR Code content skeleton
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // QR Code skeleton
                    Shimmer.fromColors(
                      baseColor: Colors.grey[300]!,
                      highlightColor: Colors.grey[100]!,
                      child: Container(
                        width: 150,
                        height: 150,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),

                    const SizedBox(width: 24),

                    // QR Code Info skeleton
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Shimmer.fromColors(
                            baseColor: Colors.grey[300]!,
                            highlightColor: Colors.grey[100]!,
                            child: Container(
                              width: double.infinity,
                              height: 14,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Shimmer.fromColors(
                            baseColor: Colors.grey[300]!,
                            highlightColor: Colors.grey[100]!,
                            child: Container(
                              width: double.infinity,
                              height: 14,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Shimmer.fromColors(
                            baseColor: Colors.grey[300]!,
                            highlightColor: Colors.grey[100]!,
                            child: Container(
                              width: double.infinity,
                              height: 14,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Shimmer.fromColors(
                                baseColor: Colors.grey[300]!,
                                highlightColor: Colors.grey[100]!,
                                child: Container(
                                  width: 120,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Shimmer.fromColors(
                                baseColor: Colors.grey[300]!,
                                highlightColor: Colors.grey[100]!,
                                child: Container(
                                  width: 120,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Dashboard Summary skeleton
        Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Grid of skeleton items
                GridView.count(
                  crossAxisCount: 4,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  childAspectRatio: 2.5,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  children: List.generate(
                    8,
                    (index) => _buildDashboardSkeletonItem(context),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDashboardSkeletonItem(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon placeholder
          Container(
            width: 24,
            height: 24,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(height: 8),

          // Value placeholder
          Container(
            width: 100,
            height: 18,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 4),

          // Label placeholder
          Container(
            width: 80,
            height: 14,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
      ),
    );
  }
}
