# Story 6.1: 兑换订单全生命周期（下单-扣分-履约-确认-激励-追踪）

Status: in-progress

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

## Story

As a **群组成员（消费方/提供方）**,
I want **用积分兑换商品并完成履约与确认**,
so that **兑换闭环稳定可追溯，积分扣减与提供者激励正确入账，并能查看订单状态与历史**.

## Acceptance Criteria

### 1) 发起兑换（创建订单 + 扣减积分）

**Given** 我在商品详情页点击“兑换”  
**When** 我选择数量（默认 1，最小 1）并确认  
**Then** 系统校验商品属于当前群组且为 `active`  
**And** 计算总价 `total_cost_points = reward.cost_points * quantity`  
**And** 若积分不足则返回“积分不足”，不创建订单、不扣分  
**And** 若积分足够则创建订单并扣减积分（points.DeductPoints）  
**And** “创建订单 + 扣分”必须在同一 DB 事务内完成（避免订单存在但未扣分，或扣分成功但订单失败）  

### 2) 自动履约 / 自动完成规则（来自 Reward）

**Given** reward.auto_fulfill = true  
**When** 订单创建成功  
**Then** 订单直接进入 `awaiting_confirm`（等同于已履约）并写入 `fulfilled_at`  

**Given** reward.auto_complete = true  
**When** 订单进入“已履约”（无论自动或手动）  
**Then** 订单直接进入 `completed`，无需消费方确认  
**And** 若群组设置了提供者激励比例，则立即给提供者加激励积分（见 AC 5）

### 3) 提供方履约

**Given** 我是订单提供方且订单状态为 `awaiting_fulfill`  
**When** 我点击“已履约”  
**Then** 订单状态变为 `awaiting_confirm` 并记录 `fulfilled_at`  
**And** 通知消费方确认

### 4) 消费方确认满意 / 不满意

**Given** 我是订单消费方且订单状态为 `awaiting_confirm`  
**When** 我点击“确认满意”  
**Then** 订单状态变为 `completed` 并记录 `confirmed_at`  
**And** 若群组设置了提供者激励比例，则给提供者加激励积分（见 AC 5）  

**Given** 我是订单消费方且订单状态为 `awaiting_confirm`  
**When** 我点击“不满意”（可选填写原因）  
**Then** 订单状态变为 `unsatisfied` 并记录 `ended_at`  
**And** 保留订单记录供查看  
**And** 提供者不获得激励积分  
**And** 不自动退回消费方积分（撤销/回退由 Epic 8 处理）

### 5) 提供者激励积分（provider_incentive_ratio）

**Given** 订单进入 `completed`  
**When** 群组 `provider_incentive_ratio` > 0  
**Then** 计算 `incentive = floor(total_cost_points * ratio / 100)`（整数向下取整）  
**And** incentive = 0 时不入账  
**And** incentive > 0 时调用 points.AddPoints 给 provider 入账  
**And** 入账 source 需可幂等（避免重复发放）  

### 6) 订单列表与详情（状态追踪）

**Given** 我在“我的订单”页  
**When** 页面加载  
**Then** 返回与我相关的订单列表（我是消费方或提供方）  
**And** 订单按时间倒序，显示：商品名、数量、总价、状态、时间  

**Given** 我进入订单详情  
**Then** 显示：商品信息、数量、单价、总价、消费方、提供方、当前状态  
**And** 显示状态时间线：创建时间、履约时间、确认时间/结束时间  

### 7) 权限与安全

- 所有接口必须走 JWT，并校验用户是该群组成员
- 状态变更权限：
  - 仅 provider 可履约
  - 仅 consumer 可确认满意/不满意
- 订单读取权限：仅相关方（consumer/provider）或群组管理员可查看

## Tasks / Subtasks

### Backend（Go / Echo / Ent）

- [x] **Ent: 新增 RedemptionOrder Schema**（AC: 1-7）
  - [x] 新增 `way2we_api/ent/schema/redemption_order.go`
  - [x] 字段建议（尽量快照化，避免 reward 价格/提供方变化影响历史）：
    - `group_id`
    - `reward_id`
    - `consumer_id`（下单人）
    - `provider_id`（从 reward.provider_id 快照）
    - `quantity`
    - `unit_cost_points`（从 reward.cost_points 快照）
    - `total_cost_points`（unit * quantity）
    - `status`（enum：`awaiting_fulfill` / `awaiting_confirm` / `completed` / `unsatisfied`）
    - `auto_fulfill` / `auto_complete`（从 reward 快照）
    - `provider_incentive_ratio`（从 group.settings 快照）
    - `created_at`, `fulfilled_at`, `confirmed_at`, `ended_at`, `updated_at`
    - `unsatisfied_reason`（可选，<=200）
  - [x] 索引：
    - `(group_id, consumer_id, created_at)`
    - `(group_id, provider_id, created_at)`
    - `(group_id, status, created_at)`
  - [x] 运行 `go generate ./ent`

