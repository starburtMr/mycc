# Agent-Reach 系统调用手册

> 目的：把 Agent-Reach 的平台能力固化成可执行调用规则，方便 Claude/Codex 按统一口径调用。

## 1. 平台能力矩阵（系统版）

| 平台 | 装好即用 | 配置后解锁 | 系统内推荐触发词 |
| --- | --- | --- | --- |
| 网页 | 读取任意网页 | - | 帮我看看这个链接 |
| YouTube | 字幕提取、视频信息 | - | 这个视频讲了什么 |
| RSS | 读取 RSS/Atom | - | 订阅这个 RSS |
| 全网搜索 | - | Exa 语义搜索 | 搜一下全网关于 XXX |
| GitHub | 公共仓库读取/搜索 | 私有仓库、Issue/PR/Fork | 帮我登录 GitHub |
| Twitter/X | 读单条推文 | 搜索推文、时间线、发推 | 帮我配 Twitter |
| B站 | 本地字幕提取/搜索 | 服务器代理后可用 | 帮我配代理 |
| Reddit | Exa 搜索 | 帖子与评论读取 | 帮我配代理 |
| 小红书 | - | 阅读/搜索/互动 | 帮我配小红书 |
| 抖音 | - | 解析与下载链接 | 帮我配抖音 |
| LinkedIn | Jina 读公开页 | 详情/公司/职位 | 帮我配 LinkedIn |
| Boss直聘 | Jina 读职位页 | 搜索职位/打招呼 | 帮我配 Boss直聘 |
| 微信公众号 | - | 搜索+全文阅读 | 帮我配微信公众号 |

## 2. 系统调用路由（强制）

1. 任务执行前先走 EvoMap 经验预检（`session_start.sh` 已强制）。
2. 需要联网检索时调用统一入口：

```bash
bash scripts/integrations/web_search.sh --query "<问题>" --task tasks/active/<task>.md
```

3. 路由逻辑：`EvoMap -> mcporter(exa)`。
4. 若仍未命中，再按平台专用工具调用（xreach/gh/yt-dlp/r.jina.ai 等）。

## 3. 触发词到命令映射

| 用户意图 | 系统命令 |
| --- | --- |
| 帮我看看这个链接 | `curl https://r.jina.ai/<URL>` |
| 这个 GitHub 仓库是做什么的 | `gh repo view owner/repo` |
| 搜一下 GitHub 上有什么 XXX | `gh search repos "<query>"` |
| 这个视频讲了什么 | `yt-dlp --dump-json <URL>` |
| 帮我看看这条推文 | `xreach tweet <URL> --json` |
| 搜 X 上关于 XXX | `xreach search "<query>" --type latest -n 20 --json` |
| 先全网搜 XXX | `bash scripts/integrations/web_search.sh --query "<query>"` |

## 4. 安装与更新标准动作

### 4.1 安装

```bash
bash scripts/integrations/agent_reach/full_install.sh auto
```

### 4.2 安全模式安装

```bash
bash scripts/integrations/agent_reach/full_install.sh auto --safe
```

### 4.3 健康检查

```bash
bash scripts/integrations/agent_reach/doctor.sh
bash scripts/integrations/agent_reach/diagnose.sh
```

### 4.4 更新

```bash
bash scripts/integrations/agent_reach/update.sh
```

## 5. Cookie 与代理策略

1. 需要 Cookie 的平台默认使用专用小号，禁止主号。
2. Cookie 仅保存在本地，不入库、不外传。
3. 本地开发默认不配代理；服务器场景再配代理。
4. 代理配置完成后必须重跑 `doctor` 和 `diagnose`。

## 6. 安全边界（系统约束）

1. 禁止自动修改 `.claude/` 目录。
2. `.codex/` 改动必须可审计并可回滚。
3. 写操作（发帖、评论、点赞、发推）默认禁用，需用户明确授权。
4. 所有联网结果必须写明来源与时间戳。

## 7. 结果回写规范

- 检索结果：写入 `2-Projects/<project>/context/WEB_SEARCH_LAST.json` 或 sessions 目录。
- 诊断结果：写入 `3-Thinking/sessions/<session_id>/agent-reach-diagnose.json`。
- 任务记录：在任务文件更新 `verification` 与 `risk` 字段。

