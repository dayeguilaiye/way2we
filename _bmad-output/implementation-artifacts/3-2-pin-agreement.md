# Story 3.2: 置顶约定

Status: review

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

## Story

As a **群组成员**,
I want **将常用的约定置顶**,
so that **我可以更快地找到和记录这些约定**.

## Acceptance Criteria

### 置顶与取消置顶操作
1. **Given** 用户在约定列表或约定卡片上
   **When** 点击"置顶"按钮或长按选择"置顶"（Context Menu）
   **Then** 该约定状态更新为"已置顶"
   **And** 显示成功提示 "已置顶"
   **And** 置顶状态只对我自己可见，不影响其他成员

2. **Given** 约定已置顶
   **When** 点击"取消置顶"
   **Then** 约定状态更新为"未置顶"
   **And** 恢复到正常排序位置

### 列表展示逻辑
3. **Given** 用户在约定列表页
   **When** 页面加载
   **Then** 已置顶的约定在列表中排在最前面（Section "置顶约定" 或 置顶图标标识并置顶排序）
   **And** 其余约定按原有规则排序

4. **Given** 用户在首页
   **When** 页面加载
   **Then** 显示我置顶的约定卡片区域（横向滚动区域）
   **And** 点击卡片可直接进入详情或快速记录

## Tasks / Subtasks

- [x] **Backend: Ent Schema 更新**
    - [x] 修改 `Agreement` Schema (`ent/schema/agreement.go`):
        - 添加 M2M Edge: `pinned_by_users` (关联 User)
        - Update Inverse Edge in `User` Schema (optional, or just use backref)
    - [x] 运行 `go generate ./ent` 更新代码

- [x] **Backend: API 扩展**
    - [x] `POST /v1/groups/:groupId/agreements/:agreementId/pin`: 置顶约定
        - 获取当前 userID
        - 添加 edge 关系
    - [x] `DELETE /v1/groups/:groupId/agreements/:agreementId/pin`: 取消置顶
        - 移除 edge 关系
    - [x] 更新 `GET /v1/groups/:groupId/agreements`:
        - 增加 `is_pinned` 字段在响应中 (需要查询 edge 是否存在)
        - 此时最好添加 Query Param `include_user_state=true` 或者默认包含
        - 或者 separate endpoint `GET /v1/groups/:groupId/agreements/pinned` (用于首页)

- [x] **Backend: Service 层实现**
    - [x] `PinAgreement(ctx, userID, agreementID)`
    - [x] `UnpinAgreement(ctx, userID, agreementID)`
    - [x] 更新 `ListAgreements` logic to populate `is_pinned` for current user

- [x] **Frontend: 数据模型更新**
    - [x] 更新 `Agreement` model (`lib/features/agreement/data/models/agreement.dart`):
        - 添加 `bool isPinned` (nullable or default false)
        - Update `fromJson` / `toJson`

- [x] **Frontend: API Provider 更新**
    - [x] `pinAgreement(groupId, agreementId)`
    - [x] `unpinAgreement(groupId, agreementId)`

- [x] **Frontend: BLoC 更新**
    - [x] `AgreementListBloc`:
        - Add Event: `TogglePinAgreement(agreementId, currentPinStatus)`
        - Add State handling for optimistic update or refresh
    - [x] `AgreementDetailBloc`:
        - Add Event: `TogglePin`

- [x] **Frontend: UI 实现**
    - [x] 更新 `AgreementCard`:
        - 添加置顶标识 (Pin Icon)
        - 添加操作入口 (Long press -> BottomSheet or Icon Button if space allows)
    - [x] 更新 `AgreementListPage`:
        - 实现置顶排序逻辑 (Pinned first)
    - [x] 更新 `HomePage` (`lib/features/home/view/home_page.dart`):
        - 添加 "置顶约定" 横向滚动区域 (Pinned Agreements Section)
        - Fetch pinned agreements (reuse `AgreementProvider` but separate Bloc or state slice? Or just filter from loaded agreements if all loaded? Better separate API call if lists are large, but for MVP load all and filter is fine)

- [x] **测试**
    - [x] Widget Test for Pin action
    - [x] Integration test for Pin persistence

- [x] **Review Fixes**
    - [x] 实现 AgreementCard 长按置顶 Context Menu
    - [x] 首页置顶区返回时自动刷新
    - [x] 后端 pin/unpin 错误码细化
    - [x] 前端错误码映射与本地化文案
    - [x] Provider 注入去重与状态提取优化

