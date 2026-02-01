# Story 5.0: 积分账本基础设施

Status: done

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

## Story

As a **后端系统**,
I want **建立积分账本与余额汇总机制**,
so that **所有积分变动可审计、余额可快速读取并支撑兑换/撤销流程**.

## Acceptance Criteria

1. **数据模型**  
   **Given** 系统需要记录积分变化  
   **When** 积分发生变动  
   **Then** 必须写入 `point_logs`（流水）  
   **And** 必须更新 `member_summaries`（余额汇总）  
   **And** 两者在同一数据库事务中完成  

2. **幂等与来源追溯**  
   **Given** 同一业务事件被重复提交（重试）  
   **When** 系统处理积分变动  
   **Then** 不产生重复积分记录（基于 `group_id + source_type + source_id` 唯一约束）  
   **And** 每条流水可关联来源（约定完成、兑换、特殊事件、撤销）  

3. **余额一致性**  
   **Given** 任意一次积分变动  
   **When** 事务提交成功  
   **Then** `member_summaries.balance` 必须等于最新 `point_logs.balance_after`  
   **And** 余额可为负数（用于撤销回退场景）  

4. **读取能力**  
   **Given** 成员查看积分余额  
   **When** 请求当前群组余额  
   **Then** 使用 `member_summaries` 直接返回，不聚合流水计算  
   **And** 返回格式为 `snake_case`  

5. **访问控制**  
   **Given** 用户查询积分相关数据  
   **When** 调用相关接口  
   **Then** 必须通过 JWT 认证且验证用户是群组成员  

6. **最低可用 API**  
   **Given** 前端需要显示积分卡片与积分明细  
   **When** 调用 API  
   **Then** 提供：  
   - `GET /v1/groups/:groupId/points/me`（当前用户余额）  
   - `GET /v1/groups/:groupId/points/logs?member_id=&from=&to=&limit=&offset=`（积分流水，默认当前用户）  
     - `from`/`to`：RFC3339 时间戳  
     - `limit`：默认 50，最大 200  
     - `offset`：默认 0  

## Tasks / Subtasks

- [x] **Backend: Ent Schema**（AC: 1,2,3）
  - [x] 新增 `way2we_api/ent/schema/point_log.go`
  - [x] 新增 `way2we_api/ent/schema/member_summary.go`
  - [x] 字段建议：
    - `point_logs`: `group_id`, `user_id`, `delta`, `balance_after`, `reason`, `source_type`, `source_id`, `created_at`
    - `member_summaries`: `group_id`, `user_id`, `balance`, `updated_at`
  - [x] 索引：`member_summaries` 唯一 `(group_id, user_id)`；`point_logs` 唯一 `(group_id, source_type, source_id)`
  - [x] 运行 `go generate ./ent`

- [x] **Backend: PointsService**（AC: 1,2,3）
  - [x] 新增 `internal/app/points/service.go`
  - [x] `AddPoints(ctx, groupID, userID, delta, source)`
  - [x] `DeductPoints(ctx, groupID, userID, delta, source)`
  - [x] `RevertPoints(ctx, source)`（按 source 反向写入）
  - [x] 同一事务内：插入流水 + 更新余额  
  - [x] 幂等：命中唯一约束时返回已存在记录

- [x] **Backend: API & Routes**（AC: 4,5,6）
  - [x] 新增 `internal/adapter/handler/points_handler.go`
  - [x] 注册路由到 `router.go`
  - [x] 响应结构与错误码遵循现有风格（`snake_case` + `{code,message,details}`）

- [x] **Tests**（AC: 1-6）
  - [x] Service：幂等、并发、负余额、事务一致性  
  - [x] Handler：权限校验、参数校验、成功路径

### Review Follow-ups (AI)

