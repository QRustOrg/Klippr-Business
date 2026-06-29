import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../promotions/application/bloc/promotions_bloc.dart';
import '../../application/bloc/redemption_bloc.dart';
import '../views/redemption_history_list_screen.dart';
import '../views/redemption_history_screen.dart';
import '../views/redemption_manual_screen.dart';
import '../views/redemption_scan_screen.dart';

// author: Samuel Bonifacio
//
// Router del bounded context Redemption. Expone constructores de [Route]
// para cada destino. La app usa Navigator imperativo (no go_router); este
// router solo centraliza el armado de las rutas para que otros bounded
// contexts no instancien las pantallas de Redemption directamente.

/// Construye las [Route] de Redemption.
abstract final class RedemptionRouter {
  /// Ruta de escaneo de código QR, compartiendo [bloc].
  static Route<void> scan(RedemptionBloc bloc) {
    return MaterialPageRoute(
      builder: (_) => BlocProvider<RedemptionBloc>.value(
        value: bloc,
        child: const RedemptionScanScreen(),
      ),
    );
  }

  /// Ruta de ingreso manual del token, compartiendo [bloc].
  static Route<void> manual(RedemptionBloc bloc) {
    return MaterialPageRoute(
      builder: (_) => BlocProvider<RedemptionBloc>.value(
        value: bloc,
        child: const RedemptionManualScreen(),
      ),
    );
  }

  /// Ruta del historial agregado (lista de promociones), compartiendo el
  /// [PromotionsBloc] (esta pantalla lista promociones, no redenciones).
  static Route<void> historyList(PromotionsBloc bloc) {
    return MaterialPageRoute(
      builder: (_) => BlocProvider<PromotionsBloc>.value(
        value: bloc,
        child: const RedemptionHistoryListScreen(),
      ),
    );
  }

  /// Ruta del historial de una promoción específica.
  static Route<void> historyForPromotion(String promotionId) {
    return MaterialPageRoute(
      builder: (_) => RedemptionHistoryScreen(promotionId: promotionId),
    );
  }
}
