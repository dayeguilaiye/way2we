# T02 空间、邀请与通知设计验收

2026-09-28。[完成评审](../../.impeccable/review/t02/finish-review.md)结论为 `ship`，覆盖本轮 30 张原生手机截图及抽查实现；`ceiling: reached` 限于该截图范围，材料性修复项为零。界面延续「日常信笺」：宋体展示文字、系统业务字体、三套明亮纸面主题和独立植物素材共同承载空间、成员与加入流程。

## 依据与交付范围

本轮为既有视觉体系的常规扩展，依据 [PRODUCT.md](../../PRODUCT.md)、[DESIGN.md](../../DESIGN.md)、[原型交互](../../prototype/app.js)中的 spaces／members／inbox、[T01 设计验收](t01-accounts-review.md)与 [T02 范围约定](../../.impeccable/review/t02/brief.md)。完成评审按该范围检查原生实现；独立方向合同、QUALITY BAR 卡与新页面 comp 未随本轮提供。

交付包含登录后的空间列表、创建空间、成员与空间昵称、复制邀请、链接／邀请码预览与接受、加入进度、全员同意、站内通知及资源跳转。首页近况、约定、积分操作和购买按 T03—T05 推进。业务实现与命令入口见 [T02 工程记录](../engineering/spaces.md)。

## 当前界面与既有体系的对应

| 项目 | 当前实现与评审依据 |
| --- | --- |
| 完整主题 | [主题实现](../../apps/mobile/lib/app/theme.dart)沿用暖杏、青瓷、雾玫的八个角色：`background`、`surface`、`tint`、`primary`、`ink`、`secondary`、`divider`、`outline`。数值对应 DESIGN.md 的既有色表；主按钮白字和共用语义色延续 T01。个人主题用于本人参与的各空间，符合 Complete Theme Rule。 |
| 字体分工 | [空空间页](../../apps/mobile/lib/features/spaces/presentation/spaces_page.dart)生活文案采用 `BrandSerif` 与 `headlineMedium`（行高 1.6）；[成员页](../../apps/mobile/lib/features/spaces/presentation/members_page.dart)和[加入进度](../../apps/mobile/lib/features/spaces/presentation/invitation_pages.dart)空间名采用 `headlineSmall` 与同一宋体。导航、表单、昵称、状态、余额与按钮使用系统业务字体，延续 Two Voices Rule。页面栏标题为 18 逻辑像素、600 字重。 |
| 字形资源 | `BrandSerif` 使用完整 Noto Serif SC Regular 字形、固定 400 字重，支持新增文案及用户自设空间名。来源为 Google Fonts 官方变量字体，经固定版本 fontTools 生成；源文件摘要、构建步骤与 OFL 许可证登记见[应用素材](../../apps/mobile/assets/README.md)。当前资源延续既定字体家族和字重。 |
| 空空间入口 | 独立植物位于文案上方留白，生活文案之后提供「创建空间」和「使用邀请加入」。植物跟随个人主题，跳过装饰语义，加载失败时保留位置，落实 Readable Ground Rule。该首屏为本轮空状态扩展。 |
| 创建与成员 | 创建空间连续填写空间名和本人空间昵称。成员页用宋体空间名、平整分组列表、昵称、参与状态和余额建立层级；主要按钮为「邀请伙伴」，加入申请与本人空间昵称通过独立入口打开。结构延续原型的信息关系，并采用 Flutter 页面导航。 |
| 邀请与同意 | [共用邀请组件](../../apps/mobile/lib/features/spaces/presentation/space_widgets.dart)展示邀请码、7 天有效期、全员同意规则及复制入口；复制调用原生 Clipboard，并显示「已复制」。预览先展示空间与邀请人，再提供接受操作。加入进度用状态文字、已同意人数及成员表态表达阶段，加入成功后提供「进入空间」。 |
| 通知 | [通知页](../../apps/mobile/lib/features/spaces/presentation/notifications_page.dart)以可点击内容行展示摘要、时间、已读／未读和详情入口，延续原型信息结构。点击后标记已读，再进入对应资源页面并重新获取访问结果。 |
| 版面与形状 | [共用页面容器](../../apps/mobile/lib/features/account/presentation/account_widgets.dart)采用 `SafeArea`、最大宽度 560 的滚动列表，边距为左／右 24、上 20、下 32 逻辑像素。输入与实心／描边按钮圆角为 8，内容表面为 12；按钮最小尺寸 48 × 48。底色明度与细分隔形成 Quiet Paper Rule 的平整层次。 |
| 提交与恢复 | 处理中显示动作进度；未确认写入保留原意图并提供「核对保存结果」，确认前限制新写入。读取和业务错误通过简短说明、重试入口及可选择复制的请求编号反馈。 |
| 放大字号与系统主题 | 双端成员页 1.6 倍文字截图保留昵称、状态、余额和操作的可读层级。[应用入口](../../apps/mobile/lib/app/app.dart)使用 `ThemeMode.light`，双端 members-dark 记录系统深色设置下继续呈现个人选定的明亮品牌主题。 |

完成评审将字体、材质、主题角色、创建表单、加入状态和控件形状判为 `match`；空空间首屏、成员分组、邀请流程、通知行、原生导航与系统主题策略判为符合本轮约定的 `adaptation`。

## 原生截图覆盖

