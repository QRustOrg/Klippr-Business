import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/redemption_bloc.dart';
import '../bloc/redemption_event.dart';
import '../bloc/redemption_state.dart';
import '../models/redemption_model.dart';
import 'redemption_history_screen.dart';

class RedemptionManualScreen extends StatefulWidget {
  const RedemptionManualScreen({super.key});

  @override
  State<RedemptionManualScreen> createState() =>
      _RedemptionManualScreenState();
}

class _RedemptionManualScreenState extends State<RedemptionManualScreen> {
  final _tokenController = TextEditingController();

  @override
  void dispose() {
    _tokenController.dispose();
    super.dispose();
  }

  void _lookup() {
    final token = _tokenController.text.trim();
    if (token.isEmpty) return;
    context.read<RedemptionBloc>().add(LookupToken(uniqueToken: token));
  }

  void _confirm() {
    final bloc = context.read<RedemptionBloc>();
    final redemption = bloc.state.foundRedemption;
    if (redemption == null || redemption.status != RedemptionTokenStatus.pending) {
      return;
    }
    showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmar Canje'),
        content: Text(
          '¿Confirmar el canje de "${redemption.promotionTitle}" '
          'para ${redemption.customerName}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    ).then((confirmed) {
      if (confirmed == true && context.mounted) {
        context
            .read<RedemptionBloc>()
            .add(ConfirmToken(uniqueToken: redemption.uniqueToken));
      }
    });
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
          'Validar Canje',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
      ),
      body: BlocConsumer<RedemptionBloc, RedemptionState>(
        listenWhen: (prev, curr) =>
            prev.successMessage != curr.successMessage ||
            prev.error != curr.error,
        listener: (context, state) {
          if (state.successMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.successMessage!)),
            );
            context
                .read<RedemptionBloc>()
                .add(const RedemptionFlagsConsumed());
            setState(() {
              _tokenController.clear();
            });
          } else if (state.error != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.error!)),
            );
            context
                .read<RedemptionBloc>()
                .add(const RedemptionFlagsConsumed());
          }
        },
        builder: (context, state) {
          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Código de canje',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF8A6FE8),
                  ),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _tokenController,
                  cursorColor: const Color(0xFF887BF3),
                  style: const TextStyle(color: Color(0xFF1A1A1A), fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Ej: ABC12345',
                    hintStyle: const TextStyle(
                      color: Color(0xFF888888),
                      fontSize: 14,
                    ),
                    filled: true,
                    fillColor: const Color(0xFFF4EFFB),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          const BorderSide(color: Color(0xFF887BF3)),
                    ),
                  ),
                  textInputAction: TextInputAction.search,
                  onSubmitted: (_) => _lookup(),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: state.isLoading ? null : _lookup,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF887BF3),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(50),
                      ),
                    ),
                    child: state.isLoading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                        : const Text(
                            'Buscar',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 24),
                if (state.foundRedemption != null) ...[
                  _FoundRedemptionCard(
                    redemption: state.foundRedemption!,
                  ),
                  const SizedBox(height: 16),
                  if (state.foundRedemption!.status ==
                      RedemptionTokenStatus.pending)
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: state.isConfirming ? null : _confirm,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF27AE60),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(50),
                          ),
                        ),
                        child: state.isConfirming
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.5,
                                ),
                              )
                            : const Text(
                                'Confirmar Canje',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                      ),
                    ),
                  const SizedBox(height: 24),
                  if (state.foundRedemption!.status !=
                      RedemptionTokenStatus.unknown)
                    _HistorySection(
                      promotionId:
                          state.foundRedemption!.promotionId,
                    ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final RedemptionTokenStatus status;

  Color get _background => switch (status) {
        RedemptionTokenStatus.pending => const Color(0xFFFBE3B8),
        RedemptionTokenStatus.confirmed => const Color(0xFFC6F0D4),
        RedemptionTokenStatus.expired => const Color(0xFFFFD6D2),
        RedemptionTokenStatus.unknown => const Color(0xFFEAEAEA),
      };

  Color get _foreground => switch (status) {
        RedemptionTokenStatus.pending => const Color(0xFFC97900),
        RedemptionTokenStatus.confirmed => const Color(0xFF009B55),
        RedemptionTokenStatus.expired => const Color(0xFFE53935),
        RedemptionTokenStatus.unknown => const Color(0xFF888888),
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: _background,
        borderRadius: BorderRadius.circular(50),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          color: _foreground,
          fontSize: 13,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _FoundRedemptionCard extends StatelessWidget {
  const _FoundRedemptionCard({required this.redemption});

  final Redemption redemption;

  String _formatDate(DateTime date) {
    final dd = date.day.toString().padLeft(2, '0');
    final mm = date.month.toString().padLeft(2, '0');
    final yyyy = date.year.toString().padLeft(4, '0');
    return '$dd/$mm/$yyyy';
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
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  redemption.promotionTitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF8A6FE8),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _StatusChip(status: redemption.status),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.person_outline,
                  size: 18, color: Color(0xFF888888)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  redemption.customerName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.confirmation_num_outlined,
                  size: 18, color: Color(0xFF888888)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  redemption.uniqueToken,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF1A1A1A),
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.calendar_today_outlined,
                  size: 18, color: Color(0xFF888888)),
              const SizedBox(width: 6),
              Text(
                _formatDate(redemption.createdAt),
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF1A1A1A),
                ),
              ),
              if (redemption.confirmedAt != null) ...[
                const SizedBox(width: 16),
                const Icon(Icons.check_circle_outline,
                    size: 18, color: Color(0xFF27AE60)),
                const SizedBox(width: 6),
                Text(
                  _formatDate(redemption.confirmedAt!),
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF27AE60),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _HistorySection extends StatelessWidget {
  const _HistorySection({required this.promotionId});

  final String promotionId;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Container(
              width: 4,
              height: 22,
              decoration: BoxDecoration(
                color: const Color(0xFF887BF3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'Historial del usuario',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Color(0xFF8A6FE8),
              ),
            ),
            const Spacer(),
            TextButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => RedemptionHistoryScreen(
                      promotionId: promotionId,
                    ),
                  ),
                );
              },
              child: const Text(
                'Ver todo',
                style: TextStyle(
                  color: Color(0xFF887BF3),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        BlocBuilder<RedemptionBloc, RedemptionState>(
          buildWhen: (prev, curr) => prev.history != curr.history,
          builder: (context, state) {
            if (state.history.isEmpty) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Center(
                  child: Text(
                    'Sin canjes previos',
                    style: TextStyle(
                      color: Color(0xFF888888),
                      fontSize: 14,
                    ),
                  ),
                ),
              );
            }
            return Column(
              children: state.history.map((r) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF4EFFB),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              r.promotionTitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1A1A1A),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              r.uniqueToken,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF888888),
                                fontFamily: 'monospace',
                              ),
                            ),
                          ],
                        ),
                      ),
                      _StatusChip(status: r.status),
                    ],
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }
}
