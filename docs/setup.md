# Setup

English | [繁體中文](setup.zh-TW.md)

## Prerequisites

| You need | For |
|---|---|
| A GitHub repo you administer | The project to install the workflow into |
| [GitHub CLI](https://cli.github.com/) (`gh`), logged in | The install script creates labels; storing secrets |
| A Claude subscription (Pro / Max) and [Claude Code](https://docs.anthropic.com/en/docs/claude-code) | `claude setup-token` creates the credential used by GitHub Actions. For API keys only, see [Other AI providers](providers.md) |
| The [Claude GitHub App](https://github.com/apps/claude) | The dev Claude pushes commits and opens PRs as this app (commit author `claude[bot]`), so its pushes trigger the review |
| A Telegram bot (optional) | Notifications. Without it the workflow still runs, it just doesn't notify |

## Installing into a project

Below, replace `<REPO>` with your project (e.g. `you/my-app`) and `<project-dir>` with its local folder.

### 1. Get this repo

```bash
git clone https://github.com/coollazy/ai-dev-flow.git
```

To maintain your own copy, fork it and clone your fork; the install script will reference your fork automatically. If your fork or copy is **private**, allow your other repos to call it:

```bash
gh api -X PUT repos/<you>/ai-dev-flow/actions/permissions/access -f access_level=user
```

(Same as Settings → Actions → General → Access → "Accessible from repositories owned by the user". A private reusable workflow can only be called by repos of the same user or organization.)

### 2. Authorize the Claude GitHub App

Install it from <https://github.com/apps/claude> and add `<REPO>` under Repository access.

### 3. Store the Claude credential

In another terminal run `claude setup-token`, copy the printed token, then (macOS):

```bash
pbpaste | tr -d ' \n' | gh secret set CLAUDE_CODE_OAUTH_TOKEN -R <REPO>
```

Never paste the token into a chat, issue or code.

### 4. Telegram notifications (optional)

```bash
gh secret set TELEGRAM_BOT_TOKEN -R <REPO>
gh secret set TELEGRAM_CHAT_ID -R <REPO>
```

One bot can serve several projects; each message names the repo.

### 5. Install caller files, issue templates and labels

```bash
cd ai-dev-flow
scripts/install.sh <project-dir>
```

It writes:
- `.github/workflows/ai-dev.yml`, `ai-review.yml`: the two caller files, pinned to the latest release by commit SHA (e.g. `@97f7655… # v0.1.0`)
- `.github/ISSUE_TEMPLATE/ai-feature.md`, `ai-bug.md`, `idea.md`: issue templates

and creates these labels on `<REPO>`: `bug`, `feature`, `ai:subscription`, `model:claude-opus-5-5`, `model:claude-sonnet-5-5`, `blocked`, `round-1` to `round-3`.

Options: `--force` overwrites existing files (skipped by default), `--no-labels` skips labels, `--ref <version or commit>` pins a specific version (e.g. `--ref v0.1.0`), `--repo <owner/repo>` sets which repo to reference. The script never commits or pushes.

### 6. Adjust the caller files

In the `with:` block of both caller files, check at least:
- `base_branch`: the branch PRs target (default `develop`; set `main` if that's all you have). Change `records_base` in `ai-review.yml` too
- `setup_command`: what to install before Claude starts, e.g. `npm ci`
- `allowed_tools`: build/test commands the dev Claude may run, e.g. `Bash(npm run build),Bash(npm test)`
- `project_instructions`: how to build, verify and write change records
- `blocked_extra`: extra files that stop the review and wait for a human, e.g. package manifests `^package\.json$|^package-lock\.json$`

All inputs are listed under "Inputs" below.

### 7. Rules

Adapt [`templates/AGENTS-ai-flow.md`](../templates/AGENTS-ai-flow.md) (`<base 分支>`, how to write change records, drop the test section if unused) and paste it into the project's `AGENTS.md` (or `CLAUDE.md`). The dev, review and test Claudes all read it; the review always reads the base branch version, so a PR can't change it.

### 8. Push and try it

Commit and push to the base branch, open a tiny issue following [Writing issues](writing-issues.md) (e.g. change a line of text), add `feature` and `ai:subscription`, and check that dev, review and notification all complete.

## Inputs

Every input and its default is defined at the top of [`dev.yml`](../.github/workflows/dev.yml) and [`review.yml`](../.github/workflows/review.yml).

### `ai-dev.yml` (dev)

| Input | Default | Description |
|---|---|---|
| `base_branch` | `develop` | Branch PRs target |
| `branch_prefix` | `ai/issue-` | Prefix of dev branch names |
| `setup_command` | empty | Runs before Claude starts (e.g. `npm ci`). Commands Claude runs are sandboxed and often can't install packages, so install them here |
| `allowed_tools` | empty | Extra commands allowed for the dev Claude, comma-separated. git, `gh issue`, `gh pr`, `gh api` and file read/write are always allowed |
| `project_instructions` | empty | How to build, verify and write change records; appended to the dev Claude's instructions |
| `extra_env` | empty | Extra environment variables, one `KEY=VALUE` per line (no secrets) |
| `runs_on` | `"ubuntu-latest"` | Where to run (JSON); for a self-hosted runner use `["self-hosted","my-runner"]` |
| `type_labels` | `bug feature` | Labels meaning "planned and ready" |
| `providers` | `subscription` | Available AI providers, see [Other AI providers](providers.md) |
| `models` | `claude-opus-5-5 claude-sonnet-5-5` | Models selectable with `model:<name>` labels |
| `max_turns` / `timeout_minutes` / `claude_timeout_minutes` | 80 / 45 / 35 | Turn and time limits |

### `ai-review.yml` (review and test)

| Input | Default | Description |
|---|---|---|
| `dev_workflow` | `ai-dev.yml` | Dev workflow file to wake up when changes are needed |
| `providers` | `subscription` | Same value as in `ai-dev.yml` |
| `blocked_pattern` | rules files, `.github/`, Dockerfile, compose files | PRs touching these skip the review and wait for a human (regex) |
| `blocked_extra` | empty | Extra files to block, appended to `blocked_pattern` |
| `records_files` | empty | Record files PRs must not change, e.g. `CHANGELOG.md TODO.md`; the dev Claude is asked to revert them |
| `records_base` / `records_exempt_prefix` | `develop` / `release/` | Which PR base the record check applies to, and which branches are exempt |
| `review_instructions` | empty | Project-specific review points |
| `max_rounds` | 3 | Maximum automatic fix rounds (needs matching `round-N` labels) |
| `review_max_turns` / `review_timeout_minutes` | 30 / 20 | Review turn and time limits |
| `test_setup` | empty | **Testing runs only when set**, see "Hooking up tests" |

The path filter (docs-only PRs skip the review) is in `on.pull_request_target.paths` of `ai-review.yml`; adjust it as needed.

## Hooking up tests (optional)

Without `test_setup`, a passing review counts as passing. Test environments vary too much between projects, so only the interface is defined here and each project builds its own environment:

| Input | Description |
|---|---|
| `test_setup` | Script that builds the test environment (a path on the base branch, run with bash, so PRs can't change it). The PR's code is in `pr-head/`. It must write `started=true` or `false` to `$GITHUB_OUTPUT`, and may write a multi-line `desc` describing the environment for the test Claude |
| `test_prompt_file` | Markdown file describing the test tools and how to use them; included in the test Claude's instructions |
| `test_allowed_tools` | Commands allowed for the test Claude, e.g. `Bash(.github/ai-test/http.sh:*)` |
| `smoke_script` | Fixed smoke check (no AI) run before the test Claude; exit 0 means pass |
| `ci_workflow` / `ci_step` | Use CI results for criteria like "unit tests pass" (the test Claude can't run package managers) |
| `test_artifacts` | Files uploaded as an artifact afterwards (default `ai-test-shots/*.png`) |
| `test_cleanup` | Cleanup script run afterwards (mainly for self-hosted runners) |
| `test_runs_on` / `test_max_turns` / `test_timeout_minutes` | Where to run, turn and time limits |

Commands run by the test Claude are sandboxed and can't reach docker. To read container logs or drive a browser, run a small bridge service outside the sandbox and give the test Claude a script that calls it. Testing executes the PR's code, so keep production secrets and data out of the test environment.

## Upgrading

Versions are published as [Releases](https://github.com/coollazy/ai-dev-flow/releases) (`v0.1.0`, …); see the [CHANGELOG](../CHANGELOG.md) for what changed. 0.x versions may include breaking changes.

1. Read the release notes and the diff between your version and the new one
2. In one project, replace `@<commit> # <version>` in both caller files with the new version's commit and tag (both files must match), then try a small issue
3. Then update the other projects

Caller files pin the commit SHA rather than the tag, because a tag can be moved later and a SHA can't.

To get upgrade PRs automatically, enable Dependabot for GitHub Actions in your project; it recognizes the `@<commit> # <version>` form:

```yaml
# .github/dependabot.yml
version: 2
updates:
  - package-ecosystem: github-actions
    directory: /
    schedule:
      interval: weekly
```

You can also rerun `scripts/install.sh <project-dir> --force` (after `git pull` here), but it overwrites your caller-file settings, which you'll need to restore.

## Notes

- Free GitHub Actions minutes and Claude usage are shared across your account; watch usage on busy private repos
- Hosted macOS runners consume minutes several times faster; for Swift / iOS builds or tests, point `runs_on` at your own Mac runner
- The dev Claude's full output is written to the log only in private repos (public repo logs are visible to everyone, so it's turned off there)
