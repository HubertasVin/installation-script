-- EXAMPLE 
local on_attach = require("nvchad.configs.lspconfig").on_attach
local on_init = require("nvchad.configs.lspconfig").on_init
local capabilities = require("nvchad.configs.lspconfig").capabilities

local lspconfig = require "lspconfig"
local servers = { "html", "cssls", "angularls", "tsserver" }

-- lsps with default config
for _, lsp in ipairs(servers) do
  lspconfig[lsp].setup {
    on_attach = on_attach,
    on_init = on_init,
    capabilities = capabilities,
  }
end

lspconfig.tsserver.setup {
  on_attach = function(client, bufnr)
    -- Disable tsserver formatting in favor of eslint
    client.resolved_capabilities.document_formatting = false
    on_attach(client, bufnr)
  end,
  on_init = on_init,
  capabilities = capabilities,
  filetypes = { "typescript", "typescriptreact", "javascript", "javascriptreact" },
  cmd = { "typescript-language-server", "--stdio" },
}

lspconfig.eslint.setup {
  on_attach = on_attach,
  on_init = on_init,
  capabilities = capabilities,
  filetypes = { "javascript", "javascriptreact", "typescript", "typescriptreact" },
  cmd = { "vscode-eslint-language-server", "--stdio" }, -- Replace with full path if needed
}

lspconfig.html.setup {
  on_attach = on_attach,
  on_init = on_init,
  capabilities = capabilities,
  filetypes = { "html", "typescriptreact", "javascriptreact" },
  cmd = { "vscode-html-language-server", "--stdio" },
}
