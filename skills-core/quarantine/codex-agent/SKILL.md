---
name: codex-agent
description: 代码实现与修复技能。用于功能实现、Bug 修复、重构、测试补齐、代码审查。触发词：codex、实现、修复、重构、测试、审查代码。
---

# codex-agent（隔离区版）

## 适用场景

1. 需要实际改代码、跑命令、修复问题。
2. 需要以最小改动完成交付并给验证步骤。

## 执行约束

1. 以仓库脚本和项目上下文为准，不使用 `~/.claude/skills/*` 路径。
2. 输出必须包含：
   - 改动文件
   - 验证命令
   - 风险与回滚
3. 任务类操作必须回写 `tasks/` 字段。

## 推荐执行步骤

1. 读取：
   - `tasks/active/<task>.md`
   - 项目 `context/PROJECT_CONTEXT.md`
   - 项目 `context/TOOLING_PROFILE.md`
2. 实施最小改动（必要时补测试）。
3. 运行：
   - `bash scripts/guardrails/check_workspace.sh`
   - 项目测试命令（若定义）
4. 输出结构化结果并回写任务状态。

## 输出模板

1. 结论（是否完成）
2. 改动摘要（文件 + 关键点）
3. 验证结果
4. 未解决风险
5. 下一步
