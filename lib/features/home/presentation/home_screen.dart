import 'package:flutter/material.dart';
import "package:myttmi/routes/cyber_page_route.dart";

import 'package:myttmi/core/constants/app_colors.dart';
import 'package:myttmi/core/storage/session_storage.dart';
import 'package:myttmi/features/shell/app_shell.dart';
import 'package:myttmi/features/shell/splash_gate.dart';
import 'package:myttmi/features/shell/tab_auto_refresh.dart';
import 'package:myttmi/features/player/api/player_api.dart';
import 'package:myttmi/features/player/models/player_dashboard_model.dart';
import 'package:myttmi/features/profile/api/profile_api.dart';
import 'package:myttmi/features/profile/models/profile_model.dart';
import 'package:myttmi/features/notifications/api/notifications_api.dart';

import '../../../routes/app_routes.dart';

import '../widget/spin_header.dart';
import '../widget/spin_player_card.dart';
import '../widget/spin_next_match_panel.dart';
import '../widget/spin_stats_row.dart';
import '../widget/spin_section_label.dart';
import '../widget/spin_mode_row.dart';

/// Pestaña "Inicio" del shell — ya no arma su propio Scaffold/fondo/nav, eso
/// lo maneja AppShell. Cambiar a otra pestaña se pide vía AppShellScope en
/// vez de empujar una segunda pantalla encima.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with TabAutoRefreshMixin<HomeScreen> {
  @override
  int get tabIndex => 0;

  @override
  void onTabActivated() => _load();

  final _playerApi = PlayerApi();
  final _profileApi = ProfileApi();
  final _notificationsApi = NotificationsApi();

  UserProfile? _profile;
  PlayerDashboard? _dashboard;
  int _unreadCount = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        _profileApi.getMe(),
        _playerApi.getDashboard(),
        _notificationsApi.getUnreadCount(),
      ]);
      if (!mounted) return;
      setState(() {
        _profile = results[0] as UserProfile;
        _dashboard = results[1] as PlayerDashboard;
        _unreadCount = results[2] as int;
      });
    } catch (_) {
      // Silencioso: la pantalla igual se puede usar sin estos datos.
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _goOpponentProfile() {
    final nm = _dashboard?.nextMatch;
    if (nm?.opponentId == null) return;
    Navigator.pushNamed(
      context,
      AppRoutes.playerProfile,
      arguments: {
        "userId": nm!.opponentId,
        "playerName": nm.opponentName ?? "Jugador",
      },
    );
  }

  Future<void> _confirmLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.scorifyDeep,
        title: const Text(
          "Cerrar sesión",
          style: TextStyle(color: AppColors.scorifyText),
        ),
        content: Text(
          "¿Quieres cerrar sesión y volver al login?",
          style: TextStyle(color: AppColors.scorifyText.withOpacity(0.85)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              "Cancelar",
              style: TextStyle(color: AppColors.scorifyText.withOpacity(0.85)),
            ),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.scorifyMint.withOpacity(0.18),
              foregroundColor: AppColors.scorifyText,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            onPressed: () => Navigator.pop(context, true),
            icon: const Icon(Icons.logout),
            label: const Text("Cerrar sesión"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await SessionStorage().clearAll();
      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        CyberPageRoute(builder: (_) => const SplashGate()),
        (route) => false,
      );
    }
  }

  Future<void> _openSettings() async {
    final action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.scorifyDeep.withOpacity(0.95),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (_) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 10),
              ListTile(
                leading: const Icon(
                  Icons.person_outline,
                  color: AppColors.scorifyText,
                ),
                title: const Text(
                  "Perfil",
                  style: TextStyle(color: AppColors.scorifyText),
                ),
                onTap: () => Navigator.pop(context, "profile"),
              ),
              ListTile(
                leading: const Icon(
                  Icons.history,
                  color: AppColors.scorifyText,
                ),
                title: const Text(
                  "Historial",
                  style: TextStyle(color: AppColors.scorifyText),
                ),
                onTap: () => Navigator.pop(context, "history"),
              ),
              ListTile(
                leading: const Icon(Icons.logout, color: AppColors.scorifyText),
                title: const Text(
                  "Cerrar sesión",
                  style: TextStyle(color: AppColors.scorifyText),
                ),
                onTap: () => Navigator.pop(context, "logout"),
              ),
              const SizedBox(height: 6),
            ],
          ),
        );
      },
    );

    if (!mounted) return;

    if (action == "profile") {
      Navigator.pushNamed(context, AppRoutes.profile);
    } else if (action == "history") {
      Navigator.pushNamed(context, AppRoutes.history);
    } else if (action == "logout") {
      await _confirmLogout();
    }
  }

  @override
  Widget build(BuildContext context) {
    final nm = _dashboard?.nextMatch;
    final hasNextMatch = nm != null;

    final matchTitle = hasNextMatch
        ? (nm.opponentName ?? "Rival por definir")
        : "Sin partidos programados";
    final matchSubtitle = hasNextMatch
        ? "${nm.tournamentName}\n${nm.queueLabel}"
        : (_loading
              ? "Cargando…"
              : "Inscribite a un campeonato para entrar al fixture");

    final stats = _dashboard?.stats;
    final played = stats?.matchesPlayed ?? 0;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          SpinHeader(
            notificationsCount: _unreadCount,
            onNotifications: () =>
                Navigator.pushNamed(context, AppRoutes.notifications),
            onSettings: _openSettings,
          ),

          const SizedBox(height: 16),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.only(bottom: 20),
              children: [
                SpinPlayerCard(
                  userId: _profile?.idUser,
                  playerName: (_profile?.displayName.isNotEmpty ?? false)
                      ? _profile!.displayName
                      : "Jugador",
                  details:
                      [
                            _profile?.category,
                            _profile?.club,
                            if (_profile?.age != null) "${_profile!.age} años",
                          ]
                          .whereType<String>()
                          .where((s) => s.trim().isNotEmpty)
                          .toList(),
                  onTap: () => Navigator.pushNamed(context, AppRoutes.profile),
                ),

                const SizedBox(height: 14),

                SpinNextMatchPanel(
                  opponentId: nm?.opponentId,
                  title: matchTitle,
                  subtitle: matchSubtitle,
                  onTap: nm?.opponentId != null
                      ? _goOpponentProfile
                      : () => AppShellScope.of(context)?.switchTab(3),
                ),

                const SizedBox(height: 14),

                SpinStatsRow(
                  stats: [
                    SpinStat(label: "PJ", value: "$played"),
                    SpinStat(label: "G", value: "${stats?.matchesWon ?? 0}"),
                    SpinStat(label: "P", value: "${stats?.matchesLost ?? 0}"),
                    SpinStat(
                      label: "%",
                      value: played == 0
                          ? "—"
                          : "${(stats!.winRate * 100).round()}",
                    ),
                  ],
                ),

                const SizedBox(height: 22),

                const SpinSectionLabel(text: "Modos de juego"),
                const SizedBox(height: 10),

                SpinModeRow(
                  icon: Icons.emoji_events_rounded,
                  title: "Campeonatos",
                  subtitle: "Torneos abiertos cerca tuyo",
                  accent: AppColors.scorifyMint,
                  onTap: () => AppShellScope.of(context)?.switchTab(3),
                ),
                const SizedBox(height: 10),

                SpinModeRow(
                  icon: Icons.calendar_month_rounded,
                  title: "Calendario",
                  subtitle: "Fixture y resultados",
                  accent: AppColors.scorifyMint,
                  onTap: () => AppShellScope.of(context)?.switchTab(1),
                ),
                const SizedBox(height: 10),

                SpinModeRow(
                  icon: Icons.bar_chart_rounded,
                  title: "Rendimiento",
                  subtitle: "Stats y progreso",
                  accent: AppColors.scorifyMint,
                  onTap: () => AppShellScope.of(context)?.switchTab(2),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
