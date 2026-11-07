// Format check for hand-written Dart files only. Generated files (*.g.dart,
// *.freezed.dart, lib/gen, lib/l10n/generated) don't follow our page width and
// aren't committed, so they're skipped.
//
// Usage: dart run tool/format_check.dart        (check, exit 1 if anything changes)
//        dart run tool/format_check.dart --fix  (format in place)
import 'dart:io';

bool _generated(String path) {
  final p = path.replaceAll(r'\', '/');
  return p.endsWith('.g.dart') ||
      p.endsWith('.freezed.dart') ||
      p.contains('lib/gen/') ||
      p.contains('lib/l10n/generated/');
}

Future<void> main(List<String> args) async {
  final files = [
    for (final dir in ['lib', 'test', 'tool'])
      if (Directory(dir).existsSync())
        ...Directory(dir)
            .listSync(recursive: true)
            .whereType<File>()
            .map((f) => f.path)
            .where((p) => p.endsWith('.dart') && !_generated(p)),
  ];
  final fix = args.contains('--fix');
  final result = await Process.run(Platform.resolvedExecutable, [
    'format',
    if (!fix) '--set-exit-if-changed',
    if (!fix) '--output=none',
    ...files,
  ]);
  stdout.write(result.stdout);
  stderr.write(result.stderr);
  if (result.exitCode != 0 && !fix) {
    stderr.writeln('\nFiles above need formatting. Run: make format');
  }
  exit(result.exitCode);
}
