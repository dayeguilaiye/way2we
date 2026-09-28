disposition: fix

输入边界：本轮是既有设计的浏览器内存原型扩展；FORM 继承已确认的暖杏首页与 DESIGN.md，不要求重新抽取方向。未提供独立 QUALITY BAR 卡，以已批准图片和本轮 brief 为质量依据。按 reviewer 角色仅检查文件与截图；运行流程以 packet 的浏览器验证记录为证，不宣称独立重跑。

## persistence

部分通过。PRODUCT.md、既有 DESIGN.md、批准图片、spec、state、hero-repro 和最终差异报告齐备。八张必看截图均已打开：desktop 1440×1080、mobile 390×846、refund、refund-large 320×780、score、agreement-form、shop、themes；尺寸和内容有效，无空白或畸形捕获。另检查 hero-repro、home-celadon、refund-rose、narrow-large。

完整复现门槛仍未通过：state 停在 `plates`；spec closed，comps skipped 并记录此前批准，plates open，hero pending。my-avatar 与 avatar-b 的细节密度分别为 68% 和 46%；无 forced 记录。最终 comp-diff 总分 0.8641 只说明该次整体比较为 match，不能代替未关闭的构建阶段。此前 hero 报告 0.7544 已由更新后的 final 报告提供当前画面证据。

## fidelity

先看图片形成的元素清单：首页顶部身份／空间／通知、左侧两行宋体文案与右侧真实植物光影、双成员余额、宽记分按钮、待处理交易及就地操作、两条近况、四入口底栏；退款为小标题、商品摘要、退款对象、金额、整笔退款说明和双按钮。

| 元素 | 判定 | 当前证据 |
| --- | --- | --- |
| 首页顺序、主要比例、留白 | match | mobile 与 hero-repro 保持获批首页的叙事和首屏内容。 |
| TYPE | match | 自托管 Noto Serif SC 承担书卷气标题；正文、数字和短确认用清楚的无衬线，符合既有 DESIGN.md。 |
| MATERIAL | adaptation | 真植物、投影与照片均可见；内容底面和按钮保持平整，符合既有 DESIGN.md 对轻氛围、干净操作区的要求。头像精确细节仍受 plates 未通过限制。 |
| GROUND | match | 明亮暖白无明显色温偏移；diff 主色簇为参考 #f7f7ef、实现 #f8f8ee，页面真实底色为 #F8F4EE。 |
| botanical／头像 | adaptation | 独立生成的实拍风素材保持题材、媒介和位置；以原型演示身份为依据，不等同逐像素复现。 |
| notification：报告 missing | match | 已检查配对裁片和全图；固定裁片只截到铃铛一侧，全图有完整且有可访问名称的通知按钮。 |
| avatar-a／activity-a：报告 missing | adaptation | 配对裁片清楚显示夕阳人物照片；是照片内容差异，不是缺图，适用于独立演示素材。 |
| activity-b：报告 missing | adaptation | 截图与代码均使用实际记录操作者阿禾的头像；packet 指明产品真实性修正，参考图在阿禾记录旁画了猫。 |
| score-button／complete-button：报告 contradicted | adaptation | 配对裁片中形状和操作仍在；#A65A40 使用已选角色色改善白字对比，packet 明确该可读性依据。 |
| hero-caption：报告 contradicted | adaptation | 暖杏中完整保留两行文字，颜色加深符合阅读需要；青瓷覆盖问题单列为 material fix。 |
| activity-delta-a／b：报告 contradicted | match | 配对裁片和全图均有完整 −20／+10 数字、正负号和语义色；字形及垂直位置差异触发区域评分，金额未缺失。 |
| 待处理、近况与底部导航 | match | 完成／取消及四个入口均清晰；当前状态同时用颜色、下划线和 aria-current 表示。 |
| 紧凑退款确认 | match | refund 保持已批小标题／正文信息行；320px、160% 字号长内容下说明与两项操作均可见。 |
| 表单、店铺、主题连续性 | match | 表单层级、商品照片、三主题面板与雾玫弹层一致；没有额外嵌套卡片或装饰性标题层级。 |
| 青瓷首页说明文案 | contradicted | home-celadon 中叶片与右侧两行小字重叠，深叶片下的字失去局部对比。 |

THESIS、STORY、FIRST VIEWPORT 与 FORM 在捕获范围内兑现；OWN-WORLD 的青瓷可读性仍待修正。演示身份、内存重置和失败开关标明用途；来源记录存在。源码含真实按钮、表单标签、focus-visible、模态 inert／焦点循环和 reduced-motion。未从所读源码及必看截图发现阻断连续购买／退款的新增交互错误；该判断不扩展到正式端运行行为。

## ceiling

以批准图片为界：首屏植物光影、宋体层级、清楚业务正文和紧凑退款结构已具备。独立质量卡未提供；不增加动效、纹理或新构图要求。cream-palette 警告有用户选定暖杏设计依据。

## material_fixes

1. **复现门槛（已知限制）**：保持 `plates` 未通过的披露；若要宣称完整 fidelity gate 通过，需重新生成 my-avatar、avatar-b 并在原阈值下关闭 plates 与后续阶段；0.8641 整体分数不能替代该步骤。本项不意味着原型头像缺图或交互不可用。
2. **青瓷文案可读性**：调整青瓷装饰的比例／位置或说明位置，使 `home-celadon.png` 右侧两行小字拥有连续清晰底面；保留植物主体，按同一路径重拍 390px 首页并检查窄屏。

## keep

保留已批首页信息顺序、真实植物素材、两种文字层级、紧凑退款说明与全额退款双按钮；保留明确的内存演示范围及现有 gate 限制披露。
