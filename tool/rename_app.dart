// Renames the app everywhere: Dart package, Android/iOS IDs, display names, base URL.
// Reads the current values from the project, so it also works after a first rename.
//
// Usage:
//   dart run tool/rename_app.dart --name "Shop" --package shop --android-id com.acme.shop \
//       [--ios-id com.acme.shop] [--base-url https://api.acme.com] [--dry-run]
//
// --ios-id defaults to --android-id with "_" → "-" (iOS bundle IDs can't contain "_").
// Flavor names become "<name> Dev" / "<name> Stg" / "<name>".
import 'dart:io';

const _skipDirs = {
  'build', '.dart_tool', '.fvm', '.git', '.idea', 'Pods', 'ephemeral', '.mason', 'node_modules', //
  'gen', 'generated', '.gradle', '.kotlin', '.cxx',
};
const _skipFiles = {
  'pubspec.lock', 'mason-lock.json', 'Generated.xcconfig', 'flutter_export_environment.sh', //
  'rename_app.dart',
};
const _binaryExt = {
  '.png', '.jpg', '.jpeg', '.gif', '.webp', '.ico', '.icns', '.ttf', '.otf', '.jks', //
  '.keystore', '.p12', '.zip', '.pdf', '.jar',
};

void main(List<String> argv) {
  final args = _parse(argv);
  final name = args['name'];
  final package = args['package'];
  final androidId = args['android-id'];
  if (name == null || package == null || androidId == null) _usage();
  final iosId = args['ios-id'] ?? androidId.replaceAll('_', '-');
  final baseUrl = args['base-url'];
  final dryRun = args.containsKey('dry-run');

  _check(RegExp(r'^[a-z][a-z0-9_]*$').hasMatch(package), '--package must be lower_snake_case');
  _check(
    RegExp(r'^[a-z][a-z0-9_]*(\.[a-z][a-z0-9_]*)+$').hasMatch(androidId),
    '--android-id must look like com.company.app (lowercase, digits, "_")',
  );
  _check(
    RegExp(r'^[A-Za-z0-9-]+(\.[A-Za-z0-9-]+)+$').hasMatch(iosId),
    '--ios-id may contain letters, digits, "-" and "." only',
  );

  final current = _currentValues();
  stdout.writeln('Current: ${current.entries.map((e) => '${e.key}=${e.value}').join(', ')}');

  // Order matters: IDs contain the package name, and "X Dev" contains "X".
  final replacements = <(Pattern, String)>[
    (current['androidId']!, androidId),
    (current['androidId']!.replaceAll('.', '/'), androidId.replaceAll('.', '/')),
    (current['iosId']!, iosId),
    (RegExp('\\b${RegExp.escape(current['package']!)}\\b'), package),
    ('${current['name']} Dev', '$name Dev'),
    ('${current['name']} Stg', '$name Stg'),
    (current['name']!, name),
    if (baseUrl != null) (current['baseUrl']!, baseUrl),
  ];

  var changedFiles = 0;
  final changedDart = <String>[];
  for (final file in _textFiles(Directory.current)) {
    final String before;
    try {
      before = file.readAsStringSync();
    } on FileSystemException {
      continue; // not UTF-8 text
    }
    var after = before;
    for (final (from, to) in replacements) {
      after = after.replaceAll(from, to);
    }
    if (after == before) continue;
    changedFiles++;
    stdout.writeln('  ${dryRun ? 'would change' : 'changed'} ${_rel(file.path)}');
    if (!dryRun) file.writeAsStringSync(after);
    if (file.path.endsWith('.dart') && !file.path.contains('{{')) changedDart.add(file.path);
  }

  // A different package name length changes line lengths in imports.
  if (!dryRun && changedDart.isNotEmpty) {
    Process.runSync(Platform.resolvedExecutable, ['format', ...changedDart]);
  }

  // Kotlin sources live in a folder per package segment.
  final oldKotlin = Directory(
    'android/app/src/main/kotlin/${current['androidId']!.replaceAll('.', '/')}',
  );
  final newKotlin = Directory('android/app/src/main/kotlin/${androidId.replaceAll('.', '/')}');
  if (oldKotlin.path != newKotlin.path && oldKotlin.existsSync()) {
    stdout.writeln('  ${dryRun ? 'would move' : 'moved'} ${oldKotlin.path} → ${newKotlin.path}');
    if (!dryRun) {
      newKotlin.createSync(recursive: true);
      for (final f in oldKotlin.listSync().whereType<File>()) {
        f.renameSync('${newKotlin.path}/${f.uri.pathSegments.last}');
      }
      _deleteEmptyParents(oldKotlin, stopAt: 'android/app/src/main/kotlin');
    }
  }

  stdout.writeln(
    dryRun
        ? '\nDry run: $changedFiles files would change. Run again without --dry-run.'
        : '\nRenamed in $changedFiles files. Next: fvm flutter clean && make setup && make check',
  );
}

