import 'package:riverpod_annotation/riverpod_annotation.dart';

{{#lite}}
import 'package:riverpod_clean_architecture/features/{{name.snakeCase()}}/data/models/{{model.snakeCase()}}_model.dart';
import 'package:riverpod_clean_architecture/features/{{name.snakeCase()}}/data/repositories/{{model.snakeCase()}}_repository.dart';
{{/lite}}
{{^lite}}
import 'package:riverpod_clean_architecture/features/{{name.snakeCase()}}/{{name.snakeCase()}}_providers.dart';
import 'package:riverpod_clean_architecture/features/{{name.snakeCase()}}/domain/entities/{{model.snakeCase()}}.dart';
{{/lite}}

part 'gen/{{name.snakeCase()}}_notifier.g.dart';

/// Page data loads in build(); BaseScreen.asyncBody renders loading/error/data.
/// For user actions (submit, delete) add `with BaseNotifier` and use callDataService.
@riverpod
class {{name.pascalCase()}}Notifier extends _${{name.pascalCase()}}Notifier {
  @override
{{#lite}}
  Future<List<{{model.pascalCase()}}Model>> build() =>
      ref.watch({{model.camelCase()}}RepositoryProvider).get{{model.pascalCase()}}List();
{{/lite}}
{{^lite}}
  Future<List<{{model.pascalCase()}}>> build() => ref.watch(get{{model.pascalCase()}}ListUseCaseProvider)();
{{/lite}}

  void retry() => ref.invalidateSelf();
}
