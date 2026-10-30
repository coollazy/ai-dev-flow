# Design

English | [繁體中文](design.zh-TW.md)

## Architecture

- This repo holds two reusable workflows (`workflow_call`): [`dev.yml`](../.github/workflows/dev.yml) (development) and [`review.yml`](../.github/workflows/review.yml) (review and test)
- Each project keeps two short caller files ([`templates/workflows/`](../templates/workflows/)): triggers, permissions and path filters live there, project differences are passed with `with:`, and `secrets: inherit` hands over the project's own secrets
- Secrets live in each project; this repo has no secrets and no workflows that run on their own
- Caller files pin the shared workflow by commit SHA: a broken change here can't break every project at once, and new versions are tried in one project first

## Why the scripts are inline

The scripts that pick the AI provider, parse acceptance criteria, find the previous review and format summaries are all inside the two workflow files instead of separate `.sh` files:

- A called workflow runs in the caller's repo; `actions/checkout` gets the caller's code, not this repo's other files (a private copy would also need an extra token)
- A composite action could reach them, but `uses:` can't take variables, so the action version would be hard-coded and not locked by the caller's pinned commit
- Inline, pinning one commit pins the scripts too

The cost: the "pick the AI provider from labels" block exists in both `dev.yml` and `review.yml` and must be changed together (comments in both files say so).

## The start check uses no AI

The label and acceptance-criteria check is a fixed shell script: when something is missing it doesn't wake Claude or spend quota; it removes the `ai:*` label and notifies you, returning the issue to "not started".

## Queuing

A GitHub concurrency group holds only one pending run; a newer one cancels the pending one. Concurrency is set on jobs rather than on the whole workflow, so unrelated events (such as adding a `model:*` label) are skipped by the job condition and never take the pending slot away from a real start. The start check and development use separate groups, so a long dev run doesn't hold up later checks. When several labels are added to one issue in quick succession, a start marker on the issue (`<!-- ai-dev-start -->`) prevents starting twice.

## Review

- `pull_request_target`: the base branch's workflow and rules always run, so a PR can't change them; the PR's code goes into `pr-head/` and is read, not executed
- The review Claude has no permission to comment: it returns its verdict as structured output (`--json-schema`) and the workflow posts "## 審查總評（版本 <sha7>）". The PR always shows a summary for the reviewed version, and the run's status matches it
- Re-reviews look only at the latest round: the previous reviewed version comes from the last summary heading and must be in the current head's history; otherwise it's treated as a first review. This stops every round from re-reviewing everything and finding new nitpicks forever
- Severity is high / medium / low; low never blocks a PR or causes another round

## Testing is optional

Test environments differ too much between projects (docker, databases, browsers, simulators…), so the shared workflow defines only the interface: the project's setup script builds the environment and reports whether it started, and the test Claude uses the tools the project provides. Without it, a passing review counts as passing.

## Formats other code depends on

Change these together with the code that reads them:

- "## 審查總評（版本 <sha7>）" and "## 測試報告（版本 <sha7>）": re-reviews find the previous version from the former
- The `<!-- ai-dev-start -->` start marker
- The `round-N`, `ai:*` and `model:*` labels