## Dev Notes

### Architecture Compliance

- **Schema Design**: 使用 Ent 的 Graph Edge (M2M) 处理 User <-> Agreement 的置顶关系。这是最 Clean 的方式，避免污染 Agreement 表或创建冗余的关联表 struct。
  - Definition in `agreement.go`:
    ```go
    edge.From("pinned_by", User.Type).
        Ref("pinned_agreements").
        Through("user_pinned_agreements", UserPinnedAgreement.Type), // Assuming explicit table is preferred for extra fields (like created_at), otherwise simple M2M
    ```
    *Correction*: Simple M2M is enough:
    ```go
    edge.From("pinned_by", User.Type).Ref("pinned_agreements")
    ```
    And in `user.go`:
    ```go
    edge.To("pinned_agreements", Agreement.Type)
    ```

- **API Response**:
  - `GET /v1/groups/:groupId/agreements` 应该是 main entry.
  - 在 Response Model 中增加 `is_pinned` (boolean).
  - 后端实现时，需要在 Query 中 `WithPinnedBy(func(q *ent.UserQuery){ q.Where(user.ID(currentUserID)) })` 类似逻辑来判断。
  - 实际上，更简单的做法是：查询全部 agreements，然后查询 `user.QueryPinnedAgreements().IDs(ctx)`，然后在内存中 map 匹配 `is_pinned = true`。

### UX Considerations

- **Interaction**:
  - 卡片长按 (Long Press) 是移动端常见的"更多操作"交互。
  - 或者在卡片右上角增加一个小的 Pin Icon (实心/空心) 供快速点击。建议后者，操作更显性。

- **Home Page**:
  - 横向滚动 (Horizontal ListView) 适合展示少量置顶项。
  - Component: `AgreementCardCompact` (smaller version defined in UX spec) or standard card. UX spec mentions `AgreementCardCompact`. Check definitions.

### Project Structure Notes

- **Frontend**:
  - Continue using `features/agreement` module.
  - `features/home` will import `features/agreement`'s exported widgets (e.g. `AgreementCard`).

### References

- **Epics**: Story 3.2
- **Architecture**: Ent Edge Definitions
- **UX**: Agreement Card Design

## Dev Agent Record

### Agent Model Used

GPT-5

### Debug Log References

- `go test ./internal/app/agreement -run TestAgreementPinnedEdge`
- `go test ./...`
- `go test ./internal/adapter/handler -run TestAgreementHandler_`
- `go test ./internal/adapter/handler -run 'TestAgreementHandler_.*Not'`
- `flutter gen-l10n`
- `flutter test test/features/agreement/view/agreement_card_test.dart`
- `flutter test test/features/agreement/view/agreement_error_mapper_test.dart`
- `flutter test test/features/home/pinned_agreements_section_test.dart`
- `flutter test`

### Completion Notes List

- Implementation plan: 使用 Ent M2M edge `pinned_by_users`/`pinned_agreements` 完成置顶关系建模
- 生成 Ent 代码并补充 pin 关系单测（sqlite in-memory）
- `go test ./...` 全量通过
- Agreement pin/unpin API 与列表 is_pinned 字段已接入，新增 handler 测试覆盖
- 前端新增 isPinned 字段与 pin/unpin API，BLoC 支持乐观更新与提示
- Agreement 列表置顶排序，详情与首页加入置顶操作与展示
- Flutter 测试通过（含新增置顶 widget 与 bloc 测试）
- AgreementCard 增加长按置顶菜单（BottomSheet），补充 widget 测试覆盖
- 首页置顶区改为 RouteAware 刷新，返回列表页后自动同步
- Pin/Unpin 错误码细化，Service 包装保留原始错误链，新增 handler 测试
- 前端错误码映射到本地化文案，列表/详情页统一错误提示策略
- AgreementProvider 统一注入，创建/编辑页面复用全局实例

### File List

