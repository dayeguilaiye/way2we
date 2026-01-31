# Story 4.2: 置顶商品

Status: review

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

## Story

As a **群组成员**,
I want **将常用的商品（兑换项）置顶**,
So that **我可以更快地找到和兑换这些商品**.

## Acceptance Criteria

### 置顶与取消置顶

**Given** 用户在商品列表或商品卡片上  
**When** 点击“置顶”或长按选择“置顶”  
**Then** 该商品在我的列表中排在最前面  
**And** 置顶状态只对我自己可见（User Private），不影响其他成员  
**And** 列表数据刷新，显示该商品为置顶状态（图钉图标高亮）  

**Given** 商品已置顶  
**When** 点击“取消置顶”  
**Then** 商品恢复到正常排序位置  
**And** 商品取消置顶状态显示  

### 首页置顶展示

**Given** 用户在首页  
**When** 页面加载且存在置顶商品  
**Then** 在“兑换”区块或顶部显示我置顶的商品列表（横向滚动区域）  
**And** 点击卡片可直接进入兑换流程（预览）  

**Given** 用户没有置顶商品  
**When** 页面加载  
**Then** 首页不显示置顶商品区域，保持整洁  

### 列表排序

**Given** 商品列表页  
**When** 加载数据  
**Then** 我置顶的商品排在列表最上方  
**And** 之后是未置顶的商品（按原有顺序，如创建时间倒序）  

## Tasks / Subtasks

### Backend (Go / Echo / Ent)

- [x] **Ent: 新增 Pinned Edge (Use <-> Reward)** (AC: 存储置顶状态)
  - [x] 修改 `way2we_api/ent/schema/reward.go`:
    - 添加 `edge.From("pinned_by", User.Type).Ref("pinned_rewards")`
  - [x] 修改 `way2we_api/ent/schema/user.go`:
    - 添加 `edge.To("pinned_rewards", Reward.Type)`
  - [x] 运行 `go generate ./ent`
  
- [x] **Service/Query: 列表查询支持置顶标记** (AC: 列表返回 is_pinned)
  - [x] 修改 `RewardService.List`:
    - 入参增加 `currentUserID`
    - 查询时通过 Ent `WithPinnedBy` 或 Predicate 判断当前用户是否在 `pinned_by` 列表
    - 或者在 Service 层组装响应时，查询 User 的 `pinned_rewards` ID 列表并映射到 `is_pinned` 字段
    - **Optimization**: 使用 Ent `WithPinnedBy(func (q *ent.UserQuery) { q.Where(user.ID(userID)) })` 一次性带出
  
- [x] **API: Pin/Unpin Endpoints** (AC: 置顶/取消置顶)
  - [x] 新增 `way2we_api/internal/adapter/handler/reward_handler.go`:
    - `POST /v1/groups/:groupId/rewards/:id/pin` (Pin)
    - `DELETE /v1/groups/:groupId/rewards/:id/pin` (Unpin)
  - [x] 注册路由
  - [x] 权限：仅检查用户是否在 Group 中
  
- [x] **API: Update Reward Response** (AC: 列表包含 is_pinned)
  - [x] 更新 `RewardResponse` struct，增加 `IsPinned bool json:"is_pinned"`
  - [x] 更新 `GET /v1/groups/:groupId/rewards` handler 逻辑

- [x] **测试 (Backend)**
  - [x] Service/Repo 单测: Pin/Unpin 操作，List 返回 is_pinned 正确性
  - [x] Handler 测试: Pin/Unpin 接口
  
### Frontend (Flutter / BLoC)

- [x] **Model: Update Reward** (AC: 支持 isPinned)
  - [x] 修改 `way2we_app/lib/features/reward/data/models/reward.dart`:
    - 增加 `final bool isPinned;` (default false)
    - 更新 `fromJson` / `toJson`
  - [x] 运行 `dart run build_runner build`
  
- [x] **Provider: Pin API** (AC: 调用 Pin 接口)
  - [x] 修改 `RewardProvider`:
    - `pinReward(groupId, rewardId)`
    - `unpinReward(groupId, rewardId)`
  
