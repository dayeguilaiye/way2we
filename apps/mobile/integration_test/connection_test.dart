import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:way2we/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('real Go success, field error and generic error', (tester) async {
    const storage = FlutterSecureStorage();
    await storage.write(key: 't00.storage.check', value: 'test-value');
    expect(await storage.read(key: 't00.storage.check'), 'test-value');
    await storage.delete(key: 't00.storage.check');
    app.main();
    await tester.pumpAndSettle();
    await tester.tap(find.text('检查连接'));
    await tester.pumpAndSettle();
    expect(find.text('连接正常'), findsOneWidget);
    await tester.enterText(find.byKey(const Key('quantity')), '0');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('验证数量'));
    await tester.tap(find.text('验证数量'));
    await tester.pumpAndSettle();
    expect(find.text('请输入大于 0 的整数。'), findsOneWidget);
    expect(find.text('请求编号'), findsOneWidget);
    await tester.ensureVisible(find.text('检查通用错误'));
    await tester.tap(find.text('检查通用错误'));
    await tester.pumpAndSettle();
    expect(find.text('内容暂时不可用。'), findsOneWidget);
  });
}
