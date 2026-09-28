# T01 账号与个人外观设计验收

2026-09-28。[完成评审](../../.impeccable/review/t01/finish-review.md)结论为 `ship`，适用于本次已记录的 T01 手机界面截图范围。实现延续「日常信笺」的精致、清爽与温暖纸面：品牌标题使用宋体，业务文字使用系统字体，植物图片围绕可读内容留白，暖杏、青瓷与雾玫提供个人外观选择。

## 依据与交付范围

本次为既有视觉体系的常规延伸，依据 [PRODUCT.md](../../PRODUCT.md)、[DESIGN.md](../../DESIGN.md)、[主题与配色](themes.md)、[原型交互](../../prototype/app.js)、[原型样式](../../prototype/style.css)和[外观原型截图](../../.impeccable/review/themes.png)。登录页依照上述方向扩展，独立登录批准稿尚未建立。完成评审采用本次已明确的质量约定；全局首页概念图与差异评审保留各自的验收范围。

Flutter 在 iOS 与 Android 共用品牌风格。本地交付包含邮箱验证码登录、我的页面、账号昵称、个人外观、退出与同邮箱恢复。外观归当前账号所有，产品规则要求跨本人参与的全部空间使用；T01 已验证账号级保存与恢复，空间业务从 T02 接入。运行方式与业务检查见 [T01 工程记录](../engineering/accounts.md)。

## 当前界面规则

| 项目 | 当前实现与证据 |
| --- | --- |
| 配色 | [主题实现](../../apps/mobile/lib/app/theme.dart)中八个主题角色 `background`、`surface`、`tint`、`primary`、`ink`、`secondary`、`divider`、`outline`，分别对应既有色表的页面、表面、衬底、主色、正文、次要文字、分隔与控件边界，三套数值一致。主按钮文字为白色，成功与错误沿用共用语义色。 |
| 字体 | [登录页](../../apps/mobile/lib/features/account/presentation/login_page.dart)品牌标题使用 `BrandSerif`（28 逻辑像素，1.4 行高）；生活文案使用系统字体（14，1.9 行高）。页面栏标题为系统字体（18，600 字重）；主题名称为系统字体（17，600 字重）。任务标题、表单、按钮与设置延续 Flutter 文本层级。 |
| 版面 | [共用页面容器](../../apps/mobile/lib/features/account/presentation/account_widgets.dart)采用 `SafeArea`、滚动列表与最大宽度 560；内容边距为左／右 24、上 20、下 32 逻辑像素。主按钮最小尺寸为 48 × 48，内容在短屏与放大字号下通过滚动保持可达。 |
| 形状与层次 | 输入框、实心与描边按钮使用 8 逻辑像素圆角；[我的菜单与主题项](../../apps/mobile/lib/features/account/presentation/profile_pages.dart)使用 12。页面以浅色底面、内容表面与细分隔建立层次，头像和色块使用圆形。 |
| 状态与选择 | 登录显示处理状态、字段错误与重发倒计时；资料保存期间显示进度文案，待确认操作提供「核对保存结果」。主题项以植物预览、名称、三个色块、勾选和选中边界共同表达选择；服务端确认保存后更新全局主题。按下反馈使用当前 Material 默认状态处理与既有颜色映射。 |
| 植物素材 | 登录展示暖杏植物，主题项各自展示对应植物。图片独立于文字与控件，装饰跳过语义读取，加载失败时保留布局。素材来源见[应用素材记录](../../apps/mobile/assets/README.md)；本次任务的来源扫描记录为 3 项、缺失 0 项。 |
| 系统深色设置 | [应用入口](../../apps/mobile/lib/app/app.dart)采用 `ThemeMode.light`；系统深色设置下继续呈现明亮品牌主题，指定双端截图验证这一策略。 |

## 原生截图覆盖

完成评审已逐张查看以下 18 张 OS 原生 PNG；本记录核对了文件数量与尺寸。来源为 iPhone 18 Pro Max／iOS 27.0 Simulator（1320 × 2868）和 Pixel 9／Android API 36 Emulator（1080 × 2424）。

