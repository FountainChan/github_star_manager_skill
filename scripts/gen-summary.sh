#!/usr/bin/env bash
# gen-summary.sh - 获取仓库 README 并准备摘要生成所需的原始数据
# 用法: bash gen-summary.sh --owner OWNER --repo REPO --output /path/to/output.json
#
# 输出: JSON 对象，包含仓库信息和 README 内容，供 AI 生成中文摘要

set -euo pipefail

OWNER=""
REPO=""
OUTPUT_FILE=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --owner) OWNER="$2"; shift 2 ;;
        --repo) REPO="$2"; shift 2 ;;
        --output) OUTPUT_FILE="$2"; shift 2 ;;
        *) shift ;;
    esac
done

[[ -z "$OWNER" || -z "$REPO" ]] && { echo "用法: gen-summary.sh --owner X --repo Y [--output file]"; exit 1; }

echo "获取 ${OWNER}/${REPO} 的信息..."

REPO_INFO=$(gh api "repos/${OWNER}/${REPO}" --jq '{
    full_name: .full_name,
    description: (.description // ""),
    language: (.language // ""),
    topics: (.topics // []),
    stargazers_count: .stargazers_count,
    html_url: .html_url,
    homepage: (.homepage // ""),
    license: (.license.spdx_id // "")
}')

README_CONTENT=""
README_B64=$(gh api "repos/${OWNER}/${REPO}/readme" --jq '.content' 2>/dev/null || echo "")
if [[ -n "$README_B64" ]]; then
    README_CONTENT=$(echo "$README_B64" | base64 -d 2>/dev/null | head -500 || echo "")
fi

RESULT=$(echo "$REPO_INFO" | jq --arg readme "$README_CONTENT" '. + {readme: $readme}')

if [[ -n "$OUTPUT_FILE" ]]; then
    echo "$RESULT" > "$OUTPUT_FILE"
    echo "已保存到 ${OUTPUT_FILE}"
else
    echo "$RESULT"
fi
