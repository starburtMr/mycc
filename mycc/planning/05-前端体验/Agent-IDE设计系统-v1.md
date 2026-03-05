# Agent IDE 设计系统（v1）

> 目标：将 MyCC 前端统一为“AI Agent Control Platform”风格，避免退化为普通聊天 UI 或传统 dashboard。  
> 适用范围：`mycc/frontend`（Next.js + Tailwind + shadcn/ui）。

## 1. 产品定位与设计原则

1. 产品定位：`Agent IDE / Operations Console`，不是单纯聊天应用。
2. 设计关键词：`Execution`、`Traceability`、`Observability`、`Controllability`。
3. 功能边界：`Chat 轻交互`、`Task 重执行`、`Debug 工程细节`。
4. 默认策略：聊天优先，按需任务化（`auto` 不强制创建任务）。

## 2. 视觉语言（Dark First）

## 2.1 颜色 Token

基础层：
- `bg-base`: `#0B0F14`
- `bg-panel`: `#111827`
- `bg-elevated`: `#1F2937`
- `bg-hover`: `#273244`

边框层：
- `border-subtle`: `#1F2937`
- `border-normal`: `#374151`
- `border-strong`: `#4B5563`

文字层：
- `text-primary`: `#E5E7EB`
- `text-secondary`: `#9CA3AF`
- `text-muted`: `#6B7280`

功能色：
- `primary`: `#3B82F6` / `#2563EB`
- `success`: `#10B981`
- `warning`: `#F59E0B`
- `error`: `#EF4444`
- `info`: `#06B6D4`

## 2.2 字体与排版

1. UI 字体：`Inter`（`font-sans`）。
2. 代码/事件字体：`JetBrains Mono`（`font-mono`）。
3. 字号层级：`12/14/16/18/20/24`（Tailwind: `text-xs` 到 `text-2xl`）。

## 2.3 间距与圆角

1. 间距采用 `8px grid`：`4/8/16/24/32`。
2. 组件圆角建议：
- 卡片：`rounded-xl`
- 按钮与输入：`rounded-lg`
- 胶囊状态：`rounded-full`

## 2.4 动效规范

1. 统一过渡：`150ms ease-out`。
2. 允许动效：hover、面板展开、tab 切换。
3. 禁止复杂持续动画与过量 spinner。

## 3. 页面结构约束

推荐三栏：
1. 左侧：导航与会话/任务入口（Chat、Tasks、Memory、Skills、System）。
2. 中间：主工作区（Chat View 或 Task View）。
3. 右侧：Debug 抽屉（Events/Routing/Tools/Memory/Verification）。

移动端（<=980px）：
1. 三栏降级为单栏堆叠。
2. Debug 抽屉折叠到主区下方，默认收起。

## 4. 核心组件清单（MVP 必备）

1. `TaskCard`：任务摘要（task_id/title/status/stage/progress）。
2. `StageTimeline`：PLAN -> EXECUTE -> EVAL -> REFLECT。
3. `EventStream`：按 `seq` 渲染事件（支持过滤与搜索）。
4. `ArtifactList`：path/hash/type/size/created_at + 操作。
5. `EngineStatus`：Claude/Codex/EvoMap 的 ready/busy/offline/error。
6. `DebugPanel`：Events/Routing/Tools/Memory/Verification 五个 tab。
7. `MemoryViewer`：Working/Facts/Decisions + TTL + evidence_ref。
8. `SSEStatus`：LIVE/REPLAYING/RECONNECTING/DISCONNECTED。

## 5. 状态系统（前后端一致）

1. Task 状态：
- `queued/running/completed/failed/cancelled`

2. Stage 状态：
- `pending/active/done/failed`

3. Engine 状态：
- `ready/busy/offline/error`

4. Verification 状态：
- `pass/fail/skipped`

5. SSE 状态：
- `live/replaying/reconnecting/disconnected`

## 6. Chat 与 Task 边界（硬约束）

1. Chat 页只展示：
- 用户/助手消息
- Task 摘要卡（`task_started/task_status/task_result`）
- 输入与调度策略（`auto/force_task/chat_only`）

2. Chat 页禁止展示：
- `tool_io` 细节
- `model_routed` 候选细节
- `verification` 细节
- `memory_write` 细节
- 全量事件日志

3. Task 页必须展示：
- run 切换
- 阶段、产物、事件、调试、回放控制
- cancel/retry/resume/export 操作

## 7. 实现约束（Next + Tailwind + shadcn）

1. 设计 Token 统一配置于 Tailwind theme，不允许页面内散落硬编码色值。
2. 业务组件放置建议：
- `components/agent-ide/*`（TaskCard、StageTimeline 等）
- `components/debug/*`
- `components/memory/*`
3. 状态边界：
- TanStack Query：服务端状态
- Zustand：UI 瞬时状态
4. 图标库统一：`lucide-react`。

## 8. 验收标准（Design System 层）

1. 三个核心页面（Chat/Task/Debug）使用统一 token 与组件语义。
2. Chat 页不存在任务细节洪流，Task 页可完整排障。
3. 状态颜色和枚举在页面之间保持一致，无冲突定义。
4. 深色主题可读性达标（主文本对比度可读，弱文本不影响信息识别）。

---

版本：v1  
状态：前端视觉与交互基线（待实现）
