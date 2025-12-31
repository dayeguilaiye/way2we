---
stepsCompleted: [1, 2, 3, 4, 5, 6, 7]
inputDocuments:
  - _bmad-output/prd.md
  - _bmad-output/project-planning-artifacts/ux-design-specification.md
workflowType: 'architecture'
project_name: 'way2we'
user_name: 'Ziyuanhe'
date: '2025-12-30T14:03:42'
---

# 架构决策文档

_本文档通过逐步发现协作构建。随着我们在每个架构决策上的推进，章节将被追加。_

## 项目背景分析

### 需求概览

**功能需求:**
*   **核心领域**: "约定管理", "积分账本", "商品兑换", "履约确认".
*   **多租户与权限**: 基于群组的隔离与细粒度的 RBAC (管理员 + 权限分配体系) (FR25-FR29).
*   **事务一致性**: 积分的增加、扣减和撤销 (FR36-FR38) 需要强一致性.
*   **审计追踪**: 对规则变更、积分事件和兑换记录的全面日志 (FR42-FR44).

**非功能需求:**
*   **性能**: 核心流程 (创建约定/兑换) 响应 ≤ 2秒.
*   **可用性**: 关键旅程 99% 成功率.
*   **平台**: 双端支持 iOS & Android (指定 Flutter).
*   **推送通知**: 集成推送服务实现 <30秒 触达.

**规模与复杂度:**

- 核心领域: Mobile App (Flutter) + Backend API
- 复杂度等级: 中等 (涉及状态管理, 账本一致性, 权限控制)
- 预估架构组件: 客户端, API 网关, 业务逻辑 (可能为模块化单体), 数据库, 对象存储, 推送服务.

### 技术约束与依赖

*   **前端**: 必须使用 **Flutter**.
*   **部署**: 移动应用商店 (iOS/Android).
*   **状态管理**: UX 暗示且需要 Optimistic UI 模式以实现"即时反馈".
*   **外部服务**: 推送通知提供商, 云存储 (图片).

### 识别到的横切关注点

1.  **认证与授权**: 统一身份 + 基于群组的权限.
2.  **审计日志**: 全局记录价值转移事件和配置变更.
3.  **通知系统**: 集中分发站内信和推送.
4.  **异常处理与一致性**: 事务回滚和故障恢复.
5.  **设计系统集成**: 基于 UX 规范实现的 Flutter 主题引擎.

## Starter 模版评估

### 核心技术领域

**全栈移动端**: Flutter 客户端 + Golang 服务端

### 客户端: Flutter (Mobile App)

**选定 Starter: Very Good Core**

**选择理由:**
*   **行业标准**: 被认为是 Flutter 生产级开发的“黄金标准”，由 Very Good Ventures 维护.
*   **内置最佳实践**: 预置了 **Flavor** (Dev/Staging/Prod)、**Logging**、**i18n** (国际化)、**Testing** (Unit/Widget/Integration) 配置.
*   **架构约束**: 强制使用严格的 Layered Architecture 和 BLoC 模式，非常适合需要长期维护的中型项目.
*   **团队一致性**: 强制的代码规范能确保团队协作时代码风格的一致性.

**初始化命令:**

```bash
# 安装 CLI
dart pub global activate very_good_cli

# 创建项目 (应用名: way2we, 组织: com.way2we)
very_good create flutter_app way2we --org com.way2we --desc "Way2We - Relationship Interaction App"
```

**提供的架构决策:**
*   **状态管理**: BLoC (Business Logic Component) - 适合处理复杂的业务逻辑（如积分状态、审批流）.
*   **测试**: 100% 覆盖率配置，集成 Mocktail.
*   **CI/CD**: Github Actions 预配置.

### 服务端: Golang (Backend API)

**选定方案: Standard Go Project Layout (模块化单体)**

**选择理由:**
*   **团队适配**: 既然团队 Go 经验丰富，避免使用过度封装的框架（如 Beego），专注于 **Standard Go Project Layout** + 最佳单品库的组合.
*   **类型安全与图逻辑**: 选用 **Ent** 而非 GORM，以获得编译时类型安全和强大的图谱关系（用户-群组-规则）处理能力，这对于关系依赖重的系统至关重要.
*   **API 设计**: 选用 **Echo** 而非 Gin，因其更符合直觉的 API 设计和无需反射的 Context 绑定，对于追求代码质量的团队更友好.

**推荐技术栈:**
*   **Web 框架**: **Echo** (高性能, 极简的 web 框架).
*   **数据库**: **PostgreSQL** (已确认).
*   **ORM**: **Ent** (Facebook 出品的实体框架, 基于图, 类型安全).
*   **迁移工具**: **Atlas** (与 Ent 集成) 或 **Golang-Migrate**.
*   **项目结构**: `github.com/golang-standards/project-layout`.

