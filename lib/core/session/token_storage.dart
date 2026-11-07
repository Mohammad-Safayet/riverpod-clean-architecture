import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:riverpod_clean_architecture/core/storage/storage_providers.dart';

part 'gen/token_storage.g.dart';

typedef AuthTokens = ({String accessToken, String refreshToken});

/// Access/refresh tokens in the platform keychain/keystore.
class TokenStorage {
  TokenStorage(this._storage);

  final FlutterSecureStorage _storage;

  static const _keyAccess = 'access_token';
  static const _keyRefresh = 'refresh_token';

  // Cached so every request doesn't hit the keychain.
  AuthTokens? _cache;
  bool _loaded = false;

  Future<AuthTokens?> read() async {
    if (_loaded) return _cache;
    final access = await _storage.read(key: _keyAccess);
    final refresh = await _storage.read(key: _keyRefresh);
    _cache = access != null && refresh != null
        ? (accessToken: access, refreshToken: refresh)
        : null;
    _loaded = true;
    return _cache;
  }

  Future<void> save(AuthTokens tokens) async {
    _cache = tokens;
    _loaded = true;
    await _storage.write(key: _keyAccess, value: tokens.accessToken);
    await _storage.write(key: _keyRefresh, value: tokens.refreshToken);
  }

  Future<void> clear() async {
    _cache = null;
    _loaded = true;
    await _storage.delete(key: _keyAccess);
    await _storage.delete(key: _keyRefresh);
  }
}

@Riverpod(keepAlive: true)
TokenStorage tokenStorage(Ref ref) => TokenStorage(ref.watch(secureStorageProvider));
