-- HarnessOS — GitHub Copilot Integration
return {
    {
        "zbirenbaum/copilot.lua",
        cmd   = "Copilot",
        event = "InsertEnter",
        opts  = {
            suggestion = {
                enabled     = true,
                auto_trigger = true,
                debounce    = 75,
                keymap = {
                    accept        = "<M-l>",
                    accept_word   = false,
                    accept_line   = false,
                    next          = "<M-]>",
                    prev          = "<M-[>",
                    dismiss       = "<C-]>",
                },
            },
            panel = { enabled = false },
            filetypes = {
                yaml        = false,
                help        = false,
                gitcommit   = false,
                gitrebase   = false,
                ["*"]       = true,
            },
        },
    },

    -- Copilot source for nvim-cmp
    {
        "zbirenbaum/copilot-cmp",
        event        = "InsertEnter",
        dependencies = { "zbirenbaum/copilot.lua" },
        config       = function() require("copilot_cmp").setup() end,
    },
}
