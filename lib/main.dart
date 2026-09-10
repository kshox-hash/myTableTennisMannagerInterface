import "package:flutter/material.dart";
import "package:myttmi/core/constants/app_colors.dart";
import "package:myttmi/features/shell/splash_gate.dart";
import "package:myttmi/routes/app_routes.dart";

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "myTTMI",
      debugShowCheckedModeBanner: false,
      // Base oscura acorde al sistema "Marcador" — antes era el
      // ThemeData(useMaterial3: true) por defecto (blanco/teal), que es lo
      // que se filtraba en cualquier pantalla o widget Material sin retocar.
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.scorifyBg,
        fontFamily: 'Montserrat',
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.scorifyMint,
          brightness: Brightness.dark,
          surface: AppColors.scorifyDeep,
          primary: AppColors.scorifyMint,
          onPrimary: AppColors.scorifyOnMint,
        ),
      ),
      onGenerateRoute: AppRoutes.onGenerateRoute,
      // "home" en vez de "initialRoute": un initialRoute con barras (ej.
      // "/splash") hace que Flutter arme el stack inicial dividiendo el
      // nombre por "/" y generando una ruta por cada tramo ("/" y "/splash")
      // — la ruta "/" no matchea ningún case de onGenerateRoute y cae al
      // placeholder "Ruta no encontrada", pero como pushReplacement del
      // splash solo pisa el tramo de arriba, esa ruta fantasma quedaba
      // enterrada en el fondo del stack para siempre y aparecía al volver
      // atrás lo suficiente. "home" no pasa por ese split.
      home: const SplashGate(),
    );
  }
}
