# Story 1.2: 多模式身份验证码发送 (Mock 模式)

状态: review

## 用户故事

作为一名 **用户**,
我希望 **输入手机号或邮箱并获取验证码**,
以便于 **我可以验证身份完成注册流程**.

> **注意**：验证码仅用于注册验证。登录使用账号密码方式。


## 验收标准 (Acceptance Criteria)

1. **Given** 用户在登录/注册页面  
   **When** 输入有效的手机号或邮箱并点击 "获取验证码"  
   **Then** 系统根据配置生成 6 位验证码，并输出至系统日志（DEBUG 模式）
2. **And** 按钮显示 60 秒倒计时，期间不可重复点击  
3. **And** 输入日志中的代码或预先定义的魔法码（123456）校验通过
4. **Given** 用户输入无效格式  
   **When** 点击 "获取验证码"  
   **Then** 显示相应的错误提示

## 任务 / 子任务 (Tasks / Subtasks)

- [x] **后端：验证码 Mock 逻辑与 API (Backend)**
  - [x] 在 `internal/app/auth/provider.go` 中定义 `SmsProvider` 和 `EmailProvider` 接口。
  - [x] 在 `internal/adapter/auth` 中实现 `LogSmsProvider` 和 `LogEmailProvider`：
    - [x] 逻辑：只需使用 Logger 打印类似 `[SMS/EMAIL MOCK] To: {target}, Code: {code}`。
  - [x] 在 `internal/app/auth/service.go` 中：
    - [x] 实现生成 6 位随机码逻辑。
    - [x] 实现认证流程，支持校验逻辑：优先匹配环境变量中的 `AUTH_MAGIC_CODE`，其次匹配存储的验证码。
  - [x] 在 `internal/adapter/handler/auth_handler.go` 中实现 `POST /v1/auth/verification-code`：
    - [x] 接收 `type` (phone/email) 和 `target`。
- [x] **前端：双模式获取验证码 UI (Frontend)**
  - [x] 在 `lib/features/auth/view/login_page.dart` 中：
    - [x] 适配手机号和邮箱两种输入形式切换。
    - [x] 实现倒计时逻辑。
  - [x] 调用新 API 获取验证码。

## 开发备注 (Dev Notes)

### 架构合规性
- **Provider 模式**: 后端必须通过接口隔离，以便 MVP 后轻松切回真实网关。
- **Magic Code**: 通过环境变量控制，生产环境必须禁用。

### 参考资料
- [Source: architecture.md#认证与安全]
- [Source: epics.md#Story 1.2]

## Dev Agent Record

### Implementation Plan
1. **Backend Provider Interfaces**: Defined `SmsProvider` and `EmailProvider` interfaces in `internal/app/auth/provider.go` with `Send(ctx, target, code)` method signature.
2. **Mock Providers**: Implemented `LogSmsProvider` and `LogEmailProvider` in `internal/adapter/auth/log_provider.go` that log verification codes to stdout.
3. **Auth Service**: Created `Service` in `internal/app/auth/service.go` with:
   - Cryptographically secure 6-digit code generation
   - In-memory code storage with expiration (5 minutes default)
   - Magic code bypass via `AUTH_MAGIC_CODE` environment variable
   - One-time use verification codes
4. **HTTP Handler**: Implemented `POST /v1/auth/verification-code` endpoint with:
   - Request validation for phone (Chinese format) and email
   - Proper error response structure per architecture spec
5. **Frontend BLoC**: Created `VerificationCodeBloc` with:
   - Send verification code action
   - 60-second countdown timer
   - Error handling and state management
6. **Login UI**: Built `LoginPage` with:
   - Phone/Email toggle using SegmentedButton
   - Input validation matching backend rules
   - Countdown button that disables during cooldown

### Debug Log
- All 16 backend tests passed
- All 12 frontend tests passed
- Flutter analyze shows no issues
- Code compiles successfully

### Completion Notes
✅ Story implementation complete. All acceptance criteria satisfied:
- AC1: 6-digit verification code generated and logged (verified via tests)
- AC2: 60-second countdown with disabled button (implemented in BLoC + UI)
- AC3: Magic code (123456) validation supported via AUTH_MAGIC_CODE env var
- AC4: Invalid format shows error messages (phone/email validation in handler + UI)

## File List

### Backend (way2we_api)
- `internal/app/auth/provider.go` (new) - SmsProvider and EmailProvider interfaces
- `internal/app/auth/service.go` (new) - Auth service with code generation and verification
- `internal/app/auth/service_test.go` (new) - Unit tests for auth service
- `internal/adapter/auth/log_provider.go` (new) - Mock SMS and Email providers
- `internal/adapter/handler/auth_handler.go` (new) - HTTP handler for verification code endpoint
- `internal/adapter/handler/auth_handler_test.go` (new) - Handler integration tests
- `cmd/api/main.go` (modified) - Wired up auth service and routes

### Frontend (way2we_app)
- `lib/features/auth/auth.dart` (new) - Feature barrel export
- `lib/features/auth/bloc/bloc.dart` (new) - BLoC barrel export
- `lib/features/auth/bloc/verification_code_bloc.dart` (new) - Verification code BLoC
- `lib/features/auth/bloc/verification_code_event.dart` (new) - BLoC events
- `lib/features/auth/bloc/verification_code_state.dart` (new) - BLoC state
- `lib/features/auth/data/models/models.dart` (new) - Models barrel export
- `lib/features/auth/data/models/verification_code_request.dart` (new) - Request model
- `lib/features/auth/data/models/verification_code_request.g.dart` (new) - Generated serialization
- `lib/features/auth/data/models/verification_code_response.dart` (new) - Response model
- `lib/features/auth/data/models/verification_code_response.g.dart` (new) - Generated serialization
- `lib/features/auth/data/providers/auth_provider.dart` (new) - API provider
- `lib/features/auth/view/view.dart` (new) - View barrel export
- `lib/features/auth/view/login_page.dart` (new) - Login page with verification UI
- `test/features/auth/bloc/verification_code_bloc_test.dart` (new) - BLoC tests

## Change Log

| Date | Change | Author |
|------|--------|--------|
| 2025-12-31 | Story implementation complete - all tasks done, tests passing | Dev Agent |