- [x] [AI-Review][CRITICAL] 补齐 PointsService 事务一致性/故障回滚测试（当前未覆盖失败回滚）[`way2we_api/internal/app/points/service_test.go:1`]
- [x] [AI-Review][CRITICAL] 补齐 PointsHandler 权限校验、参数校验、错误码映射等测试（仅有成功路径）[`way2we_api/internal/adapter/handler/points_handler_test.go:1`]
- [x] [AI-Review][HIGH] `RevertPoints` 的 `SourceID` 拼接可能超过 `point_logs.source_id` 的 64 字符上限，导致撤销失败（需限制或改存储方案）[`way2we_api/internal/app/points/service.go:84`]
- [x] [AI-Review][MEDIUM] `ListPointLogs` 无分页/limit，日志量大时可能拖垮接口响应或造成内存压力（建议加入分页或时间范围）[`way2we_api/internal/app/points/service.go:125`]
- [x] [AI-Review][MEDIUM] Story File List 使用目录占位（`ent/pointlog/`, `ent/membersummary/`），未列出具体生成文件，变更追踪不完整（建议补齐具体文件）[`_bmad-output/implementation-artifacts/5-0-points-ledger-foundation.md:171`]

## Dev Notes

### Developer Context

- 该故事是 Epic 5-8 的基础设施，支撑：完成约定积分发放、兑换扣减、提供者激励、特殊事件加减分、撤销回退
- 现有 Agreement 有 `points`，Reward 有 `cost_points`；账本必须支持正负 delta
- 现有 `GroupMember` 以 `group_id + user_id` 表示成员关系，可直接复用，不新增成员表
- 本故事只提供积分余额/流水 API，不实现 UI；UI 在 Epic 5.2/10.2 完成

### Technical Requirements

- 积分变更必须在同一数据库事务内完成：写 `point_logs` + 更新 `member_summaries`
- 余额更新必须原子化（禁止先读后写的非锁定更新）
- JSON 必须 `snake_case`，错误响应结构 `{code,message,details}`
- 所有接口必须走 JWT 中间件并校验群组成员身份
- 幂等键使用 `(group_id, source_type, source_id)` 唯一约束

### Architecture Compliance

- 遵循架构决策：积分一致性采用 **TCC 思想 + DB 事务**
- 后端业务放在 `internal/app/points`，HTTP 在 `internal/adapter/handler`
- 数据库变更必须通过 Ent Schema 定义，禁止手写 SQL 建表

### Library / Framework Requirements

- 后端继续使用 Echo v4 + Ent v0.14.5（以 `way2we_api/go.mod` 为准），不要升级版本
- 数据库为 PostgreSQL，遵循现有迁移/生成流程
- 复用现有错误码风格与 handler 结构

### File Structure Requirements

- `way2we_api/ent/schema/point_log.go`
- `way2we_api/ent/schema/member_summary.go`
- `way2we_api/internal/app/points/service.go`
- `way2we_api/internal/adapter/handler/points_handler.go`
- `way2we_api/internal/adapter/handler/router.go`（路由注册）
- 对应测试：`way2we_api/internal/app/points/service_test.go`、`way2we_api/internal/adapter/handler/points_handler_test.go`

### Testing Requirements

- Service：幂等（重复 source 不重复入账）、事务一致性（故障回滚）、负余额允许、并发更新不丢失
- Handler：JWT + 群组成员校验、参数校验、错误码映射、成功返回字段为 `snake_case`

### Project Context Reference

- 未找到 `project-context.md`，无额外项目上下文可引用

### References

