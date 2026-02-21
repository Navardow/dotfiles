return function(capabilities)
    vim.lsp.config("clangd", {
        capabilities = vim.tbl_deep_extend("force", capabilities, {
            offsetEncoding = { "utf-16" },
        }),

        cmd = {
            "clangd",
            "--background-index",
            "--clang-tidy",
            "--header-insertion=iwyu",
            "--completion-style=detailed",
            "--function-arg-placeholders",
            "--fallback-style=llvm",
        },

        init_options = {
            usePlaceholders = true,
            completeUnimported = true,
            clangdFileStatus = true,
        },

        root_dir = require("lspconfig.util").root_pattern(
            "compile_commands.json",
            "compile_flags.txt",
            "configure.ac",
            "Makefile",
            "meson.build",
            "build.ninja",
            ".git"
        ),
    })
end
