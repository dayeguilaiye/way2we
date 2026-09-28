import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:way2we/app/providers.dart';
import 'package:way2we/app/theme.dart';
import 'package:way2we/core/network/api_client.dart';
import 'package:way2we/core/network/failure.dart';
import 'package:way2we/core/session/session.dart';
import 'package:way2we/features/account/application/account_controller.dart';
import 'package:way2we/features/account/data/account_repository.dart';
import 'package:way2we/features/account/presentation/login_page.dart';

import 'api_client_test.dart' show MemoryStore;

class LoginRepository extends AccountRepository {
  LoginRepository(super.api);
  final codes = <String>[];
  @override
  Future<int> sendCode(String email) async => 60;
  @override
  Future<LoginResult> login(String email, String code) async {
    codes.add(code);
    if (codes.length == 1) {
      throw const ApiFailure(code: 'CODE_INVALID_OR_EXPIRED', status: 401);
    }
    return const LoginResult(
      Session(userId: 'a', token: 'test-token'),
      AccountUser(id: 'a', name: '新朋友', theme: AppTheme.apricot),
    );
  }
}

void main() {
  testWidgets(
    'small screen large text, keyboard and correction after invalid code',
    (tester) async {
      tester.view.physicalSize = const Size(375, 667);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final sessions = SessionController(MemoryStore());
      addTearDown(sessions.dispose);
      final dio = createDio('https://example.test');
      addTearDown(dio.close);
      final repository = LoginRepository(ApiClient(dio, sessions));
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sessionProvider.overrideWithValue(sessions),
            accountRepositoryProvider.overrideWithValue(repository),
          ],
          child: MaterialApp(
            theme: buildTheme(AppTheme.apricot),
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: const TextScaler.linear(1.6),
                viewInsets: const EdgeInsets.only(bottom: 240),
              ),
              child: child!,
            ),
            home: const LoginPage(),
          ),
        ),
      );
      await tester.scrollUntilVisible(
        find.byKey(const Key('email')),
        150,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.enterText(
        find.byKey(const Key('email')),
        'someone@example.test',
      );
      await tester.ensureVisible(find.text('获取验证码'));
      await tester.tap(find.text('获取验证码'));
      await tester.pumpAndSettle();
      for (final code in ['000000', '123456']) {
        await tester.scrollUntilVisible(
          find.byKey(const Key('code')),
          100,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.enterText(find.byKey(const Key('code')), code);
        await tester.ensureVisible(find.widgetWithText(FilledButton, '登录'));
        await tester.tap(find.widgetWithText(FilledButton, '登录'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }
      expect(repository.codes, ['000000', '123456']);
      expect(sessions.current?.userId, 'a');
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}
