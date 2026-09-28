import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:way2we/main.dart' as app;
import 'package:way2we/app/app.dart';
import 'package:way2we/app/providers.dart';
import 'package:way2we/app/theme.dart';
import 'package:way2we/features/account/application/account_controller.dart';
import 'package:way2we/features/account/data/account_repository.dart';
import 'package:way2we/features/spaces/application/space_controller.dart';
import 'package:way2we/features/spaces/presentation/spaces_page.dart';
import 'package:way2we/features/spaces/presentation/members_page.dart';
import 'package:way2we/features/spaces/presentation/invitation_pages.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'two accounts join, third waits for consent, inbox opens progress',
    (tester) async {
      tester.testTextInput.register();
      addTearDown(tester.testTextInput.unregister);
      const storage = FlutterSecureStorage();
      await storage.delete(key: 'way2we.session.v1');
      final stamp = DateTime.now().microsecondsSinceEpoch;
      final a = 't02-a-$stamp@example.test',
          b = 't02-b-$stamp@example.test',
          c = 't02-c-$stamp@example.test';
      final api = Dio(
        BaseOptions(
          baseUrl: const String.fromEnvironment(
            'API_BASE_URL',
            defaultValue: 'http://127.0.0.1:8080',
          ),
        ),
      );
      final inbox = Dio(
        BaseOptions(
          baseUrl: const String.fromEnvironment(
            'MAILPIT_URL',
            defaultValue: 'http://127.0.0.1:8025',
          ),
        ),
      );
      addTearDown(api.close);
      addTearDown(inbox.close);
      Future<void> waitFor(Finder f) async {
        for (var i = 0; i < 150; i++) {
          await tester.pump(const Duration(milliseconds: 100));
          if (f.evaluate().isNotEmpty) {
            await tester.pumpAndSettle();
            return;
          }
        }
        expect(f, findsWidgets);
      }

      Future<void> tap(String text) async {
        final filled = find.widgetWithText(FilledButton, text);
        final f = filled.evaluate().isNotEmpty
            ? filled.last
            : find.text(text).last;
        await tester.ensureVisible(f);
        await tester.tap(f);
        await tester.pumpAndSettle();
      }

      Future<void> capture(String name) async {
        await tester.pumpAndSettle();
        debugPrint('T02_CAPTURE:$name');
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(seconds: 2)),
        );
      }

      Future<String> receive(String email) async {
        for (var i = 0; i < 50; i++) {
          final r = await inbox.get<Map<String, dynamic>>('/api/v1/messages');
          for (final v in r.data!['messages'] as List) {
            if ((v['To'] as List).any((to) => to['Address'] == email)) {
              final detail = await inbox.get<Map<String, dynamic>>(
                '/api/v1/message/${v['ID']}',
              );
              return RegExp(r'\b\d{6}\b')
                  .firstMatch(detail.data!['Text'] as String)!
                  .group(0)!;
            }
          }
          await Future<void>.delayed(const Duration(milliseconds: 250));
        }
        throw StateError('no mail');
      }

      Future<void> login(String email) async {
        await waitFor(find.byKey(const Key('email')));
        await tester.enterText(find.byKey(const Key('email')), email);
        await tap('获取验证码');
        await waitFor(find.byKey(const Key('code')));
        final code = (await tester.runAsync(() => receive(email)))!;
        await tester.enterText(find.byKey(const Key('code')), code);
        await tap('登录');
        await waitFor(find.byType(SpacesPage));
      }

      ProviderContainer container() => ProviderScope.containerOf(
        tester.element(find.byType(Way2WeApp)),
        listen: false,
      );
      Future<void> go(String path) async {
        container().read(routerProvider).go(path);
        await tester.pumpAndSettle();
      }

      Future<void> idle() async {
        for (var i = 0; i < 100; i++) {
          await tester.pump(const Duration(milliseconds: 100));
          final s = container().read(operationProvider);
          if (s.ready && !s.busy) {
            expect(s.failure, isNull);
            return;
          }
        }
        fail('command never settled');
      }

      app.main();
      await tester.pumpAndSettle();
      await login(a);
      final aSession = await storage.read(key: 'way2we.session.v1');
      await capture('spaces-empty');
      await tap('创建空间');
      await tester.enterText(find.byType(TextFormField).at(0), '一起的小日子');
      await tester.enterText(find.byType(TextFormField).at(1), '阿禾');
      await capture('create-space');
      await tap('创建空间');
      await waitFor(find.byType(MembersPage));
      await waitFor(find.text('阿禾（我）'));
      final sid = (tester.widget<MembersPage>(find.byType(MembersPage))).id;
      await capture('members-apricot');
      await tap('邀请伙伴');
      await idle();
      final code =
          container().read(operationProvider).result!['invite_code'] as String;
      await waitFor(find.text('复制邀请码'));
      await capture('invite-share');
      // Simulate a second device: keep A's server session, clear local credentials,
      // then sign in as B through real email verification. T01 tests revocation.
      await container().read(sessionProvider).set(null);
      await tester.pumpAndSettle();
      await login(b);
      await tap('使用邀请加入');
      await tester.enterText(
        find.byType(TextFormField).first,
        'ABCDEFGHIJKLMNOPQRST',
      );
      await tap('查看邀请');
      await waitFor(find.text('内容暂时不可用。'));
      await capture('invite-unavailable');
      await tester.enterText(
        find.byType(TextFormField).first,
        'way2we://app/join?code=$code',
      );
      await tap('查看邀请');
      await waitFor(find.text('接受邀请'));
      await tester.enterText(find.byType(TextFormField).at(1), '小满');
      await capture('invite-preview');
      await tap('接受邀请');
      await waitFor(find.text('已加入'));
      await capture('joined');
      await tap('进入空间');
      await waitFor(find.text('小满（我）'));
      await waitFor(find.text('阿禾'));
      // Third real email account accepts B's invitation over HTTP; A still has to approve.
      await tap('邀请伙伴');
      await idle();
      final thirdCode =
          container().read(operationProvider).result!['invite_code'] as String;
      final third = await tester.runAsync(() async {
        await api.post<Object?>('/v1/auth/email-codes', data: {'email': c});
        final otp = await receive(c);
        final auth = await api.post<Map<String, dynamic>>(
          '/v1/auth/sessions',
          data: {'email': c, 'code': otp},
        );
        final res = await api.post<Map<String, dynamic>>(
          '/v1/invitations/accept',
          data: {'invite_code': thirdCode, 'nickname': '小林'},
          options: Options(
            headers: {
              'Authorization': 'Bearer ${auth.data!['access_token']}',
              'Idempotency-Key': operationKey(),
            },
          ),
        );
        return res.data!;
      });
      expect(third!['status'], 'waiting');
      final iid = third['id'] as String;
      container().read(operationProvider.notifier).dismissResult();
      await go('/invitations/$iid');
      await waitFor(find.text('等待全员同意'));
      await capture('waiting');
      // Theme choices persist through the actual profile endpoint, then re-fetch current account.
      for (final theme in ['celadon', 'rose']) {
        final token = container().read(sessionProvider).current!.token;
        await tester.runAsync(
          () => api.patch<Object?>(
            '/v1/me',
            data: {'theme': theme},
            options: Options(
              headers: {
                'Authorization': 'Bearer $token',
                'Idempotency-Key': operationKey(),
              },
            ),
          ),
        );
        await container().read(accountProvider.notifier).load();
        expect(container().read(themeProvider).name, theme);
        await go('/spaces/$sid');
        await waitFor(find.text('小满（我）'));
        await capture('members-$theme');
      }
      tester.platformDispatcher.textScaleFactorTestValue = 1.6;
      await tester.pumpAndSettle();
      await capture('members-large');
      tester.platformDispatcher.clearTextScaleFactorTestValue();
      // Restore A's genuine saved session, as a second device would; no backend bypass.
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
      await storage.write(key: 'way2we.session.v1', value: aSession);
      app.main();
      await tester.pumpAndSettle();
      await waitFor(find.byType(SpacesPage));
      await go('/invitations/$iid');
      await waitFor(find.text('同意加入'));
      await capture('approval');
      await tap('同意加入');
      await idle();
      await waitFor(find.text('已加入'));
      expect(find.text('2 / 2 位成员已同意'), findsOneWidget);
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(seconds: 2)),
      );
      await go('/notifications');
      await waitFor(find.textContaining('新的伙伴已加入空间'));
      await capture('notifications');
      await tester.tap(find.textContaining('新的伙伴已加入空间').first);
      await tester.pumpAndSettle();
      await waitFor(find.byType(InvitationPage));
      await go('/spaces/$sid');
      await waitFor(find.text('小林'));
      await capture('members-three');
      debugPrint('T02_APPEARANCE:dark');
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(seconds: 2)),
      );
      await capture('members-dark');
      debugPrint('T02_APPEARANCE:light');
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(seconds: 1)),
      );
      final saved = jsonDecode(aSession!) as Map;
      expect(
        container().read(sessionProvider).current!.userId,
        saved['user_id'],
      );
      expect(tester.takeException(), isNull);
    },
  );
}
