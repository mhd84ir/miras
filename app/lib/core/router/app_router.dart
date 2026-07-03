import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';

import 'package:miras/dev/gallery_screen.dart';
import 'package:miras/features/home_path/presentation/home_screen.dart';

abstract final class AppRoutes {
  static const home = '/';
  static const gallery = '/dev/gallery';
}

final appRouter = GoRouter(
  routes: [
    GoRoute(
      path: AppRoutes.home,
      builder: (context, state) => const HomeScreen(),
    ),
    // Design-system gallery: development builds only.
    if (kDebugMode)
      GoRoute(
        path: AppRoutes.gallery,
        builder: (context, state) => const GalleryScreen(),
      ),
  ],
);
