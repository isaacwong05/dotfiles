return {
  -- colorscheme plugins
  { "catppuccin/nvim", name = "catppuccin", lazy = true },
  { "ellisonleao/gruvbox.nvim", lazy = true },
  { "gbprod/nord.nvim", lazy = true },
  { "aktersnurra/no-clown-fiesta.nvim", lazy = true },
  { "e-ink-colorscheme/e-ink.nvim", lazy = true },
  { "rose-pine/neovim", name = "rose-pine", lazy = true },
  { "rebelot/kanagawa.nvim", lazy = true },
  { "neanias/everforest-nvim", lazy = true },
  { "Mofiqul/dracula.nvim", lazy = true },
  { "nyoom-engineering/oxocarbon.nvim", lazy = true },
  { "rktjmp/lush.nvim", lazy = true }, -- required by zenbones
  { "mcchrish/zenbones.nvim", dependencies = "rktjmp/lush.nvim", lazy = true },

  {
    "zaldih/themery.nvim",
    lazy = false,
    priority = 1000,
    config = function()
      require("themery").setup({
        themes = {
          "tokyonight",
          "tokyonight-storm",
          "tokyonight-moon",
          "tokyonight-day",

          { name = "Catppuccin Mocha", colorscheme = "catppuccin-mocha" },
          { name = "Catppuccin Macchiato", colorscheme = "catppuccin-macchiato" },
          { name = "Catppuccin Latte", colorscheme = "catppuccin-latte" },

          {
            name = "Gruvbox Dark",
            colorscheme = "gruvbox",
            before = [[ vim.opt.background = "dark" ]],
          },
          {
            name = "Gruvbox Light",
            colorscheme = "gruvbox",
            before = [[ vim.opt.background = "light" ]],
          },

          "nord",

          { name = "Rose Pine Main", colorscheme = "rose-pine-main" },
          { name = "Rose Pine Moon", colorscheme = "rose-pine-moon" },
          { name = "Rose Pine Dawn", colorscheme = "rose-pine-dawn" },

          { name = "Kanagawa Wave", colorscheme = "kanagawa-wave" },
          { name = "Kanagawa Dragon", colorscheme = "kanagawa-dragon" },
          { name = "Kanagawa Lotus", colorscheme = "kanagawa-lotus" },

          { name = "Everforest Soft", colorscheme = "everforest" },

          "dracula",

          { name = "Oxocarbon Dark", colorscheme = "oxocarbon", before = [[ vim.opt.background = "dark" ]] },
          { name = "Oxocarbon Light", colorscheme = "oxocarbon", before = [[ vim.opt.background = "light" ]] },

          -- monochrome / grayscale
          "no-clown-fiesta",
          { name = "E-ink Dark", colorscheme = "e-ink", before = [[ vim.opt.background = "dark" ]] },
          { name = "E-ink Light", colorscheme = "e-ink", before = [[ vim.opt.background = "light" ]] },
          { name = "Zenwritten Dark", colorscheme = "zenwritten", before = [[ vim.opt.background = "dark" ]] },
          { name = "Zenwritten Light", colorscheme = "zenwritten", before = [[ vim.opt.background = "light" ]] },

          "habamax",
        },
        livePreview = true,
      })
    end,
  },
}
