# 安全性

[English](security.md) | 繁體中文

這個流程讓 AI 在你的 repo 裡改程式、推 commit、留言。這份說明誰能觸發、AI 拿得到什麼，以及使用前要知道的風險。

## 誰能觸發

| 觸發方式 | 誰能做 |
|---|---|
| 加 `ai:*`、`bug`／`feature` 標籤開工 | 對 repo 有寫入權限的人（GitHub 只讓他們加標籤） |
| 留言 `@claude` | 只認 `OWNER`、`MEMBER`、`COLLABORATOR` 的留言；其他人留言不會叫醒 Claude，也不會收到回覆 |
| PR 審查 | 只審同一個 repo 的分支開的 PR；**從 fork 開的 PR 一律不審查**，不會花你的額度 |
| 審查叫醒修改 | 流程自己（`github-actions[bot]`） |

PR 還要有 `ai:*` 標籤（或它要關閉的 issue 有）才會審查。

## AI 拿得到什麼

- **開發 Claude**：用 Claude GitHub App 的身分推 commit、開 PR、留言；可以讀寫 repo 的程式。`gh` 只放行查看、建立、編輯 issue 與 PR、留言，不能用 `gh api`，也不能合併或關閉。照規則只推自己開的分支；但 `git` 本身沒有限制，請替 base 分支設定**分支保護**（branch protection／rulesets），不讓任何人直接推上去
- **審查 Claude**：只能讀程式碼、看 `git diff`／`git log`、讀 issue 與 PR、留逐行意見。總評由流程貼，不是 AI 自己貼
- **測試 Claude**：只能用專案給的測試工具
- **金鑰**：Claude 執行的指令（Bash）讀不到 AI 的 key 和 GitHub 換通行證用的 token（`CLAUDE_CODE_SUBPROCESS_ENV_SCRUB`，Linux 上用 bubblewrap 隔離）。金鑰存在各專案的 secrets，這個 repo 不放任何金鑰
- **log**：開發 Claude 的完整輸出只在私人 repo 寫進 log，公開 repo 自動關掉

## 固定的保護

- **審查用 base 分支的流程與規則**：`pull_request_target` 一律跑 base 分支的 workflow，規則讀 base 分支的 `AGENTS.md`，PR 改不到。PR 的程式放在 `pr-head/`，審查只讀不執行
- **固定檢查**：PR 改到規則檔（`AGENTS.md`、`CLAUDE.md`、`.claude/`）、`.github/`、Dockerfile、compose 檔，或你用 `blocked_extra` 指定的檔案時，不審查、停下等你人工審查
- **可疑判定**：審查發現跟 issue 無關、可能危害主機或資料的程式（讀取或外傳密鑰、連到 issue 沒提到的網址、刪 repo 以外的檔案、改套件安裝腳本）時，停下不再自動修改
- **最多 3 輪**自動修改，超過就停下通知你
- **PR 關閉或合併後**不再修改、不再推送

## 使用前要知道的風險

- **issue 與留言的內容會交給 AI**：AI 可能被寫在內容裡的指示誤導（prompt injection）。別人開的 issue，開工前先看過內文。開發 Claude 被告知只照審查結果與有寫入權限的人的留言修改，但這是提示，不是硬性限制
- **測試會執行 PR 的程式**：接上測試時，測試環境不要放正式的機密或資料
- **AI 改的程式一定要看過再合併**：審查和測試都是 AI 做的，不保證沒有錯誤或漏洞
- **公開 repo 的 run log 誰都看得到**：不要在 `project_instructions`、`extra_env` 這類設定裡放機密
- **鎖定版本**：呼叫檔用 commit 編號引用共用流程，共用流程用到的 action（`actions/checkout`、`claude-code-action`…）也都用 commit 編號鎖定，鎖一個 commit 就全部鎖住。要用別人的共用流程時，先看過內容再鎖定那個 commit，升級前也要看改動（或 fork 一份自己維護）

## 回報安全問題

發現安全問題請不要開公開的 issue，改用 GitHub 的 [Private vulnerability reporting](https://github.com/coollazy/ai-dev-flow/security/advisories/new)（repo 的 Security 分頁）。
