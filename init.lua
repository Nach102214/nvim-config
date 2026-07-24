-- ============================================================================
-- 1. УСТАНОВКА МЕНЕДЖЕРА ПЛАГИНОВ LAZY.NVIM
-- ============================================================================
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

-- ============================================================================
-- 2. СПИСОК УСТАНОВЛЕННЫХ ПЛАГИНОВ
-- ============================================================================
require("lazy").setup({
  { "catppuccin/nvim", name = "catppuccin", priority = 1000, lazy = false },
  {
    "nvim-tree/nvim-tree.lua",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
      vim.g.loaded_netrw = 1
      vim.g.loaded_netrwPlugin = 1
      require("nvim-tree").setup({ view = { width = 30 } })
    end
  },
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
  { "Exafunction/codeium.nvim", dependencies = { "nvim-lua/plenary.nvim", "hrsh7th/nvim-cmp" } },
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
}, {
    track = 'branch',
    rocks = { enabled = false }
})

-- ============================================================================
-- 3. ОСНОВНЫЕ НАСТРОЙКИ РЕДАКТОРА
-- ============================================================================
vim.g.mapleader = " "
vim.opt.termguicolors = true
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.mouse = 'a'
vim.opt.expandtab = true
vim.opt.tabstop = 4
vim.opt.shiftwidth = 4
vim.opt.clipboard = "unnamedplus"

vim.opt.colorcolumn = "79,88,120"
vim.api.nvim_set_hl(0, 'ColorColumn', { ctermbg=0, bg='#333333' })

-- ============================================================================
-- 4. НАСТРОЙКА И АКТИВАЦИЯ ПЛАГИНОВ
-- ============================================================================

-- Включение темы
local ok_cat, catppuccin = pcall(require, "catppuccin")
if ok_cat then vim.cmd.colorscheme("catppuccin-mocha") end

-- Lualine
local ok_lua, lualine = pcall(require, "lualine")
if ok_lua then lualine.setup({ options = { globalstatus = true, theme = "auto" } }) end

-- CMP
local cmp_status_ok, cmp = pcall(require, "cmp")
if cmp_status_ok then
    cmp.setup({
        snippet = { expand = function(args) require('luasnip').lsp_expand(args.body) end },
        mapping = cmp.mapping.preset.insert({
            ['<C-b>'] = cmp.mapping.scroll_docs(-4),
            ['<C-f>'] = cmp.mapping.scroll_docs(4),
            ['<CR>'] = cmp.mapping.confirm({ select = true }),
            ['<Tab>'] = cmp.mapping(function(fallback)
                if cmp.visible() then cmp.select_next_item()
                elseif require('luasnip').expand_or_jumpable() then
                    vim.fn.feedkeys(vim.api.nvim_replace_termcodes('<Plug>luasnip-expand-or-jump', true, true, true), '')
                else fallback() end
            end, { 'i', 's' }),
            ['<S-Tab>'] = cmp.mapping(function(fallback)
                if cmp.visible() then cmp.select_prev_item()
                elseif require('luasnip').jumpable(-1) then
                    vim.fn.feedkeys(vim.api.nvim_replace_termcodes('<Plug>luasnip-jump-prev', true, true, true), '')
                else fallback() end
            end, { 'i', 's' }),
        }),
        sources = cmp.config.sources({ { name = 'nvim_lsp' }, { name = 'luasnip' } }, { { name = 'buffer' } }),
        completion = { keyword_length = 1, trigger_character = {'.'} }
    })
end

-- LSP
local ok_lsp, mason_lsp = pcall(require, "mason-lspconfig")
if ok_lsp then
    require("mason").setup()
    mason_lsp.setup({
        ensure_installed = { "pyright", "ruff", "bashls" },
        automatic_installation = true,
    })
    local capabilities = vim.lsp.protocol.make_client_capabilities()
    if cmp_status_ok then capabilities = require('cmp_nvim_lsp').default_capabilities(capabilities) end

    for _, server in ipairs({ "pyright", "ruff", "bashls" }) do
        local config = { capabilities = capabilities }
        if server == "pyright" then
            config.settings = {
                python = {
                    analysis = {
                        autoSearchPaths = true,
                        diagnosticMode = "workspace",
                        useLibraryCodeForTypes = true,
                        typeCheckingMode = "basic"
                    }
                }
            }
        end
        vim.lsp.config(server, config)
        vim.lsp.enable(server)
    end
