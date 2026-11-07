// Fast checks on what's being committed. Run by .githooks/pre-commit
// (install once with `make hooks` / `./setup.ps1 hooks`).
//
// 1. Formatting of staged Dart files (hand-written only).
// 2. Analyzer (lints, riverpod_lint, package imports) on staged Dart files.
// 3. l10n check when an .arb or a lib/ Dart file is staged.
// Tests aren't run here (CI runs them). Skip in an emergency: git commit --no-verify
import 'dart:io';

bool _generated(String p) =>
    p.endsWith('.g.dart') ||
    p.endsWith('.freezed.dart') ||
    p.contains('/gen/') ||
    p.contains('l10n/generated/');

Future<void> main() async {
  final staged = (await Process.run('git', [
    'diff',
    '--cached',
    '--name-only',
    '--diff-filter=ACMR',
  ])).stdout.toString().split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty).toList();

  final dart = staged
      .where((p) => p.endsWith('.dart') && !_generated(p) && !p.startsWith('bricks/'))
      .where((p) => File(p).existsSync())
      .toList();
  final needsL10n = staged.any(
    (p) => p.endsWith('.arb') || (p.startsWith('lib/') && p.endsWith('.dart')),
  );

  if (dart.isEmpty && !needsL10n) return;

  final dartExe = Platform.resolvedExecutable;
  var failed = false;

  Future<void> step(String name, List<String> args) async {
    stdout.writeln('pre-commit: $name');
    final result = await Process.run(dartExe, args);
    if (result.exitCode != 0) {
      failed = true;
      stdout.write(result.stdout);
      stderr.write(result.stderr);
    }
  }

  if (dart.isNotEmpty) {
    await step('format', ['format', '--set-exit-if-changed', '--output=none', ...dart]);
    await step('analyze', ['analyze', '--fatal-infos', ...dart]);
  }
  if (needsL10n) await step('l10n', ['run', 'tool/l10n_check.dart']);

  if (failed) {
    stderr.writeln(
      '\npre-commit failed. Fix the above (`make format` fixes formatting and import order),\n'
      'stage the changes, and commit again.',
    );
    exit(1);
  }
}
