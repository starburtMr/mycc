# 任务模板

> 用途：通用任务主模板。所有活跃任务建议基于此文件创建。

## 基本信息

- id: 任务唯一 ID（建议 `TASK-YYYYMMDD-序号`）
- title: 任务标题（动宾结构）
- type: 任务类型（feature/bug/refactor/docs/research 等）
- priority: 优先级（P0/P1/P2）
- status: todo
- owner: User
- created_at: YYYY-MM-DD HH:mm
- updated_at: YYYY-MM-DD HH:mm

## 路由与上下文

- route_model: 本轮执行模型
- route_reason: 选择该模型的原因
- context_usage_pct: 当前上下文占用（如 45%）
- compression_summary: 达到 60% 后的阶段摘要

## 关联关系

- project: 所属项目目录名
- depends_on: 前置任务 ID
- related_tasks: 相关任务 ID 列表

## 目标与范围

- goal: 本任务要达成的结果
- in_scope: 本任务包含内容
- out_of_scope: 本任务不包含内容

## 执行计划

- plan_step_1:
- plan_step_2:
- plan_step_3:

## 技术任务尝试记录（技术执行类必填）

- attempt_count:
- attempt_summary:
- stop_reason:

## 交接字段（强制）

- progress:
- next_step:
- blocker:
- verification:
- risk:
- decision_needed:

## 验收标准

- acceptance_criteria_1:
- acceptance_criteria_2:

## 状态流转记录

- transition_1: todo -> doing | by: | at:
- transition_2: doing -> review | by: | at:
- transition_3: review -> done | by: | at:

## 备注

- notes:
