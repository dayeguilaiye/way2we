# Story 5.1: 约定完成全生命周期（状态机）

Status: review

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

## Story

As a **群组成员**,
I want **记录约定完成、处理待确认、确认/驳回，以及（有权限时）代他人记录**,
so that **约定从“可完成”到“积分入账/驳回”形成完整闭环，并为 Epic 8 撤销回退打好基础**.

## Acceptance Criteria

### 1) 记录完成（不需要确认）

**Given** 我在首页或约定列表看到某个启用中的约定  
**When** 我点击“记录”并确认  
**And** 该约定 `require_confirmation = false`  
**Then** 系统创建一条约定完成记录（状态为 `confirmed`）  
**And** 系统为完成者增加积分（delta = agreement.points）  
**And** 返回成功并可通过积分余额接口看到余额变动

### 2) 记录完成（需要确认）

**Given** 我点击“记录”并确认  
**And** 该约定 `require_confirmation = true`  
**Then** 系统创建一条约定完成记录（状态为 `pending`）  
**And** 不产生积分变动（不写 point_logs）  
**And** 返回“已提交，等待确认”

### 3) 待确认列表

**Given** 群组内存在 `pending` 的约定完成记录  
**When** 我进入“待处理/待确认”列表  
**Then** 能看到这些记录（按时间倒序）  
**And** 每条记录显示：约定名称、完成者、记录人、申请时间、积分值

### 4) 确认

**Given** 我是群组成员且我不是该记录的完成者  
**And** 存在一条 `pending` 的记录  
**When** 我点击“确认”  
**Then** 该记录状态变为 `confirmed`  
**And** 系统为完成者增加积分（写入 `point_logs` 且更新 `member_summaries`）  
**And** 该操作必须是原子的：不能出现“记录已确认但积分未入账”或相反

### 5) 驳回

**Given** 存在一条 `pending` 的记录  
**When** 我点击“驳回”并可选填写原因  
**Then** 该记录状态变为 `rejected`  
**And** 不产生积分变动  
**And** 驳回原因（如有）可被记录与返回

### 6) 代他人记录

**Given** 我拥有群组权限 `record_for_others`  
**When** 我在记录约定时选择另一个成员作为“完成者”并提交  
**Then** 系统创建记录，字段包含：完成者与记录人  
**And** 若该约定不需确认，则积分发放给被选择的完成者  
**And** 若需确认，则进入待确认，确认后再发放给完成者

### 7) 约束与校验

- 只能对 `active` 的约定创建新的完成记录
- 完成者必须是群组成员，且必须满足约定的 applicable_member_ids（为空表示全部成员可完成）
- 同一条 `pending` 记录只能被确认/驳回一次（并发请求不应产生重复积分入账）

## Tasks / Subtasks

### Backend（Go / Echo / Ent）

- [x] **Ent: 新增 AgreementCompletion Schema**（AC: 1-7）
  - [x] 新增 `way2we_api/ent/schema/agreement_completion.go`
  - [x] 字段建议（建议“快照化”，避免后续 agreement 被修改导致历史歧义）：
    - `group_id`（FK）
    - `agreement_id`（FK）
    - `completer_id`（完成者 user_id）
    - `recorder_id`（记录人 user_id）
    - `points`（int，记录当时的积分值快照）
    - `require_confirmation`（bool，记录当时是否需要确认的快照）
    - `status`（enum：`pending` / `confirmed` / `rejected`，默认 `pending`）
    - `rejected_reason`（可选，<=200）
    - `confirmed_by`（可选 user_id）
    - `confirmed_at` / `rejected_at`
    - `created_at` / `updated_at`
  - [x] 索引：
    - `(group_id, status, created_at)`
    - `(group_id, completer_id, created_at)`
  - [x] 运行 `go generate ./ent`

- [x] **Service: AgreementCompletionService（状态机 + 事务一致性）**（AC: 1-7）
  - [x] 新增 `way2we_api/internal/app/agreementcompletion/service.go`
  - [x] 关键方法：
    - `CreateCompletion(ctx, groupID, agreementID, recorderID, completerID) (*AgreementCompletion, error)`
    - `ListPending(ctx, groupID, requesterID, limit, offset) ([]*AgreementCompletion, error)`
    - `Confirm(ctx, groupID, completionID, confirmerID) error`
    - `Reject(ctx, groupID, completionID, rejecterID, reason) error`
  - [x] 权限与校验：
    - 创建：群组成员可创建；代记录需 `record_for_others`
    - 确认/驳回：群组成员可操作，但禁止完成者自确认
    - 约定必须属于该群组且为 `active`
    - applicable_member_ids 校验（空数组/空值表示全部）
  - [x] **原子性要求（最重要）**：
    - `Confirm` 必须在**一个 DB 事务**中完成：更新 completion 状态 + 调用 points 入账
    - 建议做法：让 `points.Service` 暴露一个“在已有 tx 中 applyPoints”的方法，避免双事务
  - [x] points source 约定：
    - `source_type`: `agreement_completion`
    - `source_id`: completionID（转 string）
    - `reason`: 可填入“确认约定完成：{agreement_id}”

- [x] **API: 完成记录与待确认接口**（AC: 1-7）
  - [x] 新增 `way2we_api/internal/adapter/handler/agreement_completion_handler.go`
  - [x] 路由建议（与现有 REST 风格一致）：
    - `POST /v1/groups/:groupId/agreements/:agreementId/completions`
      - body: `{ "completer_id": 123 }`（可选，默认当前用户）
    - `GET /v1/groups/:groupId/agreement-completions?status=pending&limit=&offset=`
    - `POST /v1/groups/:groupId/agreement-completions/:id/confirm`
    - `POST /v1/groups/:groupId/agreement-completions/:id/reject`（body: `{ "reason": "..." }` 可选）
  - [x] 返回字段使用 `snake_case`
  - [x] 错误码风格与现有 handler 对齐（400/401/403/404）

- [x] **测试（后端）**（AC: 1-7）
  - [x] Service：确认的事务原子性、禁止自确认、代记录权限、applicable_member_ids 校验、并发 confirm 不重复入账
  - [x] Handler：创建/列表/确认/驳回 + 错误码映射

### Frontend（Flutter / BLoC / Dio）

- [x] **Feature: agreement completion**（AC: 1-6）
  - [x] 在 `way2we_app/lib/features/agreement/` 下新增 completion 子模块（或与 agreement 复用同一 feature）
  - [x] Provider：
    - `createAgreementCompletion(groupId, agreementId, {completerId})`
    - `listPendingCompletions(groupId, {limit, offset})`
    - `confirmCompletion(groupId, completionId)`
    - `rejectCompletion(groupId, completionId, {reason})`
  - [x] BLoC：
    - 记录完成的提交状态与乐观反馈
    - 待确认列表加载、确认/驳回后刷新
  - [x] UI：
    - 约定卡片增加“记录”入口（复用 UX：确认对话框）
    - 待确认列表页（显示必要字段，提供 Confirm/Reject）

- [x] **测试（前端）**
  - [x] Provider 错误映射
  - [x] BLoC：提交成功/失败、确认/驳回状态流转

### Review Follow-ups (AI)

- [x] [AI-Review][HIGH] 允许 CreateCompletion 在空 body 时默认当前用户（避免 EOF 导致 400），并与客户端保持一致。[way2we_api/internal/adapter/handler/agreement_completion_handler.go:129]
- [x] [AI-Review][HIGH] RejectCompletion 允许空 body（reason 可选）或客户端始终发送 `{}`，避免 400。[way2we_api/internal/adapter/handler/agreement_completion_handler.go:359]
- [x] [AI-Review][MEDIUM] 待确认列表在当前用户是 completer 时禁用/隐藏确认按钮，避免 403 与误操作。[way2we_app/lib/features/agreement/completion/view/pending_completions_page.dart:264]
- [x] [AI-Review][MEDIUM] Story File List 补充未记录的改动文件（`_bmad-output/implementation-artifacts/5-0-points-ledger-foundation.md`, `_bmad-output/project-planning-artifacts/epics.md`）。[_bmad-output/implementation-artifacts/5-1-agreement-completion-lifecycle.md:195]

## Dev Notes

### State Machine

- `pending` → `confirmed`（入账）
- `pending` → `rejected`（不入账）
- `confirmed/rejected` 不允许再变更（撤销在 Epic 8 做，走 points.RevertPoints + completion 变更为 revoked 或记录撤销表）

### Implementation Pitfalls（容易出错的点）

- **双事务陷阱**：先把 completion 改 confirmed，再另起事务入账，失败会造成“确认了但没积分”——必须避免
- **并发确认**：两个确认请求同时到达，必须只入账一次（completion 状态更新要做条件更新，points 也有唯一约束兜底）
- **快照字段**：points/require_confirmation 建议快照化，否则 agreement 被改分会导致历史不一致

### References

