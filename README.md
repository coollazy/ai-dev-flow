# ai-dev-flow

English | [繁體中文](README.zh-TW.md)

Open an issue → AI writes the code and opens a PR → AI reviews it → (optional) AI tests it → you get notified. A reusable AI development workflow built on GitHub Actions and [Claude Code](https://github.com/anthropics/claude-code-action), shared across projects.

Extracted from a project that uses it every day. The workflow lives in this repo; each project keeps only two short caller files and passes its differences in as inputs.

## What it looks like

1. You write an issue describing what to do, with **acceptance criteria**, and label it `feature` (or `bug`)
2. Add the `ai:subscription` label → the dev Claude implements the issue and opens a PR
3. The PR opens → the review Claude reads the code only and decides *pass / changes / suspicious*; the summary is posted on the PR
4. (Optional) If the project has tests set up, testing runs after the review passes: the test Claude exercises the change in the project's own test environment
5. Changes requested or tests failed → the dev Claude is woken up automatically to fix them, up to 3 rounds; you get a Telegram message when everything passes or when you need to decide something
6. You read the review summary and test report, then decide whether to merge

To step in at any point, comment `@claude` with instructions on the issue or PR.

## Documentation

| Document | Contents |
|---|---|
| [Setup](docs/setup.md) | Prerequisites, installing into a project, all inputs, hooking up tests, upgrading |
| [Daily use](docs/usage.md) | Starting work, reading results, merging, stepping in, notifications, troubleshooting |
| [Writing issues](docs/writing-issues.md) | The two kinds of issues, writing acceptance criteria, examples |
| [Other AI providers](docs/providers.md) | Using an Anthropic-compatible API instead of a Claude subscription |
| [Security](docs/security.md) | Who can trigger it, what the AI can access, risks to know about |
| [Design](docs/design.md) | Why it is built this way |

## Quick start

Full steps are in [Setup](docs/setup.md).

```bash
git clone https://github.com/coollazy/ai-dev-flow.git
cd ai-dev-flow
scripts/install.sh ~/path/to/your-project   # writes caller files and issue templates, creates labels (does not commit)
```

Then: install the Claude GitHub App on the project repo, store `CLAUDE_CODE_OAUTH_TOKEN`, adjust the two caller files, paste the rules section into the project's `AGENTS.md`, commit and push, and try it with a small issue.

## Before you use it

- **The workflow speaks Traditional Chinese**: the instructions given to the AI, the review summaries and test reports on PRs, Telegram messages and issue templates are all in Chinese. The acceptance criteria heading must be exactly `## 驗收條件`
- **It spends your quota**: every dev, review and test run uses Claude usage (subscription or API) and GitHub Actions minutes (public repos don't use minutes)
- **The AI pushes code to your repo**: the dev Claude has write access (it pushes only to its own branches and opens PRs; it never merges). Merging is always your call. Please read [Security](docs/security.md) first
- **Pin a version**: caller files reference this repo by commit SHA, so updates here never change your project silently; review the changes before bumping the SHA

## Status

Verified end to end in a test project: starting from an issue, the start check rejecting an issue without acceptance criteria, duplicate-start protection, opening the PR, review passing, Telegram notifications.

Not yet exercised for real: third-party AI providers, waking the dev Claude after *changes requested*, `@claude` comments, and the optional test stage. Issues are welcome.

## License

[MIT](LICENSE)
