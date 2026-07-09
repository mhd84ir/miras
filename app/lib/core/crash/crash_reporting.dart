import 'package:flutter/foundation.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

/// Backend DSN, injected per-build (`--dart-define=SENTRY_DSN=...`) and never
/// committed (ADR-0007). Empty means crash reporting is fully disabled —
/// the default for every dev build.
const sentryDsn = String.fromEnvironment('SENTRY_DSN');

/// Privacy-respecting configuration (ADR-0007), pointed at the self-hosted
/// GlitchTip backend (ADR-0009): stack traces, app version, and device
/// model/OS only — no PII, no screenshots, no view hierarchy, no tracing.
/// The release name is auto-detected from the package (name@version+build).
void configureSentryOptions(SentryFlutterOptions options) {
  options
    ..dsn = sentryDsn
    ..environment = kReleaseMode ? 'beta' : 'dev'
    ..sendDefaultPii = false
    ..attachScreenshot = false
    ..tracesSampleRate = null;
}