end

-- ============================================================================
-- 5. НАСТРОЙКА ДИАГНОСТИКИ
-- ============================================================================
vim.diagnostic.config({
  virtual_text = false,
  signs = true,
  underline = true,
  update_in_insert = false,
  severity_sort = true,
  float = {
    focusable = true,
    style = "minimal",
    border = "rounded",
    source = "always",
    header = "",
    prefix = "",
  },
})

-- ============================================================================
-- 6. ПЕРЕВОД ОШИБОК НА РУССКИЙ
-- ============================================================================
local function translate_current_diagnostic()
    local line_diagnostics = vim.diagnostic.get(0, { lnum = vim.fn.line('.') - 1 })
    
    if #line_diagnostics == 0 then
        print("Диагностик на этой строке не найдено")
        return
    end

    table.sort(line_diagnostics, function(a, b) return a.severity < b.severity end)
    local target_diag = line_diagnostics[1]

    local raw_msg_obj = target_diag.message or "(Сообщение пустое)"
    local extracted_text = ""

    local function find_string(obj)
        if type(obj) == "string" then return obj end
        if type(obj) == "table" then
            if obj.text and type(obj.text) == "string" then return obj.text end
            if obj[1] and type(obj[1]) == "table" then return find_string(obj[1]) end
            for _, v in pairs(obj) do
                local result = find_string(v)
                if result and result ~= "" then return result end
            end
        end
        return nil
    end

    extracted_text = find_string(raw_msg_obj)
    if not extracted_text or extracted_text == "" then
        extracted_text = vim.inspect(raw_msg_obj)
    end

    if extracted_text == "" or extracted_text:len() < 2 then
        print("Не удалось извлечь текст ошибки")
        return
    end

    local severity_name = ""
    if target_diag.severity == vim.diagnostic.severity.ERROR then
        severity_name = "ОШИБКА"
    elseif target_diag.severity == vim.diagnostic.severity.WARN then
        severity_name = "ПРЕДУПРЕЖДЕНИЕ"
    else
        severity_name = "СООБЩЕНИЕ"
    end

    print(string.format("Перевожу %s...", severity_name:lower()))

    local encoded_msg
    if vim.uri_encode then
        encoded_msg = vim.uri_encode(extracted_text, { authority = true })
    else
        encoded_msg = vim.fn.escape(extracted_text, " %#&?+=")
    end
    
    local url = "https://translate.googleapis.com/translate_a/single?client=gtx&sl=auto&tl=ru&dt=t&q=" .. encoded_msg

    vim.fn.jobstart({
        "curl", "-s", "--max-time", "8",
        "-H", "User-Agent: Mozilla/5.0",
        url
    }, {
        on_stdout = function(_, data)
            if not data or #data == 0 then return end
            
            local raw_response = table.concat(data, "\n")
            raw_response = raw_response:gsub("^%)%]%}'\n", "")
            
            local ok, json = pcall(vim.json.decode, raw_response)
            local translated_text = ""

            if ok and json and type(json) == "table" then
                if #json > 0 and type(json[1]) == "table" and #json[1] > 0 then
                    local first = json[1][1]
                    if type(first) == "string" then
                        translated_text = first
                    elseif type(first) == "table" and #first > 0 then
                        translated_text = first[1] or ""
                    else
                        translated_text = tostring(first)
                    end
                else
                    translated_text = tostring(json)
                end
            elseif not ok then
                translated_text = raw_response:gsub("^%s*(.-)%s*$", "%1")
            end

            if translated_text == "" or translated_text:len() < 2 then
                print("Не удалось получить перевод")
                return
            end

            local buf = vim.api.nvim_create_buf(false, true)
            local title_str = string.format(" [%s -> RU] ", severity_name)
            
            local lines = { " Перевод:", "" }
            local clean_text = translated_text:sub(1, 400):gsub("\r", "")
            for line in clean_text:gmatch("[^\n]+") do
                table.insert(lines, " " .. line)
            end
            if #lines == 2 then
                table.insert(lines, " (пусто)")
            end
            
            local win_id = vim.api.nvim_open_win(buf, true, {
                relative = "cursor",
                row = 1,
                col = 0,
                width = math.min(#translated_text + 4, 75),
                height = #lines + 1,
                style = "minimal",
                border = "rounded",
                title = title_str,
                title_pos = "center",
            })

            vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)

            vim.defer_fn(function()
                if vim.api.nvim_win_is_valid(win_id) then vim.api.nvim_win_close(win_id, true) end
                if vim.api.nvim_buf_is_valid(buf) then vim.api.nvim_buf_delete(buf, {}) end
            end, 10000)
        end,
        on_stderr = function(_, err_data)
            if err_data and err_data[1] and err_data[1] ~= "" then
                print("Ошибка curl:", err_data[1])
            end
        end,
        on_exit = function(_, code)
            if code ~= 0 then
                print("Запрос завершился с ошибкой (" .. tostring(code) .. ")")
            end
        end
    })
