# Story 1.1: Initialize Project Infrastructure

Status: done

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

## Story

As a 开发团队,
I want 使用标准模版初始化 Flutter 和 Go 项目,
so that 我们有一个符合最佳实践的代码库基础来开始开发.

## Acceptance Criteria

1. **Given** 开发环境已准备就绪  
2. **When** 执行项目初始化脚本  
3. **Then** Flutter 项目使用 Very Good Core 模版创建，包含 BLoC、Dio、国际化配置  
4. **And** Go 项目使用 Standard Layout 创建，包含 Echo + Ent + Viper 配置  
5. **And** PostgreSQL 数据库连接配置完成  
6. **And** 基础的 CI/CD 配置文件存在  
7. **And** 项目可以成功编译运行（空白欢迎页）

## Tasks / Subtasks

- [x] **Initialize Backend (Go)** (AC: 2, 4, 5, 6, 7)
  - [x] Create `way2we_api` directory
  - [x] Initialize Go module `github.com/way2we/way2we_api`
  - [x] Set up Standard Go Project Layout structure:
    - `/cmd/api` (entry point)
    - `/internal/app` (business logic)
    - `/internal/adapter` (handlers, repos, providers)
    - `/internal/pkg` (middleware, config)
    - `/configs` (config files)
  - [x] Initialize Ent schema in `/ent/schema`
  - [x] Set up Echo server and basic middleware (Logger, Recover)
  - [x] Configure Viper for environment variables and `configs/config.yaml`
  - [x] Add PostgreSQL connection logic using Ent client
  - [x] Create basic Dockerfile and Makefile for local development
- [x] **Initialize Frontend (Flutter)** (AC: 1, 3, 7)
  - [x] Install or update `very_good_cli` (v0.28.0 recommended)
  - [x] Run `very_good create flutter_app way2we_app --org com.way2we --desc "Way2We - Relationship Interaction App"`
  - [x] Reorganize/Confirm Feature-First structure as per architecture:
    - `lib/app/`
    - `lib/core/`
    - `lib/features/`
    - `lib/shared/`
  - [x] Configure Dio client in `lib/core/network`
  - [x] Set up basic theme in `lib/app/theme` and i18n in `lib/app/l10n`
- [x] **Cross-Project Configuration** (AC: 6)
  - [x] Create `.github/workflows/main.yml` with base test/build steps for both projects
  - [x] Create root `README.md` and workspace-level `.gitignore`

## Dev Notes

### Architecture Intelligence
- **Technical Stack:** 
  - Backend: Go (v1.25.5+), Echo (v4.13+), Ent (v0.14+), PostgreSQL.
  - Frontend: Flutter, BLoC (Business Logic Component), Dio.
- **Code Structure:**
  - Backend: Modular Monolith following `github.com/golang-standards/project-layout`.
  - Frontend: Feature-First Architecture.
- **Naming Conventions:**
  - Database: Plural + snake_case.
  - API JSON: snake_case.
  - Flutter: File names in snake_case, Class names in PascalCase.

### Project Structure Notes
- Alignment with [architecture.md#项目结构与边界]
- Backend and Frontend in separate directories within the repository root.

### References
- [Source: architecture.md#Starter 模版评估]
- [Source: architecture.md#项目结构与边界]
- [Source: epics.md#Story 1.1: 初始化项目基础设施]
- [Source: prd.md#Functional Requirements]

## Dev Agent Record

### Agent Model Used

Antigravity (Custom Coding Assistant)

### Debug Log References

- Go build successful: `way2we_api/bin/api` created.
- Flutter analyze successful: No issues found.

### Completion Notes List

- Initialized Backend with Go, Echo, Ent, and Viper.
- Initialized Frontend with Flutter (Very Good Core), BLoC, and Dio.
- Fixed CI/CD Go version to 1.24.x.
- Added Backend unit tests (`main_test.go`).
- Added Frontend integration into `AppTheme`.
- Verified all tests pass and analysis is clean.

- Ultimate context engine analysis completed - comprehensive developer guide created

### File List

- `way2we_api/` (Backend Project: Go + Echo + Ent)
- `way2we_app/` (Frontend Project: Flutter + VGC + BLoC)
- `.github/workflows/main.yml` (CI/CD Pipeline)
- `README.md`
- `.gitignore` (Workspace-level)