- `_bmad-output/implementation-artifacts/sprint-status.yaml` - 故事状态更新为 review
- `_bmad-output/implementation-artifacts/3-2-pin-agreement.md` - 任务勾选与记录更新
- `way2we_api/ent/schema/agreement.go` - 添加 pinned_by_users edge
- `way2we_api/ent/schema/user.go` - 添加 pinned_agreements edge
- `way2we_api/ent/agreement.go` - Agreement 实体边更新
- `way2we_api/ent/user.go` - User 实体边更新
- `way2we_api/ent/agreement/agreement.go` - 生成的 pinned_by_users 关系定义
- `way2we_api/ent/agreement/where.go` - 生成的 pinned_by_users predicates
- `way2we_api/ent/agreement_create.go` - 生成的 edge 写入辅助
- `way2we_api/ent/agreement_query.go` - 生成的 edge 查询辅助
- `way2we_api/ent/agreement_update.go` - 生成的 edge 更新辅助
- `way2we_api/ent/user/user.go` - 生成的 pinned_agreements 关系定义
- `way2we_api/ent/user/where.go` - 生成的 pinned_agreements predicates
- `way2we_api/ent/user_create.go` - 生成的 edge 写入辅助
- `way2we_api/ent/user_query.go` - 生成的 edge 查询辅助
- `way2we_api/ent/user_update.go` - 生成的 edge 更新辅助
- `way2we_api/ent/mutation.go` - 生成的 edge mutation 记录
- `way2we_api/ent/client.go` - 生成的 edge 查询入口
- `way2we_api/ent/migrate/schema.go` - 生成的 join table schema
- `way2we_api/internal/app/agreement/pin_edges_test.go` - 新增 pinned 关系测试
- `way2we_api/internal/app/agreement/service.go` - Agreement 置顶/列表 user 状态逻辑
- `way2we_api/internal/adapter/handler/agreement_handler.go` - 新增 pin/unpin API 与 is_pinned 输出
- `way2we_api/internal/adapter/handler/router.go` - 路由注册 pin/unpin API
- `way2we_api/internal/adapter/handler/agreement_handler_test.go` - Agreement handler 置顶/列表测试
- `way2we_app/lib/features/agreement/models/agreement.dart` - 增加 isPinned 字段与序列化
- `way2we_app/lib/features/agreement/data/providers/agreement_provider.dart` - pin/unpin API 调用
- `way2we_app/lib/features/agreement/bloc/list/agreement_list_bloc.dart` - 列表置顶事件与状态处理
- `way2we_app/lib/features/agreement/bloc/list/agreement_list_event.dart` - TogglePinAgreement 事件
- `way2we_app/lib/features/agreement/bloc/list/agreement_list_state.dart` - 列表置顶状态扩展
- `way2we_app/lib/features/agreement/bloc/detail/agreement_detail_bloc.dart` - 详情页置顶事件与状态处理
- `way2we_app/lib/features/agreement/bloc/detail/agreement_detail_event.dart` - TogglePin 事件
- `way2we_app/lib/features/agreement/bloc/detail/agreement_detail_state.dart` - 详情页置顶状态扩展
- `way2we_app/lib/features/agreement/view/widgets/agreement_card.dart` - 置顶图标与紧凑卡片
- `way2we_app/lib/features/agreement/view/agreement_list_page.dart` - 置顶排序与交互
- `way2we_app/lib/features/agreement/view/agreement_detail_page.dart` - 置顶操作与提示
- `way2we_app/lib/features/home/view/home_page.dart` - 首页置顶约定区域
- `way2we_app/lib/app/view/app.dart` - 全局注入 AgreementProvider 与 routeObserver
- `way2we_app/lib/features/agreement/view/agreement_error_mapper.dart` - 约定错误码映射
- `way2we_app/lib/features/agreement/view/create_agreement_page.dart` - AgreementProvider 注入去重
- `way2we_app/lib/features/agreement/view/edit_agreement_page.dart` - AgreementProvider 注入去重
- `way2we_app/lib/l10n/arb/app_en.arb` - 新增置顶相关文案
- `way2we_app/lib/l10n/arb/app_zh.arb` - 新增置顶相关文案
- `way2we_app/lib/l10n/gen/app_localizations.dart` - 新增置顶文案接口
- `way2we_app/lib/l10n/gen/app_localizations_en.dart` - 新增置顶英文文案
- `way2we_app/lib/l10n/gen/app_localizations_zh.dart` - 新增置顶中文文案
- `way2we_app/test/features/agreement/bloc/agreement_list_bloc_test.dart` - 置顶状态流转测试
- `way2we_app/test/features/agreement/view/agreement_card_test.dart` - 置顶按钮 Widget 测试
- `way2we_app/test/features/agreement/view/agreement_error_mapper_test.dart` - 错误码映射单测
- `way2we_app/test/features/home/pinned_agreements_section_test.dart` - 首页置顶区域回退刷新测试
