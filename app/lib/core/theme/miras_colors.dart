import 'package:flutter/material.dart';

/// Miras color tokens (docs/DESIGN_SYSTEM.md §2).
///
/// Widgets read colors via `context.mirasColors` — never raw hex values.
@immutable
class MirasColors extends ThemeExtension<MirasColors> {
  const MirasColors({
    required this.firoozeh,
    required this.action,
    required this.onAction,
    required this.lajvard,
    required this.zarrin,
    required this.anari,
    required this.sabz,
    required this.atash,
    required this.background,
    required this.surface,
    required this.surfaceVariant,
    required this.ink,
    required this.inkMuted,
    required this.hairline,
  });

  /// Primary — turquoise (فیروزه): active states, progress, icon fills,
  /// large text. For normal-size text or filled CTAs use [action]/[onAction]
  /// — raw firoozeh misses WCAG AA (4.5:1) against paper and under white.
  final Color firoozeh;

  /// Accessible companion to [firoozeh] for CTA fills and accent text at
  /// normal sizes: deep turquoise in light, bright turquoise in dark. Pairs
  /// with [onAction] at ≥ 5:1.
  final Color action;

  /// Label/icon color on [action] fills.
  final Color onAction;

  /// Secondary — lapis (لاجورد): links, info, selected chips.
  final Color lajvard;

  /// Accent — gold (زرین): ornament, celebration, achievements only.
  final Color zarrin;

  /// Error — pomegranate (اناری): wrong answers, hearts.
  final Color anari;

  /// Success (سبز): correct answers.
  final Color sabz;

  /// Streak flame / warm highlight (آتش).
  final Color atash;

  final Color background;
  final Color surface;
  final Color surfaceVariant;
  final Color ink;
  final Color inkMuted;
  final Color hairline;

  static const light = MirasColors(
    firoozeh: Color(0xFF14A098),
    action: Color(0xFF0F766E),
    onAction: Color(0xFFFFFFFF),
    lajvard: Color(0xFF26619C),
    zarrin: Color(0xFFC9A227),
    anari: Color(0xFFB33A3A),
    sabz: Color(0xFF3B8C5A),
    atash: Color(0xFFE08A2E),
    background: Color(0xFFFAF6EE),
    surface: Color(0xFFFFFFFF),
    surfaceVariant: Color(0xFFF1EAD9),
    ink: Color(0xFF1E2630),
    inkMuted: Color(0xFF5A6472),
    hairline: Color(0xFFE4DCC9),
  );

  static const dark = MirasColors(
    firoozeh: Color(0xFF2FC4B2),
    action: Color(0xFF2FC4B2),
    onAction: Color(0xFF0F1826),
    lajvard: Color(0xFF5B8FCB),
    zarrin: Color(0xFFD9B44A),
    anari: Color(0xFFD46A6A),
    sabz: Color(0xFF5FAE7E),
    atash: Color(0xFFE8A455),
    background: Color(0xFF0F1826),
    surface: Color(0xFF16202F),
    surfaceVariant: Color(0xFF1D2A3C),
    ink: Color(0xFFEDE7DA),
    inkMuted: Color(0xFF9AA3B0),
    hairline: Color(0xFF273548),
  );

  @override
  MirasColors copyWith({
    Color? firoozeh,
    Color? action,
    Color? onAction,
    Color? lajvard,
    Color? zarrin,
    Color? anari,
    Color? sabz,
    Color? atash,
    Color? background,
    Color? surface,
    Color? surfaceVariant,
    Color? ink,
    Color? inkMuted,
    Color? hairline,
  }) {
    return MirasColors(
      firoozeh: firoozeh ?? this.firoozeh,
      action: action ?? this.action,
      onAction: onAction ?? this.onAction,
      lajvard: lajvard ?? this.lajvard,
      zarrin: zarrin ?? this.zarrin,
      anari: anari ?? this.anari,
      sabz: sabz ?? this.sabz,
      atash: atash ?? this.atash,
      background: background ?? this.background,
      surface: surface ?? this.surface,
      surfaceVariant: surfaceVariant ?? this.surfaceVariant,
      ink: ink ?? this.ink,
      inkMuted: inkMuted ?? this.inkMuted,
      hairline: hairline ?? this.hairline,
    );
  }

  @override
  MirasColors lerp(MirasColors? other, double t) {
    if (other == null) return this;
    return MirasColors(
      firoozeh: Color.lerp(firoozeh, other.firoozeh, t)!,
      action: Color.lerp(action, other.action, t)!,
      onAction: Color.lerp(onAction, other.onAction, t)!,
      lajvard: Color.lerp(lajvard, other.lajvard, t)!,
      zarrin: Color.lerp(zarrin, other.zarrin, t)!,
      anari: Color.lerp(anari, other.anari, t)!,
      sabz: Color.lerp(sabz, other.sabz, t)!,
      atash: Color.lerp(atash, other.atash, t)!,
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceVariant: Color.lerp(surfaceVariant, other.surfaceVariant, t)!,
      ink: Color.lerp(ink, other.ink, t)!,
      inkMuted: Color.lerp(inkMuted, other.inkMuted, t)!,
      hairline: Color.lerp(hairline, other.hairline, t)!,
    );
  }
}

extension MirasColorsX on BuildContext {
  MirasColors get mirasColors => Theme.of(this).extension<MirasColors>()!;
}
