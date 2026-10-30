# 接其他 AI 服務

[English](providers.md) | 繁體中文

預設只有 `ai:subscription`：用 Claude 訂閱（`CLAUDE_CODE_OAUTH_TOKEN`）。另外也可以接任何**相容 Anthropic Messages API** 的服務，例如直接用 Anthropic API key，或 API 代理服務。每張 issue 用標籤選這次要用哪一家。

## 怎麼接

假設服務叫 `myapi`（只能用小寫英文、數字、`-`）：

1. **取名與前綴**：標籤是 `ai:myapi`；secret 與變數的前綴是名稱轉大寫、`-` 換成 `_`，也就是 `MYAPI`（`my-proxy` 就是 `MY_PROXY`）
2. **存 key 與網址**：

   ```bash
   gh secret set MYAPI_API_KEY -R <REPO>                          # 貼上 key，不要放進程式碼或對話
   gh variable set MYAPI_BASE_URL -R <REPO> -b https://api.example.com
   ```

3. **選用：預設模型**（沒加 `model:` 標籤時用；沒設時用 `default_model`，預設 `claude-opus-5-5`）：

   ```bash
   gh variable set MYAPI_MODEL -R <REPO> -b <模型名稱>
   gh variable set MYAPI_HAIKU_MODEL -R <REPO> -b <小模型名稱>   # Claude Code 背景做小事用
   ```

4. **兩個呼叫檔都加進 `providers`**（`ai-dev.yml` 和 `ai-review.yml` 要一樣）：

   ```yaml
   providers: subscription myapi
   ```

5. **建標籤**：

   ```bash
   gh label create ai:myapi -R <REPO> --color 1d76db --description "開工：用 myapi"
   ```

之後 issue 加 `ai:myapi` 就用這家。開發 Claude 開的 PR 會沿用它要關閉的 issue 的標籤，審查也用同一家。

## 例子：直接用 Anthropic API key

```bash
gh secret set ANTHROPIC_API_KEY -R <REPO>
gh variable set ANTHROPIC_BASE_URL -R <REPO> -b https://api.anthropic.com
```

`providers: subscription anthropic`，標籤 `ai:anthropic`。

## 規則與限制

- **網址沒有預設值**：`<前綴>_BASE_URL` 沒設時不會開工，會留言說缺哪一個，避免 key 送到錯的地方
- **key 沒設時**也不會開工，同樣留言說明
- **同一張 issue 只能有一個 `ai:*` 標籤**，兩個都加會被當成設定錯誤
- **模型標籤**：`model:<名稱>` 只認 `models` 設定裡列出的名稱，要用其他模型就改 `models` 並建對應的標籤；模型名稱要是那家服務認得的
- **key 的保護**：key 只交給 Claude Code 本身。Claude 執行的指令（Bash）看不到它，見[安全性](security.zh-TW.md)
- 服務要支援 Claude Code 會用到的功能（工具呼叫等）；不完全相容的代理服務可能在中途出錯
