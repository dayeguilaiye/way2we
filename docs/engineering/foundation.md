# 工具链与工程基础

状态：T00 已完成。

T00 建立真实客户端、服务端和隔离 PostgreSQL；本章记录工程基础与开发验证页，账号实现见 [T01](accounts.md)。业务接口按 T01—T07 分任务实现，开发验证页用于维护者检查连接、错误反馈和主题 token。

## 固定版本与平台

| 项目 | 版本／目标 | 固定位置与用途 |
| --- | --- | --- |
| Go | 1.27.1 | `mise.toml`、`server/go.mod`、`tools/go.sh`；包装脚本清除外部 GOROOT，选择指定工具链 |
| Flutter / Dart | 3.47.5 / 3.13.4 | `.flutter-version`、`pubspec.yaml`；根目录 Flutter 命令检查实际版本 |
| pgx | 5.11.0 | PostgreSQL 驱动、连接池与显式 SQL，MIT |
| goose | 3.28.0 | 内嵌 SQL 迁移与独立迁移命令，MIT |
| flutter_riverpod | 3.4.3 | 依赖和界面异步状态，MIT |
| go_router | 18.0.1 | 路由，BSD-3-Clause |
| Dio | 5.11.1 | HTTP 请求与错误解码，MIT |
| flutter_secure_storage | 11.2.0 | iOS Keychain 与 Android 安全存储，BSD-3-Clause |
| flutter_lints | 6.0.0 | Dart 静态检查，BSD-3-Clause |
| PostgreSQL | 18.6 Alpine | `compose.yaml` 同时固定版本和镜像摘要 |
| Xcode / iOS SDK | 27.0 / 27.0 | 本机已安装；iOS 最低 15.0，当前设备族为 iPhone |
| Android SDK | compile / target 36，最低 API 24 | `android/app/build.gradle.kts`；本机 Android 16 / API 36 模拟器 |
| Android NDK | 28.2.13676358 | Gradle 构建配置 |
| JDK | OpenJDK 17.0.20.1 | 本机 Homebrew `openjdk@17`，Gradle 使用 Java 17 |
| AGP / Kotlin / Gradle | 9.1.0 / 2.4.0 / 9.3.1 | Flutter 模板的 `settings.gradle.kts`、Gradle wrapper |
| SDK command-line tools / emulator | 15859902 / 37.1.11 | 本机 Android SDK |

Go 的模块校验和在 `go.sum`；Flutter 应用完整解析结果在 `pubspec.lock`。标准库随 Go 固定，Flutter 的本地化、测试、集成测试使用同版 SDK。iOS 插件通过 Swift Package Manager 构建；`flutter doctor` 仍提示未安装 CocoaPods，当前插件组合已通过实际 iOS 构建与读写验证。开发应用标识为 `dev.way2we.way2we`，正式商店标识、签名和分发配置在上线准备时确定。

