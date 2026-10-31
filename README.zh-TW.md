# ai-dev-flow

[English](README.md) | 繁體中文

開 issue → AI 改程式開 PR → AI 審查 →（選用）AI 測試 → 通知你。用 GitHub Actions 和 [Claude Code](https://github.com/anthropics/claude-code-action) 做的 AI 開發流程，各專案共用。

從一個實際天天在用的專案抽出來：流程本身放在這個 repo，各專案只放兩個很短的呼叫檔，差異用設定值帶進來。

## 流程長什麼樣子

1. 你寫一張 issue，寫清楚要做什麼與**驗收條件**，加上 `feature`（或 `bug`）標籤
2. 加上 `ai:subscription` 標籤 → 開發 Claude 照 issue 改程式、開 PR
3. PR 開好 → 審查 Claude 只讀程式碼，給出「通過／需修改／可疑」，總評貼在 PR 上
4. （選用）專案有設定測試時，審查通過才測試：測試 Claude 在專案自己的測試環境實際操作
5. 需修改或測試失敗 → 自動叫開發 Claude 修改，最多 3 輪；都通過或需要你決定時發 Telegram 通知
6. 你看過審查總評與測試報告後，自己決定要不要合併

中途想插手：在 issue 或 PR 留言 `@claude` 加上指示。

## 文件

| 文件 | 內容 |
|---|---|
| [安裝與設定](docs/setup.zh-TW.md) | 事前準備、安裝到專案、全部設定值、接上測試、升級 |
| [日常使用](docs/usage.zh-TW.md) | 開工、看結果、合併、中途插手、通知的意思、常見問題 |
| [怎麼開 issue](docs/writing-issues.zh-TW.md) | issue 的兩種、驗收條件怎麼寫、範例 |
| [接其他 AI 服務](docs/providers.zh-TW.md) | 除了 Claude 訂閱，接相容 Anthropic API 的其他服務 |
| [安全性](docs/security.zh-TW.md) | 誰能觸發、AI 看得到什麼、使用前要知道的風險 |
| [設計與取捨](docs/design.zh-TW.md) | 為什麼這樣設計 |

## 快速開始

詳細步驟見[安裝與設定](docs/setup.zh-TW.md)。

```bash
git clone https://github.com/coollazy/ai-dev-flow.git
cd ai-dev-flow
scripts/install.sh ~/path/to/your-project   # 寫入呼叫檔與 issue 範本、建標籤（不會 commit）
```

接著：在專案 repo 安裝 Claude GitHub App、存 `CLAUDE_CODE_OAUTH_TOKEN`、調整兩個呼叫檔的設定、把規則段落貼進專案的 `AGENTS.md`、commit 推上去，開一張小 issue 試跑。

## 使用前要知道

- **流程的語言是繁體中文**：給 AI 的指示、PR 上的總評與報告、Telegram 通知、issue 範本都是中文；驗收條件的標題要一字不差寫成 `## 驗收條件`
- **會花你的額度**：每次開發、審查、測試都會用到 Claude 額度（訂閱或 API），以及 GitHub Actions 的分鐘數（公開 repo 不算分鐘數）
- **AI 會推程式到你的 repo**：開發 Claude 有寫入權限（只推到自己開的分支、開 PR，不會合併）。合併一律由你決定。使用前請看過[安全性](docs/security.zh-TW.md)
- **鎖定版本使用**：呼叫檔用 commit 編號引用這個 repo，這裡更新不會自動影響你的專案；要升級時看過改動再換版本號

## 授權

[MIT](LICENSE)
