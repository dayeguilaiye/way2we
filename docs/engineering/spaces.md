# 空间、邀请与站内通知

T02 将已采纳的空间、成员和邀请流程接入 Flutter 与 Go。当前登录后进入空间列表，从成员页邀请伙伴，从通知页查看加入进度。约定、积分操作、购买和首页近况按 T03—T05 推进。

## 实现入口

- `server/internal/space`：空间创建与查询、成员昵称、邀请及全员同意、空间写事务与幂等结果。
- `server/internal/notification`：事务事件、站内通知投影、租约领取、重试和渠道任务接入点。
- `server/internal/platform/paging`：绑定账号、资源、空间与筛选条件的游标。
- `server/migrations/00003_spaces_notifications.sql`：邀请、同意记录、空间审计、通知事件与通知。
- `apps/mobile/lib/features/spaces`：账号隔离的查询、持久化待确认操作、空间及通知页面。

沿用当前工程依赖，未新增 Go 或 Flutter 第三方包。PostgreSQL `timestamptz` 解码显式使用 UTC，确保接口时间符合 OpenAPI 的 `Z` 结尾要求。

## 空间与邀请

创建空间会同时建立本人稳定成员身份，余额为 0。空间和成员列表分页读取；其他当前成员可查看昵称、参与状态和余额。个人账号昵称与空间昵称分别保存。

空间写入在同一空间锁内完成。操作标识按账号唯一，业务数据、审计、通知事件与命令结果原子提交。创建空间使用账号级操作锁；查询与权限检查使用同一只读快照。列表游标采用时间与 ID 的稳定排序，并绑定访问范围。

邀请码为 20 位随机 Base32，7 天内可首次接受。数据库保存摘要及 AES-GCM 加密凭据，创建结果重放时解密；命令 JSON、技术日志和通知均不保存明文邀请码。加密使用本地 `AUTH_SECRET_FILE`，AAD 与邀请 ID 绑定。

首次接受将邀请码绑定到本人。发起邀请视为同意；同空间、同候选人的待处理申请合并，并合并邀请人的同意。多个申请按接受时间、ID 顺序核验，每次加入后重新读取当前成员集合，后来加入者需要对后续申请表态。已加入结果保存当时的同意名单。

当前成员为空时申请保持等待。历史成员通过邀请恢复时沿用成员身份、昵称与余额。T06 的公开退出、恢复接口接入同一重核函数，并处理购买退款；T02 的空空间与恢复边界由真实数据库集成测试验证。

## 客户端恢复与链接

每个账号最多保留一笔未确认的业务提交，存储在 `flutter_secure_storage`。先持久化操作标识和参数，再发请求。超时、协议错误或 5xx 后保留原意图并提供核对入口；核对重放原请求。明确拒绝后可以修正输入，提交新的操作。切换账号后，旧请求无法覆盖新账号界面；空间查询按空间 ID 独立保存状态。

邀请页接受完整邀请码，也能从链接提取 `code`。本地默认链接为 `way2we://app/join?code=…`，iOS 与 Android 注册该 scheme。未登录打开链接时先登录，再回到原邀请页；接受操作仍由用户明确点击。

正式分享链接通过 `INVITE_BASE_URL` 配置 HTTPS 入口。域名确定后配置 iOS Associated Domains、Android App Links 及网页落地页，让未安装用户也能获取安装与邀请码信息。这些工作属于正式分发接入；本地使用邀请码及已安装 App 的 scheme 链接。依据：[Flutter 深度链接](https://docs.flutter.dev/ui/navigation/deep-linking)、[iOS Universal Links](https://docs.flutter.dev/cookbook/navigation/set-up-universal-links)、[Android App Links](https://docs.flutter.dev/cookbook/navigation/set-up-app-links)。

## 通知与未来渠道

业务事务调用 `notification.Record` 保存版本 1 事件，固定接收者、资源引用、安全摘要和来源请求编号。worker 每秒领取待处理事件，以 30 秒租约恢复进程中断，每次处理限时 8 秒；失败间隔 10 秒，最多尝试 8 次，终止失败保留事件供排查。

事件投影为站内通知，以事件 ID 与接收者去重。再次领取或重复处理保持一条通知。已读只更新一次时间，并使用同一命令幂等入口。查询只返回本人当前可访问的通知；等待加入者可以读取自己的申请进度，退出成员的空间业务通知隐藏。

新增渠道实现 `notification.Channel.Enqueue(ctx, tx, event)`，在通知投影事务中创建独立、可去重的投递任务。渠道发送 worker 在事务外处理设备授权、模板、发送和重试。外部发送状态与站内已读状态分别管理。集成测试通过验证渠道创建任务，并验证投影失败后的恢复；业务模块继续使用同一个事件接口。

## 本地检查

```sh
make dev
make check
make test-integration
make check-spaces-runtime
make test-spaces-device DEVICE=<模拟器标识>
```

运行契约脚本使用 `@example.test` 地址及 Mailpit，创建三个真实邮箱账号，验证创建、重放、接受、等待、同意、分页、成员昵称、通知与已读响应。数据库测试另行验证并发抢占邀请码、跨空间权限、申请合并、空空间等待、成员集合变化、完整回滚和事件恢复。Flutter 测试验证结果丢失后的原标识恢复、账号切换时丢弃迟到响应及链接解析。

模拟器截图保存在 `.impeccable/review/t02/`，运行日志保存在本机 `.artifacts/t02/`。本轮 `make check`、数据库竞态集成测试、30 次真实 API 契约交换、16 项 Flutter 测试及双端原生集成流程均通过。三套主题、1.6 倍文字和系统深色模式共保留 30 张原始截图。iOS 模拟器与 Android debug 安装包均构建成功。界面评审记录见[原生交付检查](../design/t02-spaces-review.md)。

普通安装包的系统链接检查覆盖 Android 冷启动进入登录页，以及 iOS 弹出 App 打开确认框；登录后恢复邀请路由由路由测试验证。iOS 系统确认框之后的手动操作、真实键盘、读屏、真机手势和正式签名发布在设备验收阶段继续验证。

集中执行本机设备测试时，可仅对该 API 进程临时提高 `AUTH_SEND_PER_SOURCE`，容纳多次创建测试账号；邮箱间隔、验证码验证和会话校验仍正常执行。日常 `make dev` 使用 `.env.example` 中的默认频控。
