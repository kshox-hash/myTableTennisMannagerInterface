import "package:flutter/material.dart";
import "package:myttmi/routes/cyber_page_route.dart";
import "package:myttmi/core/constants/app_colors.dart";
import "package:myttmi/core/constants/app_typography.dart";
import "package:myttmi/core/storage/session_storage.dart";
import "package:myttmi/core/ui/auth_text_field.dart";
import "package:myttmi/core/ui/brand_logo.dart";
import "package:myttmi/core/ui/glass_card.dart";
import "package:myttmi/core/ui/pill_button.dart";
import "package:myttmi/core/ui/prism_background.dart";
import "package:myttmi/features/auth/api/auth_api.dart";
import "package:myttmi/features/auth/presentation/register_screen.dart";
import "package:myttmi/features/shell/app_shell.dart";

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController();
  final _pass = TextEditingController();
  bool loading = false;

  final api = AuthApi();
  final storage = SessionStorage();

  Future<void> _login() async {
    setState(() => loading = true);

    try {
      final resp = await api.login(email: _email.text, password: _pass.text);

      // Esta app es solo para jugadores — las cuentas admin usan la web.
      if (resp.user.role != "player") {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Esta cuenta es de administrador. Usá la versión web para gestionar campeonatos.")),
        );
        return;
      }

      await storage.saveSession(
        token: resp.token,
        role: resp.user.role,
        userId: resp.user.idUser,
        email: resp.user.email,
      );

      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        CyberPageRoute(builder: (_) => const AppShell()),
        (_) => false,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  void dispose() {
    _email.dispose();
    _pass.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scorifyBg,
      body: PrismBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const BrandLogo(markSize: 52, showWordmark: false),
                  const SizedBox(height: 12),
                  const Text(
                    "MYTTM",
                    style: TextStyle(
                      fontFamily: 'Montserrat',
                      fontWeight: FontWeight.w800,
                      fontSize: 26,
                      letterSpacing: 1,
                      color: AppColors.scorifyText,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Torneos de tenis de mesa",
                    style: AppTypography.bodyMuted,
                  ),
                  const SizedBox(height: 32),
                  GlassCard(
                    variant: GlassCardVariant.elevated,
                    padding: const EdgeInsets.all(22),
                    child: Column(
                      children: [
                        AuthTextField(
                          controller: _email,
                          label: "Email",
                          icon: Icons.mail_outline_rounded,
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 14),
                        AuthTextField(
                          controller: _pass,
                          label: "Contraseña",
                          icon: Icons.lock_outline_rounded,
                          obscureText: true,
                        ),
                        const SizedBox(height: 22),
                        loading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(strokeWidth: 2.4, color: AppColors.scorifyMint),
                              )
                            : SizedBox(
                                width: double.infinity,
                                child: Center(
                                  child: SolidPillButton(label: "ENTRAR", onTap: _login),
                                ),
                              ),
                        const SizedBox(height: 16),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              CyberPageRoute(builder: (_) => const RegisterScreen()),
                            );
                          },
                          child: Text(
                            "Crear cuenta",
                            style: AppTypography.bodyMuted.copyWith(color: AppColors.scorifyMint),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
