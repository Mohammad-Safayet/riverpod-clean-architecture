import 'package:freezed_annotation/freezed_annotation.dart';
{{^lite}}
import 'package:riverpod_clean_architecture/features/{{name.snakeCase()}}/domain/entities/{{model.snakeCase()}}.dart';
{{/lite}}

part 'gen/{{model.snakeCase()}}_model.freezed.dart';
part 'gen/{{model.snakeCase()}}_model.g.dart';

/// Exact shape of the API response. TODO: match your backend's JSON.
@freezed
abstract class {{model.pascalCase()}}Model with _${{model.pascalCase()}}Model {
  const factory {{model.pascalCase()}}Model({
    required int id,
    required String name,
  }) = _{{model.pascalCase()}}Model;

  factory {{model.pascalCase()}}Model.fromJson(Map<String, dynamic> json) =>
      _${{model.pascalCase()}}ModelFromJson(json);
}
{{^lite}}

extension {{model.pascalCase()}}ModelX on {{model.pascalCase()}}Model {
  {{model.pascalCase()}} toEntity() => {{model.pascalCase()}}(id: id, name: name);
}
{{/lite}}
