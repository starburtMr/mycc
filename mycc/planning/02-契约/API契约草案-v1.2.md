# MyCC API 契约草案（v1.2）

> 目标：明确前后端通信协议，支持“默认聊天、按需任务化、可回放执行”。  
> 范围：MVP REST + SSE（不含 WebSocket）。

## 1. 协议总则

1. 基础前缀：`/v1/*`
2. 请求/响应：`Content-Type: application/json`（SSE 除外）
3. 响应头必须带：`x-request-id`
4. 幂等支持：`POST /tasks`、`POST /chat/send` 支持 `Idempotency-Key`
5. 鉴权策略：
- `local`：仅 `127.0.0.1`，可无鉴权
- `lan/tunnel`：强制 session/cookie

## 2. 枚举定义

1. `dispatch_mode`
- `auto`（默认）：仅命中任务化条件才创建 task/run
- `force_task`：强制创建 task/run
- `chat_only`：仅聊天，不创建 task/run

2. `task_status`
- `queued/running/completed/failed/cancelled`

3. `stage`
- `PLAN/EXECUTE/EVAL/REFLECT`

## 3. 核心接口

## 3.1 POST `/chat/send`

请求：
```json
{
  "session_id": "sess_20260305_01",
  "message": "帮我给备份系统出可执行方案",
  "dispatch_mode": "auto",
  "context_refs": ["memory://decision/42"]
}
```

响应（纯聊天）：
```json
{
  "ok": true,
  "task_created": false,
  "reply": {
    "text": "先给你方案，不创建任务。"
  }
}
```

响应（任务化）：
```json
{
  "ok": true,
  "task_created": true,
  "task": {
    "task_id": "tsk_20260305_x1",
    "run_id": "run_20260305_01",
    "status": "running",
    "stage": "PLAN",
    "progress": 10
  },
  "reply": {
    "text": "已创建任务，详情见任务页。"
  }
}
```

任务化条件（后端判定）：
1. 明确执行指令（执行/落盘/产出文件/跑验证/修复）。
2. 预计为异步长任务（超阈值）。
3. 需要工具与副作用操作（文件写入、脚本执行、联网调用）。

## 3.2 POST `/tasks`

用途：显式创建任务（非聊天入口）。

请求：
```json
{
  "title": "备份恢复优化",
  "goal": "降低恢复失败率",
  "constraints": ["先查 EvoMap", "保留回滚"],
  "engine_preference": "auto"
}
```

响应：
```json
{
  "ok": true,
  "task_id": "tsk_20260305_x1",
  "run_id": "run_20260305_01",
  "status": "queued"
}
```

## 3.3 GET `/tasks`

用途：任务列表页。

查询参数：
- `status`（可选）
- `q`（可选，标题/ID 检索）
- `page`（默认 1）
- `page_size`（默认 20，最大 100）

## 3.4 GET `/tasks/:taskId`

用途：任务详情快照（可用于刷新恢复）。

行为：
1. 优先读取 `task_snapshot` 缓存。
2. 缓存缺失或损坏时，从 `task_events` fold 重建。

响应关键字段：
- `task_id`
- `latest_run_id`
- `status/stage/progress`
- `route_reason`
- `artifacts_summary`

## 3.5 GET `/tasks/:taskId/events`

用途：SSE 事件流 + 回放。

查询参数：
- `run_id`：可选（不传则 latest run）
- `after`：可选，`seq` 整数（唯一光标）

请求头：
- 支持 `Last-Event-ID`（映射为 `after`）

响应头：
- `Content-Type: text/event-stream`
- `Cache-Control: no-cache`
- `Connection: keep-alive`

## 3.6 任务控制端点

1. `POST /tasks/:taskId/cancel`
2. `POST /tasks/:taskId/retry`
3. `POST /tasks/:taskId/resume`

返回统一：
```json
{
  "ok": true,
  "task_id": "tsk_20260305_x1",
  "run_id": "run_20260305_02",
  "status": "running"
}
```

## 4. SSE 事件传输格式

服务端输出：
```text
id: 128
event: task_status
data: {"event_id":"evt_128","seq":128,"task_id":"tsk_...","run_id":"run_...","type":"task_status","payload":{"status":"running","stage":"EXECUTE","progress":45},"meta":{"request_id":"req_..."}}
```

规则：
1. `id` 必须等于 `seq`，便于浏览器侧断线续传。
2. 同一 `run_id` 内 `seq` 严格递增。
3. 事件先落库，再推流。

## 5. 错误协议

统一错误结构：
```json
{
  "ok": false,
  "error": {
    "code": "INTERNAL_ERROR",
    "message": "xxx",
    "details": [],
    "request_id": "req_xxx"
  }
}
```

补充要求：
1. API 错误码与 `task_failed.payload.code` 对齐。
2. 可重试错误必须显式标注 `retryable=true`（事件层）。

## 6. 仍待拍板（当前决策建议）

1. `GET /tasks` 的筛选字段是否扩展到 `engine/owner`。
2. `chat/send` 是否支持流式文本直出（当前建议仅走 task 事件流）。

---

版本：v1.2  
状态：草案（待拍板）
