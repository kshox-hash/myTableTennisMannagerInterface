import "package:flutter/material.dart";
import "package:myttmi/core/constants/app_colors.dart";
import "package:myttmi/core/helpers/json_parse.dart";

const Map<String, String> _typeIcon = {
  "enrollment_created": "📝",
  "enrollment_confirmed": "✅",
  "enrollment_removed": "🚫",
  "groups_started": "🥅",
  "group_changed": "🔀",
  "bracket_generated": "🏆",
  "bracket_bye": "⏭️",
  "next_match_ready": "🔜",
  "match_on_table": "🏓",
  "match_result": "🏓",
  "tournament_cancelled": "🚫",
};

String notificationIcon(String type) => _typeIcon[type] ?? "🔔";

// Color por familia de notificación — para que el ícono deje de ser un
// emoji plano y tenga un fondo distinto según el tipo de evento.
const Map<String, Color> _typeColor = {
  "enrollment_created": AppColors.scorifyMint,
  "enrollment_confirmed": AppColors.scorifyMint,
  "enrollment_removed": AppColors.scorifyNegative,
  "groups_started": AppColors.scorifyPending,
  "group_changed": AppColors.scorifyPending,
  "bracket_generated": AppColors.scorifyMint,
  "bracket_bye": AppColors.scorifyPending,
  "next_match_ready": AppColors.scorifyPending,
  "match_on_table": AppColors.scorifyMint,
  "match_result": AppColors.scorifyMint,
  "tournament_cancelled": AppColors.scorifyNegative,
};

Color notificationColor(String type) =>
    _typeColor[type] ?? AppColors.scorifyTextMuted;

class AppNotification {
  final String idNotification;
  final String type;
  final String title;
  final String message;
  final String? idTournament;
  final String? idCategory;
  final bool isRead;
  final String createdAt;

  AppNotification({
    required this.idNotification,
    required this.type,
    required this.title,
    required this.message,
    this.idTournament,
    this.idCategory,
    required this.isRead,
    required this.createdAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      idNotification: (json["id_notification"] ?? "").toString(),
      type: (json["type"] ?? "").toString(),
      title: (json["title"] ?? "").toString(),
      message: (json["message"] ?? "").toString(),
      idTournament: json["id_tournament"] as String?,
      idCategory: json["id_category"] as String?,
      isRead: json["is_read"] == true,
      createdAt: (json["created_at"] ?? "").toString(),
    );
  }
}

class NotificationsSnapshot {
  final List<AppNotification> items;
  final int unreadCount;

  NotificationsSnapshot({required this.items, required this.unreadCount});

  factory NotificationsSnapshot.fromJson(Map<String, dynamic> json) {
    return NotificationsSnapshot(
      items: (json["items"] as List? ?? [])
          .map((e) => AppNotification.fromJson(e as Map<String, dynamic>))
          .toList(),
      unreadCount: intOrDefault(json["unread_count"]),
    );
  }
}
