# Story 1.5: Profile Management

Status: ready-for-dev

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

- [ ] **Backend Implementation**
  - [ ] **Storage Infrastructure**: 
    - **Config**: Add `app.public_url` to `configs/config.yaml` (default: `http://localhost:8080`) and Go config struct.
    - Create `internal/adapter/storage` with `Provider` interface: `Upload(ctx, file) (key string, err)` and `GetPublicUrl(key string) string`.
    - Implement `LocalStorageProvider`: Save to `uploads/` dir. `GetPublicUrl` returns `{app.public_url}/uploads/{key}`.
    - Strategy: DB stores **Key** (`avatars/xyz.jpg`), API returns **Full URL**.
    - *Future Note*: When implementing S3, `GetPublicUrl` will simply return `{bucket_cdn_url}/{key}`.
  - [ ] **Security Validation**:
    - Implement middleware or helper to validate `Content-Type` allowed list (`image/jpeg`, `image/png`, `image/webp`).
    - Enforce `MaxFileSize` of **10MB**.
  - [ ] **User Domain**: 
    - Create `internal/app/user`.
    - Implement `UpdateProfile` to handle DB updates.
  - [ ] **API Layer**: 
    - `user_handler.go`: Endpoints for `PUT /me` and `POST /uploads/avatar`.
    - Router registry in `router.go`.
    - **Static Serving**: Configure Echo to serve `uploads/` dir when using LocalProvider.

- [ ] **Frontend Implementation**
  - [ ] **Configuration**:
    - **iOS**: Update `ios/Runner/Info.plist` with `NSPhotoLibraryUsageDescription` and `NSCameraUsageDescription`.
    - **Android**: Update `android/app/src/main/AndroidManifest.xml` with `<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"/>` (and `READ_MEDIA_IMAGES` for Android 13+).
  - [ ] **Dependencies**: `image_picker` (already confirmed).
  - [ ] **Refactoring (Code Reuse)**:
    - Extract `AvatarPicker` and generic input widgets from `lib/features/auth/view/onboarding_profile_setup_page.dart`.
    - Move to `lib/shared/widgets/` to be shared by both Onboarding and Profile Settings.
  - [ ] **Feature Development**:
    - **Create Directory**: `way2we_app/lib/features/profile` (Strict separation).
    - Implement `ProfileBloc` and `ProfileRepository`.
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

### File List
