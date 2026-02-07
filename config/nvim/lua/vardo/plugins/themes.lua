local function setTheme(color)
    vim.cmd.colorscheme(color)

    vim.api.nvim_set_hl(0, "Normal", { bg = "none" })
    vim.api.nvim_set_hl(0, "NormalFloat", { bg = "none" })
end

return {
    -- Gruvbox
    {
        "ellisonleao/gruvbox.nvim",
        priority = 1000,
        config = function()
            require("gruvbox").setup({
                transparent_mode = true,
            })
        end,
    },

    -- Tokyonight
    {
        "folke/tokyonight.nvim",
        priority = 1000,
        config = function()
            require("tokyonight").setup({
                style = "night",
                transparent = true,
            })
        end,
    },

    -- Catppuccin
    {
        "catppuccin/nvim",
        name = "catppuccin",
        priority = 1000,
        config = function()
            require("catppuccin").setup({
                transparent_background = true,
            })
        end,
    },

    -- Apply default theme once everything is ready
    {
        "nvim-lua/plenary.nvim",
        lazy = false,
        priority = 1001,
        config = function()
            setTheme("gruvbox")
        end,
    },
}

