---
name: dotfiles-repo-rollout
overview: Create a safe, GitHub-based dotfiles setup without leaking private config and with controlled deletion of unwanted local settings. The rollout is iterative, reversible where possible, and includes mandatory human checkpoints before any destructive actions.
todos:
  - id: inventory-config
    content: Inventory and classify all current config files into shareable, private-but-needed, and obsolete-delete.
    status: completed
  - id: audit-upstream-template
    content: Review recent changes in lewagon/dotfiles and decide what to adopt, adapt, or ignore.
    status: completed
  - id: decide-repo-visibility
    content: Decide private vs public repo and adjust policy, templates, and risk gates accordingly.
    status: completed
  - id: design-repo-policy
    content: Define repo layout, .gitignore policy, and secret-handling conventions with templates.
    status: completed
  - id: bootstrap-safe-batches
    content: Initialize repo and add shareable files in small, reviewable commits.
    status: in_progress
  - id: externalize-private
    content: Replace private values with placeholders/env references and keep real secrets local-only.
    status: pending
  - id: dry-run-apply
    content: Choose apply mechanism and run dry-run with conflict and rollback reporting.
    status: pending
  - id: cleanup-with-gates
    content: Quarantine obsolete files first, then delete only after explicit human approval checkpoint.
    status: pending
  - id: validate-and-operationalize
    content: Test setup in clean environment and establish ongoing maintenance/audit process.
    status: pending
isProject: false
---

# GitHub Dotfiles Rollout Plan

## Goal

Set up a maintainable dotfiles repository that tracks only shareable configuration, excludes secrets/private machine data, safely removes obsolete local config only after explicit human approval, and intentionally incorporates useful updates from the upstream lewagon baseline where relevant.

## Constraints And Safety Rules

- Never commit secrets, tokens, private keys, hostnames, personal paths, or machine-specific credentials.
- Prefer templating or placeholders for private values.
- Deletions are staged and reviewed first; no irreversible deletion without explicit approval.
- Agent must STOP implementation for human evaluation at each checkpoint before proceeding.

## Iterative Task Breakdown

### Task 1 — Inventory Current Config (Read-only)

- Create a candidate list of config files/directories currently used (shell, git, editor, terminal, package manager, tool-specific configs).
- Classify each candidate into:
  - `shareable`
  - `private-but-needed`
  - `obsolete-delete`
- Output a simple manifest (path, category, reason).

#### Task 1 Findings (Completed)

Inventory completed in read-only mode from home-level dotfiles and `~/.config`.

`shareable`

- `~/.zshrc` (symlink) - primary shell config.
- `~/.zprofile` - login shell bootstrap config.
- `~/.aliases` (symlink) - reusable aliases/functions.
- `~/.gitignore_global` - global ignore patterns.
- `~/.vimrc` (symlink) - editor config.
- `~/.config/nvim/` - editor config and plugins.
- `~/.config/alacritty/` - terminal config.
- `~/.config/ghostty/` - terminal config.
- `~/.config/yazi/` - file manager config.
- `~/.config/zellij/` - terminal multiplexer config.

`private-but-needed`

- `~/.gitconfig` (symlink) - contains identity/signing includes; must be templated.
- `~/.npmrc` - commonly includes registry token.
- `~/.netrc` - credential storage by design.
- `~/.ssh/` - private keys/known hosts.
- `~/.aws/` - credentials and profiles.
- `~/.gnupg/` - private key material.
- `~/.config/gh/` - GitHub CLI auth/session state.
- `~/.config/gcloud/` - cloud auth/session state.
- `~/.config/configstore/` - tool auth/state cache.
- `~/.cursor/` - editor state/auth history.
- `~/.claude.json` - agent/auth or user config with sensitive values.
- `~/.mcp-auth/` - MCP auth artifacts.
- `~/.zsh_history`, `~/.bash_history` - command history can contain secrets.

`obsolete-delete`

- `~/.zcompdump*`, `~/.zcompdump*.zwc` - generated shell completion caches.
- `~/.codewhisperer.dotfiles.bak/` - stale backup artifact.
- `~/.fig.dotfiles.bak/` - stale backup artifact.
- `~/.zshrc.backup`, `~/.zshrc.save`, `~/.gitconfig.backup` - backup copies.
- `~/.config/kitty/` - user-requested delete candidate.
- `~/.config/iterm2/` - user-requested delete candidate.

Notes:

