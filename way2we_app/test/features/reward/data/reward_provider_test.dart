import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:way2we_app/features/reward/data/providers/reward_provider.dart';

class MockDio extends Mock implements Dio {}

void main() {
  late MockDio mockDio;
  late RewardProvider rewardProvider;

  setUp(() {
    mockDio = MockDio();
    rewardProvider = RewardProvider(dio: mockDio);
  });

  setUpAll(() {
    registerFallbackValue(RequestOptions(path: '/'));
  });

  final rewardJson = {
    'id': 1,
    'name': 'Reward',
    'description': 'Desc',
    'cost_points': 10,
    'cover_image_url': '',
    'status': 'active',
    'auto_fulfill': false,
    'auto_complete': false,
    'group_id': 1,
    'provider_id': 2,
    'provider_nickname': 'Alice',
    'created_at': '2024-01-01T00:00:00Z',
    'updated_at': '2024-01-01T00:00:00Z',
  };

  test('listRewards returns parsed rewards', () async {
    when(
      () => mockDio.get<Map<String, dynamic>>(
        any(),
        queryParameters: any(named: 'queryParameters'),
      ),
    ).thenAnswer(
      (_) async => Response(
        data: {'rewards': [rewardJson]},
        statusCode: 200,
        requestOptions: RequestOptions(path: '/v1/groups/1/rewards'),
      ),
    );

    final rewards = await rewardProvider.listRewards(groupId: 1, status: 'active');
    expect(rewards, isNotEmpty);
    expect(rewards.first.id, equals(1));
    expect(rewards.first.name, equals('Reward'));
  });

  test('createReward returns reward', () async {
    when(
      () => mockDio.post<Map<String, dynamic>>(
        any(),
        data: any(named: 'data'),
      ),
    ).thenAnswer(
      (_) async => Response(
        data: rewardJson,
        statusCode: 200,
        requestOptions: RequestOptions(path: '/v1/groups/1/rewards'),
      ),
    );

    final reward = await rewardProvider.createReward(
      groupId: 1,
      input: const CreateRewardInput(name: 'Reward', costPoints: 10),
    );
    expect(reward.id, equals(1));
  });

  test('updateRewardStatus returns updated reward', () async {
    final updated = Map<String, dynamic>.from(rewardJson)
      ..['status'] = 'inactive';

    when(
      () => mockDio.put<Map<String, dynamic>>(
        any(),
        data: any(named: 'data'),
      ),
    ).thenAnswer(
      (_) async => Response(
        data: updated,
        statusCode: 200,
        requestOptions: RequestOptions(path: '/v1/groups/1/rewards/1/status'),
      ),
    );

    final reward = await rewardProvider.updateRewardStatus(
      groupId: 1,
      rewardId: 1,
      status: 'inactive',
    );
    expect(reward.status.name, equals('inactive'));
  });

  test('listRewards throws RewardApiException on API error', () async {
    final errorResponse = Response<Map<String, dynamic>>(
      data: {'message': 'Bad request', 'code': 'ERR_BAD_REQUEST'},
      statusCode: 400,
      requestOptions: RequestOptions(path: '/v1/groups/1/rewards'),
    );
    when(
      () => mockDio.get<Map<String, dynamic>>(
        any(),
        queryParameters: any(named: 'queryParameters'),
      ),
    ).thenThrow(
      DioException(
        requestOptions: RequestOptions(path: '/v1/groups/1/rewards'),
        response: errorResponse,
        type: DioExceptionType.badResponse,
      ),
    );

    expect(
      () => rewardProvider.listRewards(groupId: 1, status: 'active'),
      throwsA(
        isA<RewardApiException>()
            .having((e) => e.message, 'message', 'Bad request')
            .having((e) => e.code, 'code', 'ERR_BAD_REQUEST'),
      ),
    );
  });
}
