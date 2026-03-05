# Replay Fixtures 规范（v1）

## 1. 目标

1. 前端联调不依赖真实模型。
2. CI 可稳定重放事件流。

## 2. 运行模式

1. `connectivity_mode=replay`
2. adapter 不调用真实引擎，读取 `fixtures/*.jsonl`

## 3. 数据格式

1. 每行一个事件对象。
2. 字段遵循事件字典：`event_id, seq, type, payload, meta`。
3. 同一 fixture 内 `seq` 必须递增。

## 4. 最小 Fixture 集

1. `normal_success.jsonl`：完整成功流程。
2. `retryable_failure.jsonl`：可重试失败流程。
3. `stream_reset.jsonl`：流重置与恢复流程。

## 5. 校验

1. 读取前校验 schema。
2. 不合法 fixture 不得进入测试。

---

状态：联调与 CI 规范