- Existing legacy repo detected at `~/code/brucruz/dotfiles` with active symlinked files.
- No destructive actions performed in Task 1.

### Task 2 — Define Repository Structure And Policies

- Decide repository visibility (`private` or `public`) before bootstrap.
- Define visibility-specific risk policy:
  - if `public`: stricter defaults, secret scan required on every commit, stronger denylist.
  - if `private`: still no secrets committed, but permits personal non-sensitive preferences.
- Propose a minimal repo layout, for example:
  - `dotfiles/` (tracked public config)
  - `private.example/` (templates/placeholders only)
  - `scripts/` (bootstrap/symlink/install)
- Define secret-handling policy:
  - `.gitignore` denylist for sensitive patterns/files
  - optional pre-commit secret scan (e.g., gitleaks/trufflehog)
  - use `.example` files for private config contracts
- **STOP for human evaluation** of structure/policy before repo init.

#### Task 2 Findings (Approved: `private` selected)

Visibility decision is now fixed to `private` for initial rollout. Comparison retained for future reassessment:

| Option    | Best for                                                                                             | Required controls                                                                                             | Recommendation                        |
| --------- | ---------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------- | ------------------------------------- |
| `private` | Initial migration with lower accidental disclosure risk while still sharing across personal machines | Secret scan on staged files, strong denylist, templates for private contracts                                 | **Recommended for initial rollout**   |
| `public`  | Open-source sharing/community reuse                                                                  | Mandatory pre-commit secret scan, stricter allowlist approach, no personal preferences unless fully sanitized | Consider after initial hardening pass |

Proposed minimal repository layout:

- `dotfiles/` - tracked, shareable config only (shell/editor/terminal/tool configs already classified as shareable).
- `private.example/` - placeholder/template contracts for required private files (for example `gitconfig`, `npmrc`, `netrc` fragments).
- `scripts/` - bootstrap/apply/verify scripts (non-destructive by default).
- `docs/policies/` - security and contribution policy docs for classification and review gates.

Proposed secret-handling policy (effective now in `private` mode):

- Default denylist in root `.gitignore` for private/auth/state material:
  - `.env`_, `_.pem`, `_.key`, `_.p12`, `\*.pfx`
  - `.netrc`, `.npmrc` (real), `.aws/`, `.ssh/`, `.gnupg/`
  - `.cursor/`, `.mcp-auth/`, `.claude.json`, shell history files
- Track only examples/templates for private contracts:
  - `private.example/gitconfig.personal.example`
  - `private.example/npmrc.example`
  - `private.example/netrc.example`
- Pre-commit secret scan:
  - `private` mode (current): strongly recommended (run on staged diff before each commit).
  - `public` mode (future transition): mandatory gate (commit blocked on detection).
- Redaction rules:
  - No hostnames tied to private infra.
  - No personal absolute paths in committed files.
  - Use environment variable references for machine/user-specific values.

Human approval checkpoint for Task 2:

1. Proposed layout (`dotfiles/`, `private.example/`, `scripts/`, `docs/policies/`) - **approved**.
2. Secret-handling baseline and scan strictness for `private` mode - **approved** with scan policy set to **strongly recommended** (non-blocking).
3. Readiness to proceed to Task 2.5 - **approved**.

Task 2 status: completed. Structure/policy approved for `private` mode and Task 2.5 has been executed.

### Task 2.5 — Upstream Baseline Review (Le Wagon)

- Compare local legacy baseline (`~/code/brucruz/dotfiles`) with current upstream `lewagon/dotfiles` state.
- Focus review on:
  - shell bootstrap (`zshrc`, `zprofile`, aliases)
  - git defaults (`gitconfig`, setup scripts)
  - editor ergonomics (VS Code or equivalent settings)
  - install/bootstrap script improvements
- For each upstream change, classify as:
  - `adopt-as-is`
  - `adapt`
  - `ignore`
- Produce an adoption matrix with rationale and security notes.
- **STOP for human evaluation** before importing any upstream pattern.

#### Task 2.5 Findings (Completed review; import pending approval)

Comparison scope was executed between local legacy baseline at `~/code/brucruz/dotfiles` and current upstream `lewagon/dotfiles` (fetched via HTTPS due local SSH permission limits in this environment). Review focused on shell bootstrap, git defaults, editor ergonomics, and install/bootstrap scripts.

Top-level file deltas observed:

- Local-only (legacy): `vimrc`, `gitignore`, `gemrc`, `tm_properties`, and Sublime settings files.
- Upstream-only (new baseline candidates): `zprofile`, `settings.json`, `keybindings.json`, `config`, `pryrc`.

