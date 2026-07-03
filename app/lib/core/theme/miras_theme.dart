import 'package:flutter/material.dart';

import 'package:miras/core/theme/miras_colors.dart';
import 'package:miras/core/theme/miras_text_styles.dart';

/// Builds the app [ThemeData] from Miras design tokens.
ThemeData buildMirasTheme(Brightness brightness) {
  final colors = brightness == Brightness.light
      ? MirasColors.light
      : MirasColors.dark;

  final textTheme = TextTheme(
    displaySmall: MirasTextStyles.display.copyWith(color: colors.ink),
    headlineSmall: MirasTextStyles.headline.copyWith(color: colors.ink),
    titleMedium: MirasTextStyles.title.copyWith(color: colors.ink),
    bodyMedium: MirasTextStyles.body.copyWith(color: colors.ink),
    bodySmall: MirasTextStyles.bodySmall.copyWith(color: colors.inkMuted),
    labelSmall: MirasTextStyles.caption.copyWith(color: colors.inkMuted),
    labelLarge: MirasTextStyles.button.copyWith(color: colors.ink),
  );

  final colorScheme = ColorScheme(
    brightness: brightness,
    primary: colors.firoozeh,
    onPrimary: Colors.white,
    secondary: colors.lajvard,
    onSecondary: Colors.white,
    error: colors.anari,
    onError: Colors.white,
    surface: colors.surface,
    onSurface: colors.ink,
    outline: colors.hairline,
    surfaceContainerHighest: colors.surfaceVariant,
  );

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    fontFamily: MirasTextStyles.uiFontFamily,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: colors.background,
    textTheme: textTheme,
    extensions: [colors],
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      titleTextStyle: MirasTextStyles.headline.copyWith(color: colors.ink),
      iconTheme: IconThemeData(color: colors.ink),
    ),
    dividerTheme: DividerThemeData(
      color: colors.hairline,
      thickness: 1,
      space: 1,
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: colors.ink,
      contentTextStyle: MirasTextStyles.body.copyWith(color: colors.surface),
      behavior: SnackBarBehavior.floating,
    ),
  );
}
