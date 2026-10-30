# Daily use

English | [繁體中文](usage.zh-TW.md)

## Labels show where an issue is

| Label | Meaning | Added by |
|---|---|---|
| (no type label) | To be planned: will be done, not thought through yet | — |
| `bug` / `feature` | Planned, acceptance criteria written. **Adding it does not start work** | You |
| `ai:subscription` (or another `ai:<provider>` you configured) | Start work, with this AI provider | You |
| `model:<name>` | Optional, pick a model | You |
| `blocked` | The dev Claude couldn't do it and is waiting for you | Dev Claude |
| `round-1` to `round-3` | Which automatic fix round the PR is in | Workflow |

Only people with write access can add labels, so outsiders can't start the AI.

## Life of an issue

1. **Write the issue** with the "AI 新功能" (feature) or "AI 修錯誤" (bug) template, which adds `feature` / `bug`. See [Writing issues](writing-issues.md)
2. **Start**: add `ai:subscription`, either in Labels before submitting the issue or later
   - Start check (no AI, no cost): there must be a `bug` / `feature` label and a `## 驗收條件` (acceptance criteria) section with content. If anything is missing, work doesn't start: the `ai:*` label is removed and a Telegram message says what's missing. Fix it and add the `ai:*` label again
   - When work starts, a "開工：…" comment appears on the issue
3. **Development**: the dev Claude creates a branch, changes the code and opens a PR to the base branch with `Closes #<number>`. If it can't do the work it explains why on the issue and adds `blocked`
4. **Review**: whenever the PR opens or gets a new commit, the review Claude reads the code and the summary is posted as "## 審查總評（版本 xxxxxxx）"
   - **Pass (通過)** → testing, if configured; otherwise done
   - **Changes (需修改)** → the dev Claude is woken to fix them, then the review runs again (later rounds review only that round's changes and check that earlier issues were fixed)
   - **Suspicious (可疑)** → stops and waits for you. Used when the code contains things unrelated to the issue that could harm the host or data
5. **Testing (optional)**: the result is posted as "## 測試報告（版本 xxxxxxx）": pass / fail (dev Claude is woken to fix) / incomplete (waits for you)
6. **Notification**: Telegram message when everything passes, rounds run out, the review flags something suspicious, the PR is blocked, or testing is incomplete
7. **Merge**: your decision (see "Before merging")

## Notifications

| Message | Meaning | What to do |
|---|---|---|
| ✅ Review (and tests) passed | This version can be merged | Read the summary and report, merge if happy |
| 🛑 Out of rounds | 3 fix rounds and still not passing | Read the PR: give instructions (`@claude`), remove the `round-N` label to reset, or close it |
| 🚨 Suspicious | The code contains something unrelated and possibly dangerous | Inspect the diff carefully; don't just merge |
| ✋ Waiting for you | The PR touches rules, `.github/`, Dockerfile or files you blocked; no review ran | Review it yourself and decide |
| ⚠️ Incomplete | Testing didn't finish, or the workflow itself failed or timed out | Check the run log, rerun if needed |
| ⛔ Issue can't start yet | Missing type label or acceptance criteria | Fix it and add the `ai:*` label again |
| 💬 Dev Claude replied without a new commit | Woken to fix, but only replied (e.g. needs your decision) | Read the PR comments |

## Before merging

- The **latest** review summary (and test report) on the PR must name the PR's current head commit. A green run doesn't mean it passed (cancelled, blocked or skipped runs can be green too) — always read the comments
- No runs in progress or queued on the PR branch
- Merge pinned to the commit that passed, so GitHub refuses if more commits arrived:

  ```bash
  gh pr merge <number> --merge --match-head-commit <passed commit>
  ```

- If any commit was pushed before merging (including merging the base branch to resolve conflicts), wait for the new version to pass review again

## Stepping in

- **Add details or change direction**: comment `@claude` with instructions on the PR (or the issue, if there's no PR yet). Only comments from people with write access count
- **`blocked`**: read the explanation on the issue, provide what's needed, remove `blocked`, then comment `@claude 繼續` ("continue")
- **Reset the round count**: remove the `round-N` label from the PR
- **Drop it**: close the PR and issue. Closed or merged PRs are never changed again

## Troubleshooting

| Problem | Cause and fix |
|---|---|
| Nothing happens after adding `ai:subscription` | Check the "AI 開發" run under Actions. No run: make sure the caller files are on the default branch (issue events use the default branch's workflows). A run that didn't start work: read the start check in the run summary |
| Start check says acceptance criteria are missing | The heading must be exactly `## 驗收條件` on its own line (not bold, not a different wording), with at least one real item under it |
| PR wasn't reviewed | Neither the PR nor the issue it closes has an `ai:*` label; the PR comes from a fork; only docs changed (path filter); the commit message contains `[skip ci]` |
| Dev Claude's commit didn't trigger a review | The Claude GitHub App isn't authorized for the repo, so the push used `GITHUB_TOKEN` (which GitHub doesn't let trigger other workflows) |
| Comment saying the AI setup is wrong | The secret or variable for that `ai:<provider>` label is missing, see [Other AI providers](providers.md) |
| Review keeps finding new issues | Each round's changes introduce new problems; keep fixes aligned with the review, or state clearly in the issue what not to do |
| No Telegram messages | `TELEGRAM_BOT_TOKEN` / `TELEGRAM_CHAT_ID` missing or wrong; the run shows a warning |
