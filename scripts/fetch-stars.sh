#!/usr/bin/env bash
# fetch-stars.sh - 获取用户所有 starred 仓库
# 用法: bash fetch-stars.sh [--full] [--output /path/to/output.json] [--processed /path/to/.processed]
#
# 输出: JSON 数组，每个元素包含 full_name, description, language, topics, stargazers_count, html_url

set -euo pipefail

FULL_MODE=false
OUTPUT_FILE=""
PROCESSED_FILE=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --full) FULL_MODE=true; shift ;;
        --output) OUTPUT_FILE="$2"; shift 2 ;;
        --processed) PROCESSED_FILE="$2"; shift 2 ;;
        *) shift ;;
    esac
done

if ! command -v gh &>/dev/null; then
    echo "错误: gh CLI 未安装" >&2
    echo "请访问 https://cli.github.com/ 安装" >&2
    exit 1
fi

if ! gh auth status &>/dev/null; then
    echo "错误: gh CLI 未认证" >&2
    echo "请运行 gh auth login" >&2
    exit 1
fi

echo "正在获取 starred 仓库列表..."

ALL_STARS=$(gh api user/starred --paginate --jq '.[] | {
    full_name: .full_name,
    description: (.description // ""),
    language: (.language // ""),
    topics: (.topics // []),
    stargazers_count: .stargazers_count,
    html_url: .html_url
}')

TOTAL=$(echo "$ALL_STARS" | jq -s 'length')
echo "共获取 ${TOTAL} 个 starred 仓库"

if [[ "$FULL_MODE" == "false" && -n "$PROCESSED_FILE" && -f "$PROCESSED_FILE" ]]; then
    PROCESSED_NAMES=$(jq -r '.[] | .full_name' "$PROCESSED_FILE" 2>/dev/null || echo "")
    if [[ -n "$PROCESSED_NAMES" ]]; then
        FILTERED=$(echo "$ALL_STARS" | jq -s --argjson processed "$(jq -s '.' "$PROCESSED_FILE")" \
            '[.[] | select(.full_name as $name | ($processed | map(.full_name) | index($name)) | not)]')
        ALL_STARS="$FILTERED"
    fi
fi

NEW_COUNT=$(echo "$ALL_STARS" | jq -s 'length')
echo "新增仓库: ${NEW_COUNT} 个"

if [[ -n "$OUTPUT_FILE" ]]; then
    echo "$ALL_STARS" | jq -s '.' > "$OUTPUT_FILE"
    echo "已保存到 ${OUTPUT_FILE}"
else
    echo "$ALL_STARS" | jq -s '.'
fi
