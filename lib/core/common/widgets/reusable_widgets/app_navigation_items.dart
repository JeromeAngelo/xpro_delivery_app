import 'package:xpro_delivery_admin_app/core/common/widgets/app_structure/navigation_item.dart';
import 'package:flutter/material.dart';

/// A utility class that provides predefined navigation items for use across the application.
/// This helps maintain consistency in navigation structure and reduces duplication.
class AppNavigationItems {
  /// Private constructor to prevent instantiation
  AppNavigationItems._();

  // Add this new method to the AppNavigationItems class
  static List<NavigationItem> dashboardNavigationItems() {
    return [
      NavigationItem(
        title: 'Dashboard',
        icon: Icons.dashboard,
        route: '/main-screen',
      ),
      NavigationItem(
        title: 'Trip Tickets',
        icon: Icons.trip_origin,
        route: '/tripticket',
      ),
      NavigationItem(
        title: 'Collections',
        icon: Icons.calculate,
        route: '/collections',
      ),
      NavigationItem(
        title: 'Return Products',
        icon: Icons.keyboard_return,
        route: '/returns',
      ),
      NavigationItem(
        title: 'Users',
        icon: Icons.admin_panel_settings,
        route: '/users',
      ),

      NavigationItem(title: 'Settings', icon: Icons.settings, route: ''),
    ];
  }

  /// Returns navigation items specific to the invoice module
  static List<NavigationItem> generalTripItems() {
    return [
      NavigationItem(
        title: 'Dashboard',
        icon: Icons.dashboard,
        route: '/main-screen',
      ),
      NavigationItem(
        title: 'Master Data',
        icon: Icons.storage,
        children: [
          NavigationItem(
            title: 'Trip Overview',
            icon: Icons.summarize,
            route: '/trip-overview',
          ),
          NavigationItem(
            title: 'Trip Tickets',
            icon: Icons.trip_origin,
            route: '/tripticket',
          ),

          NavigationItem(
            title: 'Customers',
            icon: Icons.people,
            route: '/customer-list',
          ),
          NavigationItem(
            title: 'Delivery Data',
            icon: Icons.dataset,
            route: '/delivery-list',
          ),
          NavigationItem(
            title: 'Invoice Preset',
            icon: Icons.list_alt_rounded,
            route: '/invoice-preset-groups',
          ),
          NavigationItem(
            title: 'Invoices',
            icon: Icons.receipt_long_outlined,
            route: '/invoice-list',
          ),
          NavigationItem(
            title: 'Products',
            icon: Icons.shopping_bag,
            route: '/product-list',
          ),

          NavigationItem(
            title: 'Personnel',
            icon: Icons.people,
            route: '/personnel-list',
          ),
          NavigationItem(
            title: 'Checklists',
            icon: Icons.checklist,
            route: '/checklist',
          ),
        ],
      ),
    ];
  }

  /// Returns navigation items specific to the invoice module
  static List<NavigationItem> tripticketNavigationItems() {
    return [
      NavigationItem(
        title: 'Dashboard',
        icon: Icons.dashboard,
        route: '/main-screen',
      ),
      NavigationItem(
        title: 'Master Data',
        icon: Icons.storage,
        children: [
          NavigationItem(
            title: 'Trip Tickets',
            icon: Icons.trip_origin,
            route: '/tripticket',
          ),
          NavigationItem(
            title: 'Customers',
            icon: Icons.people,
            route: '/customer-list',
          ),
          NavigationItem(
            title: 'Invoices',
            icon: Icons.receipt_long_outlined,
            route: '/invoice-list',
          ),
          NavigationItem(
            title: 'Products',
            icon: Icons.shopping_bag,
            route: '/product-list',
          ),
          NavigationItem(
            title: 'Vehicles',
            icon: Icons.local_shipping,
            route: '/vehicle-list',
          ),
          NavigationItem(
            title: 'Personnel',
            icon: Icons.people,
            route: '/personnel-list',
          ),
          NavigationItem(
            title: 'Checklists',
            icon: Icons.checklist,
            route: '/checklist',
          ),
        ],
      ),
    ];
  }

  static List<NavigationItem> collectionNavigationItems() {
    return [
      NavigationItem(
        title: 'Dashboard',
        icon: Icons.dashboard,
        route: '/main-screen',
      ),
      NavigationItem(
        title: 'Master Data',
        icon: Icons.storage,
        children: [
          NavigationItem(
            title: 'Collection Overview',
            icon: Icons.summarize,
            route: '/collections-overview',
          ),
          NavigationItem(
            title: 'Trip Tickets',
            icon: Icons.trip_origin,
            route: '/collections',
          ),
          NavigationItem(
            title: 'Customers',
            icon: Icons.people,
            route: '/completed-customers',
          ),
        ],
      ),
    ];
  }

  static List<NavigationItem> returnsNavigationItems() {
    return [
      NavigationItem(
        title: 'Dashboard',
        icon: Icons.dashboard,
        route: '/main-screen',
      ),
      NavigationItem(
        title: 'Master Data',
        icon: Icons.storage,
        children: [
          NavigationItem(
            title: 'Cancelled Invoices',
            icon: Icons.error,
            route: '/undeliverable-customers',
          ),
          NavigationItem(
            title: 'Return Products',
            icon: Icons.keyboard_return,
            route: '/returns',
          ),
        ],
      ),
    ];
  }

  static List<NavigationItem> usersNavigationItems() {
    return [
      NavigationItem(
        title: 'Dashboard',
        icon: Icons.dashboard,
        route: '/main-screen',
      ),
      NavigationItem(
        title: 'Master Data',
        icon: Icons.storage,
        children: [
          NavigationItem(
            title: 'All Users',
            icon: Icons.person,
            route: '/all-users',
          ),
        ],
      ),
    ];
  }

  static List<NavigationItem> vehicleManagementNavigationItems() {
    return [
      NavigationItem(
        title: 'Dashboard',
        icon: Icons.dashboard,
        route: '/main-screen',
      ),
      NavigationItem(
        title: 'Master Data',
        icon: Icons.storage,
        children: [
          NavigationItem(
            title: 'Map Overview',
            icon: Icons.map,
            route: '/vehicle-map',
          ),
          NavigationItem(
            title: 'Vehicles',
            icon: Icons.local_shipping,
            route: '/vehicle-list',
          ),
        ],
      ),
    ];
  }
}
