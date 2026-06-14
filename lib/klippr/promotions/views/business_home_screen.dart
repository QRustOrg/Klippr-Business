import 'package:flutter/material.dart';

import '../../core/widgets/dashed_border.dart';
import '../../core/widgets/klippr_bottom_bar.dart';
import 'create_promotion_screen.dart';
import 'promo_colors.dart';

// author: Samuel Bonifacio
//
// Pantalla principal del perfil Business: dashboard con estadísticas de
// promociones y estado vacío. Replica el mockup Business 1:1.

/// Dashboard de inicio del negocio.
class BusinessHomeScreen extends StatelessWidget {
  const BusinessHomeScreen({super.key});

  void _openCreate(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const CreatePromotionScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PromoColors.screenBg,
      body: Column(
        children: [
          const _HomeTopBar(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 20),
                  Row(
                    children: const [
                      Expanded(
                        child: _StatCard(
                          title: 'Total',
                          value: '0',
                          icon: Icons.card_giftcard,
                          iconBg: PromoColors.statPurpleBg,
                          iconTint: PromoColors.statPurpleIcon,
                        ),
                      ),
                      SizedBox(width: 14),
                      Expanded(
                        child: _StatCard(
                          title: 'Actividad',
                          value: '0',
                          icon: Icons.north_east,
                          iconBg: PromoColors.statGreenBg,
                          iconTint: PromoColors.statGreenIcon,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: const [
                      Expanded(
                        child: _StatCard(
                          title: 'Activados',
                          value: '0',
                          icon: Icons.check,
                          iconBg: PromoColors.statBlueBg,
                          iconTint: PromoColors.statBlueIcon,
                        ),
                      ),
                      SizedBox(width: 14),
                      Expanded(
                        child: _StatCard(
                          title: 'Expiradas',
                          value: '0',
                          icon: Icons.calendar_today,
                          iconBg: PromoColors.statAmberBg,
                          iconTint: PromoColors.statAmberIcon,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  const Center(
                    child: Text(
                      'Promociones Creadas',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: PromoColors.purpleText,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _EmptyPromotions(onCreate: () => _openCreate(context)),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: KlipprBottomBar(
        current: KlipprTab.inicio,
        onQr: () => _openCreate(context),
        onInicio: () {},
        onMiLista: () {},
      ),
    );
  }
}

class _HomeTopBar extends StatelessWidget {
  const _HomeTopBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: PromoColors.purple,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: SizedBox(
            height: 52,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    width: 46,
                    height: 46,
                    decoration: const BoxDecoration(
                      color: PromoColors.avatarBg,
                      shape: BoxShape.circle,
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Image.asset(
                      'assets/images/klippr_mascot.png',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const Text(
                  'Klippr',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 28,
                  ),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        onPressed: () {},
                        icon: const Icon(Icons.qr_code_2,
                            color: Colors.white, size: 28),
                        tooltip: 'QR',
                      ),
                      IconButton(
                        onPressed: () {},
                        icon: const Icon(Icons.notifications_outlined,
                            color: Colors.white, size: 28),
                        tooltip: 'Notificaciones',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.iconBg,
    required this.iconTint,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color iconBg;
  final Color iconTint;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: PromoColors.purpleText,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: PromoColors.textDark,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconTint, size: 24),
          ),
        ],
      ),
    );
  }
}

class _EmptyPromotions extends StatelessWidget {
  const _EmptyPromotions({required this.onCreate});

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return DashedBorder(
      color: PromoColors.dash,
      radius: 20,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
        child: Column(
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: PromoColors.lavender, width: 2),
              ),
              child: const Icon(Icons.inventory_2_outlined,
                  color: PromoColors.emptyIcon, size: 44),
            ),
            const SizedBox(height: 20),
            const Text(
              'Sin promociones',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: PromoColors.textDark,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Crea tu primera promocion',
              style: TextStyle(fontSize: 15, color: PromoColors.textGray),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: onCreate,
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text(
                'Crear Promocion',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: PromoColors.purple,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(50),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
