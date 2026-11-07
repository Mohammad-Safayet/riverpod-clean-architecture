import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:riverpod_clean_architecture/features/auth/auth_providers.dart';
import 'package:riverpod_clean_architecture/features/auth/domain/entities/user.dart';
import 'package:riverpod_clean_architecture/features/auth/domain/usecases/login_usecase.dart';
import 'package:riverpod_clean_architecture/features/auth/presentation/screens/login_screen.dart';

import '../../../helpers/test_app.dart';

class _MockLoginUseCase extends Mock implements LoginUseCase {}

void main() {
  setUpAll(setUpTestConfig);

  late _MockLoginUseCase useCase;

  setUp(() {
    useCase = _MockLoginUseCase();
    when(
      () => useCase(
        username: any(named: 'username'),
        password: any(named: 'password'),
      ),
    ).thenAnswer((_) async => const User(id: 1, username: 'u', email: 'e', fullName: 'U'));
  });

  Future<void> pump(WidgetTester tester) => pumpTestApp(
    tester,
    const LoginScreen(),
    overrides: [loginUseCaseProvider.overrideWithValue(useCase)],
  );

  testWidgets('shows validation errors and does not submit empty fields', (tester) async {
    await pump(tester);
    await tester.enterText(find.byType(TextFormField).at(0), '');
    await tester.enterText(find.byType(TextFormField).at(1), '');
    await tester.tap(find.byType(ElevatedButton));
    await tester.pump();

    expect(find.text('Required'), findsNWidgets(2));
    verifyNever(
      () => useCase(
        username: any(named: 'username'),
        password: any(named: 'password'),
      ),
    );
  });

  testWidgets('submits the entered credentials', (tester) async {
    await pump(tester);
    await tester.enterText(find.byType(TextFormField).at(0), 'emilys');
    await tester.enterText(find.byType(TextFormField).at(1), 'secret');
    await tester.tap(find.byType(ElevatedButton));
    await tester.pumpAndSettle();

    verify(() => useCase(username: 'emilys', password: 'secret')).called(1);
  });
}
