#!/usr/bin/env bash
# update-wiki.sh - 扫描 vault 目录，生成/更新 wiki.md 索引
# 用法: bash update-wiki.sh --vault /path/to/vault [--output wiki.md]
#
# 依赖: jq

set -euo pipefail

VAULT=""
OUTPUT="wiki.md"

while [[ $# -gt 0 ]]; do
    case "$1" in
        --vault) VAULT="$2"; shift 2 ;;
        --output) OUTPUT="$2"; shift 2 ;;
        *) shift ;;
    esac
done

[[ -z "$VAULT" ]] && { echo "用法: update-wiki.sh --vault /path/to/vault"; exit 1; }
[[ ! -d "$VAULT" ]] && { echo "错误: vault 目录不存在: ${VAULT}"; exit 1; }

echo "扫描 ${VAULT} ..."

TOTAL_REPOS=0
CATEGORIES=()

CATEGORIZED=""

for dir in "$VAULT"/*/; do
    [[ ! -d "$dir" ]] && continue
    CAT_NAME=$(basename "$dir")
    COUNT=$(find "$dir" -maxdepth 1 -name "*.md" | wc -l)
    [[ "$COUNT" -eq 0 ]] && continue

    TOTAL_REPOS=$((TOTAL_REPOS + COUNT))
    CATEGORIES+=("$CAT_NAME")

    ENCODED_NAME=$(echo "$CAT_NAME" | sed 's/ /%20/g')

    CATEGORIZED+="### ${CAT_NAME} (${COUNT} 个仓库)${NL}${NL}"
    CATEGORIZED+="| 仓库 | 简介 | 详情 |${NL}"
    CATEGORIZED+="|------|------|------|${NL}"

    for mdfile in "$dir"*.md; do
        [[ ! -f "$mdfile" ]] && continue
        REPO_NAME=$(basename "$mdfile" .md)

        INTRO=""
        CAPTURING=false
        while IFS= read -r line; do
            if [[ "$line" =~ ^##\ 简介 ]]; then
                CAPTURING=true
                continue
            fi
            if $CAPTURING && [[ "$line" =~ ^##\  ]]; then
                break
            fi
            if $CAPTURING && [[ -n "${line// /}" ]]; then
                INTRO+="${line} "
            fi
        done < "$mdfile"

        INTRO=$(echo "$INTRO" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//' | cut -c1-120)

        if [[ -z "$INTRO" ]]; then
            INTRO="(暂无简介)"
        fi

        DETAIL_LINK=$(echo "${CAT_NAME}/${REPO_NAME}.md" | sed 's/ /%20/g')
        CATEGORIZED+="| ${REPO_NAME} | ${INTRO} | [查看](${DETAIL_LINK}) |${NL}"
    done

    CATEGORIZED+="${NL}"
done

CAT_COUNT=${#CATEGORIES[@]}

TOC=""
i=1
for cat in "${CATEGORIES[@]}"; do
    ENCODED=$(echo "$cat" | sed 's/ /%20/g')
    TOC+="${i}. [${cat}](./${ENCODED}/)${NL}"
    i=$((i + 1))
done

WIKI_CONTENT="# GitHub Star 书签 Wiki

> 本目录收录了 GitHub 上 star 的仓库，按分类整理，每个仓库附带详细的中文摘要说明。
>
> 仓库总数：${TOTAL_REPOS} | 分类数：${CAT_COUNT}

---

## 目录

${TOC}
---

## 分类详情

${CATEGORIZED}"

echo "$WIKI_CONTENT" > "$VAULT/$OUTPUT"
echo "已更新 ${VAULT}/${OUTPUT}（${TOTAL_REPOS} 个仓库，${CAT_COUNT} 个分类）"
