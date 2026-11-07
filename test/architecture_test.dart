// Enforces the layer rules from AGENTS.md by scanning imports in lib/.
// When this fails, fix the import, don't loosen the rule. If a rule really has
// to change, update AGENTS.md and docs/architecture/layers.md in the same change.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

const _package = 'riverpod_clean_architecture';

/// A file in lib/ and the lib-relative paths it imports (package imports only for our package).
class _Source {
  _Source(this.path, this.imports);

  final String path; // e.g. features/auth/data/sources/auth_remote_source.dart
  final List<String> imports; // lib-relative paths, or 'package:x/...' for other packages

  String? get feature => path.startsWith('features/') ? path.split('/')[1] : null;
  String? get layer => feature == null ? null : path.split('/')[2];
}

List<_Source> _loadSources() {
  final lib = Directory('lib');
  final importPattern = RegExp(r'''^\s*(?:import|export)\s+['"]([^'"]+)['"]''', multiLine: true);
  final sources = <_Source>[];

  for (final file in lib.listSync(recursive: true).whereType<File>()) {
    final rel = p.posix.joinAll(p.split(p.relative(file.path, from: lib.path)));
    if (!rel.endsWith('.dart') ||
        rel.endsWith('.g.dart') ||
        rel.endsWith('.freezed.dart') ||
        rel.startsWith('gen/') ||
        rel.startsWith('l10n/generated/')) {
      continue;
    }
    final imports = importPattern.allMatches(file.readAsStringSync()).map((m) {
      final uri = m[1]!;
      if (uri.startsWith('package:$_package/')) return uri.substring('package:$_package/'.length);
      if (uri.startsWith('package:') || uri.startsWith('dart:')) return uri;
      return p.posix.normalize(p.posix.join(p.posix.dirname(rel), uri));
    }).toList();
    sources.add(_Source(rel, imports));
  }
  return sources;
}

bool _isFullFeature(String feature) => Directory('lib/features/$feature/domain').existsSync();

void main() {
  final sources = _loadSources();
  final violations = <String>[];

  void check(bool ok, _Source source, String import, String rule) {
    if (!ok) violations.add('${source.path}\n    imports $import\n    ✗ $rule');
  }

  setUp(violations.clear);
  tearDown(() {
    if (violations.isNotEmpty) fail('\n${violations.join('\n\n')}\n');
  });

  test('sanity: sources were found', () {
    expect(sources.where((s) => s.path.startsWith('features/')), isNotEmpty);
  });

  test('core/ and flavors/ never import features/ or app/', () {
    for (final s in sources.where(
      (s) => s.path.startsWith('core/') || s.path.startsWith('flavors/'),
    )) {
      for (final i in s.imports) {
        check(
          !i.startsWith('features/') && !i.startsWith('app/'),
          s,
          i,
          'core is shared by everything, so it cannot depend on features or app',
        );
      }
    }
  });

  test('features never import another feature', () {
    for (final s in sources.where((s) => s.feature != null)) {
      for (final i in s.imports.where((i) => i.startsWith('features/'))) {
        check(
          i.split('/')[1] == s.feature,
          s,
          i,
          'move shared code to core/, or share data through a core provider',
        );
      }
    }
  });

  test('features only import app/router/routes.dart from app/', () {
    for (final s in sources.where((s) => s.feature != null)) {
      for (final i in s.imports.where((i) => i.startsWith('app/'))) {
        check(
          i == 'app/router/routes.dart',
          s,
          i,
          'features may navigate with typed routes, nothing else from app/',
        );
      }
    }
  });

  test('domain/ is pure Dart: no Flutter, Dio, Riverpod, data/ or presentation/', () {
    for (final s in sources.where((s) => s.layer == 'domain')) {
      for (final i in s.imports) {
        final pkgOk =
            !i.startsWith('package:') ||
            i.startsWith('package:freezed_annotation/') ||
            i.startsWith('package:meta/');
        final layerOk =
            !i.contains('/data/') &&
            !i.contains('/presentation/') &&
            !i.endsWith('_providers.dart') &&
            !i.startsWith('app/');
        check(
          pkgOk && layerOk,
          s,
          i,
          'domain may import only dart:, freezed_annotation, core/ and its own domain/',
        );
      }
    }
  });

  test('data/ never imports presentation/', () {
    for (final s in sources.where((s) => s.layer == 'data')) {
      for (final i in s.imports) {
        check(!i.contains('/presentation/'), s, i, 'data must not know about the UI');
      }
    }
  });

  test('presentation/ never imports data/sources/; full features never import data/ at all', () {
    for (final s in sources.where((s) => s.layer == 'presentation')) {
      final full = _isFullFeature(s.feature!);
      for (final i in s.imports.where((i) => i.startsWith('features/'))) {
        check(
          !i.contains('/data/sources/'),
          s,
          i,
          'go through the repository, never call a remote source from the UI',
        );
        if (full) {
          check(
            !i.contains('/data/'),
            s,
            i,
            'full feature: use domain/ entities and <feature>_providers.dart, not data/',
          );
        }
      }
    }
  });
}
