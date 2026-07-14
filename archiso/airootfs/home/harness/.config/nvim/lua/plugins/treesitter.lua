-- HarnessOS — Treesitter
return {
    {
        "nvim-treesitter/nvim-treesitter",
        build  = ":TSUpdate",
        event  = "BufReadPost",
        dependencies = { "nvim-treesitter/nvim-treesitter-textobjects" },
        opts   = {
            ensure_installed = {
                "bash", "c", "cmake", "comment", "cpp", "css", "dockerfile",
                "html", "java", "javascript", "json", "jsonc", "lua", "markdown",
                "markdown_inline", "php", "python", "rust", "sql", "toml",
                "tsx", "typescript", "vim", "vimdoc", "xml", "yaml",
            },
            auto_install   = true,
            highlight      = { enable = true },
            indent         = { enable = true },
            incremental_selection = {
                enable  = true,
                keymaps = {
                    init_selection    = "<C-space>",
                    node_incremental  = "<C-space>",
                    scope_incremental = false,
                    node_decremental  = "<bs>",
                },
            },
        },
        config = function(_, opts) require("nvim-treesitter.configs").setup(opts) end,
    },
}