end

-- ============================================================================
-- 7. ГОРЯЧИЕ КЛАВИШИ
-- ============================================================================
local function map(mode, lhs, rhs, desc)
    vim.keymap.set(mode, lhs, rhs, { silent = true, desc = desc })
end

-- Файлы и буферы
map('n', '<leader>e', ':NvimTreeToggle<CR>', 'Открыть/Закрыть дерево файлов')
map('n', '<leader>ff', ':Telescope find_files<CR>', 'Поиск файлов')
map('n', '<leader>w', ':w<CR>', 'Сохранить')
map('n', '<leader>q', ':q<CR>', 'Закрыть')
map('n', '<Tab>', ':bnext<CR>', 'Следующий буфер')
map('n', '<S-Tab>', ':bprevious<CR>', 'Предыдущий буфер')

-- Диагностика
map('n', '[d', vim.diagnostic.goto_prev, 'Предыдущая ошибка')
map('n', ']d', vim.diagnostic.goto_next, 'Следующая ошибка')
map('n', 'gl', vim.diagnostic.open_float, 'Показать ошибку')
map('n', '<leader>dl', vim.diagnostic.setloclist, 'Список ошибок')
map('n', '<leader>gt', translate_current_diagnostic, 'Перевести ошибку на русский')

-- Переводчик
map('n', '<leader>t', ':TranslateW --target_lang=ru<CR>', 'Перевести на русский')
map('v', '<leader>t', ':TranslateW --target_lang=ru<CR>', 'Перевести на русский (выделение)')
map('n', '<leader>f', ':TranslateW --target_lang=en<CR>', 'Перевести на английский')
map('v', '<leader>f', ':TranslateW --target_lang=en<CR>', 'Перевести на английский (выделение)')
map('v', '<leader>r', ':TranslateR --target_lang=en<CR>', 'Заменить переводом')

-- Форматирование и запуск
map('n', '<leader>fm', function() vim.lsp.buf.format({ async = true }) end, 'Форматировать')
map('n', '<leader>x', function()
    vim.cmd('w')
    vim.cmd('botright split | resize 12 | term python3 %')
    vim.defer_fn(function() vim.cmd('wincmd k') end, 50)
end, 'Запустить Python')

-- Закрытие терминала
vim.keymap.set('t', '<Esc>', [[<C-\><C-n>]], { silent = true, desc = 'Выйти из терминала' })
map('n', '<leader>tc', function()
    local found = nil
    for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
        local buf = vim.api.nvim_win_get_buf(win)
        if vim.bo[buf].buftype == 'terminal' then
            found = win
            break
        end
    end
    if found then
        vim.api.nvim_win_close(found, true)
    else
        vim.cmd('noh')
    end
end, 'Закрыть терминал')

