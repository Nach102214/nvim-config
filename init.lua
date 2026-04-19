-- 1. Установка менеджера плагинов Lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim",
    "--branch=main",
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)


-- 2. Список плагинов (Lazy)
require("lazy").setup({
  { "catppuccin/nvim", name = "catppuccin", priority = 1000, lazy = false },
  { "nvim-tree/nvim-tree.lua", dependencies = { "nvim-tree/nvim-web-devicons" } },
  { "nvim-lualine/lualine.nvim", event = "VeryLazy", dependencies = { "nvim-tree/nvim-web-devicons", "catppuccin" } },
  { "nvim-treesitter/nvim-treesitter", build = ":TSUpdate" },
  { "nvim-telescope/telescope.nvim", branch = "0.1.x", dependencies = { "nvim-lua/plenary.nvim" } },
  { "neovim/nvim-lspconfig" },
  { "williamboman/mason.nvim" },
  { "williamboman/mason-lspconfig.nvim" },
  { "hrsh7th/nvim-cmp" },
  { "hrsh7th/cmp-nvim-lsp" },
  { "hrsh7th/cmp-buffer" },
  { "hrsh7th/cmp-path" },
  { "L3MON4D3/LuaSnip" },
  { "saadparwaiz1/cmp_luasnip" },
  { "mfussenegger/nvim-dap" },
  { "rcarriga/nvim-dap-ui", dependencies = { "mfussenegger/nvim-dap", "nvim-neotest/nvim-nio" } },
  { "nvim-neotest/nvim-nio" },
  { 'akinsho/bufferline.nvim', version = "*", dependencies = 'nvim-tree/nvim-web-devicons' },
  {
    "Exafunction/codeium.nvim",
    dependencies = { "nvim-lua/plenary.nvim", "hrsh7th/nvim-cmp" }
  },
  -- ПЕРЕВОДЧИК
  {
    "voldikss/vim-translator",
    init = function()
        vim.cmd([[
            let g:translator_default_engines = ['google']
            let g:translator_default_target_lang = 'ru'
            let g:translator_source_lang = 'auto'
        ]])
    end
  },
}, { track = 'branch' }) -- ВОТ ЗДЕСЬ БЫЛА ОШИБКА (пропущена закрывающая скобка)

-- --- ОСНОВНЫЕ НАСТРОЙКИ ---
vim.g.mapleader = " "
vim.opt.termguicolors = true
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.mouse = 'a'
vim.opt.expandtab = true
vim.opt.tabstop = 4
vim.opt.shiftwidth = 4
vim.opt.colorcolumn = "79,88,120"
vim.api.nvim_set_hl(0, 'ColorColumn', { ctermbg=0, bg='#333333' })

-- --- НАСТРОЙКА ПЛАГИНОВ ---

-- Тема
local ok_cat, catppuccin = pcall(require, "catppuccin")
if ok_cat then vim.cmd.colorscheme("catppuccin-mocha") end

-- LSP (с исправлением Deprecated ошибки)
local ok_lsp, mason_lsp = pcall(require, "mason-lspconfig")
if ok_lsp then
    require("mason").setup()
    mason_lsp.setup({
        ensure_installed = { "pyright", "ruff", "bashls" },
        automatic_installation = true,
    })
    
    if vim.lsp.enable then
        vim.lsp.enable('pyright')
        vim.lsp.enable('ruff')
        vim.lsp.enable('bashls')
    else
        local lspconfig = require('lspconfig')
        lspconfig.pyright.setup({})
        lspconfig.ruff.setup({})
        lspconfig.bashls.setup({})
    end
end

-- Lualine
local ok_lua, lualine = pcall(require, "lualine")
if ok_lua then
    lualine.setup({ options = { globalstatus = true, theme = "auto" } })
end

-- Keymaps
local function map(mode, lhs, rhs, desc)
   vim.keymap.set(mode, lhs, rhs, { silent = true, desc = desc })
end

map('n', '<leader>e', ':NvimTreeToggle<CR>', 'Explorer')
map('n', '<leader>ff', ':Telescope find_files<CR>', 'Find Files')
map('n', '<leader>w', ':w<CR>', 'Save')
map('n', '<leader>q', ':q<CR>', 'Quit')
map('n', '<Tab>', ':bnext<CR>', 'Next Buffer')
map('n', '<S-Tab>', ':bprevious<CR>', 'Prev Buffer')

-- ГОРЯЧИЕ КЛАВИШИ ПЕРЕВОДЧИКА
map('n', '<leader>t', ':TranslateW --target_lang=ru<CR>', 'Translate to RU')
map('v', '<leader>t', ':TranslateW --target_lang=ru<CR>', 'Translate to RU')
map('n', '<leader>f', ':TranslateW --target_lang=en<CR>', 'Translate to EN')
map('v', '<leader>f', ':TranslateW --target_lang=en<CR>', 'Translate to EN')
map('v', '<leader>r', ':TranslateR --target_lang=en<CR>', 'Replace with EN')

-- НАСТРОЙКА DAP
local ok_dap, dap = pcall(require, "dap")
if ok_dap then
    local ok_ui, dapui = pcall(require, "dapui")
    if ok_ui then dapui.setup() end
    dap.adapters.python = {
        type = 'executable',
        command = '/usr/bin/python3',
        args = { '-m', 'debugpy.adapter' },
    }
end


