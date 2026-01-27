# Story 4.1: 商品管理

Status: done

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

## Story

As a **群组成员和商品提供者**,
I want **查看商品列表、创建、编辑和停用商品（兑换项）**,
So that **我可以完整管理我提供的商品并让成员知道有哪些商品可以兑换**.

## Acceptance Criteria

### 查看商品列表

**Given** 用户在某群组中  
**When** 进入“兑换/商品”入口  
**Then** 显示商品列表（卡片式）  
**And** 每个卡片显示：名称、积分价格、封面图、提供者  

**Given** 群组中没有商品  
**When** 进入商品列表  
**Then** 显示空状态「还没有商品，添加一个奖励」  

### 创建商品

**Given** 用户在商品列表页  
**When** 点击“创建商品”  
**Then** 显示创建商品表单  

**Given** 用户在创建商品表单中  
**When** 填写名称（必填）、描述（可选）、积分价格（必填，正整数）  
**Then** 可以配置：是否自动履约、是否自动完成（需消费方确认满意）  
**And** 可以上传封面图片（可选）  
**And** 创建者自动成为该商品的提供者  

**Given** 用户提交商品表单  
**When** 所有必填项已填写且合法  
**Then** 商品创建成功  
**And** 显示成功提示  

### 编辑商品

**Given** 用户是商品的提供者（或群组管理员）  
**When** 在商品详情页点击“编辑”  
**Then** 显示编辑表单并预填当前值  

**Given** 用户修改并保存  
**When** 点击“保存”  
**Then** 商品更新成功  

**Given** 用户不是商品提供者且非管理员  
**When** 查看商品详情  
**Then** 不显示“编辑”按钮  

### 停用与启用商品

**Given** 用户是商品提供者（或群组管理员）且商品处于启用状态  
**When** 点击“停用”  
**Then** 商品状态变为停用  
**And** 商品从主列表移除（默认不展示停用商品）  
**And** 将来的进行中订单不受影响（为 Epic 6 预留）  

**Given** 商品处于停用状态  
**When** 点击“启用”  
**Then** 商品恢复显示

## Tasks / Subtasks

### Backend（Go / Echo / Ent）

- [x] **Ent: 新增 Reward Schema**（AC: 创建/编辑/停用商品）
  - [x] 新增 `way2we_api/ent/schema/reward.go`
    - 字段建议：
      - `name`（必填，1-50）
      - `description`（可选，0-200）
      - `cost_points`（必填，正整数，1-99999）
      - `cover_image_url`（可选）
      - `status`（enum: `active` / `inactive`，默认 `active`）
      - `auto_fulfill`（bool，默认来自群组默认配置）
      - `auto_complete`（bool，默认来自群组默认配置）
      - `group_id`（FK）
      - `provider_id`（FK，创建者即提供方）
      - `created_at` / `updated_at`
    - 索引：`(group_id)`、`(group_id, status)`
  - [x] 运行 `go generate ./ent`

- [x] **Service: Reward 业务逻辑**（AC: 列表/创建/编辑/停用与启用）
  - [x] 新增 `way2we_api/internal/app/reward/service.go`
  - [x] 访问控制：
    - 任意群组成员：可查看商品列表
    - 商品提供者（provider_id）或群组管理员：可编辑/停用/启用
    - 创建：任意群组成员可创建（创建者即提供方）
  - [x] 默认值（来自 Story 2.4 群组默认配置）：
    - 若请求未传 `auto_fulfill/auto_complete`，则分别使用：
      - `Group.auto_fulfill_redemption_default`
      - `Group.auto_complete_redemption_default`
  - [x] 校验：
    - `name` 非空、≤50
    - `description` ≤200
    - `cost_points` 1-99999
    - `status` 仅允许 `active|inactive`

