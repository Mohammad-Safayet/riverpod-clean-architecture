import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:riverpod_clean_architecture/core/base/base_notifier.dart';

part 'gen/{{name.snakeCase()}}_notifier.g.dart';

/// Page data: change build() to return a Future and render it with asyncBody.
/// Actions: call methods that use callDataService (loader + error snackbar built in).
@riverpod
class {{name.pascalCase()}}Notifier extends _${{name.pascalCase()}}Notifier with BaseNotifier {
  @override
  void build() {}
}
