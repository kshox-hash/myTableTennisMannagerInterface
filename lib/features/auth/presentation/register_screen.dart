import "package:flutter/material.dart";
import "package:myttmi/routes/cyber_page_route.dart";
import "package:myttmi/core/constants/app_colors.dart";
import "package:myttmi/core/constants/app_typography.dart";
import "package:myttmi/core/storage/session_storage.dart";
import "package:myttmi/core/ui/auth_text_field.dart";
import "package:myttmi/core/ui/glass_card.dart";
import "package:myttmi/core/ui/pill_button.dart";
import "package:myttmi/core/ui/prism_background.dart";
import "package:myttmi/core/ui/top_header.dart";
import "package:myttmi/features/auth/api/auth_api.dart";
import "package:myttmi/features/shell/app_shell.dart";

const _categories = ["Sub-13", "Sub-15", "Sub-18", "Juvenil", "Todo Competidor", "Máster"];

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _email = TextEditingController();
  final _pass = TextEditingController();
  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _country = TextEditingController();
  final _idDocument = TextEditingController();
  final _club = TextEditingController();

  DateTime? _birthDate;
  String? _gender;
  String? _category;

  bool loading = false;

  final api = AuthApi();
  final storage = SessionStorage();

  Future<void> _pickBirthDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(now.year - 20, now.month, now.day),
      firstDate: DateTime(now.year - 100),
      lastDate: now,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.scorifyMint,
              onPrimary: AppColors.scorifyOnMint,
              surface: AppColors.scorifyDeep,
              onSurface: AppColors.scorifyText,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) setState(() => _birthDate = picked);
  }

  String _formatDate(DateTime d) {
    String two(int n) => n.toString().padLeft(2, "0");
    return "${two(d.day)}/${two(d.month)}/${d.year}";
  }

  Future<void> _register() async {
    if (_email.text.trim().isEmpty || _pass.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Email y contraseña son obligatorios")),
      );
      return;
    }

    setState(() => loading = true);

    try {
      // Esta app solo registra jugadores — el rol admin se gestiona desde la web.
      final resp = await api.register(
        email: _email.text,
        password: _pass.text,
        role: "player",
        firstName: _firstName.text.trim(),
        lastName: _lastName.text.trim(),
        gender: _gender,
        clubName: _club.text.trim(),
        birthDate: _birthDate == null
            ? null
            : "${_birthDate!.year.toString().padLeft(4, '0')}-"
                "${_birthDate!.month.toString().padLeft(2, '0')}-"
                "${_birthDate!.day.toString().padLeft(2, '0')}",
        country: _country.text.trim(),
        idDocument: _idDocument.text.trim(),
        category: _category,
      );

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
    _firstName.dispose();
    _lastName.dispose();
    _country.dispose();
    _idDocument.dispose();
    _club.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scorifyBg,
      body: PrismBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const TopHeader(title: "Crear cuenta"),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: GlassCard(
                      variant: GlassCardVariant.elevated,
                      padding: const EdgeInsets.all(22),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Datos del jugador", style: AppTypography.h1),
                          const SizedBox(height: 4),
                          Text(
                            "Se usan para tu categoría y tu ficha de jugador.",
                            style: AppTypography.bodyMuted,
                          ),
                          const SizedBox(height: 16),

                          AuthTextField(controller: _firstName, label: "Nombre", icon: Icons.badge_outlined),
                          const SizedBox(height: 14),
                          AuthTextField(controller: _lastName, label: "Apellido", icon: Icons.badge_outlined),
                          const SizedBox(height: 14),

                          InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: _pickBirthDate,
                            child: InputDecorator(
                              decoration: InputDecoration(
                                labelText: "Fecha de nacimiento",
                                labelStyle: AppTypography.bodyMuted,
                                prefixIcon: const Icon(Icons.cake_outlined, color: AppColors.scorifyTextMuted, size: 20),
                                filled: true,
                                fillColor: AppColors.scorifyCardFill,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide.none,
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: const BorderSide(color: AppColors.scorifyCardBorder),
                                ),
                              ),
                              child: Text(
                                _birthDate == null ? "Seleccionar fecha" : _formatDate(_birthDate!),
                                style: AppTypography.bodyText,
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),

                          DropdownButtonFormField<String>(
                            initialValue: _category,
                            dropdownColor: AppColors.scorifyDeep,
                            iconEnabledColor: AppColors.scorifyTextMuted,
                            style: AppTypography.bodyText,
                            decoration: InputDecoration(
                              labelText: "Categoría",
                              labelStyle: AppTypography.bodyMuted,
                              prefixIcon: const Icon(Icons.emoji_events_outlined, color: AppColors.scorifyTextMuted, size: 20),
                              filled: true,
                              fillColor: AppColors.scorifyCardFill,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide.none,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: const BorderSide(color: AppColors.scorifyCardBorder),
                              ),
                            ),
                            items: _categories
                                .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                                .toList(),
                            onChanged: (v) => setState(() => _category = v),
                          ),
                          const SizedBox(height: 14),

                          DropdownButtonFormField<String>(
                            initialValue: _gender,
                            dropdownColor: AppColors.scorifyDeep,
                            iconEnabledColor: AppColors.scorifyTextMuted,
                            style: AppTypography.bodyText,
                            decoration: InputDecoration(
                              labelText: "Género",
                              labelStyle: AppTypography.bodyMuted,
                              prefixIcon: const Icon(Icons.wc_outlined, color: AppColors.scorifyTextMuted, size: 20),
                              filled: true,
                              fillColor: AppColors.scorifyCardFill,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide.none,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: const BorderSide(color: AppColors.scorifyCardBorder),
                              ),
                            ),
                            items: const [
                              DropdownMenuItem(value: "male", child: Text("Masculino")),
                              DropdownMenuItem(value: "female", child: Text("Femenino")),
                              DropdownMenuItem(value: "other", child: Text("Otro")),
                            ],
                            onChanged: (v) => setState(() => _gender = v),
                          ),
                          const SizedBox(height: 14),

                          AuthTextField(controller: _country, label: "País", icon: Icons.public_outlined),
                          const SizedBox(height: 14),
                          AuthTextField(
                            controller: _idDocument,
                            label: "RUT / Cédula de identidad",
                            icon: Icons.perm_identity_outlined,
                          ),
                          const SizedBox(height: 14),
                          AuthTextField(controller: _club, label: "Club (opcional)", icon: Icons.groups_2_outlined),

                          const SizedBox(height: 22),
                          Divider(color: AppColors.scorifyCardBorder),
                          const SizedBox(height: 8),
                          Text("Cuenta", style: AppTypography.h1),
                          const SizedBox(height: 12),

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
                              ? const Center(
                                  child: SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(strokeWidth: 2.4, color: AppColors.scorifyMint),
                                  ),
                                )
                              : Center(
                                  child: SolidPillButton(label: "CREAR CUENTA", onTap: _register),
                                ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
