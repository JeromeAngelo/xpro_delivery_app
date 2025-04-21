import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:objectbox/objectbox.dart';
import 'package:provider/provider.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Delivery_Team/delivery_team/presentation/bloc/delivery_team_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Delivery_Team/personels/presentation/bloc/personel_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Delivery_Team/vehicle/presentation/bloc/vehicle_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/completed_customer/presentation/bloc/completed_customer_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/customer/presentation/bloc/customer_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/delivery_update/presentation/bloc/delivery_update_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/invoice/presentation/bloc/invoice_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/products/presentation/bloc/products_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/return_product/presentation/bloc/return_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/transaction/presentation/bloc/transaction_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/trip/presentation/bloc/trip_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/trip_updates/presentation/bloc/trip_updates_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/undeliverable_customer/presentation/bloc/undeliverable_customer_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/checklist/presentation/bloc/checklist_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/end_trip_checklist/presentation/bloc/end_trip_checklist_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/end_trip_otp/presentation/bloc/end_trip_otp_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/otp/presentation/bloc/otp_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/provider/check_connectivity_provider.dart';
import 'package:x_pro_delivery_app/core/common/app/provider/user_provider.dart';
import 'package:x_pro_delivery_app/core/services/injection_container.dart';
import 'package:x_pro_delivery_app/core/services/objectbox.dart';
import 'package:x_pro_delivery_app/core/services/router.dart';
import 'package:x_pro_delivery_app/src/auth/presentation/bloc/auth_bloc.dart';
import 'package:x_pro_delivery_app/src/on_boarding/presentation/bloc/onboarding_bloc.dart';

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
        BlocProvider(create: (_) => sl<AuthBloc>()),
        BlocProvider(create: (_) => sl<CustomerBloc>()),
        BlocProvider(create: (_) => sl<TripBloc>()),
        BlocProvider(create: (_) => sl<DeliveryTeamBloc>()),
        BlocProvider(create: (_) => sl<ChecklistBloc>()),
        BlocProvider(create: (_) => sl<OtpBloc>()),
        BlocProvider(create: (_) => sl<EndTripOtpBloc>()),
        BlocProvider(create: (_) => sl<OnboardingBloc>()),
        BlocProvider(create: (_) => sl<DeliveryUpdateBloc>()),
        BlocProvider(create: (_) => sl<InvoiceBloc>()),
        BlocProvider(create: (_) => sl<ProductsBloc>()),
        BlocProvider(create: (_) => sl<TransactionBloc>()),
        BlocProvider(create: (_) => sl<ReturnBloc>()),
        BlocProvider(create: (_) => sl<UndeliverableCustomerBloc>()),
        BlocProvider(create: (_) => sl<EndTripChecklistBloc>()),
        BlocProvider(create: (_) => sl<TripUpdatesBloc>()),
        BlocProvider(create: (_) => sl<PersonelBloc>()),
        BlocProvider(create: (_) => sl<VehicleBloc>()),
        BlocProvider(create: (_) => sl<CompletedCustomerBloc>()),
      ],
      child: MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => UserProvider()),
          ChangeNotifierProvider(create: (_) => sl<ConnectivityProvider>()),
        ],
        child: MaterialApp.router(
          debugShowCheckedModeBanner: false,
          title: 'X_Pro_Delivery_App',
          routerConfig: router,
          theme: FlexThemeData.light(
            scheme: FlexScheme.amber,
            appBarStyle: FlexAppBarStyle.primary,
          ),
          darkTheme: FlexThemeData.dark(scheme: FlexScheme.amber),
          themeMode: ThemeMode.system,
        ),
      ),
    );
  }
}
