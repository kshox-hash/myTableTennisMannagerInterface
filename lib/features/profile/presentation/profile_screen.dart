import "package:myttmi/core/ui/section_card.dart";
import "package:myttmi/core/ui/app_button.dart";
import "package:flutter/material.dart";
import "package:myttmi/core/ui/user_avatar.dart";
import "package:myttmi/core/ui/app_toast.dart";
import "package:myttmi/routes/cyber_page_route.dart";
import "package:myttmi/core/constants/app_colors.dart";
import "package:myttmi/core/ui/confirm_dialog.dart";
import "package:myttmi/core/constants/app_typography.dart";
import "package:myttmi/core/storage/session_storage.dart";
import "package:myttmi/core/ui/achievement_row.dart";
import "package:myttmi/core/ui/glass_card.dart";
import "package:myttmi/core/ui/identicon.dart";
import "package:myttmi/core/ui/list_states.dart";
import "package:myttmi/core/ui/pill_button.dart";
import "package:myttmi/core/ui/prism_background.dart";
import "package:myttmi/core/ui/top_header.dart";
import "package:myttmi/features/player/api/player_api.dart";
import "package:myttmi/features/player/models/achievement_model.dart";
import "package:myttmi/features/profile/api/clubs_api.dart";
import "package:myttmi/features/profile/api/profile_api.dart";
import "package:myttmi/features/profile/models/club_model.dart";
import "package:myttmi/features/profile/models/profile_model.dart";
import "package:myttmi/features/shell/splash_gate.dart";
import "package:myttmi/core/push/push_service.dart";

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
  final _countryCtrl = TextEditingController();
  String? _gender;
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
    _countryCtrl.dispose();
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

  String _memberSince(DateTime? dt) {
    if (dt == null) return "—";
    const months = ["ene", "feb", "mar", "abr", "may", "jun", "jul", "ago", "sep", "oct", "nov", "dic"];
    final d = dt.toLocal();
    return "${months[d.month - 1]} ${d.year}";
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
    await PushService.unregister();
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
    _countryCtrl.text = p.country ?? "";
    _gender = p.gender;
    _birthDate = p.birthDate;
    setState(() => _editing = true);
  }

  Future<void> _save() async {
    // El país es obligatorio (igual que en el registro y en la web).
    if (_countryCtrl.text.trim().isEmpty) {
      showToast(context, "Escribe tu país.", error: true);
      return;
    }
    setState(() => _saving = true);
    try {
      await api.updateMe(
        firstName: _firstNameCtrl.text.trim(),
        lastName: _lastNameCtrl.text.trim(),
        gender: _gender,
        country: _countryCtrl.text.trim(),
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
      showToast(context, "Perfil guardado");
    } catch (e) {
      if (!mounted) return;
      showToast(context, e.toString(), error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  InputDecoration _inputDeco(IconData? icon) {
    final border = OutlineInputBorder(borderRadius: BorderRadius.circular(2), borderSide: BorderSide.none);
    return InputDecoration(
      isDense: true,
      filled: true,
      fillColor: AppColors.scorifyInput,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      prefixIcon: icon == null ? null : Icon(icon, color: AppColors.scorifyTextMuted, size: 20),
      border: border,
      enabledBorder: border,
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(2),
        borderSide: const BorderSide(color: AppColors.scorifyMint, width: 1.4),
      ),
    );
  }

  Widget _textInput(TextEditingController c, IconData? icon) =>
      TextField(controller: c, style: AppTypography.bodyText, decoration: _inputDeco(icon));

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
                      if (snap.connectionState == ConnectionState.waiting && !snap.hasData) {
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
                          padding: const EdgeInsets.only(bottom: 24),
                          children: [
                            GlassCard(
                              padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Row(
                                    children: [
                                      UserAvatar(userId: p.idUser, url: p.avatarUrl, size: 44),
                                      const SizedBox(width: 12),
                                      const Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text("Editar perfil",
                                                style: TextStyle(fontFamily: AppTypography.body, fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.scorifyText)),
                                            SizedBox(height: 2),
                                            Text("Así te verán los organizadores y rivales.",
                                                style: TextStyle(fontFamily: AppTypography.body, fontSize: 12.5, fontWeight: FontWeight.w400, color: AppColors.scorifyTextMuted)),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 20),
                                  Row(
                                    children: [
                                      Expanded(child: _FormField(label: "Nombre", child: _textInput(_firstNameCtrl, Icons.badge_rounded))),
                                      const SizedBox(width: 10),
                                      Expanded(child: _FormField(label: "Apellido", child: _textInput(_lastNameCtrl, null))),
                                    ],
                                  ),
                                  const SizedBox(height: 14),
                                  _FormField(
                                    label: "Fecha de nacimiento",
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(2),
                                      onTap: _pickBirthDate,
                                      child: InputDecorator(
                                        decoration: _inputDeco(Icons.cake_rounded).copyWith(
                                          suffixIcon: const Icon(Icons.calendar_month_rounded, color: AppColors.scorifyMint, size: 20),
                                        ),
                                        child: Text(_formatBirthDate(_birthDate), style: AppTypography.bodyText),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                  _FormField(
                                    label: "Género",
                                    child: DropdownButtonFormField<String>(
                                      initialValue: _gender,
                                      isExpanded: true,
                                      dropdownColor: AppColors.scorifySurface2,
                                      borderRadius: BorderRadius.circular(2),
                                      icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.scorifyTextMuted),
                                      style: AppTypography.bodyText,
                                      decoration: _inputDeco(Icons.wc_rounded),
                                      items: const [
                                        DropdownMenuItem(value: "male", child: Text("Masculino")),
                                        DropdownMenuItem(value: "female", child: Text("Femenino")),
                                        DropdownMenuItem(value: "other", child: Text("Otro")),
                                      ],
                                      onChanged: (v) => setState(() => _gender = v),
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                  _FormField(label: "País", child: _textInput(_countryCtrl, Icons.public_rounded)),
                                  const SizedBox(height: 22),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: AppButton.outline(
                                          label: "Cancelar",
                                          onPressed: _saving ? null : () => setState(() => _editing = false),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: AppButton(
                                          label: "Guardar",
                                          onPressed: _saving ? null : _save,
                                          loading: _saving,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      }

                      return RefreshIndicator(
                        color: AppColors.scorifyMint,
                        onRefresh: _refresh,
                        child: ListView(
                          padding: const EdgeInsets.only(bottom: 24),
                          children: [
                            _ProfileHero(profile: p, onEdit: () => _startEditing(p)),
                            const SizedBox(height: 14),
                            GridView.count(
                              crossAxisCount: 2,
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              mainAxisSpacing: 10,
                              crossAxisSpacing: 10,
                              childAspectRatio: 2.3,
                              children: [
                                _InfoTile(icon: Icons.cake_rounded, label: "Edad", value: p.age == null ? "—" : "${p.age} años"),
                                _InfoTile(icon: Icons.wc_rounded, label: "Género", value: _genderLabel(p.gender)),
                                _InfoTile(
                                  icon: Icons.public_rounded,
                                  label: "País",
                                  value: (p.country ?? "").trim().isEmpty ? "Sin especificar" : p.country!,
                                ),
                                _InfoTile(icon: Icons.calendar_today_rounded, label: "Miembro desde", value: _memberSince(p.createdAt)),
                              ],
                            ),
                            if (achievementsFuture != null) ...[
                              const SizedBox(height: 14),
                              FutureBuilder<List<PlayerAchievement>>(
                                future: achievementsFuture,
                                builder: (context, aSnap) => AchievementsCard(achievements: aSnap.data ?? [], showEmpty: aSnap.connectionState == ConnectionState.done, shareAs: p.displayName),
                              ),
                            ],
                            const SizedBox(height: 14),
                            _ClubSection(currentClub: p.club),
                            if (p.club != null) ...[
                              const SizedBox(height: 12),
                              const _DuesCard(),
                            ],
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

// Club: ya no es texto libre — el jugador elige uno de la lista y manda
// una solicitud, el admin dueño del club la acepta o la rechaza (mismo
// flujo que myttmi-web, ver features/profile/pages/ProfilePage.tsx ahí).
class _ClubSection extends StatefulWidget {
  final String? currentClub;
  const _ClubSection({required this.currentClub});

  @override
  State<_ClubSection> createState() => _ClubSectionState();
}

class _ClubSectionState extends State<_ClubSection> {
  final _api = ClubsApi();
  List<PublicClub> _clubs = [];
  MyClubRequest? _myRequest;
  String? _selectedClubId;
  bool _loading = true;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (widget.currentClub != null) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    setState(() => _loading = true);
    try {
      final results = await Future.wait([_api.list(), _api.getMyRequest()]);
      final clubs = results[0] as List<PublicClub>;
      final req = results[1] as MyClubRequest?;
      if (!mounted) return;
      setState(() {
        _clubs = clubs;
        _myRequest = (req != null && req.status == "pending") ? req : null;
      });
    } catch (_) {
      // silencioso — la sección de club no es crítica para ver el resto del perfil.
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _requestJoin() async {
    final idClub = _selectedClubId;
    if (idClub == null) return;
    final ok = await confirmAction(
      context,
      title: "Unirte al club",
      message: "¿Enviar la solicitud para unirte a este club? El club debe aceptarte.",
      confirmLabel: "Enviar solicitud",
    );
    if (!ok || !mounted) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await _api.requestJoin(idClub);
      await _load();
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _cancelRequest() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await _api.cancelMyRequest();
      await _load();
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: "Mi club",
      icon: Icons.shield_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_loading)
            const Center(
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2.2, color: AppColors.scorifyMint),
              ),
            )
          else if (widget.currentClub != null)
            Row(
              children: [
                const Icon(Icons.groups_2_rounded, color: AppColors.scorifyMint, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text.rich(
                    TextSpan(
                      style: AppTypography.bodyMuted,
                      children: [
                        const TextSpan(text: "Perteneces a "),
                        TextSpan(
                          text: widget.currentClub,
                          style: AppTypography.bodyText.copyWith(fontWeight: FontWeight.w600),
                        ),
                        const TextSpan(text: "."),
                      ],
                    ),
                  ),
                ),
              ],
            )
          else if (_myRequest != null)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Solicitud enviada a ${_myRequest!.clubName} — esperando respuesta del club.",
                  style: AppTypography.bodyMuted,
                ),
                const SizedBox(height: 12),
                _busy
                    ? const Center(
                        child: SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2.2, color: AppColors.scorifyMint),
                        ),
                      )
                    : OutlinePillButton(label: "Cancelar solicitud", onTap: _cancelRequest),
              ],
            )
          else if (_clubs.isEmpty)
            Text("Todavía no hay clubes disponibles para unirte.", style: AppTypography.bodyMuted)
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text("Todavía no perteneces a un club. Elige uno y envía tu solicitud; el club debe aceptarte.",
                    style: AppTypography.bodyMuted.copyWith(height: 1.4)),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _selectedClubId,
                  dropdownColor: AppColors.scorifyDeep,
                  iconEnabledColor: AppColors.scorifyTextMuted,
                  style: AppTypography.bodyText,
                  // isExpanded: el nombre del club lo escribe cada admin
                  // libremente, puede ser largo y desbordar el botón cerrado.
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: "Elige un club",
                    labelStyle: AppTypography.bodyMuted,
                    filled: true,
                    fillColor: AppColors.scorifyInput,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(2), borderSide: BorderSide.none),
                  ),
                  items: _clubs
                      .map((c) => DropdownMenuItem(
                            value: c.idClub,
                            child: Text(c.name, overflow: TextOverflow.ellipsis),
                          ))
                      .toList(),
                  onChanged: (v) => setState(() => _selectedClubId = v),
                ),
                const SizedBox(height: 12),
                _busy
                    ? const Center(
                        child: SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2.2, color: AppColors.scorifyMint),
                        ),
                      )
                    : SolidPillButton(
                        label: "Solicitar unirme",
                        onTap: _selectedClubId == null ? () {} : _requestJoin,
                      ),
              ],
            ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!, style: AppTypography.bodyMuted.copyWith(color: Colors.redAccent)),
          ],
        ],
      ),
    );
  }
}

