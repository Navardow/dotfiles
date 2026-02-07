return function(capabilities)
  return function()
    require("lspconfig").astro.setup({
      capabilities = capabilities,
      filetypes = { "astro" },
    })
  end
end