**项目结构预览:**

```text
/cmd/api          # 入口点 (Echo server)
/ent              # Ent 生成的代码 & schema 定义
/internal
  /domain         # 领域模型 & 接口
  /app            # 应用逻辑 (Use Cases)
  /adapter        # 驱动适配器 (Ent 的 Repo 实现等)
  /port           # 驱动端口 (Echo Handlers)
/pkg              # 公共共享库
```

**注意:** 初始化将从建立标准目录结构和配置基础依赖（Echo + Ent + Atlas + Viper）开始。

## 核心架构决策

### 决策优先级分析

**关键决策 (阻碍实施):**
*   认证鉴权方案 (Self-hosted JWT + Multi-Provider Adapter)
*   积分一致性策略 (TCC + DB Transaction)
*   推送服务选型 (JPush/GeTui domestic + Abstracted Interface)

**重要决策 (塑造架构):**
*   API 通信风格 (RESTful JSON)
*   权限控制模型 (RBAC)

### 认证与安全 (Authentication & Security)

*   **决策**: **自建 JWT 认证中心 + 多供应商适配 (SMS/Social)**
    *   **核心逻辑**: Go 后端实现 JWT 签发、验证、黑名单逻辑，不强依赖特定云厂商的 Auth 服务。
    *   **短信验证码**: 设计 `SmsProvider` 接口。
        *   **MVP/国内**: 实现阿里云/腾讯云适配器。
        *   **出海/未来**: 实现 Twilio/Firebase Adapter。
    *   **社交登录**: 设计 `OAuthProvider` 接口。
        *   **MVP**: 预留微信登录接口。
        *   **出海/未来**: 增加 Google/Apple Sign-in 实现。
    *   **理由**: 保证国内用户体验（手机号+验证码是主流），同时通过适配器模式为未来出海留出灵活切换空间，避免被单一厂商锁定。

### 数据架构 (Data Architecture)

*   **积分一致性**: **TCC 思想 + 数据库本地事务**
    *   **实现**: 所有的积分变更操作（加/减）必须在同一个数据库事务中完成：
        1.  插入 `point_logs`（流水表）。
        2.  更新 `member_summaries`（余额表）。
    *   **实体关系**: 利用 Ent 的 Graph 能力处理 `User -> Group -> MemberSummary` 的级联关系。

### API 与通信模式 (API & Communication)

*   **风格**: **RESTful + JSON**
    *   **理由**: Echo 框架对 REST 支持极好，Flutter 端调试和集成最为成熟简单。
    *   **规范**: 使用标准 HTTP 状态码，统一的 JSON 错误响应结构。

### 基础设施与部署 (Infrastructure)

*   **推送通知**: **极光推送 (JPush) / 个推 (GeTui)**
    *   **MVP**: 使用免费版 SDK 集成。
    *   **架构**: 后端设计 `NotificationService` 接口，初期实现 `JPushAdapter`，封装“单推”、“群推”、“标签推”等方法。
    *   **未来**: 出海时增加 `FCMAdapter` 实现，通过配置开关或用户区域判断走哪个通道。
    *   **理由**: 确保国内 Android 机型的送达率（厂商通道集成），免费额度足够 MVP 验证。

### 决策影响分析

**实施顺序:**
1.  **基础**: 搭建 Echo + Ent 后端骨架，集成 JWT 中间件。
2.  **核心**: 实现 Group/User 实体及关联关系（Ent Schema）。
3.  **业务**: 实现积分流水记录与事务更新逻辑。
4.  **适配器**: 实现阿里云短信接口与极光推送接口。
5.  **客户端**: 初始化 Very Good Core 项目，对接 API。

## 实施模式与一致性规则

### 命名模式

**数据库命名规范 (PostgreSQL + Ent):**
*   **表名**: 复数 + Snake Case (e.g., `users`, `point_logs`).
*   **主键/外键**: `id` 作为主键, `xxx_id` 作为外键 (e.g., `user_id`, `group_id`). *强制检查: 不使用 `fk_user` 这种形式*.
*   **字段**: `snake_case` (e.g., `created_at`).

**API 命名规范 (RESTful):**
*   **资源路径**: 复数名词 (e.g., `/v1/users`, `/v1/groups`).
*   **JSON 字段**: `snake_case` (e.g., `{"user_id": 123, "display_name": "John"}`).
    *   *理由*: 与后端 Go 的 Struct Tag 保持一致，通过 `json_serializable` 处理 Dart 的转换。

**代码命名规范 (Flutter):**
*   **文件名**: `snake_case.dart`.
*   **类名**: `PascalCase`.
*   **变量/方法**: `camelCase`.

### 结构模式

