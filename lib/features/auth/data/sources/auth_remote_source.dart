import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:riverpod_clean_architecture/core/base/base_remote_source.dart';
import 'package:riverpod_clean_architecture/core/network/api_endpoints.dart';
import 'package:riverpod_clean_architecture/core/network/dio_provider.dart';
import 'package:riverpod_clean_architecture/core/network/interceptors/auth_interceptor.dart';
import 'package:riverpod_clean_architecture/features/auth/data/models/login_request_model.dart';
import 'package:riverpod_clean_architecture/features/auth/data/models/login_response_model.dart';

part 'gen/auth_remote_source.g.dart';

class AuthRemoteSource extends BaseRemoteSource {
  AuthRemoteSource(super.dio);

  Future<LoginResponseModel> login(LoginRequestModel request) => callApi(
    dio.post<dynamic>(
      ApiEndpoints.login,
      data: request.toJson(),
      options: Options(extra: AuthInterceptor.skipAuth),
    ),
    (data) => LoginResponseModel.fromJson(data as Map<String, dynamic>),
  );
}

@riverpod
AuthRemoteSource authRemoteSource(Ref ref) => AuthRemoteSource(ref.watch(dioClientProvider));
