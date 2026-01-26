# Story 2.3: Member Management & Permissions

Status: ready-for-dev

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

## Story

As a **Group Administrator**,
I want to **view the member list, set member roles, and assign specific permissions**,
so that **I can granularly control who has management rights and what actions members can perform**.

## Acceptance Criteria

### Member List & Role Management

1.  **Given** the user is a group administrator,
    **When** they navigate to Group Settings > Member Management,
    **Then** display a list of all members showing avatar, nickname, role (Admin/Member), and join time.

2.  **Given** the administrator views member details,
    **When** they select a member,
    **Then** they can promote the member to Administrator or revoke Administrator status.

3.  **Given** the group has only one administrator,
    **When** the administrator attempts to downgrade themselves to a regular member,
    **Then** show an error message: "Group must have at least one administrator".

### Permission Assignment

4.  **Given** the user is a group administrator,
    **When** they access Member Details > Permission Settings,
    **Then** display a configurable list of permissions:
    *   Create Agreement (`create_agreement`)
    *   Edit Agreement (`edit_agreement`)
    *   Delete Agreement (`delete_agreement`)
    *   Record Completion for Others (`record_for_others`)
    *   Modify Group Defaults (`modify_defaults`)
    *   Create Special Events (`create_special_events`)
    *   Revoke Records (`revoke_records`)

5.  **Given** the administrator modifies permissions,
    **When** they toggle permissions and save,
    **Then** the permissions take effect immediately, and the member's actions are restricted accordingly.

6.  **Given** a member lacks a specific permission,
    **When** they attempt to perform a restricted action,
    **Then** show a "You do not have permission to perform this action" message.

## Tasks / Subtasks

- [x] **Backend: Ent Schema & Logic**
    - [x] Update `GroupMembership` (edge schema between User and Group) to include:
        - `role` (enum: admin, member) - *Note: Check if already exists from Story 2.2*
        - `permissions` (json/bitmask) - Store flags for granular rights.
    - [x] Run `ent generate` to update assets.
    - [x] Implement validation logic:
        - Ensure at least one admin remains per group.
        - Validate permission flags are valid.

- [x] **Backend: API Implementation**
    - [x] `GET /v1/groups/:id/members`: List members with roles and permissions.
    - [x] `PUT /v1/groups/:id/members/:userId/role`: Update role (promote/demote).
    - [x] `PUT /v1/groups/:id/members/:userId/permissions`: Update granular permissions.
    - [x] Middleware/Policy: Enforce that only Admins can call these endpoints.

- [x] **Frontend: Member Management BLoc**
    - [x] Create `GroupMembersBloc`:
        - Events: `LoadMembers`, `UpdateMemberRole`, `UpdateMemberPermissions`.
        - State: `GroupMembersLoading`, `GroupMembersLoaded`, `MemberOperationSuccess`, `MemberOperationFailure`.

- [x] **Frontend: UI Implementation**
    - [x] **Member List Page**:
        - List view with `MemberListItem` widget.
        - Badges for Admin/Member roles.
    - [x] **Member Detail / Edit Page**:
        - Role toggle (Admin/Member).
        - Permission toggles list (Switch widgets).
        - Save button.
    - [x] **Permission Guard**:
        - Create a utility or mixin to check permissions `can(action)` before showing buttons/actions in other parts of the app.

## Dev Notes

### Architecture Compliance

-   **Data Modeling**: Use **Ent Edge Schema** for `User` <-> `Group` relationship. This is critical for storing the `permissions` field on the link itself.
    -   Field `permissions` can be a JSON array of strings or an integer bitmask (JSON strings preferred for readability/extensibility unless performance constraints exist).
-   **Security**: Use a robust permission check middleware on the backend. Do not rely solely on frontend checks.
    -   Backend: `RequireGroupPermission(groupID, permissionName)` middleware.

### Project Structure Notes

-   **Feature Module**: Create `lib/features/group_management` or expand `lib/features/group`. Given the complexity, a sub-feature `lib/features/group/members` is appropriate.
-   **Backend**: `internal/app/group/service.go` should handle the logic.

### References

-   **Epics**: Epic 2, Story 2.3
-   **UX Design**: Section "Group Management" - typically standard list and detail views.
-   **Architecture**: "RBAC (Administrator + Permission Assignment)".

## Dev Agent Record

### Agent Model Used

Antigravity (Google DeepMind)

### Debug Log References

### Completion Notes List

- [2026-01-26] Completed Full Implementation:
  - Backend API: Handlers and tests for member listing/updates.
  - Frontend Logic: `GroupMembersBloc` and `GroupProvider`.
  - Frontend UI: `MemberManagementPage`, `MemberDetailPage`, and Home integration.
  - Localization: Added translations.
- [2026-01-26] Code Review Fixes:
  - Implemented `RequireGroupPermission` and `RequireGroupAdmin` middleware.
  - Added missing unit tests for `GroupMembersBloc`.

### File List

- way2we_api/ent/schema/groupmember.go
- way2we_api/internal/app/group/service.go
- way2we_api/internal/app/group/role_permission_test.go
- way2we_api/internal/adapter/handler/group_handler.go
- way2we_api/internal/adapter/handler/group_members_test.go
- way2we_api/internal/adapter/handler/router.go
- way2we_app/lib/features/group/data/providers/group_provider.dart
- way2we_app/lib/features/group/models/member.dart
- way2we_app/lib/features/group/bloc/members/group_members_bloc.dart
- way2we_app/lib/features/group/bloc/members/group_members_event.dart
- way2we_app/lib/features/group/bloc/members/group_members_state.dart
- way2we_app/lib/features/group/view/member_management_page.dart
- way2we_app/lib/features/group/view/member_detail_page.dart
- way2we_app/lib/features/home/view/home_page.dart
- way2we_app/lib/l10n/arb/app_en.arb
- way2we_app/test/features/group/bloc/group_members_bloc_test.dart
- way2we_api/internal/pkg/middleware/authz.go
- way2we_api/cmd/api/main.go
