import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:way2we_app/features/redemption/data/models/redemption_order.dart';
import 'package:way2we_app/features/redemption/data/providers/redemption_provider.dart';
import 'package:way2we_app/features/redemption/view/redemption_order_list_page.dart';
import 'package:way2we_app/l10n/l10n.dart';
import 'package:way2we_app/theme/app_theme.dart';

class _FakeRedemptionProvider extends RedemptionProvider {
  _FakeRedemptionProvider(this.orders) : super(dio: Dio());

  final List<RedemptionOrder> orders;

  @override
  Future<List<RedemptionOrder>> listOrders({
    required int groupId,
    String? status,
    String? role,
    int? limit,
    int? offset,
  }) async {
    return orders;
  }

  @override
  Future<RedemptionOrder> getOrderDetail({
    required int groupId,
    required int orderId,
  }) async {
    return orders.firstWhere((order) => order.id == orderId);
  }
}

class _TestNavigatorObserver extends NavigatorObserver {
  int didPushCount = 0;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    didPushCount += 1;
    super.didPush(route, previousRoute);
  }
}

RedemptionOrder _buildOrder({
  required int id,
  required RedemptionOrderStatus status,
}) {
  return RedemptionOrder(
    id: id,
    groupId: 1,
    rewardId: id + 10,
    rewardName: 'Reward $id',
    consumerId: 100,
    consumerNickname: 'Alex',
    providerId: 200,
    providerNickname: 'Sam',
    quantity: 2,
    unitCostPoints: 30,
    totalCostPoints: 60,
    status: status,
    autoFulfill: false,
    autoComplete: false,
    providerIncentiveRatio: 20,
    createdAt: DateTime.parse('2025-01-01T00:00:00Z'),
    updatedAt: DateTime.parse('2025-01-01T00:00:00Z'),
  );
}

Future<void> _pumpPage(
  WidgetTester tester,
  RedemptionProvider provider, {
  List<NavigatorObserver> navigatorObservers = const [],
}) async {
  await tester.pumpWidget(
    RepositoryProvider<RedemptionProvider>.value(
      value: provider,
      child: MaterialApp(
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: ThemeMode.light,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        navigatorObservers: navigatorObservers,
        home: const RedemptionOrderListPage(groupId: 1),
      ),
    ),
  );
}

void main() {
  group('RedemptionOrderListPage', () {
    testWidgets('renders empty state when there are no orders', (tester) async {
      await _pumpPage(tester, _FakeRedemptionProvider(const []));
      await tester.pumpAndSettle();

      final context = tester.element(find.byType(RedemptionOrderListPage));
      final l10n = context.l10n;

      expect(find.text(l10n.redemptionOrderEmptyTitle), findsOneWidget);
      expect(find.text(l10n.redemptionOrderEmptySubtitle), findsOneWidget);
    });

    testWidgets('renders status badges for returned orders', (tester) async {
      final orders = [
        _buildOrder(id: 1, status: RedemptionOrderStatus.awaitingFulfill),
        _buildOrder(id: 2, status: RedemptionOrderStatus.awaitingConfirm),
        _buildOrder(id: 3, status: RedemptionOrderStatus.completed),
        _buildOrder(id: 4, status: RedemptionOrderStatus.unsatisfied),
      ];

      await _pumpPage(tester, _FakeRedemptionProvider(orders));
      await tester.pumpAndSettle();

      final context = tester.element(find.byType(RedemptionOrderListPage));
      final l10n = context.l10n;

      expect(find.text(l10n.redemptionStatusAwaitingFulfill), findsOneWidget);
      expect(find.text(l10n.redemptionStatusAwaitingConfirm), findsOneWidget);
      expect(find.text(l10n.redemptionStatusCompleted), findsOneWidget);
      expect(find.text(l10n.redemptionStatusUnsatisfied), findsOneWidget);

      expect(
        find.text(l10n.commonQuantityTimesPoints(2, 30)),
        findsNWidgets(4),
      );
      expect(find.text(l10n.commonPoints(60)), findsNWidgets(4));
    });

    testWidgets('navigates to detail page when order card is tapped', (
      tester,
    ) async {
      final observer = _TestNavigatorObserver();
      final orders = [
        _buildOrder(id: 99, status: RedemptionOrderStatus.awaitingFulfill),
      ];

      await _pumpPage(
        tester,
        _FakeRedemptionProvider(orders),
        navigatorObservers: [observer],
      );
      await tester.pumpAndSettle();

      final initialPushCount = observer.didPushCount;
      await tester.tap(find.text('Reward 99'));
      await tester.pumpAndSettle();

      final context = tester.element(find.byType(Scaffold).first);
      final l10n = AppLocalizations.of(context);
      expect(find.text(l10n.redemptionOrderDetailTitle), findsOneWidget);
      expect(observer.didPushCount, greaterThan(initialPushCount));
    });
  });
}
