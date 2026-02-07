local mason_lspconfig = require("mason-lspconfig")
local handlers = require("vardo.plugins.lsp.handlers")

require("mason").setup()
require("fidget").setup({})

mason_lspconfig.setup({
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
	automatic_enable = {
		exclude = { "jdtls" },
	},
	handlers = handlers,
})
