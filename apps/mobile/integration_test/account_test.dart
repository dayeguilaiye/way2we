import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:way2we/main.dart' as app;
import 'package:way2we/features/account/presentation/profile_pages.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('local email login, profile persistence and account recovery', (
    tester,
  ) async {
    // Keep deterministic test input separate from native IME updates.
    tester.testTextInput.register();
    addTearDown(tester.testTextInput.unregister);
    const storage = FlutterSecureStorage();
    await storage.delete(key: 'way2we.session.v1');
    final stamp = DateTime.now().microsecondsSinceEpoch;
    final email = 'mobile-$stamp@example.test';
    late DateTime sentAt;
    final inbox = Dio(
      BaseOptions(
        baseUrl: const String.fromEnvironment(
          'MAILPIT_URL',
          defaultValue: 'http://127.0.0.1:8025',
        ),
        connectTimeout: const Duration(seconds: 5),
        receiveTimeout: const Duration(seconds: 5),
      ),
    );
    addTearDown(() => inbox.close(force: true));
    Future<void> capture(String name) async {
      await tester.pumpAndSettle();
      // The host runner captures the actual Simulator/emulator screen at this marker.
      debugPrint('T01_CAPTURE:$name');
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(seconds: 3)),
      );
    }

    Future<String> receive() async {
      for (var n = 0; n < 40; n++) {
        final response = await inbox.get<Map<String, dynamic>>(
          '/api/v1/messages',
        );
        for (final value in response.data!['messages'] as List) {
          final message = value as Map<String, dynamic>;
          if ((message['To'] as List).any((to) => to['Address'] == email)) {
            final detail = await inbox.get<Map<String, dynamic>>(
              '/api/v1/message/${message['ID']}',
            );
            return RegExp(r'\b\d{6}\b')
                .firstMatch(detail.data!['Text'] as String)!
                .group(0)!;
          }
        }
        await Future<void>.delayed(const Duration(milliseconds: 300));
      }
      throw StateError('Local code mail not received');
    }

    Future<void> waitFor(Finder finder) async {
      for (var i = 0; i < 100; i++) {
        await tester.pump(const Duration(milliseconds: 100));
        if (finder.evaluate().isNotEmpty) {
          await tester.pumpAndSettle();
          return;
        }
      }
      expect(finder, findsWidgets);
    }

    Future<void> send() async {
      await tester.enterText(find.byKey(const Key('email')), email);
      await tester.pump();
      await tester.ensureVisible(find.text('获取验证码'));
      await tester.tap(find.text('获取验证码'));
      await waitFor(find.text('查看你的邮箱'));
      sentAt = DateTime.now();
    }

    Future<void> signIn(String code) async {
      await tester.enterText(find.byKey(const Key('code')), '');
      await tester.pump();
      await tester.enterText(find.byKey(const Key('code')), code);
      await tester.pump();
      expect(
        tester
                .widget<TextFormField>(find.byKey(const Key('code')))
                .controller!
                .text ==
            code,
        isTrue,
        reason: 'Code field must use the newly entered value',
      );
      await tester.ensureVisible(find.widgetWithText(FilledButton, '登录'));
      await tester.tap(find.widgetWithText(FilledButton, '登录'));
      await tester.pumpAndSettle();
    }

    app.main();
    await tester.pumpAndSettle();
    await capture('login');
    await send();
    final code = (await tester.runAsync(receive))!;
    await signIn(code == '000000' ? '111111' : '000000');
    expect(find.textContaining('验证码无效'), findsOneWidget);
    await capture('code-error');
    await signIn(code);
    await waitFor(find.text('我的'));
    await tester.tap(find.text('我的'));
    await tester.pumpAndSettle();
    await waitFor(find.text('新朋友'));
    expect(find.text('新朋友'), findsOneWidget);
    final firstSession = await storage.read(key: 'way2we.session.v1');
    expect(firstSession, isNotNull);
    await tester.tap(find.text('账号信息'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('display_name')), '阿禾');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.ensureVisible(find.text('保存昵称'));
    await tester.tap(find.text('保存昵称'));
    await tester.pumpAndSettle();
    await waitFor(find.text('阿禾'));
    expect(find.text('阿禾'), findsOneWidget);
    await capture('profile');
    await tester.tap(find.text('外观'));
    await tester.pumpAndSettle();
    for (final theme in ['apricot', 'celadon', 'rose']) {
      await tester.ensureVisible(find.byKey(Key('theme_$theme')));
      await tester.tap(find.byKey(Key('theme_$theme')));
      await tester.pumpAndSettle();
      await waitFor(
        find.byWidgetPredicate(
          (widget) =>
              widget is ThemeOption &&
              widget.theme.name == theme &&
              widget.selected &&
              widget.enabled,
        ),
      );
      await capture('appearance-$theme');
    }
    tester.platformDispatcher.textScaleFactorTestValue = 1.6;
    await tester.pumpAndSettle();
    await capture('appearance-large');
    tester.platformDispatcher.clearTextScaleFactorTestValue();
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    // A fresh app/container restores secure storage and fetches the saved account.
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    app.main();
    await tester.pumpAndSettle();
    await waitFor(find.text('我的'));
    await tester.tap(find.text('我的'));
    await tester.pumpAndSettle();
    await waitFor(find.text('阿禾'));
    expect(find.text('阿禾'), findsOneWidget);
    expect(find.text('雾玫'), findsOneWidget);
    await tester.tap(find.text('退出登录'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, '退出登录').last);
    await tester.pumpAndSettle();
    expect(find.text('用邮箱开始'), findsOneWidget);
    expect(await storage.read(key: 'way2we.session.v1'), isNull);
    // Honor the actual service resend interval; there is no verification bypass.
    final remaining =
        const Duration(seconds: 62) - DateTime.now().difference(sentAt);
    if (remaining > Duration.zero) {
      await tester.runAsync(() => Future<void>.delayed(remaining));
    }
    // Remove only this test address's previous email to wait for the newest one.
    final messages = await inbox.get<Map<String, dynamic>>('/api/v1/messages');
    for (final value in messages.data!['messages'] as List) {
      if ((value['To'] as List).any((to) => to['Address'] == email)) {
        await inbox.delete<void>(
          '/api/v1/messages',
          data: {
            'IDs': [value['ID']],
          },
        );
      }
    }
    await send();
    final fresh = (await tester.runAsync(receive))!;
    await signIn(fresh);
    await waitFor(find.text('我的'));
    await tester.tap(find.text('我的'));
    await tester.pumpAndSettle();
    await waitFor(find.text('阿禾'));
    await waitFor(find.text('阿禾'));
    expect(find.text('阿禾'), findsOneWidget);
    expect(find.text('雾玫'), findsOneWidget);
    await capture('recovered');
    expect(tester.takeException(), isNull);
  });
}