Map<String, String> _currentValues() {
  String find(String path, RegExp pattern, String what) {
    final match = pattern.firstMatch(File(path).readAsStringSync());
    _check(match != null, 'Could not find the current $what in $path');
    return match![1]!;
  }

  return {
    'package': find('pubspec.yaml', RegExp(r'^name:\s*(\S+)', multiLine: true), 'package name'),
    'androidId': find(
      'android/app/build.gradle.kts',
      RegExp(r'applicationId = "([^"]+)"'),
      'Android applicationId',
    ),
    'iosId': find('tool/ios_flavors.dart', RegExp(r"baseBundleId = '([^']+)'"), 'iOS bundle ID'),
    'name': find('lib/main_prod.dart', RegExp(r"appName: '([^']+)'"), 'app name'),
    'baseUrl': find('lib/main_prod.dart', RegExp(r"baseUrl: '([^']+)'"), 'base URL'),
  };
}

Iterable<File> _textFiles(Directory dir) sync* {
  for (final entity in dir.listSync(followLinks: false)) {
    final base = entity.uri.pathSegments.lastWhere((s) => s.isNotEmpty);
    if (entity is Directory) {
      if (!_skipDirs.contains(base)) yield* _textFiles(entity);
    } else if (entity is File) {
      final dot = base.lastIndexOf('.');
      final ext = dot == -1 ? '' : base.substring(dot).toLowerCase();
      if (_skipFiles.contains(base) ||
          _binaryExt.contains(ext) ||
          base.endsWith('.g.dart') ||
          base.endsWith('.freezed.dart')) {
        continue;
      }
      yield entity;
    }
  }
}

void _deleteEmptyParents(Directory dir, {required String stopAt}) {
  var current = dir;
  while (current.existsSync() &&
      current.listSync().isEmpty &&
      _rel(current.path).replaceAll(r'\', '/') != stopAt) {
    current.deleteSync();
    current = current.parent;
  }
}

String _rel(String path) => path.startsWith(Directory.current.path)
    ? path.substring(Directory.current.path.length + 1)
    : path;

Map<String, String?> _parse(List<String> argv) {
  final out = <String, String?>{};
  for (var i = 0; i < argv.length; i++) {
    if (!argv[i].startsWith('--')) continue;
    final key = argv[i].substring(2);
    final hasValue = i + 1 < argv.length && !argv[i + 1].startsWith('--');
    out[key] = hasValue ? argv[++i] : null;
  }
  return out;
}

void _check(bool ok, String message) {
  if (ok) return;
  stderr.writeln('Error: $message');
  exit(64);
}

Never _usage() {
  stderr.writeln(
    'Usage: dart run tool/rename_app.dart --name "Shop" --package shop '
    '--android-id com.acme.shop [--ios-id com.acme.shop] [--base-url URL] [--dry-run]',
  );
  exit(64);
}