- [x] **BLoC: RewardListBloc** (AC: 处理置顶逻辑)
  - [x] 新增 Event: `PinRewardRequested`, `UnpinRewardRequested`
  - [x] 逻辑：调用 API 成功后，更新本地 State 中列表顺序和 item 状态 (Optimistic UI 建议)
    - 排序逻辑：`isPinned` true 的排在前面
    
- [x] **UI: Reward List Item** (AC: 显示置顶状态与操作)
  - [x] 修改 `RewardCard` (或新建 `RewardListItem`)
  - [x] 增加长按菜单或按钮：Pin/Unpin
  - [x] 显示图钉图标 (Material Symbols: `push_pin`)
  
- [x] **UI: Home Page Section** (AC: 首页置顶展示)
  - [x] 修改 `HomePage`
  - [x] 增加 `PinnedRewardsSection` (Horizontal ListView)
  - [x] 复用 `RewardListBloc` (或 HomeBloc 聚合请求) 获取置顶数据
    - *建议*: HomeBloc 增加 fetchPinnedRewards 或者 Home 直接复用 RewardListBloc 做局部展示
    
- [x] **测试 (Frontend)**
  - [x] Model 测试: 序列化
  - [x] BLoC 测试: Pin/Unpin 状态流转，排序逻辑

### Review Follow-ups (AI)
- [x] [AI-Review][High] 更新商品状态/详情接口返回的 `is_pinned` 会丢失（未为当前用户 eager-load pinned_by），更新状态后 UI 可能错误取消置顶 [way2we_api/internal/app/reward/service.go:334] [way2we_api/internal/adapter/handler/reward_handler.go:47] [way2we_app/lib/features/reward/bloc/list/reward_list_bloc.dart:80]
- [x] [AI-Review][Medium] Reward 服务测试覆盖回退：当前仅剩 Pin/Unpin 与排序测试，原有创建/更新/权限校验用例缺失，存在回归风险 [way2we_api/internal/app/reward/service_test.go:1]
- [x] [AI-Review][Medium] Story File List 未记录实际变更（sprint-status.yaml），需要补齐或解释 [_bmad-output/implementation-artifacts/sprint-status.yaml:68]
- [x] [AI-Review][Low] Pin/Unpin 图标 tooltip 未做本地化，英文环境显示中文 [way2we_app/lib/features/reward/view/widgets/reward_card.dart:121]
- [x] [AI-Review][Low] 首页置顶区块使用全量 rewards 拉取后再过滤，数据量大时性能浪费，可考虑 pinned_only 或复用缓存 [way2we_app/lib/features/home/view/home_page.dart:488]
  
## Dev Notes

### Developer Context

- **Data Model**: 置顶是 User 和 Reward 的 M2M 关系 (`edge`), 它是私有的 (Private)，不影响 Reward 本身在 Group 的公共属性。
- **List Sorting**: 后端不需要改变默认的 DB 排序 (Database Order)，但前端或 API 层需要根据 `is_pinned` 将其排在前面。
  - **Decision**: 考虑到分页，如果必须"Pinned on Top"且分页，后端必须在 SQL 层处理排序 (`ORDER BY is_pinned DESC, created_at DESC`)。
  - 请在 Backend Service 查询时处理排序：先 Join `pinned_by` (filtered by active user)，然后 Order By 该关联是否存在。如果 Ent 实现复杂，可接受 API 返回后 Service 层内存排序 (如果单页数据量小) 或者仅前端排序 (如果不分页)。考虑到 App 规模，目前全量或单页数据量较小，**推荐 Service 层内存排序或 DB 简单排序**。

### Technical Requirements

**Backend**
- **Endpoint Design**: 使用 RESTful Sub-resource 风格 `.../pin`。
- **Latency**: Pin/Unpin 应该是轻量操作，响应时间 < 200ms。
- **Ent Queries**: 注意 N+1 问题。查询 List 时，必须 Eager Load 或特定查询当前用户的 Pin 状态，不要在 Loop 中逐个查询。

