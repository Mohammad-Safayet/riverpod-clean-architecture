import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:riverpod_clean_architecture/core/base/base_remote_source.dart';
import 'package:riverpod_clean_architecture/core/network/api_endpoints.dart';
import 'package:riverpod_clean_architecture/core/network/dio_provider.dart';
import 'package:riverpod_clean_architecture/features/{{name.snakeCase()}}/data/models/{{model.snakeCase()}}_model.dart';

part 'gen/{{model.snakeCase()}}_remote_source.g.dart';

class {{model.pascalCase()}}RemoteSource extends BaseRemoteSource {
  {{model.pascalCase()}}RemoteSource(super.dio);

  // TODO: adjust to the real endpoint and response envelope.
  Future<List<{{model.pascalCase()}}Model>> get{{model.pascalCase()}}List() => callApi(
    dio.get<dynamic>(ApiEndpoints.{{name.camelCase()}}),
    (data) => (data as List)
        .map((e) => {{model.pascalCase()}}Model.fromJson(e as Map<String, dynamic>))
        .toList(),
  );
}

@riverpod
{{model.pascalCase()}}RemoteSource {{model.camelCase()}}RemoteSource(Ref ref) =>
    {{model.pascalCase()}}RemoteSource(ref.watch(dioClientProvider));
