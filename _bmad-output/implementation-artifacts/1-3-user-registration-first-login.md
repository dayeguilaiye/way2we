# Story 1.3: User Registration & Setting Password

Status: done

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

## Story

As a **新用户 (New User)**,
I want **使用手机号或邮箱注册账户并设置密码 (Register with phone/email and set password)**,
so that **我可以创建账户并使用密码登录 (I can create an account and log in with a password)**.

## Acceptance Criteria

1. **Verify Code Linkage**: Given a user has entered a phone/email and received a code (via Story 1.2), when they submit the correct code, the system must allow them to proceed to password setting. [Source: epics.md#Story 1.3]
2. **Password Input**: The password setting form must include "Password" and "Confirm Password" fields with visibility toggles. [Source: ux-design-specification.md#User Journey Flows]
3. **Password Validation**: Password must be 6-20 characters long. [Source: epics.md#Story 1.3]
4. **Data Persistence**: Upon successful registration, the system must create records in both `User` and `UserIdentity` tables. [Source: architecture.md#Data Architecture]
5. **Security**: Passwords must be hashed using `bcrypt` before storage in `User.password_hash`. [Source: architecture.md#Authentication & Security]
6. **Auto-Login**: After successful registration, the system must issue a JWT token and automatically log the user in. [Source: epics.md#Story 1.3]
7. **Navigation**: Upon completion, the user should be redirected to the "Profile Setup" (Nickname/Avatar) page. [Source: ux-design-specification.md#User Journey Flows]
8. **API Standards**: All API requests/responses must use `snake_case`. [Source: architecture.md#Naming Patterns]

## Tasks / Subtasks

- [x] Backend: Database Schema Enhancement (AC: 4, 5)
  - [x] Add `password_hash` to `User` schema in `ent/schema/user.go`.
  - [x] Ensure `UserIdentity` schema in `ent/schema/useridentity.go` supports `identifier` and `type`.
  - [x] Run `go generate ./ent` to update entities.
- [x] Backend: Authentication Logic (AC: 1, 4, 5, 6)
  - [x] Implement `Register` method in `internal/app/auth/service.go`.
  - [x] Use `golang.org/x/crypto/bcrypt` for secure hashing.
  - [x] Generate JWT using existing secret configuration.
- [x] Backend: API Implementation (AC: 8)
  - [x] Implement `POST /v1/auth/register` in `internal/adapter/handler/auth_handler.go`.
  - [x] Define `RegisterRequest` and `AuthResponse` structs with json tags.
  - [x] Replace `interface{}` with typed `UserDTO` struct for API responses.
- [x] Frontend: Registration Experience (AC: 2, 1, 4)
  - [x] Update `RegistrationBloc` in `lib/features/auth/bloc/` to handle password submission.
  - [x] Create `SetPasswordView` in `lib/features/auth/view/`. (Implemented within `LoginPage` for seamless UX)
- [x] Frontend: UI Components (AC: 2, 3)
  - [x] Use custom `rounded-full` (pill-shaped) inputs as per design system.
  - [x] Implement client-side validation for length (6-20) and match.
  - [x] Add password visibility toggle buttons.
- [x] Frontend: Session Management (AC: 6, 7)
  - [x] Store JWT securely using `flutter_secure_storage`.
  - [x] Update `AppBloc` state to `authenticated` (Handled via navigation to next screen).
  - [x] Navigate to `OnboardingProfileSetupPage` after registration (distinct from general settings page).
  - [x] Navigate to `HomePage` after login.

## Dev Notes

### Architecture Guardrails
- **Backend**: Use `ent` for all DB operations. Do NOT use raw SQL.
- **Frontend**: Follow the `Feature-First` structure in `lib/features/auth/`.
- **Security**: Never return `password_hash` in any API response.
- **Naming**: Ensure PostgreSQL tables are plural (`users`, `user_identities`).

### Source Tree Components
- **Backend API**: `way2we_api/internal/app/auth/`, `way2we_api/ent/schema/`
- **Frontend App**: `way2we_app/lib/features/auth/`, `way2we_app/lib/shared/widgets/`

### Testing Standards
- **Backend**: Unit tests for `AuthService.Register` ensuring hash correctness.
- **Frontend**: Widget tests for `SetPasswordView` validating 6-20 length constraint.

## References

- [Architecture: Authentication & Security](_bmad-output/architecture.md#认证与安全 (Authentication & Security))
- [Architecture: Data Model](_bmad-output/architecture.md#数据架构 (Data Architecture))
- [UX: Visual Design Foundation](_bmad-output/project-planning-artifacts/ux-design-specification.md#Visual Design Foundation)
- [Epic: 1.3 Requirements](_bmad-output/project-planning-artifacts/epics.md#Story 1.3: 用户注册与设置密码)

## Dev Agent Record

### Agent Model Used

Claude 3.5 Sonnet (Code Review & Fix)

### Debug Log References

### Completion Notes List

- **2026-01-23**: Code Review completed with fixes:
  - **AC 2 Fix**: Added password visibility toggle (`showVisibilityToggle`) to all password input fields
  - **AC 3 Fix**: Extended password validation to check both min (6) and max (20) length
  - **AC 7 Fix**: Registration now navigates to `OnboardingProfileSetupPage`, login navigates to `HomePage`
  - **L10n Fix**: Updated password placeholder from "8-20" to "6-20 characters"
  - **Backend Fix**: Replaced `interface{}` with typed `UserDTO` struct in auth responses
  - **New Page**: Created `OnboardingProfileSetupPage` for post-registration profile setup (nickname/avatar)

### File List

- `way2we_app/lib/features/auth/view/login_page.dart` - Added visibility toggle, fixed validation
- `way2we_app/lib/features/auth/view/onboarding_profile_setup_page.dart` - NEW: Post-registration profile setup
- `way2we_app/lib/features/auth/view/view.dart` - Added export for new page
- `way2we_app/lib/l10n/arb/app_en.arb` - Fixed placeholder, added new l10n keys
- `way2we_api/internal/adapter/handler/auth_handler.go` - Added UserDTO struct, toUserDTO converter
