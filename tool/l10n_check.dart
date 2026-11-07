// Localization check, part of `make check` and CI.
//
// Errors (exit 1):
//   - a key missing from, or extra in, any app_<locale>.arb compared to app_en.arb
//   - a translation that drops or renames a {placeholder}
//   - a hardcoded user-visible string in lib/ (Text('...'), labelText: '...', ...)
// Warnings:
//   - a translation identical to English (often a forgotten copy-paste)
//
// Silence a deliberate literal with a trailing `// l10n-ignore` on that line.
// Usage: dart run tool/l10n_check.dart
import 'dart:convert';
import 'dart:io';

const _l10nDir = 'lib/l10n';
const _templateLocale = 'en';

/// Widget arguments that put text on screen.
final _uiLiteral = RegExp(
  r'''(?:\bText\(|\b(?:labelText|hintText|helperText|errorText|tooltip|semanticLabel|semanticsLabel|label|title|message):\s*)(?:const\s+)?(['"])((?:(?!\1).)*)\1''',
);

void main() {
  final errors = <String>[];
  final warnings = <String>[];

  _checkArbFiles(errors, warnings);
  _checkHardcodedStrings(errors);

  for (final w in warnings) {
    stdout.writeln('warning: $w');
  }
  for (final e in errors) {
    stderr.writeln('error: $e');
  }
  if (errors.isNotEmpty) {
    stderr.writeln('\n${errors.length} l10n error(s). See docs/architecture/l10n.md.');
    exit(1);
  }
  stdout.writeln('l10n OK (${warnings.length} warning(s)).');
}

Map<String, String> _messages(File file) {
  final json = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
  return {
    for (final MapEntry(:key, :value) in json.entries)
      if (!key.startsWith('@')) key: value as String,
  };
}

Set<String> _placeholders(String message) =>
    RegExp(r'\{(\w+)').allMatches(message).map((m) => m[1]!).toSet();

void _checkArbFiles(List<String> errors, List<String> warnings) {
  const templateName = 'app_$_templateLocale.arb';
  final base = _messages(File('$_l10nDir/$templateName'));
  final others = Directory(_l10nDir).listSync().whereType<File>().where((f) {
    final name = f.uri.pathSegments.last;
    return RegExp(r'^app_\w+\.arb$').hasMatch(name) && name != templateName;
  });

  for (final file in others) {
    final name = file.uri.pathSegments.last;
    final messages = _messages(file);
    for (final key in base.keys.where((k) => !messages.containsKey(k))) {
      errors.add('$name is missing "$key" (en: "${base[key]}")');
    }
    for (final key in messages.keys.where((k) => !base.containsKey(k))) {
      errors.add('$name has "$key", which app_en.arb doesn\'t define');
    }
    for (final MapEntry(:key, :value) in messages.entries) {
      final english = base[key];
      if (english == null) continue;
      final missing = _placeholders(english).difference(_placeholders(value));
      if (missing.isNotEmpty) {
        errors.add('$name "$key" lost placeholder(s) ${missing.map((p) => '{$p}').join(', ')}');
      }
      final words = english.replaceAll(RegExp(r'\{[^}]*\}'), '');
      if (value == english && RegExp('[A-Za-z]{3,}').hasMatch(words)) {
        warnings.add('$name "$key" is identical to English: "$value"');
      }
    }
  }
}

void _checkHardcodedStrings(List<String> errors) {
  final files = Directory('lib').listSync(recursive: true).whereType<File>().where((f) {
    final p = f.path.replaceAll(r'\', '/');
    return p.endsWith('.dart') &&
        !p.endsWith('.g.dart') &&
        !p.endsWith('.freezed.dart') &&
        !p.contains('lib/gen/') &&
        !p.contains('lib/l10n/');
  });

  for (final file in files) {
    final lines = file.readAsLinesSync();
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      if (line.contains('l10n-ignore') || line.trimLeft().startsWith('//')) continue;
      for (final match in _uiLiteral.allMatches(line)) {
        final text = match[2]!.replaceAll(RegExp(r'\$\{[^}]*\}|\$\w+'), '');
        if (RegExp(r'\p{L}', unicode: true).hasMatch(text)) {
          final path = file.path.replaceAll(r'\', '/');
          errors.add('$path:${i + 1} hardcoded UI string "${match[2]}"; use context.l10n');
        }
      }
    }
  }
}
