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

M.dev = {
  log_height = 12,
  max_log_lines = 5000,
}

return M
