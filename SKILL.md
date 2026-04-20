---
name: github-star-sync
description: 同步 GitHub starred 仓库到 Obsidian，自动分类到 GitHub Lists，生成中文摘要文档和 wiki 索引
argument-hint: "[--full] [--config /path/to/vault]"
---

# /github-star-sync

将 GitHub starred 仓库同步到 Obsidian 仓库，自动分类、创建 GitHub Lists、生成中文摘要文档和 wiki 索引。

## 触发条件

当用户提到以下关键词时触发：
- "同步 star"、"github star"、"star 同步"
- "github-star-sync"
- "管理 star 仓库"、"star 分类"

## 前置依赖

- **gh CLI**：必须安装并认证。检查命令 `gh --version`
- **GH_TOKEN**：需要 `user` + `repo` scope
- **Obsidian vault**：首次运行时询问路径，保存到配置文件

## 执行流程

### Step 0: 环境检查

1. 检查 `gh` 是否安装：`gh --version`
2. 检查认证状态：`gh auth status`
3. 读取配置文件 `.github-star-manager.json`（在 vault 目录下）
   - 无配置则进入首次配置流程（询问 vault 路径）
4. 检查参数：
   - `--full`：全量重新处理（忽略已处理列表）
   - `--config /path/to/vault`：指定 vault 路径

### Step 1: 获取 Starred 仓库

执行 `scripts/fetch-stars.sh`：
- `gh api user/starred --paginate --jq '.[] | {full_name, description, language, topics, stargazers_count, html_url}'`
- 输出 JSON 数组到临时文件
- 与已处理列表对比，得到新增仓库
- 全量模式跳过对比

### Step 2: 自动分类

对每个仓库，基于以下信号推断分类：
- **language**：主语言（如 Python → 倾向开发者工具/AI应用）
- **topics**：仓库标签（如 cli, llm, trading）
- **description**：仓库描述文本

分类映射规则（`scripts/classify.sh`）：

| 关键词信号 | 分类 |
|-----------|------|
| skill, opencode, claude-code | Skills |
| agent, mcp, claude, copilot, cursor | AI Agent 与 Claude 工具 |
| llm, gpt, openai, ai, model, transformer | AI 与 LLM 应用 |
| video, ffmpeg, youtube, stream, subtitle | 视频与媒体 |
| stock, trading, finance, quant, fund | 金融与量化 |
| music, audio, midi, tts, asr | 音乐与音频 |
| wechat, weixin, wx, telegram, bot | 微信与社交 |
| novel, writing, fiction, story | 小说与写作 |
| siyuan, obsidian, note, markdown | 思源笔记 |
| browser, chrome, extension, proxy, network | 浏览器与网络 |
| docker, k8s, deploy, devops, server | Docker 与运维 |
| cli, tool, dev, git, debug, test | 开发者工具 |
| data, csv, json, excel, pdf, doc | 数据与文档 |
| tutorial, course, learn, awesome, book | 学习资源 |
| crawl, spider, scraper, automation | 自动化与爬虫 |
| news, rss, feed, media | 新闻与媒体 |
| security, privacy, encrypt, vpn | 安全与隐私 |
| (未匹配) | 实用工具 |

置信度判断：3 个信号中匹配 2+ → 高置信度自动分配；否则列出候选分类询问用户。

### Step 3: GitHub Lists 管理

执行 `scripts/manage-lists.sh`：

1. **查询已有 Lists**：
```graphql
query { viewer { lists(first: 100) { nodes { id name } } } }
```

2. **创建不存在的 List**：
```graphql
mutation CreateUserList($name: String!) {
  createUserList(input: {name: $name, isPrivate: false}) {
    list { id name }
  }
}
```

3. **获取仓库 node_id**：
```graphql
query { repository(owner: "OWNER", name: "REPO") { id } }
```

4. **添加仓库到 List**：
```graphql
mutation AddToList($itemId: ID!, $listIds: [ID!]!) {
  updateUserListsForItem(input: {itemId: $itemId, listIds: $listIds}) {
    clientMutationId
  }
}
```

### Step 4: 生成中文摘要

执行 `scripts/gen-summary.sh`，对每个仓库：

