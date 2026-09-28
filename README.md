# 一起的小日子 · Way2We

iOS 与 Android 使用 Flutter，后端使用 Go 与 PostgreSQL。业务规则、交互原型和工程规范均保存在本仓库。

当前实现为 **T00 工程基础**：开发页可连接 Go，展示成功与错误结果；已建立数据库迁移、事务命令入口、主题、路由、安全存储及统一检查。邮箱登录和完整业务页面从 T01 开始实现。

## 从哪里看

- [工程规范目录](docs/engineering/README.md)：技术栈、代码规范、错误与日志约定。
- [工具链与工程基础](docs/engineering/foundation.md)：精确版本、目录、实现边界和验证记录。
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

`make dev` 启动开发 PostgreSQL、执行迁移，再以前台进程运行 Go。默认地址为 `http://127.0.0.1:8080`，退出用 Ctrl+C；数据库保留在项目 Docker volume 中。按需将 `.env.example` 复制为 `.env.local` 修改本机配置。

另开终端，使用 `flutter devices` 获取设备 ID：

```sh
make mobile DEVICE=<iOS模拟器ID>
make mobile DEVICE=emulator-5554 API_BASE_URL=http://10.0.2.2:8080
```

开发页可以切换配色、检查连接、输入数量验证字段错误，并查看请求编号。当前启动命令只面向本机模拟器。真实手机及发布环境使用明确配置的 HTTPS API 地址。

## 检查

```sh
make check                    # Go、Flutter 与静态契约
make test-integration         # 独立 PostgreSQL 中的真实事务
make check-runtime            # 需要 make dev 已运行
make test-mobile-integration DEVICE=<iOS模拟器ID>
make test-mobile-integration DEVICE=emulator-5554 API_BASE_URL=http://10.0.2.2:8080
make build-ios                # iOS 模拟器开发构建
make build-android            # Android 开发 APK
make db-stop                 # 停止本项目两个数据库容器
```

开发库在 `127.0.0.1:55432/way2we_dev`；测试实例在 `127.0.0.1:55433/way2we_test`。测试仅允许这个本机测试地址，每次使用独立 schema，结束时清理该 schema。现有云数据库的连接信息独立于本项目本地配置。

## 版本管理

代码库：[dayeguilaiye/way2we](https://github.com/dayeguilaiye/way2we)，默认分支 `main`。仓库包含应用代码、文档、已采纳原型和设计素材；构建产物、本机配置、凭据与开发缓存按 `.gitignore` 保留在本机。
