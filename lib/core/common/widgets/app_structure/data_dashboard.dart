import 'package:flutter/material.dart';

class DashboardSummary extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? detailId;
  final List<DashboardInfoItem> items;
  final int crossAxisCount;
  final double childAspectRatio;
  final double crossAxisSpacing;
  final double mainAxisSpacing;
  final bool isLoading;
  final Widget? headerContent;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const DashboardSummary({
    super.key,
    this.title = '',
    this.subtitle,
    this.detailId,
    required this.items,
    this.crossAxisCount = 3,
    this.childAspectRatio = 3.5,
    this.crossAxisSpacing = 16.0,
    this.mainAxisSpacing = 24.0,
    this.isLoading = false,
    this.headerContent,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header section with no background color
        if (headerContent != null)
          headerContent!
        else if (title.isNotEmpty || subtitle != null || detailId != null)
          _buildDefaultHeader(context),

        const SizedBox(height: 12),

        // Dashboard content in a card
        Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child:
                isLoading
                    ? const Center(
                      child: SizedBox(
                        height: 40,
                        width: 40,
                        child: CircularProgressIndicator(strokeWidth: 3),
                      ),
                    )
                    : GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        childAspectRatio: childAspectRatio,
                        crossAxisSpacing: crossAxisSpacing,
                        mainAxisSpacing: mainAxisSpacing,
                      ),
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        return _buildInfoItem(context, items[index]);
                      },
                    ),
          ),
        ),
      ],
    );
  }

  Widget _buildDefaultHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left side: Title and Detail ID
          Expanded(
            child: Row(
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
                ),
                if (detailId != null) ...[
                  const Text(': '),
                  Text(
                    detailId!,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w500,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Right side: Action buttons
          Row(
            children: [
              if (onDelete != null)
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  tooltip: 'Delete',
                  onPressed: onDelete,
                  style: IconButton.styleFrom(foregroundColor: Colors.red),
                ),
              if (onEdit != null)
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  tooltip: 'Edit',
                  onPressed: onEdit,
                  style: IconButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.primary,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(BuildContext context, DashboardInfoItem item) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: item.backgroundColor ?? Theme.of(context).cardColor,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: (item.iconColor ?? Theme.of(context).colorScheme.primary)
                  .withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              item.icon,
              color: item.iconColor ?? Theme.of(context).colorScheme.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: Text(
                    item.value,
                    style: Theme.of(context).textTheme.titleLarge!.copyWith(
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.3,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
                const SizedBox(height: 4),
                Flexible(
                  child: Text(
                    item.label,
                    style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                      color: Colors.grey[600],
                      height: 1.2,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ],
            ),
          ),
          if (item.trend != null) ...[
            const SizedBox(width: 8),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  item.trend! > 0
                      ? Icons.trending_up
                      : (item.trend! < 0
                          ? Icons.trending_down
                          : Icons.trending_flat),
                  color:
                      item.trend! > 0
                          ? Colors.green
                          : (item.trend! < 0 ? Colors.red : Colors.grey),
                  size: 18,
                ),
                const SizedBox(height: 2),
                Text(
                  '${item.trend! > 0 ? '+' : ''}${item.trend}%',
                  style: TextStyle(
                    color:
                        item.trend! > 0
                            ? Colors.green
                            : (item.trend! < 0 ? Colors.red : Colors.grey),
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class DashboardInfoItem {
  final IconData icon;
  final String value;
  final String label;
  final Function? onTap;
  final Color? iconColor;
  final Color? backgroundColor;
  final double? trend;

  const DashboardInfoItem({
    required this.icon,
    required this.value,
    required this.label,
    this.onTap,
    this.iconColor,
    this.backgroundColor,
    this.trend,
  });
}
