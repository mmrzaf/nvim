return {
	{ "mason-org/mason.nvim", build = ":MasonUpdate", config = true, lazy = false,
		cmd = { "Mason", "MasonInstall", "MasonUpdate" } },
	{ "mason-org/mason-lspconfig.nvim", dependencies = { "mason-org/mason.nvim" }, event = "VeryLazy" },

  {
    "WhoIsSethDaniel/mason-tool-installer.nvim",
    lazy = false,
    dependencies = { "mason-org/mason.nvim" },
    config = function()
      require("mason-tool-installer").setup({
        run_on_start = true,
        start_delay = 150,
        -- auto_update = false,
        ensure_installed = {
          -- LSP serverskage names)
          "lua-language-server",
          "basedpyright",
          "ruff",
          "vtsls",
          "gopls",
          "bash-language-server",
          "json-lsp",
          "yaml-language-server",
          "eslint-lsp",
          --"jdtls",
          --"kotlin-language-server",
          "rust-analyzer",
          "clangd",

          -- formatters
          "stylua",
          "biome",
          "prettierd",
          "jq",
          "gofumpt",
          "goimports",
          "google-java-format",
          "ktlint",
	  "ktfmt",
          "rustfmt",
          "clang-format",
          "shfmt",

          -- linters/others
          "ruff",
          "golangci-lint",
          "eslint_d",
          "stylelint",
        },
      })
    end,
  }
}