- [x] **API: Reward Handler + Routes**（AC: 列表/创建/编辑/停用与启用）
  - [x] 新增 `way2we_api/internal/adapter/handler/reward_handler.go`
  - [x] 注册路由（参考 `way2we_api/internal/adapter/handler/router.go`）：
    - `GET /v1/groups/:groupId/rewards`（可选 `status=active|inactive`，默认 `active`）
    - `POST /v1/groups/:groupId/rewards`
    - `GET /v1/groups/:groupId/rewards/:id`
    - `PUT /v1/groups/:groupId/rewards/:id`
    - `PUT /v1/groups/:groupId/rewards/:id/status`
  - [x] 响应字段使用 `snake_case`（参考 `_bmad-output/architecture.md#通信模式`）
  - [x] 错误码参考现有 Handler（例如 `ERR_INVALID_GROUP_ID`、`ERR_UNAUTHORIZED`）

- [x] **API: 封面图片上传（Reward Cover Upload）**（AC: 上传封面图片）
  - [x] 在 `way2we_api/internal/adapter/handler/router.go` 的 `/v1/uploads` 下新增：
    - `POST /v1/uploads/reward-cover`
  - [x] 复用 `way2we_api/internal/pkg/validator/ValidateImageFile` 与 `storageProvider.Upload`
  - [x] 表单字段：`cover`（multipart）
  - [x] 返回：`{ "url": "...", "key": "..." }`（与 avatar upload 保持一致）

- [x] **测试（后端）**
  - [x] Service 单测：创建/更新/状态切换权限校验（参考 `way2we_api/internal/app/agreement/*`）
  - [x] Handler 测试：list/create/update/status/upload（参考 `way2we_api/internal/adapter/handler/user_handler_test.go`）

### Frontend（Flutter / BLoC / Dio）

- [x] **Feature: reward 目录结构**（AC: 列表/创建/编辑/停用）
  - [x] 新增 `way2we_app/lib/features/reward/`（遵循 Feature-First：见 `_bmad-output/architecture.md#结构模式`）
    - `data/models/reward.dart`（`json_serializable`）
    - `data/providers/reward_provider.dart`
    - `bloc/list/reward_list_bloc.dart`（加载列表、刷新）
    - `bloc/form/reward_form_bloc.dart`（创建/编辑表单）
    - `view/reward_list_page.dart`
    - `view/create_reward_page.dart`
    - `view/edit_reward_page.dart`
    - `view/widgets/reward_card.dart`

- [x] **API Provider: RewardProvider**（AC: 列表/创建/编辑/停用与启用）
  - [x] `listRewards(groupId, {status})`
  - [x] `createReward(groupId, input)`
  - [x] `updateReward(groupId, rewardId, input)`
  - [x] `updateRewardStatus(groupId, rewardId, status)`
  - [x] `uploadRewardCover(XFile file) -> String url`（调用 `/v1/uploads/reward-cover`）

- [x] **UI: 列表页与空状态**（AC: 查看商品列表 + 空状态）
  - [x] 列表卡片展示：名称、积分价格、封面图、提供者（优先显示 provider.nickname）
  - [x] 空状态文案：「还没有商品，添加一个奖励」

- [x] **UI: 创建/编辑表单**（AC: 创建/编辑商品）
  - [x] 必填：名称、积分价格；可选：描述、封面
  - [x] 开关：自动履约、自动完成（默认值来自群组默认配置：Story 2.4）
  - [x] 图片选择：`image_picker` 选择后先上传再提交表单

- [x] **入口接入**
  - [x] 更新 `way2we_app/lib/features/home/view/home_page.dart`：
    - 将 “Rewards (Coming Soon)” 替换为可点击入口，跳转 `RewardListPage`
    - 文案与图标按 UX（兑换/商品）调整

- [x] **测试（前端）**
  - [x] Provider 单测（mock dio）
  - [x] BLoC 单测（列表加载/创建成功/失败、表单校验）

### Review Follow-ups (AI)

