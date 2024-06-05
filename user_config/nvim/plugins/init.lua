return {
  {
    "wakatime/vim-wakatime",
    lazy = false,
  },

  {
  	"nvim-treesitter/nvim-treesitter",
  	opts = {
  		ensure_installed = { "asm", "awk", "bash", "c", "c_sharp", "cmake", "cpp", "css", "go", "haskell", "html", "json", "javascript", "lua", "luadoc", "make", "markdown", "php", "phpdoc", "python", "ruby", "rust", "sql", "toml", "tsx", "typescript", "xml", "yaml", "vim", "vimdoc" },
  	},
  },

  {
    "stevearc/conform.nvim",
    event = 'BufWritePre',
    config = function()
      require "configs.conform"
    end,
  },

  {
    "neovim/nvim-lspconfig",
    config = function()
      require("nvchad.configs.lspconfig").defaults()
      require "configs.lspconfig"
    end,
  },

  {
  	"williamboman/mason.nvim",
  	opts = {
  		ensure_installed = {
  			"angular-language-server", "asm-lsp", "ansible-language-server", "ansible-lint", "lua-language-server", "ltex-ls", "markdown-oxide", "stylua", "html-lsp", "css-lsp", "prettier", "typescript-language-server", "csharp-language-server", "haskell-language-server", "java-language-server", "tailwindcss-language-server", "yaml-language-server", "standardjs", "ast-grep", "html-lsp"
  		},
  	},
  },
}
