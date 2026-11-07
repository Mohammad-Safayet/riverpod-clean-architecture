import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:riverpod_clean_architecture/core/base/base_screen.dart';
import 'package:riverpod_clean_architecture/core/extensions/context_extensions.dart';
import 'package:riverpod_clean_architecture/features/{{feature.snakeCase()}}/presentation/notifiers/{{name.snakeCase()}}_notifier.dart';
{{^stateful}}

class {{name.pascalCase()}}Screen extends BaseScreen {
  const {{name.pascalCase()}}Screen({super.key});

  @override
  PreferredSizeWidget? appBar(BuildContext context, WidgetRef ref) =>
      AppBar(title: Text(context.l10n.{{name.camelCase()}}Title));

  @override
  Widget body(BuildContext context, WidgetRef ref) {
    ref.watch({{name.camelCase()}}Provider);
    return const SizedBox.shrink();
  }
}
{{/stateful}}
{{#stateful}}

class {{name.pascalCase()}}Screen extends BaseStatefulScreen {
  const {{name.pascalCase()}}Screen({super.key});

  @override
  BaseScreenState<{{name.pascalCase()}}Screen> createState() => _{{name.pascalCase()}}ScreenState();
}

class _{{name.pascalCase()}}ScreenState extends BaseScreenState<{{name.pascalCase()}}Screen> {
  @override
  void dispose() {
    // Dispose controllers here.
    super.dispose();
  }

  @override
  PreferredSizeWidget? appBar(BuildContext context, WidgetRef ref) =>
      AppBar(title: Text(context.l10n.{{name.camelCase()}}Title));

  @override
  Widget body(BuildContext context, WidgetRef ref) {
    ref.watch({{name.camelCase()}}Provider);
    return const SizedBox.shrink();
  }
}
{{/stateful}}
