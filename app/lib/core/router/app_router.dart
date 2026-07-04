import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:miras/core/l10n/gen/app_localizations.dart';
import 'package:miras/dev/gallery_screen.dart';
import 'package:miras/features/home_path/presentation/home_path_screen.dart';
import 'package:miras/features/lesson/presentation/lesson_screen.dart';
import 'package:miras/features/library/presentation/library_chapter_screen.dart';
import 'package:miras/features/library/presentation/library_screen.dart';

abstract final class AppRoutes {
  static const home = '/';
  static const library = '/library';
  static const gallery = '/dev/gallery';

  static String lesson(String lessonId) => '/lesson/$lessonId';
}

final appRouter = GoRouter(
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, shell) => _NavigationShell(shell: shell),
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.home,
              builder: (context, state) => const HomePathScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.library,
              builder: (context, state) => const LibraryScreen(),
              routes: [
                GoRoute(
                  path: ':chapterId',
                  builder: (context, state) => LibraryChapterScreen(
                    chapterId: state.pathParameters['chapterId']!,
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    ),
    // Lessons take over the whole screen — no bottom navigation.
    GoRoute(
      path: '/lesson/:lessonId',
      builder: (context, state) => LessonScreen(
        lessonId: state.pathParameters['lessonId']!,
      ),
    ),
    // Design-system gallery: development builds only.
    if (kDebugMode)
      GoRoute(
        path: AppRoutes.gallery,
        builder: (context, state) => const GalleryScreen(),
      ),
  ],
);

class _NavigationShell extends StatelessWidget {
  const _NavigationShell({required this.shell});

  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return Scaffold(
      body: shell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: shell.currentIndex,
        onDestinationSelected: shell.goBranch,
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.school_outlined),
            selectedIcon: const Icon(Icons.school),
            label: strings.navHome,
          ),
          NavigationDestination(
            icon: const Icon(Icons.auto_stories_outlined),
            selectedIcon: const Icon(Icons.auto_stories),
            label: strings.navLibrary,
          ),
        ],
      ),
    );
  }
}
