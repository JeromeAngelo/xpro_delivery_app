import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:geolocator/geolocator.dart';
import 'package:objectbox/objectbox.dart';
import 'package:provider/provider.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/return_items/presentation/bloc/return_items_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/app_logs/presentation/bloc/logs_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_team/delivery_team/presentation/bloc/delivery_team_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_team/personels/presentation/bloc/personel_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/delivery_update/presentation/bloc/delivery_update_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/trip/presentation/bloc/trip_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/trip_updates/presentation/bloc/trip_updates_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/checklist/presentation/bloc/checklist_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/end_trip_checklist/presentation/bloc/end_trip_checklist_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/end_trip_otp/presentation/bloc/end_trip_otp_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/otp/presentation/bloc/otp_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/cancelled_invoices/presentation/bloc/cancelled_invoice_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/collection/presentation/bloc/collections_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/customer_data/presentation/bloc/customer_data_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/delivery_data/presentation/bloc/delivery_data_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/delivery_receipt/presentation/bloc/delivery_receipt_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/delivery_vehicle_data/presentation/bloc/delivery_vehicle_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/invoice_data/presentation/bloc/invoice_data_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/invoice_items/presentation/bloc/invoice_items_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/user_performance/presentation/bloc/user_performance_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/provider/check_connectivity_provider.dart';
import 'package:x_pro_delivery_app/core/common/app/provider/user_provider.dart';
import 'package:x_pro_delivery_app/core/services/injection_container.dart';
import 'package:x_pro_delivery_app/core/services/objectbox.dart';
import 'package:x_pro_delivery_app/core/services/router.dart';
import 'package:x_pro_delivery_app/src/auth/presentation/bloc/auth_bloc.dart';
import 'package:x_pro_delivery_app/src/on_boarding/presentation/bloc/onboarding_bloc.dart';

import 'core/common/app/features/sync_data/cubit/sync_cubit.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final store = await ObjectBoxStore.create();
  await Geolocator.isLocationServiceEnabled();
  sl.registerSingleton<Store>(store.store);
  await init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Define a consistent primary color for app bars

    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => sl<SyncCubit>()),
        BlocProvider(create: (_) => sl<AuthBloc>()),
        BlocProvider(create: (_) => sl<TripBloc>()),
        BlocProvider(create: (_) => sl<DeliveryTeamBloc>()),
        BlocProvider(create: (_) => sl<ChecklistBloc>()),
        BlocProvider(create: (_) => sl<OtpBloc>()),
        BlocProvider(create: (_) => sl<EndTripOtpBloc>()),
        BlocProvider(create: (_) => sl<OnboardingBloc>()),
        BlocProvider(create: (_) => sl<DeliveryUpdateBloc>()),
        BlocProvider(create: (_) => sl<EndTripChecklistBloc>()),
        BlocProvider(create: (_) => sl<TripUpdatesBloc>()),
        BlocProvider(create: (_) => sl<PersonelBloc>()),

        //new entities
        BlocProvider(create: (_) => sl<CustomerDataBloc>()),
        BlocProvider(create: (_) => sl<InvoiceDataBloc>()),
        BlocProvider(create: (_) => sl<InvoiceItemsBloc>()),
        BlocProvider(create: (_) => sl<DeliveryDataBloc>()),
        BlocProvider(create: (_) => sl<DeliveryVehicleBloc>()),
        BlocProvider(create: (_) => sl<DeliveryReceiptBloc>()),
        BlocProvider(create: (_) => sl<CancelledInvoiceBloc>()),
        BlocProvider(create: (_) => sl<CollectionsBloc>()),
        BlocProvider(create: (_) => sl<ReturnItemsBloc>()),
        BlocProvider(create: (_) => sl<UserPerformanceBloc>()),
                BlocProvider(create: (_) => sl<LogsBloc>()),

      ],
      child: MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => UserProvider()),
          ChangeNotifierProvider(create: (_) => sl<ConnectivityProvider>()),
        ],
        child: ScreenUtilInit(
          designSize: const Size(375, 812), // iPhone 11 Pro size as base
          minTextAdapt: true,
          splitScreenMode: true,
          builder: (context, child) => MaterialApp.router(
            debugShowCheckedModeBanner: false,
            title: 'X_Pro_Delivery_App',
            routerConfig: router,
            theme: FlexThemeData.light(
              scheme: FlexScheme.amber,
              appBarStyle: FlexAppBarStyle.primary,
            ),
            darkTheme: FlexThemeData.dark(scheme: FlexScheme.amber),
            themeMode: ThemeMode.system,
            builder: (context, child) => ResponsiveBreakpoints.builder(
              child: child!,
              breakpoints: [
                const Breakpoint(start: 0, end: 450, name: MOBILE),
                const Breakpoint(start: 451, end: 800, name: TABLET),
                const Breakpoint(start: 801, end: 1920, name: DESKTOP),
                const Breakpoint(start: 1921, end: double.infinity, name: '4K'),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
