import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../application/bloc/promotions_bloc.dart';
import '../../domain/models/promotion.dart';
import '../views/active_promotions_screen.dart';
import '../views/business_home_screen.dart';
import '../views/create_promotion_screen.dart';

// author: Samuel Bonifacio
//
// Router del bounded context Promotions. Expone constructores de [Route]
// para cada destino. La app usa Navigator imperativo (no go_router); este
// router solo centraliza el armado de las rutas para que otros bounded
// contexts no instancien las pantallas de Promotions directamente.

/// Construye las [Route] de Promotions.
abstract final class PromotionsRouter {
  /// Ruta del dashboard principal del negocio (home post-login).
  static Route<void> home() {
    return MaterialPageRoute(builder: (_) => const BusinessHomeScreen());
  }

  /// Ruta del listado de promociones activas, compartiendo [bloc].
  static Route<void> active(PromotionsBloc bloc) {
    return MaterialPageRoute(
      builder: (_) => BlocProvider<PromotionsBloc>.value(
        value: bloc,
        child: const ActivePromotionsScreen(),
      ),
    );
  }

  /// Ruta del formulario de creación/edición, compartiendo [bloc].
  ///
  /// [promotion] no nulo abre el formulario en modo edición.
  static Route<void> create(PromotionsBloc bloc, {Promotion? promotion}) {
    return MaterialPageRoute(
      builder: (_) => BlocProvider<PromotionsBloc>.value(
        value: bloc,
        child: CreatePromotionScreen(promotion: promotion),
      ),
    );
  }
}
