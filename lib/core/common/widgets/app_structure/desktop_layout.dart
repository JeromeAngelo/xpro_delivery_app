import 'package:xpro_delivery_admin_app/core/common/widgets/app_structure/desktop_appbar.dart';
import 'package:xpro_delivery_admin_app/core/common/widgets/app_structure/navigation_item.dart';
import 'package:flutter/material.dart';

class DesktopLayout extends StatelessWidget {
  final List<NavigationItem> navigationItems;
  final String currentRoute;
  final Function(String) onNavigate;
  final VoidCallback onThemeToggle;
  final VoidCallback onNotificationTap;
  final VoidCallback onProfileTap;
  final Widget child;
  final String? title;
  final bool disableScrolling;
  final bool useCompactNavigation;
  final double sidebarWidth;
  final bool adaptiveLayout;

  const DesktopLayout({
    super.key,
    required this.navigationItems,
    required this.currentRoute,
    required this.onNavigate,
    required this.onThemeToggle,
    required this.onNotificationTap,
    required this.onProfileTap,
    required this.child,
    this.title,
    this.disableScrolling = false,
    this.useCompactNavigation = false,
    this.sidebarWidth = 250,
    this.adaptiveLayout = true,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isCompact = adaptiveLayout && screenWidth < 1100;

    return Scaffold(
      appBar: DesktopAppBar(
        onThemeToggle: onThemeToggle,
        onNotificationTap: onNotificationTap,
        onProfileTap: onProfileTap,
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Main content area with side navigation and content
          Expanded(
            child: Row(
              children: [
                // Side Navigation
                if (!isCompact || !adaptiveLayout)
                  SideNavigation(
                    items: navigationItems,
                    onNavigate: onNavigate,
                    currentRoute: currentRoute,
                    isCompact:
                        useCompactNavigation ||
                        (adaptiveLayout && screenWidth < 1300),
                    width: sidebarWidth,
                  ),

                // Main Content - adapt to available space
                Expanded(
                  child: Container(
                    color: Theme.of(context).colorScheme.background,
                    child: _buildContent(context, isCompact),
                  ),
                ),
              ],
            ),
          ),

          // Footer
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12.0),
            color: Theme.of(context).colorScheme.surface,
            child: Center(
              child: Text(
                '© ${DateTime.now().year} Xpro Delivery. All rights reserved.',
                style: TextStyle(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.7),
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, bool isCompact) {
    // If scrolling is disabled or the child is already a scrollable widget,
    // just return the child with minimal wrapping
    if (disableScrolling) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Optional title
          if (title != null)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                title!,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),

          // Main content - using Expanded to fill available space
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: child,
            ),
          ),
        ],
      );
    }

    // Otherwise, wrap the content in a SingleChildScrollView
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Optional title
          if (title != null)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                title!,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),

          // Main content
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: child,
          ),

          // Bottom padding
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
