import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:way2we_app/features/group/bloc/create_group_bloc.dart';
import 'package:way2we_app/features/group/bloc/group_control_bloc.dart';
import 'package:way2we_app/features/group/bloc/join_group_bloc.dart';
import 'package:way2we_app/features/group/view/create_group_page.dart';
import 'package:way2we_app/features/group/view/join_group_page.dart';
import 'package:way2we_app/features/home/view/main_shell_page.dart';
import 'package:way2we_app/l10n/l10n.dart';
import 'package:way2we_app/theme/app_theme.dart';

class _MockCreateGroupBloc extends MockBloc<CreateGroupEvent, CreateGroupState>
    implements CreateGroupBloc {}

class _MockJoinGroupBloc extends MockBloc<JoinGroupEvent, JoinGroupState>
    implements JoinGroupBloc {}

class _MockGroupControlBloc
    extends MockBloc<GroupControlEvent, GroupControlState>
    implements GroupControlBloc {}

Future<void> _pumpWithProviders(
  WidgetTester tester, {
  required List<BlocProvider<dynamic>> providers,
  required Widget child,
}) async {
  await tester.pumpWidget(
    MultiBlocProvider(
      providers: providers,
      child: MaterialApp(
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: ThemeMode.light,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: child,
      ),
    ),
  );
}

void main() {
  group('Group flow navigation', () {
    testWidgets(
      'CreateGroupView refreshes groups and navigates to main shell on success',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(430, 932));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        final createBloc = _MockCreateGroupBloc();
        final groupControlBloc = _MockGroupControlBloc();

        const initialState = CreateGroupState(name: 'Family');
        const successState = CreateGroupState(
          name: 'Family',
          status: CreateGroupStatus.success,
          groupId: 1,
        );

        when(() => createBloc.state).thenReturn(initialState);
        whenListen(
          createBloc,
          Stream<CreateGroupState>.value(successState),
          initialState: initialState,
        );

        when(
          () => groupControlBloc.state,
        ).thenReturn(const GroupControlLoadFailure('load failed'));
        whenListen(
          groupControlBloc,
          const Stream<GroupControlState>.empty(),
          initialState: const GroupControlLoadFailure('load failed'),
        );

        await _pumpWithProviders(
          tester,
          providers: [
            BlocProvider<CreateGroupBloc>.value(value: createBloc),
            BlocProvider<GroupControlBloc>.value(value: groupControlBloc),
          ],
          child: const CreateGroupView(),
        );
        await tester.pumpAndSettle();

        verify(
          () => groupControlBloc.add(const GroupControlGroupsLoaded()),
        ).called(1);
        expect(find.byType(MainShellPage), findsOneWidget);
      },
    );

    testWidgets(
      'JoinGroupView refreshes groups and navigates to main shell on success',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(430, 932));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        final joinBloc = _MockJoinGroupBloc();
        final groupControlBloc = _MockGroupControlBloc();

        const initialState = JoinGroupState(
          status: JoinGroupStatus.previewLoaded,
          invitationCode: 'ABC123',
          groupId: 1,
          groupName: 'Family',
          memberCount: 2,
        );
        const successState = JoinGroupState(
          status: JoinGroupStatus.success,
          invitationCode: 'ABC123',
          groupId: 1,
          groupName: 'Family',
          memberCount: 2,
        );

        when(() => joinBloc.state).thenReturn(initialState);
        whenListen(
          joinBloc,
          Stream<JoinGroupState>.value(successState),
          initialState: initialState,
        );

        when(
          () => groupControlBloc.state,
        ).thenReturn(const GroupControlLoadFailure('load failed'));
        whenListen(
          groupControlBloc,
          const Stream<GroupControlState>.empty(),
          initialState: const GroupControlLoadFailure('load failed'),
        );

        await _pumpWithProviders(
          tester,
          providers: [
            BlocProvider<JoinGroupBloc>.value(value: joinBloc),
            BlocProvider<GroupControlBloc>.value(value: groupControlBloc),
          ],
          child: const JoinGroupView(),
        );
        await tester.pumpAndSettle();

        verify(
          () => groupControlBloc.add(const GroupControlGroupsLoaded()),
        ).called(1);
        expect(find.byType(MainShellPage), findsOneWidget);
      },
    );
  });
}
