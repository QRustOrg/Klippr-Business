import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../promotions/presentation/views/promo_colors.dart';
import '../../application/bloc/admin_bloc.dart';
import '../../application/bloc/admin_event.dart';
import '../../application/bloc/admin_state.dart';
import '../../domain/models/admin_analytics.dart';

class AdminAnalyticsScreen extends StatelessWidget {
  const AdminAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PromoColors.screenBg,
      appBar: AppBar(
        backgroundColor: PromoColors.purple,
        title: const Text(
          'Reportes de Abuso',
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
          if (state.isLoading && state.abuseReports.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(color: PromoColors.purple),
            );
          }

          if (state.abuseReports.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle, color: Colors.green, size: 64),
                  const SizedBox(height: 16),
                  const Text(
                    'No hay reportes de abuso',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: PromoColors.textDark,
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            color: PromoColors.purple,
            onRefresh: () async {
              context.read<AdminBloc>().add(const LoadAdminData());
              await context.read<AdminBloc>().stream.firstWhere(
                    (s) => !s.isLoading,
                  );
            },
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              itemCount: state.abuseReports.length,
              itemBuilder: (context, index) {
                final report = state.abuseReports[index];
                return _AbuseReportCard(
                  report: report,
                  onMarkReviewed: () => context.read<AdminBloc>().add(
                        UpdateAbuseReportStatusRequested(
                          report.id.value,
                          'REVIEWED',
                        ),
                      ),
                  onMarkResolved: () => context.read<AdminBloc>().add(
                        UpdateAbuseReportStatusRequested(
                          report.id.value,
                          'RESOLVED',
                        ),
                      ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _AbuseReportCard extends StatelessWidget {
  const _AbuseReportCard({
    required this.report,
    required this.onMarkReviewed,
    required this.onMarkResolved,
  });

  final AbuseReport report;
  final VoidCallback onMarkReviewed;
  final VoidCallback onMarkResolved;

  @override
  Widget build(BuildContext context) {
    final statusColor = switch (report.status.toUpperCase()) {
      'PENDING' => Colors.orange,
      'REVIEWED' => Colors.blue,
      'RESOLVED' => Colors.green,
      _ => Colors.grey,
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      report.targetType ?? 'Contenido',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: PromoColors.textDark,
                      ),
                    ),
                    if (report.reason != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Razón: ${report.reason}',
                        style: const TextStyle(
                          fontSize: 13,
                          color: PromoColors.textGray,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  report.statusLabel,
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          if (report.description != null && report.description!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              report.description!,
              style: const TextStyle(
                fontSize: 13,
                color: PromoColors.textDark,
              ),
            ),
          ],
          if (report.createdAt != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.access_time, size: 14, color: PromoColors.textGray),
                const SizedBox(width: 4),
                Text(
                  'Reportado: ${_formatDateTime(report.createdAt!)}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: PromoColors.textGray,
                  ),
                ),
              ],
            ),
          ],
          if (report.isPending || report.isReviewed) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                if (report.isPending)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onMarkReviewed,
                      icon: const Icon(Icons.visibility, size: 18),
                      label: const Text('Marcar Revisado'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.blue,
                        side: const BorderSide(color: Colors.blue),
                      ),
                    ),
                  ),
                if (report.isPending) const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onMarkResolved,
                    icon: const Icon(Icons.check_circle, size: 18),
                    label: const Text('Resolver'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  String _formatDateTime(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
