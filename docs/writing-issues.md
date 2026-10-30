# Writing issues

English | [繁體中文](writing-issues.zh-TW.md)

An issue is the work order for the AI: the dev Claude implements it, the review Claude checks it for missing or extra work, and the test Claude verifies its acceptance criteria one by one. The clearer it is, the fewer fix rounds you'll need.

> The workflow and templates are in Traditional Chinese. Section headings below are shown as *Chinese heading (meaning)*; the acceptance criteria heading **must** be written exactly as `## 驗收條件`.

## Two kinds of issues

| | Ready to start | To be planned |
|---|---|---|
| When | Scope and acceptance criteria are clear | Will be done, details not worked out |
| Template | "AI 新功能" (feature), "AI 修錯誤" (bug) | "待規劃（先記下來）" (to be planned) |
| Contents | Background, what to do, what not to do, **`## 驗收條件`**, user checks (optional), notes | A sentence or two: the outcome you want and why |
| Labels | `feature` or `bug`; add `ai:*` to start | No type label |
| Can start? | Yes | No: adding `ai:*` is rejected |

Once a to-be-planned issue is thought through, rewrite it in the ready-to-start format with acceptance criteria, then add `feature` / `bug`.

Settle scope and acceptance criteria with an AI assistant (or a teammate) before starting; changing direction after work starts costs much more.

## How the start check finds acceptance criteria

- There must be a heading on its own line that reads **exactly** `## 驗收條件` (`###` also works; a trailing colon is fine). `## 驗收`, `## 驗收標準`, `**驗收條件**` (bold isn't a heading) and `## Acceptance criteria` don't count
- Below it, before the next heading of the same level, there must be at least one real item. Template comments `<!-- … -->` and empty `1.`, `-`, `- [ ]` don't count; `###` subheadings for grouping are fine
- The check reads the issue body as it is now: after fixing it, just add the `ai:*` label again

```markdown
## 驗收條件
1. Opening `/articles?tag=no-such-tag` returns 404
2. Opening `/articles` still returns 200
```

## Writing each section

### Title
One sentence stating the outcome.
- Good: "Return 404 when the article list page number is out of range"
- Bad: "Article list problem", "fix bug"

### `## 背景` (background)
Why: what happens now and who is affected. For bugs, how to reproduce: where, what you did, what you saw, what you expected.

### `## 要做什麼` (what to do)
The outcome you want, not how to change the code. Mention related pages or files if you know them.

Leave nothing for the AI to guess: name the one library, tool or approach to use instead of "A or B" or "for example". If the AI should decide, say "the dev agent decides" and give the criteria.

### `## 不要做什麼` (what not to do)
The most often skipped section, and the best way to prevent extra work. For example:
- Change only the article list, not the article page
- Don't change the database schema
- Don't add packages

The review Claude checks the PR against this section.

### `## 驗收條件` (acceptance criteria)
The most important section: review and testing decide based on this section only, and every item must hold. Anything that must be confirmed belongs here; other sections are checked only in passing.

- **Each item can be answered yes or no**
- **Write it as something checkable**: where to go, as which user, what should appear
- **Give concrete values**: status codes, exact text, returned fields
- **Only what review and testing can check**: if the project has tests set up, follow the test capabilities described in its `AGENTS.md`; mark items that can only be confirmed by reading the code with "（讀程式碼確認即可）" ("code reading is enough"). Without tests, the review only reads code, so write criteria that code reading can confirm
- **Don't forget "nothing broke"**: list one or two existing behaviors most likely to be affected
- Things required every time ("the build passes", "write a change record") belong in the project's `AGENTS.md`, not in every issue

| Bad | Good |
|---|---|
| The page should work | `/articles?page=999` returns 404; `/articles?page=2` still returns 200 |
| Clear error message | With a password under 8 characters, the page shows "密碼至少要 8 個字元" |
| Admins only | Opening `/admin/stats` logged out redirects to `/login`; admins can see it |
| Look nicer | Title uses `#D4A73B` (code reading is enough); whether it looks good goes under user checks |
| Faster | (Hard to state as a criterion — first agree on what to measure) |

### `## 使用者驗證` (user checks, optional)
Things you must check yourself that the AI can't: judging looks from screenshots, trying it on a phone, things only visible after deployment. Keep this separate from acceptance criteria; review and testing ignore it.

### `## 補充` (notes, optional)
Related issues, PRs, reference sites, and constraints you know but the AI may not (e.g. "the mobile app also uses this field, don't rename it").

## How big should an issue be

- One independently verifiable change per issue; split large features and open them in order
- Rough guide: 3–6 acceptance criteria. If you're writing 10 or more, it probably needs splitting
- If issues depend on each other, open the next one after the previous one is merged

## Don't ask for these in an issue

- Changes to rules or automation (`AGENTS.md`, `CLAUDE.md`, `.claude/`, `.github/`), Dockerfiles, compose files, or package manifests the project blocks: PRs touching them are stopped for human review. Make those changes yourself or with a local AI assistant
- Work that needs secrets, accounts or anything outside the repo: the dev Claude will add `blocked` and stop

## Examples

### bug

```markdown
Title: Return 404 when the article list tag doesn't exist

## 背景
`/articles?tag=no-such-tag` shows an empty list with status 200, so search engines index it as a normal page.

## 要做什麼
Return 404 and show the site's 404 page when the tag doesn't exist.

## 不要做什麼
- Keep showing an empty list when the tag exists but has no articles
- Don't touch the sitemap

## 驗收條件
1. `/articles?tag=no-such-tag` returns 404
2. `/articles?tag=<an existing tag>` still returns 200 and shows that tag's article titles
3. `/articles` still returns 200
```

Label: `bug`; add `ai:subscription` to start.

### feature

```markdown
Title: Search the admin article list by title

## 背景
With many articles, finding one in the admin means paging through the list.

## 要做什麼
Add a search box to `/admin/articles` that lists only articles whose title contains the keyword, with `?q=keyword` in the URL.

## 不要做什麼
- Search titles only, not bodies
- Don't change the public article list

## 驗收條件
1. As an admin, `/admin/articles?q=<a word from an article title>` lists that article and no article without the word
2. `/admin/articles?q=<a string that never appears>` shows "找不到文章" (no articles found)
3. Opening `/admin/articles?q=anything` logged out redirects to the login page

## 使用者驗證
- Position and style of the search box
```

Label: `feature`.

### To be planned

```markdown
Title: Add a share button to article pages

Readers copy the URL by hand to share an article; a one-tap share would help. Which platforms and where to put it — to be discussed.
```

No labels.

## Common causes of extra rounds

| Symptom | Usually because | Next time |
|---|---|---|
| Review keeps saying "extra work" | No "what not to do" | State the scope |
| Testing says "can't verify" | A criterion the tests can't check | Move it to user checks, or say how to prepare the data |
| Passed, but something wasn't done | It was only in "what to do", not in acceptance criteria | Put anything that must be confirmed in `## 驗收條件` |
| Result isn't what you meant | "What to do" described code changes, or only half the picture | Describe the outcome, with examples if needed |
| Stopped by the fixed check | The change touches rules, `.github/` or manifests | Make those changes yourself |
