import "package:flutter/material.dart";
import "package:myttmi/features/notifications/models/notification_model.dart";
import "package:myttmi/routes/app_routes.dart";

/// Al tocar una notificación (en la lista o en el aviso emergente): lleva a
/// donde está la acción — el partido, la categoría o el perfil (club).
void openNotification(NavigatorState nav, AppNotification n) {
  if (n.type == "club_payment" || n.type.startsWith("club_join")) {
    nav.pushNamed(AppRoutes.profile);
    return;
  }
  if (n.idMatch != null && n.matchType != null && n.type != "match_result_corrected") {
    nav.pushNamed(
      AppRoutes.matchDetail,
      arguments: {"matchType": n.matchType, "matchId": n.idMatch},
    );
    return;
  }
  if (n.idCategory != null && n.idTournament != null) {
    nav.pushNamed(
      AppRoutes.myCategory,
      arguments: {
        "tournamentId": n.idTournament,
        "tournamentName": n.tournamentName ?? "",
        "categoryId": n.idCategory,
        "categoryLabel": n.categoryLabel ?? n.tournamentName ?? "Mi categoría",
      },
    );
  }
}
