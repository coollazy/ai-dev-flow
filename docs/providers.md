# Other AI providers

English | [繁體中文](providers.zh-TW.md)

By default only `ai:subscription` exists: a Claude subscription (`CLAUDE_CODE_OAUTH_TOKEN`). You can also add any service that speaks the **Anthropic Messages API**, such as an Anthropic API key or an API gateway. Each issue picks a provider with a label.

## Adding one

Say the provider is called `myapi` (lowercase letters, digits and `-` only):

1. **Name and prefix**: the label is `ai:myapi`; the secret/variable prefix is the name uppercased with `-` replaced by `_`, i.e. `MYAPI` (`my-proxy` becomes `MY_PROXY`)
2. **Store the key and URL**:

   ```bash
   gh secret set MYAPI_API_KEY -R <REPO>                          # paste the key; never put it in code or chat
   gh variable set MYAPI_BASE_URL -R <REPO> -b https://api.example.com
   ```

3. **Optional: default models** (used without a `model:` label; otherwise `default_model`, `claude-opus-5-5` by default):

   ```bash
   gh variable set MYAPI_MODEL -R <REPO> -b <model name>
   gh variable set MYAPI_HAIKU_MODEL -R <REPO> -b <small model name>   # used by Claude Code for background tasks
   ```

4. **Add it to `providers` in both caller files** (`ai-dev.yml` and `ai-review.yml` must match):

   ```yaml
   providers: subscription myapi
   ```

5. **Create the label**:

   ```bash
   gh label create ai:myapi -R <REPO> --color 1d76db --description "Start with myapi"
   ```

Issues labeled `ai:myapi` now use it. A PR opened by the dev Claude inherits the labels of the issue it closes, so its review uses the same provider.

## Example: Anthropic API key

```bash
gh secret set ANTHROPIC_API_KEY -R <REPO>
gh variable set ANTHROPIC_BASE_URL -R <REPO> -b https://api.anthropic.com
```

`providers: subscription anthropic`, label `ai:anthropic`.

## Rules and limits

- **No default URL**: if `<PREFIX>_BASE_URL` is missing, work doesn't start and a comment says what's missing, so the key is never sent to the wrong place
- **Missing key**: same — no start, with a comment
- **One `ai:*` label per issue**: two are treated as a configuration error
- **Model labels**: `model:<name>` only accepts names listed in `models`; to use other models, change `models` and create matching labels. Names must be ones the provider recognizes
- **Key protection**: the key goes only to Claude Code itself; commands Claude runs (Bash) can't see it, see [Security](security.md)
- The service must support what Claude Code uses (tool use, etc.); partially compatible gateways may fail midway
