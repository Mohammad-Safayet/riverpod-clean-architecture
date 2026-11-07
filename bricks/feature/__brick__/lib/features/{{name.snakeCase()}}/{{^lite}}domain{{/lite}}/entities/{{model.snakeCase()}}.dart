import 'package:freezed_annotation/freezed_annotation.dart';

part 'gen/{{model.snakeCase()}}.freezed.dart';

/// What the app means by "{{model.lowerCase()}}", independent of the API shape.
@freezed
abstract class {{model.pascalCase()}} with _${{model.pascalCase()}} {
  const factory {{model.pascalCase()}}({
    required int id,
    required String name,
  }) = _{{model.pascalCase()}};
}
