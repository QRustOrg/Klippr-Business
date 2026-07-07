import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../promotions/presentation/views/promo_colors.dart';
import '../../application/bloc/admin_bloc.dart';
import '../../application/bloc/admin_event.dart';
import '../../application/bloc/admin_state.dart';
import 'admin_verifications_screen.dart';
import 'admin_promotions_screen.dart';
import 'admin_analytics_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  @override
  void initState() {
    super.initState();
    context.read<AdminBloc>().add(const LoadAdminData());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PromoColors.screenBg,
      appBar: AppBar(
        backgroundColor: PromoColors.purple,
        title: const Text(
          'Panel de Administrador',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: BlocConsumer<AdminBloc, AdminState>(
        listener: (context, state) {
          if (state.error != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.error!),
                backgroundColor: Colors.red,
              ),
            );
            context.read<AdminBloc>().add(const AdminErrorConsumed());
          }
          if (state.actionMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.actionMessage!),
                backgroundColor: PromoColors.purple,
              ),
            );
            context.read<AdminBloc>().add(const AdminMessageConsumed());
          }
        },
        builder: (context, state) {
          if (state.isLoading && state.platformAnalytics == null) {
            return const Center(
              child: CircularProgressIndicator(color: PromoColors.purple),
            );
          }

          final analytics = state.platformAnalytics;
          final pendingCount = state.pendingVerifications.length;
          final reportsCount = state.abuseReports.where((r) => r.isPending).length;

          return RefreshIndicator(
            color: PromoColors.purple,
            onRefresh: () async {
              context.read<AdminBloc>().add(const LoadAdminData());
              await context.read<AdminBloc>().stream.firstWhere(
                    (s) => !s.isLoading,
                  );
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Estadísticas de la Plataforma',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: PromoColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _StatsGrid(
                    totalUsers: analytics?.totalUsers ?? 0,
                    totalPromotions: analytics?.totalPromotions ?? 0,
                    pendingVerifications: pendingCount,
                    pendingReports: reportsCount,
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Acciones de Moderación',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: PromoColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _ActionCard(
                    title: 'Verificaciones Pendientes',
                    subtitle: '$pendingCount perfiles esperando aprobación',
                    icon: Icons.verified_user,
                    color: Colors.orange,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => BlocProvider.value(
                          value: context.read<AdminBloc>(),
                          child: const AdminVerificationsScreen(),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _ActionCard(
                    title: 'Moderar Promociones',
                    subtitle: '${state.allPromotions.length} promociones activas',
                    icon: Icons.local_offer,
                    color: PromoColors.purple,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => BlocProvider.value(
                          value: context.read<AdminBloc>(),
                          child: const AdminPromotionsScreen(),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _ActionCard(
                    title: 'Reportes de Abuso',
                    subtitle: '$reportsCount reportes pendientes de revisión',
                    icon: Icons.flag,
                    color: Colors.red,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => BlocProvider.value(
                          value: context.read<AdminBloc>(),
                          child: const AdminAnalyticsScreen(),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _StatsGrid extends StatelessWidget {
  const _StatsGrid({
    required this.totalUsers,
    required this.totalPromotions,
    required this.pendingVerifications,
    required this.pendingReports,
  });

  final int totalUsers;
  final int totalPromotions;
  final int pendingVerifications;
  final int pendingReports;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _StatCard(
                label: 'Usuarios',
                value: '$totalUsers',
                icon: Icons.people,
                color: PromoColors.purple,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                label: 'Promociones',
                value: '$totalPromotions',
                icon: Icons.local_offer,
                color: Colors.blue,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                label: 'Verificaciones',
                value: '$pendingVerifications',
                icon: Icons.verified_user,
                color: Colors.orange,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                label: 'Reportes',
                value: '$pendingReports',
                icon: Icons.flag,
                color: Colors.red,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: PromoColors.textGray,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
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
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: PromoColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 13,
                      color: PromoColors.textGray,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: PromoColors.textGray),
          ],
        ),
      ),
    );
  }
}
