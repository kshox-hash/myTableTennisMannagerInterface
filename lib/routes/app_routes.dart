import "package:flutter/material.dart";

// LOGIN
import "package:myttmi/features/auth/presentation/login_screen.dart";

// PLAYER
import "package:myttmi/features/tournament/presentation/tournament_detail_screen.dart";
import "package:myttmi/features/profile/presentation/profile_screen.dart";
import "package:myttmi/features/tournament/models/tournament_model.dart";
import "package:myttmi/features/tournament/presentation/my_category_screen.dart";
import "package:myttmi/features/tournament/presentation/tournament_matches_screen.dart";
import "package:myttmi/features/tournament/presentation/match_detail_screen.dart";
import "package:myttmi/features/tournament/presentation/tournament_players_screen.dart";
import "package:myttmi/features/tournament/presentation/tournament_tables_screen.dart";
import "package:myttmi/features/profile/presentation/player_profile_screen.dart";
import "package:myttmi/features/tournament/presentation/history_screen.dart";
import "package:myttmi/features/notifications/presentation/notifications_screen.dart";
import "package:myttmi/routes/cyber_page_route.dart";

class AppRoutes {
  static const login = "/login";

  static const profile = "/profile";
  static const notifications = "/notifications";
  static const history = "/history";

  static const tournamentDetail = "/tournament/detail";
  static const tournamentPlayers = "/tournament/players";
  static const tournamentMatches = "/tournament/matches";
  static const tournamentTables = "/tournament/tables";
  static const matchDetail = "/match/detail";
  static const myCategory = "/tournament/my-category";
  static const playerProfile = "/player/profile";

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case login:
        return CyberPageRoute(builder: (_) => const LoginScreen());

      case profile:
        return CyberPageRoute(builder: (_) => const ProfileScreen());

      case history:
        return CyberPageRoute(builder: (_) => const HistoryScreen());

      case notifications:
        return CyberPageRoute(builder: (_) => const NotificationsScreen());

      case tournamentDetail:
        {
          final t = settings.arguments as Tournament;
          return CyberPageRoute(
            builder: (_) => TournamentDetailScreen(tournament: t),
          );
        }

      case myCategory:
        {
          final args = settings.arguments as Map<String, dynamic>;
          return CyberPageRoute(
            builder: (_) => MyCategoryScreen(
              tournamentId: args["tournamentId"] as String,
              tournamentName: args["tournamentName"] as String,
              categoryId: args["categoryId"] as String,
              categoryLabel: args["categoryLabel"] as String,
            ),
          );
        }

      case tournamentMatches:
        {
          final args = settings.arguments as Map<String, dynamic>;
          return CyberPageRoute(
            builder: (_) => TournamentMatchesScreen(
              tournamentId: args["tournamentId"] as String,
              tournamentName: args["tournamentName"] as String,
              initialMode: args["initialMode"] as String?,
            ),
          );
        }

      case matchDetail:
        {
          final args = settings.arguments as Map<String, dynamic>;
          return CyberPageRoute(
            builder: (_) => MatchDetailScreen(
              matchType: args["matchType"] as String,
              matchId: args["matchId"] as String,
            ),
          );
        }

      case tournamentPlayers:
        {
          final args = settings.arguments as Map<String, dynamic>;
          return CyberPageRoute(
            builder: (_) => TournamentPlayersScreen(
              tournamentId: args["tournamentId"] as String,
              tournamentName: args["tournamentName"] as String,
            ),
          );
        }

      case tournamentTables:
        {
          final args = settings.arguments as Map<String, dynamic>;
          return CyberPageRoute(
            builder: (_) => TournamentTablesScreen(
              tournamentId: args["tournamentId"] as String,
              tournamentName: args["tournamentName"] as String,
            ),
          );
        }

      case playerProfile:
        {
          final args = settings.arguments as Map<String, dynamic>;
          return CyberPageRoute(
            builder: (_) => PlayerProfileScreen(
              userId: args["userId"] as String,
              playerName: args["playerName"] as String?,
            ),
          );
        }

      default:
        return CyberPageRoute(
          builder: (_) =>
              _PlaceholderScreen(title: "Ruta no encontrada: ${settings.name}"),
        );
    }
  }
}

class _PlaceholderScreen extends StatelessWidget {
  final String title;
  const _PlaceholderScreen({required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
        ),
      ),
    );
  }
}
