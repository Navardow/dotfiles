return {
  "neovim/nvim-lspconfig",
  dependencies = {
    "williamboman/mason.nvim",
    "williamboman/mason-lspconfig.nvim",
    "j-hui/fidget.nvim",
    "saghen/blink.cmp",
  },
  config = function()
    require("vardo.plugins.lsp.diagnostics")
    require("vardo.plugins.lsp.mason") -- ← mason-lspconfig is required THERE
  end,
}

