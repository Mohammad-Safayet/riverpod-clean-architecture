import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:riverpod_clean_architecture/core/base/base_screen.dart';
import 'package:riverpod_clean_architecture/core/extensions/context_extensions.dart';
import 'package:riverpod_clean_architecture/core/theme/app_values.dart';
import 'package:riverpod_clean_architecture/core/widgets/app_error_view.dart';
import 'package:riverpod_clean_architecture/features/{{name.snakeCase()}}/presentation/notifiers/{{name.snakeCase()}}_notifier.dart';

class {{name.pascalCase()}}Screen extends BaseScreen {
  const {{name.pascalCase()}}Screen({super.key});

  @override
  PreferredSizeWidget? appBar(BuildContext context, WidgetRef ref) =>
      AppBar(title: Text(context.l10n.{{name.camelCase()}}Title));

  @override
  Widget body(BuildContext context, WidgetRef ref) => asyncBody(
    ref.watch({{name.camelCase()}}Provider),
    onRetry: ref.read({{name.camelCase()}}Provider.notifier).retry,
    data: (items) => items.isEmpty
        ? const AppEmptyView()
        : ListView.separated(
            padding: const EdgeInsets.all(AppValues.padding),
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(height: AppValues.paddingSmall),
            itemBuilder: (context, index) => ListTile(title: Text(items[index].name)),
          ),
  );
}
