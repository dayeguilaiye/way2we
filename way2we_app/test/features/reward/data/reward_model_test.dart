import 'package:flutter_test/flutter_test.dart';
import 'package:way2we_app/features/reward/data/models/reward.dart';

void main() {
  test('Reward serializes isPinned correctly', () {
    final json = {
      'id': 1,
      'name': 'Reward',
      'description': 'Desc',
      'cost_points': 10,
      'cover_image_url': '',
      'status': 'active',
      'is_pinned': true,
      'auto_fulfill': false,
      'auto_complete': false,
      'group_id': 1,
      'provider_id': 2,
      'provider_nickname': 'Alice',
      'created_at': '2024-01-01T00:00:00Z',
      'updated_at': '2024-01-01T00:00:00Z',
    };

    final reward = Reward.fromJson(json);
    expect(reward.isPinned, isTrue);

    final serialized = reward.toJson();
    expect(serialized['is_pinned'], isTrue);
  });

  test('Reward defaults isPinned to false when missing', () {
    final json = {
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

    final reward = Reward.fromJson(json);
    expect(reward.isPinned, isFalse);
  });
}
