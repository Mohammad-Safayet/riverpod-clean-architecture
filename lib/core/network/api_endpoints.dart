/// Paths relative to [EnvConfig.baseUrl]. Keep every endpoint here so they're easy to audit.
abstract final class ApiEndpoints {
  static const login = '/auth/login';
  static const refreshToken = '/auth/refresh';

  // Under /auth/ so DummyJSON requires the Bearer token, which exercises the
  // auth + refresh interceptor in the demo.
  static const products = '/auth/products';
  static String product(int id) => '/auth/products/$id';
}
