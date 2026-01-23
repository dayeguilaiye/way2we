import 'package:bloc_test/bloc_test.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:way2we_app/features/auth/bloc/verification_code_bloc.dart';
import 'package:way2we_app/features/auth/data/models/models.dart';
import 'package:way2we_app/features/auth/data/providers/auth_provider.dart';

class MockDio extends Mock implements Dio {}

void main() {
  late MockDio mockDio;
  late AuthProvider authProvider;

  setUp(() {
    mockDio = MockDio();
    authProvider = AuthProvider(dio: mockDio);
  });

  setUpAll(() {
    registerFallbackValue(
      RequestOptions(path: '/v1/auth/verification-code'),
    );
  });

  group('VerificationCodeBloc', () {
    blocTest<VerificationCodeBloc, VerificationCodeState>(
      'emits [sending, sent] when SendVerificationCode succeeds',
      build: () {
        when(
          () => mockDio.post<Map<String, dynamic>>(
            any(),
            data: any(named: 'data'),
          ),
        ).thenAnswer(
          (_) async => Response(
            data: {'success': true, 'message': '验证码已发送'},
            statusCode: 200,
            requestOptions: RequestOptions(path: '/v1/auth/verification-code'),
          ),
        );
        return VerificationCodeBloc(authProvider: authProvider);
      },
      act: (bloc) => bloc.add(
        const SendVerificationCode(type: 'phone', target: '13800138000'),
      ),
      expect: () => [
        const VerificationCodeState(status: VerificationCodeStatus.sending),
        const VerificationCodeState(
          status: VerificationCodeStatus.sent,
          countdown: 60,
        ),
      ],
    );

    blocTest<VerificationCodeBloc, VerificationCodeState>(
      'emits [sending, failure] when SendVerificationCode fails',
      build: () {
        when(
          () => mockDio.post<Map<String, dynamic>>(
            any(),
            data: any(named: 'data'),
          ),
        ).thenThrow(
          DioException(
            requestOptions: RequestOptions(path: '/v1/auth/verification-code'),
            response: Response(
              data: {'code': 'ERR_INVALID_TARGET', 'message': '手机号码格式无效'},
              statusCode: 400,
              requestOptions: RequestOptions(
                path: '/v1/auth/verification-code',
              ),
            ),
          ),
        );
        return VerificationCodeBloc(authProvider: authProvider);
      },
      act: (bloc) => bloc.add(
        const SendVerificationCode(type: 'phone', target: '12345'),
      ),
      expect: () => [
        const VerificationCodeState(status: VerificationCodeStatus.sending),
        const VerificationCodeState(
          status: VerificationCodeStatus.failure,
          errorMessage: '手机号码格式无效',
        ),
      ],
    );

    blocTest<VerificationCodeBloc, VerificationCodeState>(
      'countdown decreases on CountdownTick',
      build: () => VerificationCodeBloc(authProvider: authProvider),
      seed: () => const VerificationCodeState(
        status: VerificationCodeStatus.sent,
        countdown: 60,
      ),
      act: (bloc) => bloc.add(const CountdownTick()),
      expect: () => [
        const VerificationCodeState(
          status: VerificationCodeStatus.sent,
          countdown: 59,
        ),
      ],
    );

    blocTest<VerificationCodeBloc, VerificationCodeState>(
      'ResetCooldown resets state to initial',
      build: () => VerificationCodeBloc(authProvider: authProvider),
      seed: () => const VerificationCodeState(
        status: VerificationCodeStatus.sent,
        countdown: 30,
      ),
      act: (bloc) => bloc.add(const ResetCooldown()),
      expect: () => [
        const VerificationCodeState(
          status: VerificationCodeStatus.initial,
          countdown: 0,
        ),
      ],
    );

    test('canSend is true when initial', () {
      const state = VerificationCodeState();
      expect(state.canSend, isTrue);
    });

    test('canSend is false when sending', () {
      const state = VerificationCodeState(
        status: VerificationCodeStatus.sending,
      );
      expect(state.canSend, isFalse);
    });

    test('canSend is false when countdown active', () {
      const state = VerificationCodeState(
        status: VerificationCodeStatus.sent,
        countdown: 30,
      );
      expect(state.canSend, isFalse);
    });

    test('canSend is true when countdown finished', () {
      const state = VerificationCodeState(
        status: VerificationCodeStatus.sent,
        countdown: 0,
      );
      expect(state.canSend, isTrue);
    });

    test('canSend is true after failure', () {
      const state = VerificationCodeState(
        status: VerificationCodeStatus.failure,
        errorMessage: 'Some error',
      );
      expect(state.canSend, isTrue);
    });
  });

  group('VerificationCodeRequest', () {
    test('toJson produces correct output', () {
      const request = VerificationCodeRequest(
        type: 'phone',
        target: '13800138000',
      );
      expect(request.toJson(), {
        'type': 'phone',
        'target': '13800138000',
      });
    });

    test('fromJson parses correctly', () {
      final request = VerificationCodeRequest.fromJson({
        'type': 'email',
        'target': 'test@example.com',
      });
      expect(request.type, 'email');
      expect(request.target, 'test@example.com');
    });
  });

  group('VerificationCodeResponse', () {
    test('fromJson parses success response', () {
      final response = VerificationCodeResponse.fromJson({
        'success': true,
        'message': '验证码已发送',
      });
      expect(response.success, isTrue);
      expect(response.message, '验证码已发送');
    });
  });
}
