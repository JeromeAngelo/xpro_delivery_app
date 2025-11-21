import 'package:xpro_delivery_admin_app/src/auth/presentation/view/auth_view.dart';
import 'package:xpro_delivery_admin_app/src/collection_data/completed_customer_list/presentation/view/completed_customer_list_screen.dart';
import 'package:xpro_delivery_admin_app/src/collection_data/completed_customer_list/presentation/view/completed_customer_overview.dart';
import 'package:xpro_delivery_admin_app/src/collection_data/completed_customer_list/presentation/view/specific_completed_customer_data.dart';
import 'package:xpro_delivery_admin_app/src/collection_data/tripricket_list/presentation/view/specific_trip_collection.dart';
import 'package:xpro_delivery_admin_app/src/collection_data/tripricket_list/presentation/view/tripticket_list_for_collection.dart';
import 'package:xpro_delivery_admin_app/src/delivery_monitoring/presentation/view/delivery_monitoring_screen.dart';
import 'package:xpro_delivery_admin_app/src/master_data/checklist_screen/presentation/view/checklist_screen_view.dart';
import 'package:xpro_delivery_admin_app/src/master_data/customer_screen/presentation/view/customer_list_screen_view.dart';
import 'package:xpro_delivery_admin_app/src/master_data/customer_screen/presentation/view/specific_customer_screen_view.dart';
import 'package:xpro_delivery_admin_app/src/master_data/delivery_data/view/delivery_data_screen.dart';
import 'package:xpro_delivery_admin_app/src/master_data/invoice_preset_groups_screen/presentation/view/invoice_preset_group_screen.dart';
import 'package:xpro_delivery_admin_app/src/master_data/invoice_screen/presentation/view/invoice_screen_list_view.dart';
import 'package:xpro_delivery_admin_app/src/master_data/invoice_screen/presentation/view/specific_invoice_screen_view.dart';
import 'package:xpro_delivery_admin_app/src/main_screen/presentation/view/main_screen_view.dart';
import 'package:xpro_delivery_admin_app/src/master_data/personnels_list_screen/presentation/view/personnel_list_screen_view.dart';
import 'package:xpro_delivery_admin_app/src/master_data/personnels_list_screen/presentation/view/specific_personnel_screen_view.dart';
import 'package:xpro_delivery_admin_app/src/master_data/product_list_screen/presentation/view/product_list_screen_view.dart';
import 'package:xpro_delivery_admin_app/src/master_data/tripticket_screen/presentation/view/create_tripticket_screen_view.dart';
import 'package:xpro_delivery_admin_app/src/master_data/tripticket_screen/presentation/view/trip_ticket_overview_screen.dart';
import 'package:xpro_delivery_admin_app/src/master_data/tripticket_screen/presentation/view/tripticket_screen_view.dart';
import 'package:xpro_delivery_admin_app/src/master_data/tripticket_screen/presentation/view/tripticket_specific_trip_view.dart';
import 'package:xpro_delivery_admin_app/src/vehicle_management/view/specific_vehicle_view/specific_vehicle_view.dart';
import 'package:xpro_delivery_admin_app/src/vehicle_management/view/vehicle_list_screen/vehicle_list_screen_view.dart';
import 'package:xpro_delivery_admin_app/src/return_data/return_list_screen/presentation/view/return_list_view.dart';
import 'package:xpro_delivery_admin_app/src/return_data/undelivered_customer_data/presentation/view/undelivered_customer_list_view.dart';
import 'package:xpro_delivery_admin_app/src/users/presentation/view/all_users_view.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:xpro_delivery_admin_app/src/users/presentation/view/create_user_view.dart';
import 'package:xpro_delivery_admin_app/src/users/presentation/view/specific_user_view.dart';
import 'package:xpro_delivery_admin_app/src/users/presentation/view/update_user_view.dart';
import 'package:xpro_delivery_admin_app/src/vehicle_management/view/vehicle_map_view/vehicle_map_view.dart';

import '../../src/master_data/delivery_data/view/specific_delivery_data_screen.dart';
import '../../src/master_data/tripticket_screen/presentation/view/edit_tripticket_screen_view.dart';
import '../../src/return_data/undelivered_customer_data/presentation/view/specific_cancelled_invoice_view.dart';

// Custom page transition for smooth desktop experience
Page<T> _createSmoothTransition<T extends Object?>(
  Widget child,
  GoRouterState state,
) {
  return CustomTransitionPage<T>(
    key: state.pageKey,
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: CurveTween(curve: Curves.easeInOut).animate(animation),
        child: child,
      );
    },
    transitionDuration: const Duration(milliseconds: 200),
  );
}