完成评审已逐张查看以下 30 张完整 PNG。本记录核对全部文件数量、PNG 尺寸及 SHA-256，均与[证据清单](../../.impeccable/review/t02/evidence.json)一致。iOS 15 张来自 iPhone 18 Pro Max／iOS 27 Simulator（1320 × 2868），Android 15 张来自 Pixel 9／API 36 Emulator（1080 × 2424）；原始截图分别由 `simctl` 和 `adb` 获取。

| 状态 | iOS | Android |
| --- | --- | --- |
| 空空间 | [spaces-empty](../../.impeccable/review/t02/ios-spaces-empty.png) | [spaces-empty](../../.impeccable/review/t02/android-spaces-empty.png) |
| 创建空间 | [create-space](../../.impeccable/review/t02/ios-create-space.png) | [create-space](../../.impeccable/review/t02/android-create-space.png) |
| 暖杏成员页 | [members-apricot](../../.impeccable/review/t02/ios-members-apricot.png) | [members-apricot](../../.impeccable/review/t02/android-members-apricot.png) |
| 分享邀请 | [invite-share](../../.impeccable/review/t02/ios-invite-share.png) | [invite-share](../../.impeccable/review/t02/android-invite-share.png) |
| 邀请不可用 | [invite-unavailable](../../.impeccable/review/t02/ios-invite-unavailable.png) | [invite-unavailable](../../.impeccable/review/t02/android-invite-unavailable.png) |
| 邀请预览 | [invite-preview](../../.impeccable/review/t02/ios-invite-preview.png) | [invite-preview](../../.impeccable/review/t02/android-invite-preview.png) |
| 已加入 | [joined](../../.impeccable/review/t02/ios-joined.png) | [joined](../../.impeccable/review/t02/android-joined.png) |
| 等待同意 | [waiting](../../.impeccable/review/t02/ios-waiting.png) | [waiting](../../.impeccable/review/t02/android-waiting.png) |
| 青瓷成员页 | [members-celadon](../../.impeccable/review/t02/ios-members-celadon.png) | [members-celadon](../../.impeccable/review/t02/android-members-celadon.png) |
| 雾玫成员页 | [members-rose](../../.impeccable/review/t02/ios-members-rose.png) | [members-rose](../../.impeccable/review/t02/android-members-rose.png) |
| 成员页 1.6 倍文字 | [members-large](../../.impeccable/review/t02/ios-members-large.png) | [members-large](../../.impeccable/review/t02/android-members-large.png) |
| 同意加入 | [approval](../../.impeccable/review/t02/ios-approval.png) | [approval](../../.impeccable/review/t02/android-approval.png) |
| 通知 | [notifications](../../.impeccable/review/t02/ios-notifications.png) | [notifications](../../.impeccable/review/t02/android-notifications.png) |
| 三人成员页 | [members-three](../../.impeccable/review/t02/ios-members-three.png) | [members-three](../../.impeccable/review/t02/android-members-three.png) |
| 系统深色设置 | [members-dark](../../.impeccable/review/t02/ios-members-dark.png) | [members-dark](../../.impeccable/review/t02/android-members-dark.png) |

评审确认文件内容与命名状态对应、系统区域完整、正文和操作有效，所审截图的 craft-floor 检查通过。该结论来自原生截图及界面代码，HTML／CSS detector 不适用于本次 Flutter 交付。

## 运行证据与验收边界

工程记录与证据清单记载：`make check`、带竞态检测的数据库集成测试、30 次真实 HTTP 契约交换、16 项 Flutter 测试及双端空间集成流程通过；iOS Simulator debug 与 Android debug APK 构建成功。本轮文档核对已有证据，业务执行详情由工程记录维护。

[双端集成流程](../../apps/mobile/integration_test/spaces_test.dart)连接本地 Go API、PostgreSQL 与 Mailpit，输入经 Flutter `TestTextInput`。小屏[组件检查](../../apps/mobile/test/spaces_widget_test.dart)覆盖 375 × 667、1.6 倍文字和 240 逻辑像素模拟键盘 inset 下的邀请复制组件，确认布局无异常且「复制链接」可滚动到达；该结论限于组件环境。

普通安装包的系统链接检查覆盖 Android 冷启动到登录页和 iOS 系统打开确认框；登录前后的邀请路由由路由测试覆盖。iOS 确认框后的操作、真实输入法弹出／候选／遮挡、VoiceOver／TalkBack、硬件返回手势、减少动态效果、真机性能、最低系统版本、平板和发布签名继续按设备验收范围验证。邮件证据限于本地 Mailpit。

非空空间列表、昵称编辑及其他未单独截取的状态保留其各自验收范围。三套主题与大字号的视觉结论对应上述成员页状态；静态截图只证明捕获时的画面。

## 既有规范的适用范围

DESIGN.md 与 [.impeccable/design.json](../../.impeccable/design.json)记录浏览器原型体系。Flutter 的按下反馈采用 Material 默认状态与品牌颜色映射；原型 `pressed` 色表、浏览器焦点轮廓、动画和控件尺寸仍以各自证据为准。

[主题文档](themes.md)保留原型阶段的主题数量、独立素材制作、主题接入待办和即时预览描述。当前客户端已经提供三套素材与账号级持久化，并在服务端确认后更新主题；阶段差异在此登记，由对应文档维护任务处理。

本记录仅新增 T02 验收文档。PRODUCT.md、DESIGN.md 与 sidecar 的文件摘要均与本轮证据清单基线一致，既有产品及全局设计约定保持原状。
