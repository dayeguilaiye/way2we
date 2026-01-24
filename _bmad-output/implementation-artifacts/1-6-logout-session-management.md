# Story 1.6: Logout & Session Management

Status: review

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

## Story

As a **User**,
I want **to be able to log out of my account**,
so that **I can protect my account security or switch to another account**.

## Requirements & Acceptance Criteria

1.  **Logout Action**:
    - Given the user is on the "Profile" page (or "Me" tab), there must be a "Log Out" button/list tile.
    - **Confirmation**: Clicking "Log Out" must trigger a confirmation dialog: "Are you sure you want to log out?" with "Cancel" and "Confirm" options. [Source: epics.md#Story 1.6]
2.  **Session Termination**:
    - **Local**: Upon confirmation, the system must clear all sensitive local data:
        - JWT Token (SecureStorage)
        - User Profile Data (Memory/Cache)
    - **Backend**: The system must call `POST /v1/auth/logout` to invalidate the current session (Token Blacklisting).
3.  **Redirection**:
    - After clearing the session, the app must immediately navigate back to the `LoginPage`.
    - The navigation stack should be cleared so the user cannot go back to the protected pages. [Source: epics.md#Story 1.6]
4.  **Global Session Management**:
    - The application must maintain a global authentication state (`AuthenticationBloc`) to handle session validity checks on app startup (`SplashPage`) and redirect unauthenticated users.

## Tasks / Subtasks

- [x] **Backend Implementation**
    - [x] **Blacklist Infrastructure**:
        - Create `internal/app/auth/blacklist_service.go` (Interface & In-Memory/DB Implementation).
        - *Note*: Since Redis is not yet in the stack, use a `token_blacklist` table in PostgreSQL (`token_hash`, `expires_at`).
        - Update Ent Schema: Add `TokenBlacklist` entity.
    - [x] **Logout API**:
        - Implement `POST /v1/auth/logout`.
        - Handler extracts token from context/header and adds to blacklist.
    - [x] **Middleware Update**:
        - Update `CommonJwtMiddleware` (or equivalent) to check if the token is in the blacklist. If yes, return `401 Unauthorized`.

- [x] **Frontend Implementation**
    - [x] **Architecture Upgrade (Session Management)**:
        - **Global Repository**: Promote `AuthProvider` (currently local in `LoginPage`) to a global `RepositoryProvider` in `lib/app/view/app.dart`.
        - **Global BLoC**: Create `lib/features/auth/bloc/authentication_bloc.dart`.
            - Events: `AppStarted`, `AppLogoutRequested`.
            - States: `AuthenticationInitial`, `AuthenticationAuthenticated`, `AuthenticationUnauthenticated`.
            - Logic: `AppStarted` checks `SecureStorage`. `AppLogoutRequested` calls Repo & clears storage.
        - **Injection**: Inject `AuthenticationBloc` at the `App` level.
    - [x] **Splash Page Update**:
        - Update `SplashPage` to dispatch `AppStarted` and listen to `AuthenticationState` for navigation (Home vs Login).
    - [x] **Profile Page UI**:
        - Add "Log Out" list tile to `ProfilePage`.
        - Implement `showDialog` for confirmation.
        - Dispatch `AppLogoutRequested` on confirmation.
    - [x] **Navigation Handling**:
        - Ensure `MaterialApp` (or a top-level Listener) listens to `AuthenticationUnauthenticated` to strict-push `LoginPage` and clear stack (`pushNamedAndRemoveUntil` or `GoRouter` redirect if active).

## Dev Notes

### Architecture Guardrails
- **Global Auth State**: Move away from ad-hoc auth checks. Use `AuthenticationBloc` as the single source of truth for session state.
- **Dependency Injection**: `AuthProvider` (Repository) must be singleton or transient provided at the root, so it can be accessed by both `LoginPage` and `ProfilePage`.
- **Token Blacklist**: While local logout is "functional", strictly implementing backend blacklisting ensures security compliance (FR36, NFR10 reliability).
- **Secure Storage**: Use `flutter_secure_storage` implementation wrapping. Ensure keys are consistent (`token`, `user_id`).

### Source Tree Components to Touch
- **Backend**:
    - `way2we_api/ent/schema/token_blacklist.go` (New)
    - `way2we_api/internal/app/auth/`
    - `way2we_api/internal/adapter/handler/auth_handler.go`
    - `way2we_api/internal/pkg/middleware/jwt.go`
- **Frontend**:
    - `way2we_app/lib/app/view/app.dart` (Add Providers)
    - `way2we_app/lib/features/auth/bloc/authentication_bloc.dart` (New)
    - `way2we_app/lib/features/profile/view/profile_page.dart`
    - `way2we_app/lib/features/splash/view/splash_page.dart`

### Testing Standards
- **Backend**: Test `Logout` adds token to DB. Test Middleware blocks blacklisted token.
- **Frontend**: Widget test for "Log Out" button and Dialog. Unit test `AuthenticationBloc` state transitions.

### Project Structure Notes
- **AuthenticationBloc**: Place in `features/auth/bloc/` but treat as global.
- **TokenBlacklist**: New entity in `ent`.

### References
- [Epic 1.6](_bmad-output/project-planning-artifacts/epics.md#story-1.6-登出与会话管理)
- [Previous Story 1.5](_bmad-output/implementation-artifacts/1-5-profile-management.md)

## Dev Agent Record

### Agent Model Used

Reka Flash (Gemini 2.5 Pro)

### Debug Log References

- Backend and frontend tests passed during implementation

### Completion Notes List

- ✅ Created `TokenBlacklist` Ent schema with `token_hash`, `expires_at`, `created_at` fields
- ✅ Implemented `BlacklistService` interface with `DBBlacklistService` using PostgreSQL
- ✅ Added `Logout` method to `auth.Service` that blacklists tokens
- ✅ Added `POST /v1/auth/logout` endpoint to auth handler
- ✅ Created custom JWT middleware with blacklist checking (`internal/pkg/middleware/jwt.go`)
- ✅ Updated router to use new JWT middleware with AuthService for blacklist support
- ✅ Added `logout()`, `getToken()`, `clearToken()` methods to `AuthProvider`
- ✅ Created `AuthenticationBloc` with `AppStarted`, `AppLogoutRequested`, `AppLoginSucceeded` events
- ✅ Used sealed classes for `AuthenticationState` (Initial, Authenticated, Unauthenticated)
- ✅ Updated `App` widget to inject global `AuthProvider` and `AuthenticationBloc`
- ✅ Added `BlocListener` in `App` for global navigation on auth state change
- ✅ Updated `SplashPage` to dispatch `AppStarted` event for auth check
- ✅ Added "Log Out" button with confirmation dialog to `ProfilePage`
- ✅ Added l10n strings for logout button and confirmation dialog (en/zh)
- ✅ Created unit tests for `AuthenticationBloc` (4 tests passing)
- ✅ Created unit tests for `BlacklistService` and `Logout` (5 tests passing)
- ✅ All backend tests pass (no regressions)

### File List

**Backend (New):**
- way2we_api/ent/schema/token_blacklist.go
- way2we_api/internal/app/auth/blacklist_service.go
- way2we_api/internal/app/auth/blacklist_service_test.go
- way2we_api/internal/pkg/middleware/jwt.go

**Backend (Modified):**
- way2we_api/ent/* (generated files)
- way2we_api/internal/app/auth/service.go
- way2we_api/internal/adapter/handler/auth_handler.go
- way2we_api/internal/adapter/handler/router.go
- way2we_api/internal/pkg/jwt/jwt.go
- way2we_api/cmd/api/main.go

**Frontend (New):**
- way2we_app/lib/features/auth/bloc/authentication_bloc.dart
- way2we_app/lib/features/auth/bloc/authentication_event.dart
- way2we_app/lib/features/auth/bloc/authentication_state.dart
- way2we_app/test/features/auth/bloc/authentication_bloc_test.dart

**Frontend (Modified):**
- way2we_app/lib/app/view/app.dart
- way2we_app/lib/features/auth/bloc/bloc.dart
- way2we_app/lib/features/auth/data/providers/auth_provider.dart
- way2we_app/lib/features/splash/view/splash_page.dart
- way2we_app/lib/features/profile/view/profile_page.dart
- way2we_app/lib/l10n/arb/app_en.arb
- way2we_app/lib/l10n/arb/app_zh.arb
- way2we_app/test/app/view/app_test.dart

## Change Log

- 2026-01-24: Implemented Story 1.6 - Logout & Session Management
  - Backend: TokenBlacklist entity, BlacklistService, Logout API, JWT middleware with blacklist check
  - Frontend: AuthenticationBloc, global AuthProvider injection, ProfilePage logout button
  - Tests: AuthenticationBloc unit tests, BlacklistService tests
