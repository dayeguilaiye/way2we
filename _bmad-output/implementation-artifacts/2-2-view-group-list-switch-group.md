# Story 2.2: 查看群组列表与切换群组

Status: done

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

## Story

As a **用户**,
I want **查看我加入的所有群组并在它们之间切换**,
So that **我可以管理不同的关系和积分系统**.

## Acceptance Criteria

### 查看群组列表部分

**Given** 用户已加入多个群组
**When** 点击首页顶部的群组名称/图标
**Then** 显示群组列表抽屉 (Drawer) 或弹窗 (Bottom Sheet)
**And** 列表显示每个群组的名称、头像和成员数
**And** 当前活动群组有明显标识

**Given** 用户只有一个群组
**When** 打开群组切换界面
**Then** 显示"创建新群组"和"加入群组"选项

### 切换群组部分

**Given** 用户在群组列表中
**When** 点击另一个群组
**Then** 切换到该群组，首页显示该群组的数据 (刷新数据)
**And** 本地保存选择，下次打开 App 自动进入该群组

## Tasks / Subtasks

### Backend: Group List & Info
- [x] **Endpoint: List User's Groups**
  - [x] Implement `GET /v1/groups` (or reuse if exists) to list all groups the authenticated user belongs to.
  - [x] Ensure response includes: `id`, `name`, `description`, `member_count`, `role` (admin/member), `created_at`.
- [x] **Data Access (Ent)**
  - [x] Verify `QueryGroups` on `User` entity works correctly via `group_memberships`.

### Frontend: State & Persistence
- [x] **State Management (GroupControlBloc)**
  - [x] Create `GroupControlBloc` (or similar global scope bloc) to manage:
    - List of joined groups.
    - Currently selected group (`selectedGroup`).
  - [x] Event `LoadGroups`: Fetch list from API.
  - [x] Event `SelectGroup`: Update validation, persist selection.
- [x] **Persistence**
  - [x] Use `SharedPreferences` (or `hydrated_bloc`) to store `last_selected_group_id`.
  - [x] On App Launch: Check storage. If valid and user still member, select it. Else select first available or show empty/setup state.

### Frontend: UI Implementation
- [x] **Home Page Header**
  - [x] Add clickable Group Name/Avatar in `HomePage` AppBar/Header.
  - [x] Add visual indicator (chevron down) to suggest switchability.
- [x] **Group Switcher Widget**
  - [x] Implement `GroupSwitcherBottomSheet` (recommended for mobile) or Drawer.
  - [x] Display list of groups with `GroupListTile` (Avatar, Name, Member Count).
  - [x] Highlight current group.
  - [x] Add "Create New Group" action (navigates to `CreateGroupPage`).
  - [x] Add "Join Group" action (navigates to `JoinGroupPage`).
- [x] **Switching Logic**
  - [x] On tap group:
    - Update `GroupControlBloc` selection.
    - Trigger data refresh for Home/Agreement/Reward tabs (via `BlocListener` or key change).
    - Close switcher.

## Dev Notes

### Architecture Compliance
- **Global State**: The currently selected group is a global context for almost all other features (Agreements, Rewards, Points).
  - **Recommendation**: Inject `GroupControlBloc` at top level (e.g., `App` or `HomeWrapper`) or make it available via `MultiBlocProvider` up high.
  - **Dependency**: Other Blocs (like `AgreementBloc`, `RewardBloc`) need `groupId` to fetch data. They should listen to `GroupControlBloc` stream or accept `groupId` as parameter in events.
- **Persistence**: Store `last_selected_group_id` using `shared_preferences`.

### UX Specification Reference
- **Interaction**: Click header -> Bottom Sheet pops up -> Select -> Switch.
- **Visual**:
  - `AgreementCardCompact` / `PointsCard` etc. depend on current group data.
  - Smooth transition when switching (skeleton load for new group data).

### Technical Requirements
- **API**: `GET /v1/groups`
  - Response Schema: `[ { "id": 1, "name": "Family", "member_count": 3, "role": "admin" }, ... ]`
- **Flutter**:
  - Use `showModalBottomSheet` for the switcher.
  - Ensure `BlocListener` in HomePage handles `GroupSelected` state change to refresh tabs.

### Previous Story Intelligence (from 2.1)
- **Reuse**: We already have `Group` entity and schema.
- **Navigation**: `CreateGroupPage` and `JoinGroupPage` already exist. We just need to link them in the switcher.

## Developer Context

### Library & Framework Requirements
- **Flutter**: `flutter_bloc`, `shared_preferences`.
- **Backend API**: Echo handler for `GET /v1/groups`.

### File Structure
- **Backend**: `way2we_api/internal/app/group/service.go` (ListGroups), `way2we_api/internal/adapter/handler/group_handler.go`.
- **Frontend**:
  - `way2we_app/lib/features/group/bloc/group_control_bloc.dart` (New)
  - `way2we_app/lib/features/group/view/widgets/group_switcher_sheet.dart` (New)
  - `way2we_app/lib/features/home/view/home_page.dart` (Modify header)

## References
- **Epics**: Epic 2, Story 2.2
- **UX Design**: Section "User Journey Flows - 2. 创建/加入群组" (implies switching context)
- **Architecture**: Multi-tenant/Group-based isolation.

## Dev Agent Record

### Implementation Plan
- **Backend**: Update `GET /v1/groups` to include `member_count` and `description`.
- **Frontend**: Implement `GroupControlBloc` with `shared_preferences` persistence. Implement `GroupSwitcherSheet` widget. Refactor `HomePage` to use `GroupControlBloc`.

### Completion Notes
- Backend API updated and verified with tests.
- `GroupControlBloc` implemented with unit tests.
- `HomePage` header is now interactive and switches groups.
- `GroupSwitcherSheet` lists groups with member counts and allows creating/joining new groups.

### AI Review Fixes (2026-01-25)
- **Backend Optimization**: Refactored `GetUserGroups` to batch `count` queries, eliminating N+1 performance issue.
- **Backend Quality**: Removed duplicate validation in `GroupHandler`, enforcing Single Source of Truth in Service layer.
- **Frontend Integration**: Added `BlocConsumer` loop in `HomePage` to prepare for Agreement/Reward refresh integration.
- **Frontend Robustness**: Implemented UI-level blocking (Option A) in `HomePage` header to prevent race conditions during group loading.
- **Documentation**: Updated File List to include auto-generated platform files.

## File List
- way2we_api/internal/adapter/handler/group_handler.go
- way2we_api/internal/adapter/handler/group_handler_test.go
- way2we_api/internal/app/group/service.go
- way2we_app/lib/app/view/app.dart
- way2we_app/lib/features/group/bloc/group_control_bloc.dart
- way2we_app/lib/features/group/bloc/group_control_event.dart
- way2we_app/lib/features/group/bloc/group_control_state.dart
- way2we_app/lib/features/group/data/providers/group_provider.dart
- way2we_app/lib/features/group/view/widgets/group_switcher_sheet.dart
- way2we_app/lib/features/home/view/home_page.dart
- way2we_app/lib/l10n/arb/app_zh.arb
- way2we_app/pubspec.yaml
- way2we_app/test/features/group/bloc/group_control_bloc_test.dart
- way2we_app/pubspec.lock
- way2we_app/macos/Flutter/GeneratedPluginRegistrant.swift

## Change Log
- 2026-01-25: Implemented Story 2.2 - Group List and Switching.

