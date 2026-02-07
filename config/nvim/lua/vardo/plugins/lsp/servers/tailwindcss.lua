return function(capabilities)
  return function()
    require("lspconfig").tailwindcss.setup({
      capabilities = capabilities,
      filetypes = {
        "html",
        "css",
        "scss",
        "javascript",
        "javascriptreact",
        "typescript",
        "typescriptreact",
        "vue",
        "svelte",
        "heex",
      },
    })
  end
end

