import 'package:flutter/widgets.dart';
import 'package:riverpod_clean_architecture/core/extensions/context_extensions.dart';
import 'package:riverpod_clean_architecture/l10n/generated/app_localizations.dart';

typedef Validator = String? Function(String? value);

/// Localized `TextFormField` validators. Combine with [all]:
///
/// ```dart
/// final v = context.validators;
/// TextFormField(validator: v.all([v.required(), v.email()]));
/// TextFormField(validator: v.all([v.required(), v.minLength(8)]));
/// TextFormField(validator: v.match(() => _password.text));
/// ```
///
/// Each rule except [required] passes on empty input, so optional fields work by
/// leaving [required] out. Messages come from the `validation*` ARB keys.
class Validators {
  const Validators(this._l10n);

  final AppLocalizations _l10n;

  static final _email = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  /// Bangladesh mobile: 01XXXXXXXXX, optionally +880 / 880 prefixed. Adjust per market.
  static final _phone = RegExp(r'^(?:\+?880|0)1[3-9]\d{8}$');

  static bool _empty(String? v) => v == null || v.trim().isEmpty;

  /// First failing rule's message, or null when all pass.
  Validator all(List<Validator> rules) => (value) {
    for (final rule in rules) {
      final error = rule(value);
      if (error != null) return error;
    }
    return null;
  };

  Validator required() =>
      (v) => _empty(v) ? _l10n.validationRequired : null;

  Validator email() =>
      (v) => _empty(v) || _email.hasMatch(v!.trim()) ? null : _l10n.validationEmail;

  Validator phone() => (v) {
    if (_empty(v)) return null;
    final digits = v!.replaceAll(RegExp(r'[\s-]'), '');
    return _phone.hasMatch(digits) ? null : _l10n.validationPhone;
  };

  Validator minLength(int min) =>
      (v) => _empty(v) || v!.trim().length >= min ? null : _l10n.validationMinLength(min);

  Validator maxLength(int max) =>
      (v) => _empty(v) || v!.trim().length <= max ? null : _l10n.validationMaxLength(max);

  /// Equal to another field's current value (confirm password, confirm email).
  Validator match(String Function() other) =>
      (v) => _empty(v) || v == other() ? null : _l10n.validationMismatch;
}

extension ValidatorsX on BuildContext {
  Validators get validators => Validators(l10n);
}
