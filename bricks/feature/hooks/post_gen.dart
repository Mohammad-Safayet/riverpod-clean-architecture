import 'dart:io';

import 'package:mason/mason.dart';

/// Adds the pieces mason can't template because they live in existing files:
/// the endpoint constant and the screen title strings. Then prints next steps.
void run(HookContext context) {
  final name = context.vars['name'] as String;
  final lite = context.vars['lite'] as bool;
  final camel = name.camelCase;
  final title = name.sentenceCase;

  _insertBeforeLastBrace(
    'lib/core/network/api_endpoints.dart',
    "  static const $camel = '/${name.paramCase}';\n",
    marker: ' $camel =',
    logger: context.logger,
  );
  for (final locale in ['en', 'bn']) {
    _addArbKey('lib/l10n/app_$locale.arb', '${camel}Title', title, context.logger);
  }

  context.logger
    ..info('')
    ..success('Created ${lite ? 'lite' : 'full'} feature "$name".')
    ..info('Next:')
    ..info('  1. Add a route in lib/app/router/routes.dart (see AGENTS.md → Routing).')
    ..info('  2. Fix the endpoint path in lib/core/network/api_endpoints.dart and the model fields.')
    ..info('  3. Translate "${camel}Title" in lib/l10n/app_bn.arb.')
    ..info('  4. make gen   (or keep `make watch` running), then make check.');
}

void _insertBeforeLastBrace(String path, String line, {required String marker, required Logger logger}) {
  final file = File(path);
  if (!file.existsSync()) return logger.warn('Skipped $path (not found)');
  final text = file.readAsStringSync();
  if (text.contains(marker)) return;
  final end = text.lastIndexOf('}');
  file.writeAsStringSync('${text.substring(0, end)}$line${text.substring(end)}');
}

void _addArbKey(String path, String key, String value, Logger logger) {
  final file = File(path);
  if (!file.existsSync()) return logger.warn('Skipped $path (not found)');
  final text = file.readAsStringSync();
  if (text.contains('"$key"')) return;
  final end = text.lastIndexOf('}');
  final body = text.substring(0, end).trimRight();
  file.writeAsStringSync('$body,\n\n  "$key": "$value"\n}\n');
}
