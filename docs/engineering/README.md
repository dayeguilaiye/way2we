# 工程方案与规范目录

状态：阶段 3.1 已获用户采纳。先阅读[评审记录](review.md)，再按需要查看专题。

## 技术栈与依赖入口

移动端采用 **Flutter／Dart + Riverpod + go_router + Dio + flutter_secure_storage**；服务端采用 **Go net/http + PostgreSQL + pgx + goose + slog**。各项职责与选型依据集中保存在[工程方案的技术栈与主要依赖](architecture.md#技术栈与主要依赖)。

## 规范与工程落实状态

T00 已建立两端工程。精确版本、安装位置、当前边界和验证证据见[工具链与工程基础](foundation.md)；日常命令见根目录 [README](../../README.md)。

| 事项 | 规范 | 实现入口 |
| --- | --- | --- |
| 技术栈与主要库 | [工程方案](architecture.md) | `server/go.mod`、`apps/mobile/pubspec.yaml` 与锁文件 |
| 代码结构与写法 | [Go](go.md)、[Flutter](flutter.md) | `server/internal`、`apps/mobile/lib` |
| 前后端错误传递 | [API 规范](api.md) | `httpapi/errors.go`、`core/network` 与运行契约检查 |
| 日志与配置 | [运行规范](operations.md) | `platform/logging`、`platform/config`、`.env.example` |
| 格式与质量检查 | [检查规范](quality.md) | `Makefile`、`analysis_options.yaml`、单元／数据库／双端集成检查 |

邮件供应商及 SDK 在 T01 的真实邮件接入前确定；对象存储和图片选择等平台依赖在 T07 接入前确定。新增功能依赖按所属任务记录用途、许可证、实际版本与验证结果。

## 文档目录

阶段 3.2 产出：[数据模型与事务设计](data-model.md)、[OpenAPI 契约](../../api/openapi.yaml)、[首轮实施任务](../planning/implementation.md)及[设计检查记录](contract-validation.md)。

阶段 3.1 在正式工程编码前形成统一的实现依据。先用已确认的[产品规则](../product/rules.md)、[验收场景](../product/acceptance-scenarios.md)和[原型](../../prototype/README.md)准备具体示例，再确认技术方案和规范。规范写清可执行的约定，并标明状态与适用范围。

| 位置 | 内容 | 形成时机 |
| --- | --- | --- |
| [工程方案](architecture.md) | 技术选型、工程目录、模块接口、账号与登录身份、存储和事务分工 | 3.1 已采纳 |
| [接口约定](api.md) | 前后端共同使用的 HTTP 契约：认证、请求与响应、错误码、字段错误、请求标识、重复提交与重试 | 3.1 已采纳；首轮具体接口已在 3.2 补齐 |
| [Go 规范](go.md) | Go 内部错误与转换、代码组织、命名、依赖、数据库访问和事务写法 | 3.1 已采纳 |
| [Flutter 规范](flutter.md) | Dart/Flutter 代码组织、状态管理、导航、主题、网络层与错误反馈 | 3.1 已采纳 |
| [运行规范](operations.md) | 结构化日志、敏感信息、配置、数据库变更、图片存储及运行诊断 | 3.1 已采纳 |
| [检查规范](quality.md) | 格式化、静态检查、测试范围、构建命令和完成标准 | 3.1 已采纳；T00 已加入实际命令 |
| `../adr/` | 对后续维护有明显影响、需要保留取舍理由的技术决定 | 作出决定时 |
| `../../AGENTS.md` | AI 开发入口及权威文档链接 | 持续维护 |

阶段 3.2 将业务数据关系和第一条流程的具体接口补进工程方案，并在仓库根目录 `api/openapi.yaml` 保存机器可检查的请求、响应及错误定义；`api.md` 保留跨接口通用语义与示例。工程实际入口和检查命令见上表。

## 确认顺序

1. 整理少量真正影响使用体验或长期维护的选择，给出推荐方案、代价和需要用户确定的点，例如登录与账号恢复、数据托管位置、图片存储方式。普通编码细节由工程规范统一处理。
2. 先写共享契约，再写两端实现规则。至少用“余额不足、字段填写错误、权限不足、购买状态已变化、重复提交、网络超时”展示一次操作如何从 Go 错误转换为 HTTP 响应、Flutter 提示和可追踪日志。
3. 检查规范与产品场景一致，并做一次集中评审。明确记录已确认与待确认事项；确认后的规范作为阶段 3.2 数据与接口设计、阶段 3.3 工程初始化的依据。
4. 工程建立后，将关键约定落实为格式化、静态检查、契约验证和针对业务风险的测试。修改规则或契约时，同步更新文档、示例和检查。

业务词汇以根目录 [CONTEXT.md](../../CONTEXT.md) 为准，业务行为以 `docs/product/` 为准，视觉与交互以 [DESIGN.md](../../DESIGN.md) 和 `docs/design/` 为准。工程规范描述这些规则在程序中的落实方式。
