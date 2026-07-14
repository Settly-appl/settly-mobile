import 'package:flutter/material.dart';

/// Wraps a tappable element so it feels right on the web/desktop: shows a
/// pointer cursor and a subtle scale on hover. On touch platforms there's no
/// pointer, so the hover state simply never triggers — behaviour is unchanged.
class Hoverable extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  /// Prawy przycisk myszy (desktop) — zwykle to samo co [onLongPress].
  /// Natywne menu przeglądarki jest wyłączone globalnie w `main()`
  /// (`BrowserContextMenu.disableContextMenu`), więc nic nie koliduje.
  final VoidCallback? onSecondaryTap;

  /// How much to scale up while hovered. 1.0 disables the scale effect.
  final double hoverScale;

  const Hoverable({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.onSecondaryTap,
    this.hoverScale = 1.02,
  });

  @override
  State<Hoverable> createState() => _HoverableState();
}

class _HoverableState extends State<Hoverable> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: widget.onTap == null
          ? MouseCursor.defer
          : SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: GestureDetector(
        onTap: widget.onTap,
        onLongPress: widget.onLongPress,
        onSecondaryTap: widget.onSecondaryTap,
        child: AnimatedScale(
          scale: _hovering ? widget.hoverScale : 1.0,
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOut,
          child: widget.child,
        ),
      ),
    );
  }
}
