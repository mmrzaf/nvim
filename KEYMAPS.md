# Neovim keymap standard

`<leader>` is **Space**.

The standard is intentionally simple:

1. **Native Vim/Neovim grammar wins** for editing and navigation.
2. **Leader prefixes are workflows**, grouped by one stable namespace.
3. **No duplicate aliases** unless a fast-path key is materially better for daily use.
4. **Lowercase is the normal action; uppercase is the stronger/alternate form** when a pair exists.
5. Buffer-local language/plugin maps use the same namespaces and appear in MiniClue only where relevant.

| Prefix | Area |
|---|---|
| `<leader>b` | buffer lifecycle |
| `<leader>c` | code, formatting, language actions |
| `<leader>d` | diagnostics |
| `<leader>f` | files, history, pickers |
| `<leader>g` | Git |
| `<leader>j` | Just tasks |
| `<leader>l` | LSP session/tooling |
| `<leader>m` | Markdown |
| `<leader>s` | search and symbols |
| `<leader>t` | terminals |
| `<leader>u` | UI/config utilities |

MiniClue exposes these prefixes plus useful native `g`, `z`, `[`/`]`, register, mark, insert-completion, and `<C-w>` families. Use `<leader>fk` to search all mappings or `:ConfigKeymaps` / `<leader>uk` to open this guide.

## Core

| Key | Action |
|---|---|
| `<leader>w` | write current file |
| `<leader>W` | write all files |
| `<leader>q` | quit current window with confirmation |
| `<leader>Q` | quit Neovim with confirmation |
| `<leader>p` / `<leader>P` | paste after / before from system `+` clipboard |
| `<Esc>` | clear search highlight |
| `<C-h/j/k/l>` | move between windows |
| `<C-Up/Down/Left/Right>` | resize current window |

Normal yanks are mirrored to the desktop clipboard. Deletes, changes, and `x` stay in Neovim registers only.

## Editing and native navigation

| Key | Action |
|---|---|
| `n` / `N` | next / previous search result and center |
| `<C-d>` / `<C-u>` | half-page down / up and center |
| visual `<` / `>` | indent and keep selection |
| visual `J` / `K` | move selected lines down / up |
| `gS` | split/join bracketed arguments (`mini.splitjoin`) |

Useful native families intentionally remain canonical:

- `[b` / `]b`, `[B` / `]B`: listed buffers
- `[q` / `]q`, `[Q` / `]Q`: quickfix
- `[l` / `]l`, `[L` / `]L`: location list
- `[d` / `]d`, `[D` / `]D`: diagnostics
- `<C-^>`: alternate buffer
- `<C-w>...`: windows
- `gc`: comments
- registers (`"`), marks (`'` / `` ` ``), `z...`, and insert `<C-x>...`

`mini.ai` extends `a`/`i` text objects. `mini.surround` supplies `sa` add, `sd` delete, `sr` replace, `sf`/`sF` find, and `sh` highlight.

## Buffers — `<leader>b`

| Key | Action |
|---|---|
| `<leader>bd` | delete buffer while preserving window layout |
| `<leader>bD` | force-delete buffer |
| `<leader>bo` | delete other unmodified listed buffers |

Buffer navigation remains native `[b` / `]b`; alternate buffer remains native `<C-^>`.

## Code — `<leader>c`

Global:

| Key | Action |
|---|---|
| `<leader>cf` | format buffer / visual selection |
| `<leader>cI` / `<leader>cO` | incoming / outgoing call hierarchy |

Neovim 0.12 LSP grammar remains canonical:

| Key | Action |
|---|---|
| `gd` / `gD` | LSP definition/declaration when available, otherwise native Vim behavior |
| `K` | hover when LSP attached |
| `gra` | code action |
| `grn` | rename |
| `gri` | implementation |
| `grr` | references |
| `grt` | type definition |
| `grx` | CodeLens |
| `gO` | document symbols |
| insert `<C-S>` | signature help |

### TypeScript / JavaScript buffer-local code maps

| Key | Action |
|---|---|
| `<leader>ct` | non-emitting TypeScript typecheck for ordinary configs |
| `<leader>cB` | explicit TypeScript project-reference build check (`tsc -b`; may write configured outputs) |
| `<leader>cl` | project ESLint lint |
| `<leader>cL` | project ESLint lint + `--fix` |
| `<leader>ci` | resolved TypeScript/ESLint tooling info |
| `<leader>co` | organize imports (VTSLS) |
| `<leader>cs` | sort imports (VTSLS) |
| `<leader>cm` | add missing imports (VTSLS) |
| `<leader>cu` | remove unused imports (VTSLS) |
| `<leader>cU` | remove unused TypeScript code (VTSLS) |
| `<leader>cF` | TypeScript fix-all source action |
| `<leader>ce` | ESLint fix current file |

Commands: `:TypeScriptInfo`, `:TypeScriptTypecheck`, `:TypeScriptBuildCheck`, `:TypeScriptLint`, `:TypeScriptLint!`.

Project checks use files on disk and warn about modified buffers under the project root. `:TypeScriptTypecheck` refuses solution configs with project references because a complete non-emitting CLI check is not supported by TypeScript; use the explicit build-check command instead. ESLint `--fix` refuses to run while project buffers are modified.

## LSP session/tooling — `<leader>l`

| Key | Action |
|---|---|
| `<leader>li` | clients attached to current buffer |
| `<leader>ll` | LSP log |
| `<leader>lh` | LSP health |
| `<leader>lm` | Mason UI |
| `<leader>lM` | explicitly synchronize pinned Mason wrappers |
| `<leader>lr` | re-scan current environment and refresh configured LSPs |
| `<leader>lR` | restart clients attached to current buffer |
| `<leader>le` | enable a relevant configured LSP for this session **globally** |
| `<leader>ld` | disable a relevant configured LSP for this session **globally** |
| `<leader>lx` | stop clients attached to current buffer |

`le`/`ld` change Neovim's session-wide enabled state for that LSP configuration. `ConfigRefreshLsp` respects manual session disables.

## Diagnostics — `<leader>d`

| Key | Action |
|---|---|
| `<leader>dd` | diagnostic float |
| `<leader>dl` | diagnostics to location list |
| `<leader>dq` | diagnostics to quickfix |
| `<leader>dv` | toggle diagnostic virtual text |
| `<leader>dV` | toggle current-line virtual lines |
| `<leader>du` | toggle diagnostic underline |
| `<leader>dx` | toggle diagnostics for current buffer |
| `<leader>dX` | toggle diagnostics globally |
| `]e` / `[e` | next / previous error |
| `]w` / `[w` | next / previous warning |

Generic diagnostic movement remains native `[d` / `]d`.

## Files / inspect — `<leader>f`

| Key | Action |
|---|---|
| `<leader>fa` | FzfLua global picker |
| `<leader>ff` | project files |
| `<leader>fg` | Git files |
| `<leader>fe` | MiniFiles at current file |
| `<leader>fE` | MiniFiles at project root |
| `<leader>fb` | buffers |
| `<leader>fr` | recent files |
| `<leader>fH` | file/buffer history |
| `<leader>fh` | help |
| `<leader>fk` | keymaps |
| `<leader>fc` | commands |
| `<leader>f:` | command history |
| `<leader>f/` | search history |
| `<leader>f"` | registers |
| `<leader>fm` | marks |
| `<leader>fj` | jumplist |
| `<leader>fC` | change list |
| `<leader>fu` | undo tree |
| `<leader>ft` | tabs |
| `<leader>fq` | quickfix entries |
| `<leader>fl` | location-list entries |
| `<leader>fR` | resume last picker |
| `<leader>fy` / `<leader>fY` | yank relative / absolute file path |

MiniFiles is the filesystem editor; FzfLua is the finder. Inside MiniFiles use `g?` for its complete local keymap help and `=` to synchronize filesystem edits.

## Search / symbols — `<leader>s`

| Key | Action |
|---|---|
| `<leader>/` | live grep project (fast path) |
| `<leader>sg` | live grep with glob filters |
| `<leader>sw` | search word; Visual mode searches selection |
| `<leader>sW` | search WORD |
| `<leader>sb` | search current buffer |
| `<leader>sl` | search lines across open buffers |
| `<leader>sd` / `<leader>sD` | buffer / workspace diagnostics picker |
| `<leader>sf` | combined LSP locations finder |
| `<leader>ss` / `<leader>sS` | document / workspace symbols |

Resume is a general picker operation and therefore lives only at `<leader>fR`.

## Git — `<leader>g`

| Key | Action |
|---|---|
| `<leader>gg` | project LazyGit |
| `<leader>gs` | status picker |
| `<leader>gc` / `<leader>gC` | repository / buffer commits |
| `<leader>gB` | branches |
| `<leader>gf` | changed-files diff picker |
| `<leader>gh` | hunks picker |
| `<leader>gl` | reflog |
| `<leader>gS` | stash |
| `<leader>gt` | tags |
| `<leader>gw` | worktrees |
| `<leader>gp` | preview hunk |
| `<leader>ga` | stage/unstage hunk or visual range |
| `<leader>gr` | reset hunk or visual range |
| `<leader>gA` | stage buffer |
| `<leader>gb` | full blame for line |
| `<leader>gd` / `<leader>gD` | diff against index / previous commit |
| `[h` / `]h` | previous / next hunk |
| `[H` / `]H` | previous / next staged hunk |
| `ih` | hunk text object |

## Just — `<leader>j`

| Key | Action |
|---|---|
| `<leader>jr` | choose recipe |
| `<leader>ja` | choose recipe + quoted arguments |
| `<leader>jl` | logs |
| `<leader>jc` | clear logs |
| `<leader>jk` | stop active task |

## Terminal — `<leader>t`

| Key | Action |
|---|---|
| `<leader>tt` | toggle shell for current project |
| `<C-\>` | fast-path toggle project shell |
| terminal `<C-\>` | toggle the exact terminal currently open |
| terminal `<Esc><Esc>` | leave terminal mode |
| terminal `<C-h/j/k/l>` | move to another window |

LazyGit belongs to Git and stays at `<leader>gg`. Shell/LazyGit terminals are cached per project root.

## Markdown — `<leader>m`

| Key | Action |
|---|---|
| `<leader>mp` | toggle in-buffer Markview preview |
| `<leader>ms` | toggle Markview split preview |

These mappings exist only in Markdown buffers.

## UI / config — `<leader>u`

| Key | Action |
|---|---|
| `<leader>ui` | toggle LSP inlay hints |
| `<leader>uw` | toggle wrap |
| `<leader>us` | toggle spell |
| `<leader>ul` | toggle list characters |
| `<leader>un` | toggle absolute line numbers |
| `<leader>ur` | toggle relative line numbers |
| `<leader>uc` | toggle cursor line |
| `<leader>ut` | trim trailing whitespace/final blank lines |
| `<leader>uh` | config health |
| `<leader>uH` | all health checks |
| `<leader>uk` | open this guide |
| `<leader>up` | Lazy plugin manager |

## Completion

| Key | Action |
|---|---|
| `<C-Space>` | show completion / documentation |
| `<C-n>` / `<C-p>` | next / previous completion |
| `<C-y>` | accept |
| `<C-e>` | close |
| `<C-k>` | show/hide signature help |
| `<Tab>` / `<S-Tab>` | next / previous snippet position |
| `<C-f>` / `<C-b>` | scroll documentation |

Completion is non-preselected, has no ghost text, and is disabled for large-file buffers.