final router = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      pageBuilder:
          (context, state) => _createSmoothTransition(AuthView(), state),
    ),
    GoRoute(
      path: '/main-screen',
      pageBuilder:
          (context, state) => _createSmoothTransition(MainScreenView(), state),
    ),
    GoRoute(
      path: '/trip-overview',
      pageBuilder:
          (context, state) =>
              _createSmoothTransition(TripTicketOverviewScreen(), state),
    ),
    GoRoute(
      path: '/tripticket',
      pageBuilder:
          (context, state) =>
              _createSmoothTransition(TripTicketScreenView(), state),
    ),
    GoRoute(
      path: '/tripticket-edit/:tripId',
      builder: (context, state) {
        final tripId = state.pathParameters['tripId']!;
        // We need to get the trip entity first, but we'll handle this in the edit screen
        return EditTripTicketScreenView(tripId: tripId);
      },
    ),
    // Add this new route for specific trip view
    GoRoute(
      path: '/tripticket/:tripId',
      builder: (context, state) {
        final tripId = state.pathParameters['tripId']!;
        return TripTicketSpecificTripView(tripId: tripId);
      },
    ),
    // Add this new route for creating trip tickets
    GoRoute(
      path: '/tripticket-create',
      builder: (context, state) => CreateTripTicketScreenView(),
    ),
    GoRoute(
      path: '/customer-list',
      pageBuilder:
          (context, state) =>
              _createSmoothTransition(CustomerListScreenView(), state),
    ),
    GoRoute(
      path: '/delivery-list',
      pageBuilder:
          (context, state) =>
              _createSmoothTransition(DeliveryDataScreen(), state),
    ),
    GoRoute(
      path: '/delivery-details/:deliveryId',
      builder: (context, state) {
        final deliveryId = state.pathParameters['deliveryId']!;
        return SpecificDeliveryDataScreen(deliveryId: deliveryId);
      },
    ),

    GoRoute(
      path: '/customer/:customerId',
      builder: (context, state) {
        // Extract the customerId without any additional colons
        final customerId = state.pathParameters['customerId']!;
        return SpecificCustomerScreenView(customerId: customerId);
      },
    ),
    GoRoute(
      path: '/invoice-list',
      pageBuilder:
          (context, state) =>
              _createSmoothTransition(InvoiceScreenListView(), state),
    ),
    GoRoute(
      path: '/invoice-preset-groups',
      pageBuilder:
          (context, state) =>
              _createSmoothTransition(InvoicePresetGroupScreen(), state),
    ),
    GoRoute(
      path: '/invoice/:invoiceId',
      builder: (context, state) {
        final invoiceId = state.pathParameters['invoiceId']!;
        return SpecificInvoiceScreenView(invoiceId: invoiceId);
      },
    ),
    // Add this import

    // Inside the GoRouter routes list, add:
    GoRoute(
      path: '/product-list',
      pageBuilder:
          (context, state) =>
              _createSmoothTransition(const ProductListScreenView(), state),
    ),
    GoRoute(
      path: '/vehicle-list',
      pageBuilder:
          (context, state) =>
              _createSmoothTransition(const VehicleListScreenView(), state),
    ),
     GoRoute(
      path: '/vehicle-id/:vehicleId',
      builder: (context, state) {
        final vehicleId = state.pathParameters['vehicleId']!;
        return SpecificVehicleView(vehicleId: vehicleId);
      },
    ),
    GoRoute(
      path: '/personnel-list',
      pageBuilder:
          (context, state) =>
              _createSmoothTransition(const PersonnelListScreenView(), state),
    ),
    GoRoute(
      path: '/personnel/:personnelId',
      builder: (context, state) {
        final personnelId = state.pathParameters['personnelId']!;
        return SpecificPersonnelScreenView(personnelId: personnelId);
      },
    ),

    // Inside the GoRouter routes list, add:
    GoRoute(
      path: '/checklist',
      pageBuilder:
          (context, state) =>
              _createSmoothTransition(const ChecklistScreenView(), state),
    ),
    GoRoute(
      path: '/collections-overview',
      pageBuilder:
          (context, state) =>
              _createSmoothTransition(const CompletedCustomerOverview(), state),
    ),
    GoRoute(
      path: '/collections',
      pageBuilder:
          (context, state) => _createSmoothTransition(
            const TripTicketListForCollection(),
            state,
          ),
    ),
    GoRoute(
      path: '/collections/:tripId',
      builder: (context, state) {
        final tripId = state.pathParameters['tripId']!;
        return SpecificTripCollection(tripId: tripId);
      },
    ),
    GoRoute(
      path: '/completed-customers',
      pageBuilder:
          (context, state) => _createSmoothTransition(
            const CompletedCustomerListScreen(),
            state,
          ),
    ),
    GoRoute(
      path: '/completed-collections/:collectionId',
      builder: (context, state) {
        final customerId = state.pathParameters['collectionId']!;
        return SpecificCompletedCustomerData(collectionId: customerId);
      },
    ),
    GoRoute(
      path: '/returns',
      pageBuilder:
          (context, state) =>
              _createSmoothTransition(const ReturnListView(), state),
    ),

    //GoRoute(path: '/users', builder: (context, state) => const UsersListView()),
    GoRoute(
      path: '/all-users',
      pageBuilder:
          (context, state) =>
              _createSmoothTransition(const AllUsersView(), state),
    ),
    GoRoute(
      path: '/create-users',
      pageBuilder:
          (context, state) =>
              _createSmoothTransition(const CreateUserView(), state),
    ),
    // Add this route to your router configuration
    GoRoute(
      path: '/user/:userId',
      builder: (context, state) {
        final userId = state.pathParameters['userId']!;
        return SpecificUserView(userId: userId);
      },
    ),

    // Add the new route for updating users
    GoRoute(
      path: '/update-user/:userId',
      builder: (context, state) {
        final userId = state.pathParameters['userId']!;
        return UpdateUserView(userId: userId);
      },
    ),

    GoRoute(
      path: '/undeliverable-customers',
      pageBuilder:
          (context, state) => _createSmoothTransition(
            const UndeliveredCustomerListView(),
            state,
          ),
    ),

    GoRoute(
      path: '/undeliverable-customers/:cancelledInvoiceId',
      builder: (context, state) {
        final invoiceId = state.pathParameters['cancelledInvoiceId']!;
        return SpecificCancelledInvoiceView(cancelledInvoiceId: invoiceId);
      },
    ),

    // Add this route to your router configuration
    GoRoute(
      path: '/delivery-monitoring',
      pageBuilder:
          (context, state) =>
              _createSmoothTransition(const DeliveryMonitoringScreen(), state),
    ),

    GoRoute(
      path: '/vehicle-map',
      pageBuilder:
          (context, state) =>
              _createSmoothTransition(VehicleMapView(), state),
    )
  ],
);