Human decisions applied:

- Sublime-related config is now explicitly out of scope and will be discarded from migration (`Package Control.sublime-settings`, `Preferences.sublime-settings`, Sublime bootstrap steps/aliases).
- `zshrc` migration constraints:
  - Keep current Oh My Zsh lazy `nvm` style (do not switch to upstream `load-nvmrc` hook flow).
  - Keep `HOMEBREW_NO_ANALYTICS` handling as in current config (commented, not force-enabled).
  - Remove `JAVA_HOME`, `ANDROID_HOME`, and `FIRESTORE_EMULATOR_HOST` exports from shared target `zshrc`.
  - Keep current Zinit usage and plugin loading behavior.

Adoption matrix:

| Area              | Upstream pattern                                                                                                                               | Classification                       | Rationale                                                                                                              | Security notes                                                                                                    |
| ----------------- | ---------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------ | ---------------------------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------- |
| Shell bootstrap   | `zprofile` pyenv/homebrew bootstrap                                                                                                            | `adapt`                              | Useful split between login-shell initialization and interactive shell config; aligns with modern shell startup design. | Remove hardcoded machine paths if added; keep only portable env setup.                                            |
| Shell bootstrap   | `zshrc` improvements (`ZSH_DISABLE_COMPFIX`, `unalias` safety cleanup, `nvm` auto-load via `.nvmrc`)                                           | `adapt`                              | Practical quality-of-life defaults; safer and cleaner than legacy monolithic `zshrc`.                                  | Do not import absolute personal paths, host-specific exports, or private infra values from current local `zshrc`. |
| Shell bootstrap   | Current Zinit block (`zinit` bootstrap + `zsh-autosuggestions` + `zsh-completions`)                                                            | `adopt-as-is`                        | User approved retaining current zinit-managed plugin setup to preserve behavior.                                       | Avoid installer-style side effects in interactive shell startup where possible.                                   |
| Shell bootstrap   | Upstream `aliases` (`myip`, `speedtest`, `stt`)                                                                                                | `adapt`                              | Adopt upstream alias ideas except `stt`; also remove `serve` from target alias set per user preference.                | No direct secret risk; keep aliases minimal and tool-agnostic where possible.                                     |
| Git defaults      | `gitconfig` dynamic branch aliases (`defaultBranch`, `remoteSetHead`, branch-agnostic `m`, improved `sweep`)                                   | `adopt-as-is`                        | Improves compatibility with `main`/`master` mixed repos and removes hardcoded branch assumptions.                      | Keep `[user]` identity out of tracked file; identity must be templated in `private.example`.                      |
| Git defaults      | `gitconfig` editor defaults (`code --wait`) and pull policy (`pull.rebase = false`)                                                            | `adapt`                              | Keep pull policy; adapt editor command to preferred tool (`cursor --wait` if desired).                                 | Avoid personal absolute paths in `core.excludesfile`; use `$HOME`-portable value.                                 |
| Git setup         | `git_setup.sh` simplified identity script                                                                                                      | `ignore`                             | Still performs commit/push side effects; not needed for safe bootstrap model.                                          | Contains network and history-mutating actions; should not be part of non-destructive bootstrap path.              |
| Editor ergonomics | VS Code `settings.json` baseline                                                                                                               | `ignore`                             | User requested to ignore upstream settings baseline; keep current local/editor-managed preferences instead.            | No secret risk; avoids importing opinionated workspace-global defaults.                                           |
| Editor ergonomics | VS Code `keybindings.json` (`pasteAndIndent`)                                                                                                  | `ignore`                             | User requested to ignore upstream keybindings baseline.                                                                | No secret risk; avoids drift from current keymap habits.                                                          |
| Install/bootstrap | Upstream `install.sh` explicit allowlist symlinking and helper functions (`backup`, `symlink`)                                                 | `adopt-as-is`                        | Cleaner and safer than legacy exclusion-based loop; deterministic files to link.                                       | Keep script non-destructive; preserve backup behavior before linking.                                             |
| Install/bootstrap | Upstream `install.sh` editor and SSH config symlinking (`settings.json`, `keybindings.json`, `~/.ssh/config`)                                  | `adapt`                              | Editor symlinks are useful; SSH handling should be decoupled into optional private step.                               | `~/.ssh/config` and keychain ops are private/sensitive and must be optional + template-driven only.               |
| SSH defaults      | Upstream `config` file                                                                                                                         | `ignore` (for tracked public config) | Too environment-specific for shared baseline in current phase.                                                         | Keep SSH config under `private.example` contract, never as real tracked private config.                           |
| Legacy editor     | Sublime files and Sublime install logic (`Package Control.sublime-settings`, `Preferences.sublime-settings`, Sublime symlinks in `install.sh`) | `ignore`                             | User no longer uses Sublime; keeping these adds maintenance noise.                                                     | No direct secret risk, but unnecessary surface area and obsolete tooling.                                         |

