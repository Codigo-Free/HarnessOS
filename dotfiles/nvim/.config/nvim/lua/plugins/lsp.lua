-- HarnessOS — LSP Configuration
return {
    -- Mason: LSP/linter/formatter installer
    {
        "williamboman/mason.nvim",
        cmd = "Mason",
        build = ":MasonUpdate",
        opts = {
            ui = { icons = { package_installed = "✓", package_pending = "➜", package_uninstalled = "✗" } },
        },
    },

    -- Mason + LSPConfig bridge
    {
        "williamboman/mason-lspconfig.nvim",
        event = "BufReadPre",
        dependencies = { "williamboman/mason.nvim" },
        opts = {
            ensure_installed = {
                "pyright",       -- Python
                "ts_ls",         -- TypeScript / JavaScript
                "html",          -- HTML
                "cssls",         -- CSS
                "jsonls",        -- JSON
                "lua_ls",        -- Lua
                "omnisharp",     -- C#
                "jdtls",         -- Java
                "intelephense",  -- PHP
                "dockerls",      -- Dockerfile
            },
            automatic_installation = true,
        },
    },

    -- nvim-lspconfig
    {
        "neovim/nvim-lspconfig",
        event = "BufReadPre",
        dependencies = {
            "williamboman/mason-lspconfig.nvim",
            "hrsh7th/cmp-nvim-lsp",
        },
        config = function()
            local lspconfig = require("lspconfig")
            local capabilities = require("cmp_nvim_lsp").default_capabilities()

            local on_attach = function(_, bufnr)
                local map = function(keys, func, desc)
                    vim.keymap.set("n", keys, func, { buffer = bufnr, desc = "LSP: " .. desc })
                end
                map("gd",         vim.lsp.buf.definition,       "Go to definition")
                map("gD",         vim.lsp.buf.declaration,      "Go to declaration")
                map("gr",         vim.lsp.buf.references,       "Go to references")
                map("gi",         vim.lsp.buf.implementation,   "Go to implementation")
                map("K",          vim.lsp.buf.hover,            "Hover docs")
                map("<leader>rn", vim.lsp.buf.rename,           "Rename symbol")
                map("<leader>ca", vim.lsp.buf.code_action,      "Code action")
                map("<leader>f",  vim.lsp.buf.format,           "Format file")
            end

            local servers = {
                "pyright", "ts_ls", "html", "cssls",
                "jsonls", "lua_ls", "dockerls", "intelephense",
            }

            for _, server in ipairs(servers) do
                lspconfig[server].setup({
                    capabilities = capabilities,
                    on_attach    = on_attach,
                })
            end

            -- Lua-specific setup
            lspconfig.lua_ls.setup({
                capabilities = capabilities,
                on_attach    = on_attach,
                settings     = { Lua = { diagnostics = { globals = { "vim" } } } },
            })
        end,
    },

    -- Autocompletion
    {
        "hrsh7th/nvim-cmp",
        event = "InsertEnter",
        dependencies = {
            "hrsh7th/cmp-nvim-lsp",
            "hrsh7th/cmp-buffer",
            "hrsh7th/cmp-path",
            "L3MON4D3/LuaSnip",
            "saadparwaiz1/cmp_luasnip",
            "rafamadriz/friendly-snippets",
        },
        config = function()
            local cmp    = require("cmp")
            local luasnip = require("luasnip")
            require("luasnip.loaders.from_vscode").lazy_load()

            cmp.setup({
                snippet = {
                    expand = function(args) luasnip.lsp_expand(args.body) end,
                },
                mapping = cmp.mapping.preset.insert({
                    ["<C-b>"]     = cmp.mapping.scroll_docs(-4),
                    ["<C-f>"]     = cmp.mapping.scroll_docs(4),
                    ["<C-Space>"] = cmp.mapping.complete(),
                    ["<C-e>"]     = cmp.mapping.abort(),
                    ["<CR>"]      = cmp.mapping.confirm({ select = false }),
                    ["<Tab>"]     = cmp.mapping(function(fallback)
                        if cmp.visible() then
                            cmp.select_next_item()
                        elseif luasnip.expand_or_jumpable() then
                            luasnip.expand_or_jump()
                        else
                            fallback()
                        end
                    end, { "i", "s" }),
                }),
                sources = cmp.config.sources({
                    { name = "copilot",   priority = 900 },
                    { name = "nvim_lsp",  priority = 800 },
                    { name = "luasnip",   priority = 700 },
                    { name = "buffer",    priority = 500 },
                    { name = "path",      priority = 400 },
                }),
            })
        end,
    },

    -- Diagnostics list
    {
        "folke/trouble.nvim",
        cmd  = { "Trouble", "TroubleToggle" },
        opts = { use_diagnostic_signs = true },
        keys = {
            { "<leader>xx", "<cmd>Trouble diagnostics toggle<cr>", desc = "Diagnostics" },
            { "<leader>xX", "<cmd>Trouble diagnostics toggle filter.buf=0<cr>", desc = "Buffer diagnostics" },
        },
    },
}
