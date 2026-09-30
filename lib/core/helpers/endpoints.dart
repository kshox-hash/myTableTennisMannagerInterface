class Endpoints {
  static const path = "api";
  static const version = "v1";

  static const base = "/$path/$version";

  // AUTH
  static const signIn = "$base/auth/sign-in";
  static const signUp = "$base/auth/sign-up";

  // TOURNAMENTS (jugador)
  static const listTournaments = "$base/tournament/player/tournaments";
  static const subscribe = "$base/enrollments/subscribe";

  static String tournamentById(String tournamentId) =>
      "$base/tournament/player/tournaments/$tournamentId";

  static String tournamentParticipants(String tournamentId) =>
      "$base/player/tournament/$tournamentId/participants";

  static String tournamentMatches(String tournamentId) =>
      "$base/player/tournament/$tournamentId/matches";

  static String categoryView(String tournamentId, String categoryId) =>
      "$base/player/tournament/$tournamentId/category/$categoryId";

  static String categoryStandings(String tournamentId, String categoryId) =>
      "$base/player/tournament/$tournamentId/category/$categoryId/standings";

  // Todos los grupos y la llave completa de la categoría (no solo "los
  // míos") — mismo endpoint que usa el panel admin, abierto a cualquier
  // jugador logueado.
  static String allGroups(String tournamentId, String categoryId) =>
      "$base/bracket/tournaments/$tournamentId/categories/$categoryId";

  static String matchDetail(String matchType, String matchId) =>
      "$base/player/match/$matchType/$matchId";

  // Mesas en vivo + próximos partidos de la cola de despacho — versión
  // read-only para jugadores del mismo tablero que ve el admin.
  static String tablesQueue(String tournamentId) =>
      "$base/tournament/$tournamentId/tables/queue";

  static String userMatches(String userId) =>
      "$base/player/user/$userId/matches";

  static String userAchievements(String userId) =>
      "$base/player/user/$userId/achievements";

  // DASHBOARD / ENROLLMENTS PROPIAS
  static const playerDashboard = "$base/player/dashboard";
  static const myEnrollments = "$base/player/my-enrollments";

  // PERFIL
  static const me = "$base/users/me";
  static const myStats = "$base/users/me/stats";

  static String userProfile(String userId) => "$base/users/$userId/profile";

  // CLUBES — selector al registrarse / desde Perfil, pide unirse con una
  // solicitud que confirma el admin dueño del club (mismo flujo que
  // myttmi-web, ver features/profile/api/clubsApi.ts ahí).
  static const clubs = "$base/clubs";
  static const clubMyRequest = "$base/clubs/me/request";

  static String clubJoin(String idClub) => "$base/clubs/$idClub/join";

  // RANKING
  static const ranking = "$base/ranking";

  // NOTIFICACIONES
  static const notifications = "$base/notifications";
  static const notificationsUnreadCount = "$base/notifications/unread-count";
  static const notificationsReadAll = "$base/notifications/read-all";
  static const deviceToken = "$base/notifications/device-token";

  static String notificationRead(String idNotification) =>
      "$base/notifications/$idNotification/read";
}