- [x] **Service: RedemptionService（状态机 + 事务一致性）**（AC: 1-5,7）
  - [x] 新增 `way2we_api/internal/app/redemption/service.go`
  - [x] `CreateOrder(ctx, groupID, rewardID, consumerID, quantity) (*Order, error)`
    - 校验 reward active + belongs to group
    - 查询 `points.GetBalance` 并校验余额足够（或在事务内校验并扣分）
    - 事务内：创建 order + points.DeductPoints（source_type=`redemption_order_cost`, source_id=orderID）
    - auto_fulfill/auto_complete：在创建阶段内推进状态并写入时间戳
  - [x] `MarkFulfilled(ctx, groupID, orderID, providerID) error`
  - [x] `ConfirmSatisfied(ctx, groupID, orderID, consumerID) error`
    - 事务内：更新状态 + 发放 provider incentive（若需要）
  - [x] `MarkUnsatisfied(ctx, groupID, orderID, consumerID, reason) error`
  - [x] `ListMyOrders(ctx, groupID, requesterID, roleFilter?, statusFilter?, limit, offset)`
  - [x] `GetOrder(ctx, groupID, orderID, requesterID)`
  - [x] points source 约定（建议）：
    - 扣分：`source_type=redemption_cost`, `source_id=orderID`
    - 激励：`source_type=redemption_incentive`, `source_id=orderID`

- [x] **API: Order Handler + Routes**（AC: 1-7）
  - [x] 新增 `way2we_api/internal/adapter/handler/redemption_handler.go`
  - [x] 路由建议：
    - `POST /v1/groups/:groupId/rewards/:rewardId/redemptions`（创建订单）
    - `GET /v1/groups/:groupId/orders`（我的订单列表，可选 status/role）
    - `GET /v1/groups/:groupId/orders/:id`（详情）
    - `POST /v1/groups/:groupId/orders/:id/fulfill`
    - `POST /v1/groups/:groupId/orders/:id/confirm`
    - `POST /v1/groups/:groupId/orders/:id/unsatisfied`
  - [x] 错误码建议：
    - `ERR_INSUFFICIENT_POINTS`
    - `ERR_ORDER_NOT_FOUND`
    - `ERR_REWARD_INACTIVE`
    - `ERR_NOT_ORDER_CONSUMER` / `ERR_NOT_ORDER_PROVIDER`

- [x] **测试（后端）**
  - [x] CreateOrder：积分不足不创建、原子扣分、auto_fulfill/auto_complete 状态正确
  - [x] Confirm：激励计算（含 ratio=0/小数舍入）、幂等不重复发放
  - [x] 权限：provider/consumer 角色校验

### Frontend（Flutter / BLoC / Dio）

- [x] **Feature: redemption / order**（AC: 1-6）
  - [x] Provider：
    - `createRedemption(groupId, rewardId, quantity)`
    - `listOrders(groupId, {status, role, limit, offset})`
    - `getOrderDetail(groupId, orderId)`
    - `fulfillOrder(groupId, orderId)`
    - `confirmOrder(groupId, orderId)`
    - `markUnsatisfied(groupId, orderId, {reason})`
  - [x] BLoC：
    - 下单流程（积分不足 UI 置灰/提示）
    - 订单列表与详情加载
    - provider/consumer 不同操作按钮渲染
  - [x] UI：
    - RewardDetail 兑换确认对话框（数量选择 + 总价）
    - 我的订单列表页
    - 订单详情页（时间线）

### Review Follow-ups (AI)
- [x] [AI-Review][HIGH] 将余额校验与扣分合并到同一事务内（例如在事务内锁定/校验余额或用条件更新防止负余额），避免并发下“余额足够但实际透支”导致订单仍创建成功。 [way2we_api/internal/app/redemption/service.go:84]
- [x] [AI-Review][MEDIUM] CreateRedemption 对 quantity=0 目前会默认为 1，建议改为直接返回数量无效，避免客户端错误被静默吞掉。 [way2we_api/internal/adapter/handler/redemption_handler.go:145]
- [x] [AI-Review][MEDIUM] 补充 MarkFulfilled/MarkUnsatisfied 成功路径与状态时间戳（fulfilled_at/ended_at）测试，覆盖 AC 3/4 正向流程。 [way2we_api/internal/app/redemption/service_test.go]
- [ ] [AI-Review][MEDIUM] git 发现 _bmad-output/project-planning-artifacts/epics.md 有变更但未记录在 Story File List，补充或移除该变更记录以保持可追溯性。 [_bmad-output/project-planning-artifacts/epics.md]
- [x] [AI-Review][LOW] 余额获取失败时仍可提交兑换，建议禁用确认按钮或提示“继续尝试会由后端校验”，减少用户困惑。 [way2we_app/lib/features/reward/view/reward_detail_page.dart:295]

## Dev Notes

### Order State Machine

