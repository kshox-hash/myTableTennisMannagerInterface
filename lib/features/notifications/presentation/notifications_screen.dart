import "package:flutter/material.dart";
import "package:myttmi/core/constants/app_colors.dart";
import "package:myttmi/core/constants/app_typography.dart";
import "package:myttmi/core/ui/glass_card.dart";
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
    if (n.isRead) return;
    try {
      await _api.markRead(n.idNotification);
      _load();
    } catch (_) {}
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
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TopHeader(
                  title: "Notificaciones",
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
                  ],
                ),
                const SizedBox(height: 14),
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
                                  message: "No tenés notificaciones.",
                                ),
                              ),
                            ],
                          );
                        }

                        final grouped = _groupByDay(items);
                        return ListView.separated(
                          itemCount: grouped.length,
                          separatorBuilder: (_, i) =>
                              SizedBox(height: grouped[i] is String ? 4 : 10),
                          itemBuilder: (context, i) {
                            final entry = grouped[i];
                            if (entry is String) {
                              return Padding(
                                padding: EdgeInsets.only(
                                  top: i == 0 ? 0 : 10,
                                  bottom: 2,
                                ),
                                child: Text(
                                  entry,
                                  style: AppTypography.caption.copyWith(
                                    color: AppColors.scorifyTextFaint,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.4,
                                  ),
                                ),
                              );
                            }

                            final n = entry as AppNotification;
                            final color = notificationColor(n.type);
                            return GlassCard(
                              onTap: () => _markRead(n),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      color: color.withOpacity(0.16),
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: color.withOpacity(0.4),
                                      ),
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      notificationIcon(n.type),
                                      style: const TextStyle(fontSize: 17),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                n.title,
                                                style: n.isRead
                                                    ? AppTypography.bodyText
                                                    : AppTypography.h2,
                                              ),
                                            ),
                                            if (!n.isRead)
                                              Container(
                                                width: 8,
                                                height: 8,
                                                margin: const EdgeInsets.only(
                                                  left: 8,
                                                  top: 4,
                                                ),
                                                decoration: const BoxDecoration(
                                                  color: AppColors.scorifyMint,
                                                  shape: BoxShape.circle,
                                                ),
                                              ),
                                          ],
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          n.message,
                                          style: AppTypography.bodyMuted,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    _timeAgo(n.createdAt),
                                    style: AppTypography.caption,
                                  ),
                                ],
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