- [Source: _bmad-output/architecture.md#数据架构-积分一致性]
- [Source: _bmad-output/project-planning-artifacts/epics.md#Epic-5-完成约定与积分获取]
- [Source: _bmad-output/project-planning-artifacts/epics.md#Epic-6-兑换与履约流程]
- [Source: _bmad-output/project-planning-artifacts/epics.md#Epic-8-撤销与回退机制]
- [Source: _bmad-output/project-planning-artifacts/epics.md#Epic-10-活动记录与审计]
- [Source: _bmad-output/project-planning-artifacts/ux-design-specification.md#PointsCard]
- [Source: way2we_api/go.mod]
- [Source: way2we_api/ent/schema/groupmember.go]
- [Source: way2we_api/internal/app/points/service.go]
- [Source: way2we_api/internal/adapter/handler/points_handler.go]
- [Source: way2we_api/internal/adapter/handler/router.go]

## Story Completion Status

- Status: done
- Note: 积分账本与余额汇总已实现并接入 API（/points/me 与 /points/logs）

## Dev Agent Record

### Agent Model Used

GPT-5 (Codex)

### Implementation Plan

- 新增积分账本与余额汇总 Ent Schema 与索引，生成代码
- 实现 PointsService 与 points API 处理器/路由
- 补齐 service/handler 测试并运行全量测试

### Debug Log References

- `go run -mod=mod entgo.io/ent/cmd/ent generate ./ent/schema`
- `go test ./internal/app/points ./internal/adapter/handler`

### Completion Notes List

- Ultimate context engine analysis completed - comprehensive developer guide created
- 新增 Epic 5 子故事：积分账本基础设施（ready-for-dev）
- 已实现积分账本/余额汇总实体、PointsService 与 points API，并补充测试覆盖
- 修复 source_id 超长：新增 source_ref 并对超长 source_id 归一化为哈希
- 积分流水接口新增分页与时间范围过滤
- 补齐 PointsService/PointsHandler 测试覆盖（回滚、权限/参数校验）
- 测试：`go test ./internal/app/points ./internal/adapter/handler`
### File List

- `_bmad-output/implementation-artifacts/5-0-points-ledger-foundation.md`
- `_bmad-output/implementation-artifacts/sprint-status.yaml`
- `way2we_api/cmd/api/main.go`
- `way2we_api/ent/client.go`
- `way2we_api/ent/ent.go`
- `way2we_api/ent/group.go`
- `way2we_api/ent/group/group.go`
- `way2we_api/ent/group/where.go`
- `way2we_api/ent/group_create.go`
- `way2we_api/ent/group_query.go`
- `way2we_api/ent/group_update.go`
- `way2we_api/ent/hook/hook.go`
- `way2we_api/ent/membersummary.go`
- `way2we_api/ent/membersummary_create.go`
- `way2we_api/ent/membersummary_delete.go`
- `way2we_api/ent/membersummary_query.go`
- `way2we_api/ent/membersummary_update.go`
- `way2we_api/ent/membersummary/membersummary.go`
- `way2we_api/ent/membersummary/where.go`
- `way2we_api/ent/migrate/schema.go`
- `way2we_api/ent/mutation.go`
- `way2we_api/ent/pointlog.go`
- `way2we_api/ent/pointlog_create.go`
- `way2we_api/ent/pointlog_delete.go`
- `way2we_api/ent/pointlog_query.go`
- `way2we_api/ent/pointlog_update.go`
- `way2we_api/ent/pointlog/pointlog.go`
- `way2we_api/ent/pointlog/where.go`
- `way2we_api/ent/predicate/predicate.go`
- `way2we_api/ent/runtime.go`
- `way2we_api/ent/schema/group.go`
- `way2we_api/ent/schema/member_summary.go`
- `way2we_api/ent/schema/point_log.go`
- `way2we_api/ent/schema/user.go`
- `way2we_api/ent/tx.go`
- `way2we_api/ent/user.go`
- `way2we_api/ent/user/user.go`
- `way2we_api/ent/user/where.go`
- `way2we_api/ent/user_create.go`
- `way2we_api/ent/user_query.go`
- `way2we_api/ent/user_update.go`
- `way2we_api/internal/adapter/handler/points_handler.go`
- `way2we_api/internal/adapter/handler/points_handler_test.go`
- `way2we_api/internal/adapter/handler/router.go`
- `way2we_api/internal/app/points/service.go`
- `way2we_api/internal/app/points/service_test.go`

### Change Log

- 实现积分账本基础设施（Ent Schema + PointsService + API + 测试）。(Date: 2026-01-31)
- 修复积分账本评审问题：source_id 归一化 + source_ref、流水分页/时间范围、补齐测试覆盖。(Date: 2026-01-31)
