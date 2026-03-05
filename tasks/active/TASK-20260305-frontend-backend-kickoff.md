# 开发准备任务

## 基本信息

- id: TASK-20260305-001
- title: 前后端开发开工准备与蜂巢协作基线建立
- type: docs
- priority: P0
- status: doing
- owner: Codex
- created_at: 2026-03-05 16:00
- updated_at: 2026-03-05 16:20

## 路由与上下文

- route_model: codex
- route_reason: 任务为本地文档体系梳理与规范落盘，需快速多文件一致性修改
- context_usage_pct: 35%
- compression_summary: 未触发

## 关联关系

- project: mycc
- depends_on:
- related_tasks:

## 目标与范围

- goal: 为即将开始的前后端长周期开发建立统一准备清单与并行执行协议
- in_scope:
  - 建立 `09-开发准备` 目录及核心文档
  - 提供 Agent 设计输入模板
  - 将准备文档接入 planning 索引
- out_of_scope:
  - 前后端代码实现
  - 契约升级到 v1.3

## 执行计划

- plan_step_1: 盘点当前前后端与规划状态
- plan_step_2: 新增开发准备清单与蜂巢并行协议
- plan_step_3: 新增 Agent 设计输入模板并接入索引

## 技术任务尝试记录（技术执行类必填）

- attempt_count: 1
- attempt_summary: 一次性完成文档落盘与索引接入
- stop_reason: 等待用户提供下一批 agent 设计输入

## 交接字段（强制）

- progress: 已完成开发准备文档与模板搭建，可直接进入 agent 设计迭代
- next_step: 接收用户提供的 agent 设计稿并按模板改写为可执行协议
- blocker: 无
- verification: 文档路径存在且已接入 `mycc/planning/README.md`
- risk: 若后续约束继续扩张，需防止 `persona/constitution` 重复漂移
- decision_needed: 是否将该任务状态切到 review

## 验收标准

- acceptance_criteria_1: `09-开发准备` 三份文档齐全并可读
- acceptance_criteria_2: planning 索引包含该目录与文档条目

## 状态流转记录

- transition_1: todo -> doing | by: Codex | at: 2026-03-05 16:00

## 备注

- notes: 后续每个子代理任务建议引用 `0-System/rules/engineering-policy.yaml`
