-- 1. Установка менеджера плагинов Lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com", -- Исправлен путь к репозиторию
    "--branch=stable",
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

-- 2. Список плагинов
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
  { "Exafunction/codeium.vim", event = "BufReadPre" },
  {
    "voldikss/vim-translator",
    init = function()
        vim.g.translator_default_engines = {'google'}
        vim.g.translator_default_target_lang = 'ru'
        vim.g.translator_source_lang = 'auto'
    end
  },
})

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
vim.opt.clipboard = "unnamedplus"

-- --- НАСТРОЙКА ПЛАГИНОВ ---

-- Тема
local ok_cat, catppuccin = pcall(require, "catppuccin")
if ok_cat then vim.cmd.colorscheme("catppuccin-mocha") end

-- NvimTree (Файловый менеджер)
local ok_tree, nvimtree = pcall(require, "nvim-tree")
if ok_tree then
    nvimtree.setup({
        sort_by = "case_sensitive",
        view = { width = 30 },
        renderer = { group_empty = true },
        filters = { dotfiles = false },
    })
end

-- Bufferline (Вкладки сверху)
local ok_buf, bufferline = pcall(require, "bufferline")
if ok_buf then
    bufferline.setup({})
end

-- LSP Настройки
local ok_mason, mason = pcall(require, "mason")
if ok_mason then
    mason.setup()
    local ok_mason_lsp, mason_lsp = pcall(require, "mason-lspconfig")
    if ok_mason_lsp then
        mason_lsp.setup({
            ensure_installed = { "pyright", "ruff", "bashls" },
            automatic_installation = true,
        })
    end
    
    local caps = require("cmp_nvim_lsp").default_capabilities()
    -- Исправление кодировки для устранения конфликта UTF-8 / UTF-16
    caps.offsetEncoding = { "utf-8" }

    for _, server in ipairs({ "pyright", "ruff", "bashls" }) do
        vim.lsp.config(server, { capabilities = caps })
        vim.lsp.enable(server)
    end
end

-- Автодополнение (Cmp)
local ok_cmp, cmp = pcall(require, "cmp")
if ok_cmp then
    cmp.setup({
        snippet = { expand = function(args) require('luasnip').lsp_expand(args.body) end },
        mapping = cmp.mapping.preset.insert({
            ['<C-b>'] = cmp.mapping.scroll_docs(-4),
            ['<C-f>'] = cmp.mapping.scroll_docs(4),
            ['<C-Space>'] = cmp.mapping.complete(),
            ['<CR>'] = cmp.mapping.confirm({ select = true }),
        }),
        sources = cmp.config.sources({
            { name = 'nvim_lsp' },
            { name = 'luasnip' },
        }, {
            { name = 'buffer' },
        })
    })
end

-- Lualine (Статус-бар)
local ok_lua, lualine = pcall(require, "lualine")
if ok_lua then
    lualine.setup({ options = { globalstatus = true, theme = "auto" } })
end

-- Treesitter (Подсветка синтаксиса)
local ok_ts, ts = pcall(require, "nvim-treesitter.configs")
if ok_ts then
    ts.setup({
        ensure_installed = { "python", "lua", "bash", "markdown", "markdown_inline", "vim", "vimdoc" },
        highlight = { enable = true },
    })
end

-- --- ГОРЯЧИЕ КЛАВИШИ ---
local function map(mode, lhs, rhs, desc)
    vim.keymap.set(mode, lhs, rhs, { silent = true, desc = desc })
end

-- Навигация и файлы
map("n", "<leader>e", ":NvimTreeToggle<CR>", "Проводник (Tree)")
map("n", "<leader>ff", ":Telescope find_files<CR>", "Поиск файлов")
map("n", "<Tab>", ":bnext<CR>", "Следующая вкладка")
map("n", "<S-Tab>", ":bprevious<CR>", "Предыдущая вкладка")
map("n", "<leader>w", ":w<CR>", "Сохранить")
map("n", "<leader>q", ":q<CR>", "Выход")
map("n", "<leader>fm", function() vim.lsp.buf.format({ async = true }) end, "Форматирование кода")

-- Переводчик (в визуальном режиме выделяете текст и жмете Space + t/f)
map("v", "<leader>t", ":TranslateW --target_lang=ru<CR>", "Перевод на RU (окно)")
map("v", "<leader>f", ":TranslateW --target_lang=en<CR>", "Перевод на EN (окно)")
map("v", "<leader>tr", ":TranslateR --target_lang=ru<CR>", "Заменить на RU")
map("v", "<leader>fr", ":TranslateR --target_lang=en<CR>", "Заменить на EN")

-- LSP функции
map("n", "K", function() vim.lsp.buf.hover() end, "Документация под курсором")
map("n", "gd", function() vim.lsp.buf.definition() end, "Перейти к определению")
map("n", "gl", function() vim.diagnostic.open_float() end, "Показать ошибку")

-- --- НАСТРОЙКА ОТЛАДЧИКА (DAP) ---
local ok_dap, dap = pcall(require, "dap")
if ok_dap then
    local ok_ui, dapui = pcall(require, "dapui")
    if ok_ui then dapui.setup() end

    dap.adapters.python = {
      type = 'executable',
      command = '/usr/bin/python3',
      args = { '-m', 'debugpy.adapter' },
    }

    dap.configurations.python = {{
        type = 'python', request = 'launch', name = "Launch file",
        program = "${file}", pythonPath = function() return '/usr/bin/python3' end,
    }}

    if ok_ui then
        dap.listeners.after.event_initialized["dapui_config"] = function() dapui.open() end
        dap.listeners.before.event_terminated["dapui_config"] = function() dapui.close() end
    end
end

