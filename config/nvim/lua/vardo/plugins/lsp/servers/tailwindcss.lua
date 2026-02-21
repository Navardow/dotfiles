return function(capabilities)
    vim.lsp.config("tailwindcss", {
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
