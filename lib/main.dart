import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

import 'klippr/admin/application/bloc/admin_bloc.dart';
import 'klippr/iam/application/bloc/auth_bloc.dart';
import 'klippr/iam/presentation/views/splash_session_screen.dart';
import 'klippr/profile/application/bloc/profile_bloc.dart';
import 'klippr/promotions/application/bloc/promotions_bloc.dart';
import 'klippr/redemption/application/bloc/redemption_bloc.dart';
import 'klippr/shared/presentation/theme/app_theme.dart';
import 'service_locator.dart';

// author: Samuel Bonifacio
//
// Punto de entrada de la app Klippr Business. Inicializa el ServiceLocator
// (DI vía get_it, paridad con la guía DDD+hexagonal+BLoC) y compone los
// blocs de cada bounded context en un único MultiBlocProvider raíz, igual
// que la app original.

Future<void> main() async {
  // Necesario antes de usar plugins (shared_preferences) previo a runApp.
  WidgetsFlutterBinding.ensureInitialized();
  await ServiceLocator.init();
  runApp(const KlipprBusinessApp());
}

class KlipprBusinessApp extends StatelessWidget {
  const KlipprBusinessApp({super.key});

  @override
  Widget build(BuildContext context) {
    final sl = GetIt.instance;

    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>(create: (_) => sl<AuthBloc>()),
        BlocProvider<PromotionsBloc>(create: (_) => sl<PromotionsBloc>()),
        BlocProvider<RedemptionBloc>(create: (_) => sl<RedemptionBloc>()),
        BlocProvider<ProfileBloc>(create: (_) => sl<ProfileBloc>()),
        BlocProvider<AdminBloc>(create: (_) => sl<AdminBloc>()),
      ],
      child: MaterialApp(
        title: 'Klippr Business',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: const SplashSessionScreen(),
      ),
    );
  }
}
