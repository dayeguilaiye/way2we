# 一起的小日子 · Way2We

iOS 与 Android 使用 Flutter，后端使用 Go 与 PostgreSQL。业务规则、交互原型和工程规范均保存在本仓库。

当前实现包含 **T00—T02 的本地流程**：邮箱登录、个人外观、创建空间、邀请与全员同意、成员昵称和站内通知均连接真实 Go 和 PostgreSQL。邮件在本机收件箱查看，真实发送服务在上线接入时确定。

## 从哪里看

- [工程规范目录](docs/engineering/README.md)：技术栈、代码规范、错误与日志约定。
- [工具链与工程基础](docs/engineering/foundation.md)：精确版本、目录、实现边界和验证记录。
- [邮箱登录与个人外观](docs/engineering/accounts.md)：实现、邮件收件箱与恢复机制。
- [空间、邀请与通知](docs/engineering/spaces.md)：加入规则、链接、事务、通知恢复与验证。
- [实施任务](docs/planning/implementation.md)：T00—T07 的交付范围。
- [原型说明](prototype/README.md)：已采纳的完整交互与视觉基准。

## 本机启动

准备 Go 1.27.1、Flutter 3.47.5、Docker Compose、Python 3，以及对应移动平台 SDK。安装细节见[工具链说明](docs/engineering/foundation.md)。

```sh
# 在仓库根目录运行。Docker Desktop 需要已启动。
make setup-contract
cd apps/mobile && flutter pub get && cd ../..
make dev
```

`make dev` 启动开发 PostgreSQL 和 Mailpit，创建本机认证密钥、执行迁移，再以前台进程运行 Go。默认地址为 `http://127.0.0.1:8080`，退出用 Ctrl+C；数据库保留在项目 Docker volume 中。按需将 `.env.example` 复制为 `.env.local` 修改本机配置。

另开终端，使用 `flutter devices` 获取设备 ID：

```sh
make mobile DEVICE=<iOS模拟器ID>
make mobile DEVICE=emulator-5554 API_BASE_URL=http://10.0.2.2:8080
```

App 从邮箱登录开始。输入测试邮箱后，在 [Mailpit 本地收件箱](http://127.0.0.1:8025) 查看验证码；登录后进入空间列表，可以创建空间、邀请伙伴并查看通知；「我的」中修改昵称和配色，退出后使用同邮箱恢复。当前启动命令面向本机模拟器；真实手机及发布环境配置 HTTPS API 与真实邮件服务。

开发验证页仍可用 `--dart-define=DEV_DIAGNOSTICS=true --dart-define=START_DIAGNOSTICS=true` 显式启动，检查连接、字段错误与请求编号。

## 检查

```sh
make check                    # Go、Flutter 与静态契约
make test-integration         # 独立 PostgreSQL 中的真实事务
make check-runtime            # 需要 make dev 已运行
make check-auth-runtime       # 本地邮件 + T01 HTTP 契约
make check-spaces-runtime     # 三个真实账号 + T02 HTTP 契约
make test-spaces-device DEVICE=<iOS模拟器ID>
make test-spaces-device DEVICE=emulator-5554
make test-account-device DEVICE=<iOS模拟器ID>
make test-account-device DEVICE=emulator-5554
make test-mobile-integration DEVICE=<iOS模拟器ID>
make test-mobile-integration DEVICE=emulator-5554 API_BASE_URL=http://10.0.2.2:8080
make build-ios                # iOS 模拟器开发构建
make build-android            # Android 开发 APK
make db-stop                 # 停止本项目数据库与收件箱容器
```

开发库在 `127.0.0.1:55432/way2we_dev`；测试实例在 `127.0.0.1:55433/way2we_test`。测试仅允许这个本机测试地址，每次使用独立 schema，结束时清理该 schema。现有云数据库的连接信息独立于本项目本地配置。

## 版本管理

代码库：[dayeguilaiye/way2we](https://github.com/dayeguilaiye/way2we)，默认分支 `main`。仓库包含应用代码、文档、已采纳原型和设计素材；构建产物、本机配置、凭据与开发缓存按 `.gitignore` 保留在本机。
