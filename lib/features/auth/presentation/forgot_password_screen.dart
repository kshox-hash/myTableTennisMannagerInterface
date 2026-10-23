import "package:flutter/material.dart";
import "package:myttmi/core/constants/app_colors.dart";
import "package:myttmi/core/constants/app_typography.dart";
import "package:myttmi/core/storage/session_storage.dart";
import "package:myttmi/core/ui/app_button.dart";
import "package:myttmi/core/ui/app_toast.dart";
import "package:myttmi/core/ui/auth_text_field.dart";
import "package:myttmi/core/ui/glass_card.dart";
import "package:myttmi/core/ui/prism_background.dart";
import "package:myttmi/core/ui/top_header.dart";
import "package:myttmi/features/auth/api/auth_api.dart";
import "package:myttmi/features/shell/splash_gate.dart";
import "package:myttmi/routes/cyber_page_route.dart";

/// Recuperar contraseña en dos pasos: 1) el email → el servidor manda un
/// código de 6 dígitos; 2) código + contraseña nueva → queda la sesión
/// iniciada (entra directo, sin volver al login).
class ForgotPasswordScreen extends StatefulWidget {
  final String? initialEmail;
  const ForgotPasswordScreen({super.key, this.initialEmail});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _api = AuthApi();
  late final _email = TextEditingController(text: widget.initialEmail ?? "");
  final _code = TextEditingController();
  final _pass = TextEditingController();
  final _pass2 = TextEditingController();
  bool _codeSent = false;
  bool _loading = false;

  @override
  void dispose() {
    _email.dispose();
    _code.dispose();
    _pass.dispose();
    _pass2.dispose();
    super.dispose();
  }

  Future<void> _sendCode() async {
    final email = _email.text.trim();
    if (!email.contains("@")) {
      showToast(context, "Escribe el email de tu cuenta.", error: true);
      return;
    }
    setState(() => _loading = true);
    try {
      await _api.forgotPassword(email);
      if (!mounted) return;
      setState(() => _codeSent = true);
      showToast(context, "Si el email tiene una cuenta, te llegará un código en unos minutos.");
    } catch (e) {
      if (mounted) showToast(context, e.toString(), error: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _reset() async {
    if (_code.text.trim().length != 6) {
      showToast(context, "El código tiene 6 dígitos.", error: true);
      return;
    }
    if (_pass.text.length < 8) {
      showToast(context, "La contraseña debe tener al menos 8 caracteres.", error: true);
      return;
    }
    if (_pass.text != _pass2.text) {
      showToast(context, "Las contraseñas no coinciden.", error: true);
      return;
    }
    setState(() => _loading = true);
    try {
      final resp = await _api.resetPassword(email: _email.text, code: _code.text, password: _pass.text);
      await SessionStorage().saveSession(
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
      if (mounted) showToast(context, e.toString(), error: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scorifyBg,
      body: PrismBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const TopHeader(title: "Recuperar contraseña"),
              const SizedBox(height: 18),
              Text(
                _codeSent
                    ? "Revisa tu correo (también la carpeta de spam) y escribe el código de 6 dígitos junto a tu contraseña nueva."
                    : "Escribe el email de tu cuenta y te enviaremos un código para crear una contraseña nueva.",
                style: AppTypography.bodyMuted,
              ),
              const SizedBox(height: 18),
              GlassCard(
                padding: const EdgeInsets.all(22),
                child: Column(
                  children: [
                    AuthTextField(
                      controller: _email,
                      label: "Email",
                      icon: Icons.mail_outline_rounded,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    if (_codeSent) ...[
                      const SizedBox(height: 14),
                      AuthTextField(
                        controller: _code,
                        label: "Código de 6 dígitos",
                        icon: Icons.pin_outlined,
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 14),
                      AuthTextField(controller: _pass, label: "Contraseña nueva", icon: Icons.lock_outline_rounded, obscureText: true),
                      const SizedBox(height: 14),
                      AuthTextField(controller: _pass2, label: "Repite la contraseña", icon: Icons.lock_outline_rounded, obscureText: true),
                    ],
                    const SizedBox(height: 22),
                    AppButton(
                      label: _codeSent ? "Cambiar contraseña" : "Enviar código",
                      loading: _loading,
                      onPressed: _codeSent ? _reset : _sendCode,
                    ),
                    if (_codeSent) ...[
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: _loading ? null : _sendCode,
                        child: Text("Enviar otro código", style: AppTypography.bodyMuted.copyWith(color: AppColors.scorifyMint)),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
