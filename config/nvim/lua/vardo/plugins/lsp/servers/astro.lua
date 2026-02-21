return function(capabilities)
    vim.lsp.config("astro", {
        cmd = { "astro-language-server" },
        capabilities = capabilities,
        filetypes = { "astro" },
    })
end
