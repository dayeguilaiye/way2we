# Story 1.2: 多模式身份验证码发送 (Mock 模式)

状态: ready-for-dev

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

- [ ] **后端：验证码 Mock 逻辑与 API (Backend)**
  - [ ] 在 `internal/app/auth/provider.go` 中定义 `SmsProvider` 和 `EmailProvider` 接口。
  - [ ] 在 `internal/adapter/auth` 中实现 `LogSmsProvider` 和 `LogEmailProvider`：
    - [ ] 逻辑：只需使用 Logger 打印类似 `[SMS/EMAIL MOCK] To: {target}, Code: {code}`。
  - [ ] 在 `internal/app/auth/service.go` 中：
    - [ ] 实现生成 6 位随机码逻辑。
    - [ ] 实现认证流程，支持校验逻辑：优先匹配环境变量中的 `AUTH_MAGIC_CODE`，其次匹配存储的验证码。
  - [ ] 在 `internal/adapter/handler/auth_handler.go` 中实现 `POST /v1/auth/verification-code`：
    - [ ] 接收 `type` (phone/email) 和 `target`。
- [ ] **前端：双模式获取验证码 UI (Frontend)**
  - [ ] 在 `lib/features/auth/view/login_page.dart` 中：
    - [ ] 适配手机号和邮箱两种输入形式切换。
    - [ ] 实现倒计时逻辑。
  - [ ] 调用新 API 获取验证码。

## 开发备注 (Dev Notes)

### 架构合规性
- **Provider 模式**: 后端必须通过接口隔离，以便 MVP 后轻松切回真实网关。
- **Magic Code**: 通过环境变量控制，生产环境必须禁用。

### 参考资料
- [Source: architecture.md#认证与安全]
- [Source: epics.md#Story 1.2]
