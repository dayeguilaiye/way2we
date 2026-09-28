import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:way2we/app/app.dart';
import 'package:way2we/app/providers.dart';
import 'package:way2we/core/session/session.dart';

import 'api_client_test.dart' show MemoryStore;

void main() {
  testWidgets(
    'all T02 destinations resolve and invitation resumes after login',
    (tester) async {
      final sessions = SessionController(MemoryStore());
      addTearDown(sessions.dispose);
      final c = ProviderContainer(
        overrides: [sessionProvider.overrideWithValue(sessions)],
      );
      addTearDown(c.dispose);
      final router = c.read(routerProvider);
      // Route parsing is tested without constructing business pages or making HTTP calls.
      final parser = router.routeInformationParser;
      final provider = router.routeInformationProvider;
      await tester.pumpWidget(const MaterialApp(home: SizedBox()));
      final context = tester.element(find.byType(SizedBox).last);
      Future<String> resolve(String path) async {
        provider.go(path);
        final matches = await parser.parseRouteInformationWithDependencies(
          provider.value,
          context,
        );
        expect(matches.isError, isFalse, reason: path);
        return matches.uri.toString();
      }

      const link = '/join?code=ABCDEFGHIJKLMNOPQRST';
      expect(await resolve(link), '/login');
      await sessions.set(const Session(userId: 'a', token: 'a'));
      expect(await resolve('/login'), link);
      for (final path in [
        '/me',
        '/me/appearance',
        '/spaces',
        '/spaces/new',
        '/spaces/space-a',
        '/spaces/space-a/invitations',
        '/spaces/space-a/nickname',
        '/notifications',
        '/invitations/invite-a',
      ]) {
        expect(await resolve(path), path);
      }
    },
  );
}
