import "package:myttmi/routes/app_routes.dart";
import "package:flutter/material.dart";
import "package:myttmi/core/constants/app_colors.dart";
import "package:myttmi/core/constants/app_typography.dart";
import "package:myttmi/core/ui/list_states.dart";
import "package:myttmi/core/ui/prism_background.dart";
import "package:myttmi/core/ui/top_header.dart";
import "package:myttmi/features/notifications/api/notifications_api.dart";
import "package:myttmi/features/notifications/models/notification_model.dart";

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final _api = NotificationsApi();
  Future<NotificationsSnapshot>? _future;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    setState(() {
      _future = _api.list();
    });
  }

  Future<void> _markRead(AppNotification n) async {
    if (!n.isRead) {
      try {
        await _api.markRead(n.idNotification);
        _load();
      } catch (_) {}
    }
    if (!mounted) return;
    _open(n);
  }

  // Al tocar: lleva a donde está la acción — el partido, la categoría o el
  // perfil (cuotas del club). Antes solo marcaba la notificación leída.
  void _open(AppNotification n) {
    if (n.type == "club_payment" || n.type.startsWith("club_join")) {
      Navigator.pushNamed(context, AppRoutes.profile);
      return;
    }
    if (n.idMatch != null &&
        n.matchType != null &&
        n.type != "match_result_corrected") {
      Navigator.pushNamed(
        context,
        AppRoutes.matchDetail,
        arguments: {"matchType": n.matchType, "matchId": n.idMatch},
      );
      return;
    }
    if (n.idCategory != null && n.idTournament != null) {
      Navigator.pushNamed(
        context,
        AppRoutes.myCategory,
        arguments: {
          "tournamentId": n.idTournament,
          "tournamentName": n.tournamentName ?? "",
          "categoryId": n.idCategory,
          "categoryLabel":
              n.categoryLabel ?? n.tournamentName ?? "Mi categoría",
        },
      );
    }
  }

  Future<void> _markAllRead() async {
    try {
      await _api.markAllRead();
      _load();
    } catch (_) {}
  }

  String _timeAgo(String iso) {
    final d = DateTime.tryParse(iso);
    if (d == null) return "";
    final diff = DateTime.now().difference(d);
    if (diff.inMinutes < 1) return "ahora";
    if (diff.inMinutes < 60) return "hace ${diff.inMinutes} min";
    if (diff.inHours < 24) return "hace ${diff.inHours} h";
    return "hace ${diff.inDays} d";
  }

  // Agrupa por "Hoy" / "Ayer" / "Esta semana" / "Más antiguo" para que la
  // lista se lea como una línea de tiempo en vez de un bloque plano.
  String _dayBucket(String iso) {
    final d = DateTime.tryParse(iso)?.toLocal();
    if (d == null) return "Más antiguo";
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(d.year, d.month, d.day);
    final diffDays = today.difference(day).inDays;
    if (diffDays == 0) return "Hoy";
    if (diffDays == 1) return "Ayer";
    if (diffDays < 7) return "Esta semana";
    return "Más antiguo";
  }

  List<Object> _groupByDay(List<AppNotification> items) {
    const order = ["Hoy", "Ayer", "Esta semana", "Más antiguo"];
    final buckets = <String, List<AppNotification>>{};
    for (final n in items) {
      buckets.putIfAbsent(_dayBucket(n.createdAt), () => []).add(n);
    }
    final result = <Object>[];
    for (final label in order) {
      final group = buckets[label];
      if (group == null || group.isEmpty) continue;
      result.add(label);
      result.addAll(group);
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scorifyBg,
      body: PrismBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: TopHeader(
                    title: "Notificaciones",
                    // Se abre como panel lateral: se cierra con la X, no con "volver".
                    showBack: false,
                    actions: [
                      GestureDetector(
                        onTap: _markAllRead,
                        child: Text(
                          "Marcar todo leído",
                          style: AppTypography.bodyMuted.copyWith(
                            color: AppColors.scorifyMint,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      HeaderIconButton(
                        icon: Icons.close_rounded,
                        onTap: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: RefreshIndicator(
                    color: AppColors.scorifyMint,
                    onRefresh: () async {
                      _load();
                      await _future;
                    },
                    child: FutureBuilder<NotificationsSnapshot>(
                      future: _future,
                      builder: (context, snap) {
                        if (snap.connectionState == ConnectionState.waiting) {
                          return const LoadingState();
                        }
                        if (snap.hasError) {
                          return ListView(
                            children: [
                              ErrorStateView(
                                message:
                                    "No pudimos cargar tus notificaciones.\n${snap.error}",
                                onRetry: _load,
                              ),
                            ],
                          );
                        }

                        final items = snap.data?.items ?? [];
                        if (items.isEmpty) {
                          return ListView(
                            children: const [
                              Padding(
                                padding: EdgeInsets.only(top: 40),
                                child: EmptyState(
                                  icon: Icons.notifications_none_rounded,
                                  message: "No tienes notificaciones.",
                                ),
                              ),
                            ],
                          );
                        }

                        // Estilo Facebook: filas a todo el ancho separadas por una
                        // línea fina, sin íconos (carga más liviana); las no leídas
                        // con fondo destacado y un punto celeste.
                        final grouped = _groupByDay(items);
                        return ListView.builder(
                          itemCount: grouped.length,
                          itemBuilder: (context, i) {
                            final entry = grouped[i];
                            if (entry is String) {
                              return Padding(
                                padding: EdgeInsets.fromLTRB(
                                  16,
                                  i == 0 ? 4 : 18,
                                  16,
                                  8,
                                ),
                                child: Text(
                                  entry,
                                  style: const TextStyle(
                                    fontFamily: AppTypography.body,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.scorifyText,
                                  ),
                                ),
                              );
                            }
                            final n = entry as AppNotification;
                            return Material(
                              color: n.isRead
                                  ? Colors.transparent
                                  : AppColors.scorifyMint.withValues(
                                      alpha: 0.08,
                                    ),
                              child: InkWell(
                                onTap: () => _markRead(n),
                                child: Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.fromLTRB(
                                    16,
                                    12,
                                    16,
                                    12,
                                  ),
                                  decoration: const BoxDecoration(
                                    border: Border(
                                      bottom: BorderSide(
                                        color: Color(0xFF1A2F39),
                                      ),
                                    ),
                                  ),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              n.title,
                                              style: TextStyle(
                                                fontFamily: AppTypography.body,
                                                fontSize: 14.5,
                                                fontWeight: n.isRead
                                                    ? FontWeight.w600
                                                    : FontWeight.w800,
                                                color: AppColors.scorifyText,
                                              ),
                                            ),
                                            const SizedBox(height: 3),
                                            Text(
                                              n.message,
                                              style: const TextStyle(
                                                fontFamily: AppTypography.body,
                                                fontSize: 13.5,
                                                height: 1.35,
                                                fontWeight: FontWeight.w500,
                                                color:
                                                    AppColors.scorifyTextMuted,
                                              ),
                                            ),
                                            const SizedBox(height: 5),
                                            Text(
                                              _timeAgo(n.createdAt),
                                              style: TextStyle(
                                                fontFamily: AppTypography.body,
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                                color: n.isRead
                                                    ? AppColors.scorifyTextFaint
                                                    : AppColors.scorifyMint,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      if (!n.isRead)
                                        Container(
                                          width: 10,
                                          height: 10,
                                          margin: const EdgeInsets.only(
                                            left: 12,
                                            top: 6,
                                          ),
                                          decoration: const BoxDecoration(
                                            color: AppColors.scorifyMint,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        );
                      },
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
