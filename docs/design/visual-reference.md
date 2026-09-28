# 视觉基准图片索引

三张完整首页图片保存在项目的 `.impeccable/mocks/themes/` 目录，核心业务页面保存在 `.impeccable/mocks/core-v1/`，操作界面与多主题应用保存在 `.impeccable/mocks/actions-v1/`。后续界面设计、实现与视觉校对从本页进入。

| 图片 | 定位 | 项目文件 |
| --- | --- | --- |
| 暖杏枝叶 | 用户选定的整体视觉基准，保留顶部文案与右侧植物装饰 | [apricot-reference.png](../../.impeccable/mocks/themes/apricot-reference.png) |
| 青瓷叶影 | 同一布局下的配色与装饰扩展示例 | [celadon.png](../../.impeccable/mocks/themes/celadon.png) |
| 雾玫花枝 | 同一布局下的配色与装饰扩展示例 | [rose.png](../../.impeccable/mocks/themes/rose.png) |

## 已确认的关键页面

以下四张暖杏主题页面已获用户确认。页面含义与连续数据说明见[关键页面设计](core-pages.md)。

| 页面 | 项目文件 |
| --- | --- |
| 约定列表 | [agreements.png](../../.impeccable/mocks/core-v1/agreements.png) |
| 记一笔 | [score.png](../../.impeccable/mocks/core-v1/score.png) |
| 小卖部 | [shop-v2.png](../../.impeccable/mocks/core-v1/shop-v2.png) |
| 购买详情 | [purchase.png](../../.impeccable/mocks/core-v1/purchase.png) |

## 已确认的操作界面与主题应用

以下设计稿已获用户确认。完整说明与生成提示词见[操作界面设计](action-pages.md)。

| 页面 | 当前项目文件 |
| --- | --- |
| 购买确认 | [purchase-confirm-v2.png](../../.impeccable/mocks/actions-v1/purchase-confirm-v2.png) |
| 退款确认 | [refund-confirm-v2.png](../../.impeccable/mocks/actions-v1/refund-confirm-v2.png) |
| 新建／编辑约定 | [agreement-form.png](../../.impeccable/mocks/actions-v1/agreement-form.png) |
| 我的店铺 | [my-shop.png](../../.impeccable/mocks/actions-v1/my-shop.png) |
| 添加／编辑商品 | [item-form-v2.png](../../.impeccable/mocks/actions-v1/item-form-v2.png) |
| 青瓷约定表单 | [agreement-celadon.png](../../.impeccable/mocks/actions-v1/agreement-celadon.png) |
| 雾玫退款确认 | [refund-rose-v2.png](../../.impeccable/mocks/actions-v1/refund-rose-v2.png) |

## 可点击原型与实际截图

原型入口与操作方法见[使用说明](../../prototype/README.md)，验证范围见[原型验证记录](prototype-validation.md)。当前实现截图保存在 `.impeccable/review/`，用于对照实际字体、控件和长内容状态。

| 界面 | 实际截图 |
| --- | --- |
| 暖杏首页 | [mobile.png](../../.impeccable/review/mobile.png) |
| 紧凑退款确认 | [refund.png](../../.impeccable/review/refund.png) |
| 320 像素宽、160% 字号退款确认 | [refund-large.png](../../.impeccable/review/refund-large.png) |
| 青瓷首页 | [home-celadon.png](../../.impeccable/review/home-celadon.png) |
| 三套外观选择 | [themes.png](../../.impeccable/review/themes.png) |

独立植物、头像与商品图片保存在 `assets/plates/` 和 `prototype/assets/`，当前素材的提示词、生成来源与尺寸保存在同名文件及 `.impeccable/build/asset-provenance.json` 中。

## 后续校对方式

让 agent 实际打开对应图片，与当前界面截图对照，检查整体气质、顶部图文、文字层级、留白、卡片与按钮，以及待处理交易右侧的完成／取消操作。暖杏图片是当前整体视觉依据；青瓷和雾玫用于说明同一设计语言下的主题变化，具体配色仍是候选。

文字与交互以[页面结构与交互草图](app-structure.md)为准，候选色值与个人主题行为以[主题与配色](themes.md)为准，全局视觉原则见 [DESIGN.md](../../DESIGN.md)。布局在真实设备上结合文字缩放、安全区域和长内容适配。

参考图片作为可追溯的基准保留，后续修订另存新版本，并在用户确认后更新本页的基准指向。每张图片的来源与评审状态保存在同名 JSON 中；青瓷与雾玫的生成提示词保存在同名 `.prompt.txt` 中。

可直接给后续 agent 这段指令：

> 请阅读 docs/design/visual-reference.md，打开其中的视觉基准图片，对照当前界面截图校对视觉偏差，并结合 DESIGN.md 与主题配色规范修正。