**项目组织 (Feature-First Architecture):**

基于 2025 Flutter 最佳实践，我们将采用 **Feature-First (按功能特性)** 的目录结构。

```text
lib/
  app/              # 全局应用配置 (Routes, Theme, AppWidget)
  features/         # 业务模块
    login/          # 登录模块
      bloc/         # 状态管理
      view/         # UI 页面
      widgets/      # 模块私有组件
      login_page.dart
    home/
    agreement/
  shared/           # 共享代码
    api/            # API Client
    models/         # 全局数据模型
    widgets/        # 全局通用 UI 组件
```

**后端结构 (Modular Monolith):**
遵循 Golang Standard Layout，按业务域划分 `internal/app` 下的 usecase。

### 通信模式

**API 响应格式 (扁平化):**
*   **成功**: 200/201 + 纯数据 JSON.
*   **失败**: 400/401/500 + 错误对象.
    ```json
    {
      "code": "ERR_INSUFFICIENT_FUNDS",
      "message": "积分不足，无法兑换",
      "details": { "current": 100, "required": 200 }
    }
    ```

**状态管理 (BLoC):**
*   **Event**: 动词+名词 (e.g., `LoadAgreements`, `CreateRule`).
*   **State**: 状态名词 (e.g., `AgreementsLoading`, `AgreementsLoaded`, `AgreementsError`).

### 强制执行指南

**所有 AI Agents 必须遵守:**
1.  **JSON 字段必须用 snake_case**，禁止在 API 层混合使用驼峰。
2.  **Flutter 新功能必须在 features/ 下新建目录**，禁止把所有页面堆在 screens/ 下。
3.  **数据库变更必须通过 Ent Schema 定义**，禁止手写 SQL 建表。
4.  **业务逻辑必须写在 BLoC 或 Backend Usecase 层**，禁止写在 UI Widget 或 Controller 中。

## 项目结构与边界

### 完整项目目录结构

**1. Flutter 客户端 (Feature-First Structure)**

```text
way2we_app/
├── lib/
│   ├── app/                    # 全局应用级配置
│   │   ├── view/               # App 入口 (MaterialApp)
│   │   ├── router/             # 全局路由定义 (GoRouter)
│   │   ├── theme/              # UX 定义的设计系统 (Colors, Typography)
│   │   └── l10n/               # 国际化资源 (.arb)
│   │
│   ├── core/                   # 核心基础层 (非业务相关)
│   │   ├── network/            # Dio Client, Interceptors
│   │   ├── storage/            # SecureStorage 封装
│   │   ├── di/                 # 依赖注入 (get_it)
│   │   └── error/              # 错误处理与 Failure 定义
│   │
│   ├── features/               # 业务功能模块 (在此处新增 Epic 对应的目录)
│   │   ├── auth/               # [Example] 认证模块
│   │   │   ├── bloc/           # AuthBloc (状态)
│   │   │   ├── data/           # AuthRepository & Providers (API 调用)
│   │   │   └── view/           # Login/Register UI
│   │   │
│   │   └── [feature_name]/     # [Template] 新增业务模块标准结构
│   │       ├── bloc/           # 模块状态管理
│   │       ├── data/           # 模块数据层 (Models, Providers, Repo Impl)
│   │       ├── view/           # 模块 UI 页面
│   │       └── widgets/        # 模块私有组件
│   │
│   ├── shared/                 # 跨模块共享 (Components, Models)
│   │   ├── widgets/            # 通用 UI (Buttons, Cards, Badges)
│   │   └── models/             # 全局通用 Model (User, Group)
│   │
│   ├── bootstrap.dart          # 启动初始化逻辑
│   └── main_development.dart   # 入口 (Flavor)
├── pubspec.yaml
└── analysis_options.yaml
```

**2. Go 服务端 (Modular Monolith)**

```text
way2we_api/
├── cmd/
│   └── api/                    # 主程序入口
│       └── main.go
│
├── ent/                        # Ent 自动生成的代码 (Schema & Client)
│   ├── schema/                 # 数据库定义 (User, Group, Rule, PointLog)
│   └── generate.go
│
├── internal/
│   ├── app/                    # 应用逻辑 (Use Cases / Services)
│   │   ├── auth/               # [Example] 认证业务逻辑
│   │   └── [domain_name]/      # [Template] 新增业务域逻辑
│   │
│   ├── adapter/                # 驱动适配器 (外部依赖)
│   │   ├── handler/            # Echo HTTP Handlers (Controller)
│   │   ├── repo/               # 数据仓储实现 (基于 Ent Client)
│   │   ├── sms/                # 短信发送适配器 (Aliyun/Tencent)
│   │   └── push/               # 推送适配器 (JPush)
│   │
│   └── pkg/                    # 内部核心包 (Utils, Configs)
│       ├── config/             # 配置加载 (Viper)
│       └── middleware/         # Echo 中间件 (JWT, CORS, Logger)
│
├── pkg/                        # 可被外部引用的公共库 (如有)
├── configs/                    # 配置文件 (yaml)
├── Dockerfile
├── go.mod
└── makefile
```

