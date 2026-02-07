local lspconfig = require("lspconfig")

local capabilities = vim.tbl_deep_extend(
  "force",
  {},
  vim.lsp.protocol.make_client_capabilities(),
  require("blink.cmp").get_lsp_capabilities()
)

local handlers = {}

-- default handler
handlers[1] = function(server_name)
  lspconfig[server_name].setup({
    capabilities = capabilities,
  })
end

-- custom servers
handlers.lua_ls = require("vardo.plugins.lsp.servers.lua_ls")(capabilities)
handlers.tailwindcss = require("vardo.plugins.lsp.servers.tailwindcss")(capabilities)
handlers.astro = require("vardo.plugins.lsp.servers.astro")(capabilities)
handlers.clangd = require("vardo.plugins.lsp.servers.clangd")(capabilities)


return handlers

