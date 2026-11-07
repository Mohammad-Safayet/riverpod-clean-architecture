import 'dart:io';

import 'package:mason/mason.dart';

/// Adds the screen title string to both ARB files, then prints next steps.
void run(HookContext context) {
  final name = context.vars['name'] as String;
  final feature = context.vars['feature'] as String;
  final key = '${name.camelCase}Title';

  for (final locale in ['en', 'bn']) {
    final file = File('lib/l10n/app_$locale.arb');
    if (!file.existsSync()) continue;
    final text = file.readAsStringSync();
    if (text.contains('"$key"')) continue;
    final body = text.substring(0, text.lastIndexOf('}')).trimRight();
    file.writeAsStringSync('$body,\n\n  "$key": "${name.sentenceCase}"\n}\n');
  }

  context.logger
    ..info('')
    ..success('Created ${name.pascalCase}Screen in features/$feature.')
    ..info('Next:')
    ..info('  1. Add a route in lib/app/router/routes.dart (see AGENTS.md → Routing).')
    ..info('  2. Translate "$key" in lib/l10n/app_bn.arb.')
    ..info('  3. make gen   (or keep `make watch` running), then make check.');
}
