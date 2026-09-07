# Neovim 0.12 configuration

A reliability-first Neovim 0.12 configuration with a native-first editing model, project-aware tooling, strong TypeScript/JavaScript support, Catppuccin Mocha, fzf-lua, Blink completion, native LSP, Mason, Treesitter, Conform, Gitsigns, Markview, ToggleTerm, Mini, and a custom Just runner.

## Requirements

Required:

- Neovim 0.12+
- Git
- fzf 0.37+
- ripgrep (`rg`)
- curl
- tar
- C compiler
- tree-sitter CLI 0.26.1+

Recommended:

- fd
- unzip
- just
- lazygit
- shellcheck (adds Bash lint diagnostics through bash-language-server)
- `wl-clipboard` on Wayland
- `xclip` or `xsel` on X11

Language servers, most formatters, linters, and compilers are intentionally environment-dependent. Install only the tools needed by the projects you work on; they do not all need to exist globally. Shell formatting is the exception: Mason installs a pinned `shfmt` globally for Bash and POSIX shell buffers.

Mason automatically ensures the lightweight editor-side `vtsls` and `eslint-lsp` wrappers when Node/npm are available, plus the global `shfmt` shell formatter. The project/dev environment still owns `typescript`, `eslint`, Prettier, plugins, configs, and their versions.

The Mason tool versions are pinned in `config.settings` for reproducible clean installs. Normal startup installs only missing tools and never silently changes an installed version; use `:ConfigSyncMason` (or `<leader>lM`) when you intentionally want to reconcile them to the configured pins.

## Clean install

This removes the complete default Neovim profile: configuration, plugins, Mason packages, parsers, state, undo/history, and cache.

```sh
rm -rf -- \
  "${XDG_CONFIG_HOME:-$HOME/.config}/nvim" \
  "${XDG_DATA_HOME:-$HOME/.local/share}/nvim" \
  "${XDG_STATE_HOME:-$HOME/.local/state}/nvim" \
  "${XDG_CACHE_HOME:-$HOME/.cache}/nvim"
```

The full archive contains a top-level `nvim/` directory. Extract it into your config home:

```sh
config_home="${XDG_CONFIG_HOME:-$HOME/.config}"
mkdir -p "$config_home"
tar -xzf nvim-config.tar.gz -C "$config_home"
nvim
```

Missing Treesitter parsers install automatically on first start (when the
`tree-sitter` CLI is present). After plugin installation, verify with:

```vim
:ConfigInstallParsers  " only needed to force a re-scan
:Mason
:checkhealth
:checkhealth config
```

Keep and commit the included `lazy-lock.json`. Update it intentionally with `:Lazy update`.

## Keymap standard

`<leader>` is Space. Leader mappings are organized by stable namespaces:

- `b`: buffers
- `c`: code, formatting, TypeScript, ESLint
- `d`: diagnostics
- `f`: find/pickers
- `g`: Git
- `j`: Just
- `l`: LSP session/tooling
- `m`: Markdown
- `s`: search/symbols
- `t`: terminal
- `u`: UI/editor toggles

MiniClue makes those groups and useful native families discoverable. See **[KEYMAPS.md](KEYMAPS.md)** for the complete map.

Neovim 0.12 native functionality is kept where it is already good instead of being remapped for the sake of remapping. This includes the native `gr*` LSP family, `[d`/`]d`, quickfix/location/buffer bracket navigation, registers, marks, `z` commands, and `<C-w>` window commands.

## TypeScript / JavaScript

TypeScript is deliberately split into separate responsibilities:

- **VTSLS**: navigation, completion, type diagnostics, refactors, imports, source actions, inlay hints.
- **ESLint language server**: live lint diagnostics and current-buffer ESLint fix actions.
- **project-local `tsc`**: explicit non-emitting typecheck for ordinary configs, plus an explicit build-mode check for project-reference solutions.
- **project-local `eslint`**: explicit package/project lint and lint-fix.
- **Prettier through Conform**: formatting only when the current project/environment provides the actual Prettier CLI.

VTSLS prefers the workspace TypeScript SDK, updates imports when files move, prefers source definitions when possible, enables useful auto-import/function-call completion behavior, and supplies practical inlay hints without enabling every noisy hint.

TypeScript/JavaScript formatting is not delegated to VTSLS or ESLint. Prettier remains the formatting owner, so opening a project without Prettier does not silently switch formatting engines.

### TypeScript commands

- `:TypeScriptInfo`: show the resolved `tsconfig`, `tsc`, ESLint executable, and lint working directory.
- `:TypeScriptTypecheck`: run `tsc --noEmit -p` for an ordinary nearest config. It refuses project-reference solutions rather than pretending `tsc -b --noEmit` is safe.
- `:TypeScriptBuildCheck`: explicitly run `tsc -b` for a project-reference solution. Build mode can update configured outputs and `.tsbuildinfo`; results go to quickfix.
- `:TypeScriptLint`: run project-local `eslint . --format json`; results go to quickfix.
- `:TypeScriptLint!`: run the same lint with `--fix`.

