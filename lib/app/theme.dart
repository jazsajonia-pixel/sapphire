import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';

/// Sapphire visual identity ("Deep Sapphire"): neutral blue-black slate
/// surfaces so the jewel blue is the only saturated color in the chrome,
/// a silver secondary, violet reserved for AI-inferred/derived things, and a
/// graph palette taken from the colors natural sapphires come in.
abstract final class SapphireTheme {
  /// Primary accent: the gem's lit-facet blue. AA contrast on every surface.
  static const Color sapphire = Color(0xFF5E95FF);
  static const Color sapphireDeep = Color(0xFF1E4FD0);

  /// Silver highlight (white sapphire) used as the secondary role.
  static const Color ice = Color(0xFFC3CEE0);

  /// Violet sapphire: AI-inferred links and AI surfaces only.
  static const Color violet = Color(0xFFA98BFF);
  static const Color ink = Color(0xFF05080F);
  static const Color surface = Color(0xFF0A0F1A);
  static const Color surfaceLow = Color(0xFF0F1522);
  static const Color surfaceMid = Color(0xFF141C2C);
  static const Color surfaceHigh = Color(0xFF1A2438);
  static const Color surfaceHighest = Color(0xFF222E46);
  static const Color onSurface = Color(0xFFE8EDF6);
  static const Color onSurfaceVariant = Color(0xFFA7B2C6);
  static const Color outline = Color(0xFF7F8BA3);
  static const Color outlineVariant = Color(0xFF2A3449);

  /// Notes changed by the latest sync (mint, distinct from every node color).
  static const Color changed = Color(0xFF69E6C1);

  /// Solid, distinct colors for graph nodes (one per folder group), named
  /// after sapphire varieties.
  static const List<Color> nodePalette = [
    Color(0xFF4F86F7), // royal blue
    Color(0xFF5CC8F2), // ceylon
    Color(0xFFF5C451), // yellow sapphire
    Color(0xFFFF9A76), // padparadscha
    Color(0xFFA98BFF), // violet sapphire
    Color(0xFF2CB8C7), // teal sapphire
    Color(0xFFF07AB0), // pink sapphire
    Color(0xFF8CCB6B), // green sapphire
    Color(0xFFD9E2F2), // white sapphire
    Color(0xFF8AA0C8), // steel
  ];
  static const Color unresolvedNode = Color(0xFF59647C);

  /// Soft background glow used behind hero areas.
  static const RadialGradient heroGlow = RadialGradient(
    center: Alignment(-0.6, -0.9),
    radius: 1.3,
    colors: [Color(0x261E4FD0), Color(0x0005080F)],
  );

  static ThemeData dark() {
    final scheme =
        ColorScheme.fromSeed(
          seedColor: sapphire,
          brightness: Brightness.dark,
        ).copyWith(
          primary: sapphire,
          onPrimary: ink,
          primaryContainer: const Color(0xFF163DA6),
          onPrimaryContainer: const Color(0xFFDCE7FF),
          secondary: ice,
          onSecondary: const Color(0xFF1A2333),
          secondaryContainer: const Color(0xFF2A3550),
          onSecondaryContainer: const Color(0xFFE1E8F4),
          tertiary: violet,
          onTertiary: const Color(0xFF241660),
          tertiaryContainer: const Color(0xFF3A2C78),
          onTertiaryContainer: const Color(0xFFE8E0FF),
          error: const Color(0xFFFFB4AB),
          onError: const Color(0xFF690005),
          errorContainer: const Color(0xFF93000A),
          onErrorContainer: const Color(0xFFFFDAD6),
          surface: surface,
          surfaceDim: ink,
          surfaceBright: surfaceHighest,
          surfaceContainerLowest: ink,
          surfaceContainerLow: surfaceLow,
          surfaceContainer: surfaceMid,
          surfaceContainerHigh: surfaceHigh,
          surfaceContainerHighest: surfaceHighest,
          surfaceTint: sapphire,
          onSurface: onSurface,
          onSurfaceVariant: onSurfaceVariant,
          outline: outline,
          outlineVariant: outlineVariant,
          shadow: Colors.black,
          scrim: Colors.black,
          inverseSurface: onSurface,
          onInverseSurface: surface,
          inversePrimary: sapphireDeep,
        );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      canvasColor: ink,
      cardColor: surfaceLow,
      visualDensity: VisualDensity.standard,
      splashFactory: InkSparkle.splashFactory,
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.linux: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.windows: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
        },
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(64, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(64, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          side: BorderSide(color: scheme.outlineVariant),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: surfaceLow,
        selectedColor: scheme.primaryContainer,
        side: BorderSide(color: scheme.outlineVariant),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? ink : outline,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? sapphire : surfaceHigh,
        ),
      ),
      materialTapTargetSize: MaterialTapTargetSize.padded,
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant.withValues(alpha: 0.72),
        thickness: 1,
        space: 1,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: CardThemeData(
        color: surfaceLow,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.7)),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: ink,
        surfaceTintColor: Colors.transparent,
        indicatorColor: scheme.primaryContainer,
        elevation: 0,
        labelTextStyle: WidgetStatePropertyAll(
          TextStyle(color: scheme.onSurfaceVariant),
        ),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected
                ? scheme.onPrimaryContainer
                : scheme.onSurfaceVariant,
          );
        }),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: ink,
        indicatorColor: scheme.primaryContainer,
        selectedIconTheme: IconThemeData(color: scheme.onPrimaryContainer),
        unselectedIconTheme: IconThemeData(color: scheme.onSurfaceVariant),
        selectedLabelTextStyle: TextStyle(
          color: scheme.onSurface,
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelTextStyle: TextStyle(color: scheme.onSurfaceVariant),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceLow,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: scheme.primary, width: 2),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: surfaceHighest,
        contentTextStyle: TextStyle(color: scheme.onSurface),
        actionTextColor: scheme.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

