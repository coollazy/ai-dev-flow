# Changelog / 變更記錄

Versions follow [Semantic Versioning](https://semver.org/); 0.x versions may include breaking changes. New versions go at the bottom. Each entry notes whether callers need to change anything.

版本號採語意化版本（Semver），0.x 的版本之間可能有不相容的改動。新版本加在最下面，每條記錄寫明呼叫端要不要跟著改。

## v0.1.0 — 2026-10-30

First public version / 第一個公開版本

- Reusable `dev.yml` (start check, dev Claude, notification when no commit is pushed) and `review.yml` (fixed check, review Claude with incremental re-review, optional test stage, notifications, waking the dev Claude), caller templates, issue templates, rules template and install script
- 可重用的 `dev.yml`（開工檢查、開發 Claude、沒推新 commit 時通知）與 `review.yml`（固定檢查、審查 Claude 與只看這輪改動的複審、選用的測試、通知、叫醒開發），加上呼叫檔範本、issue 範本、規則範本與安裝腳本
- `@claude` comments only count from people with write access; PRs from forks are not reviewed
- `@claude` 留言只認有寫入權限的人；從 fork 開的 PR 不審查
- Concurrency is set on jobs inside `dev.yml`, so unrelated label events can't cancel a pending start (caller files no longer set `concurrency` for dev)
- 排隊設在 `dev.yml` 的 job 上，跟開工無關的標籤事件不會擠掉排隊中的開工（開發的呼叫檔不再設 `concurrency`）
- Default provider is `subscription` only; other Anthropic-compatible services are configured per project (docs/providers.md)
- 預設只有 `subscription`；其他相容 Anthropic API 的服務由各專案設定（docs/providers.md）
- `scripts/install.sh` pins the latest release by commit SHA with a version comment (`@<commit> # v0.1.0`)
- `scripts/install.sh` 用 commit 編號鎖定最新的版本，後面加版本號註解（`@<commit> # v0.1.0`）

## v0.1.1 — 2026-10-30

Security hardening; callers only need to bump the pinned commit. / 安全性加強；呼叫端只要換鎖定的 commit。

- Every action used by the shared workflows (`actions/checkout`, `anthropics/claude-code-action`, `actions/upload-artifact`) is pinned by commit SHA, so pinning ai-dev-flow pins everything
- 共用流程用到的 action（`actions/checkout`、`anthropics/claude-code-action`、`actions/upload-artifact`）都改用 commit 編號鎖定，鎖定 ai-dev-flow 的版本就連 action 一起鎖住
- The dev Claude can no longer run `gh api` or arbitrary `gh pr`／`gh issue` subcommands (e.g. merge, close); only view / create / edit / comment / diff / list / checks. Inline review comments are fetched by the workflow and included in its instructions instead
- 開發 Claude 不再放行 `gh api` 與任意的 `gh pr`／`gh issue` 子指令（例如合併、關閉），只放行查看、建立、編輯、留言、diff、列表、checks；逐行意見改由 workflow 先取出、放進給它的指示
- Verified for real: the *changes requested* → fix → re-review loop, `@claude` comments on a PR, and the no-new-commit notification (README status updated)
- 實際驗證過：審查「需修改」→ 修改 → 複審的循環、在 PR 留言 `@claude`、沒推新 commit 時的通知（README 的狀態已更新）

## v0.2.0 — 2026-10-31

The review can run on a self-hosted runner. No change needed for callers that stay on the cloud. / 審查可以跑在自己的電腦（self-hosted runner）；繼續用雲端的呼叫端不用改設定。

- New `review_runs_on` input in `review.yml` (default `"ubuntu-latest"`): where the review and notification jobs run
- `review.yml` 新增 `review_runs_on` 設定（預設 `"ubuntu-latest"`）：審查與通知跑在哪裡
- The bubblewrap step runs only on Linux, skips installing when `bwrap` and `socat` are already present, and only touches the AppArmor setting when it's actually restricted, so self-hosted runners without `sudo` work
- 安裝 bubblewrap 那步只在 Linux 跑，已經裝好就不再安裝，AppArmor 只在真的有限制時才調整：沒有 `sudo` 的 self-hosted runner 也能跑
- Docs: "Self-hosted runners" section in setup (private repos only, dedicated OS account, required tools)
- 文件：安裝與設定新增「用自己的電腦跑」（只用在私人 repo、專用系統帳號、要裝的工具）
