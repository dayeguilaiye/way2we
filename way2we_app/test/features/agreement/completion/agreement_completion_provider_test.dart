import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:way2we_app/features/agreement/completion/data/providers/agreement_completion_provider.dart';

class MockDio extends Mock implements Dio {}

void main() {
  late MockDio mockDio;
  late AgreementCompletionProvider provider;

  setUp(() {
    mockDio = MockDio();
    provider = AgreementCompletionProvider(dio: mockDio);
  });

  setUpAll(() {
    registerFallbackValue(RequestOptions(path: '/'));
  });

  final completionJson = {
    'id': 1,
    'group_id': 10,
    'agreement_id': 5,
    'agreement_name': 'Agreement',
    'completer_id': 2,
    'completer_nickname': 'Alice',
    'recorder_id': 3,
    'recorder_nickname': 'Bob',
    'points': 5,
    'require_confirmation': true,
    'status': 'pending',
    'created_at': '2024-01-01T00:00:00Z',
  };

  test('createAgreementCompletion returns completion', () async {
    when(
      () => mockDio.post<Map<String, dynamic>>(
        any(),
        data: any(named: 'data'),
      ),
    ).thenAnswer(
      (_) async => Response(
        data: {'completion': completionJson},
        statusCode: 200,
        requestOptions: RequestOptions(
          path: '/v1/groups/10/agreements/5/completions',
        ),
      ),
    );

    final completion = await provider.createAgreementCompletion(
      groupId: 10,
      agreementId: 5,
      completerId: 2,
    );

    expect(completion.id, equals(1));
    expect(completion.status.name, equals('pending'));
  });

  test('listPendingCompletions returns list', () async {
    when(
      () => mockDio.get<Map<String, dynamic>>(
        any(),
        queryParameters: any(named: 'queryParameters'),
      ),
    ).thenAnswer(
      (_) async => Response(
        data: {
          'completions': [completionJson],
        },
        statusCode: 200,
        requestOptions: RequestOptions(
          path: '/v1/groups/10/agreement-completions',
        ),
      ),
    );

    final completions = await provider.listPendingCompletions(groupId: 10);
    expect(completions.length, equals(1));
    expect(completions.first.agreementName, equals('Agreement'));
  });

  test('confirmCompletion sends request', () async {
    when(
      () => mockDio.post<void>(any()),
    ).thenAnswer(
      (_) async => Response(
        statusCode: 200,
        requestOptions: RequestOptions(
          path: '/v1/groups/10/agreement-completions/1/confirm',
        ),
      ),
    );

    await provider.confirmCompletion(groupId: 10, completionId: 1);

    verify(
      () => mockDio.post<void>(
        '/v1/groups/10/agreement-completions/1/confirm',
      ),
    ).called(1);
  });

  test('rejectCompletion sends request', () async {
    when(
      () => mockDio.post<void>(any(), data: any(named: 'data')),
    ).thenAnswer(
      (_) async => Response(
        statusCode: 200,
        requestOptions: RequestOptions(
          path: '/v1/groups/10/agreement-completions/1/reject',
        ),
      ),
    );

    await provider.rejectCompletion(
      groupId: 10,
      completionId: 1,
      reason: 'Not valid',
    );

    verify(
      () => mockDio.post<void>(
        '/v1/groups/10/agreement-completions/1/reject',
        data: {'reason': 'Not valid'},
      ),
    ).called(1);
  });

  test(
    'createAgreementCompletion throws '
    'AgreementCompletionApiException on API error',
    () async {
      final errorResponse = Response<Map<String, dynamic>>(
        data: {'message': 'Bad request', 'code': 'ERR_BAD_REQUEST'},
        statusCode: 400,
        requestOptions: RequestOptions(
          path: '/v1/groups/10/agreements/5/completions',
        ),
      );

      when(
        () => mockDio.post<Map<String, dynamic>>(
          any(),
          data: any(named: 'data'),
        ),
      ).thenThrow(
        DioException(
          requestOptions: RequestOptions(
            path: '/v1/groups/10/agreements/5/completions',
          ),
          response: errorResponse,
          type: DioExceptionType.badResponse,
        ),
      );

      expect(
        () => provider.createAgreementCompletion(
          groupId: 10,
          agreementId: 5,
          completerId: 2,
        ),
        throwsA(
          isA<AgreementCompletionApiException>()
              .having((e) => e.message, 'message', 'Bad request')
              .having((e) => e.code, 'code', 'ERR_BAD_REQUEST'),
        ),
      );
    },
  );
}
