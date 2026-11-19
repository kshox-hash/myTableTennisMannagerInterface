import "package:myttmi/core/ui/panel_style.dart";
import "package:myttmi/features/auth/presentation/login_background.dart";
import "package:myttmi/core/monitoring.dart";
import "package:myttmi/features/shell/splash_gate.dart";
import "package:myttmi/core/ui/app_button.dart";
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
import "package:myttmi/core/ui/glass_card.dart";
import "package:myttmi/features/auth/api/auth_api.dart";
import "package:myttmi/features/auth/presentation/register_screen.dart";
import "package:myttmi/features/auth/presentation/forgot_password_screen.dart";

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
      Monitoring.log("inicio_sesion", {"metodo": "email"});
      await storage.saveSession(
        token: resp.token,
        role: "player",
        userId: resp.user.idUser,
        email: resp.user.email,
      );

      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        CyberPageRoute(waitForData: false, builder: (_) => const SplashGate(afterLogin: true)),
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
      Monitoring.log("inicio_sesion", {"metodo": "google"});
      await storage.saveSession(
        token: r.auth.token,
        role: "player",
        userId: r.auth.user.idUser,
        email: r.auth.user.email,
      );
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(context, CyberPageRoute(waitForData: false, builder: (_) => const SplashGate(afterLogin: true)), (_) => false);
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
      // Foto del jugador con cenizas blancas; logo y formulario abajo.
      body: LoginBackground(
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, box) => SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: box.maxHeight - 44),
                // Logo arriba (no tapa la cara del jugador) y el formulario abajo.
                child: IntrinsicHeight(
              child: Column(
                mainAxisSize: MainAxisSize.max,
                children: [
                  // Logo 3D metálico en vertical: la M arriba y "MyTTM ·
                  // Gestión de torneos y clubes" abajo (armado del logo
                  // horizontal). Discreto, 190 de ancho; el asset viene en
                  // 1x/2x/3x de ese tamaño (assets/images/2.0x, 3.0x): no se
                  // achica en el teléfono y los bordes no se ven dentados.
                  const SizedBox(
                    width: 150,
                    child: Image(
                      image: AssetImage("assets/images/logo-stacked.png"),
                      fit: BoxFit.contain,
                      filterQuality: FilterQuality.medium,
                      isAntiAlias: true,
                      semanticLabel: "MyTTM",
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Bajada como texto real (dentro de la imagen quedaba
                  // diminuta), con la línea verde a cada lado como el logo.
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(width: 22, height: 1.5, color: AppColors.loginAccent),
                      const SizedBox(width: 8),
                      const Text(
                        "GESTIÓN DE TORNEOS Y CLUBES",
                        style: TextStyle(
                          fontFamily: "Montserrat",
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.8,
                          color: Color(0xFFE6ECEA),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(width: 22, height: 1.5, color: AppColors.loginAccent),
                    ],
                  ),
                  // Espacio libre al medio: ahí se ve el jugador.
                  const Spacer(),
                  const SizedBox(height: 16),
                  GlassCard(
                    variant: GlassCardVariant.elevated,
                    fillColor: Colors.transparent, // sin tarjeta: se ve el jugador detrás
                    padding: const EdgeInsets.fromLTRB(2, 0, 2, 0),
                    child: Column(
                      children: [
                        AuthTextField(
                          controller: _email,
                          label: "Correo",
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
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () => Navigator.push(
                              context,
                              CyberPageRoute(waitForData: false, builder: (_) => ForgotPasswordScreen(initialEmail: _email.text.trim())),
                            ),
                            child: Text(
                              "¿Olvidaste tu contraseña?",
                              style: AppTypography.bodyMuted.copyWith(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.loginAccent),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        loading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(strokeWidth: 2.4, color: AppColors.loginAccent),
                              )
                            : AppButton(
                                label: "Entrar",
                                onPressed: _login,
                                height: 46,
                                radius: 0,
                                // Plano, como el resto de la app (sin degradado).
                                gradient: const LinearGradient(colors: [AppColors.scorifyMint, AppColors.scorifyMint]),
                                foreground: AppColors.loginOnAccent,
                              ),
                        const SizedBox(height: 16),
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
                            // Botón oficial de Google (tema claro): fondo
                            // blanco, texto casi negro y la "G" de 4 colores.
                            // Oscuro con borde fino: no le gana a "Entrar" (la acción principal).
                            style: OutlinedButton.styleFrom(
                              backgroundColor: const Color(0x66000000),
                              foregroundColor: Colors.white,
                              disabledBackgroundColor: const Color(0x33000000),
                              side: const BorderSide(color: Color(0x40FFFFFF)),
                              shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Image(image: AssetImage("assets/images/google_g.png"), width: 20, height: 20, filterQuality: FilterQuality.medium),
                                SizedBox(width: 12),
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
                          child: Text.rich(
                            TextSpan(children: [
                              TextSpan(text: "¿No tienes cuenta? ", style: AppTypography.bodyMuted.copyWith(fontSize: 14, color: const Color(0xCCFFFFFF))),
                              TextSpan(text: "Crea una", style: AppTypography.bodyMuted.copyWith(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.loginAccent)),
                            ]),
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
        ),
      ),
    );
  }
}
