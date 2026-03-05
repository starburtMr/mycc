# Agent Adapter v1

> 目标：为 Claude/Codex 建立统一调用契约，减少上层业务对底层 SDK 的耦合。

## 1. 统一能力面

仅暴露四类能力：

1. `plan`
2. `act`
3. `review`
4. `memory`

## 2. 输入输出契约

输入：

- `engine`：`claude|codex`
- `action`：`plan|act|review|memory`
- `route_reason`：路由理由（强制）
- `input`：任务载荷（JSON）

输出：

- `engine`、`action`
- `route_reason`
- `status`
- `result.summary`
- `result.next_step`

## 3. 当前实现

- 入口脚本：`scripts/adapters/agent_adapter.py`
- 状态：契约桩（stub），用于先统一调用格式与审计字段。

## 4. 升级路径

1. `adapter.py` 保持稳定。
2. 新增 provider：`claude_provider.py`、`codex_provider.py`。
3. adapter 内部按 `engine` 分发到 provider。
4. 保持上层任务编排器调用方式不变。
