---
name: "way2we · 日常信笺"
description: "暖白纸感、克制的自然色彩与植物光影，陪伴成员记录共同生活。"
colors:
  bg: "#F8F4EE"
  surface: "#FFFCF8"
  tint: "#F0DBCE"
  primary: "#A65A40"
  pressed: "#934D36"
  ink: "#352D29"
  secondary: "#71685F"
  divider: "#E4D9CF"
  outline: "#978779"
  celadon-bg: "#F5F6EF"
  celadon-surface: "#FCFCF7"
  celadon-tint: "#E1E8DD"
  celadon-primary: "#506D5D"
  celadon-pressed: "#40594C"
  celadon-ink: "#2D3931"
  celadon-secondary: "#606D61"
  celadon-divider: "#D8DFD3"
  celadon-outline: "#829280"
  rose-bg: "#FAF4F2"
  rose-surface: "#FFFBF8"
  rose-tint: "#EFDFE2"
  rose-primary: "#935D69"
  rose-pressed: "#7B4A56"
  rose-ink: "#3D3034"
  rose-secondary: "#79676C"
  rose-divider: "#E3D6D8"
  rose-outline: "#A0878E"
  on-primary: "#FFFFFF"
  positive: "#4F754D"
  negative: "#AF493B"
typography:
  display:
    fontFamily: "\"Noto Serif SC\", \"Songti SC\", serif"
    fontSize: "2rem"
    fontWeight: 400
    lineHeight: 1.5
  headline:
    fontFamily: "\"Noto Serif SC\", \"Songti SC\", serif"
    fontSize: "calc(1.35rem * var(--zoom))"
    fontWeight: 400
    lineHeight: 1.4
  hero:
    fontFamily: "\"Noto Serif SC\", \"Songti SC\", serif"
    fontSize: "calc(1.1rem * var(--zoom))"
    fontWeight: 400
    lineHeight: 1.55
    letterSpacing: ".04em"
  title:
    fontFamily: "-apple-system, BlinkMacSystemFont, \"PingFang SC\", \"Microsoft YaHei\", sans-serif"
    fontSize: "calc(1.2rem * var(--zoom))"
    fontWeight: 600
    lineHeight: 1.4
  body:
    fontFamily: "-apple-system, BlinkMacSystemFont, \"PingFang SC\", \"Microsoft YaHei\", sans-serif"
    fontSize: "calc(.875rem * var(--zoom))"
    fontWeight: 400
    lineHeight: 1.5
  sheet-body:
    fontFamily: "-apple-system, BlinkMacSystemFont, \"PingFang SC\", \"Microsoft YaHei\", sans-serif"
    fontSize: "calc(1rem * var(--zoom))"
    fontWeight: 400
    lineHeight: 1.5
  label:
    fontFamily: "-apple-system, BlinkMacSystemFont, \"PingFang SC\", \"Microsoft YaHei\", sans-serif"
    fontSize: "1em"
    fontWeight: 400
    lineHeight: 1.45
  balance:
    fontFamily: "-apple-system, BlinkMacSystemFont, \"PingFang SC\", \"Microsoft YaHei\", sans-serif"
    fontSize: "2rem"
    fontWeight: 500
    lineHeight: 1.1
rounded:
  image: "7px"
  control: "8px"
  compact: "9px"
  score-action: "11px"
  surface: "12px"
  sheet: "17px 17px 0 0"
  badge: "20px"
  circle: "50%"
spacing:
  small: ".5rem"
  compact: ".65rem"
  gutter: ".875rem"
  regular: "1rem"
  section: "1.35rem"
