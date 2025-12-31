# Story 1.2: 发送手机验证码

状态: ready-for-dev

<!-- 注意：验证是可选的。在执行 dev-story 前，可以运行 validate-create-story 进行质量检查。 -->

## 用户故事

作为一名 **用户**,
我希望 **输入手机号并收到验证码**,
以便于 **我可以验证身份进行注册或登录**.

## 验收标准 (Acceptance Criteria)

1. **Given** 用户在登录页面  
   **When** 输入有效的手机号并点击 "获取验证码"  
   **Then** 系统调用短信服务发送 6 位数字验证码  
2. **And** 按钮显示 60 秒倒计时，期间不可重复点击  
3. **And** 验证码 5 分钟内有效  
4. **Given** 用户输入无效的手机号格式  
   **When** 点击 "获取验证码"  
   **Then** 显示错误提示 "请输入正确的手机号"  
   **And** 不发送验证码  
5. **Given** 用户在 60 秒内重复请求验证码  
   **When** 点击 "获取验证码"  
   **Then** 按钮保持禁用状态直到倒计时结束

## 任务 / 子任务 (Tasks / Subtasks)

- [ ] **后端：短信逻辑与 API (Backend)** (AC: 1, 3, 4, 5)
  - [ ] 在 `internal/app/auth/provider.go` 中定义 `SmsProvider` 接口。
  - [ ] 在 `internal/adapter/sms/aliyun.go` 中使用 SDK v2.0 实现 `AliyunSmsAdapter`。
  - [ ] 在 `internal/app/auth/service.go` 中创建 `AuthService`:
    - [ ] 生成 6 位随机验证码。
    - [ ] 将验证码映射手机号存储在缓存中（如 Redis 或带 TTL 的内存缓存）。
    - [ ] 针对每个手机号执行 60 秒的频率限制。
  - [ ] 在 `internal/adapter/handler/auth_handler.go` 中实现 `POST /v1/auth/sms-code` 处理函数。
  - [ ] 为 AuthService 和短信 Handler 添加单元测试。
- [ ] **前端：认证功能与 UI (Frontend)** (AC: 1, 2, 4, 5)
  - [ ] 创建文件夹结构 `lib/features/auth/{bloc,data,view,widgets}`。
  - [ ] 在 `lib/features/auth/data` 中实现 `AuthRepository` 以调用 `/v1/auth/sms-code`。
  - [ ] 在 `lib/features/auth/bloc` 中实现 `AuthBloc` (或 `AuthCubit`):
    - [ ] 处理 `AuthSmsCodeRequested` 事件。
    - [ ] 实现基于 `Ticker` 的 60 秒倒计时计时器。
    - [ ] 管理状态: `AuthInitial`, `AuthSmsCodeInProgress`, `AuthSmsCodeSuccess`, `AuthSmsCodeFailure`。
  - [ ] 在 `lib/features/auth/view/login_page.dart` 中创建 `LoginPage`:
    - [ ] 带有 `Form` 和 `Regex` 正则验证的手机号输入框。
    - [ ] 带有 BLoC 状态驱动倒计时和禁用状态的 "获取验证码" 按钮。
    - [ ] 使用 `SnackBar` 或提示文本进行错误反馈。

## 开发备注 (Dev Notes)

### 架构合规性 (Architecture Compliance)
- **Feature-First 结构**: 所有认证逻辑必须位于 `lib/features/auth` 内。
- **状态管理**: 使用 `flutter_bloc` 和 `equatable`。遵循计时器的 `Ticker` 模式以避免 UI 侧内存泄漏。
- **后端布局**: 业务逻辑使用 `internal/app`，外部集成（短信/REST）使用 `internal/adapter`。
- **通信规范**: JSON 字段必须使用 `snake_case`（例如：`phone_number`, `verification_code`）。

### 库 / 框架要求 (Library Requirements)
- **后端**: 使用 `github.com/aliyun/alibaba-cloud-sdk-go` 进行短信集成。
- **前端**: 使用 `flutter_bloc` 进行状态管理，使用 `dio` 进行网络请求。

### 项目结构说明
- 共享逻辑（如网络客户端）应放在 `lib/core/network`。
- 用于存储 Token 的安全存储应放在 `lib/core/storage`。

### 参考资料 (References)
- [Source: architecture.md#认证与安全]
- [Source: architecture.md#项目结构与边界]
- [Source: epics.md#Story 1.2: 手机号验证码发送]

## 开发代理记录 (Dev Agent Record)

### 使用的代理模型
Antigravity (Custom Coding Assistant)

### 调试日志引用

### 完成说明列表

### 文件列表
