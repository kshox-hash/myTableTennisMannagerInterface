import "package:flutter/material.dart";
import "package:myttmi/routes/cyber_page_route.dart";
import "package:myttmi/core/constants/app_colors.dart";
import "package:myttmi/core/storage/session_storage.dart";
import "package:myttmi/core/ui/brand_logo.dart";
import "package:myttmi/features/auth/presentation/login_screen.dart";
import "package:myttmi/features/shell/app_shell.dart";
import "package:myttmi/features/profile/api/profile_api.dart";

class SplashGate extends StatefulWidget {
  const SplashGate({super.key});

  @override
  State<SplashGate> createState() => _SplashGateState();
}

class _SplashGateState extends State<SplashGate> {
  @override
  void initState() {
    super.initState();
    _route();
  }

  Future<void> _route() async {
    final storage = SessionStorage();
    final token = await storage.getToken();
    final role = await storage.getRole();

    if (!mounted) return;

    // Esta app es solo para jugadores — una sesión admin vieja (de antes de
    // sacar esas pantallas) no debe quedar atrapada acá.
    if (token == null || token.isEmpty || role != "player") {
      await storage.clear();
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        CyberPageRoute(builder: (_) => const LoginScreen()),
      );
      return;
    }

    // La sesión puede ser de un usuario que ya no existe (se borró la cuenta
    // o la base): el servidor responde 401 y se vuelve al login. Sin conexión
    // se sigue igual — no se echa al jugador por no tener señal.
    try {
      await ProfileApi().getMe();
    } catch (e) {
      if (e.toString().contains("HTTP 401")) {
        await storage.clear();
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          CyberPageRoute(builder: (_) => const LoginScreen()),
        );
        return;
      }
    }
    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      CyberPageRoute(builder: (_) => const AppShell()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.scorifyBg,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            BrandLogo(markSize: 64, showWordmark: false),
            SizedBox(height: 24),
            SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.scorifyMint),
            ),
          ],
        ),
      ),
    );
  }
}