| 状态 | iOS | Android |
| --- | --- | --- |
| 邮箱登录 | [login](../../.impeccable/review/t01/ios-login.png) | [login](../../.impeccable/review/t01/android-login.png) |
| 验证码错误，滚动至表单 | [code-error](../../.impeccable/review/t01/ios-code-error.png) | [code-error](../../.impeccable/review/t01/android-code-error.png) |
| 我的与已保存昵称 | [profile](../../.impeccable/review/t01/ios-profile.png) | [profile](../../.impeccable/review/t01/android-profile.png) |
| 暖杏选择 | [appearance-apricot](../../.impeccable/review/t01/ios-appearance-apricot.png) | [appearance-apricot](../../.impeccable/review/t01/android-appearance-apricot.png) |
| 青瓷选择 | [appearance-celadon](../../.impeccable/review/t01/ios-appearance-celadon.png) | [appearance-celadon](../../.impeccable/review/t01/android-appearance-celadon.png) |
| 雾玫选择 | [appearance-rose](../../.impeccable/review/t01/ios-appearance-rose.png) | [appearance-rose](../../.impeccable/review/t01/android-appearance-rose.png) |
| 外观 1.6 倍字号 | [appearance-large](../../.impeccable/review/t01/ios-appearance-large.png) | [appearance-large](../../.impeccable/review/t01/android-appearance-large.png) |
| 同邮箱恢复昵称与雾玫 | [recovered](../../.impeccable/review/t01/ios-recovered.png) | [recovered](../../.impeccable/review/t01/android-recovered.png) |
| 系统深色设置 | [profile-dark](../../.impeccable/review/t01/ios-profile-dark.png) | [login-dark](../../.impeccable/review/t01/android-login-dark.png) |

完成评审确认上述截图内容对应、系统上下区域完整，大字号外观可读，未发现需要修正的材料性视觉问题。品牌字形、暖纸底面、独立植物、主题识别和非颜色单独表达的选中状态符合本次方向。

## 运行证据与验收边界

[双端集成测试](../../apps/mobile/integration_test/account_test.dart)通过真实本地 Go API、PostgreSQL 与 Mailpit 完成收码、错误反馈、更正登录、昵称保存、三套主题保存、本机会话恢复、退出和同邮箱重新登录；两端日志均记录 `All tests passed!`。当前普通 debug 应用也已构建并启动。执行记录与命令入口由 [T01 工程记录](../engineering/accounts.md)维护，本次文档整理核对已有证据。

集成测试使用 Flutter `TestTextInput` 通道输入文字，截图由模拟器／仿真器的 OS 截屏产生。输入法类型和自动填充提示已配置；原生输入法的弹出、候选、遮挡和提交行为仍需单独验证。[登录组件检查](../../apps/mobile/test/login_widget_test.dart)通过 375 × 667、1.6 倍文字、240 逻辑像素模拟键盘遮挡条件下的验证码更正与登录，结论限于该组件环境。

昵称表单与退出确认已经在双端集成流程中操作，尚缺独立截图，因此当前视觉验收仅覆盖其关联结果。真机、最低系统版本、平板、VoiceOver／TalkBack、实际系统手势、原生输入法、减少动态效果与刷新率尚待验证。截图中的 OS 深色设置覆盖指定的我的／登录状态，其他页面沿用同一明亮主题实现。正式邮件供应商、生产网络与发布签名的验证范围见工程记录。

## 既有规范的适用范围

[DESIGN.md](../../DESIGN.md)与 [.impeccable/design.json](../../.impeccable/design.json)记录浏览器原型体系，T01 按上述 Flutter 规则适配。原型中的完整 `pressed` 色表、浏览器焦点轮廓、动画与控件尺寸拥有各自证据范围；当前 Flutter 按下状态采用 Material 默认处理，本次不将其记作完整 `primaryPressed` token 映射已验收。

[主题文档](themes.md)仍包含原型阶段的数量、素材制作和主题接入待办，以及即时预览的描述；当前 T01 已提供三套独立植物素材、账号级持久化，并在服务端确认后更新主题。这些既有记录的适用阶段与当前实现差异在此登记，后续由对应文档维护任务处理。本次仅增加本验收记录，保留产品约定、全局设计文件、sidecar、原型与实现。
