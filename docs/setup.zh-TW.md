# 安裝與設定

[English](setup.md) | 繁體中文

## 事前準備

| 需要 | 用途 |
|---|---|
| GitHub repo（你有管理權限） | 要裝流程的專案 |
| [GitHub CLI](https://cli.github.com/)（`gh`），已登入 | 安裝腳本建標籤、存 secrets |
| Claude 訂閱（Pro／Max）與 [Claude Code](https://docs.anthropic.com/en/docs/claude-code) | 用 `claude setup-token` 產生 GitHub Actions 用的憑證。只用 API key 的話見[接其他 AI 服務](providers.zh-TW.md) |
| [Claude GitHub App](https://github.com/apps/claude) | 開發 Claude 用它的身分推 commit、開 PR（commit 作者是 `claude[bot]`），推上去的 commit 才會觸發審查 |
| Telegram bot（選用） | 收通知。沒設的話流程照跑，只是不發通知 |

## 安裝到一個專案

以下 `<REPO>` 換成你的專案（例如 `you/my-app`），`<專案目錄>` 換成本機的專案資料夾。

### 1. 取得這個 repo

```bash
git clone https://github.com/coollazy/ai-dev-flow.git
```

想自己維護一份的話，先 fork 再 clone 你的 fork，安裝腳本會自動改成引用你的 fork。fork 或複製成**私人** repo 時，要開放給自己的其他 repo 呼叫：

```bash
gh api -X PUT repos/<你的帳號>/ai-dev-flow/actions/permissions/access -f access_level=user
```

（等同 Settings → Actions → General → Access 選「Accessible from repositories owned by the user」。私人的共用流程只有同一個帳號或組織的 repo 能呼叫。）

### 2. 授權 Claude GitHub App

到 <https://github.com/apps/claude> 安裝，Repository access 加入 `<REPO>`。

### 3. 存 Claude 的憑證

在另一個終端機視窗執行 `claude setup-token`，複製印出的 token，然後（macOS）：

```bash
pbpaste | tr -d ' \n' | gh secret set CLAUDE_CODE_OAUTH_TOKEN -R <REPO>
```

不要把 token 貼進對話、issue 或程式碼裡。

### 4. Telegram 通知（選用）

```bash
gh secret set TELEGRAM_BOT_TOKEN -R <REPO>
gh secret set TELEGRAM_CHAT_ID -R <REPO>
```

同一個 bot 可以給好幾個專案用；通知裡會寫是哪個 repo。

### 5. 裝呼叫檔、issue 範本與標籤

```bash
cd ai-dev-flow
scripts/install.sh <專案目錄>
```

會寫入：
- `.github/workflows/ai-dev.yml`、`ai-review.yml`：呼叫共用流程的兩個檔案，鎖定這個 repo 目前的 commit
- `.github/ISSUE_TEMPLATE/ai-feature.md`、`ai-bug.md`、`idea.md`：issue 範本

並在 `<REPO>` 建好標籤：`bug`、`feature`、`ai:subscription`、`model:claude-opus-5-5`、`model:claude-sonnet-5-5`、`blocked`、`round-1`～`round-3`。

選項：`--force` 覆蓋已經有的檔案（預設略過）、`--no-labels` 不建標籤、`--ref <commit>` 指定版本、`--repo <owner/repo>` 指定引用哪個 repo。腳本不會 commit、不會 push。

### 6. 依專案調整呼叫檔

打開兩個呼叫檔的 `with:` 區塊，至少確認：
- `base_branch`：PR 開到哪個分支（預設 `develop`；只有 `main` 就改成 `main`）。`ai-review.yml` 的 `records_base` 也一起改
- `setup_command`：Claude 啟動前要先裝的東西，例如 `npm ci`
- `allowed_tools`：開發 Claude 可以執行的建置、測試指令，例如 `Bash(npm run build),Bash(npm test)`
- `project_instructions`：怎麼建置、驗證、寫變更記錄
- `blocked_extra`：另外要擋下等你人工審查的檔案，例如套件清單 `^package\.json$|^package-lock\.json$`

全部設定見下面「設定值」。

### 7. 規則

把 [`templates/AGENTS-ai-flow.md`](../templates/AGENTS-ai-flow.md) 依專案改寫（`<base 分支>`、變更記錄的寫法、用不到的測試段落）後，貼進專案的 `AGENTS.md`（或 `CLAUDE.md`）。開發、審查、測試 Claude 都會讀這份規則；審查一律讀 base 分支的版本，PR 改不到。

### 8. 推上去、試跑

commit 並推到 base 分支，照[怎麼開 issue](writing-issues.zh-TW.md) 開一張很小的 issue（例如改一段文字），加 `feature` 和 `ai:subscription`，確認開發、審查、通知都走完一圈。

## 設定值

全部選項與預設值寫在 [`dev.yml`](../.github/workflows/dev.yml) 與 [`review.yml`](../.github/workflows/review.yml) 開頭的 `inputs`。

### `ai-dev.yml`（開發）

| 設定 | 預設 | 說明 |
|---|---|---|
| `base_branch` | `develop` | PR 開到哪個分支 |
| `branch_prefix` | `ai/issue-` | 開發分支的名稱開頭 |
| `setup_command` | 空 | Claude 啟動前執行（例如 `npm ci`）。Claude 執行的指令有隔離，自己裝套件常會失敗，要在這裡先裝 |
| `allowed_tools` | 空 | 另外放行給開發 Claude 的指令，逗號分隔。git、`gh issue`、`gh pr`、`gh api`、讀寫檔案一律放行 |
| `project_instructions` | 空 | 專案的建置、驗證方式與變更記錄寫法，加在給開發 Claude 的指示後面 |
| `extra_env` | 空 | 額外的環境變數，一行一個 `KEY=VALUE`（不要放機密） |
| `runs_on` | `"ubuntu-latest"` | 跑在哪裡（JSON），self-hosted runner 寫 `["self-hosted","my-runner"]` |
| `type_labels` | `bug feature` | 代表「已經規劃好」的類型標籤 |
| `providers` | `subscription` | 可用的 AI 服務，見[接其他 AI 服務](providers.zh-TW.md) |
| `models` | `claude-opus-5-5 claude-sonnet-5-5` | `model:<名稱>` 標籤可以指定的模型 |
| `max_turns` / `timeout_minutes` / `claude_timeout_minutes` | 80 / 45 / 35 | 步數與時間上限 |

### `ai-review.yml`（審查與測試）

| 設定 | 預設 | 說明 |
|---|---|---|
| `dev_workflow` | `ai-dev.yml` | 要修改時叫醒的開發流程檔名 |
| `providers` | `subscription` | 跟 `ai-dev.yml` 設一樣 |
| `blocked_pattern` | 規則檔、`.github/`、Dockerfile、compose 檔 | PR 改到就不審查、停下等你人工審查（正規表示式） |
| `blocked_extra` | 空 | 另外要擋的檔案，接在 `blocked_pattern` 後面 |
| `records_files` | 空 | PR 不能改的紀錄檔，例如 `CHANGELOG.md TODO.md`；改到時請開發 Claude 改回來 |
| `records_base` / `records_exempt_prefix` | `develop` / `release/` | 紀錄檔檢查只看開到哪個分支的 PR、哪種分支例外 |
| `review_instructions` | 空 | 專案自己的審查重點 |
| `max_rounds` | 3 | 自動修改最多幾輪（要有對應的 `round-N` 標籤） |
| `review_max_turns` / `review_timeout_minutes` | 30 / 20 | 審查的步數與時間上限 |
| `test_setup` | 空 | **設了才測試**，見下面「接上測試」 |

路徑過濾（只改文件的 PR 不跑審查）寫在 `ai-review.yml` 的 `on.pull_request_target.paths`，可以依專案調整。

## 接上測試（選用）

沒設 `test_setup` 時，審查通過就算通過。每個專案的測試環境差很多，所以這裡只定介面，環境由專案自己做：

| 設定 | 說明 |
|---|---|
| `test_setup` | 建立測試環境的腳本（base 分支裡的路徑，用 bash 執行，PR 改不到）。執行時 PR 的程式在 `pr-head/`。要在 `$GITHUB_OUTPUT` 寫 `started=true` 或 `false`；可以另外用多行格式寫 `desc`，交給測試 Claude 當環境說明 |
| `test_prompt_file` | Markdown 檔，寫測試工具有哪些、怎麼用，內容會放進給測試 Claude 的指示 |
| `test_allowed_tools` | 放行給測試 Claude 的指令，例如 `Bash(.github/ai-test/http.sh:*)` |
| `smoke_script` | 固定的冒煙檢查（不用 AI），在測試 Claude 之前跑，exit 0 算通過 |
| `ci_workflow` / `ci_step` | 「單元測試通過」這類驗收條件改看 CI 的結果（測試 Claude 跑不了套件管理工具） |
| `test_artifacts` | 測完上傳成 artifact 的檔案（預設 `ai-test-shots/*.png`） |
| `test_cleanup` | 測完執行的清理腳本（主要給 self-hosted runner） |
| `test_runs_on` / `test_max_turns` / `test_timeout_minutes` | 跑在哪裡、步數與時間上限 |

測試 Claude 執行的指令有隔離，連不到 docker。要看容器 log、操作瀏覽器時，專案要在隔離外起一個小服務轉接，再給測試 Claude 呼叫那個服務的腳本。測試會執行 PR 的程式，測試環境不要放正式的機密或資料。

## 升級共用流程

1. 看這個 repo 的 [CHANGELOG](../CHANGELOG.md) 與兩個版本之間的改動
2. 挑一個專案，把兩個呼叫檔的 `@<commit>` 換成新的 commit（兩個要一樣），開一張小 issue 確認
3. 沒問題再換其他專案

也可以重跑 `scripts/install.sh <專案目錄> --force`，但它會蓋掉你在呼叫檔裡調整過的設定，之後要再改回來。

## 注意

- GitHub Actions 每月免費分鐘數與 Claude 額度都是整個帳號共用；私人 repo 用量大時要留意
- 在雲端的 macOS 電腦上跑要多花好幾倍分鐘數；Swift／iOS 專案要建置或測試的話，用 `runs_on` 指到自己的 Mac runner
- 開發 Claude 的完整輸出只在私人 repo 寫進 log（公開 repo 誰都看得到 log，自動關掉）