components:
  button-primary:
    backgroundColor: "{colors.primary}"
    textColor: "{colors.on-primary}"
    typography: "{typography.label}"
    rounded: "{rounded.control}"
    padding: ".55rem .85rem"
  button-primary-active:
    backgroundColor: "{colors.pressed}"
    textColor: "{colors.on-primary}"
  button-outline:
    backgroundColor: "transparent"
    textColor: "{colors.ink}"
    typography: "{typography.label}"
    rounded: "{rounded.control}"
    padding: ".55rem .85rem"
  button-text:
    backgroundColor: "transparent"
    textColor: "{colors.primary}"
    typography: "{typography.label}"
    rounded: "{rounded.control}"
    padding: ".55rem .85rem"
  score-action:
    backgroundColor: "{colors.primary}"
    textColor: "{colors.on-primary}"
    rounded: "{rounded.score-action}"
    height: "3.72rem"
    width: "100%"
  input:
    backgroundColor: "{colors.surface}"
    textColor: "{colors.ink}"
    rounded: "{rounded.control}"
    padding: ".85rem"
    width: "100%"
  badge:
    backgroundColor: "{colors.tint}"
    textColor: "{colors.primary}"
    rounded: "{rounded.badge}"
    padding: ".18rem .65rem"
  segmented-selected:
    backgroundColor: "{colors.primary}"
    textColor: "{colors.on-primary}"
    rounded: "{rounded.image}"
    padding: ".45rem .8rem"
  agreement-card:
    backgroundColor: "{colors.surface}"
    textColor: "{colors.ink}"
    rounded: "{rounded.surface}"
    padding: "1.2rem 1rem"
  bottom-nav:
    backgroundColor: "{colors.bg}"
    textColor: "{colors.ink}"
    padding: ".55rem .4rem .3rem"
  sheet:
    backgroundColor: "{colors.surface}"
    textColor: "{colors.ink}"
    rounded: "{rounded.sheet}"
    padding: ".55rem 1.2rem 1.8rem"
    width: "100%"
---

# Design System: way2we · 日常信笺

## Overview

**Creative North Star: "日常信笺"**

视觉方向以用户选中的[暖杏枝叶首页](.impeccable/mocks/themes/apricot-reference.png)为依据：精致、清爽、温馨而有分寸。暖色纸面、带书卷感的标题、清楚的业务文字与柔和的植物光影共同构成识别度。装饰停留在内容周围的留白，文字与操作落在清楚的底面上。

本文件从阶段 2.3 的[浏览器原型](prototype/index.html)、[样式](prototype/style.css)、[交互](prototype/app.js)与[字体资源](prototype/assets/fonts/fonts.css)提取当前实现，保留已确认的视觉方向。前置 token 记录浏览器使用值，组件与响应规则用于继续验证原型和移植设计；正式客户端使用 Flutter，原生字号、键盘、返回与安全区域按真实设备验证。

具体页面构图与业务流程分别见[原型说明](docs/design/prototype-brief.md)和[操作界面设计](docs/design/action-pages.md)。参考图片及评审状态见[视觉基准索引](docs/design/visual-reference.md)，运行和视觉验证边界见[原型验证记录](docs/design/prototype-validation.md)。

**Key Characteristics:**

- 明亮的纸面层次与三套完整主题角色。
- 宋体标题、无衬线业务文字与稳定数字宽度。
- 柔和圆角、线性图标和就近的交易操作。
- 真实文字、独立植物图片与简短状态反馈。

## Colors

暖杏以杏陶主色与暖墨建立亲切感；青瓷以灰绿和深绿墨延续安静气质；雾玫以灰玫瑰和梅棕带来柔和变化。三套颜色由原型中的同名 CSS 变量整体替换，暖杏使用无前缀 token，另两套分别使用 `celadon-` 与 `rose-` 前缀。色值以前置 token 为准，主题角色含义与[主题文档](docs/design/themes.md)对应。

### Primary

- **杏陶／青瓷／灰玫主色**（`primary`）：主要按钮、当前导航、选中分段、默认余额及重点数值。
- **按下主色**（`pressed`）：主要按钮按下反馈；白色 `on-primary` 承担主操作文字和 SVG。
- **浅色衬底**（`tint`）：状态标记、网络提示与文字选区。

### Neutral

- **纸面**（`bg`）与 **内容表面**（`surface`）：分别承载页面和卡片、弹层、输入区域。
- **暖墨／绿墨／梅棕**（`ink`）：标题、正文与普通图标；`secondary` 承担时间和说明。
- **细分隔**（`divider`）区分相邻内容；`outline` 为输入和描边控件提供可辨认边界。