- [x] [AI-Review][HIGH] 修复封面上传 Content-Type，确保后端 `ValidateImageFile` 通过（`way2we_app/lib/features/reward/data/providers/reward_provider.dart#L192`）
- [x] [AI-Review][CRITICAL] 补齐后端上传校验测试：非法类型/超限用例（`way2we_api/internal/adapter/handler/reward_handler_test.go#L184`）
- [x] [AI-Review][CRITICAL] 补齐前端测试：Provider 错误映射与 BLoC 失败/校验用例（`way2we_app/test/features/reward/data/reward_provider_test.dart#L37`，`way2we_app/test/features/reward/bloc/reward_form_bloc_test.dart#L39`，`way2we_app/test/features/reward/bloc/reward_list_bloc_test.dart#L40`）
- [x] [AI-Review][MEDIUM] 补充商品详情页，允许非提供者查看详情并从详情进入编辑（`way2we_app/lib/features/reward/view/reward_detail_page.dart#L1`）

## Dev Notes

### Developer Context（实现前先读）

- 本 Story 仅实现「商品（Reward）管理」：列表/创建/编辑/停用启用 + 封面上传；兑换下单/履约/积分扣减属于 Epic 6/5，先不实现。
- 依赖已完成能力：
  - 群组上下文与成员权限（Epic 2）
  - 群组默认配置（Story 2.4）：创建商品时用于初始化/回填默认开关（自动履约/自动完成）。
- 重要一致性：现有 `Agreement` 已有 `cover_image_url` 字段与卡片展示方式，Reward 视觉与交互应尽量复用相同模式（减少 UX 不一致）。

### Technical Requirements（必须满足，避免后续灾难）

**Backend**
- 统一鉴权：所有 Reward API 必须走 JWT middleware（参考 `way2we_api/internal/adapter/handler/router.go`）。
- 列表默认只返回 `active`（避免“停用商品仍在主列表”的体验问题），如需查看停用商品用 `status=inactive`。
- 权限策略（最小可行且与需求一致）：
  - 任意群组成员可查看列表
  - 创建者即提供方（provider），可编辑/停用/启用
  - 群组管理员可编辑/停用/启用（兜底治理）
- 状态切换用 `PUT .../status`（与 Agreement 一致），不要做软删除/硬删除（为 Epic 6 订单/审计预留）。
- JSON 字段必须 `snake_case`，错误响应必须结构化 `{code,message,details}`（见 `_bmad-output/architecture.md#通信模式`）。

**Frontend**
- BLoC 结构与命名遵循现有风格（`AgreementListBloc` / `AgreementDetailBloc`），不要引入新状态管理框架。
- 封面上传流程：选择图片 → 上传获取 `url` → 将 `cover_image_url` 写入 create/update 请求；上传失败必须提示并阻止提交。
- 创建表单默认值：
  - `auto_fulfill`、`auto_complete` 初始值从群组默认配置读取（Story 2.4）。

### Architecture Compliance（必须遵循）

- 命名：DB/JSON 使用 `snake_case`；Flutter 文件名 `snake_case.dart`，类名 `PascalCase`（见 `_bmad-output/architecture.md#命名模式`）。
- 后端结构：新增业务域放 `way2we_api/internal/app/<domain>`；HTTP 层放 `way2we_api/internal/adapter/handler`（见 `_bmad-output/architecture.md#完整项目目录结构`）。
- 失败响应：请复用现有 handler 错误码风格（参考 `way2we_api/internal/adapter/handler/agreement_handler.go`）。

### Library / Framework Requirements（避免引入错误依赖）

- 后端继续使用现有栈：Echo v4、Ent v0.14.5（见 `way2we_api/go.mod`），不要为了“更现代”升级到 Echo v5（仍处于迁移窗口，且项目当前路由/中间件均为 v4）。
- 前端继续使用现有栈：Flutter SDK `^3.8.0`、`dio`、`flutter_bloc`、`json_serializable`（见 `way2we_app/pubspec.yaml`）。
- 图片上传：复用现有上传基础设施（`way2we_api/internal/adapter/storage/*` + `validator/ValidateImageFile` + `e.Static("/uploads", "uploads")`）。