- `awaiting_fulfill` → `awaiting_confirm`（provider fulfill 或 auto_fulfill）
- `awaiting_confirm` → `completed`（consumer confirm 或 auto_complete）
- `awaiting_confirm` → `unsatisfied`（consumer mark unsatisfied）

### Transaction & Idempotency（关键）

- CreateOrder 必须保证“订单创建 + 扣分”一致性
- 完成激励必须幂等（`source_type=redemption_incentive + source_id=orderID`）
- “并发确认”不得重复发激励积分

### References

- [Source: _bmad-output/project-planning-artifacts/epics.md#Epic-6-兑换与履约流程]
- [Source: _bmad-output/project-planning-artifacts/ux-design-specification.md#兑换商品]
- [Source: _bmad-output/architecture.md#积分一致性]
- [Source: _bmad-output/implementation-artifacts/4-1-reward-management.md#Dev-Notes]
- [Source: _bmad-output/implementation-artifacts/2-4-group-default-configuration.md#与后续-Story-的关系]
- [Source: way2we_api/internal/app/points/service.go]

## Dev Agent Record

### Implementation Plan
1. 新增兑换订单 Ent Schema 并生成代码，补齐后端服务/路由/处理器。
2. 实现兑换订单状态机与积分扣减/激励幂等逻辑，并补齐后端测试。
3. 前端新增兑换订单 Provider、BLoC 与页面，接入“我的订单”和兑换确认对话框。

### Debug Log
- 2026-02-01: `go test ./...` ✅
- 2026-02-01: `go test ./internal/app/redemption` ✅
- 2026-02-01: `go test ./internal/app/points ./internal/app/redemption` ✅
- 2026-02-01: `flutter test` ✅

### Completion Notes
- 完成兑换订单 Schema、服务层状态机、API 处理器与路由接入。
- 添加 Create/Confirm/权限与并发确认幂等测试用例。
- 前端新增兑换入口、订单列表与详情页、时间线展示与角色操作按钮。

## File List
- _bmad-output/implementation-artifacts/6-1-redemption-order-lifecycle.md
- _bmad-output/implementation-artifacts/sprint-status.yaml
- way2we_api/cmd/api/main.go
- way2we_api/ent/client.go
- way2we_api/ent/ent.go
- way2we_api/ent/hook/hook.go
- way2we_api/ent/migrate/schema.go
- way2we_api/ent/mutation.go
- way2we_api/ent/predicate/predicate.go
- way2we_api/ent/runtime.go
- way2we_api/ent/tx.go
- way2we_api/ent/redemptionorder.go
- way2we_api/ent/redemptionorder_create.go
- way2we_api/ent/redemptionorder_delete.go
- way2we_api/ent/redemptionorder_query.go
- way2we_api/ent/redemptionorder_update.go
- way2we_api/ent/redemptionorder/redemptionorder.go
- way2we_api/ent/redemptionorder/where.go
- way2we_api/ent/schema/redemption_order.go
- way2we_api/internal/adapter/handler/redemption_handler.go
- way2we_api/internal/adapter/handler/router.go
- way2we_api/internal/app/points/service.go
- way2we_api/internal/app/redemption/service.go
- way2we_api/internal/app/redemption/service_test.go
- way2we_app/lib/app/view/app.dart
- way2we_app/lib/features/home/view/home_page.dart
- way2we_app/lib/features/reward/view/reward_detail_page.dart
- way2we_app/lib/features/redemption/data/models/redemption_order.dart
- way2we_app/lib/features/redemption/data/models/redemption_order.g.dart
- way2we_app/lib/features/redemption/data/providers/redemption_provider.dart
- way2we_app/lib/features/redemption/bloc/create/redemption_create_bloc.dart
- way2we_app/lib/features/redemption/bloc/create/redemption_create_event.dart
- way2we_app/lib/features/redemption/bloc/create/redemption_create_state.dart
- way2we_app/lib/features/redemption/bloc/list/redemption_list_bloc.dart
- way2we_app/lib/features/redemption/bloc/list/redemption_list_event.dart
- way2we_app/lib/features/redemption/bloc/list/redemption_list_state.dart
- way2we_app/lib/features/redemption/bloc/detail/redemption_detail_bloc.dart
- way2we_app/lib/features/redemption/bloc/detail/redemption_detail_event.dart
- way2we_app/lib/features/redemption/bloc/detail/redemption_detail_state.dart
- way2we_app/lib/features/redemption/view/redemption_order_list_page.dart
- way2we_app/lib/features/redemption/view/redemption_order_detail_page.dart
- way2we_app/lib/l10n/arb/app_en.arb
- way2we_app/lib/l10n/arb/app_zh.arb
- way2we_app/lib/l10n/gen/app_localizations.dart
- way2we_app/lib/l10n/gen/app_localizations_en.dart
- way2we_app/lib/l10n/gen/app_localizations_zh.dart

## Change Log
- 2026-02-01: 完成 6-1 兑换订单全生命周期（后端 Ent/服务/API + 前端兑换/订单页面 + 测试）
