# Story 1.4: User Login

Status: done

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

## Story

As a **Registered User**,
I want **to log in using my account and password**,
so that **I can access my account and data**.

## Acceptance Criteria

1. **Smart Account Identification**: Given a user enters a phone number or email, when they submit, the system must strictly identify the account type (`phone` or `email`) based on the input format and pass it to the backend. [Source: epics.md#Story 1.4]
2. **Password Login**: Given the user selects "Password Login" mode, when they enter their credential and password, the system must verify the password hash using `bcrypt`. [Source: architecture.md#Authentication & Security]
3. **Alternative Login**: The system must support "Verification Code Login" as an alternative mode (reusing Story 1.2 capabilities). [Source: epics.md#Story 1.4]
4. **Error Handling**: Given an incorrect password or non-existent account, the system must return a generic "Account or password error" (or specific error if UX permits, but Security prefers generic) and the UI must display it clearly. [Source: epics.md#Story 1.4]
5. **Token Issuance**: Upon successful authentication, the system must issue a standard JWT token. [Source: epics.md#Story 1.4]
6. **Navigation**: Upon successful login, the user must be redirected to the **HomePage**. [Source: 1-3-user-registration-first-login.md#Dev Agent Record]

## Tasks / Subtasks

- [x] **Verification & Testing** (High Priority - Feature pre-implemented in Story 1.3)
  - [x] **Audit Backend**: Verified `Login` implementation in `way2we_api/internal/adapter/handler/auth_handler.go` and `way2we_api/internal/app/auth/service.go`.
  - [x] **Audit Frontend**: Verified `LoginPage` in `way2we_app/lib/features/auth/view/login_page.dart` correctly handles the "Password Login" mode toggle and API call.
  - [x] **Add Tests**:
    - [x] Backend: Added unit tests for `LoginByPassword` and `LoginByCode` in `auth/service_test.go`.
    - [x] Frontend: Added widget tests for `LoginPage` testing mode toggle and UI elements in `login_page_test.dart`.
- [x] **Refinement (if needed)**
  - [x] Verified `UserIdentity` lookup logic correctly handles both phone and email types.
  - [x] Verified `bcrypt` comparison logic is secure and correct.

## Dev Notes

### Architecture Guardrails
- **Security**: Password verification uses `bcrypt`. Never compare plain text passwords.
- **Data Model**: Login queries `UserIdentity` first to resolve `User`.
- **API**: Endpoint `POST /v1/auth/login` uses `snake_case` JSON fields.

### Source Tree Components
- **Backend**: `way2we_api/internal/app/auth/`
- **Frontend**: `way2we_app/lib/features/auth/view/login_page.dart`

### Testing Standards
- **Backend**: `LoginByPassword` handles:
  - Wrong password -> Error ✅
  - User not found -> Error ✅
  - Correct password -> Success + Token ✅
- **Frontend**: `LoginPage` validates UI mode switching correctly.

## Dev Agent Record

### Agent Model Used

Claude Sonnet 4

### Debug Log References

### Completion Notes List

- **2026-01-23**: Story 1.4 implementation verified and tests added:
  - **Backend Tests Added**: 7 new integration tests for `Register`, `LoginByPassword`, `LoginByCode` in `service_test.go` using in-memory SQLite.
  - **Frontend Tests Added**: 6 widget tests for `AuthView` covering register/login mode switching, password/code login mode switching, and UI element verification.
  - **Code Changes**: Added `Key` parameters to `_buildLabeledInput` in `login_page.dart` and renamed `_AuthView` to `AuthView` for testability.
  - **All 15 backend tests pass**
  - **All 6 frontend tests pass**

### Change Log

- 2026-01-23: Added comprehensive backend integration tests for login/register flows
- 2026-01-23: Added frontend widget tests for LoginPage UI verification
- 2026-01-23: Enhanced login_page.dart with test-friendly Keys

### File List

- `way2we_api/internal/app/auth/service_test.go` - Added Register/Login integration tests
- `way2we_api/go.mod` - Added sqlite3 driver for testing
- `way2we_app/lib/features/auth/view/login_page.dart` - Added Keys for testing, renamed _AuthView
- `way2we_app/test/features/auth/view/login_page_test.dart` - NEW: Widget tests for login page
