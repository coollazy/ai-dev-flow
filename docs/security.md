# Security

English | [繁體中文](security.zh-TW.md)

This workflow lets AI change code, push commits and comment in your repo. This page covers who can trigger it, what the AI can access, and the risks to know about.

## Who can trigger it

| Trigger | Who |
|---|---|
| Adding `ai:*` or `bug` / `feature` labels to start | People with write access (GitHub only lets them label) |
| Commenting `@claude` | Only comments from `OWNER`, `MEMBER` or `COLLABORATOR`; others don't wake Claude and get no reply |
| PR review | Only PRs from branches in the same repo; **PRs from forks are never reviewed**, so they can't spend your quota |
| Waking the dev Claude to fix | The workflow itself (`github-actions[bot]`) |

A PR is reviewed only if it (or the issue it closes) has an `ai:*` label.

## What the AI can access

- **Dev Claude**: pushes commits, opens PRs and comments as the Claude GitHub App; can read and write the repo's code. Its `gh` access is limited to viewing, creating, editing and commenting on issues and PRs — no `gh api`, no merging or closing. Per the rules it works on its own branches; `git` itself isn't restricted, so **protect your base branch** (branch protection / rulesets) so nothing can be pushed to it directly
- **Review Claude**: can only read code, run `git diff` / `git log`, read issues and PRs, and leave line comments. The summary is posted by the workflow, not by the AI
- **Test Claude**: can only use the test tools the project provides
- **Secrets**: commands Claude runs (Bash) can't read the AI key or the token used to obtain GitHub credentials (`CLAUDE_CODE_SUBPROCESS_ENV_SCRUB`, sandboxed with bubblewrap on Linux). Secrets live in each project; this repo holds none
- **Logs**: the dev Claude's full output is logged only in private repos; it's off in public repos

## Built-in safeguards

- **Review uses the base branch's workflow and rules**: `pull_request_target` always runs the base branch's workflow and reads the base branch's `AGENTS.md`, so a PR can't change them. The PR's code goes into `pr-head/` and is read, never executed, by the review
- **Fixed check**: PRs touching rules files (`AGENTS.md`, `CLAUDE.md`, `.claude/`), `.github/`, Dockerfiles, compose files, or files you add via `blocked_extra` skip the review and wait for a human
- **Suspicious verdict**: if the review finds code unrelated to the issue that could harm the host or data (reading or sending secrets, contacting URLs the issue doesn't mention, deleting files outside the repo, changing package install scripts), it stops and doesn't auto-fix
- **At most 3** automatic fix rounds, then it stops and notifies you
- **Closed or merged PRs** are never changed or pushed to again

## Risks to know about

- **Issue and comment text is given to the AI**: it can be misled by instructions hidden in that text (prompt injection). Read issues opened by others before starting work on them. The dev Claude is told to act only on review results and comments from people with write access, but that is an instruction, not a hard limit
- **Testing executes the PR's code**: if you hook up tests, keep production secrets and data out of the test environment
- **Always read AI-written code before merging**: review and testing are done by AI and don't guarantee the absence of bugs or vulnerabilities
- **Run logs of public repos are public**: don't put secrets in inputs such as `project_instructions` or `extra_env`
- **Pin versions**: caller files reference the shared workflow by commit SHA, and the shared workflow pins every action it uses (`actions/checkout`, `claude-code-action`, …) by commit SHA too, so pinning one commit pins everything. When using someone else's copy, read it before pinning a commit, and review the changes before upgrading (or fork and maintain your own)

## Reporting a vulnerability

Please don't open a public issue. Use GitHub's [private vulnerability reporting](https://github.com/coollazy/ai-dev-flow/security/advisories/new) (the repo's Security tab).