### File Structure Requirements（建议落点，避免放错目录）

**Backend**
- `way2we_api/ent/schema/reward.go`
- `way2we_api/internal/app/reward/service.go`
- `way2we_api/internal/adapter/handler/reward_handler.go`
- `way2we_api/internal/adapter/handler/router.go`（注册 routes + upload route）
- `way2we_api/internal/pkg/validator/*`（仅复用；除非规格要求改变，不要改验证规则）

**Frontend**
- `way2we_app/lib/features/reward/**`
- `way2we_app/lib/app/view/app.dart`（如果需要注入 `RewardProvider`）
- `way2we_app/lib/features/home/view/home_page.dart`（入口接入）
- `way2we_app/lib/l10n/arb/app_zh.arb` / `app_en.arb`（新增 Reward 文案）

### Testing Requirements（最小覆盖，确保不回归）

**Backend**
- Service：成员校验、provider/admin 权限、status filter 默认 active、非法输入校验
- Handler：错误码映射（400/401/403/404）、创建/更新/状态切换成功路径
- Upload：非法文件类型/超限、成功返回 url/key

**Frontend**
- Provider：成功/失败解析、错误提示映射
- BLoC：列表加载与空状态、创建/编辑表单校验（名称空/积分非正）、上传失败阻止提交

### 最新技术信息（Web Research，2026-01-27）

- Echo：v5 已发布，但官方仍标注 v4 支持到 2026-12-31；本项目继续使用 v4 更稳妥（避免中间件/路由迁移成本）。
- Ent：0.14.5 为官方最新发布版本（与当前 `go.mod` 一致），无需升级。

### Project Context Reference

- 未找到 `project-context.md`（workflow 配置：`**/project-context.md`）；本 Story 以 `_bmad-output/project-planning-artifacts/*` 与现有代码为准。

### Story Completion Status（交付定义）

- 输出文件已生成：本 Story 文档状态为 `ready-for-dev`。
- 实现完成后（dev-story/code-review）：应将 `sprint-status.yaml` 中 `4-1-reward-management` 依流程推进到 `review` / `done`。

### Project Structure Notes

- **对齐项**：Feature-First（前端）、Modular Monolith（后端）与现有代码一致。
- **已存在偏差（请按现状实现，避免无关重构）**：
  - 架构文档提到 GoRouter/get_it，但当前 App 使用 `MaterialApp` + 自研 `ServiceLocator`（见 `way2we_app/lib/app/di.dart` 与 `way2we_app/lib/app/view/app.dart`）。
  - 因此 Reward 功能请沿用现有 DI/导航方式，不要在本 Story 引入 GoRouter/get_it。

### References

- Epic 需求源：`_bmad-output/project-planning-artifacts/epics.md`（Epic 4 / Story 4.1）
- UX 细节源：`_bmad-output/project-planning-artifacts/ux-design-specification.md`（“创建商品”“兑换商品”相关章节）
- 架构约束源：`_bmad-output/architecture.md`（命名模式 / 结构模式 / 通信模式 / 完整项目目录结构）
- 参考实现（Agreement）：`way2we_api/internal/app/agreement/service.go`、`way2we_api/internal/adapter/handler/agreement_handler.go`、`way2we_app/lib/features/agreement/*`
- 参考实现（上传）：`way2we_api/internal/adapter/handler/user_handler.go`（UploadAvatar）、`way2we_api/internal/adapter/storage/storage.go`

## Dev Agent Record

### Agent Model Used

GPT-5.2 (Codex CLI)

