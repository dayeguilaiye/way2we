# Story 1.5: Profile Management

Status: completed

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

## Story

As a **User**,
I want **to set and modify my avatar and nickname**,
so that **other group members can identify me**.

## Requirements & Acceptance Criteria

1.  **View Profile**: Given the user is logged in, when they navigate to the "Profile" page (or "Me" tab), they must see their current avatar (or default) and nickname. [Source: epics.md#Story 1.5]
2.  **Edit Nickname**: Given the user edits their nickname, the system must validate it is between 1-20 characters. Upon saving, it must update the backend (`PUT /v1/users/me`). [Source: epics.md#Story 1.5]
3.  **Avatar Upload**: 
    - Given the user clicks the avatar, they must be able to select an image from their device gallery.
    - **Permissions**: System must request and handle `Photo/Gallery` permissions on both iOS and Android.
    - **Upload**: The image must be uploaded to `POST /v1/uploads/avatar`.
    - **Constraint**: File must be an image (jpg/png/webp) and **Max Size 10MB**.
    - **Result**: The returned **Full URL** is used to update the profile display.
4.  **Error Handling**: 
    - Nickname > 20 chars -> Error "Nickname cannot exceed 20 characters".
    - File > 10MB -> Error "Image too large (Max 10MB)".
    - Invalid Type -> Error "Invalid image format".
5.  **Success Feedback**: Upon successful update of avatar or nickname, a success message/toast must be displayed. [Source: epics.md#Story 1.5]

## Tasks / Subtasks

- [x] **Backend Implementation**
  - [x] **Storage Infrastructure**: 
    - **Config**: Add `app.public_url` to `configs/config.yaml` (default: `http://localhost:8080`) and Go config struct.
    - Create `internal/adapter/storage` with `Provider` interface: `Upload(ctx, file) (key string, err)` and `GetPublicUrl(key string) string`.
    - Implement `LocalStorageProvider`: Save to `uploads/` dir. `GetPublicUrl` returns `{app.public_url}/uploads/{key}`.
    - Strategy: DB stores **Key** (`avatars/xyz.jpg`), API returns **Full URL**.
    - *Future Note*: When implementing S3, `GetPublicUrl` will simply return `{bucket_cdn_url}/{key}`.
  - [x] **Security Validation**:
    - Implement middleware or helper to validate `Content-Type` allowed list (`image/jpeg`, `image/png`, `image/webp`).
    - Enforce `MaxFileSize` of **10MB**.
  - [x] **User Domain**: 
    - Create `internal/app/user`.
    - Implement `UpdateProfile` to handle DB updates.
  - [x] **API Layer**: 
    - `user_handler.go`: Endpoints for `PUT /me` and `POST /uploads/avatar`.
    - Router registry in `router.go`.
    - **Static Serving**: Configure Echo to serve `uploads/` dir when using LocalProvider.

- [x] **Frontend Implementation**
  - [x] **Configuration**:
    - **iOS**: Update `ios/Runner/Info.plist` with `NSPhotoLibraryUsageDescription` and `NSCameraUsageDescription`.
    - **Android**: Update `android/app/src/main/AndroidManifest.xml` with `<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"/>` (and `READ_MEDIA_IMAGES` for Android 13+).
  - [x] **Dependencies**: `image_picker` (already confirmed).
  - [x] **Refactoring (Code Reuse)**:
    - Extract `AvatarPicker` and generic input widgets from `lib/features/auth/view/onboarding_profile_setup_page.dart`.
    - Move to `lib/shared/widgets/` to be shared by both Onboarding and Profile Settings.
  - [x] **Feature Development**:
    - **Create Directory**: `way2we_app/lib/features/profile` (Strict separation).
    - Implement `ProfileBloc` and `ProfileRepository` (implemented via `ProfileProvider`).
    - Implement `ProfilePage` reusing the extracted widgets.


## Dev Notes

### Architecture Guardrails
- **Modular Monolith**: Place user business logic in `internal/app/user`, NOT in auth module.
- **Storage Abstraction**: Do NOT hardcode local file operations in the handler. Use a `StorageProvider` interface in `internal/port` (or `adapter` interface definition) to allow future switch to S3/OSS.
- **Static Files**: If using local storage, ensure the `uploads` directory is served correctly by Echo in `cmd/api/main.go`.
- **Flutter BLoC**: Use a dedicated `ProfileBloc` to handle the state of the profile view (loading, updating, error, success).
- **Ent Schema**: `User` entity already has `nickname` and `avatar` fields. No schema change needed.

### Source Tree Components to Touch
- **Backend**:
    - `way2we_api/internal/app/user/` (New)
    - `way2we_api/internal/adapter/storage/` (New)
    - `way2we_api/internal/adapter/handler/user_handler.go` (New)
    - `way2we_api/internal/adapter/handler/router.go`
    - `way2we_api/cmd/api/main.go`
- **Frontend**:
    - `way2we_app/lib/features/profile/` (New)
    - `way2we_app/pubspec.yaml`
    - `way2we_app/lib/shared/api/`

### Testing Standards
- **Backend**: Update profile with valid data -> Success. Update with invalid nickname -> Error. Upload file -> Success + URL returned.
- **Frontend**: Verify UI shows current data. Verify "Save" calls Bloc event. Verify error states.

### Project Structure Notes
- **User Domain**: We are introducing the `user` domain. Keep it distinct from `auth`. Auth is about *access*, User is about *profile data*.

### References
- [Epics Story 1.5](_bmad-output/project-planning-artifacts/epics.md#story-1.5-个人资料管理)
- [Architecture Storage](_bmad-output/architecture.md#infrastructure)

## Dev Agent Record

### Agent Model Used
{{agent_model_name_version}}

### Debug Log References

### Completion Notes List
- 2026-01-23: Implemented Storage Infrastructure (LocalStorageProvider) and Security Validation (Image Validator). Added Config support for PublicURL.
- 2026-01-23: Completed Backend Implementation: UserService, UserHandler, router integration, and unit tests.
- 2026-01-23: Completed Frontend Implementation: AvatarPicker widget, ProfileProvider, ProfileBloc, ProfilePage, L10n, and Onboarding refactoring.
- 2026-01-23: Integrated navigation from HomePage to ProfilePage and hooked up real API calls to Onboarding.
- 2026-01-24: **Code Review Fixes**:
  - Added `uploads/` to `.gitignore` to prevent runtime files from being committed.
  - Created `AppConfig` class for environment-based API URL configuration (using `--dart-define`).
  - Implemented `ServiceLocator` for centralized Dio instance management and dependency injection.
  - Refactored `ProfileState` to use sealed classes for robust success/failure detection (`ProfileLoadSuccess`, `ProfileUpdateSuccess`, `ProfileFailure`).
  - Added `Delete` and `ExtractKeyFromUrl` methods to storage `Provider` interface for old avatar cleanup.
  - Implemented old avatar deletion when uploading new avatar to prevent storage leaks.
  - Updated `UserHandler` to return structured error codes instead of raw error messages.
  - Added error code to localized message mapping in `ProfilePage`.
  - Removed hardcoded URLs from `LoginPage`, `ProfilePage`, and `OnboardingProfileSetupPage`.

### File List
- way2we_api/.gitignore
- way2we_api/configs/config.yaml
- way2we_api/internal/pkg/config/config.go
- way2we_api/internal/pkg/config/config_test.go
- way2we_api/internal/adapter/storage/storage.go
- way2we_api/internal/adapter/storage/local_provider_test.go
- way2we_api/internal/pkg/validator/image_validator.go
- way2we_api/internal/pkg/validator/image_validator_test.go
- way2we_api/internal/app/user/service.go
- way2we_api/internal/app/user/service_test.go
- way2we_api/internal/adapter/handler/user_handler.go
- way2we_api/internal/adapter/handler/user_handler_test.go
- way2we_api/internal/adapter/handler/router.go
- way2we_api/cmd/api/main.go
- way2we_app/lib/app/config.dart
- way2we_app/lib/app/di.dart
- way2we_app/lib/bootstrap.dart
- way2we_app/ios/Runner/Info.plist
- way2we_app/android/app/src/main/AndroidManifest.xml
- way2we_app/lib/shared/widgets/avatar_picker.dart
- way2we_app/lib/features/profile/data/providers/profile_provider.dart
- way2we_app/lib/features/profile/bloc/profile_event.dart
- way2we_app/lib/features/profile/bloc/profile_state.dart
- way2we_app/lib/features/profile/bloc/profile_bloc.dart
- way2we_app/lib/features/profile/view/profile_page.dart
- way2we_app/lib/l10n/arb/app_en.arb
- way2we_app/lib/features/auth/view/login_page.dart
- way2we_app/lib/features/auth/view/onboarding_profile_setup_page.dart
- way2we_app/lib/features/home/view/home_page.dart

