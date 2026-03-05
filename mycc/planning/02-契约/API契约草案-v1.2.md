# MyCC API 契约草案（v1.2）

## 1. 新增/调整摘要

1. `POST /tasks`、`POST /chat/send` 支持 `Idempotency-Key`。
2. `GET /tasks/:taskId/events` 的 `after` 统一为 `seq`（整数）。
3. 增加 snapshot 生成策略：`task_events` 为真源，`task_snapshot` 为可重建缓存。
4. 鉴权默认策略写死：`local` 无鉴权（仅 127.0.0.1），`lan/tunnel` 强制 session。
5. 响应头统一包含 `x-request-id`。

## 2. 接口变化

## 2.1 POST `/tasks`

请求头：
- `Idempotency-Key: <uuid>`（可选但强烈建议）

行为：
- 相同 key + 相同请求体在窗口期内返回同一 `task_id/run_id`。

## 2.2 POST `/chat/send`

请求头：
- `Idempotency-Key: <uuid>`（可选）

语义：
- v1.2 统一为“默认纯聊天，按需任务化”。
- 新增请求字段 `dispatch_mode`：
  - `auto`（默认）：仅命中任务化条件时创建 task/run
  - `force_task`：强制创建 task/run
  - `chat_only`：仅聊天，不创建 task/run

响应补充：
- 当未任务化时：返回 `task_created=false`，不返回 `task_id/run_id`。
- 当任务化时：返回 `task_created=true`，并返回 `task_id/run_id` 及摘要字段（`status/stage/progress`）。

任务化条件（后端判定）：
1. 明确执行指令（执行、落盘、产出文件、验证、修复）。
2. 预计为异步长任务（超阈值）。
3. 需要工具与副作用操作（文件写入、脚本执行、联网调用）。

## 2.3 GET `/tasks/:taskId/events`

查询参数：
- `run_id`：可选
- `after`：可选，`seq` 整数（仅此一种）

请求头：
- 支持 `Last-Event-ID`（映射为 seq）

## 2.4 GET `/tasks/:taskId`

snapshot 来源：
1. 优先读取 `task_snapshot` 缓存。
2. 缓存缺失或损坏时，从 `task_events` fold 重建。

## 3. 错误结构补充

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
1. 所有响应头返回 `x-request-id`。
2. `task_failed` 事件与 API 错误码枚举保持一致。

---

版本：v1.2
状态：草案（待拍板）
