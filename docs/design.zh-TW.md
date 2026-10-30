# 設計與取捨

[English](design.md) | 繁體中文

## 架構

- 這個 repo 放兩個可重用的 workflow（`workflow_call`）：[`dev.yml`](../.github/workflows/dev.yml)（開發）、[`review.yml`](../.github/workflows/review.yml)（審查與測試）
- 各專案放兩個短的呼叫檔（[`templates/workflows/`](../templates/workflows/)）：觸發條件、權限、路徑過濾寫在呼叫檔，專案的差異用 `with:` 帶進共用流程，`secrets: inherit` 交出專案自己的金鑰
- 金鑰存在各專案；這個 repo 不放金鑰，也沒有會自動執行的流程
- 呼叫檔用 commit 編號鎖定共用流程的版本：這裡改壞了不會讓所有專案一起壞，新版先在一個專案試

## 腳本為什麼直接寫在 workflow 裡

判斷 AI 服務、驗收條件、複審版本、總評格式這些腳本，全部寫在兩個 workflow 檔裡，沒有另外放 `.sh`：

- 被呼叫的 workflow 跑在呼叫端 repo 的環境，`actions/checkout` 拿到的是呼叫端的程式，拿不到這個 repo 的其他檔案（私人的副本還要另外給有權限的 token）
- 包成 composite action 雖然拿得到，但 `uses:` 不能用變數，action 的版本只能寫死，呼叫端鎖定 workflow 的 commit 時鎖不住 action
- 寫在 workflow 裡，鎖定一個 commit 就連腳本一起鎖住

代價：「看標籤決定 AI 服務」那段在 `dev.yml`、`review.yml` 各有一份，改的時候要一起改（兩個檔案的註解都有寫）。

## 開工檢查不用 AI

標籤與驗收條件的檢查是固定的 shell 腳本：條件不齊時不叫醒 Claude、不花額度，拿掉 `ai:*` 標籤並通知，issue 回到「還沒開工」的狀態。

## 排隊

GitHub 同一組排隊（concurrency group）只能有一個在排隊，新來的會把排隊中的擠掉。排隊設在 job 上、不設在整個 workflow，跟開工無關的事件（例如加 `model:*` 標籤）在 job 的條件就被略過，不會占排隊位置、把真正的開工擠掉。開工檢查和開發分成兩組，開發跑很久時不會擋住後面的檢查。同一張 issue 連續加好幾個標籤時，靠 issue 上的開工紀錄（`<!-- ai-dev-start -->`）避免重複開工。

## 審查

- 用 `pull_request_target`：一律跑 base 分支的 workflow 與規則，PR 改不到；PR 的程式放在 `pr-head/`，只讀不執行
- 審查 Claude 沒有留言權限：結論用結構化輸出（`--json-schema`）交給流程，由流程貼上「## 審查總評（版本 <sha7>）」。這樣 PR 上一定看得到這次版本的總評，run 的紅綠燈也跟總評一致
- 複審只看這輪的改動：從上次的總評標題找出上次審查的版本，而且那個版本要在這次 head 的歷史裡，找不到就當第一次審查。避免每輪都從頭審、每次都挑出新的小毛病而收斂不了
- 嚴重程度分【高】【中】【低】，【低】不擋 PR，也不會因此多跑一輪

## 測試是選用的

每個專案的測試環境差太多（docker、資料庫、瀏覽器、模擬器…），共用流程只定介面：專案的啟動腳本建好環境並回報有沒有起來，測試 Claude 用專案提供的工具操作。沒設定時，審查通過就算通過。

## 固定不變的格式

這些格式有程式在讀，改的話要一起改：

- 「## 審查總評（版本 <sha7>）」「## 測試報告（版本 <sha7>）」：複審靠前者找上次審查的版本
- 開工紀錄的 `<!-- ai-dev-start -->` 標記
- `round-N`、`ai:*`、`model:*` 標籤
