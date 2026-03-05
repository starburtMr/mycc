# MyCC API 契约草案（v1.1）

> 目标：支持“聊天入口 + 任务编排 + SSE 回放 + 可恢复执行”。

## 1. 通用规则

## 1.1 Base

- Base URL: `/v1`
- Content-Type: `application/json`
- 鉴权：`Authorization: Bearer <token>`（SSE 可用 cookie 或 query token）

## 1.2 统一响应

成功：
```json
{ "ok": true, "data": {} }
```

失败：
```json
{
  "ok": false,
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "constraints 不能为空",
    "details": [{"path":"constraints","issue":"Required"}],
    "request_id": "req_xxx"
  }
}
```

## 1.3 错误码枚举

- `VALIDATION_ERROR` (400)
- `UNAUTHORIZED` (401)
- `FORBIDDEN` (403)
- `NOT_FOUND` (404)
- `RATE_LIMITED` (429)
- `CONFLICT` (409)
- `INTERNAL_ERROR` (500)
- `EVOMAP_PRECHECK_FAILED` (412)

## 2. 系统接口

## 2.1 GET `/system/status`

用途：服务健康状态、运行模式与引擎可用性。

响应示例：
```json
{
  "ok": true,
  "data": {
    "mode": "local",
    "version": "0.1.0",
    "engines": {"claude":"ready","codex":"ready"},
    "evomap_precheck": true
  }
}
```

## 2.2 GET `/skills`

用途：返回可调用技能清单（注册表过滤后）。

## 3. 聊天接口

## 3.1 POST `/chat/send`

用途：聊天入口（轻量任务可直接返回流式结果）。

请求：
```json
{
  "session_id": "sess_xxx",
  "message": "帮我分析这个需求",
  "engine_preference": "auto"
}
```

响应：
```json
{
  "ok": true,
  "data": {
    "session_id": "sess_xxx",
    "task_id": "tsk_xxx",
    "stream_url": "/v1/tasks/tsk_xxx/events"
  }
}
```

## 3.2 POST `/chat/pair`

用途：移动端配对。

请求：
```json
{
  "pair_code": "123456",
  "challenge": "random_nonce"
}
```

说明：短码有 TTL，失败触发限流。

## 4. 任务接口

## 4.1 POST `/tasks`

用途：创建任务并进入编排。

请求：
```json
{
  "title": "备份恢复系统优化",
  "goal": "输出可执行方案并沉淀",
  "constraints": ["先查EvoMap", "最小改动"],
  "engine_preference": "auto",
  "connectivity_mode": "local"
}
```

响应：
```json
{
  "ok": true,
  "data": {
    "task_id": "tsk_xxx",
    "run_id": "run_xxx",
    "status": "queued"
  }
}
```

## 4.2 GET `/tasks/:taskId`

用途：读取任务快照。

## 4.3 GET `/tasks/:taskId/runs/:runId`

用途：读取某次运行详情。

## 4.4 POST `/tasks/:taskId/cancel`

用途：取消当前运行。

## 4.5 POST `/tasks/:taskId/retry`

用途：基于同任务创建新 run。

## 4.6 POST `/tasks/:taskId/resume`

用途：从阶段检查点恢复。

## 5. SSE 事件流

## 5.1 GET `/tasks/:taskId/events`

查询参数：
- `run_id`：可选，默认当前 run
- `after`：可选，按事件 id 或 seq 回放

请求头：
- 支持 `Last-Event-ID`

响应头：
- `Content-Type: text/event-stream`
- `Cache-Control: no-cache`
- `Connection: keep-alive`

事件幂等字段（必须）：
- `event_id`
- `seq`
- `task_id`
- `run_id`
- `ts`

## 5.2 事件类型

- 状态类：`run_created` `status_changed` `stage_changed` `progress_updated`
- 内容类：`assistant_delta` `tool_io` `artifact_emitted`
- 审计类：`model_routed` `verification` `memory_write`
- 生命周期：`task_completed` `task_failed` `heartbeat`

示例：
```json
{
  "event_id": "evt_01",
  "seq": 12,
  "task_id": "tsk_xxx",
  "run_id": "run_xxx",
  "ts": "2026-03-05T14:30:00Z",
  "type": "model_routed",
  "payload": {
    "engine": "codex",
    "route_reason": "任务为代码实现，且需本地执行能力"
  }
}
```

## 6. 执行闸门（系统级）

1. 创建任务后，执行阶段前必须通过 EvoMap 预检。
2. 预检失败返回 `EVOMAP_PRECHECK_FAILED`，不得进入 EXECUTE。
3. 每次模型路由都必须产出 `model_routed` 事件并写入 `route_reason`。

## 7. 数据模型（最小）

- `tasks`：任务定义
- `task_runs`：运行实例
- `task_events`：事件账本（含 seq）
- `artifacts`：产物索引（path/hash/type）

---

版本：v1.1
状态：草案（待实现联调）