Recommended import order after approval:

1. Adopt upstream-style `install.sh` structure (allowlist + safe backups), excluding SSH/private hooks.
2. Adapt `gitconfig` branch-aware aliases and keep identity in private template only.
3. Adapt shell (`zprofile` split + selected `zshrc` improvements) without machine-specific values.
4. Keep editor preferences as-is (explicitly skip upstream `settings.json` and `keybindings.json`).

Expected changes and diff impact (preview for Task 3 bootstrap):

- `add` files (likely 2-4 files):
  - `dotfiles/zprofile` (adapted from upstream + local compatibility checks).
  - `scripts/install.sh` (deterministic allowlist symlink flow; no SSH/private side effects).
  - Optional small docs/policy stubs already approved in Task 2.
- `modify` files (likely 2-3 files):
  - `dotfiles/zshrc` (portable cleanup + selected upstream improvements, remove machine-specific exports).
  - `dotfiles/gitconfig` (branch-aware aliases; editor command adapted; identity excluded to private template).
  - `dotfiles/aliases` (adopt upstream non-obsolete aliases, remove `stt` and `serve`).
- `private templates` added (likely 2-4 files):
  - `private.example/gitconfig.personal.example`.
  - `private.example/npmrc.example`.
  - `private.example/netrc.example`.
  - Optional `private.example/ssh-config.example` contract if SSH layering is kept.
- `excluded/ignored` from migration:
  - All Sublime artifacts and Sublime bootstrap logic.
  - Upstream `settings.json` and `keybindings.json`.
  - `git_setup.sh` side-effectful identity/commit/push flow.
  - Real SSH config/auth artifacts.
- Net impact estimate:
  - Moderate additive diff with focused replacements (roughly 90-180 LOC added, 50-120 LOC adapted, and obsolete local-only blocks dropped from migration scope).
  - Low destructive risk because Task 3 remains non-destructive and backup-first.

Human approval checkpoint for Task 2.5:

1. Adoption matrix decisions above (including explicit Sublime discard) - **pending explicit go/no-go**.
2. Readiness to begin Task 3 bootstrap (non-destructive batches) using approved upstream patterns only - **pending explicit go/no-go**.

### Task 3 — Bootstrap Dotfiles Repo (Non-destructive)

- Repository bootstrap model:
  - Rename legacy repository from `~/code/brucruz/dotfiles` to `~/code/brucruz/dotfiles-old` before bootstrap.
  - Create/bootstrap the new canonical repository at `~/code/brucruz/dotfiles`.
  - Treat `~/code/brucruz/dotfiles-old` as reference/rollback source only (no new implementation work there).
- Initialize repository and baseline files (`README`, `.gitignore`, bootstrap script skeleton).
- Add only low-risk, clearly shareable files first.
- Commit in small batches per tool (shell, git, editor) to keep review granular.
- Apply approved scope guardrails from Task 2.5:
  - Exclude all Sublime artifacts and Sublime bootstrap logic.
  - Exclude upstream `settings.json` and `keybindings.json`.
  - Exclude `git_setup.sh` side-effectful identity/commit/push flow.
  - Exclude tracked SSH config and real auth artifacts.
- Apply approved shell constraints for `zshrc`:
  - Keep current OMZ lazy `nvm` style.
  - Keep `HOMEBREW_NO_ANALYTICS` as current config style (commented, not force-enabled).
  - Remove `JAVA_HOME`, `ANDROID_HOME`, and `FIRESTORE_EMULATOR_HOST`.
  - Keep current zinit usage/plugins.
- Apply approved aliases constraints:
  - Adopt upstream alias ideas selectively.
  - Remove `stt` and `serve`.
