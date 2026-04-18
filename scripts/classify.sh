#!/usr/bin/env bash
# classify.sh - 基于 language/topics/description 自动分类仓库
# 用法: bash classify.sh --repo '{"full_name":"...","description":"...","language":"...","topics":[...]}'
#
# 输出: JSON 对象 {"category": "分类名", "confidence": "high|low"}

set -euo pipefail

REPO_JSON=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --repo) REPO_JSON="$2"; shift 2 ;;
        *) shift ;;
    esac
done

if [[ -z "$REPO_JSON" ]]; then
    echo "用法: classify.sh --repo '<json>'" >&2
    exit 1
fi

LANGUAGE=$(echo "$REPO_JSON" | jq -r '.language // ""')
DESCRIPTION=$(echo "$REPO_JSON" | jq -r '.description // ""' | tr '[:upper:]' '[:lower:]')
TOPICS=$(echo "$REPO_JSON" | jq -r '.topics // [] | join(" ")' | tr '[:upper:]' '[:lower:]')
FULL_NAME=$(echo "$REPO_JSON" | jq -r '.full_name // ""' | tr '[:upper:]' '[:lower:]')

COMBINED="${LANGUAGE} ${DESCRIPTION} ${TOPICS} ${FULL_NAME}"

classify() {
    local signal=0
    local category=""

    if echo "$COMBINED" | grep -qiE 'skill|opencode|claude.code|agent.skill'; then
        category="Skills"; ((signal++))
    fi
    if echo "$COMBINED" | grep -qiE 'agent|mcp|claude|copilot|cursor|ai.agent|llm.agent'; then
        if [[ "$category" == "Skills" ]]; then
            category="AI Agent 与 Claude 工具"; ((signal++))
        elif [[ -z "$category" ]]; then
            category="AI Agent 与 Claude 工具"; ((signal++))
        fi
    fi
    if echo "$COMBINED" | grep -qiE 'llm|gpt|openai|gemini|claude|transformer|model|huggingface|diffusion|stable.diffusion|midjourney|ollama|lora|fine.tun'; then
        if [[ -z "$category" ]]; then
            category="AI 与 LLM 应用"; ((signal++))
        fi
    fi
    if echo "$COMBINED" | grep -qiE 'video|ffmpeg|youtube|stream|subtitle|字幕|视频|bilibili|movie|record|screen|obs'; then
        if [[ -z "$category" ]]; then
            category="视频与媒体"; ((signal++))
        fi
    fi
    if echo "$COMBINED" | grep -qiE 'stock|trading|finance|quant|fund|invest|backtest|kline|期货|股票|金融|东方财富|同花顺'; then
        if [[ -z "$category" ]]; then
            category="金融与量化"; ((signal++))
        fi
    fi
    if echo "$COMBINED" | grep -qiE 'music|audio|midi|tts|asr|whisper|语音|音乐|声|singer|voice|song|钢琴'; then
        if [[ -z "$category" ]]; then
            category="音乐与音频"; ((signal++))
        fi
    fi
    if echo "$COMBINED" | grep -qiE 'wechat|weixin|wx|telegram|bot|qq|discord|slack|社交|公众号|微信|群|chat'; then
        if [[ -z "$category" ]]; then
            category="微信与社交"; ((signal++))
        fi
    fi
    if echo "$COMBINED" | grep -qiE 'novel|writing|fiction|story|创作|小说|写作|文学|creative'; then
        if [[ -z "$category" ]]; then
            category="小说与写作"; ((signal++))
        fi
    fi
    if echo "$COMBINED" | grep -qiE 'siyuan|obsidian|note|markdown|笔记|memos|logseq|notion'; then
        if [[ -z "$category" ]]; then
            category="思源笔记"; ((signal++))
        fi
    fi
    if echo "$COMBINED" | grep -qiE 'browser|chrome|extension|firefox|proxy|network|surf|爬|下载|download'; then
        if [[ -z "$category" ]]; then
            category="浏览器与网络"; ((signal++))
        fi
    fi
    if echo "$COMBINED" | grep -qiE 'docker|k8s|kubernetes|deploy|devops|server|nginx|运维|部署|container|podman'; then
        if [[ -z "$category" ]]; then
            category="Docker 与运维"; ((signal++))
        fi
    fi
    if echo "$COMBINED" | grep -qiE 'cli|tool|dev|git|debug|test|lint|ide|vim|neovim|editor|terminal|shell|bash'; then
        if [[ -z "$category" ]]; then
            category="开发者工具"; ((signal++))
        fi
    fi
    if echo "$COMBINED" | grep -qiE 'data|csv|json|excel|pdf|doc|document|表格|解析|parse|convert|格式'; then
        if [[ -z "$category" ]]; then
            category="数据与文档"; ((signal++))
        fi
    fi
    if echo "$COMBINED" | grep -qiE 'tutorial|course|learn|awesome|book|roadmap|指南|教程|学习|资源|interview'; then
        if [[ -z "$category" ]]; then
            category="学习资源"; ((signal++))
        fi
    fi
    if echo "$COMBINED" | grep -qiE 'crawl|spider|scraper|automation|自动化|爬虫|抓取|scrape|puppeteer|selenium'; then
        if [[ -z "$category" ]]; then
            category="自动化与爬虫"; ((signal++))
        fi
    fi
    if echo "$COMBINED" | grep -qiE 'news|rss|feed|media|新闻|资讯|热搜|headline'; then
        if [[ -z "$category" ]]; then
            category="新闻与媒体"; ((signal++))
        fi
    fi
    if echo "$COMBINED" | grep -qiE 'security|privacy|encrypt|vpn|password|安全|隐私|加密|渗透|pentest'; then
        if [[ -z "$category" ]]; then
            category="安全与隐私"; ((signal++))
        fi
    fi

    if [[ -z "$category" ]]; then
        category="实用工具"
        signal=1
    fi

    if [[ $signal -ge 2 ]]; then
        echo "{\"category\": \"${category}\", \"confidence\": \"high\"}"
    else
        echo "{\"category\": \"${category}\", \"confidence\": \"low\"}"
    fi
}

classify
