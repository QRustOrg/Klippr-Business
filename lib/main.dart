import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:klippr/klippr/core/network/api_client.dart';
import 'package:klippr/klippr/core/prefs/prefs_helper.dart';
import 'package:klippr/klippr/core/theme/app_theme.dart';
import 'package:klippr/klippr/iam/bloc/auth_bloc.dart';
import 'package:klippr/klippr/iam/repository/iam_repository.dart';
import 'package:klippr/klippr/iam/services/iam_service.dart';
import 'package:klippr/klippr/iam/views/sign_in_screen.dart';
import 'package:klippr/klippr/promotions/bloc/promotions_bloc.dart';
import 'package:klippr/klippr/promotions/repository/promotions_repository.dart';
import 'package:klippr/klippr/promotions/services/promotions_service.dart';

// author: Samuel Bonifacio
//
// Punto de entrada de la app Klippr Business. Inicializa la persistencia ligera,
// arma la cadena de dependencias de IAM (ApiClient -> IamService -> IamRepository
// -> AuthBloc) y aplica el tema de marca (claro).

Future<void> main() async {
  // Necesario antes de usar plugins (shared_preferences) previo a runApp.
  WidgetsFlutterBinding.ensureInitialized();
  await PrefsHelper.instance.init();
  runApp(const KlipprBusinessApp());
}

class KlipprBusinessApp extends StatelessWidget {
  const KlipprBusinessApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Cadena de dependencias (ApiClient compartido).
    final apiClient = ApiClient();
    final iamRepository = IamRepository(IamService(apiClient));
    final promotionsRepository =
        PromotionsRepository(PromotionsService(apiClient));

    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>(create: (_) => AuthBloc(iamRepository)),
        BlocProvider<PromotionsBloc>(
          create: (_) => PromotionsBloc(promotionsRepository),
        ),
      ],
      child: MaterialApp(
        title: 'Klippr Business',
        debugShowCheckedModeBanner: false,
        // La app fuerza el tema claro (identidad visual de Klippr).
        theme: AppTheme.light,
        home: const SignInScreen(),
      ),
    );
  }
}
