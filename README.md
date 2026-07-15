# Neovim 0.12 configuration

A reliability-first Neovim configuration with Catppuccin Mocha, fzf-lua, Blink completion, native LSP, Mason, Treesitter, Conform, Gitsigns, Markview, ToggleTerm, and a custom Just runner.

## Theme

- `catppuccin/nvim`
- flavour: `mocha`
- opaque background
- restrained cursor-line, split, float, and statusline highlights

Catppuccin v2 uses the `catppuccin-nvim` colorscheme name.

## Requirements

Required:

- Neovim 0.12+
- Git
- fzf 0.36+
- ripgrep (`rg`)
- fd
- curl
- tar
- C compiler
- tree-sitter CLI 0.26.1+

Recommended:

- unzip
- just
- lazygit

## Clean install

This removes the complete default Neovim profile: configuration, plugins, Mason packages, parsers, state, undo/history, and cache.

```sh
rm -rf -- \
  "${XDG_CONFIG_HOME:-$HOME/.config}/nvim" \
  "${XDG_DATA_HOME:-$HOME/.local/share}/nvim" \
  "${XDG_STATE_HOME:-$HOME/.local/state}/nvim" \
  "${XDG_CACHE_HOME:-$HOME/.cache}/nvim"
```

It does not uninstall Neovim or system command-line tools.

Extract the archive into the home directory:

```sh
tar -xzf nvim-config.tar.gz -C "$HOME"
nvim
```

After the first plugin installation:

```vim
:ConfigInstallParsers
:Mason
:checkhealth
:checkhealth config
:checkhealth markview
```

Install only the language servers and formatters you use. Restart Neovim after installing Mason packages. The first successful plugin installation generates `lazy-lock.json`; commit it.

## Plugin stack

- `folke/lazy.nvim`
- `catppuccin/nvim`
- `ibhagwan/fzf-lua`
- `saghen/blink.cmp` v1
- `neovim/nvim-lspconfig`
- `mason-org/mason.nvim`
- `nvim-treesitter/nvim-treesitter` main
- `stevearc/conform.nvim`
- `lewis6991/gitsigns.nvim`
- `nvim-mini/mini.nvim`
- `OXY2DEV/markview.nvim` v28
- `akinsho/toggleterm.nvim` v2

No AI completion, AI chat, agent integration, DAP, test framework, database client, or REST client is included.

## Search

- `<leader><leader>` / `<leader>ff`: files
- `<leader>/`: live grep
- `<leader>fb`: buffers
- `<leader>fg`: Git files
- `<leader>fr`: recent files
- `<leader>ss`: document symbols
- `<leader>sS`: workspace symbols
- `<leader>sr`: resume the previous search

## Code and diagnostics

- `gd`: definition
- `gD`: declaration
- `K`: hover
- native `grn`, `gra`, `grr`, `gri`, and `gO` remain available
- `[d` / `]d`: previous/next diagnostic
- `<leader>e`: diagnostic float
- `<leader>dv`: toggle diagnostic virtual text
- `<leader>uh`: toggle inlay hints
- `<Space>f`: manually format the buffer or selected range

Format-on-save is disabled. Formatting runs only when requested with `<Space>f` or `:Format`. Supported filetypes include Lua, Python, Go, JavaScript/TypeScript, HTML, CSS, JSON/JSONC/JSON5, YAML, Markdown, TOML, Rust, Bash/sh, and C/C++.

## Completion

Blink handles deterministic completion from LSP, path, and buffer sources.

- `<C-Space>`: open completion
- `<C-n>` / `<C-p>`: select item
- `<C-y>`: accept
- `<C-e>`: close
- `<Tab>` / `<S-Tab>`: move through snippet positions

No ghost text, AI candidates, command-line completion, terminal completion, or community snippet bundle is enabled.

## Terminal

- `<C-\>`: shell terminal
- `<leader>gg`: LazyGit terminal
- `<Esc><Esc>`: leave terminal mode
- `<C-h/j/k/l>`: move between windows

## Markdown

Markview is loaded normally but preview is manual:

- `<leader>mp`: toggle in-buffer rendering
- `<leader>ms`: toggle split rendering

Rendering is disabled for large buffers and limited to 5,000 lines.

## Custom Just runner

- `<leader>jr`: choose a recipe through fzf-lua
- `<leader>ja`: enter a recipe and quoted arguments
- `<leader>jl`: show logs
- `<leader>jc`: clear logs
- `<leader>jk`: stop the active task

The runner finds the nearest Justfile, streams output, strips terminal escape sequences, highlights failures and warnings, and caps retained logs at 5,000 lines.

## Large files

Files at least 1 MiB or 20,000 lines enter large-file mode. Expensive LSP, Treesitter, formatting, and Markview behavior is limited or disabled. Swap and persistent undo are disabled for those buffers only.

## Updates

1. Commit the config and `lazy-lock.json`.
2. Run `:Lazy update`.
3. Run `:TSUpdate`.
4. Run `:checkhealth` and `:checkhealth config`.
5. Test Lua, Python, TypeScript, Go, Markdown, formatting, diagnostics, terminal, and Just workflows.

Do not update automatically. Do not delete the lockfile after it is generated.