积分增加使用 `positive`，减少与错误使用 `negative`；配合实际分值、正负号和说明文字。主题变化保持这些业务语义一致。

**The Complete Theme Rule.** 主题按同名角色整体映射到页面、表面、文字、控件和装饰图；个人选择沿用到本人参与的每个空间。

**The Readable Ground Rule.** 植物的视觉重量留在空白区域，文案与操作需要连续、清晰的底面。

## Typography

**Display Font:** 自托管 Noto Serif SC，回退 Songti SC 与 serif。字体按本原型标题文字提取，使用 `font-display: swap`，来源及 SIL Open Font License 见[字体目录](prototype/assets/fonts/SOURCE.md)。新增文字需检查字形覆盖。

**Body Font:** 系统无衬线栈覆盖 Apple、苹方、微软雅黑及通用 sans-serif，承担中文正文、按钮、表单、导航、数字和短确认标题。

**Character:** 清秀宋体让展示区域带有书卷感，业务文字保持直接、容易扫描。页面以浏览器根字号为单位；当前根字号为 16px，原型阅读开关通过 `--zoom` 提供 1、1.3、1.6 三档。

### Hierarchy

- **Display**：约定、小卖部与记录的页面标题，使用前置 `display`。
- **Headline**：首页分区标题，使用前置 `headline`；其他信息区小标题沿用宋体，实际为 1.4rem。
- **Hero**：首页两行生活文案，使用前置 `hero`。大字体时调整版面和该段文字比例，给完整内容留出高度。
- **Title**：短确认弹层的小标题，使用前置 `title`。页面返回栏使用无衬线中等字重标题。
- **Body / Sheet Body**：普通页面与弹层分别使用前置 `body`、`sheet-body`。弹层内商品名和信息行保持正文尺度，说明文字为该正文的 .875em。
- **Label**：按钮继承所在容器文字尺度，并使用前置 `label` 的行高；导航、时间和辅助说明采用较小的相对字号。
- **Balance**：余额使用前置 `balance`。余额和积分变化均使用 `tabular-nums`，积分单位回到接近正文的尺度。

**The Two Voices Rule.** 宋体承担展示与分区，业务正文、表单、导航和短确认使用无衬线；金额通过字重、主题色或加减语义强调。

## Layout

相关信息紧密成组，主要任务区块保持舒适间距。前置 spacing 记录源码中重复使用的间距，并非额外引入的 CSS 变量。标准内容横向留白为 `gutter`，常用容器内边距为 `regular`；首页分区间距沿用 `section`。

浏览器桌面预览展示 390 × 846px 应用外壳，并按可用高度收缩；演示身份与网络控制位于外壳之外。屏幕宽度不超过 760px 时，应用占满 `100dvh`，演示设置通过独立入口展开。标题与底部导航保持在滚动内容之外，正文和弹层各自滚动。

首页的成员余额采用两列布局，底部导航为四等列；待处理和近况行以图标／头像、内容、数值或动作构成可扫描顺序。具体首页顺序属于原型 brief，其他页面按任务组织。

不超过 360px 时，余额区域收紧头像和间距，待处理操作转入下一行，商品图列缩小。阅读字号放大后，余额头像与文字竖排，交易双方和详情图文改为单列，弹层操作允许换行。长昵称、标题和信息值可折行。

首页植物使用独立透明图片，定位在文案右侧，读屏跳过装饰。青瓷主题的说明文案使用专属横向位置避开叶片，大字体布局再归入下方留白。原型中的状态栏、底部手势条和比较截图模式属于浏览器演示呈现；Flutter 实现采用平台提供的安全区域与文字缩放行为。

## Elevation & Depth

页面以纸面和内容表面的明度差建立温润层次，细线区分连续记录。植物图片自身的柔光和叶影提供自然氛围，卡片在静止状态保持平整。弹层以半透明暖黑遮罩分离前后内容；短暂反馈浮在页面上。

### Shadow Vocabulary

