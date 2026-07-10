/// CDN manifest + bundled sidecar for the pack update protocol (ADR-0010).
library;

/// Everything a future downloader needs to fetch and verify a pack. Signed
/// at release time (tool/release/sign_manifest.sh); deterministic except
/// [builtAt].
Map<String, Object?> buildManifest({
  required int packVersion,
  required int schemaVersion,
  required String checksum,
  required Map<String, ({String sha256, int bytes})> files,
  required DateTime builtAt,
}) => {
  'schema': 1,
  'pack_version': packVersion,
  'schema_version': schemaVersion,
  'checksum': checksum,
  'built_at': builtAt.toUtc().toIso8601String(),
  'files': [
    for (final path in files.keys.toList()..sort())
      {
        'path': path,
        'sha256': files[path]!.sha256,
        'bytes': files[path]!.bytes,
      },
  ],
};

/// Tiny sidecar bundled with the app: lets the bootstrap decide whether the
/// installed pack matches the bundled one without reading either DB's bytes.
Map<String, Object?> buildPackMeta({
  required int packVersion,
  required String checksum,
}) => {'pack_version': packVersion, 'checksum': checksum};
