import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:miras/core/l10n/gen/app_localizations.dart';
import 'package:miras/core/persian_text/persian_text.dart';
import 'package:miras/dev/gallery_screen.dart';
import 'package:miras/features/gamification/application/stats_providers.dart';
import 'package:miras/features/home_path/presentation/home_path_screen.dart';
import 'package:miras/features/lesson/presentation/lesson_screen.dart';
import 'package:miras/features/library/presentation/library_chapter_screen.dart';
import 'package:miras/features/library/presentation/library_screen.dart';
import 'package:miras/features/onboarding/presentation/onboarding_screen.dart';
import 'package:miras/features/profile/presentation/profile_screen.dart';
import 'package:miras/features/review/presentation/review_screen.dart';
import 'package:miras/features/review/presentation/review_session_screen.dart';

abstract final class AppRoutes {
  static const home = '/';
  static const onboarding = '/onboarding';
  static const review = '/review';
  static const reviewSession = '/review/session';
  static const library = '/library';
  static const profile = '/profile';
  static const gallery = '/dev/gallery';

  static String lesson(String lessonId) => '/lesson/$lessonId';
}

/// [initialLocation] is decided once at bootstrap: /onboarding on first run.
GoRouter createAppRouter({String initialLocation = AppRoutes.home}) => GoRouter(
  initialLocation: initialLocation,
  routes: [
    GoRoute(
      path: AppRoutes.onboarding,
      builder: (context, state) => const OnboardingScreen(),
    ),
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
              path: AppRoutes.review,
              builder: (context, state) => const ReviewScreen(),
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
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.profile,
              builder: (context, state) => const ProfileScreen(),
            ),
          ],
        ),
      ],
    ),
    // Full-screen flows — no bottom navigation.
    GoRoute(
      path: '/lesson/:lessonId',
      builder: (context, state) => LessonScreen(
        lessonId: state.pathParameters['lessonId']!,
      ),
    ),
    GoRoute(
      path: AppRoutes.reviewSession,
      builder: (context, state) => const ReviewSessionScreen(),
    ),
    // Design-system gallery: development builds only.
    if (kDebugMode)
      GoRoute(
        path: AppRoutes.gallery,
        builder: (context, state) => const GalleryScreen(),
      ),
  ],
);

class _NavigationShell extends ConsumerWidget {
  const _NavigationShell({required this.shell});

  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppLocalizations.of(context);
    final due = ref.watch(dueCountProvider).value ?? 0;

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
            icon: Badge(
              isLabelVisible: due > 0,
              label: Text(PersianText.number(due)),
              child: const Icon(Icons.style_outlined),
            ),
            selectedIcon: Badge(
              isLabelVisible: due > 0,
              label: Text(PersianText.number(due)),
              child: const Icon(Icons.style),
            ),
            label: strings.navReview,
          ),
          NavigationDestination(
            icon: const Icon(Icons.auto_stories_outlined),
            selectedIcon: const Icon(Icons.auto_stories),
            label: strings.navLibrary,
          ),
          NavigationDestination(
            icon: const Icon(Icons.person_outline),
            selectedIcon: const Icon(Icons.person),
            label: strings.navProfile,
          ),
        ],
      ),
    );
  }
}