**Frontend**
- **Optimistic UI**: 点击置顶应立即反馈 (UI 变动)，后台静默请求。失败则回滚并 Toast 提示。
- **Home Page Performance**: 首页的置顶区域如果不复用主 List 数据，注意不要重复请求太多次。如果置顶商品也在主 List 中，可以考虑数据源共享，但简单实现由 HomeBloc 单独请求 `GET /rewards?pinned_only=true` (可选 API 优化) 或直接复用 List 逻辑。
  - *Refinement*: 暂时不需要专用 API，Home 可以请求 List 并由前端过滤 Top N pinned items。

### Architecture Compliance

- **Naming**: `is_pinned` (JSON), `PinReward` (Func), `pinned_rewards` (Edge).
- **Directory**: 复用 `features/reward/` 目录。

### Library / Framework Requirements

- **Icons**: 使用 `Icons.push_pin` / `Icons.push_pin_outlined`.

## Dev Agent Record

### Agent Model Used

Antigravity (Google Deepmind)

### Debug Log References
- 2026-01-31: `go run entgo.io/ent/cmd/ent generate ./ent/schema`
- 2026-01-31: `go test ./...` (way2we_api)
- 2026-01-31: `dart run build_runner build`
- 2026-01-31: `flutter test`

### Completion Notes List
- 新增 Reward ↔ User 置顶关系与生成的 Ent 代码，列表查询携带 is_pinned 并进行置顶优先排序。
- 增加 Pin/Unpin 接口与路由，返回结构新增 is_pinned 字段。
- 前端模型、Provider、BLoC 与列表/首页 UI 支持置顶与置顶展示，并加入对应测试。
- 后端与前端测试全量通过（go test、flutter test）。

### File List
- `way2we_api/ent/schema/reward.go`
- `way2we_api/ent/schema/user.go`
- `way2we_api/ent/client.go`
- `way2we_api/ent/migrate/schema.go`
- `way2we_api/ent/mutation.go`
- `way2we_api/ent/reward.go`
- `way2we_api/ent/reward/reward.go`
- `way2we_api/ent/reward/where.go`
- `way2we_api/ent/reward_create.go`
- `way2we_api/ent/reward_query.go`
- `way2we_api/ent/reward_update.go`
- `way2we_api/ent/user.go`
- `way2we_api/ent/user/user.go`
- `way2we_api/ent/user/where.go`
- `way2we_api/ent/user_create.go`
- `way2we_api/ent/user_query.go`
- `way2we_api/ent/user_update.go`
- `way2we_api/internal/app/reward/service.go`
- `way2we_api/internal/app/reward/service_test.go`
- `way2we_api/internal/adapter/handler/reward_handler.go`
- `way2we_api/internal/adapter/handler/reward_handler_test.go`
- `way2we_api/internal/adapter/handler/router.go`
- `way2we_app/lib/features/reward/data/models/reward.dart`
- `way2we_app/lib/features/reward/data/models/reward.g.dart`
- `way2we_app/lib/features/reward/data/providers/reward_provider.dart`
- `way2we_app/lib/features/reward/bloc/list/reward_list_bloc.dart`
- `way2we_app/lib/features/reward/bloc/list/reward_list_event.dart`
- `way2we_app/lib/features/reward/view/widgets/reward_card.dart`
- `way2we_app/lib/features/reward/view/reward_list_page.dart`
- `way2we_app/lib/features/home/view/home_page.dart`
- `way2we_app/lib/l10n/arb/app_en.arb`
- `way2we_app/lib/l10n/arb/app_zh.arb`
- `way2we_app/lib/l10n/gen/app_localizations.dart`
- `way2we_app/lib/l10n/gen/app_localizations_en.dart`
- `way2we_app/lib/l10n/gen/app_localizations_zh.dart`
- `way2we_app/test/features/reward/bloc/reward_list_bloc_test.dart`
- `way2we_app/test/features/reward/data/reward_provider_test.dart`
- `way2we_app/test/features/reward/data/reward_model_test.dart`
- `_bmad-output/implementation-artifacts/sprint-status.yaml`

### Change Log
- 2026-01-31: 完成商品置顶功能（后端 M2M 关系、Pin/Unpin 接口与 is_pinned，前端置顶交互与首页展示，补充测试）
- 2026-01-31: 修复置顶状态更新丢失、补齐 Reward Service 权限/默认值测试、支持 pinned_only 查询与置顶提示本地化
