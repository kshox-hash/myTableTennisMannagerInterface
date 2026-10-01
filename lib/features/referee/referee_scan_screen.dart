import "package:flutter/material.dart";
import "package:mobile_scanner/mobile_scanner.dart";
import "package:myttmi/core/constants/app_colors.dart";
import "package:myttmi/core/constants/app_typography.dart";
import "package:myttmi/core/ui/app_toast.dart";
import "package:myttmi/core/ui/top_header.dart";
import "package:myttmi/features/referee/referee_api.dart";
import "package:myttmi/features/referee/referee_screen.dart";
import "package:myttmi/routes/cyber_page_route.dart";

/// Escanear el QR de árbitro que muestra el organizador en el panel. El
/// código sirve una sola vez y dura 2 minutos: al canjearlo, quien escanea
/// queda como árbitro de ese partido y se abre la pantalla para anotar.
class RefereeScanScreen extends StatefulWidget {
  const RefereeScanScreen({super.key});

  @override
  State<RefereeScanScreen> createState() => _RefereeScanScreenState();
}

class _RefereeScanScreenState extends State<RefereeScanScreen> {
  final _api = RefereeApi();
  final _controller = MobileScannerController(detectionSpeed: DetectionSpeed.noDuplicates);
  bool _busy = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_busy) return;
    final code = capture.barcodes.map((b) => b.rawValue).whereType<String>().firstWhere(
          (v) => v.startsWith("myttm-ref:"),
          orElse: () => "",
        );
    if (code.isEmpty) return;
    setState(() => _busy = true);
    try {
      final (type, id) = await _api.claim(code);
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        CyberPageRoute(builder: (_) => RefereeScreen(matchType: type, matchId: id)),
      );
    } catch (e) {
      if (!mounted) return;
      showToast(context, e.toString().replaceFirst("Exception: ", ""), error: true);
      // Deja volver a intentar con otro código.
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const TopHeader(title: "Arbitrar con QR"),
              const SizedBox(height: 12),
              Text(
                "Escanea el código que muestra el organizador en su pantalla. Sirve una sola vez y dura 2 minutos.",
                style: AppTypography.bodyMuted.copyWith(fontSize: 13),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      MobileScanner(
                        controller: _controller,
                        onDetect: _onDetect,
                        errorBuilder: (context, error) => Container(
                          color: AppColors.scorifyDeep,
                          padding: const EdgeInsets.all(24),
                          alignment: Alignment.center,
                          child: const Text(
                            "No se pudo abrir la cámara. Revisa que MyTTM tenga permiso de cámara en Ajustes.",
                            textAlign: TextAlign.center,
                            style: TextStyle(color: AppColors.scorifyText),
                          ),
                        ),
                      ),
                      // Marco guía
                      Center(
                        child: Container(
                          width: 230,
                          height: 230,
                          decoration: BoxDecoration(
                            border: Border.all(color: AppColors.scorifyButterfly, width: 3),
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                      ),
                      if (_busy)
                        Container(
                          color: Colors.black54,
                          alignment: Alignment.center,
                          child: const CircularProgressIndicator(color: AppColors.scorifyButterfly),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
