import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:riverpod_clean_architecture/core/exceptions/app_exception.dart';
import 'package:riverpod_clean_architecture/core/utils/provider_retry.dart';
{{#lite}}
import 'package:riverpod_clean_architecture/features/{{name.snakeCase()}}/data/models/{{model.snakeCase()}}_model.dart';
import 'package:riverpod_clean_architecture/features/{{name.snakeCase()}}/data/repositories/{{model.snakeCase()}}_repository.dart';
{{/lite}}
{{^lite}}
import 'package:riverpod_clean_architecture/features/{{name.snakeCase()}}/{{name.snakeCase()}}_providers.dart';
import 'package:riverpod_clean_architecture/features/{{name.snakeCase()}}/domain/entities/{{model.snakeCase()}}.dart';
import 'package:riverpod_clean_architecture/features/{{name.snakeCase()}}/domain/usecases/get_{{model.snakeCase()}}_list_usecase.dart';
{{/lite}}
import 'package:riverpod_clean_architecture/features/{{name.snakeCase()}}/presentation/notifiers/{{name.snakeCase()}}_notifier.dart';

import '../../../helpers/test_app.dart';

{{#lite}}
class _MockRepository extends Mock implements {{model.pascalCase()}}Repository {}
{{/lite}}
{{^lite}}
class _MockUseCase extends Mock implements Get{{model.pascalCase()}}ListUseCase {}
{{/lite}}

void main() {
  setUpAll(setUpTestConfig);

{{#lite}}
  late _MockRepository repository;
  late ProviderContainer container;

  setUp(() {
    repository = _MockRepository();
    container = ProviderContainer(
      retry: noProviderRetry,
      overrides: [{{model.camelCase()}}RepositoryProvider.overrideWithValue(repository)],
    );
  });
  tearDown(() => container.dispose());

  test('loads the list', () async {
    when(() => repository.get{{model.pascalCase()}}List())
        .thenAnswer((_) async => [const {{model.pascalCase()}}Model(id: 1, name: 'One')]);

    final items = await container.read({{name.camelCase()}}Provider.future);

    expect(items.single.name, 'One');
  });

  test('exposes the error', () async {
    when(() => repository.get{{model.pascalCase()}}List())
        .thenAnswer((_) async => throw const NetworkException());
{{/lite}}
{{^lite}}
  late _MockUseCase useCase;
  late ProviderContainer container;

  setUp(() {
    useCase = _MockUseCase();
    container = ProviderContainer(
      retry: noProviderRetry,
      overrides: [get{{model.pascalCase()}}ListUseCaseProvider.overrideWithValue(useCase)],
    );
  });
  tearDown(() => container.dispose());

  test('loads the list', () async {
    when(() => useCase()).thenAnswer((_) async => [const {{model.pascalCase()}}(id: 1, name: 'One')]);

    final items = await container.read({{name.camelCase()}}Provider.future);

    expect(items.single.name, 'One');
  });

  test('exposes the error', () async {
    when(() => useCase()).thenAnswer((_) async => throw const NetworkException());
{{/lite}}

    await expectLater(container.read({{name.camelCase()}}Provider.future), throwsA(isA<NetworkException>()));
  });
}
