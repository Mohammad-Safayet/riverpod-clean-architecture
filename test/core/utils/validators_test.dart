import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod_clean_architecture/core/utils/validators.dart';
import 'package:riverpod_clean_architecture/l10n/generated/app_localizations.dart';

void main() {
  final v = Validators(lookupAppLocalizations(const Locale('en')));

  test('required rejects null, empty and whitespace', () {
    final rule = v.required();
    expect(rule(null), 'Required');
    expect(rule('   '), 'Required');
    expect(rule('x'), isNull);
  });

  test('email', () {
    final rule = v.email();
    expect(rule('a@b.co'), isNull);
    expect(rule(' a@b.co '), isNull);
    expect(rule('a@b'), 'Enter a valid email address');
    expect(rule('a b@c.d'), isNotNull);
  });

  test('phone accepts BD mobile formats with spaces or dashes', () {
    final rule = v.phone();
    expect(rule('01712345678'), isNull);
    expect(rule('+8801712345678'), isNull);
    expect(rule('017-1234-5678'), isNull);
    expect(rule('01212345678'), 'Enter a valid phone number');
    expect(rule('0171234567'), isNotNull);
  });

  test('length rules include the number in the message', () {
    expect(v.minLength(8)('short'), 'Must be at least 8 characters');
    expect(v.minLength(3)('long enough'), isNull);
    expect(v.maxLength(3)('long'), 'Must be at most 3 characters');
  });

  test('match compares against the other field at validation time', () {
    var password = 'a';
    final rule = v.match(() => password);
    expect(rule('b'), "Doesn't match");
    password = 'b';
    expect(rule('b'), isNull);
  });

  test('optional fields: every rule but required passes on empty', () {
    for (final rule in [v.email(), v.phone(), v.minLength(5), v.match(() => 'x')]) {
      expect(rule(''), isNull);
    }
  });

  test('all returns the first failure', () {
    final rule = v.all([v.required(), v.email()]);
    expect(rule(''), 'Required');
    expect(rule('nope'), 'Enter a valid email address');
    expect(rule('a@b.co'), isNull);
  });

  test('messages are localized', () {
    final bn = Validators(lookupAppLocalizations(const Locale('bn')));
    expect(bn.required()(''), 'আবশ্যক');
  });
}
