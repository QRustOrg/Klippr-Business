import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../application/bloc/redemption_bloc.dart';
import '../../application/bloc/redemption_event.dart';
import '../../application/bloc/redemption_state.dart';
import '../../domain/models/redemption.dart';

class RedemptionHistoryScreen extends StatefulWidget {
  const RedemptionHistoryScreen({super.key, required this.promotionId});

  final String promotionId;

  @override
  State<RedemptionHistoryScreen> createState() =>
      _RedemptionHistoryScreenState();
}

class _RedemptionHistoryScreenState extends State<RedemptionHistoryScreen> {
  @override
  void initState() {
    super.initState();
    context
        .read<RedemptionBloc>()
        .add(LoadHistory(promotionId: widget.promotionId));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      appBar: AppBar(
        backgroundColor: const Color(0xFF887BF3),
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
      body: BlocConsumer<RedemptionBloc, RedemptionState>(
        listenWhen: (prev, curr) => prev.error != curr.error,
        listener: (context, state) {
          if (state.error != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.error!)),
            );
            context
                .read<RedemptionBloc>()
                .add(const RedemptionFlagsConsumed());
          }
        },
        builder: (context, state) {
          return RefreshIndicator(
            onRefresh: () async {
              final bloc = context.read<RedemptionBloc>();
              bloc.add(LoadHistory(promotionId: widget.promotionId));
              await bloc.stream.firstWhere((s) => !s.isHistoryLoading);
            },
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
              children: [
                const Text(
                  'Canjes realizados',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF8A6FE8),
                  ),
                ),
                const SizedBox(height: 20),
                if (state.isHistoryLoading && state.history.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 48),
                    child: Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF887BF3),
                      ),
                    ),
                  )
                else if (state.history.isEmpty)
                  const _HistoryEmptyState()
                else
                  ...state.history.map(
                    (r) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _HistoryRedemptionCard(redemption: r),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _HistoryEmptyState extends StatelessWidget {
  const _HistoryEmptyState();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 56),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              color: Color(0xFFE879C7),
              size: 64,
            ),
            SizedBox(height: 16),
            Text(
              'Sin canjes registrados',
              style: TextStyle(
                color: Color(0xFF888888),
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Aún no se han canjeado tokens\npara esta promoción.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF888888),
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HistoryRedemptionCard extends StatelessWidget {
  const _HistoryRedemptionCard({required this.redemption});

  final Redemption redemption;

  Color get _statusBackground => switch (redemption.status) {
        RedemptionTokenStatus.pending => const Color(0xFFFBE3B8),
        RedemptionTokenStatus.confirmed => const Color(0xFFC6F0D4),
        RedemptionTokenStatus.expired => const Color(0xFFFFD6D2),
        RedemptionTokenStatus.unknown => const Color(0xFFEAEAEA),
      };

  Color get _statusForeground => switch (redemption.status) {
        RedemptionTokenStatus.pending => const Color(0xFFC97900),
        RedemptionTokenStatus.confirmed => const Color(0xFF009B55),
        RedemptionTokenStatus.expired => const Color(0xFFE53935),
        RedemptionTokenStatus.unknown => const Color(0xFF888888),
      };

  String _formatDateTime(DateTime date) {
    final dd = date.day.toString().padLeft(2, '0');
    final mm = date.month.toString().padLeft(2, '0');
    final yyyy = date.year.toString().padLeft(4, '0');
    final hh = date.hour.toString().padLeft(2, '0');
    final min = date.minute.toString().padLeft(2, '0');
    return '$dd/$mm/$yyyy $hh:$min';
  }

  String _formatDate(DateTime date) {
    final dd = date.day.toString().padLeft(2, '0');
    final mm = date.month.toString().padLeft(2, '0');
    final yyyy = date.year.toString().padLeft(4, '0');
    return '$dd/$mm/$yyyy';
  }

  String _formatMoney(double amount) {
    if (amount == 0) return 'S/ 0.00';
    return 'S/ ${amount.toStringAsFixed(2)}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
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
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: _statusBackground,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  redemption.status == RedemptionTokenStatus.confirmed
                      ? Icons.check_circle_outline
                      : redemption.status == RedemptionTokenStatus.pending
                          ? Icons.schedule
                          : Icons.cancel_outlined,
                  color: _statusForeground,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Código',
                      style: TextStyle(
                        fontSize: 11,
                        color: Color(0xFF888888),
                      ),
                    ),
                    Text(
                      redemption.code.isNotEmpty
                          ? redemption.code
                          : redemption.uniqueToken,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1A1A),
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _statusBackground,
                  borderRadius: BorderRadius.circular(50),
                ),
                child: Text(
                  redemption.status.label,
                  style: TextStyle(
                    color: _statusForeground,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(color: Color(0xFFEDE5F1), height: 1, thickness: 1),
          const SizedBox(height: 12),
          _DetailRow(
            icon: Icons.savings_outlined,
            label: 'Descuento aplicado',
            value: _formatMoney(redemption.discountAppliedAmount),
            valueColor: const Color(0xFF27AE60),
          ),
          if (redemption.validationMethod.isNotEmpty) ...[
            const SizedBox(height: 10),
            _DetailRow(
              icon: Icons.smartphone_outlined,
              label: 'Método de validación',
              value: redemption.validationMethod,
            ),
          ],
          const SizedBox(height: 10),
          _DetailRow(
            icon: Icons.calendar_today_outlined,
            label: 'Generado',
            value: _formatDateTime(redemption.createdAt),
          ),
          if (redemption.confirmedAt != null) ...[
            const SizedBox(height: 10),
            _DetailRow(
              icon: Icons.check_circle_outline,
              label: 'Canjeado',
              value: _formatDateTime(redemption.confirmedAt!),
              valueColor: const Color(0xFF27AE60),
            ),
          ],
          if (redemption.blockedAt != null) ...[
            const SizedBox(height: 10),
            _DetailRow(
              icon: Icons.block_outlined,
              label: 'Bloqueado',
              value: _formatDateTime(redemption.blockedAt!),
              valueColor: const Color(0xFFE53935),
            ),
          ],
          if (redemption.expiresAt != null) ...[
            const SizedBox(height: 10),
            _DetailRow(
              icon: Icons.timer_outlined,
              label: 'Expira',
              value: _formatDate(redemption.expiresAt!),
            ),
          ],
          const SizedBox(height: 10),
          _DetailRow(
            icon: Icons.key_outlined,
            label: 'Token',
            value: redemption.uniqueToken,
            mono: true,
          ),
          const SizedBox(height: 10),
          _DetailRow(
            icon: Icons.tag,
            label: 'ID',
            value: '#${redemption.id.value}',
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
    this.mono = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;
  final bool mono;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: const Color(0xFF887BF3)),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFF888888),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: valueColor ?? const Color(0xFF1A1A1A),
                  fontFamily: mono ? 'monospace' : null,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