Project JS tooling is resolved within the workspace boundary: Yarn Plug'n'Play uses `yarn exec` and `.yarn/sdks`, traditional installs search project/hoisted `node_modules/.bin`, then the current `PATH` is the fallback. Typecheck/lint use saved files and warn when any buffer under the project root is modified. Project ESLint fix refuses to start while project buffers have unsaved changes, then runs `:checktime` after fixes.

Important TypeScript mappings:

- `<leader>co`: organize imports
- `<leader>cs`: sort imports
- `<leader>cu`: remove unused imports
- `<leader>cU`: remove unused TypeScript code
- `<leader>cm`: add missing imports
- `<leader>cF`: TypeScript fix-all source action
- `<leader>ce`: ESLint fix current file
- `<leader>ct`: non-emitting project typecheck
- `<leader>cB`: explicit project-reference build check
- `<leader>cl`: project lint
- `<leader>cL`: project lint + fix
- `<leader>ci`: resolved project-tool info

## LSP and diagnostics

LSP servers are enabled only when their server executable is available in Neovim's current environment. This works naturally when Neovim is launched from `nix develop`, direnv, a container/dev shell, or any environment that prepares `PATH`.

The lint/type-diagnostic strategy is language-native rather than one generic duplicated pipeline:

- **TypeScript/JavaScript:** VTSLS type intelligence + ESLint LSP live linting; project-local `tsc` and ESLint CLI commands provide explicit whole-project checks.
- **Python:** ty for type analysis + Ruff for lint diagnostics/fixes/formatting when available.
- **Go:** gopls with `staticcheck`, `shadow`, and `unusedparams` analysis.
- **Rust:** rust-analyzer check diagnostics; if `cargo-clippy` is available when the config loads, rust-analyzer uses Clippy instead of plain `cargo check`.
- **C/C++:** clangd with background indexing and embedded clang-tidy diagnostics; project `.clang-tidy` configuration remains authoritative.
- **Shell:** bash-language-server; when `shellcheck` is available it is used automatically for stronger shell lint diagnostics.

C/C++ and Rust remain environment-dependent like the other language servers: make `clangd` or `rust-analyzer` available only where you need them.

After installing a server with Mason or changing Neovim's process `PATH`, run:

```vim
:ConfigRefreshLsp
```

LSP lifecycle mappings use Neovim 0.12's native config/client model. `<leader>le` / `<leader>ld` explicitly enable/disable a relevant configured LSP for the **session-wide** config state; `:ConfigRefreshLsp` preserves those manual disables. `<leader>lR` restarts clients for the current buffer, `<leader>lx` stops them, and `<leader>li` shows attached clients. `<leader>lM` explicitly reconciles the pinned Mason tools.

LSP document references highlight on `CursorHold` and clear as you move. TypeScript/JavaScript VTSLS attachments enable inlay hints by default; `<leader>ui` toggles them.

Core mappings:

- `gd`: definition
- `gD`: declaration
- `K`: hover
- `<leader>cI` / `<leader>cO`: incoming / outgoing call hierarchy
- native `gra`, `gri`, `grn`, `grr`, `grt`, `grx`, `gO`, and insert `<C-S>` remain available
- native `[d` / `]d`: diagnostic navigation
- `<leader>dd`: diagnostic float
- `<leader>dq`: diagnostics to quickfix
- `<leader>dl`: diagnostics to location list
- `]e` / `[e`: next / previous error
- `]w` / `[w`: next / previous warning

## Formatting

Format-on-save is disabled. Manual formatting is synchronous:

- `<leader>cf`: format buffer
- visual `<leader>cf`: format selection

Conform resolves formatter availability when formatting is requested. Bash and POSIX shell buffers use the globally Mason-managed `shfmt`. Project/environment-owned Prettier filetypes (JavaScript/TypeScript, HTML, CSS, JSON/JSONC/JSON5, YAML, and Markdown) use a project-aware Prettier resolver that supports local `node_modules`, Yarn Plug'n'Play via `yarn exec`, and `PATH` fallback. They intentionally do **not** silently fall back to LSP formatting when Prettier is absent. Other languages may use LSP formatting as a fallback when their external formatter is unavailable.

## Completion

Blink provides manual, non-preselected completion from LSP, path, and buffer sources. Signature help is enabled and automatically follows LSP trigger characters; `<C-k>` explicitly shows/hides it.

- `<C-Space>`: open completion/documentation
- `<C-n>` / `<C-p>`: select item
- `<C-y>`: accept
- `<C-e>`: close
- `<C-k>`: signature help
- `<Tab>` / `<S-Tab>`: snippet positions

No ghost text, AI candidates, command-line completion, terminal completion, or community snippet bundle is enabled. Completion is disabled automatically for large-file buffers.

## Search and navigation

Project-aware searches, explorers, and terminals use the nearest configured project marker. The set covers Git/Just, Python (`pyproject.toml`, `requirements.txt`), JS/TS (`package.json`, `tsconfig.json`, `jsconfig.json`, pnpm workspaces, Deno configs), Go (`go.mod`, `go.work`), Rust (`Cargo.toml`), and C/C++ (`.clangd`, compile databases/flags, CMake, Meson, Makefiles).