- [Source: _bmad-output/project-planning-artifacts/epics.md#Epic-5-完成约定与积分获取]
- [Source: _bmad-output/project-planning-artifacts/ux-design-specification.md#记录完成约定]
- [Source: _bmad-output/architecture.md#积分一致性]
- [Source: way2we_api/internal/app/group/service.go#PermissionRecordForOthers]
- [Source: way2we_api/internal/app/points/service.go]

## Story Completion Status

- Status: review
- Note: 已完成约定完成全生命周期实现与测试，等待评审

## Dev Agent Record

### Agent Model Used

GPT-5 (Codex)

### Implementation Plan

- 新增 AgreementCompletion Ent Schema 与索引并生成 Ent 代码
- 实现 AgreementCompletionService（创建/列表/确认/驳回）与 points tx 内入账能力
- 新增 completion API handler 与路由并接入 main
- 前端新增 completion provider/BLoC 与待确认列表/记录完成入口
- 补齐前后端测试并执行全量测试

### Debug Log References

- `go run -mod=mod entgo.io/ent/cmd/ent generate ./ent/schema`
- `go test ./...`
- `flutter test`
- `go test ./internal/adapter/handler`

### Completion Notes List

- 新增 AgreementCompletion 数据模型与索引，生成 ent 代码
- AgreementCompletionService 实现状态机与单事务确认入账
- 新增 completion API（创建/列表/确认/驳回）并更新路由与 main 注入
- 前端完成记录入口、待确认列表页与 provider/BLoC
- 新增后端/前端测试并通过全量测试
- ✅ Resolved review finding [HIGH]: CreateCompletion 允许空 body 默认当前用户，避免 EOF 400
- ✅ Resolved review finding [HIGH]: RejectCompletion 允许空 body（reason 可选），避免 EOF 400
- 新增 CurrentUserRepository 统一解析并缓存 userId（基于 auth token）
- 待确认列表：当前用户为 completer 时禁用确认按钮
- ✅ Resolved review finding [MEDIUM]: 待确认列表禁用自确认按钮，避免 403 与误操作

### File List

- `_bmad-output/implementation-artifacts/5-1-agreement-completion-lifecycle.md`
- `_bmad-output/implementation-artifacts/5-0-points-ledger-foundation.md`
- `_bmad-output/project-planning-artifacts/epics.md`
- `_bmad-output/implementation-artifacts/sprint-status.yaml`
- `way2we_api/cmd/api/main.go`
- `way2we_api/ent/agreementcompletion.go`
- `way2we_api/ent/agreementcompletion_create.go`
- `way2we_api/ent/agreementcompletion_delete.go`
- `way2we_api/ent/agreementcompletion_query.go`
- `way2we_api/ent/agreementcompletion_update.go`
- `way2we_api/ent/agreementcompletion/agreementcompletion.go`
- `way2we_api/ent/agreementcompletion/where.go`
- `way2we_api/ent/client.go`
- `way2we_api/ent/ent.go`
- `way2we_api/ent/hook/hook.go`
- `way2we_api/ent/migrate/schema.go`
- `way2we_api/ent/mutation.go`
- `way2we_api/ent/predicate/predicate.go`
- `way2we_api/ent/runtime.go`
- `way2we_api/ent/tx.go`
- `way2we_api/ent/schema/agreement_completion.go`
- `way2we_api/internal/adapter/handler/agreement_completion_handler.go`
- `way2we_api/internal/adapter/handler/agreement_completion_handler_test.go`
- `way2we_api/internal/adapter/handler/router.go`
- `way2we_api/internal/app/agreementcompletion/service.go`
- `way2we_api/internal/app/agreementcompletion/service_test.go`
- `way2we_api/internal/app/points/service.go`
- `way2we_app/lib/app/di.dart`
- `way2we_app/lib/app/view/app.dart`
- `way2we_app/lib/core/session/current_user_repository.dart`
- `way2we_app/lib/features/agreement/completion/bloc/pending/pending_completions_bloc.dart`
- `way2we_app/lib/features/agreement/completion/bloc/pending/pending_completions_event.dart`
- `way2we_app/lib/features/agreement/completion/bloc/pending/pending_completions_state.dart`
- `way2we_app/lib/features/agreement/completion/bloc/record/agreement_completion_record_bloc.dart`
- `way2we_app/lib/features/agreement/completion/bloc/record/agreement_completion_record_event.dart`
- `way2we_app/lib/features/agreement/completion/bloc/record/agreement_completion_record_state.dart`
- `way2we_app/lib/features/agreement/completion/data/providers/agreement_completion_provider.dart`
- `way2we_app/lib/features/agreement/completion/models/agreement_completion.dart`
- `way2we_app/lib/features/agreement/completion/view/pending_completions_page.dart`
- `way2we_app/lib/features/agreement/view/agreement_list_page.dart`
- `way2we_app/lib/l10n/arb/app_en.arb`
- `way2we_app/lib/l10n/arb/app_zh.arb`
- `way2we_app/lib/l10n/gen/app_localizations.dart`
- `way2we_app/lib/l10n/gen/app_localizations_en.dart`
- `way2we_app/lib/l10n/gen/app_localizations_zh.dart`
- `way2we_app/test/features/agreement/completion/agreement_completion_provider_test.dart`
- `way2we_app/test/features/agreement/completion/agreement_completion_record_bloc_test.dart`
- `way2we_app/test/features/agreement/completion/pending_completions_bloc_test.dart`

### Change Log

- 2026-02-01：实现约定完成全生命周期（后端状态机+事务入账、前端记录/待确认 UI），补齐前后端测试
- 2026-02-01：补充 CurrentUserRepository 与待确认列表禁用自确认按钮
