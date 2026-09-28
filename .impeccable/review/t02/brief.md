# T02 原生界面交付范围

模式：Operate。把已采纳的空间、成员、邀请与通知原型接到 Flutter 真实业务；继承 PRODUCT.md、DESIGN.md、prototype/app.js 的 spaces / members / inbox 结构及 T01 控件。用户授权继续 T02；规则、全员同意与邀请链接已确认。本轮为现有产品的功能扩展，未开启视觉方向选择，也没有独立的新页面 comp。

界面：登录后空间列表、创建空间、成员与昵称入口、复制邀请、链接／邀请码预览、接受、加入进度、全员同意、站内通知与跳转。首页近况、约定及购买按 T03—T05 实现。

保留暖杏、青瓷、雾玫三套角色；浅纸面、平整表面、细线、8px 控件与 12px 内容圆角，Noto Serif SC 展示文字及系统业务字体。Botanical 沿用已有 PNG。个人主题跨空间，主题不跟随 OS 深色切换；深色 OS 截图确认这一已选产品行为。操作采用 Flutter 导航、SafeArea、可滚动内容和原生 Material 控件。

新增完整 Noto Serif SC Regular 字形资源，解决仅覆盖原型文本的子集遇到新文案、自设空间名称时混入系统字体的问题；字重固定 400，来源、校验及生成步骤见 apps/mobile/assets/README.md。风格与字体家族延续既定系统。

实际交互：先看邀请对象再接受；当前成员逐一同意；加入后进度变为已加入；通知点击后标记已读并重新获取资源权限。复制为原生 Clipboard；未确认写入保存原意图并禁止新写入，提供恢复入口。读取／业务错误保留简短反馈和可复制请求编号。

验证：iPhone 18 Pro Max / iOS 27 与 Pixel 9 模拟器 / Android API 36，三套主题、文字缩放 1.6，以及最终成员页 OS 深色状态。小屏 375×667 + 1.6 字号 + 240px 键盘 inset 由 Widget 测试验证复制邀请控件；真实 IME、硬件手势、读屏与发布签名不在本轮验证范围。

原生平台未运行 HTML/CSS detector；请以原生截图、工程界面代码与 craft-floor / ios / android 规范评审。DESIGN.md 与 .impeccable/design.json 属于已采纳系统，本轮不修复预先存在的 sidecar 或主题文档漂移。

截图命名：每个平台的 spaces-empty、create-space、members-apricot、invite-share、invite-unavailable、invite-preview、joined、waiting、members-celadon、members-rose、members-large、approval、notifications、members-three、members-dark。每张均来自 simctl / adb。原始文件就是本轮证据，未做图片编辑。
