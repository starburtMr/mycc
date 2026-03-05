# 规则暂存区（Staging）

> 用途：新规则先进入暂存区，连续验证通过后再晋级到稳定区。

## 记录格式

- id: RULE-YYYYMMDD-xxx
- source_session: SESSION_ID
- proposal: 可执行规则（一句话）
- trigger: 触发条件
- verify: 验证方式
- result: pass/fail
- next_action: promote/revise/drop

## 规则条目