1. 获取 README：`gh api repos/OWNER/REPO/readme --jq .content | base64 -d`
2. 获取仓库信息：`gh api repos/OWNER/REPO`
3. 使用 AI 生成中文摘要（调用当前模型），包含：
   - 简介段（150-300 字）
   - 核心功能列表
   - 安装方法
   - 使用示例
   - 适用场景
4. 按 `templates/summary.md` 模板写入 vault 分类目录

摘要文件命名：`{repo_name}.md`（特殊字符替换为 `-`）

### Step 5: 更新 wiki.md 索引

执行 `scripts/update-wiki.sh`：

1. 遍历 vault 目录下所有分类子目录
2. 读取每个 .md 文件的 `## 简介` 段
3. 按 `templates/wiki.md` 模板生成索引：
   - 分类导航列表
   - 每个分类的仓库表格
   - 链接中空格编码为 `%20`
   - 简介列展示中文摘要（截断到 120 字）

### Step 6: 更新状态

1. 将本次处理的仓库写入已处理列表（`.processed`）
2. 输出统计报告：
   - 新增仓库数
   - 分类分布
   - 失败数（如有）

## 配置文件格式

`.github-star-manager.json`（保存在 vault 目录下）：

```json
{
  "vault_path": "/path/to/obsidian/vault",
  "github_username": "FountainChan",
  "categories": [
    "Skills",
    "AI Agent 与 Claude 工具",
    "AI 与 LLM 应用",
    "视频与媒体",
    "金融与量化",
    "音乐与音频",
    "微信与社交",
    "小说与写作",
    "思源笔记",
    "浏览器与网络",
    "Docker 与运维",
    "开发者工具",
    "数据与文档",
    "学习资源",
    "自动化与爬虫",
    "新闻与媒体",
    "安全与隐私",
    "实用工具"
  ],
  "last_sync": "2026-04-19T00:00:00Z",
  "total_processed": 171
}
```

## 文件命名与匹配规则

### Vault 文件命名格式

仓库摘要文件使用 `{owner}_{repo}.md` 格式，其中：
- `{owner}` 是仓库所有者名称
- `{repo}` 是仓库名称
- `/` 替换为 `_`

示例：
| GitHub 完整名称 | Vault 文件名 |
|---------------|-------------|
| OpenMOSS/MOSS-TTS-Nano | OpenMOSS_MOSS-TTS-Nano.md |
| datawhalechina/hello-agents | datawhalechina_hello-agents.md |
| anomalyco/opencode | anomalyco_opencode.md |

### 增量同步匹配逻辑

**重要**：匹配时不能简单地将 `owner/repo` 转换为 `owner_repo` 来比较。

正确匹配逻辑（伪代码）：
```python
# 获取 GitHub starred 仓库列表（每行一个 owner/repo）
github_repos = ["OpenMOSS/MOSS-TTS-Nano", "datawhalechina/hello-agents", ...]

# 获取 vault 中所有已处理的仓库文件名（不含 .md 扩展名）
vault_files = ["OpenMOSS_MOSS-TTS-Nano", "datawhalechina_hello-agents", ...]

# 匹配：将 owner/repo 转换为 owner_repo 格式后比较
for gh_repo in github_repos:
    # 例如 "OpenMOSS/MOSS-TTS-Nano" → "OpenMOSS_MOSS-TTS-Nano"
    vault_name = gh_repo.replace('/', '_')
    if vault_name not in vault_files:
        # 这是一个需要同步的新仓库
```

**关键点**：
- Vault 文件名使用下划线 `_` 替代斜杠 `/`
- 匹配时需将 GitHub 的 `owner/repo` 格式转换为 `owner_repo` 格式
- 例如 `OpenMOSS/MOSS-TTS-Nano` → `OpenMOSS_MOSS-TTS-Nano`

## 错误处理

- 单个仓库获取 README 失败 → 跳过 README，基于 description 生成摘要
- GitHub API 限流 → 等待后重试（gh api 自动处理）
- 分类不确定 → 询问用户，提供候选列表
- 网络中断 → 保存进度，下次继续

## 注意事项

- GraphQL 字段名不能猜，必须用 introspection 查询确认
- Token 需要 `user` scope 才能操作 Lists
- 目录名含中文和空格，Markdown 链接中空格必须用 `%20` 编码
- README 内容是 base64 编码，需要解码
- `updateUserListsForItem` 的最小返回字段用 `clientMutationId`
- `deleteUserList` 的参数是 `listId` 不是 `id`
