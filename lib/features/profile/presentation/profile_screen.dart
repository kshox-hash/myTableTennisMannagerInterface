import "package:flutter/material.dart";
import "package:myttmi/routes/cyber_page_route.dart";
import "package:myttmi/core/constants/app_colors.dart";
import "package:myttmi/core/constants/app_typography.dart";
import "package:myttmi/core/storage/session_storage.dart";
import "package:myttmi/core/ui/achievement_row.dart";
import "package:myttmi/core/ui/auth_text_field.dart";
import "package:myttmi/core/ui/glass_card.dart";
import "package:myttmi/core/ui/identicon.dart";
import "package:myttmi/core/ui/list_states.dart";
import "package:myttmi/core/ui/pill_button.dart";
import "package:myttmi/core/ui/prism_background.dart";
import "package:myttmi/core/ui/top_header.dart";
import "package:myttmi/features/player/api/player_api.dart";
import "package:myttmi/features/player/models/achievement_model.dart";
import "package:myttmi/features/profile/api/profile_api.dart";
import "package:myttmi/features/profile/models/profile_model.dart";
import "package:myttmi/features/shell/splash_gate.dart";

const _categories = [
  "Sub-13",
  "Sub-15",
  "Sub-18",
  "Juvenil",
  "Todo Competidor",
  "Máster",
];

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final api = ProfileApi();
  final _playerApi = PlayerApi();
  late Future<UserProfile> future;
  Future<List<PlayerAchievement>>? achievementsFuture;
  bool _editing = false;
  bool _saving = false;

  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _clubCtrl = TextEditingController();
  final _countryCtrl = TextEditingController();
  final _idDocumentCtrl = TextEditingController();
  String? _gender;
  String? _category;
  DateTime? _birthDate;

  @override
  void initState() {
    super.initState();
    future = api.getMe();
    _loadAchievements();
  }

  Future<void> _loadAchievements() async {
    final userId = await SessionStorage().getUserId();
    if (userId == null || !mounted) return;
    setState(
      () => achievementsFuture = _playerApi.getPlayerAchievements(userId),
    );
  }

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _clubCtrl.dispose();
    _countryCtrl.dispose();
    _idDocumentCtrl.dispose();
    super.dispose();
  }

  String _genderLabel(String? g) {
    switch (g) {
      case "male":
        return "Masculino";
      case "female":
        return "Femenino";
      case "other":
        return "Otro";
      default:
        return "Sin especificar";
    }
  }

  String _formatDate(DateTime? dt) {
    if (dt == null) return "—";
    final d = dt.toLocal();
    String two(int n) => n.toString().padLeft(2, "0");
    return "${two(d.day)}-${two(d.month)}-${d.year}  ${two(d.hour)}:${two(d.minute)}";
  }

  String _formatBirthDate(DateTime? dt) {
    if (dt == null) return "Seleccionar fecha";
    String two(int n) => n.toString().padLeft(2, "0");
    return "${two(dt.day)}/${two(dt.month)}/${dt.year}";
  }

  Future<void> _pickBirthDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthDate ?? DateTime(now.year - 20, now.month, now.day),
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

  Future<void> _logout() async {
    await SessionStorage().clear();
    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      CyberPageRoute(builder: (_) => const SplashGate()),
      (_) => false,
    );
  }

  Future<void> _refresh() async {
    setState(() {
      future = api.getMe();
    });
    await future;
    await _loadAchievements();
  }

  void _startEditing(UserProfile p) {
    _firstNameCtrl.text = p.firstName ?? "";
    _lastNameCtrl.text = p.lastName ?? "";
    _clubCtrl.text = p.club ?? "";
    _countryCtrl.text = p.country ?? "";
    _idDocumentCtrl.text = p.idDocument ?? "";
    _gender = p.gender;
    _category = p.category;
    _birthDate = p.birthDate;
    setState(() => _editing = true);
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await api.updateMe(
        firstName: _firstNameCtrl.text.trim(),
        lastName: _lastNameCtrl.text.trim(),
        gender: _gender,
        clubName: _clubCtrl.text.trim(),
        country: _countryCtrl.text.trim(),
        idDocument: _idDocumentCtrl.text.trim(),
        category: _category,
        birthDate: _birthDate == null
            ? null
            : "${_birthDate!.year.toString().padLeft(4, '0')}-"
                  "${_birthDate!.month.toString().padLeft(2, '0')}-"
                  "${_birthDate!.day.toString().padLeft(2, '0')}",
      );
      if (!mounted) return;
      setState(() => _editing = false);
      await _refresh();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Perfil actualizado")));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
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
                TopHeader(
                  title: "Perfil",
                  actions: [
                    HeaderIconButton(
                      icon: Icons.logout_rounded,
                      onTap: _logout,
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Expanded(
                  child: FutureBuilder<UserProfile>(
                    future: future,
                    builder: (context, snap) {
                      if (snap.connectionState == ConnectionState.waiting) {
                        return const LoadingState();
                      }
                      if (snap.hasError) {
                        return ErrorStateView(
                          message:
                              "No pudimos cargar tu perfil.\n${snap.error}",
                          onRetry: _refresh,
                        );
                      }

                      final p = snap.data!;

                      if (_editing) {
                        return ListView(
                          children: [
                            AuthTextField(
                              controller: _firstNameCtrl,
                              label: "Nombre",
                              icon: Icons.badge_outlined,
                            ),
                            const SizedBox(height: 12),
                            AuthTextField(
                              controller: _lastNameCtrl,
                              label: "Apellido",
                              icon: Icons.badge_outlined,
                            ),
                            const SizedBox(height: 12),
                            InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: _pickBirthDate,
                              child: InputDecorator(
                                decoration: InputDecoration(
                                  labelText: "Fecha de nacimiento",
                                  labelStyle: AppTypography.bodyMuted,
                                  prefixIcon: const Icon(
                                    Icons.cake_outlined,
                                    color: AppColors.scorifyTextMuted,
                                    size: 20,
                                  ),
                                  filled: true,
                                  fillColor: AppColors.scorifyCardFill,
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: const BorderSide(
                                      color: AppColors.scorifyCardBorder,
                                    ),
                                  ),
                                ),
                                child: Text(
                                  _formatBirthDate(_birthDate),
                                  style: AppTypography.bodyText,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            DropdownButtonFormField<String>(
                              initialValue: _category,
                              dropdownColor: AppColors.scorifyDeep,
                              iconEnabledColor: AppColors.scorifyTextMuted,
                              style: AppTypography.bodyText,
                              decoration: InputDecoration(
                                labelText: "Categoría",
                                labelStyle: AppTypography.bodyMuted,
                                filled: true,
                                fillColor: AppColors.scorifyCardFill,
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: const BorderSide(
                                    color: AppColors.scorifyCardBorder,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: const BorderSide(
                                    color: AppColors.scorifyMint,
                                    width: 1.4,
                                  ),
                                ),
                              ),
                              items: _categories
                                  .map(
                                    (c) => DropdownMenuItem(
                                      value: c,
                                      child: Text(c),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (v) => setState(() => _category = v),
                            ),
                            const SizedBox(height: 12),
                            DropdownButtonFormField<String>(
                              initialValue: _gender,
                              dropdownColor: AppColors.scorifyDeep,
                              iconEnabledColor: AppColors.scorifyTextMuted,
                              style: AppTypography.bodyText,
                              decoration: InputDecoration(
                                labelText: "Género",
                                labelStyle: AppTypography.bodyMuted,
                                filled: true,
                                fillColor: AppColors.scorifyCardFill,
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: const BorderSide(
                                    color: AppColors.scorifyCardBorder,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: const BorderSide(
                                    color: AppColors.scorifyMint,
                                    width: 1.4,
                                  ),
                                ),
                              ),
                              items: const [
                                DropdownMenuItem(
                                  value: "male",
                                  child: Text("Masculino"),
                                ),
                                DropdownMenuItem(
                                  value: "female",
                                  child: Text("Femenino"),
                                ),
                                DropdownMenuItem(
                                  value: "other",
                                  child: Text("Otro"),
                                ),
                              ],
                              onChanged: (v) => setState(() => _gender = v),
                            ),
                            const SizedBox(height: 12),
                            AuthTextField(
                              controller: _countryCtrl,
                              label: "País",
                              icon: Icons.public_outlined,
                            ),
                            const SizedBox(height: 12),
                            AuthTextField(
                              controller: _idDocumentCtrl,
                              label: "RUT / Cédula de identidad",
                              icon: Icons.perm_identity_outlined,
                            ),
                            const SizedBox(height: 12),
                            AuthTextField(
                              controller: _clubCtrl,
                              label: "Club (opcional)",
                              icon: Icons.groups_2_outlined,
                            ),
                            const SizedBox(height: 20),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinePillButton(
                                    label: "Cancelar",
                                    onTap: _saving
                                        ? () {}
                                        : () =>
                                              setState(() => _editing = false),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _saving
                                      ? const Center(
                                          child: SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2.2,
                                              color: AppColors.scorifyMint,
                                            ),
                                          ),
                                        )
                                      : SolidPillButton(
                                          label: "Guardar",
                                          onTap: _save,
                                        ),
                                ),
                              ],
                            ),
                          ],
                        );
                      }

                      return RefreshIndicator(
                        color: AppColors.scorifyMint,
                        onRefresh: _refresh,
                        child: ListView(
                          children: [
                            GlassCard(
                              child: Row(
                                children: [
                                  Identicon(seed: p.idUser, size: 52),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          p.displayName,
                                          style: AppTypography.h1,
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          "${p.email} · Jugador",
                                          style: AppTypography.bodyMuted,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            if (achievementsFuture != null)
                              FutureBuilder<List<PlayerAchievement>>(
                                future: achievementsFuture,
                                builder: (context, aSnap) => AchievementsCard(
                                  achievements: aSnap.data ?? [],
                                ),
                              ),
                            GlassCard(
                              child: Column(
                                children: [
                                  _ProfileRow(
                                    icon: Icons.emoji_events_outlined,
                                    label: "Categoría",
                                    value: (p.category ?? "").trim().isEmpty
                                        ? "Sin categoría"
                                        : p.category!,
                                  ),
                                  const SizedBox(height: 12),
                                  _ProfileRow(
                                    icon: Icons.cake_outlined,
                                    label: "Edad",
                                    value: p.age == null
                                        ? "—"
                                        : "${p.age} años",
                                  ),
                                  const SizedBox(height: 12),
                                  _ProfileRow(
                                    icon: Icons.wc_outlined,
                                    label: "Género",
                                    value: _genderLabel(p.gender),
                                  ),
                                  const SizedBox(height: 12),
                                  _ProfileRow(
                                    icon: Icons.groups_2_outlined,
                                    label: "Club",
                                    value: (p.club ?? "").trim().isEmpty
                                        ? "Sin club"
                                        : p.club!,
                                  ),
                                  const SizedBox(height: 12),
                                  _ProfileRow(
                                    icon: Icons.public_outlined,
                                    label: "País",
                                    value: (p.country ?? "").trim().isEmpty
                                        ? "Sin especificar"
                                        : p.country!,
                                  ),
                                  const SizedBox(height: 12),
                                  _ProfileRow(
                                    icon: Icons.perm_identity_outlined,
                                    label: "RUT/Cédula",
                                    value: (p.idDocument ?? "").trim().isEmpty
                                        ? "Sin especificar"
                                        : p.idDocument!,
                                  ),
                                  const SizedBox(height: 12),
                                  _ProfileRow(
                                    icon: Icons.calendar_today_outlined,
                                    label: "Creado en",
                                    value: _formatDate(p.createdAt),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            SolidPillButton(
                              icon: Icons.edit_outlined,
                              label: "Editar perfil",
                              onTap: () => _startEditing(p),
                            ),
                          ],
                        ),
                      );
                    },
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

class _ProfileRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _ProfileRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.scorifyMint, size: 18),
        const SizedBox(width: 10),
        Expanded(child: Text(label, style: AppTypography.bodyMuted)),
        Text(
          value,
          style: AppTypography.bodyText.copyWith(fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}