第三方依赖用维护方稳定发布和实际双端构建确认兼容。Android 构建另自动安装 CMake 3.22.1。后续升级同时修改版本依据、锁文件与验证记录。官方来源：[Go 下载](https://go.dev/dl/)、[Flutter archive](https://docs.flutter.dev/install/archive)、[PostgreSQL 支持版本](https://www.postgresql.org/support/versioning/)、[Android 工具](https://developer.android.com/studio)、[Riverpod](https://pub.dev/packages/flutter_riverpod)、[go_router](https://pub.dev/packages/go_router)、[Dio](https://pub.dev/packages/dio)、[安全存储](https://pub.dev/packages/flutter_secure_storage)。

## 本机安装与配置

本次安装保留在本机：mise 下的 Go 1.27.1；Homebrew 下的 Flutter、Android command-line tools 和 OpenJDK 17；Android SDK 位于 `~/Library/Android/sdk`，本项目模拟器为 `way2we_api36`。Docker Desktop 提供两个项目数据库容器。Flutter CLI analytics 已关闭。

其他机器按上表安装固定版本，运行：

```sh
flutter config --android-sdk=<Android-SDK目录> --jdk-dir=<JDK17目录>
flutter doctor -v
flutter devices
```

Android SDK 包含 `platform-tools`、`platforms;android-36`、`build-tools;36.0.0`、`ndk;28.2.13676358`、`emulator`、`system-images;android-36;google_apis;arm64-v8a`。插件构建同时使用 SDK Platform 35。iOS 使用 Xcode simulator，无需配置正式发布证书即可运行模拟器。

日常入口统一在根目录 [Makefile](../../Makefile)，安装契约检查依赖用 `make setup-contract`，启动步骤见 [README](../../README.md)。Python 3.9 的系统 LibreSSL 会产生 urllib3 兼容提示；当前静态契约与本地 HTTP 检查已验证，后续环境优先使用带 OpenSSL 的 Python。

## 服务端入口

- `cmd/api` 装配配置、pgx 连接池、HTTP handler 和优雅退出。
- `cmd/migrate` 单独执行内嵌 goose 迁移；API 启动过程使用已迁移结构。
- `internal/httpapi` 集中生成请求编号、错误响应和请求完成日志。字段允许列表保持日志简洁，错误正文、令牌、邮箱与连接串不进入日志。
- `internal/platform` 提供配置、数据库、标识和无 HTTP 状态的业务错误。
- `internal/space/Writer.Run` 在空间行锁内执行鉴权、命令查重、业务回调与结果原子提交；每次重放重新鉴权，账号内命令锁协调跨空间标识复用。回调错误会回滚整个事务。

首个迁移包含 `users`、`spaces`、`memberships`、`commands`。命令入口当前用于成功结果与原子性验证；各业务任务会加入自己的数据、权限和事件。确定性拒绝持久化、邀请敏感结果加密、本人退出结果查询的特殊权限随相关业务任务接入。回调只执行数据库操作，参数必须是包含目标资源 ID 的规范化类型化 JSON。

## 客户端入口

`app` 装配主题、路由及会话恢复。`core` 提供安全存储和 Dio；业务接口登录到期按发起请求时的会话代次协调，旧账号响应不能结束新账号会话。公开验证码接口调用声明 `authenticated: false`。错误对象保留 code、字段信息和 request_id；显示使用本地文案。

开发页位于 `features/diagnostics`，按 data / application / presentation 划分。三套配色使用已采纳 token，ThemeData 与有类型扩展共享语义色。开发主题切换保持表单；T01 已接入账号外观的持久化和同步，见[账号实现](accounts.md)。业务写操作的意图生成、未确认操作恢复与空间状态生命周期按 T02—T04 的实际业务接入。

当前浅色主题遵循已确认视觉基准，系统深色外观下仍显示选定品牌配色。正式首页、四个业务入口、字体与植物装饰按对应业务页面实现，原型和参考图仍是视觉依据。

## 开发 HTTP 检查

| 请求 | 返回 | 用途 |
| --- | --- | --- |
| `GET /health/live` | 200 `{"status":"ok"}` | 进程存活 |
| `GET /health/ready` | 200 或 503 标准错误 | 数据库连通 |
| `POST /dev/validate`，`{"quantity":2}` | 200 `{"quantity":2}` | 两端成功响应 |
| 同上，quantity 为 0 | 422 `VALIDATION_FAILED`，quantity 字段错误 | 页面就近提示 |
| 未注册路径 | 404 `NOT_FOUND` 标准错误 | 通用提示与请求编号 |

服务端的 `DEV_DIAGNOSTICS` 只允许 local/test；客户端开发入口同时要求 debug。Android HTTP 明文只在 debug manifest 开放；发布 API 配置要求 HTTPS。`make check-runtime` 使用真实 HTTP 响应核对主 OpenAPI 的 Error schema。业务契约继续由 `api/openapi.yaml` 管理。

## 验证记录

运行日期：2026-09-28。本机原始日志留存在 `.artifacts/t00/`。`make check`、`make test-integration`、`make check-runtime` 均通过。

- Go：健康、解析、错误响应、请求编号、日志脱敏和 panic 恢复检查。
- PostgreSQL：空 schema 迁移与重复迁移、12 个相同意图并发仅执行一次、服务实例重新创建后的重放、修改参数冲突、业务写入后失败回滚、退出后的重放权限。
- Flutter：并发 401 单次过期、旧响应隔离、公开验证码错误、未知 code、非 JSON、超时类型与原操作标识传递；375×667 和 1.5 倍文字下主题切换保留表单。
- 实际 HTTP：5 组响应通过共享错误结构和请求编号检查；45 个契约操作、17 组静态示例与 3 个无效输入保持通过。
- 双端：iPhone 18 Pro Max / iOS 27.0 与 Pixel 9 / Android API 36 的 `connection_test.dart` 均通过，覆盖真实 Go 成功响应、字段错误、通用错误和平台安全存储读写。iOS simulator debug 与 Android debug APK 均构建并启动成功。
- 原生截图：默认字号、系统深色外观和大字号组合均已留存；选定的浅色品牌主题保持一致。截图位于 `.impeccable/review/t00/`，控制恢复为检查前的浅色与普通字号。[原生界面评审记录](../design/t00-foundation-review.md)结论为 ship，范围限于暖杏开发验证页的已提供状态；其他主题为源码／对比度检查，错误状态的原生视觉仍待对应页面验收。

Git 仓库为 `git@github.com:dayeguilaiye/way2we.git`，默认分支为 `main`。CI 平台待配置，根目录检查命令可由后续 CI 直接调用。真实设备、最低系统版本、正式签名、完整业务流程、真实邮件和图片服务在对应任务验证。T00 的数据库原子性检查提供共用入口的证据；业务余额、流水和通知的完整约束由后续任务添加场景检查。
