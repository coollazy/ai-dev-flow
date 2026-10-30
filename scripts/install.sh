#!/usr/bin/env bash
# 把 AI 協作流程裝進一個專案：複製呼叫端的 workflow 與 issue 範本、鎖定共用流程的版本、建好標籤。
# 用法：scripts/install.sh <專案目錄> [--repo <owner/repo>] [--ref <commit>] [--force] [--no-labels]
#   --repo       呼叫端要引用的共用流程 repo，預設是這個 repo 的 origin（fork 的話就是你的 fork）
#   --ref        呼叫端鎖定的共用流程版本，預設是這個 repo 目前的 HEAD（要先 push 到 GitHub）
#   --force      專案裡已經有同名檔案時覆蓋（預設不覆蓋，只列出來）
#   --no-labels  不建標籤
# 只複製檔案、建標籤，不 commit、不 push；secrets 要使用者自己存（見 README.md「安裝到一個專案」）
set -euo pipefail

here=$(cd "$(dirname "$0")/.." && pwd)
target="" repo_src="" ref="" force=false labels=true
while [ $# -gt 0 ]; do
  case "$1" in
    --repo) repo_src=$2; shift 2 ;;
    --ref) ref=$2; shift 2 ;;
    --force) force=true; shift ;;
    --no-labels) labels=false; shift ;;
    -*) echo "不認得的參數：$1" >&2; exit 2 ;;
    *) target=$1; shift ;;
  esac
done
[ -n "$target" ] || { sed -n 2,8p "$0" >&2; exit 2; }
[ -d "$target/.git" ] || { echo "$target 不是 git repo" >&2; exit 1; }

if [ -z "$repo_src" ]; then
  url=$(git -C "$here" remote get-url origin 2>/dev/null) || { echo "這個 repo 沒有 origin，用 --repo 指定共用流程的 repo" >&2; exit 1; }
  # https://github.com/owner/repo(.git) 或 git@github.com:owner/repo(.git)
  repo_src=$(sed -E 's#^(https://github\.com/|git@github\.com:)##; s#\.git$##' <<<"$url")
fi
[[ "$repo_src" =~ ^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$ ]] || { echo "共用流程的 repo 格式不對：$repo_src（要是 owner/repo）" >&2; exit 1; }

if [ -z "$ref" ]; then
  ref=$(git -C "$here" rev-parse HEAD)
  # 呼叫端要拿得到這個 commit：確認已經 push
  if ! git -C "$here" branch -r --contains "$ref" 2>/dev/null | grep -q .; then
    echo "共用流程目前的 commit ${ref:0:7} 還沒 push 到 GitHub，先 push 再裝（或用 --ref 指定已 push 的 commit）" >&2
    exit 1
  fi
fi

copy() {
  src=$1 dst=$target/$2
  if [ -e "$dst" ] && [ "$force" != true ]; then
    echo "略過（已存在，加 --force 覆蓋）：$2"; return
  fi
  mkdir -p "$(dirname "$dst")"
  sed -e "s/__AI_DEV_FLOW_REF__/$ref/g" -e "s#__AI_DEV_FLOW_REPO__#$repo_src#g" "$src" > "$dst"
  echo "寫入：$2"
}
copy "$here/templates/workflows/ai-dev.yml" .github/workflows/ai-dev.yml
copy "$here/templates/workflows/ai-review.yml" .github/workflows/ai-review.yml
for f in ai-bug.md ai-feature.md idea.md; do
  copy "$here/templates/ISSUE_TEMPLATE/$f" ".github/ISSUE_TEMPLATE/$f"
done
echo "共用流程：$repo_src@$ref"
echo "規則段落範本：$here/templates/AGENTS-ai-flow.md（依專案改寫後貼進 AGENTS.md）"

if [ "$labels" = true ]; then
  repo=$(cd "$target" && gh repo view --json nameWithOwner -q .nameWithOwner)
  echo "在 $repo 建標籤（已存在的會更新顏色與說明；其他 AI 服務的 ai:<名稱> 標籤見 docs/providers.md）："
  while IFS='|' read -r name color desc; do
    gh label create "$name" -R "$repo" --color "$color" --description "$desc" --force > /dev/null && echo "  $name"
  done <<'LABELS'
bug|d73a4a|修錯誤：已規劃好、驗收條件寫好了（加上本身不會開工）
feature|a2eeef|新功能：已規劃好、驗收條件寫好了（加上本身不會開工）
ai:subscription|5319e7|開工：用 Claude 訂閱
model:claude-opus-5-5|c5def5|指定模型（選用）
model:claude-sonnet-5-5|c5def5|指定模型（選用）
blocked|b60205|AI 做不出來，等使用者處理
round-1|fbca04|審查／測試後自動修改第 1 輪（workflow 管理）
round-2|fbca04|審查／測試後自動修改第 2 輪（workflow 管理）
round-3|fbca04|審查／測試後自動修改第 3 輪（workflow 管理）
LABELS
fi
