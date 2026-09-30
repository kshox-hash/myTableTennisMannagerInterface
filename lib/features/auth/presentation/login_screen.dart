import "package:flutter/material.dart";
import "package:google_sign_in/google_sign_in.dart";
import "package:myttmi/core/constants/app_config.dart";
import "package:myttmi/routes/app_routes.dart";
import "package:myttmi/core/ui/app_toast.dart";
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

      // La app es la parte de jugador: una cuenta con rol de administrador
      // (organiza un club/torneos en la web y además juega) entra igual y se
      // usa como jugador — el servidor acepta su sesión en las rutas de jugador.
      await storage.saveSession(
        token: resp.token,
        role: "player",
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
      showToast(context, e.toString(), error: true);
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _loginGoogle() async {
    setState(() => loading = true);
    try {
      final google = GoogleSignIn(scopes: const ["email"], serverClientId: AppConfig.googleWebClientId);
      await google.signOut(); // que siempre deje elegir la cuenta
      final account = await google.signIn();
      if (account == null) return; // canceló
      final idToken = (await account.authentication).idToken;
      if (idToken == null) throw Exception("Google no entregó el token. Intenta de nuevo.");

      final r = await api.loginWithGoogle(idToken);
      await storage.saveSession(
        token: r.auth.token,
        role: "player",
        userId: r.auth.user.idUser,
        email: r.auth.user.email,
      );
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(context, CyberPageRoute(builder: (_) => const AppShell()), (_) => false);
      // Cuenta nueva por Google: falta la ficha (país, género, nacimiento).
      if (r.profileIncomplete) {
        Navigator.pushNamed(context, AppRoutes.profile);
        showToast(context, "¡Bienvenido! Completa tu perfil (país, género y fecha de nacimiento).");
      }
    } catch (e) {
      if (!mounted) return;
      showToast(context, e.toString(), error: true);
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
                                  child: SolidPillButton(label: "Entrar", onTap: _login),
                                ),
                              ),
                        const SizedBox(height: 18),
                        Row(
                          children: [
                            const Expanded(child: Divider(color: AppColors.scorifySurface2)),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 10),
                              child: Text("o", style: AppTypography.bodyMuted),
                            ),
                            const Expanded(child: Divider(color: AppColors.scorifySurface2)),
                          ],
                        ),
                        const SizedBox(height: 14),
                        SizedBox(
                          width: double.infinity,
                          height: 46,
                          child: OutlinedButton(
                            onPressed: loading ? null : _loginGoogle,
                            style: OutlinedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: const Color(0xFF1F1F1F),
                              side: BorderSide.none,
                              shape: const StadiumBorder(),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text("G", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF4285F4))),
                                SizedBox(width: 10),
                                Text("Continuar con Google", style: TextStyle(fontFamily: "Montserrat", fontSize: 14, fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
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
