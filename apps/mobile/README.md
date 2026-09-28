# Flutter 客户端

使用 Flutter 3.47.5 / Dart 3.13.4。运行与检查入口见[根目录 README](../../README.md)，实现约定见 [Flutter 规范](../../docs/engineering/flutter.md)。

- `lib/app`：Riverpod 依赖装配、启动时恢复会话、GoRouter 和三套主题 token。
- `lib/core/network`：Dio、类型化错误、集中提示文案。
- `lib/core/session`：平台安全存储、账号会话生命周期和过期协调。
- `lib/features/diagnostics`：开发构建的联通检查。
- `test`：会话竞态、错误解码与界面检查。
- `integration_test`：真实后端连接、字段错误与平台安全存储验证。

`DEV_DIAGNOSTICS=true` 与 debug 构建共同启用 `/dev`。Release 构建只允许 HTTPS API。T01 实现邮箱登录和账号外观保存，后续业务页面按已采纳原型增加。
