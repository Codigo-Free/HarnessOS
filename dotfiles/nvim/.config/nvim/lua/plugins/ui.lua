-- HarnessOS — UI Plugins
return {
    -- Tokyo Night theme
    {
        "folke/tokyonight.nvim",
        lazy = false,
        priority = 1000,
        opts = {
            style = "night",
            transparent = false,
            terminal_colors = true,
            styles = {
                sidebars = "dark",
                floats = "dark",
            },
        },
        config = function(_, opts)
            require("tokyonight").setup(opts)
            vim.cmd("colorscheme tokyonight-night")
        end,
    },

    -- Status line
    {
        "nvim-lualine/lualine.nvim",
        event = "VeryLazy",
        dependencies = { "nvim-tree/nvim-web-devicons" },
        opts = {
            options = {
                theme = "tokyonight",
                component_separators = "|",
                section_separators = { left = "", right = "" },
                globalstatus = true,
            },
            sections = {
                lualine_a = { "mode" },
                lualine_b = { "branch", "diff", "diagnostics" },
                lualine_c = { { "filename", path = 1 } },
                lualine_x = { "filetype" },
                lualine_y = { "progress" },
                lualine_z = { "location" },
            },
        },
    },

    -- File tree
    {
        "nvim-tree/nvim-tree.lua",
        cmd = "NvimTreeToggle",
        dependencies = { "nvim-tree/nvim-web-devicons" },
        opts = {
            view = { width = 30 },
            renderer = { group_empty = true },
            filters = { dotfiles = false },
        },
    },

    -- Fuzzy finder
    {
        "nvim-telescope/telescope.nvim",
        cmd = "Telescope",
        dependencies = {
            "nvim-lua/plenary.nvim",
            { "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
        },
        opts = {
            defaults = {
                file_ignore_patterns = { "node_modules", ".git/", "dist/", ".venv/" },
                layout_strategy = "horizontal",
                sorting_strategy = "ascending",
            },
        },
    },

    -- Which key
    {
        "folke/which-key.nvim",
        event = "VeryLazy",
        opts = { plugins = { spelling = true } },
    },

    -- Notifications
    {
        "rcarriga/nvim-notify",
        opts = {
            timeout = 2000,
            max_height = function() return math.floor(vim.o.lines * 0.75) end,
            max_width  = function() return math.floor(vim.o.columns * 0.75) end,
        },
    },

    -- Indent guides
    {
        "lukas-reineke/indent-blankline.nvim",
        main = "ibl",
        event = "BufReadPost",
        opts = {},
    },
}