### 架构边界定义

**API 边界 (API Boundaries):**
*   **外部 API**: 通过 `internal/adapter/handler` 暴露 RESTful 接口。
*   **认证边界**: `internal/pkg/middleware` 中的 JWT 中间件负责在进入 Handler 前拦截未授权请求。

**组件边界 (Component Boundaries):**
*   **Feature 隔离**: `features/` 下的每个模块应尽量独立。
*   **共享组件**: 通用 UI 组件（如按钮、卡片）必须放在 `shared/widgets`，严禁直接引用其他 Feature 的私有 Widget。

**服务边界 (Service Boundaries):**
*   **Use Cases**: `internal/app/` 下的 Service 只负责纯业务逻辑，不直接操作 HTTP 或 Database，而是依赖 Interface。
*   **Repository**: `internal/adapter/repo` 负责具体的数据存取实现。

### 映射关系 (Mapping)

*   **Epic/Feature 映射**:
    *   当开发新的 Epic (如 "积分商城") 时，应在客户端建立 `lib/features/mall/`，在服务端建立 `internal/app/mall/`。
*   **跨切面映射**:
    *   **认证**: `lib/features/auth/` (Login UI) + `internal/app/auth/` (Token Logic)。
    *   **基础**: `lib/core/` (Network, DI) + `internal/pkg/` (Config, Middleware)。

## 架构验证结果 (Architecture Validation)

### 连贯性验证 (Coherence) ✅

**决策兼容性:**
*   **前后端架构**: Go (Modular Monolith) 与 Flutter (Feature-First) 均采用模块化思想，理念一致，便于特征团队 (Feature Team) 并行开发。
*   **API 协议**: 选择 RESTful + JSON (Snake Case) 完美适配 Go Struct Tag 和 Dart 的 `json_serializable`，消除了前后端命名风格转换的痛点。
*   **技术栈**: Echo + Ent 的组合在类型安全和图关系处理上表现优异，弥补了传统 ORM 在处理复杂关系（如 User-Group-Rule）时的不足。

**模式一致性:**
*   **Feature-First**: 无论前端 `lib/features/` 还是后端 `internal/app/`，都以业务领域为核心组织代码，降低了认知负荷。
*   **命名规范**: 统一的 `snake_case` 数据库字段和 JSON 字段，避免了不必要的转换层。

### 需求覆盖度验证 (Coverage) ✅

**Epic 覆盖:**
*   **约定管理/积分账本**: 均能在 `features/` 和 `internal/app/` 中找到明确的对应位置。
*   **多租户**: Ent 的 Graph Schema 原生支持多对多关系，能轻松实现 User-Group 和细粒度 RBAC。

**功能需求:**
*   **积分一致性**: 通过架构决策中的 "TCC + DB Transaction" 明确了解决方案，且 Ent 支持事务。
*   **推送通知**: 架构中预留了 `NotificationService` 接口和 Adapter 层，支持从 JPush 到 FCM 的平滑切换。

### 可实施性评估 (Readiness) ✅

**决策完备性:**
*   所有关键技术栈（Echo, Ent, Flutter IOC, BLoC）均已选定。
*   第三方服务（Aliyun SMS, JPush）已明确，接口已抽象。

**结构清晰度:**
*   提供了精确到文件层级的目录树，以及初始化命令。
*   明确了 "What goes where" 的规则，能有效防止代码乱放。

### 架构就绪评估

**整体状态: READY FOR IMPLEMENTATION**

**关键优势:**
1.  **高度模块化**: 适合未来扩展。
2.  **类型安全**: 端到端（Database -> Go -> API -> Flutter）的强类型约束。
3.  **可维护性**: 清晰的 Layered Architecture + Clean Architecture 思想。

**未来优化点 (Post-MVP):**
1.  **CI/CD Pipeline**: 目前仅预配置了 Github Actions，未来需加入自动化测试和部署脚本。
2.  **可观测性**: 需集成 Prometheus + Grafana 以监控 API 指标 (Echo 中间件支持)。

### 实施交接指南

**AI Agent 准则:**
1.  **严守结构**: 任何新功能必须遵循 Feature-First 目录结构，不得创建 `lib/screens` 等传统目录。
2.  **接口优先**: 在编写具体 Adapter 实现前，必须先定义 Go Interface 或 Dart Abstract Class。
3.  **命名一致**: 数据库和 API 必须使用 `snake_case`。
