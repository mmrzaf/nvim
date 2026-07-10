return {
  {
    "mason-org/mason.nvim",
    lazy = false,
    config = function()
      require("mason").setup({
        PATH = "prepend",
        ui = {
          border = "rounded",
        },
      })
    end,
  },
}