- **Toast**（`0 5px 18px #352d291f`）：短暂文字反馈的柔和投影。
- **Preview shell**（`0 18px 55px #44342821`）：桌面演示设备外壳；手机宽度下取消外壳投影和圆角。

**The Quiet Paper Rule.** 业务表面以底色明度和细分隔建立层次，投影仅用于浮起反馈与桌面预览外壳。

## Shapes

表面、操作控件和图片使用前置 rounded 的柔和圆角。内容表面与主题选项使用 `surface`，输入与普通按钮使用 `control`，分段内项与商品缩略图使用 `image`；徽标使用 `badge`，头像使用 `circle`。底部弹层只处理顶部两角，使用 `sheet`。

描边按钮与输入采用单像素 `outline` 边界，内容分隔采用单像素 `divider`。选中主题采用双像素主色边界，同时微调内边距保持尺寸稳定。SVG 图标采用 24 单位视框、1.65 的线宽、圆端点和圆连接，图形与主题继承同一文字色。

## Components

### Buttons

主要操作清楚、柔和，普通按钮采用前置 `button-primary`、`button-outline` 和 `button-text`。标准最小高度为 2.75rem；主操作按下使用 `pressed`，按钮按下移动 1px。键盘焦点使用主色双像素轮廓，向外留 3px。当前触屏原型没有独立悬停动画。

首页「记一笔」沿用 `score-action` 的高度和圆角，并配合线性加号图标。提交时显示「处理中…」，控件暂时禁用；当前原型以降低透明度表示禁用。校验失败在相关字段或弹层中给出文字原因。

### Chips

状态标记沿用 `badge`，主色文字放在浅衬底上；次要状态使用分隔色衬底和次要文字。分段选择以边框容器包裹等宽选项，当前选项使用 `segmented-selected`。

### Cards / Containers

约定卡片沿用 `agreement-card`，标题与分值同排，适用成员和就近操作置于下方。商品采用图文行，商品无图片时使用单列。连续记录共享表面和细分隔，积分变化靠右，状态由文字表达。详情的信息行左右排列标签和值，长值可折行。

### Inputs / Fields

输入框使用前置 `input`、清楚标签及次要色占位文字；多行输入可随内容扩展。焦点沿用全局主色轮廓。复选和单选保留原生控件行为，以主题主色表达选择；错误文字使用 `negative` 并关联当前操作。

### Navigation

底部导航沿用 `bottom-nav`，线性 SVG 与文字垂直排列。当前项使用主色、短下划线和 `aria-current`。详情使用顶部返回栏，表单主要操作置于内容之外的底部操作区。

### Confirmation Sheet

短确认沿用 `sheet`，最大高度为应用区域的 90%，内容超出时滚动。小标题、商品摘要、对象、正文尺度金额、说明与操作构成连续阅读顺序。遮罩出现时背景区域 `inert`，焦点进入弹层并限制在内部；关闭后恢复触发控件焦点，支持 Escape。

弹层以 240ms 的 `cubic-bezier(.16,1,.3,1)` 从下方 20px 淡入；反馈文字以 150ms 切换透明度，显示约 2600ms。系统偏好减少动态时关闭动画与过渡。主题点选即时生效并显示勾选，原型保留当前空间与操作位置。

## Do's and Don'ts

### Do:

- Do 保留精致、清爽、温馨的日常信笺气质，让独立植物图片围绕文字留白。
- Do 以同一角色映射覆盖按钮、导航、弹层、表单与反馈，并分别检查三套主题。
- Do 保持头像和商品图片原始内容，使用真实文字、独立 SVG 与可访问控件。
- Do 用正负号、状态文字及选中标记补充颜色，用长内容与放大字号检查换行和滚动。
- Do 在 Flutter 中延续语义层级与主题关系，并验证原生安全区域、系统字号和触控。

### Don't:

- Don't 将生成概念图中的文字、数值和控件作为整张界面图片交付。
- Don't 把短确认的商品摘要和退款金额扩大成展示标题。
- Don't 用主题滤镜修改头像或商品图片的内容。
