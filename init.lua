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
  { 
    "nvim-lualine/lualine.nvim", 
    event = "VeryLazy",
    dependencies = { "nvim-tree/nvim-web-devicons", "catppuccin" } 
  },
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
  { "rcarriga/nvim-dap-ui" , dependencies = { "mfussenegger/nvim-dap", "nvim-neotest/nvim-nio" } },
  { "nvim-neotest/nvim-nio" },
  { 'akinsho/bufferline.nvim', version = "*", dependencies = 'nvim-tree/nvim-web-devicons' },
  --{ "mfussenegger/nvim-dap-python" },
  {
    "Exafunction/codeium.nvim",
    dependencies = { "nvim-lua/plenary.nvim", "hrsh7th/nvim-cmp" }
  },
}, { track = 'branch' })

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
local ok, catppuccin = pcall(require, "catppuccin")
if ok then vim.cmd.colorscheme("catppuccin-mocha") end

-- LSP
ok, mason_lsp = pcall(require, "mason-lspconfig")
if ok then
    require("mason").setup()
    mason_lsp.setup({
        ensure_installed = { "pyright", "ruff", "bashls" },
        automatic_installation = true,
    })

    -- Новый способ активации серверов для nvim-lspconfig 0.11+
    if vim.lsp.enable then
        vim.lsp.enable('pyright')
        vim.lsp.enable('ruff')
        vim.lsp.enable('bashls')
    else
        -- Запасной вариант для более старых версий
        local lspconfig = require('lspconfig')
        lspconfig.pyright.setup({})
        lspconfig.ruff.setup({})
        lspconfig.bashls.setup({})
    end
end

-- Lualine
ok, lualine_module = pcall(require, "lualine")
if ok then
    local lualine_x_sections = { 'location' }
    local get_codeium_status = function()
        if vim.fn.exists('*codeium#GetStatusString') == 1 then
            return '★ ' .. vim.api.nvim_call_function("codeium#GetStatusString", {})
        end
        return ''
    end
    table.insert(lualine_x_sections, 1, { get_codeium_status, color = { fg = "#3185FC" } })

    lualine_module.setup({
        options = { globalstatus = true, theme = "auto", icons_enabled = true },
        sections = {
            lualine_a = { 'mode' },
            lualine_b = { 'branch' },
            lualine_c = { 'filename' },
            lualine_x = lualine_x_sections,
        }
    })
end

-- Bufferline (вкладки сверху)
ok, bufferline = pcall(require, "bufferline")
if ok then
    bufferline.setup({
        options = {
            mode = "buffers",
            separator_style = "slant",
            always_show_bufferline = true,
            -- Добавляем отступ для NvimTree
            offsets = {
                {
                    filetype = "NvimTree",
                    text = "File Explorer",
                    text_align = "center",
                    separator = true,
                }
            },
        }
    })
end

-- CMP
ok, cmp_module = pcall(require, "cmp")
if ok then
    cmp_module.setup({
        snippet = { expand = function(args) require('luasnip').lsp_expand(args.body) end },
        mapping = cmp_module.mapping.preset.insert({
            ['<CR>'] = cmp_module.mapping.confirm({ select = true }),
            ['<Tab>'] = cmp_module.mapping.select_next_item(),
        }),
        sources = cmp_module.config.sources({
            { name = 'nvim_lsp' }, { name = 'luasnip' }, { name = 'buffer' }, { name = 'path' },
        })
    })
end

-- Codeium
ok, codeium = pcall(require, "codeium")
if ok then
    codeium.setup({
        enable_cmp_source = false,
        virtual_text = { enabled = true, key_bindings = { accept = "<M-l>" } }
    })
end

-- Nvim-Tree
ok, nvim_tree = pcall(require, "nvim-tree")
if ok then nvim_tree.setup({ hijack_netrw = true }) end

-- Keymaps
local map = vim.keymap.set
map('n', '<leader>e', ':NvimTreeToggle<CR>')
map('n', '<leader>ff', ':Telescope find_files<CR>')
map('n', '<F5>', ':DapContinue<CR>')
map('n', '<F9>', ':DapToggleBreakpoint<CR>')
map('n', '<F10>', ':DapStepOver<CR>')
map('n', '<leader>w', ':w<CR>', { desc = 'Save file' })
map('n', '<leader>q', ':q<CR>', { desc = 'Quit' })
map('n', '<leader>wa', ':wa<CR>', { desc = 'Save all' })
map('n', '<leader>qa', ':qa<CR>', { desc = 'Quit all' })
-- Переключение между буферами (открытыми файлами)
map('n', '<Tab>', ':bnext<CR>', { desc = 'Next buffer' })
map('n', '<S-Tab>', ':bprevious<CR>', { desc = 'Previous buffer' })

-- Закрыть текущий буфер (но не окно)
map('n', '<leader>x', ':bd<CR>', { desc = 'Close buffer' })



-- НАСТРОЙКА ОТЛАДЧИКА (DAP)
local ok_dap, dap = pcall(require, "dap")
if ok_dap then
    -- Пытаемся загрузить UI отдельно
    local ok_ui, dapui = pcall(require, "dapui")
    if ok_ui then dapui.setup() end

    -- Адаптер
    dap.adapters.python = {
      type = 'executable',
      command = '/home/nach101/Study/ProjectsPython/Study/bin/python',
      args = { '-m', 'debugpy.adapter' },
    }

    -- Конфигурация
    dap.configurations.python = {
      {
        type = 'python',
        request = 'launch',
        name = "Launch file",
        program = "${file}",
        pythonPath = "/home/nach101/Study/ProjectsPython/Study/bin/python",
      },
    }

    -- Слушатели (только если UI загружен)
    if ok_ui then
        dap.listeners.after.event_initialized["dapui_config"] = function() dapui.open() end
        dap.listeners.before.event_terminated["dapui_config"] = function() dapui.close() end
        dap.listeners.before.event_exited["dapui_config"] = function() dapui.close() end
    end
end
