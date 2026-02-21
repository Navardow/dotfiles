return {
    "neovim/nvim-lspconfig",
    dependencies = {
        "williamboman/mason.nvim",
        "williamboman/mason-lspconfig.nvim",
        "j-hui/fidget.nvim",
        "saghen/blink.cmp",
    },

    config = function()
        local capabilities = vim.tbl_deep_extend(
            "force",
            {},
            vim.lsp.protocol.make_client_capabilities(),
            require("blink.cmp").get_lsp_capabilities()
        )

        require("fidget").setup({})
        require("mason").setup()
        require("mason-lspconfig").setup({
            ensure_installed = {
                "lua_ls",
                "rust_analyzer",
                "vtsls",
                "tailwindcss",
                "astro",
                "html",
                "cssls",
                "jdtls",
                "clangd",
            },
            handlers = {
                function(server_name)
                    vim.lsp.config(server_name, {
                        capabilities = capabilities,
                    })
                    vim.lsp.enable(server_name)
                end,

                -- custom lsp setups
                ["lua_ls"] = function()
                    require("vardo.plugins.lsp.servers.lua_ls")(capabilities)
                    vim.lsp.enable("lua_ls")
                end,

                ["tailwindcss"] = function()
                    require("vardo.plugins.lsp.servers.tailwindcss")(capabilities)
                    vim.lsp.enable("tailwindcss")
                end,

                ["astro"] = function()
                    require("vardo.plugins.lsp.servers.astro")(capabilities)
                    vim.lsp.enable("astro")
                end,

                ["clangd"] = function()
                    require("vardo.plugins.lsp.servers.clangd")(capabilities)
                    vim.lsp.enable("clangd")
                end

            }
        })

        -- diagnostics
        vim.diagnostic.config({
            virtual_text = {
                spacing = 4,
                prefix = "!",
            },
            signs = true,
            underline = true,
            update_in_insert = false,
            severity_sort = true,
            float = {
                focusable = false,
                style = "minimal",
                border = "rounded",
                source = "always",
                header = "",
                prefix = "",
            },
        })
    end,


}