- Execute first batch using explicit A/M/I checklist:
  - `A` (add): `dotfiles/zprofile`, `scripts/install.sh`, private templates (`private.example/gitconfig.personal.example`, `private.example/npmrc.example`, `private.example/netrc.example`).
  - `M` (modify): `dotfiles/zshrc`, `dotfiles/gitconfig`, `dotfiles/aliases`.
  - `I` (ignore): upstream editor baseline files, Sublime files, `git_setup.sh`, tracked SSH config.
- **STOP for human evaluation** after each batch commit.

#### Task 3 Findings (Batch 1 implemented; checkpoint approved)

Batch 1 was implemented in `~/code/brucruz/dotfiles` using non-destructive, backup-first behavior.

Completed A/M/I outcomes:

- `A` (added):
  - `dotfiles/zprofile`
  - `scripts/install.sh` (allowlist linker with `--dry-run`)
  - `private.example/gitconfig.personal.example`
  - `private.example/npmrc.example`
  - `private.example/netrc.example`
  - root `.gitignore` with credential/auth/state denylist
- `M` (modified):
  - `dotfiles/zshrc` (removed machine-specific env exports and personal absolute paths; retained approved OMZ lazy `nvm` and zinit behavior)
  - `dotfiles/gitconfig` (portable excludesfile, branch-aware aliases, identity externalized to include file)
  - `dotfiles/aliases` (removed `serve`, excluded `stt`)
  - `README.md` (bootstrap/apply guidance)
- `I` (ignored/excluded as approved):
  - upstream `settings.json` and `keybindings.json`
  - all Sublime artifacts and Sublime bootstrap logic
  - `git_setup.sh`
  - tracked SSH config and real auth artifacts

Git identity handling (approved Option B, now implemented):

- `dotfiles/gitconfig` includes `~/.gitconfig.personal`.
- Installer creates `~/.gitconfig.personal` from template when missing.
- Installer prompts interactively for `user.name`, `user.email`, and optional `user.signingkey`, then writes to local private file only.
- In non-interactive contexts, installer skips prompt with explicit message.

Validation snapshot:

- `./scripts/install.sh --dry-run` executed successfully.
- No `sublime`/`subl` references remain in tracked repo content.

Human checkpoint for Task 3:

1. Approve Batch 1 implementation scope and behavior - **approved**.
2. Approve checkpoint commit creation for Batch 1 - **approved**.
3. Approve proceeding to Task 4 private externalization hardening - **deferred / do not proceed yet**.

### Task 4 — Private Config Externalization

- For each `private-but-needed` file, replace tracked values with placeholders or env-variable references.
- Keep private real values out of repo (local-only path or secret manager).
- Add validation notes so setup fails clearly if private values are missing.
- Confirm local-only contract files created by installer (`~/.gitconfig.personal`) are not tracked and remain mode `600`.
- Add explicit non-interactive guidance (CI/headless): pre-create `~/.gitconfig.personal` before running installer.
- **STOP for human evaluation** before merging any file that previously had sensitive content.

### Task 5 — Dry-run Apply Strategy

- Decide application model (symlink manager like `stow` vs copy/bootstrap script).
- Run dry-run to preview what would change in `$HOME`.
- Capture conflicts and rollback strategy.
- Current decision: keep bootstrap script model (`scripts/install.sh`) as canonical apply mechanism for this rollout.
- Add explicit rollback command examples per linked target (restore from timestamped backup paths).
- **STOP for human evaluation** before first real apply.

### Task 6 — Controlled Cleanup And Deletion Plan

- Build explicit deletion list only from `obsolete-delete` items.
- For each deletion candidate, record:
  - backup path
  - restore command
  - delete command
- Execute in two steps:
  1. backup + quarantine move
  2. later hard delete after verification window
- **Mandatory STOP for human evaluation** between quarantine and permanent deletion.

### Task 7 — Validation Across Environments

- Test bootstrap on a clean shell session and (if possible) secondary machine/container.
- Verify core workflows: shell startup, git, editor, package manager, language runtimes.
- Add quick health-check script to confirm expected tools/config loaded.
- Include identity validation in health-check (`git config --global user.name` and `user.email` resolve via include file).

### Task 8 — Operationalize Maintenance

- Add contribution/change protocol:
  - new config must be classified first
  - secret scan before each push
  - small PRs with risk labels (`safe`, `sensitive`, `deletion`)
- Add periodic audit cadence (e.g., monthly) for stale local configs and secret drift.

## Execution Cadence

- Run one task at a time.
- Every task ends with explicit review output and a go/no-go decision.
- If any secret risk is detected, pause and remediate before continuing.
