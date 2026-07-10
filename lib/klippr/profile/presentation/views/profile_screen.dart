import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../admin/application/bloc/admin_bloc.dart';
import '../../../admin/presentation/views/admin_dashboard_screen.dart';
import '../../../analytics/domain/models/business_dashboard_metrics.dart';
import '../../../analytics/domain/stores/analytics_store.dart';
import '../../../iam/application/bloc/auth_bloc.dart';
import '../../../iam/application/bloc/auth_event.dart';
import '../../../iam/presentation/navigation/iam_router.dart';
import '../../../promotions/application/bloc/promotions_bloc.dart';
import '../../../promotions/application/bloc/promotions_event.dart';
import '../../../promotions/presentation/views/promo_colors.dart';
import '../../../shared/data/network/result.dart';
import '../../../shared/data/pref/prefs_helper.dart';
import '../../../shared/domain/models/id.dart';
import '../../application/bloc/profile_bloc.dart';
import '../../application/bloc/profile_event.dart';
import '../../application/bloc/profile_state.dart';
import '../../domain/models/business_profile.dart';
import '../../domain/models/verification_document.dart';
import '../../domain/models/verification_document_template.dart';
import '../navigation/profile_router.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, this.analyticsStore});

  final AnalyticsStore? analyticsStore;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Future<Result<BusinessDashboardMetrics>>? _dashboardFuture;

  @override
  void initState() {
    super.initState();
    context.read<ProfileBloc>().add(const LoadBusinessProfile());
    context.read<PromotionsBloc>().add(const LoadPromotions());
  }

  Future<Result<BusinessDashboardMetrics>>? _dashboard(String businessId) {
    final store = widget.analyticsStore;
    if (store == null || businessId.isEmpty) return null;
    return _dashboardFuture ??= store.loadDashboard(businessId);
  }

  void _edit() {
    Navigator.of(context).push(ProfileRouter.edit(context.read<ProfileBloc>()));
  }

  Future<void> _submitVerification(BusinessProfile profile) async {
    final profileId = profile.id.value.trim();
    if (profileId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No se encontró el perfil del negocio. Vuelve a iniciar sesión.',
          ),
        ),
      );
      return;
    }

    final documentUrl = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return _VerificationDocumentSheet(profile: profile);
      },
    );
    if (!mounted || documentUrl == null || documentUrl.isEmpty) return;

    context.read<ProfileBloc>().add(
      SubmitVerificationRequested(
        VerificationDocument(profileId: profileId, documentUrl: documentUrl),
      ),
    );
  }

  void _logout() {
    context.read<AuthBloc>().add(const SignOutRequested());
    Navigator.of(context).pushAndRemoveUntil(IamRouter.signIn(), (_) => false);
  }

  void _openAdminPanel() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: context.read<AdminBloc>(),
          child: const AdminDashboardScreen(),
        ),
      ),
    );
  }

  bool _isAdmin() {
    final authState = context.read<AuthBloc>().state;
    return authState.user?.role.toUpperCase() == 'ADMIN';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PromoColors.screenBg,
      body: BlocConsumer<ProfileBloc, ProfileState>(
        listener: (context, state) {
          final message = state.error ?? state.actionMessage;
          if (message != null) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(message)));
            context.read<ProfileBloc>().add(const ProfileFlagsConsumed());
          }
        },
        builder: (context, state) {
          final profile = state.profile;
          return Column(
            children: [
              const _ProfileHeader(),
              Expanded(
                child: RefreshIndicator(
                  color: PromoColors.purple,
                  onRefresh: () async {
                    setState(() => _dashboardFuture = null);
                    context.read<ProfileBloc>().add(
                      const LoadBusinessProfile(),
                    );
                    context.read<PromotionsBloc>().add(const LoadPromotions());
                    await context.read<ProfileBloc>().stream.firstWhere(
                      (s) => !s.isLoading,
                    );
                  },
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
                    child: profile == null && state.isLoading
                        ? const Padding(
                            padding: EdgeInsets.only(top: 120),
                            child: Center(
                              child: CircularProgressIndicator(
                                color: PromoColors.purple,
                              ),
                            ),
                          )
                        : _ProfileContent(
                            profile: profile ?? _fallbackProfile(),
                            dashboardFuture: _dashboard(_businessId(profile)),
                            onEdit: _edit,
                            onSubmitVerification: _submitVerification,
                            onLogout: _logout,
                            onOpenAdminPanel: _openAdminPanel,
                            isAdmin: _isAdmin(),
                          ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  BusinessProfile _fallbackProfile() {
    return BusinessProfile(
      id: const Id.empty(),
      userId: Id(_safeUserId()),
      businessName: 'Negocio Klippr',
      role: 'BUSINESS',
      verificationStatus: 'Pending',
    );
  }

  String _businessId(BusinessProfile? profile) {
    if (profile != null && profile.userId.value.isNotEmpty) {
      return profile.userId.value;
    }
    return _safeUserId();
  }

  String _safeUserId() {
    try {
      return PrefsHelper.instance.userId ?? '';
    } on StateError {
      return '';
    }
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: PromoColors.purple,
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: 64,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  onPressed: () => Navigator.of(context).maybePop(),
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  tooltip: 'Volver',
                ),
              ),
              const Text(
                'Perfil negocio',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileContent extends StatelessWidget {
  const _ProfileContent({
    required this.profile,
    required this.dashboardFuture,
    required this.onEdit,
    required this.onSubmitVerification,
    required this.onLogout,
    required this.onOpenAdminPanel,
    required this.isAdmin,
  });

  final BusinessProfile profile;
  final Future<Result<BusinessDashboardMetrics>>? dashboardFuture;
  final VoidCallback onEdit;
  final void Function(BusinessProfile profile) onSubmitVerification;
  final VoidCallback onLogout;
  final VoidCallback onOpenAdminPanel;
  final bool isAdmin;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _MainProfileCard(profile: profile),
        const SizedBox(height: 16),
        FutureBuilder<Result<BusinessDashboardMetrics>>(
          future: dashboardFuture,
          builder: (context, snapshot) {
            final metrics = snapshot.data?.dataOrNull;
            return BlocBuilder<PromotionsBloc, dynamic>(
              builder: (context, promoState) {
                final totalPromos =
                    metrics?.totalPromotions ??
                    (promoState.promotions as List?)?.length ??
                    0;
                final activePromos =
                    metrics?.activePromotions ??
                    (promoState.activos as int?) ??
                    0;
                return _MetricsGrid(
                  promotions: totalPromos,
                  active: activePromos,
                  redemptions: metrics?.totalRedemptions,
                  used: metrics?.usedRedemptions,
                );
              },
            );
          },
        ),
        const SizedBox(height: 16),
        _BusinessDataCard(
          profile: profile,
          onEdit: onEdit,
          onSubmitVerification: () => onSubmitVerification(profile),
        ),
        if (isAdmin) ...[
          const SizedBox(height: 18),
          SizedBox(
            height: 52,
            child: ElevatedButton.icon(
              onPressed: onOpenAdminPanel,
              icon: const Icon(Icons.admin_panel_settings, color: Colors.white),
              label: const Text(
                'Panel de Administrador',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: PromoColors.purple,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
        const SizedBox(height: 18),
        SizedBox(
          height: 52,
          child: ElevatedButton.icon(
            onPressed: onLogout,
            icon: const Icon(Icons.logout, color: Colors.white),
            label: const Text(
              'Cerrar sesión',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: PromoColors.errorRed,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _MainProfileCard extends StatelessWidget {
  const _MainProfileCard({required this.profile});

  final BusinessProfile profile;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: _cardDecoration(),
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          CircleAvatar(
            radius: 34,
            backgroundColor: PromoColors.lavender,
            child: Text(
              _initials(profile.displayName),
              style: const TextStyle(
                color: PromoColors.purple,
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profile.displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: PromoColors.textDark,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  profile.email ?? '--',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: PromoColors.textGray,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 10),
                _StatusBadge(profile: profile),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.profile});

  final BusinessProfile profile;

  @override
  Widget build(BuildContext context) {
    final verified = profile.isVerified;
    final rejected =
        profile.verificationStatus?.trim().toLowerCase() == 'rejected';
    final label = verified ? 'BUSINESS' : profile.statusLabel;
    final background = verified
        ? PromoColors.statGreenBg
        : rejected
        ? const Color(0xFFFFD6D2)
        : PromoColors.statAmberBg;
    final foreground = verified
        ? PromoColors.statGreenIcon
        : rejected
        ? PromoColors.errorRed
        : PromoColors.statAmberIcon;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: foreground,
          fontWeight: FontWeight.w800,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _MetricsGrid extends StatelessWidget {
  const _MetricsGrid({
    required this.promotions,
    required this.active,
    required this.redemptions,
    required this.used,
  });

  final int promotions;
  final int active;
  final int? redemptions;
  final int? used;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _MetricCard(
                'Promociones',
                '$promotions',
                Icons.local_offer,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _MetricCard('Activas', '$active', Icons.trending_up),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _MetricCard(
                'Canjes',
                redemptions?.toString() ?? '--',
                Icons.qr_code_2,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _MetricCard(
                'Usados',
                used?.toString() ?? '--',
                Icons.check_circle_outline,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard(this.title, this.value, this.icon);

  final String title;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: _cardDecoration(),
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: PromoColors.purpleText,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  value,
                  style: const TextStyle(
                    color: PromoColors.textDark,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          Icon(icon, color: PromoColors.purple),
        ],
      ),
    );
  }
}

class _BusinessDataCard extends StatelessWidget {
  const _BusinessDataCard({
    required this.profile,
    required this.onEdit,
    required this.onSubmitVerification,
  });

  final BusinessProfile profile;
  final VoidCallback onEdit;
  final VoidCallback onSubmitVerification;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: _cardDecoration(),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Datos del negocio',
                  style: TextStyle(
                    color: PromoColors.textDark,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined, size: 18),
                label: const Text('Editar'),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _InfoRow('Nombre comercial', profile.displayName),
          _InfoRow('RUC', profile.taxId ?? 'Sin RUC'),
          _InfoRow('Correo', profile.email ?? '--'),
          _InfoRow('Rol', profile.role.isEmpty ? 'BUSINESS' : profile.role),
          _InfoRow('Estado', profile.statusLabel),
          _InfoRow('Miembro desde', _date(profile.createdAt)),
          _InfoRow('Categoria', profile.category?.name ?? '--'),
          _InfoRow('Ubicacion', profile.location?.display ?? '--'),
          if (!profile.isVerified) ...[
            const SizedBox(height: 12),
            if (profile.documentUrl != null &&
                profile.documentUrl!.trim().isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _InfoRow('Documento', profile.documentUrl!),
              ),
            OutlinedButton.icon(
              onPressed: onSubmitVerification,
              icon: const Icon(Icons.verified_user_outlined),
              label: const Text('Enviar verificación'),
            ),
            const SizedBox(height: 6),
            const Text(
              'Elige un tipo de documento (plantilla) o pega una URL. '
              'El admin recibe esa info para aprobar o rechazar.',
              style: TextStyle(
                fontSize: 12,
                color: PromoColors.textGray,
                height: 1.3,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Bottom sheet: dropdown de plantillas + URL opcional / placeholder.
class _VerificationDocumentSheet extends StatefulWidget {
  const _VerificationDocumentSheet({required this.profile});

  final BusinessProfile profile;

  @override
  State<_VerificationDocumentSheet> createState() =>
      _VerificationDocumentSheetState();
}

class _VerificationDocumentSheetState
    extends State<_VerificationDocumentSheet> {
  VerificationDocumentTemplate _selected =
      VerificationDocumentTemplate.templates.first;
  late final TextEditingController _urlController;
  String? _error;

  @override
  void initState() {
    super.initState();
    final existing = widget.profile.documentUrl?.trim() ?? '';
    _urlController = TextEditingController(text: existing);
    if (existing.isNotEmpty) {
      final summary =
          VerificationDocumentTemplate.parseDocumentUrl(existing);
      final matched = VerificationDocumentTemplate.byId(summary.typeId);
      if (matched != null) {
        _selected = matched;
      } else if (!summary.isTemplate) {
        _selected = VerificationDocumentTemplate.other;
      }
    }
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  bool get _needsCustomUrl =>
      _selected.id == VerificationDocumentTemplate.other.id;

  String get _previewUrl => _selected.buildUrl(
    profile: widget.profile,
    customUrl: _urlController.text.trim().isEmpty
        ? null
        : _urlController.text.trim(),
  );

  IconData _iconFor(VerificationDocumentTemplate t) => switch (t.id) {
    'ruc' => Icons.badge_outlined,
    'licencia' => Icons.storefront_outlined,
    'dni_rep' => Icons.person_outline,
    'constancia_tributaria' => Icons.receipt_long_outlined,
    'foto_local' => Icons.photo_camera_outlined,
    _ => Icons.link,
  };

  void _submit() {
    final url = _previewUrl.trim();
    if (url.isEmpty) {
      setState(() {
        _error = _needsCustomUrl
            ? 'Pega la URL del documento (Drive, Dropbox, PDF…).'
            : 'No se pudo generar la plantilla.';
      });
      return;
    }
    final uri = Uri.tryParse(url);
    if (uri == null || !(uri.isScheme('http') || uri.isScheme('https'))) {
      setState(() {
        _error = 'Usa una URL válida (http:// o https://).';
      });
      return;
    }
    Navigator.of(context).pop(url);
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 12, 20, 20 + bottom),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.black12,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Enviar verificación',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: PromoColors.textDark,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'No hay carga de archivos en el backend. Elige una plantilla '
              'para enviar al admin el tipo de documento y datos del negocio, '
              'o pega un enlace real si ya lo tienes.',
              style: TextStyle(
                fontSize: 13,
                height: 1.35,
                color: PromoColors.textGray,
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<VerificationDocumentTemplate>(
              value: _selected,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Tipo de documento',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.folder_open_outlined),
              ),
              items: [
                for (final template in VerificationDocumentTemplate.templates)
                  DropdownMenuItem(
                    value: template,
                    child: Row(
                      children: [
                        Icon(
                          _iconFor(template),
                          size: 18,
                          color: PromoColors.purple,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            template.label,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
              onChanged: (value) {
                if (value == null) return;
                setState(() {
                  _selected = value;
                  _error = null;
                  if (value.id != VerificationDocumentTemplate.other.id &&
                      (_urlController.text.startsWith(
                            'https://klippr.app/verification-templates/',
                          ) ||
                          _urlController.text.isEmpty)) {
                    _urlController.clear();
                  }
                });
              },
            ),
            const SizedBox(height: 8),
            Text(
              _selected.description,
              style: const TextStyle(
                fontSize: 12,
                color: PromoColors.textGray,
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _urlController,
              keyboardType: TextInputType.url,
              textInputAction: TextInputAction.done,
              onChanged: (_) => setState(() => _error = null),
              decoration: InputDecoration(
                labelText: _needsCustomUrl
                    ? 'URL del documento (obligatoria)'
                    : 'URL real (opcional)',
                hintText: _needsCustomUrl
                    ? 'https://drive.google.com/…'
                    : 'Si la dejas vacía se usa la plantilla',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.link),
                errorText: _error,
              ),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: PromoColors.fieldBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFEDE5F1)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Vista previa para el admin',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                      color: PromoColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _PreviewRow('Tipo', _selected.label),
                  _PreviewRow('Negocio', widget.profile.displayName),
                  if ((widget.profile.taxId ?? '').isNotEmpty)
                    _PreviewRow('RUC', widget.profile.taxId!),
                  if ((widget.profile.email ?? '').isNotEmpty)
                    _PreviewRow('Email', widget.profile.email!),
                  const SizedBox(height: 6),
                  Text(
                    _previewUrl.isEmpty
                        ? 'Completa la URL para previsualizar'
                        : _previewUrl,
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      color: PromoColors.purpleText,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancelar'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _submit,
                    icon: const Icon(Icons.send_outlined, size: 18),
                    label: const Text('Enviar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: PromoColors.purple,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PreviewRow extends StatelessWidget {
  const _PreviewRow(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(fontSize: 12, color: PromoColors.textDark),
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: PromoColors.textGray,
              ),
            ),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 132,
            child: Text(
              label,
              style: const TextStyle(color: PromoColors.textGray, fontSize: 13),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: PromoColors.textDark,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

BoxDecoration _cardDecoration() => BoxDecoration(
  color: Colors.white,
  borderRadius: BorderRadius.circular(16),
  boxShadow: [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.06),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
  ],
);

String _initials(String value) {
  final parts = value
      .trim()
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .toList();
  if (parts.isEmpty) return 'K';
  return parts.take(2).map((part) => part[0].toUpperCase()).join();
}

String _date(DateTime? date) {
  if (date == null) return 'Sin fecha';
  final dd = date.day.toString().padLeft(2, '0');
  final mm = date.month.toString().padLeft(2, '0');
  return '$dd/$mm/${date.year}';
}
