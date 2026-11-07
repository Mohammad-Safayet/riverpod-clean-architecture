import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:riverpod_clean_architecture/core/storage/preference_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'gen/storage_providers.g.dart';

/// Loaded in `bootstrap()` and injected with `overrideWithValue`, so reads are synchronous.
@Riverpod(keepAlive: true)
SharedPreferences sharedPreferences(Ref ref) =>
    throw UnimplementedError('sharedPreferencesProvider must be overridden in bootstrap()');

@Riverpod(keepAlive: true)
PreferenceManager preferenceManager(Ref ref) =>
    PreferenceManager(ref.watch(sharedPreferencesProvider));

@Riverpod(keepAlive: true)
FlutterSecureStorage secureStorage(Ref ref) => const FlutterSecureStorage();
