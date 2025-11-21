import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import 'package:xpro_delivery_admin_app/core/common/widgets/app_structure/data_dashboard.dart';

import '../../../../core/common/app/features/Trip_Ticket/delivery_vehicle_data/domain/enitity/delivery_vehicle_entity.dart';

class VehicleDashboardWidget extends StatefulWidget {
  final DeliveryVehicleEntity? vehicle;
  final bool isLoading;
  final VoidCallback? onEditVehicle;

  const VehicleDashboardWidget({
    super.key,
    required this.vehicle,
    this.isLoading = false,
    this.onEditVehicle,
  });

  @override
  State<VehicleDashboardWidget> createState() => _VehicleDashboardWidgetState();
}

class _VehicleDashboardWidgetState extends State<VehicleDashboardWidget> {
  @override
  Widget build(BuildContext context) {
    if (widget.isLoading) {
      return _buildLoadingSkeleton(context);
    }

    String fmt(String? value) => value?.isNotEmpty == true ? value! : "N/A";

    String fmtDouble(double? value) => value != null ? value.toString() : "N/A";

    String fmtDate(DateTime? date) {
      if (date == null) return "Not set";
      return DateFormat('MM/dd/yyyy hh:mm a').format(date);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Top Actions Panel
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
                  "Vehicle Actions",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: widget.onEditVehicle,
                  icon: const Icon(Icons.edit),
                  label: const Text("Edit Vehicle"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),

        // Vehicle Info Dashboard
        DashboardSummary(
          items: [
            DashboardInfoItem(
              icon: Icons.numbers,
              value: fmt(widget.vehicle?.id),
              label: "ID",
            ),
            DashboardInfoItem(
              icon: Icons.branding_watermark,
              value: fmt(widget.vehicle?.make),
              label: "Make / Brand",
            ),
            DashboardInfoItem(
              icon: Icons.local_shipping,
              value: fmt(widget.vehicle?.name),
              label: "Vehicle Plate Number",
            ),
            DashboardInfoItem(
              icon: Icons.category,
              value: fmt(widget.vehicle?.type),
              label: "Vehicle Type",
            ),
            DashboardInfoItem(
              icon: Icons.tire_repair_outlined,
              value: fmt(widget.vehicle?.wheels),
              label: "No. of Wheels",
            ),
            DashboardInfoItem(
              icon: Icons.square_foot,
              value: fmtDouble(widget.vehicle?.volumeCapacity),
              label: "Volume Capacity",
            ),
            DashboardInfoItem(
              icon: Icons.monitor_weight,
              value: fmtDouble(widget.vehicle?.weightCapacity),
              label: "Weight Capacity",
            ),
            DashboardInfoItem(
              icon: Icons.date_range,
              value: fmtDate(widget.vehicle?.created),
              label: "Created At",
            ),
            DashboardInfoItem(
              icon: Icons.update,
              value: fmtDate(widget.vehicle?.updated),
              label: "Last Updated",
            ),
          ],
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // LOADING SKELETON (SHIMMER)
  // ---------------------------------------------------------------------------

  Widget _buildLoadingSkeleton(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Top Panel Skeleton
        Card(
          margin: const EdgeInsets.only(bottom: 16),
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                _shimmerCircle(size: 20),
                const SizedBox(width: 8),
                _shimmerBox(width: 140, height: 18),
                const Spacer(),
                _shimmerBox(width: 120, height: 36),
              ],
            ),
          ),
        ),

        // Dashboard Grid Skeleton
        Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 2.5,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              children: List.generate(
                9,
                (index) => _buildDashboardSkeletonItem(),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDashboardSkeletonItem() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _shimmerCircle(size: 26),
        const SizedBox(height: 8),
        _shimmerBox(width: 100, height: 18),
        const SizedBox(height: 4),
        _shimmerBox(width: 80, height: 14),
      ],
    );
  }

  Widget _shimmerBox({required double width, required double height}) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(4),
        ),
      ),
    );
  }

  Widget _shimmerCircle({required double size}) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
