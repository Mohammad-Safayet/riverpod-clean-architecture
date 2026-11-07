import 'package:riverpod_clean_architecture/features/{{name.snakeCase()}}/domain/entities/{{model.snakeCase()}}.dart';
import 'package:riverpod_clean_architecture/features/{{name.snakeCase()}}/domain/repositories/{{model.snakeCase()}}_repository.dart';

class Get{{model.pascalCase()}}ListUseCase {
  const Get{{model.pascalCase()}}ListUseCase(this._repository);

  final {{model.pascalCase()}}Repository _repository;

  Future<List<{{model.pascalCase()}}>> call() => _repository.get{{model.pascalCase()}}List();
}
