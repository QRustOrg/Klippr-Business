import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/widgets/klippr_bottom_bar.dart';
import '../../promotions/bloc/promotions_bloc.dart';
import '../../promotions/bloc/promotions_state.dart';
import '../../promotions/views/active_promotions_screen.dart';
import '../../promotions/views/business_home_screen.dart';
import '../../promotions/views/promo_colors.dart';
import '../views/redemption_history_screen.dart';

// author: Samuel Bonifacio
//
// Pantalla que lista las promociones del negocio para seleccionar una
// y ver su historial de canjes.

/// Lista de promociones con acceso al historial de canjes.
class RedemptionHistoryListScreen extends StatefulWidget {
  const RedemptionHistoryListScreen({super.key});

  @override
  State<RedemptionHistoryListScreen> createState() =>
      _RedemptionHistoryListScreenState();
}

class _RedemptionHistoryListScreenState
    extends State<RedemptionHistoryListScreen> {
  void _onTabSelected(KlipprTab tab) {
    switch (tab) {
      case KlipprTab.qr:
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => BlocProvider.value(
              value: context.read<PromotionsBloc>(),
              child: const BusinessHomeScreen(),
            ),
          ),
        );
      case KlipprTab.inicio:
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => BlocProvider.value(
              value: context.read<PromotionsBloc>(),
              child: const BusinessHomeScreen(),
            ),
          ),
        );
      case KlipprTab.miLista:
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => BlocProvider.value(
              value: context.read<PromotionsBloc>(),
              child: const ActivePromotionsScreen(),
            ),
          ),
        );
      case KlipprTab.historial:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PromoColors.screenBg,
      appBar: AppBar(
        backgroundColor: PromoColors.purple,
        centerTitle: true,
        leading: IconButton(
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          tooltip: 'Volver',
        ),
        title: const Text(
          'Historial de Canjes',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
      ),
      bottomNavigationBar: KlipprBottomBar(
        current: KlipprTab.historial,
        onQr: () => _onTabSelected(KlipprTab.qr),
        onInicio: () => _onTabSelected(KlipprTab.inicio),
        onMiLista: () => _onTabSelected(KlipprTab.miLista),
        onHistorial: () {},
      ),
      body: BlocBuilder<PromotionsBloc, PromotionsState>(
        builder: (context, state) {
          if (state.isLoading) {
            return const Center(
              child: CircularProgressIndicator(color: PromoColors.purple),
            );
          }

          if (state.promotions.isEmpty) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.receipt_long_outlined,
                    color: PromoColors.emptyIcon,
                    size: 64,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Sin promociones',
                    style: TextStyle(
                      color: PromoColors.textGray,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Crea una promoción para ver\nsu historial de canjes.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: PromoColors.textGray,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
            itemCount: state.promotions.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final promo = state.promotions[index];
              return GestureDetector(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => RedemptionHistoryScreen(
                        promotionId: promo.id,
                      ),
                    ),
                  );
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.18),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              promo.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: PromoColors.purpleText,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            Icons.chevron_right,
                            color: PromoColors.textGray,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            promo.isExpired
                                ? Icons.event_busy
                                : Icons.check_circle_outline,
                            size: 16,
                            color: promo.isExpired
                                ? PromoColors.errorRed
                                : PromoColors.statGreenIcon,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            promo.status.label,
                            style: TextStyle(
                              fontSize: 13,
                              color: promo.isExpired
                                  ? PromoColors.errorRed
                                  : PromoColors.textGray,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            promo.discountLabel,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: PromoColors.textDark,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
