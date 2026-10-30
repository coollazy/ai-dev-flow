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