/// Sapphire's mark: a step-cut sapphire seen from above whose table is a
/// note page with a folded corner (a gem that holds your notes). Flat facets,
/// no outlines or sparkles, so it reads at 24 dp and in one color. The
/// Android launcher icon, splash and `tool/make_icons.py` use exactly this
/// geometry ([outer], [table], [fold]).
class SapphireMark extends StatelessWidget {
  const SapphireMark({
    super.key,
    this.size = 40,
    this.semanticsLabel = 'Sapphire',
  });

  final double size;
  final String semanticsLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticsLabel,
      image: true,
      child: SizedBox.square(
        dimension: size,
        child: const CustomPaint(painter: SapphireMarkPainter()),
      ),
    );
  }
}

class SapphireMarkPainter extends CustomPainter {
  const SapphireMarkPainter({this.glint = 0});

  /// 0..1 position of a moving light glint across the gem (0 = none).
  final double glint;

  /// Girdle outline (8 points, clockwise from the top-left).
  static const outer = <Offset>[
    Offset(.33, .05),
    Offset(.67, .05),
    Offset(.83, .21),
    Offset(.83, .79),
    Offset(.67, .95),
    Offset(.33, .95),
    Offset(.17, .79),
    Offset(.17, .21),
  ];

  /// Table (the note page); point i pairs with [outer] point i. The top-right
  /// chamfer is the page's folded corner.
  static const table = <Offset>[
    Offset(.43, .27),
    Offset(.53, .27),
    Offset(.64, .38),
    Offset(.64, .66),
    Offset(.57, .73),
    Offset(.43, .73),
    Offset(.36, .66),
    Offset(.36, .34),
  ];

  static const fold = <Offset>[
    Offset(.53, .27),
    Offset(.53, .38),
    Offset(.64, .38),
  ];

  /// Step facets lit from the upper left: facet i joins outer i..i+1 to
  /// table i+1..i.
  static const facetColors = <Color>[
    Color(0xFF5E95FF), // top
    Color(0xFF2F6BF2), // top-right
    Color(0xFF1E4FD0), // right
    Color(0xFF163DA6), // bottom-right
    Color(0xFF0F2D80), // bottom
    Color(0xFF1A46BC), // bottom-left
    Color(0xFF2F6BF2), // left
    Color(0xFF8FB8FF), // top-left
  ];
  static const tableColor = Color(0xFFD6E4FF);
  static const foldColor = Color(0xFF8FB8FF);

  static Path path(List<Offset> pts, Size size) {
    final p = Path()..moveTo(pts[0].dx * size.width, pts[0].dy * size.height);
    for (final o in pts.skip(1)) {
      p.lineTo(o.dx * size.width, o.dy * size.height);
    }
    return p..close();
  }

  @override
  void paint(Canvas canvas, Size size) {
    for (var i = 0; i < 8; i++) {
      final j = (i + 1) % 8;
      canvas.drawPath(
        path([outer[i], outer[j], table[j], table[i]], size),
        Paint()
          ..color = facetColors[i]
          ..isAntiAlias = true,
      );
    }
    canvas.drawPath(path(table, size), Paint()..color = tableColor);
    canvas.drawPath(path(fold, size), Paint()..color = foldColor);
    if (glint > 0 && glint < 1) {
      final w = size.width;
      canvas.save();
      canvas.clipPath(path(outer, size));
      final x = (glint * 1.6 - 0.3) * w;
      canvas.drawRect(
        Offset.zero & size,
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0x00FFFFFF), Color(0x40FFFFFF), Color(0x00FFFFFF)],
            stops: [0, 0.5, 1],
          ).createShader(Rect.fromLTWH(x - w * 0.25, 0, w * 0.5, size.height)),
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant SapphireMarkPainter old) => old.glint != glint;
}

/// The mark with a slow light glint passing over it (static under reduced
/// motion).
class AnimatedSapphireMark extends StatefulWidget {
  const AnimatedSapphireMark({super.key, this.size = 40});
  final double size;

  @override
  State<AnimatedSapphireMark> createState() => _AnimatedSapphireMarkState();
}

class _AnimatedSapphireMarkState extends State<AnimatedSapphireMark>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 4200),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduce = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (reduce) {
      _c.stop();
    } else if (!_c.isAnimating) {
      _c.repeat();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Sapphire',
    image: true,
    child: SizedBox.square(
      dimension: widget.size,
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, _) => CustomPaint(
          painter: SapphireMarkPainter(
            // Glint passes during the first 30% of each cycle.
            glint: _c.value < 0.3 ? _c.value / 0.3 : 0,
          ),
        ),
      ),
    ),
  );
}
