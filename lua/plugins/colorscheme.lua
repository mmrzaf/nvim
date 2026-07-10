return {
  {
    "catppuccin/nvim",
    name = "catppuccin",
    version = "2.*",
    lazy = false,
    priority = 1000,
    config = function()
      require("catppuccin").setup({
        flavour = "mocha",
        background = {
          light = "latte",
          dark = "mocha",
        },
        transparent_background = false,
        term_colors = false,
        no_italic = false,
        no_bold = false,
        no_underline = false,
        styles = {
          comments = { "italic" },
          conditionals = { "italic" },
        },
        float = {
          transparent = false,
          solid = false,
        },
        dim_inactive = {
          enabled = false,
        },
        default_integrations = false,
        auto_integrations = false,
        integrations = {
          blink_cmp = { style = "bordered" },
          fzf = true,
          gitsigns = true,
          markview = true,
          mason = true,
          mini = { enabled = true },
        },
        custom_highlights = function(colors)
          return {
            Normal = { bg = colors.base },
            NormalNC = { bg = colors.base },
            NormalFloat = { bg = colors.mantle },
            FloatBorder = { fg = colors.surface2, bg = colors.mantle },
            FloatTitle = { fg = colors.text, bg = colors.mantle },
            WinSeparator = { fg = colors.surface1 },
            StatusLine = { bg = colors.mantle },
            StatusLineNC = { bg = colors.mantle },
            CursorLine = { bg = colors.surface0 },
          }
        end,
      })

      vim.cmd.colorscheme("catppuccin-nvim")
    end,
  },
}
