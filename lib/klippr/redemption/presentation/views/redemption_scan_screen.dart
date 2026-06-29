import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../application/bloc/redemption_bloc.dart';
import '../../application/bloc/redemption_event.dart';
import '../../application/bloc/redemption_state.dart';
import '../../domain/models/redemption.dart';
import '../navigation/redemption_router.dart';

class RedemptionScanScreen extends StatefulWidget {
  const RedemptionScanScreen({super.key});

  @override
  State<RedemptionScanScreen> createState() => _RedemptionScanScreenState();
}

class _RedemptionScanScreenState extends State<RedemptionScanScreen> {
  MobileScannerController? _scannerController;
  bool _isProcessing = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _scannerController = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
      facing: CameraFacing.back,
    );
  }

  @override
  void dispose() {
    _scannerController?.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_isProcessing) return;
    for (final barcode in capture.barcodes) {
      final code = barcode.rawValue;
      if (code != null && code.isNotEmpty) {
        setState(() => _isProcessing = true);
        context.read<RedemptionBloc>().add(LookupToken(uniqueToken: code));
        break;
      }
    }
  }

  void _resetScan() {
    setState(() => _isProcessing = false);
    context.read<RedemptionBloc>().add(const ResetLookup());
  }

  void _confirm() {
    final bloc = context.read<RedemptionBloc>();
    final redemption = bloc.state.foundRedemption;
    if (redemption == null ||
        redemption.status != RedemptionTokenStatus.pending) {
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

  void _openManual() {
    final bloc = context.read<RedemptionBloc>();
    Navigator.of(context).push(RedemptionRouter.manual(bloc));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
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
            _resetScan();
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
          final found = state.foundRedemption;
          return Stack(
            fit: StackFit.expand,
            children: [
              if (!_hasError)
                MobileScanner(
                  controller: _scannerController,
                  onDetect: _onDetect,
                )
              else
                _CameraPermissionDenied(onRetry: () {
                  setState(() {
                    _hasError = false;
                    _scannerController?.dispose();
                    _scannerController = MobileScannerController(
                      detectionSpeed: DetectionSpeed.normal,
                      facing: CameraFacing.back,
                    );
                  });
                }),
              if (_hasError)
                Positioned.fill(
                  child: Container(
                    color: Colors.black,
                    child: SafeArea(
                      child: Column(
                        children: [
                          AppBar(
                            backgroundColor: Colors.transparent,
                            elevation: 0,
                            leading: IconButton(
                              onPressed: () =>
                                  Navigator.of(context).maybePop(),
                              icon: const Icon(Icons.arrow_back,
                                  color: Colors.white),
                            ),
                            title: const Text(
                              'Escanear Canje',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 22,
                              ),
                            ),
                            centerTitle: true,
                          ),
                          const Spacer(),
                          const Icon(Icons.videocam_off_outlined,
                              color: Colors.white54, size: 80),
                          const SizedBox(height: 16),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 40),
                            child: Text(
                              'Permiso de cámara denegado.\n'
                              'Activa el permiso desde la configuración del dispositivo.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          const Spacer(),
                        ],
                      ),
                    ),
                  ),
                ),
              if (found != null && !_hasError)
                Positioned.fill(
                  child: GestureDetector(
                    onTap: _resetScan,
                    child: Container(
                      color: Colors.black.withValues(alpha: 0.6),
                      child: SafeArea(
                        child: Column(
                          children: [
                            AppBar(
                              backgroundColor: Colors.transparent,
                              elevation: 0,
                              leading: IconButton(
                                onPressed: () =>
                                    Navigator.of(context).maybePop(),
                                icon: const Icon(Icons.arrow_back,
                                    color: Colors.white),
                              ),
                              title: const Text(
                                'Escanear Canje',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 22,
                                ),
                              ),
                              centerTitle: true,
                            ),
                            const Spacer(),
                            GestureDetector(
                              onTap: () {},
                              child: _ScanResultCard(
                                redemption: found,
                                isConfirming: state.isConfirming,
                                onConfirm:
                                    found.status == RedemptionTokenStatus.pending
                                        ? _confirm
                                        : null,
                              ),
                            ),
                            const Spacer(),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              if (!_hasError && found == null)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.8),
                        ],
                      ),
                    ),
                    padding: const EdgeInsets.fromLTRB(20, 40, 20, 32),
                    child: SafeArea(
                      top: false,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.qr_code_scanner,
                            color: Colors.white54,
                            size: 48,
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Apunta la cámara al código QR del canje',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: ElevatedButton.icon(
                              onPressed: _openManual,
                              icon: const Icon(Icons.keyboard,
                                  color: Colors.white),
                              label: const Text(
                                'Ingresar código manualmente',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF887BF3),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(50),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              if (_isProcessing && found == null && !_hasError)
                Positioned.fill(
                  child: Container(
                    color: Colors.black.withValues(alpha: 0.5),
                    child: const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(
                            color: Color(0xFF887BF3),
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Buscando canje...',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                            ),
                          ),
                        ],
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
}

class _ScanResultCard extends StatelessWidget {
  const _ScanResultCard({
    required this.redemption,
    required this.onConfirm,
    this.isConfirming = false,
  });

  final Redemption redemption;
  final VoidCallback? onConfirm;
  final bool isConfirming;

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

  String _formatDate(DateTime date) {
    final dd = date.day.toString().padLeft(2, '0');
    final mm = date.month.toString().padLeft(2, '0');
    final yyyy = date.year.toString().padLeft(4, '0');
    return '$dd/$mm/$yyyy';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {},
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: _statusBackground,
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: Text(
                    redemption.status.label,
                    style: TextStyle(
                      color: _statusForeground,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
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
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 48),
                      side: const BorderSide(
                          color: Color(0xFF887BF3), width: 1.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(50),
                      ),
                    ),
                    child: const Text(
                      'Cerrar',
                      style: TextStyle(
                        color: Color(0xFFCCAACF),
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
                if (onConfirm != null) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: onConfirm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF27AE60),
                        minimumSize: const Size(0, 48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(50),
                        ),
                      ),
                      child: isConfirming
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
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CameraPermissionDenied extends StatelessWidget {
  const _CameraPermissionDenied({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      child: SafeArea(
        child: Column(
          children: [
            AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                onPressed: () => Navigator.of(context).maybePop(),
                icon: const Icon(Icons.arrow_back, color: Colors.white),
              ),
              title: const Text(
                'Escanear Canje',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                ),
              ),
              centerTitle: true,
            ),
            const Spacer(),
            const Icon(Icons.videocam_off_outlined,
                color: Colors.white54, size: 80),
            const SizedBox(height: 16),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                'Permiso de cámara denegado.\n'
                'Activa el permiso desde la configuración del dispositivo.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                ),
              ),
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }
}
