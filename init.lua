-- 1. Установка менеджера плагинов Lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com",
    "--branch=main",
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
  
  -- Стабильная версия Codeium (VimScript)
  { "Exafunction/codeium.vim", event = "BufReadPre" },

  -- ПЕРЕВОДЧИК
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

-- LSP (Самый новый стандарт для Neovim 0.11/0.12)
local ok_lsp, mason_lsp = pcall(require, "mason-lspconfig")
if ok_lsp then
    require("mason").setup()
    mason_lsp.setup({
        ensure_installed = { "pyright", "ruff", "bashls" },
        automatic_installation = true,
    })
    
    local caps = require("cmp_nvim_lsp").default_capabilities()

    -- Используем новый системный API вместо require('lspconfig')
    for _, server in ipairs({ "pyright", "ruff", "bashls" }) do
        -- Регистрируем конфигурацию сервера
        vim.lsp.config(server, { capabilities = caps })
        -- Активируем сервер
        vim.lsp.enable(server)
    end
end


-- Lualine
local ok_lua, lualine = pcall(require, "lualine")
if ok_lua then
    lualine.setup({ options = { globalstatus = true, theme = "auto" } })
end

-- Treesitter (с автоустановкой markdown)
local ok_ts, ts = pcall(require, "nvim-treesitter.configs")
if ok_ts then
    ts.setup({
        ensure_installed = { "python", "lua", "bash", "markdown", "markdown_inline", "vim", "vimdoc" },
        auto_install = true,
        highlight = { enable = true },
    })
end

-- --- ГОРЯЧИЕ КЛАВИШИ ---
local function map(mode, lhs, rhs, desc)
    vim.keymap.set(mode, lhs, rhs, { silent = true, desc = desc })
end
 
map("n", "<leader>e", ":NvimTreeToggle<CR>", "Explorer")
map("n", "<leader>ff", ":Telescope find_files<CR>", "Find Files")
map("n", "<Tab>", ":bnext<CR>", "Next Buffer")
map("n", "<S-Tab>", ":bprevious<CR>", "Prev Buffer")
map("n", "<leader>w", ":w<CR>", "Save")
map("n", "<leader>q", ":q<CR>", "Quit")
map("n", "<leader>fm", function() vim.lsp.buf.format({ async = true }) end, "Format File")

-- Переводчик
map("v", "<leader>t", ":TranslateW --target_lang=ru<CR>", "View RU translation")
map("v", "<leader>f", ":TranslateW --target_lang=en<CR>", "View EN translation")
map("v", "<leader>tr", ":TranslateR --target_lang=ru<CR>", "Replace with RU")
map("v", "<leader>fr", ":TranslateR --target_lang=en<CR>", "Replace with EN")

-- LSP функции
map("n", "K", function() vim.lsp.buf.hover() end, "Show Documentation")
map("n", "gl", function() vim.diagnostic.open_float() end, "Log diagnostics")

-- --- НАСТРОЙКА ОТЛАДЧИКА (DAP) ---
local ok_dap, dap = pcall(require, "dap")
if ok_dap then
    local ok_ui, dapui = pcall(require, "dapui")
    if ok_ui then dapui.setup() end

    local function get_python_path()
        local venv_path = os.getenv("VIRTUAL_ENV")
        if venv_path then return venv_path .. '/bin/python' end
        local cwd = vim.fn.getcwd()
        if vim.fn.executable(cwd .. '/venv/bin/python') == 1 then return cwd .. '/venv/bin/python' end
        if vim.fn.executable(cwd .. '/.venv/bin/python') == 1 then return cwd .. '/.venv/bin/python' end
        return '/usr/bin/python3'
    end

    dap.adapters.python = {
      type = 'executable',
      command = get_python_path(),
      args = { '-m', 'debugpy.adapter' },
    }

    dap.configurations.python = {
      {
        type = 'python',
        request = 'launch',
        name = "Launch file",
        program = "${file}",
        pythonPath = get_python_path(),
      },
    }

    if ok_ui then
        dap.listeners.after.event_initialized["dapui_config"] = function() dapui.open() end
        dap.listeners.before.event_terminated["dapui_config"] = function() dapui.close() end
    end
end

