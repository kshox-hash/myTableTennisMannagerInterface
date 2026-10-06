import "package:myttmi/features/shell/splash_gate.dart";
import "package:myttmi/core/ui/app_button.dart";
import "package:flutter/material.dart";
import "package:myttmi/core/ui/app_toast.dart";
import "package:myttmi/routes/cyber_page_route.dart";
import "package:myttmi/core/constants/app_colors.dart";
import "package:myttmi/core/constants/app_typography.dart";
import "package:myttmi/core/constants/countries.dart";
import "package:myttmi/core/storage/session_storage.dart";
import "package:myttmi/core/ui/auth_text_field.dart";
import "package:myttmi/core/ui/glass_card.dart";
import "package:myttmi/core/ui/prism_background.dart";
import "package:myttmi/core/ui/top_header.dart";
import "package:myttmi/features/auth/api/auth_api.dart";
import "package:myttmi/features/profile/api/clubs_api.dart";
import "package:myttmi/features/profile/models/club_model.dart";

const _handLabel = {"right-handed": "Diestro", "left-handed": "Zurdo"};

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

  DateTime? _birthDate;
  String? _gender;
  String? _dominantHand;
  String? _country;
  String? _selectedClubId;

  bool loading = false;

  final api = AuthApi();
  final storage = SessionStorage();
  final clubsApi = ClubsApi();
  List<PublicClub> _clubs = [];

  @override
  void initState() {
    super.initState();
    // Endpoint público (sin login) — el club tiene que poder elegirse acá,
    // antes de que exista sesión.
    clubsApi.list().then((clubs) {
      if (mounted) setState(() => _clubs = clubs);
    }).catchError((_) {});
  }

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
      showToast(context, "Email y contraseña son obligatorios", error: true);
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
        dominantHand: _dominantHand,
        birthDate: _birthDate == null
            ? null
            : "${_birthDate!.year.toString().padLeft(4, '0')}-"
                "${_birthDate!.month.toString().padLeft(2, '0')}-"
                "${_birthDate!.day.toString().padLeft(2, '0')}",
        country: _country,
      );

      await storage.saveSession(
        token: resp.token,
        role: resp.user.role,
        userId: resp.user.idUser,
        email: resp.user.email,
      );

      // El pedido de club recién puede mandarse con la sesión ya activa
      // (guardada arriba) — si falla no bloquea el registro, se puede pedir
      // después desde Perfil.
      if (_selectedClubId != null) {
        await clubsApi.requestJoin(_selectedClubId!).catchError((_) {});
      }

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

  @override
  void dispose() {
    _email.dispose();
    _pass.dispose();
    _firstName.dispose();
    _lastName.dispose();
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

                          AuthTextField(controller: _firstName, label: "Nombre", icon: Icons.badge_rounded),
                          const SizedBox(height: 14),
                          AuthTextField(controller: _lastName, label: "Apellido", icon: Icons.badge_rounded),
                          const SizedBox(height: 14),

                          InkWell(
                            borderRadius: BorderRadius.circular(2),
                            onTap: _pickBirthDate,
                            child: InputDecorator(
                              decoration: InputDecoration(
                                labelText: "Fecha de nacimiento",
                                labelStyle: AppTypography.bodyMuted,
                                prefixIcon: const Icon(Icons.cake_rounded, color: AppColors.scorifyTextMuted, size: 20),
                                filled: true,
                                fillColor: AppColors.scorifyInput,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(2),
                                  borderSide: BorderSide.none,
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(2),
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
                            initialValue: _gender,
                            dropdownColor: AppColors.scorifyDeep,
                            iconEnabledColor: AppColors.scorifyTextMuted,
                            style: AppTypography.bodyText,
                            decoration: InputDecoration(
                              labelText: "Género",
                              labelStyle: AppTypography.bodyMuted,
                              prefixIcon: const Icon(Icons.wc_rounded, color: AppColors.scorifyTextMuted, size: 20),
                              filled: true,
                              fillColor: AppColors.scorifyInput,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(2),
                                borderSide: BorderSide.none,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(2),
                                borderSide: const BorderSide(color: AppColors.scorifyCardBorder),
                              ),
                            ),
                            items: const [
                              DropdownMenuItem(value: "male", child: Text("Masculino")),
                              DropdownMenuItem(value: "female", child: Text("Femenino")),
                            ],
                            onChanged: (v) => setState(() => _gender = v),
                          ),
                          const SizedBox(height: 14),

                          DropdownButtonFormField<String>(
                            initialValue: _dominantHand,
                            dropdownColor: AppColors.scorifyDeep,
                            iconEnabledColor: AppColors.scorifyTextMuted,
                            style: AppTypography.bodyText,
                            decoration: InputDecoration(
                              labelText: "Mano con la que juegas",
                              labelStyle: AppTypography.bodyMuted,
                              prefixIcon: const Icon(Icons.sports_tennis_rounded, color: AppColors.scorifyTextMuted, size: 20),
                              filled: true,
                              fillColor: AppColors.scorifyInput,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(2),
                                borderSide: BorderSide.none,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(2),
                                borderSide: const BorderSide(color: AppColors.scorifyCardBorder),
                              ),
                            ),
                            items: _handLabel.entries
                                .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
                                .toList(),
                            onChanged: (v) => setState(() => _dominantHand = v),
                          ),
                          const SizedBox(height: 14),

                          DropdownButtonFormField<String>(
                            initialValue: _country,
                            dropdownColor: AppColors.scorifyDeep,
                            iconEnabledColor: AppColors.scorifyTextMuted,
                            style: AppTypography.bodyText,
                            menuMaxHeight: 360,
                            // isExpanded: nombres largos ("República
                            // Democrática del Congo") desbordaban el botón
                            // cerrado — sin esto el DropdownButton se dimensiona
                            // a su contenido intrínseco en vez de al ancho
                            // disponible.
                            isExpanded: true,
                            decoration: InputDecoration(
                              labelText: "País",
                              labelStyle: AppTypography.bodyMuted,
                              prefixIcon: const Icon(Icons.public_rounded, color: AppColors.scorifyTextMuted, size: 20),
                              filled: true,
                              fillColor: AppColors.scorifyInput,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(2),
                                borderSide: BorderSide.none,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(2),
                                borderSide: const BorderSide(color: AppColors.scorifyCardBorder),
                              ),
                            ),
                            items: kCountries
                                .map((c) => DropdownMenuItem(
                                      value: c,
                                      child: Text(c, overflow: TextOverflow.ellipsis),
                                    ))
                                .toList(),
                            onChanged: (v) => setState(() => _country = v),
                          ),
                          const SizedBox(height: 14),

                          DropdownButtonFormField<String>(
                            initialValue: _selectedClubId,
                            dropdownColor: AppColors.scorifyDeep,
                            iconEnabledColor: AppColors.scorifyTextMuted,
                            style: AppTypography.bodyText,
                            // isExpanded: el nombre del club lo escribe cada
                            // admin libremente, puede ser largo.
                            isExpanded: true,
                            decoration: InputDecoration(
                              labelText: "Club (opcional)",
                              labelStyle: AppTypography.bodyMuted,
                              prefixIcon: const Icon(Icons.groups_2_rounded, color: AppColors.scorifyTextMuted, size: 20),
                              filled: true,
                              fillColor: AppColors.scorifyInput,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(2),
                                borderSide: BorderSide.none,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(2),
                                borderSide: const BorderSide(color: AppColors.scorifyCardBorder),
                              ),
                            ),
                            hint: Text(
                              _clubs.isEmpty ? "No existen clubes registrados" : "Sin club por ahora",
                              style: AppTypography.bodyMuted,
                            ),
                            items: _clubs
                                .map((c) => DropdownMenuItem(
                                      value: c.idClub,
                                      child: Text(c.name, overflow: TextOverflow.ellipsis),
                                    ))
                                .toList(),
                            onChanged: _clubs.isEmpty ? null : (v) => setState(() => _selectedClubId = v),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Le llega una solicitud al club — lo confirma su organizador.",
                            style: AppTypography.bodyMuted,
                          ),

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
                              : AppButton(label: "Crear cuenta", onPressed: _register),
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
