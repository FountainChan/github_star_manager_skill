# ⭐ GitHub Star Manager Skill

> 🧠 自动同步 GitHub starred 仓库到 Obsidian，智能分类、生成中文摘要、维护索引

## 🎯 功能概览

| 功能 | 说明 |
|------|------|
| 🔄 **增量同步** | 检测新 star 的仓库，只处理新增部分 |
| 🏷️ **智能分类** | AI 读取仓库信息后智能推断分类，低置信度时询问用户 |
| 📋 **GitHub Lists** | 自动创建 Lists 并分配仓库（GraphQL API） |
| 📝 **中文摘要** | 获取 README，生成详细的中文摘要文档（含安装、使用示例） |
| 📑 **Wiki 索引** | 自动维护 `wiki.md` 分类导航 + 仓库表格 |
| ⚙️ **首次配置** | 交互式引导，保存配置供后续使用 |

## 📂 目录结构

```
github-star-manager-skill/
├── 📘 SKILL.md                  # Skill 主文件（触发条件、执行流程）
├── 📰 README.md                 # 本文件
├── 📁 scripts/
│   ├── 🔍 fetch-stars.sh        # 获取 starred 仓库列表（增量/全量）
│   ├── 🏷️ classify.sh           # AI 智能分类逻辑
│   ├── 📋 manage-lists.sh       # GitHub Lists CRUD（GraphQL）
│   ├── 📝 gen-summary.sh        # 获取 README + 仓库信息
│   └── 📑 update-wiki.sh        # 生成 wiki.md 索引
└── 📁 templates/
    ├── 📄 summary.md             # 摘要文件模板
    └── 📄 wiki.md                # Wiki 索引模板
```

## 🚀 使用方法

在 opencode 中执行：

```
/github-star-sync
/github-star-sync --full              # 全量重新处理
/github-star-sync --config /path/to   # 指定 Obsidian vault 路径
```

## 📦 依赖

| 依赖 | 用途 | 安装 |
|------|------|------|
| ✅ **gh CLI** | GitHub API 调用 | [cli.github.com](https://cli.github.com/) |
| ✅ **GH_TOKEN** | 需 `user` + `repo` scope | `gh auth login` |
| ✅ **jq** | JSON 解析 | 包含在 gh CLI 中 |

## 🔄 执行流程

```
1️⃣ 环境检查 → 检查 gh CLI、认证状态、读取配置
     ↓
2️⃣ 获取仓库 → 分页拉取 starred 列表，对比已处理列表
     ↓
3️⃣ 智能分类 → 自动推断分类，低置信度时询问用户
     ↓
4️⃣ Lists 管理 → 创建/复用 GitHub Lists，分配仓库
     ↓
5️⃣ 生成摘要 → 获取 README，AI 生成中文摘要 .md
     ↓
6️⃣ 更新索引 → 重新生成 wiki.md（%20 编码 + 中文简介）
     ↓
7️⃣ 输出报告 → 统计新增数、分类分布、失败数
```

## ⚠️ 注意事项

- 🔑 GitHub Lists 只有 **GraphQL API**，无 REST API
- 🔍 GraphQL 字段名必须通过 **introspection** 查询确认
- 🔗 目录名含空格时，Markdown 链接中必须用 **%20** 编码
- 📦 README 内容是 **base64 编码**，需解码
- 🛡️ `updateUserListsForItem` 最小返回字段用 `clientMutationId`

## 📄 许可证

MIT