### Debug Log References
N/A
### Completion Notes List
- 已将需求/UX/架构约束整合进本 Story（含默认值策略与权限策略）。
- 已明确本 Story 范围不包含「兑换/订单/积分扣减」实现（留给 Epic 5/6）。
- 已给出对齐 Agreement 风格的 API 形态与图片上传复用方案。
- 已实现 Reward 实体/业务/接口与封面上传，完成权限与默认值逻辑。
- 已新增 Reward 前端 Feature（Provider/BLoC/UI）并接入首页入口与多语言。
- 已补充后端/前端单测；`go test ./...` 通过，`flutter test` 因权限错误未能执行。
- 已修复封面上传 Content-Type，补齐上传校验测试与前端失败/校验测试，并新增商品详情页入口。
### File List
- `_bmad-output/implementation-artifacts/sprint-status.yaml`
- `way2we_api/cmd/api/main.go`
- `way2we_api/ent/client.go`
- `way2we_api/ent/ent.go`
- `way2we_api/ent/group.go`
- `way2we_api/ent/group_create.go`
- `way2we_api/ent/group_query.go`
- `way2we_api/ent/group_update.go`
- `way2we_api/ent/group/group.go`
- `way2we_api/ent/group/where.go`
- `way2we_api/ent/hook/hook.go`
- `way2we_api/ent/migrate/schema.go`
- `way2we_api/ent/mutation.go`
- `way2we_api/ent/predicate/predicate.go`
- `way2we_api/ent/reward.go`
- `way2we_api/ent/reward_create.go`
- `way2we_api/ent/reward_delete.go`
- `way2we_api/ent/reward_query.go`
- `way2we_api/ent/reward_update.go`
- `way2we_api/ent/reward/reward.go`
- `way2we_api/ent/reward/where.go`
- `way2we_api/ent/runtime.go`
- `way2we_api/ent/tx.go`
- `way2we_api/ent/schema/group.go`
- `way2we_api/ent/schema/reward.go`
- `way2we_api/internal/app/reward/service.go`
- `way2we_api/internal/app/reward/service_test.go`
- `way2we_api/internal/adapter/handler/reward_handler.go`
- `way2we_api/internal/adapter/handler/reward_handler_test.go`
- `way2we_api/internal/adapter/handler/router.go`
- `way2we_app/lib/app/view/app.dart`
- `way2we_app/lib/features/home/view/home_page.dart`
- `way2we_app/lib/features/reward/bloc/form/reward_form_bloc.dart`
- `way2we_app/lib/features/reward/bloc/form/reward_form_event.dart`
- `way2we_app/lib/features/reward/bloc/form/reward_form_state.dart`
- `way2we_app/lib/features/reward/bloc/list/reward_list_bloc.dart`
- `way2we_app/lib/features/reward/bloc/list/reward_list_event.dart`
- `way2we_app/lib/features/reward/bloc/list/reward_list_state.dart`
- `way2we_app/lib/features/reward/data/models/reward.dart`
- `way2we_app/lib/features/reward/data/models/reward.g.dart`
- `way2we_app/lib/features/reward/data/providers/reward_provider.dart`
- `way2we_app/lib/features/reward/view/create_reward_page.dart`
- `way2we_app/lib/features/reward/view/edit_reward_page.dart`
- `way2we_app/lib/features/reward/view/reward_detail_page.dart`
- `way2we_app/lib/features/reward/view/reward_list_page.dart`
- `way2we_app/lib/features/reward/view/widgets/reward_card.dart`
- `way2we_app/lib/l10n/arb/app_zh.arb`
- `way2we_app/lib/l10n/arb/app_en.arb`
- `way2we_app/lib/l10n/gen/app_localizations.dart`
- `way2we_app/lib/l10n/gen/app_localizations_en.dart`
- `way2we_app/lib/l10n/gen/app_localizations_zh.dart`
- `way2we_app/test/features/reward/bloc/reward_form_bloc_test.dart`
- `way2we_app/test/features/reward/bloc/reward_list_bloc_test.dart`
- `way2we_app/test/features/reward/data/reward_provider_test.dart`

### Change Log
- 2026-01-27：完成 Reward 管理全链路（后端实体/服务/接口/上传 + 前端 Feature/入口/多语言），新增后端与前端测试。
- 2026-01-27：修复封面上传 Content-Type 与测试覆盖，新增商品详情页与失败用例测试。
