import "dart:async";

import "package:flutter/material.dart";
import "package:myttmi/core/constants/app_colors.dart";
import "package:myttmi/core/constants/app_typography.dart";
import "package:myttmi/core/ui/background_music.dart";
import "package:myttmi/core/ui/panel_style.dart";

/// Barra "Sonando" (estilo panel): baja desde arriba cuando empieza una
/// canción de la música de fondo, muestra el tema unos segundos y se va.
/// Va encima de todas las pantallas (en el builder de MaterialApp).
class NowPlayingBanner extends StatefulWidget {
  const NowPlayingBanner({super.key});

  @override
  State<NowPlayingBanner> createState() => _NowPlayingBannerState();
}

class _NowPlayingBannerState extends State<NowPlayingBanner> {
  static const _shown = Duration(seconds: 4);

  String? _title;
  bool _visible = false;
  Timer? _hide;

  @override
  void initState() {
    super.initState();
    BackgroundMusic.nowPlaying.addListener(_onSong);
  }

  @override
  void dispose() {
    BackgroundMusic.nowPlaying.removeListener(_onSong);
    _hide?.cancel();
    super.dispose();
  }

  void _onSong() {
    final t = BackgroundMusic.nowPlaying.value;
    if (t == null || !mounted) return;
    setState(() {
      _title = t;
      _visible = true;
    });
    _hide?.cancel();
    _hide = Timer(_shown, () {
      if (mounted) setState(() => _visible = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    return Positioned(
      left: 16,
      right: 16,
      top: top + 8,
      child: IgnorePointer(
        child: AnimatedSlide(
          offset: _visible ? Offset.zero : const Offset(0, -1.6),
          duration: const Duration(milliseconds: 320),
          curve: _visible ? Curves.easeOutCubic : Curves.easeInCubic,
          child: AnimatedOpacity(
            opacity: _visible ? 1 : 0,
            duration: const Duration(milliseconds: 250),
            child: _title == null
                ? const SizedBox.shrink()
                : Container(
                    padding: const EdgeInsets.fromLTRB(10, 9, 14, 9),
                    decoration: BoxDecoration(
                      gradient: Panel.gradient,
                      borderRadius: BorderRadius.circular(Panel.radius),
                      border: Border.all(color: Panel.edge),
                      boxShadow: const [BoxShadow(color: Color(0x99000000), blurRadius: 14, offset: Offset(0, 4))],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: panelBox(color: AppColors.scorifyMint),
                          child: const Icon(Icons.music_note_rounded, size: 18, color: AppColors.scorifyMint),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "SONANDO",
                                style: TextStyle(fontFamily: AppTypography.body, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.4, color: AppColors.scorifyMint, decoration: TextDecoration.none),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _title!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontFamily: AppTypography.body, fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.scorifyText, decoration: TextDecoration.none),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
