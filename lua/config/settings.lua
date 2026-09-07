local M = {}

M.large_file = {
  bytes = 1024 * 1024,
  lines = 20000,
}

M.treesitter = {
  parsers = {
    "bash",
    "c",
    "cpp",
    "css",
    "go",
    "html",
    "javascript",
    "jsdoc",
    "json",
    "json5",
    "lua",
    "markdown",
    "markdown_inline",
    "python",
    "rust",
    "toml",
    "tsx",
    "typescript",
    "vim",
    "vimdoc",
    "yaml",
  },
  filetypes = {
    "bash",
    "c",
    "cpp",
    "css",
    "go",
    "html",
    "javascript",
    "javascriptreact",
    "json",
    "json5",
    "jsonc",
    "lua",
    "markdown",
    "python",
    "rust",
    "sh",
    "toml",
    "typescript",
    "typescriptreact",
    "vim",
    "yaml",
  },
}

M.typescript = {
  -- Stronger cross-file diagnostics. Disable on extremely large monorepos if
  -- the TypeScript server becomes too expensive.
  project_diagnostics = true,
}

-- Single source of truth for the filetype groups the config keys behaviour off
-- of, so the lists in autocmds/formatting/typescript no longer drift apart.
M.filetypes = {
  -- Prettier owns formatting for these; Conform must not fall back to an LSP.
  prettier = {
    "javascript",
    "javascriptreact",
    "typescript",
    "typescriptreact",
    "html",
    "css",
    "json",
    "json5",
    "jsonc",
    "yaml",
    "markdown",
  },
  -- TypeScript/JavaScript project tooling: tsc, eslint, vtsls source actions.
  typescript = {
    "javascript",
    "javascriptreact",
    "typescript",
    "typescriptreact",
  },
  -- Two-space indent overrides for web/markup/config buffers.
  two_space_indent = {
    "lua",
    "javascript",
    "javascriptreact",
    "typescript",
    "typescriptreact",
    "json",
    "json5",
    "jsonc",
    "yaml",
    "html",
    "css",
  },
}

M.mason = {
  -- Stable editor-side tools. Project-specific TypeScript, ESLint, and
  -- Prettier versions remain project/environment-owned.
  ensure_installed = {
    { name = "vtsls", version = "0.3.0", requires = { "node", "npm" } },
    { name = "eslint-lsp", version = "4.10.0", requires = { "node", "npm" } },
    { name = "shfmt", version = "v3.13.1" },
  },
}

M.lsp = {
  servers = {
    "bashls",
    "clangd",
    "cssls",
    "eslint",
    "gopls",
    "html",
    "jsonls",
    "lua_ls",
    "marksman",
    "ruff",
    "rust_analyzer",
    "ty",
    "vtsls",
    "yamlls",
  },
  executables = {
    bashls = "bash-language-server",
    clangd = "clangd",
    cssls = "vscode-css-language-server",
    eslint = "vscode-eslint-language-server",
    gopls = "gopls",
    html = "vscode-html-language-server",
    jsonls = "vscode-json-language-server",
    lua_ls = "lua-language-server",
    marksman = "marksman",
    ruff = "ruff",
    rust_analyzer = "rust-analyzer",
    ty = "ty",
    vtsls = "vtsls",
    yamlls = "yaml-language-server",
  },
}

M.formatting = {
  executables = {
    "stylua",
    "ruff",
    "goimports",
    "gofumpt",
    "prettier",
    "shfmt",
    "taplo",
    "rustfmt",
    "clang-format",
  },
}

M.just = {
  log_height = 12,
  max_log_lines = 5000,
}

return M
