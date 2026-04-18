#!/usr/bin/env bash
# manage-lists.sh - GitHub Lists CRUD 操作
# 用法:
#   bash manage-lists.sh list                          # 列出已有 Lists
#   bash manage-lists.sh create "分类名"               # 创建 List
#   bash manage-lists.sh add REPO_NODE_ID LIST_ID      # 添加仓库到 List
#   bash manage-lists.sh get-node OWNER REPO            # 获取仓库 node_id
#   bash manage-lists.sh delete LIST_ID                 # 删除 List

set -euo pipefail

ACTION="${1:-}"
shift || true

list_lists() {
    gh api graphql -f query='
        query { viewer { lists(first: 100) { nodes { id name description } } } }
    ' --jq '.data.viewer.lists.nodes'
}

create_list() {
    local name="$1"
    gh api graphql -f query='
        mutation CreateUserList($name: String!) {
            createUserList(input: {name: $name, isPrivate: false}) {
                list { id name }
            }
        }
    ' -f name="$name" --jq '.data.createUserList.list'
}

get_repo_node_id() {
    local owner="$1"
    local repo="$2"
    gh api graphql -f query='
        query GetRepoId($owner: String!, $repo: String!) {
            repository(owner: $owner, name: $repo) { id }
        }
    ' -f owner="$owner" -f repo="$repo" --jq '.data.repository.id'
}

add_to_list() {
    local item_id="$1"
    local list_id="$2"
    gh api graphql -f query='
        mutation AddToList($itemId: ID!, $listId: ID!) {
            updateUserListsForItem(input: {itemId: $itemId, listIds: [$listId]}) {
                clientMutationId
            }
        }
    ' -f itemId="$item_id" -f listId="$list_id" --jq '.data.updateUserListsForItem.clientMutationId'
}

delete_list() {
    local list_id="$1"
    gh api graphql -f query='
        mutation DeleteList($listId: ID!) {
            deleteUserList(input: {listId: $listId}) {
                clientMutationId
            }
        }
    ' -f listId="$list_id" --jq '.data.deleteUserList.clientMutationId'
}

case "$ACTION" in
    list)
        list_lists
        ;;
    create)
        [[ -z "${1:-}" ]] && { echo "用法: manage-lists.sh create <name>"; exit 1; }
        create_list "$1"
        ;;
    get-node)
        [[ -z "${1:-}" || -z "${2:-}" ]] && { echo "用法: manage-lists.sh get-node <owner> <repo>"; exit 1; }
        get_repo_node_id "$1" "$2"
        ;;
    add)
        [[ -z "${1:-}" || -z "${2:-}" ]] && { echo "用法: manage-lists.sh add <item_id> <list_id>"; exit 1; }
        add_to_list "$1" "$2"
        ;;
    delete)
        [[ -z "${1:-}" ]] && { echo "用法: manage-lists.sh delete <list_id>"; exit 1; }
        delete_list "$1"
        ;;
    *)
        echo "用法: manage-lists.sh {list|create|get-node|add|delete} [args...]"
        exit 1
        ;;
esac
