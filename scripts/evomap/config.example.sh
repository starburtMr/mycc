#!/usr/bin/env bash

# EvoMap 集成开关：1 启用，0 禁用
EVOMAP_ENABLED=1

# EvoMap Hub 地址
EVOMAP_HUB_URL="https://evomap.ai"

# 检索模式：internal | web | full
EVOMAP_SEARCH_MODE="internal"

# 严格模式：1=检索失败则阻断会话开始；0=仅告警不阻断
EVOMAP_STRICT=1

# 只读模式：1=禁止注册/心跳/任务等可调度接口，仅允许知识查询
EVOMAP_READONLY=1
