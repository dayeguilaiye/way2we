---
stepsCompleted: [1, 2, 3, 4, 5, 6, 7]
inputDocuments:
  - _bmad-output/prd.md
  - _bmad-output/project-planning-artifacts/product-brief-way2we-2025-12-26.md
workflowType: 'ux-design'
lastStep: 0
project_name: 'way2we'
user_name: 'Ziyuanhe'
date: '2025-12-29T10:09:22Z'
---

# UX Design Specification way2we

**Author:** Ziyuanhe
**Date:** 2025-12-29T10:09:22Z

---

<!-- UX design content will be appended sequentially through collaborative workflow steps -->

## Executive Summary

### Project Vision

way2we 是一款面向情侣与亲子关系的互动激励移动应用，通过“约定/规则 → 积分 → 兑换 → 履约确认”的闭环机制，把日常付出转化为可被看见、认可与回报的体验，帮助关系长期稳定与正向互动。

### Target Users

- 主要用户：同居/已婚情侣，以及孩子 6 岁以上的现代父母  
- 次要用户：可上网的孩子（6+）  
- 用户技术熟练度较低，主要使用 iPhone 与 Android 手机，在家中日常场景使用

### Key Design Challenges

- 让低技术熟练度用户也能轻松完成规则创建、积分记录与兑换确认  
- 情侣与亲子场景并存，权限与审核既要公平可信又不能复杂  
- 日常高频使用场景下，操作需要足够轻量，避免打断生活节奏

### Design Opportunities

- 用即时反馈与情感化表达强化“被看见/被认可”的核心价值  
- 以积分与兑换进度的清晰可视化增强动力与持续性  
- 提供默认规则模板与简化引导，降低首次上手门槛

## Core User Experience

### Defining Experience

way2we 的核心体验围绕高频“完成约定”展开：用户日常完成健身、家务等约定并获得积分反馈。创建约定与设置商品也要足够轻松，但最关键的高频交互是“完成约定”，必须做到极致顺滑与零负担。

### Platform Strategy

仅做移动端 App，采用 Flutter；支持移动尺寸的 Web 版用于开发与测试，但正式发布仍为纯 App。主要触屏操作，设备能力侧重相册与通知，不需要离线能力。

### Effortless Interactions

需要做到“几乎不用思考”的动作包括：完成约定、兑换商品、确认约定/兑换。尤其是完成与确认必须顺滑高效；支持自动确认/自动完成的配置，以减少高频操作负担。

### Critical Success Moments

用户“兑换成功”是关键成功时刻，直接体现价值闭环。  
完成约定失败或兑换失败会严重破坏体验，是核心风险点。

### Experience Principles

- 以“完成约定”的高频操作为第一优先级，极简、顺滑、零负担  
- 兑换与确认流程必须稳定可靠，确保成功闭环  
- 配置自动化优先，减少重复确认与摩擦  
- 移动端触屏体验优先，流程短、反馈清晰

## Desired Emotional Response

### Primary Emotional Goals

- 被看见、被认可、有掌控感  
- 成就感与温暖感并存，愿意持续参与  
- 建立信任，感到公平与安心

### Emotional Journey Mapping

- 初次发现：好奇、被吸引，感觉“这能解决我的问题”  
- 核心操作中（完成约定/兑换）：顺畅、轻松、安心  
- 完成后：满足、被肯定、关系更亲近  
- 出错/失败时：被安抚、有清晰引导，不被责怪  
- 复访时：期待、信任、习惯化使用

### Micro-Emotions

- 自信 > 困惑  
- 信任 > 怀疑  
- 成就感 > 挫败  
- 愉悦/满足并重

### Design Implications

- 关键操作用清晰反馈和即时认可强化“被看见”  
- 失败场景提供温和解释与补救路径，降低挫败  
- 通过可视化进度和稳定规则建立信任感  
- 高频流程保持短路径与低认知负担

### Emotional Design Principles

- 以肯定与认可为默认语气，避免冷硬指令  
- 操作结果即时反馈，让用户持续获得正向情绪  
- 失败也给出尊重与支持，维持关系感与信任

## UX Pattern Analysis & Inspiration

### Inspiring Products Analysis

- TODO 类应用（高设计感/完成体验优秀的清单类）  
  - 优点：完成动作极简、反馈明确、进度清晰、使用成本低  
  - 价值：适合高频“完成约定”的核心动作设计
- 积分兑换类应用（多数体验不佳）  
  - 问题：流程冗长、层级复杂、界面信息噪声高、反馈不清晰  
  - 价值：提示我们要避免将“兑换”做得像复杂电商流程

### Transferable UX Patterns

- 完成动作一键化：完成约定应该像勾选待办一样顺滑  
- 低层级信息结构：减少步骤与页面跳转  
- 明确的即时反馈：完成后给予清晰确认与情感化反馈

### Anti-Patterns to Avoid

- 兑换流程过长、步骤过多  
- 信息堆叠导致用户难以找到核心操作  
- 视觉杂乱、过度促销化的积分商城体验

### Design Inspiration Strategy

**Adopt**
- TODO 类应用的“完成即反馈”与“低认知负担”模式

**Adapt**
- 把任务完成与积分反馈结合，但保持轻量化流程

**Avoid**
- 积分兑换类应用的复杂层级与视觉噪声

## Design System Foundation

### 1.1 Design System Choice

选择“可主题化设计系统”作为基础，组件与版式规范统一，但色彩提供多套主题选择。

### Rationale for Selection

- 团队设计能力较弱，需要成熟组件与交互模式保障质量  
- 希望有优秀设计且可快速落地，主题化系统更高效  
- 时间宽松，允许在色彩主题上精细打磨  
- 不开放用户自行调色，改为提供有限但高质量的色彩主题

### Implementation Approach

- 采用统一的字体、间距、圆角、阴影与组件结构规范  
- 预设 2-3 套完整色彩主题（主色、辅色、背景、文本、状态色）  
- 所有页面与组件依赖设计 token，确保一致性与可维护性

### Customization Strategy

- 只允许切换“色彩主题”，其余设计规范固定  
- 每套主题需匹配“温暖、被认可、信任”的情绪目标  
- 后续可基于用户反馈微调主题色，但不破坏整体规范

## 2. Core User Experience

### 2.1 Defining Experience

决定性核心体验是“完成约定并立即获得认可与积分反馈”。用户会把它描述为：在 app 里一键完成今天的约定（比如健身/家务），立刻得到积分与确认，让付出被看见。

### 2.2 User Mental Model

目前用户通常没有意识到“日常付出可被量化并兑现”，更多依赖口头沟通或模糊约定。  
他们期待的是“像勾选待办一样顺手”，不用复杂流程，就能确认和获得回馈。

### 2.3 Success Criteria

- 一键完成，无需多步确认  
- 反馈即时且清晰（积分变动、被认可的提示）  
- 不会失败或卡住，流程稳定可靠  
- 完成后明确知道“我成功了、积分到账了”

### 2.4 Novel UX Patterns

核心动作以“待办完成”这种成熟模式为主，用户无需学习新交互；  
创新点在于将“完成”与“认可/积分/兑换闭环”结合，但交互保持熟悉与轻量。

### 2.5 Experience Mechanics

**启动**：用户从首页/提醒进入“今日约定”列表  
**互动**：点击完成按钮/滑动完成动作  
**反馈**：即时积分增长 + 认可提示 + 状态变更  
**完成**：约定状态变为已完成，并可进入兑换或查看记录