-- ESC: закрыть терминал или сбросить поиск
vim.keymap.set('n', '<Esc>', function()
    local found = nil
    for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
        local buf = vim.api.nvim_win_get_buf(win)
        if vim.bo[buf].buftype == 'terminal' then
            found = win
            break
        end
    end
    if found then
        vim.api.nvim_win_close(found, true)
    else
        vim.cmd('noh')
    end
end, { silent = true, desc = 'Закрыть терминал / Сбросить поиск' })

-- ============================================================================
-- 8. НАСТРОЙКА ОТЛАДЧИКА (DAP)
-- ============================================================================
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
        if vim.fn.executable('python3') == 1 then return vim.fn.exepath('python3') end
        return '/usr/bin/python3'
    end

    dap.adapters.python = function(cb, config)
        if config.request == 'attach' then
            local port = (config.connect or config).port
            local host = (config.connect or config).host or '127.0.0.1'
            cb({ type = 'server', port = assert(port), host = host, options = { source_filetype = 'python' } })
        else
            cb({ type = 'executable', command = get_python_path(), args = { '-m', 'debugpy.adapter' }, options = { source_filetype = 'python' } })
        end
    end

    dap.configurations.python = {
        {
            type = 'python',
            request = 'launch',
            name = "Launch file",
            program = "${file}",
            pythonPath = get_python_path,
        },
    }

    if ok_ui then
        dap.listeners.after.event_initialized["dapui_config"] = function() dapui.open() end
        dap.listeners.before.event_terminated["dapui_config"] = function() dapui.close() end
        dap.listeners.before.event_exited["dapui_config"] = function() dapui.close() end
    end

    -- Горячие клавиши отладки
    vim.keymap.set('n', '<F5>', function() dap.continue() end, { desc = 'Старт / Продолжить' })
    vim.keymap.set('n', '<F10>', function() dap.step_over() end, { desc = 'Шаг с обходом' })
    vim.keymap.set('n', '<F11>', function() dap.step_into() end, { desc = 'Шаг с заходом' })
    vim.keymap.set('n', '<F12>', function() dap.step_out() end, { desc = 'Шаг с выходом' })
    vim.keymap.set('n', '<leader>b', function() dap.toggle_breakpoint() end, { desc = 'Точка останова' })
    vim.keymap.set('n', '<leader>dr', function() dap.restart() end, { desc = 'Перезапустить' })
end

-- ============================================================================
-- НАВИГАЦИЯ CTRL + СТРЕЛКИ (Гарантированно рабочий вариант)
-- ============================================================================
local function win_nav(mode, key, cmd)
  vim.keymap.set(mode, key, cmd, { silent = true })
end

-- Normal mode
win_nav('n', '<C-Up>', '<C-w>k')
win_nav('n', '<C-Down>', '<C-w>j')
win_nav('n', '<C-Left>', '<C-w>h')
win_nav('n', '<C-Right>', '<C-w>l')

-- Visual mode
win_nav('v', '<C-Up>', '<C-w>k')
win_nav('v', '<C-Down>', '<C-w>j')
win_nav('v', '<C-Left>', '<C-w>h')
win_nav('v', '<C-Right>', '<C-w>l')

-- Insert mode (оставляем стандартными Ctrl+стрелки, если нужны перемещения курсора)
-- Обычно в Insert режиме Ctrl+стрелки свободны, но лучше оставить дефолт
vim.keymap.set('i', '<C-Up>', '<C-Up>', { noremap = true })
vim.keymap.set('i', '<C-Down>', '<C-Down>', { noremap = true })
vim.keymap.set('i', '<C-Left>', '<C-Left>', { noremap = true })
vim.keymap.set('i', '<C-Right>', '<C-Right>', { noremap = true })