Useful entry points:

- `<leader>ff`: project files
- `<leader>fa`: FzfLua global files/buffers/symbols picker
- `<leader>fe` / `<leader>fE`: MiniFiles at current file / project root
- `<leader>/`: live grep project
- `<leader>sg`: live grep with glob filters
- visual `<leader>sw`: grep selected text
- `<leader>fk`: searchable keymaps
- `<leader>f:` / `<leader>f/`: command / search history
- `<leader>f"`: registers; `<leader>fu`: undo tree
- `<leader>fy` / `<leader>fY`: yank relative / absolute current-file path
- `<leader>fq` / `<leader>fl`: quickfix / location list
- `<leader>sf`: combined LSP locations
- `<leader>ss` / `<leader>sS`: document / workspace symbols

## Git

Git now lives consistently under `<leader>g`:

- `<leader>gg`: project LazyGit
- `<leader>gs`: status
- `<leader>gc` / `<leader>gC`: repository / current-buffer commits
- `<leader>gB`: branches
- `<leader>gf`: changed-files diff picker
- `<leader>gh`: hunks picker
- `<leader>gl`: reflog
- `<leader>gS`: stash
- `<leader>gt`: tags
- `<leader>gw`: worktrees
- `<leader>gp`: preview hunk
- `<leader>ga`: stage/unstage hunk or visual range
- `<leader>gr`: reset hunk or visual range
- `<leader>gA`: stage buffer
- `<leader>gb`: blame line
- `<leader>gd` / `<leader>gD`: diff against index / previous commit
- `[h` / `]h`: hunk navigation

Gitsigns does not attach to large-file buffers.

## Mini modules

The existing `mini.nvim` dependency now provides a broader coherent base without adding another plugin repository:

- `mini.ai`
- `mini.surround`
- `mini.pairs`
- `mini.splitjoin` (`gS`) for dot-repeatable argument split/join
- `mini.bufremove` for layout-preserving buffer deletion
- `mini.files` for LSP-aware create/rename/move/copy/delete filesystem work
- `mini.icons`
- `mini.trailspace`
- `mini.clue` for leader/native-key discoverability

MiniFiles opens with `<leader>fe` at the current file and `<leader>fE` at the project root. Its delete mode uses MiniFiles trash rather than permanent deletion. `<leader>ut` trims trailing whitespace and trailing blank lines explicitly; nothing auto-trims on save.

## Clipboard

Normal Vim register behavior is preserved while yanks are mirrored to the desktop clipboard:

- `y`, `yy`, visual yank, etc.: normal Neovim yank **and** system `+` clipboard
- `d`, `x`, and `c`: Neovim registers only
- `p` / `P`: normal Neovim registers
- `<leader>p` / `<leader>P`: system `+` clipboard

The config does not set `clipboard=unnamedplus`. Native Neovim clipboard providers handle Linux; install `wl-clipboard` for Wayland or `xclip`/`xsel` for X11. WSL keeps its explicit Windows clipboard bridge.

## Terminal

- `<C-\\>` / `<leader>tt`: project shell terminal
- `<leader>gg`: project LazyGit terminal
- `<Esc><Esc>`: leave terminal mode
- `<C-h/j/k/l>`: window navigation

Shell and LazyGit terminals are kept per project root.

## Markdown

Markview preview remains manual:

- `<leader>mp`: toggle in-buffer rendering
- `<leader>ms`: toggle split rendering

Markview refuses large buffers and Markdown files over 5,000 lines.

## Custom Just runner

- `<leader>jr`: choose a recipe through fzf-lua
- `<leader>ja`: recipe plus quoted arguments
- `<leader>jl`: logs
- `<leader>jc`: clear logs
- `<leader>jk`: stop task

The runner reconstructs partial stdout/stderr chunks, strips terminal escape sequences after reconstruction, highlights failures/warnings, caps retained log/extmark data, and handles stop/restart state safely.

## Large files

Files at least 1 MiB or 20,000 lines enter large-file mode. Swap and persistent undo are disabled for those buffers only. LSP activation/attachment, Treesitter, Blink completion, Conform formatting, Gitsigns, and Markview are prevented or detached as appropriate.

## Health

`:checkhealth config` treats project-specific LSP servers and formatters as environment information rather than global requirements. Missing project tools are informational. Core dependencies, incompatible versions, parser problems, and clipboard problems are reported separately.

Legacy Node/Perl/Python/Ruby remote-plugin providers are disabled because this configuration does not use them, avoiding meaningless provider-health warnings and unnecessary host-package installs. The config also keeps Neovim 0.12's builtin statusline instead of replacing it with a static one, preserving native diagnostic/progress/terminal status.

## Updates

1. Commit the config and `lazy-lock.json`.
2. Run `:Lazy update` intentionally.
3. Run `:TSUpdate`.
4. Run `:checkhealth` and `:checkhealth config`.
5. Test Lua, Python, TypeScript, Go, Markdown, formatting, diagnostics, clipboard, terminal, Git, and Just workflows.

Do not update automatically. Do not delete the lockfile after it is generated.
