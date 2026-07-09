import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:miras/core/l10n/gen/app_localizations.dart';
import 'package:miras/core/persian_text/persian_text.dart';
import 'package:miras/core/share/share_service.dart';
import 'package:miras/core/theme/miras_colors.dart';
import 'package:miras/core/theme/miras_spacing.dart';
import 'package:miras/core/theme/miras_text_styles.dart';
import 'package:miras/features/profile/application/beta_report_provider.dart';
import 'package:miras/features/profile/domain/beta_metrics.dart';

/// PRD §7 beta metrics, computed locally on demand. Sharing is explicit and
/// user-initiated — the JSON goes wherever the user sends it, nowhere else.
class BetaReportScreen extends ConsumerWidget {
  const BetaReportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppLocalizations.of(context);
    final report = ref.watch(betaReportProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(strings.profileBetaReport),
        actions: [
          if (report case AsyncData(:final value))
            IconButton(
              tooltip: strings.betaReportShare,
              icon: const Icon(Icons.share),
              onPressed: () => ref
                  .read(shareServiceProvider)
                  .shareText(
                    const JsonEncoder.withIndent('  ').convert(value.toJson()),
                    subject: strings.profileBetaReport,
                  ),
            ),
        ],
      ),
      body: switch (report) {
        AsyncData(:final value) => _ReportView(report: value),
        AsyncError() => const SizedBox.shrink(),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }
}

class _ReportView extends StatelessWidget {
  const _ReportView({required this.report});

  final BetaMetricsReport report;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final colors = context.mirasColors;

    String percentOf(double accuracy) =>
        PersianText.number((accuracy * 100).round());

    return ListView(
      padding: const EdgeInsetsDirectional.all(MirasSpacing.screenMargin),
      children: [
        Text(
          strings.betaReportPrivacyNote,
          style: MirasTextStyles.bodySmall.copyWith(color: colors.inkMuted),
        ),
        const SizedBox(height: MirasSpacing.lg),
        _MetricRow(
          label: strings.betaReportLessons,
          value: PersianText.number(report.lessonsCompleted),
        ),
        _MetricRow(
          label: strings.betaReportActivation,
          value: switch (report.daysToActivation) {
            null => strings.betaReportNotYet,
            final days => strings.betaReportDaysAfterInstall(
              PersianText.number(days),
            ),
          },
        ),
        _MetricRow(
          label: strings.betaReportCurrentStreak,
          value: strings.statStreakDays(
            PersianText.number(report.effectiveStreak),
          ),
        ),
        _MetricRow(
          label: strings.betaReportLongestStreak,
          value: strings.statStreakDays(
            PersianText.number(report.longestStreak),
          ),
        ),
        _MetricRow(
          label: strings.betaReportSevenDay,
          value: report.sevenDayStreakReached
              ? strings.betaReportReached
              : strings.betaReportNotYet,
        ),
        _MetricRow(
          label: strings.betaReportAccuracy,
          value: report.totalAttempts == 0
              ? '—'
              : strings.betaReportAccuracyValue(
                  percentOf(report.totalCorrect / report.totalAttempts),
                  PersianText.number(report.totalAttempts),
                ),
        ),
        const SizedBox(height: MirasSpacing.xl),
        Text(
          strings.betaReportTrend,
          style: MirasTextStyles.title.copyWith(color: colors.ink),
        ),
        const SizedBox(height: MirasSpacing.sm),
        for (final (i, week) in report.weeklyAccuracy.reversed.indexed)
          _MetricRow(
            label: i == 0
                ? strings.betaReportThisWeek
                : strings.betaReportWeeksAgo(PersianText.number(i)),
            value: week.attempts == 0
                ? '—'
                : strings.betaReportAccuracyValue(
                    percentOf(week.accuracy),
                    PersianText.number(week.attempts),
                  ),
          ),
      ],
    );
  }
}

class _MetricRow extends StatelessWidget {
  const _MetricRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = context.mirasColors;
    return Padding(
      padding: const EdgeInsetsDirectional.only(bottom: MirasSpacing.sm),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: MirasTextStyles.body.copyWith(color: colors.inkMuted),
            ),
          ),
          Text(
            value,
            style: MirasTextStyles.body.copyWith(color: colors.ink),
          ),
        ],
      ),
    );
  }
}
