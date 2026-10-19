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
    'numToStr/Comment.nvim',
    opts = {},
    lazy = false,
  },
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
  { "akinsho/bufferline.nvim", version = "*", dependencies = "nvim-tree/nvim-web-devicons" },
  { "Exafunction/codeium.nvim", dependencies = { "nvim-lua/plenary.nvim", "hrsh7th/nvim-cmp" } },
  {
    "voldikss/vim-translator",
    init = function()
      vim.cmd([[
        " vim-translator оставлен для совместимости, но основной перевод идёт
        " через собственную функцию google_translate (см. секцию 6.5).
        let g:translator_default_engines = ['bing', 'google']
        let g:translator_source_lang = 'ru'
        let g:translator_default_target_lang = 'en'
        let g:translator_window_max_width = 80
        let g:translator_window_max_height = 20
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
vim.api.nvim_set_hl(0, 'ColorColumn', { ctermbg = 0, bg = '#333333' })

-- Автоматически удалять терминальные буферы после закрытия окна.
vim.api.nvim_create_autocmd("TermOpen", {
  pattern = "*",
  callback = function()
    vim.opt_local.bufhidden = "wipe"
    vim.opt_local.buflisted = false
    vim.opt_local.number = false
    vim.opt_local.relativenumber = false
  end,
})

-- Принудительно удалять терминальный буфер при закрытии окна
vim.api.nvim_create_autocmd("WinClosed", {
  pattern = "*",
  callback = function(args)
    local win = tonumber(args.match)
    if not win then return end

    local buf = vim.api.nvim_win_get_buf(win)
    if vim.bo[buf].buftype == "terminal" then
      vim.schedule(function()
        if vim.api.nvim_buf_is_valid(buf) then
          vim.api.nvim_buf_delete(buf, { force = true })
        end
      end)
    end
  end,
})

-- ============================================================================
-- 4. НАСТРОЙКА И АКТИВАЦИЯ ПЛАГИНОВ
-- ============================================================================

-- Включение темы
local ok_cat, _ = pcall(require, "catppuccin")
if ok_cat then vim.cmd.colorscheme("catppuccin-mocha") end

-- Lualine
local ok_lua, lualine = pcall(require, "lualine")
if ok_lua then
  lualine.setup({ options = { globalstatus = true, theme = "auto" } })
end

-- CMP
local cmp_status_ok, cmp = pcall(require, "cmp")
if cmp_status_ok then
  cmp.setup({
    snippet = {
      expand = function(args)
        require('luasnip').lsp_expand(args.body)
      end
    },
    mapping = cmp.mapping.preset.insert({
      ['<C-b>'] = cmp.mapping.scroll_docs(-4),
      ['<C-f>'] = cmp.mapping.scroll_docs(4),
      ['<CR>'] = cmp.mapping.confirm({ select = true }),
      ['<Tab>'] = cmp.mapping(function(fallback)
        if cmp.visible() then
          cmp.select_next_item()
        elseif require('luasnip').expand_or_jumpable() then
          vim.fn.feedkeys(vim.api.nvim_replace_termcodes('<Plug>luasnip-expand-or-jump', true, true, true), '')
        else
          fallback()
        end
      end, { 'i', 's' }),
      ['<S-Tab>'] = cmp.mapping(function(fallback)
        if cmp.visible() then
          cmp.select_prev_item()
        elseif require('luasnip').jumpable(-1) then
          vim.fn.feedkeys(vim.api.nvim_replace_termcodes('<Plug>luasnip-jump-prev', true, true, true), '')
        else
          fallback()
        end
      end, { 'i', 's' }),
    }),
    sources = cmp.config.sources(
      { { name = 'nvim_lsp' }, { name = 'luasnip' } },
      { { name = 'buffer' } }
    ),
    completion = { keyword_length = 1, trigger_character = { '.' } }
  })
end

-- LSP (синтаксис для Neovim 0.11+)
local ok_lsp, mason_lsp = pcall(require, "mason-lspconfig")
if ok_lsp then
  require("mason").setup()
  mason_lsp.setup({
    ensure_installed = { "pyright", "ruff", "bashls" },
    automatic_installation = true,
  })
  local capabilities = vim.lsp.protocol.make_client_capabilities()
  if cmp_status_ok then
    capabilities = require('cmp_nvim_lsp').default_capabilities(capabilities)
  end

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

-- Bufferline (визуальные вкладки вверху, как в браузере)
local ok_bufferline, bufferline = pcall(require, "bufferline")
if ok_bufferline then
  bufferline.setup({
    options = {
      mode = "buffers",
      style_preset = bufferline.style_preset.default,
      numbers = "none",
      indicator = {
        style = "icon",
      },
      buffer_close_icon = "",
      modified_icon = "●",
      close_icon = "",
      left_trunc_marker = "",
      right_trunc_marker = "",
      max_name_length = 30,
      max_prefix_length = 15,
      tab_size = 20,
      diagnostics = "nvim_lsp",
      diagnostics_update_in_insert = false,
      diagnostics_indicator = function(count, level, diagnostics_dict, context)
        local icon = level:match("error") and " " or " "
        return " " .. icon .. count
      end,
      offsets = {
        {
          filetype = "NvimTree",
          text = "File Explorer",
          text_align = "center",
          separator = true,
        },
      },
      show_buffer_icons = true,
      show_buffer_close_icons = true,
      show_close_icon = false,
      show_tab_indicators = true,
      persist_buffer_sort = true,
      separator_style = "slant",
      enforce_regular_tabs = false,
      always_show_bufferline = true,
      sort_by = "insert_after_current",
    },
    highlights = {},
  })
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

  local url = "https://translate.google.com/translate_a/single?client=gtx&sl=auto&tl=ru&dt=t&q=" .. encoded_msg

  vim.fn.jobstart({
    "curl", "-s", "-L", "--max-time", "15",
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
        if vim.api.nvim_win_is_valid(win_id) then
          vim.api.nvim_win_close(win_id, true)
        end
        if vim.api.nvim_buf_is_valid(buf) then
          vim.api.nvim_buf_delete(buf, {})
        end
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
-- 6.5. СВОЙ ПЕРЕВОДЧИК (все определения функций)
-- ============================================================================
-- Использует translate.googleapis.com — тот же endpoint, что и перевод диагностик.
-- Не зависит от капризов Bing и vim-translator.

-- Получить выделенный в визуальном режиме текст
local function get_visual_selection()
  local start_pos = vim.fn.getpos("'<")
  local end_pos = vim.fn.getpos("'>")
  local lines = vim.fn.getline(start_pos[2], end_pos[2])

  if #lines == 0 then return nil end

  local text
  if #lines == 1 then
    text = string.sub(lines[1], start_pos[3], end_pos[3])
  else
    lines[1] = string.sub(lines[1], start_pos[3])
    lines[#lines] = string.sub(lines[#lines], 1, end_pos[3])
    text = table.concat(lines, "\n")
  end

  if text == "" then return nil end
  return text
end

-- Перевести текст через Google API
local function google_translate(text, source_lang, target_lang, callback)
  local encoded = vim.uri_encode(text, { authority = true })
  local url = string.format(
    "https://translate.googleapis.com/translate_a/single?client=gtx&sl=%s&tl=%s&dt=t&q=%s",
    source_lang, target_lang, encoded
  )

  vim.fn.jobstart({
    "curl", "-s", "-L", "--max-time", "15",
    "-H", "User-Agent: Mozilla/5.0",
    url
  }, {
    on_stdout = function(_, data)
      if not data or #data == 0 then
        callback(nil)
        return
      end
      local raw = table.concat(data, "\n")
      local ok, json = pcall(vim.json.decode, raw)

      if not ok or not json or not json[1] then
        callback(nil)
        return
      end

      local parts = {}
      for _, segment in ipairs(json[1]) do
        if type(segment) == "table" and segment[1] then
          table.insert(parts, segment[1])
        end
      end
      local translated = table.concat(parts)
      if translated == "" then
        callback(nil)
      else
        callback(translated)
      end
    end,
    on_stderr = function() end,
    on_exit = function(_, code)
      if code ~= 0 then callback(nil) end
    end
  })
end

-- Определить направление перевода по наличию кириллицы
local function detect_direction(text)
  if text:find("[а-яА-ЯёЁ]") then
    return "ru", "en"
  else
    return "en", "ru"
  end
end

-- Показать перевод в плавающем окне
local function show_translation_window(src, tgt, translated)
  local buf = vim.api.nvim_create_buf(false, true)
  local lines = { " Перевод:", "" }
  for line in translated:gmatch("[^\n]+") do
    table.insert(lines, " " .. line)
  end

  local win_id = vim.api.nvim_open_win(buf, true, {
    relative = "cursor",
    row = 1,
    col = 0,
    width = math.min(#translated + 4, 75),
    height = #lines + 1,
    style = "minimal",
    border = "rounded",
    title = string.format(" [%s → %s] ", src:upper(), tgt:upper()),
    title_pos = "center",
  })

  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)

  vim.defer_fn(function()
    if vim.api.nvim_win_is_valid(win_id) then
      vim.api.nvim_win_close(win_id, true)
    end
    if vim.api.nvim_buf_is_valid(buf) then
      vim.api.nvim_buf_delete(buf, {})
    end
  end, 10000)
end

-- Visual: заменить выделение переводом
local function translate_visual_and_replace()
  local text = get_visual_selection()
  if not text then
    print("Ничего не выделено")
    return
  end

  local src, tgt = detect_direction(text)
  print(string.format("Перевожу (%s → %s)...", src, tgt))

  google_translate(text, src, tgt, function(translated)
    if not translated then
      print("Не удалось перевести")
      return
    end

    vim.schedule(function()
      vim.cmd("normal! gv")
      local keys = vim.api.nvim_replace_termcodes('c' .. translated .. '<Esc>', true, false, true)
      vim.api.nvim_feedkeys(keys, 'n', false)
      print("Заменено: " .. translated)
    end)
  end)
end

-- Visual: показать перевод выделения в окне
local function translate_visual_show()
  local text = get_visual_selection()
  if not text then
    print("Ничего не выделено")
    return
  end

  local src, tgt = detect_direction(text)
  print(string.format("Перевожу (%s → %s)...", src, tgt))

  google_translate(text, src, tgt, function(translated)
    if not translated then
      print("Не удалось перевести")
      return
    end
    vim.schedule(function()
      show_translation_window(src, tgt, translated)
    end)
  end)
end

-- Normal: слово под курсором — показать перевод
local function translate_word_under_cursor_show()
  local word = vim.fn.expand("<cword>")
  if word == "" then
    print("Под курсором нет слова")
    return
  end

  local src, tgt = detect_direction(word)
  print(string.format("Перевожу (%s → %s): %s", src, tgt, word))

  google_translate(word, src, tgt, function(translated)
    if not translated then
      print("Не удалось перевести")
      return
    end
    vim.schedule(function()
      show_translation_window(src, tgt, translated)
    end)
  end)
end

-- Normal: слово под курсором — заменить переводом
local function translate_word_under_cursor_replace()
  local word = vim.fn.expand("<cword>")
  if word == "" then
    print("Под курсором нет слова")
    return
  end

  local src, tgt = detect_direction(word)
  print(string.format("Перевожу (%s → %s): %s", src, tgt, word))

  google_translate(word, src, tgt, function(translated)
    if not translated then
      print("Не удалось перевести")
      return
    end

    vim.schedule(function()
      local keys = vim.api.nvim_replace_termcodes('ciw' .. translated .. '<Esc>', true, false, true)
      vim.api.nvim_feedkeys(keys, 'n', false)
      print("Заменено: " .. translated)
    end)
  end)
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
-- Навигация по bufferline
map('n', '<A-1>', '<Cmd>BufferLineGoToBuffer 1<CR>', 'Буфер 1')
map('n', '<A-2>', '<Cmd>BufferLineGoToBuffer 2<CR>', 'Буфер 2')
map('n', '<A-3>', '<Cmd>BufferLineGoToBuffer 3<CR>', 'Буфер 3')
map('n', '<A-4>', '<Cmd>BufferLineGoToBuffer 4<CR>', 'Буфер 4')
map('n', '<A-5>', '<Cmd>BufferLineGoToBuffer 5<CR>', 'Буфер 5')
map('n', '<A-Left>', '<Cmd>BufferLineCyclePrev<CR>', 'Предыдущий буфер')
map('n', '<A-Right>', '<Cmd>BufferLineCycleNext<CR>', 'Следующий буфер')
map('n', '<A-w>', '<Cmd>bdelete<CR>', 'Закрыть буфер')
map('n', '<A-W>', '<Cmd>BufferLineCloseOthers<CR>', 'Закрыть все кроме текущего')

-- Диагностика
map('n', '[d', vim.diagnostic.goto_prev, 'Предыдущая ошибка')
map('n', ']d', vim.diagnostic.goto_next, 'Следующая ошибка')
map('n', 'gl', vim.diagnostic.open_float, 'Показать ошибку')
map('n', '<leader>dl', vim.diagnostic.setloclist, 'Список ошибок')
map('n', '<leader>gt', translate_current_diagnostic, 'Перевести ошибку на русский')

-- ============================================================================
-- Переводчик (только маппинги; определения — в секции 6.5)
-- ============================================================================
-- Normal режим: слово под курсором
vim.keymap.set('n', '<leader>t', translate_word_under_cursor_show, { silent = true, desc = 'Перевести слово под курсором (окно)' })
vim.keymap.set('n', '<leader>f', translate_word_under_cursor_show, { silent = true, desc = 'Перевести слово под курсором (окно)' })
vim.keymap.set('n', '<leader>r', translate_word_under_cursor_replace, { silent = true, desc = 'Заменить слово под курсором переводом' })

-- Визуальный режим: выделенный текст
vim.keymap.set('v', '<leader>t', translate_visual_show, { silent = true, desc = 'Перевести выделение (окно)' })
vim.keymap.set('v', '<leader>f', translate_visual_show, { silent = true, desc = 'Перевести выделение (окно)' })
vim.keymap.set('v', '<leader>r', translate_visual_and_replace, { silent = true, desc = 'Заменить выделение переводом' })

-- ============================================================================
-- Форматирование и запуск Python
-- ============================================================================
map('n', '<leader>fm', function()
  vim.lsp.buf.format({ async = true })
end, 'Форматировать')

map('n', '<leader>x', function()
  vim.cmd('silent! update')
  vim.cmd('botright split | resize 12 | term python3 %')
  vim.defer_fn(function() vim.cmd('wincmd k') end, 50)
end, 'Запустить Python')

-- Закрытие терминала
vim.keymap.set('t', '<Esc>', [[<C-\><C-n>]], { silent = true, desc = 'Выйти из терминала' })

map('n', '<leader>tc', function()
  local found_win = nil
  local found_buf = nil
  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    local buf = vim.api.nvim_win_get_buf(win)
    if vim.bo[buf].buftype == 'terminal' then
      found_win = win
      found_buf = buf
      break
    end
  end
  if found_win then
    vim.api.nvim_win_close(found_win, true)
    vim.schedule(function()
      if vim.api.nvim_buf_is_valid(found_buf) then
        vim.api.nvim_buf_delete(found_buf, { force = true })
      end
    end)
  else
    vim.cmd('noh')
  end
end, 'Закрыть терминал')

-- ESC: закрыть терминал или сбросить поиск
vim.keymap.set('n', '<Esc>', function()
  local found_win = nil
  local found_buf = nil
  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    local buf = vim.api.nvim_win_get_buf(win)
    if vim.bo[buf].buftype == 'terminal' then
      found_win = win
      found_buf = buf
      break
    end
  end
  if found_win then
    vim.api.nvim_win_close(found_win, true)
    vim.schedule(function()
      if vim.api.nvim_buf_is_valid(found_buf) then
        vim.api.nvim_buf_delete(found_buf, { force = true })
      end
    end)
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
-- 9. НАВИГАЦИЯ CTRL + СТРЕЛКИ
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

-- Insert mode (стандартное поведение Ctrl+стрелки)
vim.keymap.set('i', '<C-Up>', '<C-Up>', { noremap = true })
vim.keymap.set('i', '<C-Down>', '<C-Down>', { noremap = true })
vim.keymap.set('i', '<C-Left>', '<C-Left>', { noremap = true })
vim.keymap.set('i', '<C-Right>', '<C-Right>', { noremap = true })
