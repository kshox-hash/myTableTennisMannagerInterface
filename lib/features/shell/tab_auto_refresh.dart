import 'package:flutter/material.dart';
import 'package:myttmi/features/shell/app_shell.dart';

/// Recarga los datos de una pestaña del shell sola cuando el usuario vuelve
/// a ella — el IndexedStack del shell mantiene las 5 pestañas vivas todo el
/// tiempo (no las recrea al volver), así que sin esto una pestaña se queda
/// mostrando datos viejos para siempre después de la primera carga. Evita
/// necesitar un botón de "actualizar" manual en cada pantalla.
mixin TabAutoRefreshMixin<T extends StatefulWidget> on State<T> {
  /// Índice de esta pestaña dentro de AppShell._tabs.
  int get tabIndex;

  /// Se llama cada vez que el usuario navega A esta pestaña (no en el
  /// primer build, eso ya lo cubre initState de cada pantalla).
  void onTabActivated();

  int? _lastIndex;
  // Al volver a la app (desde WhatsApp, la cámara, etc.) la pestaña que se
  // está viendo se recarga: lo que cargó el organizador aparece sin tener
  // que deslizar. No hay recarga cada X segundos.
  late final _ResumeObserver _resume = _ResumeObserver(() {
    if (mounted && AppShellScope.of(context)?.currentIndex == tabIndex) onTabActivated();
  });

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(_resume);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(_resume);
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final current = AppShellScope.of(context)?.currentIndex;
    if (current == tabIndex && _lastIndex != tabIndex) {
      onTabActivated();
    }
    _lastIndex = current;
  }
}

class _ResumeObserver extends WidgetsBindingObserver {
  final VoidCallback onResume;
  _ResumeObserver(this.onResume);

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) onResume();
  }
}
