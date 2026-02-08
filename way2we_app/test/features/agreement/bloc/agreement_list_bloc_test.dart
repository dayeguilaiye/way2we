import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:way2we_app/features/agreement/bloc/list/agreement_list_bloc.dart';
import 'package:way2we_app/features/agreement/data/providers/agreement_provider.dart';
import 'package:way2we_app/features/agreement/models/agreement.dart';

class MockAgreementProvider extends Mock implements AgreementProvider {}

void main() {
  late AgreementProvider agreementProvider;
  late AgreementListBloc bloc;

  setUp(() {
    agreementProvider = MockAgreementProvider();
    bloc = AgreementListBloc(agreementProvider: agreementProvider);
  });

  Agreement buildAgreement({required bool isPinned}) {
    return Agreement(
      id: 1,
      name: 'Test Agreement',
      points: 10,
      requireConfirmation: true,
      status: AgreementStatus.active,
      groupId: 1,
      creatorId: 1,
      applicableMemberIds: const [],
      createdAt: DateTime.parse('2024-01-01T00:00:00Z'),
      updatedAt: DateTime.parse('2024-01-01T00:00:00Z'),
      isPinned: isPinned,
      description: 'Desc',
    );
  }

  group('AgreementListBloc', () {
    test('initial state is AgreementListInitial', () {
      expect(bloc.state, equals(const AgreementListInitial()));
    });

    blocTest<AgreementListBloc, AgreementListState>(
      'emits loaded and success when pinning succeeds',
      build: () {
        final agreement = buildAgreement(isPinned: false);
        when(
          () => agreementProvider.listAgreements(
            groupId: 1,
          ),
        ).thenAnswer((_) async => [agreement]);
        when(
          () => agreementProvider.pinAgreement(
            groupId: 1,
            agreementId: 1,
          ),
        ).thenAnswer((_) async {});
        return bloc;
      },
      act: (bloc) => bloc
        ..add(const LoadAgreements(groupId: 1))
        ..add(
          const TogglePinAgreement(
            agreementId: 1,
            currentPinStatus: false,
          ),
        ),
      expect: () {
        final agreement = buildAgreement(isPinned: false);
        final pinnedAgreement = agreement.copyWith(isPinned: true);
        return [
          const AgreementListLoading(),
          AgreementListLoaded(agreements: [agreement], groupId: 1),
          AgreementListLoaded(agreements: [pinnedAgreement], groupId: 1),
          AgreementListActionSuccess(
            agreements: [pinnedAgreement],
            groupId: 1,
            isPinned: true,
          ),
        ];
      },
      verify: (_) {
        verify(
          () => agreementProvider.pinAgreement(
            groupId: 1,
            agreementId: 1,
          ),
        ).called(1);
      },
    );

    blocTest<AgreementListBloc, AgreementListState>(
      'emits loaded and success when unpinning succeeds',
      build: () {
        final agreement = buildAgreement(isPinned: true);
        when(
          () => agreementProvider.listAgreements(
            groupId: 1,
          ),
        ).thenAnswer((_) async => [agreement]);
        when(
          () => agreementProvider.unpinAgreement(
            groupId: 1,
            agreementId: 1,
          ),
        ).thenAnswer((_) async {});
        return bloc;
      },
      act: (bloc) => bloc
        ..add(const LoadAgreements(groupId: 1))
        ..add(
          const TogglePinAgreement(
            agreementId: 1,
            currentPinStatus: true,
          ),
        ),
      expect: () {
        final agreement = buildAgreement(isPinned: true);
        final unpinnedAgreement = agreement.copyWith(isPinned: false);
        return [
          const AgreementListLoading(),
          AgreementListLoaded(agreements: [agreement], groupId: 1),
          AgreementListLoaded(agreements: [unpinnedAgreement], groupId: 1),
          AgreementListActionSuccess(
            agreements: [unpinnedAgreement],
            groupId: 1,
            isPinned: false,
          ),
        ];
      },
      verify: (_) {
        verify(
          () => agreementProvider.unpinAgreement(
            groupId: 1,
            agreementId: 1,
          ),
        ).called(1);
      },
    );
  });
}
