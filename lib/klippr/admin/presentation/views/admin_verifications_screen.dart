import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../promotions/presentation/views/promo_colors.dart';
import '../../application/bloc/admin_bloc.dart';
import '../../application/bloc/admin_event.dart';
import '../../application/bloc/admin_state.dart';
import '../../domain/models/admin_business_profile.dart';

class AdminVerificationsScreen extends StatelessWidget {
  const AdminVerificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PromoColors.screenBg,
      appBar: AppBar(
        backgroundColor: PromoColors.purple,
        title: const Text(
          'Verificaciones Pendientes',
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
          if (state.isLoading && state.pendingVerifications.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(color: PromoColors.purple),
            );
          }

          if (state.pendingVerifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle, color: Colors.green, size: 64),
                  const SizedBox(height: 16),
                  const Text(
                    'No hay verificaciones pendientes',
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
              context.read<AdminBloc>().add(const LoadPendingVerifications());
              await context.read<AdminBloc>().stream.firstWhere(
                    (s) => !s.isLoading,
                  );
            },
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              itemCount: state.pendingVerifications.length,
              itemBuilder: (context, index) {
                final profile = state.pendingVerifications[index];
                return _VerificationCard(
                  profile: profile,
                  onApprove: () => _showApproveDialog(context, profile),
                  onReject: () => _showRejectDialog(context, profile),
                  onViewDocument: () => _showDocumentDialog(context, profile),
                );
              },
            ),
          );
        },
      ),
    );
  }

  void _showApproveDialog(BuildContext context, AdminBusinessProfile profile) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Aprobar Verificación'),
        content: Text(
          '¿Estás seguro de aprobar la verificación de "${profile.businessName}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              context
                  .read<AdminBloc>()
                  .add(ApproveVerificationRequested(profile.id.value));
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
            ),
            child: const Text('Aprobar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showRejectDialog(BuildContext context, AdminBusinessProfile profile) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Rechazar Verificación'),
        content: Text(
          '¿Estás seguro de rechazar la verificación de "${profile.businessName}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              context
                  .read<AdminBloc>()
                  .add(RejectVerificationRequested(profile.id.value));
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Rechazar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showDocumentDialog(BuildContext context, AdminBusinessProfile profile) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Documento de Verificación'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('URL del documento:'),
            const SizedBox(height: 8),
            SelectableText(
              profile.documentUrl ?? 'No disponible',
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }
}

class _VerificationCard extends StatelessWidget {
  const _VerificationCard({
    required this.profile,
    required this.onApprove,
    required this.onReject,
    required this.onViewDocument,
  });

  final AdminBusinessProfile profile;
  final VoidCallback onApprove;
  final VoidCallback onReject;
  final VoidCallback onViewDocument;

  @override
  Widget build(BuildContext context) {
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
              CircleAvatar(
                radius: 24,
                backgroundColor: PromoColors.lavender,
                child: Text(
                  _initials(profile.businessName),
                  style: const TextStyle(
                    color: PromoColors.purple,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile.businessName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: PromoColors.textDark,
                      ),
                    ),
                    Text(
                      profile.email ?? 'Sin email',
                      style: const TextStyle(
                        fontSize: 13,
                        color: PromoColors.textGray,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Pendiente',
                  style: TextStyle(
                    color: Colors.orange,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (profile.taxId != null) ...[
            Text(
              'Tax ID: ${profile.taxId}',
              style: const TextStyle(
                fontSize: 13,
                color: PromoColors.textDark,
              ),
            ),
            const SizedBox(height: 4),
          ],
          if (profile.category != null) ...[
            Text(
              'Categoría: ${profile.category}',
              style: const TextStyle(
                fontSize: 13,
                color: PromoColors.textDark,
              ),
            ),
            const SizedBox(height: 12),
          ],
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onViewDocument,
                  icon: const Icon(Icons.description, size: 18),
                  label: const Text('Ver Documento'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: PromoColors.purple,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onReject,
                  icon: const Icon(Icons.close, size: 18),
                  label: const Text('Rechazar'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onApprove,
                  icon: const Icon(Icons.check, size: 18),
                  label: const Text('Aprobar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _initials(String value) {
    final parts = value.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    return parts.take(2).map((p) => p[0].toUpperCase()).join();
  }
}