/// Cuotas del club: "Estás al día" o "Debes 2 meses · $10.000".
class _DuesCard extends StatefulWidget {
  const _DuesCard();
  @override
  State<_DuesCard> createState() => _DuesCardState();
}

class _DuesCardState extends State<_DuesCard> {
  MyClubDues? _dues;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    ClubsApi().getMyDues().then((d) {
      if (mounted) setState(() { _dues = d; _loaded = true; });
    }).catchError((_) {
      if (mounted) setState(() => _loaded = true);
    });
  }

  static String _money(int v) {
    final s = v.toString();
    final b = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) b.write(".");
      b.write(s[i]);
    }
    return "\$${b.toString()}";
  }

  @override
  Widget build(BuildContext context) {
    final d = _dues;
    if (!_loaded || d == null) return const SizedBox.shrink();
    final ok = d.upToDate;
    final color = ok ? AppColors.scorifyButterfly : AppColors.scorifyNegative;
    final unit = d.feeFrequency == "weekly" ? (d.owedPeriods == 1 ? "semana" : "semanas") : (d.owedPeriods == 1 ? "mes" : "meses");
    return SectionCard(
      title: "Cuotas del club",
      icon: Icons.payments_rounded,
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(2)),
            child: Icon(ok ? Icons.verified_rounded : Icons.error_outline_rounded, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ok ? "Estás al día" : "Debes ${d.owedPeriods} $unit",
                  style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.w600),
                ),
                if (!ok && d.owedAmount > 0)
                  Text("Total pendiente: ${_money(d.owedAmount)}", style: const TextStyle(color: AppColors.scorifyTextMuted, fontSize: 12, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Cabecera del perfil: avatar grande, nombre, correo y chips, con el botón
/// "Editar perfil" a mano (antes estaba al final de la pantalla).
class _ProfileHero extends StatelessWidget {
  final UserProfile profile;
  final VoidCallback onEdit;
  const _ProfileHero({required this.profile, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    final p = profile;
    Widget chip(IconData icon, String text) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(color: AppColors.scorifySurface2, borderRadius: BorderRadius.circular(2)),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: AppColors.scorifyMint),
              const SizedBox(width: 5),
              Text(text, style: const TextStyle(fontFamily: AppTypography.body, fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.scorifyText)),
            ],
          ),
        );
    return GlassCard(
      padding: const EdgeInsets.fromLTRB(18, 22, 18, 18),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: const BoxDecoration(color: AppColors.scorifySurface2, shape: BoxShape.circle),
            child: UserAvatar(userId: p.idUser, url: p.avatarUrl, size: 84),
          ),
          const SizedBox(height: 12),
          Text(
            p.displayName,
            textAlign: TextAlign.center,
            style: const TextStyle(fontFamily: AppTypography.body, fontSize: 22, fontWeight: FontWeight.w600, color: AppColors.scorifyText),
          ),
          const SizedBox(height: 2),
          Text(p.email, style: AppTypography.bodyMuted),
          const SizedBox(height: 12),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              chip(Icons.sports_tennis_rounded, "Jugador"),
              if ((p.club ?? "").isNotEmpty) chip(Icons.shield_rounded, p.club!),
            ],
          ),
          const SizedBox(height: 16),
          AppButton.outline(label: "Editar perfil", icon: Icons.edit_rounded, onPressed: onEdit),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoTile({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(gradient: AppColors.cardGradient, borderRadius: BorderRadius.circular(2)),
      child: Row(
        children: [
          Icon(icon, color: AppColors.scorifyMint, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontFamily: AppTypography.body, fontSize: 11.5, fontWeight: FontWeight.w400, color: AppColors.scorifyTextMuted)),
                const SizedBox(height: 2),
                Text(value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontFamily: AppTypography.body, fontSize: 14.5, fontWeight: FontWeight.w600, color: AppColors.scorifyText)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Campo del formulario con su etiqueta arriba (antes la etiqueta quedaba
/// montada sobre el borde del campo y costaba leerla).
class _FormField extends StatelessWidget {
  final String label;
  final Widget child;
  const _FormField({required this.label, required this.child});

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 6),
            child: Text(label,
                style: const TextStyle(fontFamily: AppTypography.body, fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.scorifyTextMuted)),
          ),
          child,
        ],
      );
}
