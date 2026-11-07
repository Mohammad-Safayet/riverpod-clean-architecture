import 'package:riverpod_clean_architecture/features/{{name.snakeCase()}}/domain/entities/{{model.snakeCase()}}.dart';

abstract interface class {{model.pascalCase()}}Repository {
  /// Throws `AppException` on failure.
  Future<List<{{model.pascalCase()}}>> get{{model.pascalCase()}}List();
}
