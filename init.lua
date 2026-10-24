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
    -- Запуск блока кода внутри Markdown-файлов.
    {
  "michaelb/sniprun",
  build = "sh ./install.sh",
  config = function() require("sniprun").setup() end
    },

  -- Тема
  { "catppuccin/nvim", name = "catppuccin", priority = 1000, lazy = false },

  -- Комментарии
  { "numToStr/Comment.nvim", lazy = false, config = function() require("Comment").setup() end },

  -- Дерево файлов
  {
    "nvim-tree/nvim-tree.lua",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
      vim.g.loaded_netrw = 1
      vim.g.loaded_netrwPlugin = 1
      require("nvim-tree").setup({ view = { width = 30 } })
    end,
  },

  -- Статусная строка
  { "nvim-lualine/lualine.nvim", event = "VeryLazy", dependencies = { "nvim-tree/nvim-web-devicons", "catppuccin" } },

  -- Синтаксис
  { "nvim-treesitter/nvim-treesitter", build = ":TSUpdate" },

  -- Поиск
  { "nvim-telescope/telescope.nvim", branch = "0.1.x", dependencies = { "nvim-lua/plenary.nvim" } },

  -- LSP и автодополнение
  { "neovim/nvim-lspconfig" },
  { "williamboman/mason.nvim" },
  { "williamboman/mason-lspconfig.nvim" },
  { "hrsh7th/nvim-cmp" },
  { "hrsh7th/cmp-nvim-lsp" },
  { "hrsh7th/cmp-buffer" },
  { "hrsh7th/cmp-path" },
  { "L3MON4D3/LuaSnip" },
  { "rafamadriz/friendly-snippets" },
  { "saadparwaiz1/cmp_luasnip" },

  -- Отладчик
  { "mfussenegger/nvim-dap" },
  { "rcarriga/nvim-dap-ui", dependencies = { "mfussenegger/nvim-dap", "nvim-neotest/nvim-nio" } },
  { "nvim-neotest/nvim-nio" },

  -- Буферы
  { "akinsho/bufferline.nvim", version = "*", dependencies = "nvim-tree/nvim-web-devicons" },

  -- AI автодополнение
  { "Exafunction/codeium.nvim", dependencies = { "nvim-lua/plenary.nvim", "hrsh7th/nvim-cmp" } },

  -- Переводчик
  {
    "voldikss/vim-translator",
    init = function()
      vim.cmd([[
        let g:translator_default_engines = ['google', 'bing']
        let g:translator_source_lang = 'auto'
        let g:translator_default_target_lang = 'ru'
        let g:translator_window_max_width = 80
        let g:translator_window_max_height = 20
      ]])
    end,
  },

  -- Просмотр Markdown и Mermaid в браузере
  {
    "iamcco/markdown-preview.nvim",
    cmd = { "MarkdownPreviewToggle", "MarkdownPreview", "MarkdownPreviewStop" },
    ft = { "markdown" },
    build = function() vim.fn["mkdp#util#install"]() end,
    init = function()
      vim.g.mkdp_auto_start = 0
      vim.g.mkdp_auto_close = 1
      vim.g.mkdp_refresh_slow = 0
    end,
    config = function()
      vim.keymap.set("n", "<leader>mk", ":MarkdownPreviewToggle<CR>", { silent = true, desc = "Предпросмотр MD/Mermaid" })
    end,
  },

  -- Эмодзи (поиск и вставка) — только для markdown
  {
    "allaman/emoji.nvim",
    ft = "markdown",
    dependencies = {
      "hrsh7th/nvim-cmp",
      "nvim-telescope/telescope.nvim",
    },
    opts = {
      enable_cmp_integration = true,
    },
    config = function(_, opts)
      require("emoji").setup(opts)
      require("telescope").load_extension("emoji")
      -- Добавляем источник emoji в cmp ТОЛЬКО для markdown,
      -- не трогая глобальные настройки cmp.
      local cmp = require("cmp")
      cmp.setup.filetype({ "markdown" }, {
        sources = cmp.config.sources({
          { name = "nvim_lsp" },
          { name = "luasnip" },
          { name = "emoji" },
        }, {
          { name = "buffer" },
        }),
      })
    end,
  },
}, {
  track = "branch",
  rocks = { enabled = false },
  git = { timeout = 120000 },
})

-- ============================================================================
-- 3. ОСНОВНЫЕ НАСТРОЙКИ РЕДАКТОРА
-- ============================================================================
vim.g.mapleader = " "
vim.opt.termguicolors = true
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.mouse = "a"
vim.opt.expandtab = true
vim.opt.tabstop = 4
vim.opt.shiftwidth = 4
vim.opt.clipboard = "unnamedplus"

-- Кодировки
vim.opt.encoding = "utf-8"
vim.opt.fileencodings = "ucs-bom,utf-8,cp1251,koi8-r,cp866,latin1"
vim.opt.bomb = false
vim.env.LANG = "en_US.UTF-8"
vim.env.PYTHONIOENCODING = "utf-8"

vim.opt.colorcolumn = "79,88,120"
vim.api.nvim_set_hl(0, "ColorColumn", { ctermbg = 0, bg = "#333333" })

-- Автоудаление терминальных буферов
vim.api.nvim_create_autocmd("TermOpen", {
  pattern = "*",
  callback = function()
    vim.opt_local.bufhidden = "wipe"
    vim.opt_local.buflisted = false
    vim.opt_local.number = false
    vim.opt_local.relativenumber = false
  end,
})

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
-- 4. НАСТРОЙКА ПЛАГИНОВ
-- ============================================================================
local ok_cat, _ = pcall(require, "catppuccin")
if ok_cat then vim.cmd.colorscheme("catppuccin-mocha") end

local ok_lua, lualine = pcall(require, "lualine")
if ok_lua then lualine.setup({ options = { globalstatus = true, theme = "auto" } }) end

local cmp_status_ok, cmp = pcall(require, "cmp")
if cmp_status_ok then
  pcall(require("luasnip.loaders.from_vscode").lazy_load)
  cmp.setup({
    snippet = {
      expand = function(args)
        require("luasnip").lsp_expand(args.body)
      end,
    },
    mapping = cmp.mapping.preset.insert({
      ["<C-b>"] = cmp.mapping.scroll_docs(-4),
      ["<C-f>"] = cmp.mapping.scroll_docs(4),
      ["<CR>"] = cmp.mapping.confirm({ select = true }),
      ["<Tab>"] = cmp.mapping(function(fallback)
        if cmp.visible() then
          cmp.select_next_item()
        elseif require("luasnip").expand_or_jumpable() then
          vim.fn.feedkeys(vim.api.nvim_replace_termcodes("<Plug>luasnip-expand-or-jump", true, true, true), "")
        else
          fallback()
        end
      end, { "i", "s" }),
    }),
    sources = cmp.config.sources(
      { { name = "nvim_lsp" }, { name = "luasnip" } },
      { { name = "buffer" } }
    ),
    completion = { keyword_length = 1, trigger_character = { "." } },
  })
end

local ok_lsp, mason_lsp = pcall(require, "mason-lspconfig")
if ok_lsp then
  require("mason").setup()
  mason_lsp.setup({
    ensure_installed = { "pyright", "ruff", "bashls" },
    automatic_installation = true,
  })
  local capabilities = vim.lsp.protocol.make_client_capabilities()
  if cmp_status_ok then
    capabilities = require("cmp_nvim_lsp").default_capabilities(capabilities)
  end
  for _, server in ipairs({ "pyright", "ruff", "bashls" }) do
    local config = { capabilities = capabilities }
    if server == "pyright" then
      config.settings = {
        python = {
          analysis = {
            autoSearchPaths = true,
            diagnosticMode = "workspace",
            typeCheckingMode = "basic",
          },
        },
      }
    end
    vim.lsp.config(server, config)
    vim.lsp.enable(server)
  end

  -- Горячие клавиши LSP
  vim.api.nvim_create_autocmd("LspAttach", {
    callback = function(args)
      local bufnr = args.buf
      local map = function(mode, lhs, rhs, desc)
        vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, silent = true, desc = desc })
      end
      map("n", "gd", vim.lsp.buf.definition, "Перейти к определению")
      map("n", "gr", vim.lsp.buf.references, "Найти ссылки")
      map("n", "gI", vim.lsp.buf.implementation, "Перейти к реализации")
      map("n", "K", function()
        vim.lsp.buf.hover({
          border = "rounded",
          max_width = 500,
          max_height = 40,
        })
      end, "Документация")
      map("n", "<leader>ca", vim.lsp.buf.code_action, "Действия кода")
      -- <leader>r НЕ переопределяем здесь — он уже задан в секции 6 (MyMemory)
    end,
  })
end

local ok_bufferline, bufferline = pcall(require, "bufferline")
if ok_bufferline then
  bufferline.setup({
    options = {
      mode = "buffers",
      separator_style = "slant",
      always_show_bufferline = true,
      offsets = {
        { filetype = "NvimTree", text = "File Explorer", text_align = "center", separator = true },
      },
    },
  })
end

vim.diagnostic.config({ virtual_text = false, signs = true, underline = true, severity_sort = true })

-- ============================================================================
-- 5. ПЕРЕВОДЧИК (MyMemory API)
-- ============================================================================
local function mymemory_translate(text, source_lang, target_lang, callback)
  local langpair = source_lang .. "|" .. target_lang
  local encoded_text = vim.uri_encode(text)
  local encoded_pair = vim.uri_encode(langpair)
  local url = string.format(
    "https://api.mymemory.translated.net/get?q=%s&langpair=%s&de=%s",
    encoded_text, encoded_pair, vim.uri_encode("nach10@mail.ru")
  )

  vim.fn.jobstart({ "curl", "-s", "-L", "--max-time", "15", url }, {
    on_stdout = function(_, data)
      if not data or #data == 0 then callback(nil) return end
      local raw = table.concat(data, "\n")
      local ok, json = pcall(vim.json.decode, raw)
      if ok and json and json.responseData and json.responseData.translatedText then
        callback(json.responseData.translatedText)
      else
        callback(nil)
      end
    end,
    on_exit = function(_, code) if code ~= 0 then callback(nil) end end,
  })
end

local function detect_direction(text)
  if text:find("[а-яА-ЯёЁ]") then return "ru", "en" else return "en", "ru" end
end

local function show_translation_window(src, tgt, translated)
  local buf = vim.api.nvim_create_buf(false, true)
  local lines = { " Перевод:", "" }
  for line in translated:gmatch("[^\n]+") do table.insert(lines, " " .. line) end
  local win_id = vim.api.nvim_open_win(buf, true, {
    relative = "cursor", row = 1, col = 0,
    width = math.min(#translated + 4, 75),
    height = #lines + 1,
    style = "minimal", border = "rounded",
    title = string.format(" [%s → %s] ", src:upper(), tgt:upper()),
    title_pos = "center",
  })
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.defer_fn(function()
    if vim.api.nvim_win_is_valid(win_id) then vim.api.nvim_win_close(win_id, true) end
    if vim.api.nvim_buf_is_valid(buf) then vim.api.nvim_buf_delete(buf, {}) end
  end, 10000)
end

local function translate_current_diagnostic()
  local line_diagnostics = vim.diagnostic.get(0, { lnum = vim.fn.line(".") - 1 })
  if #line_diagnostics == 0 then print("Диагностик не найдено") return end
  table.sort(line_diagnostics, function(a, b) return a.severity < b.severity end)
  mymemory_translate(line_diagnostics[1].message or "", "en", "ru", function(translated)
    if translated then vim.schedule(function() show_translation_window("en", "ru", translated) end) end
  end)
end

local function get_visual_selection()
  local start_pos, end_pos = vim.fn.getpos("'<"), vim.fn.getpos("'>")
  local lines = vim.fn.getline(start_pos[2], end_pos[2])
  if #lines == 0 then return nil end
  if #lines == 1 then return string.sub(lines[1], start_pos[3], end_pos[3]) end
  lines[1] = string.sub(lines[1], start_pos[3])
  lines[#lines] = string.sub(lines[#lines], 1, end_pos[3])
  return table.concat(lines, "\n")
end

local function translate_visual_and_replace()
  local text = get_visual_selection()
  if not text then print("Ничего не выделено") return end
  local src, tgt = detect_direction(text)
  mymemory_translate(text, src, tgt, function(translated)
    if not translated then print("Не удалось перевести") return end
    vim.schedule(function()
      vim.cmd("normal! gv")
      local keys = vim.api.nvim_replace_termcodes("c" .. translated .. "<Esc>", true, false, true)
      vim.api.nvim_feedkeys(keys, "n", false)
    end)
  end)
end

local function translate_visual_show()
  local text = get_visual_selection()
  if not text then print("Ничего не выделено") return end
  local src, tgt = detect_direction(text)
  mymemory_translate(text, src, tgt, function(translated)
    if translated then vim.schedule(function() show_translation_window(src, tgt, translated) end) end
  end)
end

local function translate_word_under_cursor_show()
  local word = vim.fn.expand("<cword>")
  if word == "" then print("Нет слова под курсором") return end
  local src, tgt = detect_direction(word)
  mymemory_translate(word, src, tgt, function(translated)
    if translated then vim.schedule(function() show_translation_window(src, tgt, translated) end) end
  end)
end

local function translate_word_under_cursor_replace()
  local word = vim.fn.expand("<cword>")
  if word == "" then print("Нет слова под курсором") return end
  local src, tgt = detect_direction(word)
  mymemory_translate(word, src, tgt, function(translated)
    if not translated then print("Не удалось перевести") return end
    vim.schedule(function()
      local keys = vim.api.nvim_replace_termcodes("ciw" .. translated .. "<Esc>", true, false, true)
      vim.api.nvim_feedkeys(keys, "n", false)
    end)
  end)
end

-- ============================================================================
-- 6. ГОРЯЧИЕ КЛАВИШИ
-- ============================================================================
local function map(mode, lhs, rhs, desc)
  vim.keymap.set(mode, lhs, rhs, { silent = true, desc = desc })
end

map("n", "<leader>dt", function() require("dap").terminate() end, "Остановить отладку")
map("n", "<leader>e", ":NvimTreeToggle<CR>", "Дерево файлов")
map("n", "<leader>ff", ":Telescope find_files<CR>", "Поиск файлов")
map("n", "<leader>w", ":w<CR>", "Сохранить")
map("n", "<leader>q", ":q<CR>", "Закрыть")
map("n", "<Tab>", ":bnext<CR>", "Следующий буфер")
map("n", "<S-Tab>", ":bprevious<CR>", "Предыдущий буфер")

map("n", "<A-1>", "<Cmd>BufferLineGoToBuffer 1<CR>", "Буфер 1")
map("n", "<A-2>", "<Cmd>BufferLineGoToBuffer 2<CR>", "Буфер 2")
map("n", "<A-3>", "<Cmd>BufferLineGoToBuffer 3<CR>", "Буфер 3")
map("n", "<A-Left>", "<Cmd>BufferLineCyclePrev<CR>", "Предыдущий буфер")
map("n", "<A-Right>", "<Cmd>BufferLineCycleNext<CR>", "Следующий буфер")
map("n", "<A-w>", "<Cmd>bdelete<CR>", "Закрыть буфер")

map("n", "[d", vim.diagnostic.goto_prev, "Предыдущая ошибка")
map("n", "]d", vim.diagnostic.goto_next, "Следующая ошибка")
map("n", "gl", vim.diagnostic.open_float, "Показать ошибку")
map("n", "<leader>dl", vim.diagnostic.setloclist, "Список ошибок")
map("n", "<leader>gt", translate_current_diagnostic, "Перевести ошибку")

vim.keymap.set("n", "<leader>t", translate_word_under_cursor_show, { silent = true, desc = "Перевести слово" })
vim.keymap.set("n", "<leader>r", translate_word_under_cursor_replace, { silent = true, desc = "Заменить слово" })
vim.keymap.set("v", "<leader>t", translate_visual_show, { silent = true, desc = "Перевести выделение" })
vim.keymap.set("v", "<leader>r", translate_visual_and_replace, { silent = true, desc = "Заменить выделение" })

map("n", "<leader>mk", ":MarkdownPreviewToggle<CR>", "Предпросмотр MD/Mermaid")
map("n", "<leader>fm", function() vim.lsp.buf.format({ async = true }) end, "Форматировать")

map("n", "<leader>x", function()
  vim.cmd("silent! update")
  local ft = vim.bo.filetype
  
  if ft == "python" then
    -- Обычный запуск для Python-файлов
    vim.cmd("botright split | resize 12 | term python3 %")
    vim.defer_fn(function() vim.cmd("wincmd k") end, 50)
  elseif ft == "markdown" then
    -- Умный запуск для Markdown: вытаскиваем только блоки python
    local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
    local python_code = {}
    local in_block = false
    
    for _, line in ipairs(lines) do
      if line:match("^```python") then
        in_block = true
      elseif line:match("^```") and in_block then
        in_block = false
      elseif in_block then
        table.insert(python_code, line)
      end
    end
    
    if #python_code > 0 then
      local tmp = vim.fn.tempname() .. ".py"
      vim.fn.writefile(python_code, tmp)
      vim.cmd("botright split | resize 12 | term python3 " .. vim.fn.fnameescape(tmp))
      vim.defer_fn(function() vim.cmd("wincmd k") end, 50)
    else
      print("В этом Markdown-файле не найдено блоков кода ```python")
    end
  else
    print("Запуск не поддерживается для типа файла: " .. ft)
  end
end, "Запустить код (Python / MD)")

vim.keymap.set("t", "<Esc>", [[<C-\><C-n>]], { silent = true, desc = "Выйти из терминала" })

local function close_terminal_or_clear()
  local found_win, found_buf = nil, nil
  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    local buf = vim.api.nvim_win_get_buf(win)
    if vim.bo[buf].buftype == "terminal" then
      found_win, found_buf = win, buf
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
    vim.cmd("noh")
  end
end
map("n", "<leader>tc", close_terminal_or_clear, "Закрыть терминал")
vim.keymap.set("n", "<Esc>", close_terminal_or_clear, { silent = true, desc = "Закрыть терминал / Сбросить поиск" })

-- Фикс встроенных gc/gcc Neovim 0.10+
for _, mode in ipairs({ "n", "x", "o" }) do
  pcall(vim.keymap.del, mode, "gc")
  pcall(vim.keymap.del, mode, "gcc")
end
vim.keymap.set("n", "gcc", "<Plug>(comment_toggle_linewise_current)", { silent = true, remap = true })
vim.keymap.set("n", "gc", "<Plug>(comment_toggle_linewise)", { silent = true, remap = true })
vim.keymap.set("x", "gc", "<Plug>(comment_toggle_linewise_visual)", { silent = true, remap = true })
-- Настройки для SnipRun
vim.keymap.set("n", "<leader>sr", "<Cmd>SnipRun<CR>", { silent = true, desc = "Запустить строку кода" })
vim.keymap.set("v", "<leader>sr", ":<C-u>SnipRun<CR>", { silent = true, desc = "Запустить выделенный код" })
vim.keymap.set("n", "<leader>sc", "<Cmd>SnipReset<CR>", { silent = true, desc = "Очистить результаты SnipRun" })

-- ============================================================================
-- 7. ОТЛАДЧИК (DAP)
-- ============================================================================
local ok_dap, dap = pcall(require, "dap")
if ok_dap then
  local ok_ui, dapui = pcall(require, "dapui")
  if ok_ui then dapui.setup() end

  local function get_python_path()
    local venv_path = os.getenv("VIRTUAL_ENV")
    if venv_path then return venv_path .. "/bin/python" end
    local cwd = vim.fn.getcwd()
    if vim.fn.executable(cwd .. "/venv/bin/python") == 1 then return cwd .. "/venv/bin/python" end
    if vim.fn.executable(cwd .. "/.venv/bin/python") == 1 then return cwd .. "/.venv/bin/python" end
    if vim.fn.executable("python3") == 1 then return vim.fn.exepath("python3") end
    return "/usr/bin/python3"
  end

  dap.adapters.python = function(cb, config)
    if config.request == "attach" then
      cb({ type = "server", port = assert(config.connect.port), host = config.connect.host or "127.0.0.1" })
    else
      cb({ type = "executable", command = get_python_path(), args = { "-m", "debugpy.adapter" } })
    end
  end

  dap.configurations.python = {
    {
      type = "python",
      request = "launch",
      name = "Launch",
      program = "${file}",
      pythonPath = get_python_path,
      console = "integratedTerminal",
    },
  }

  if ok_ui then
    dap.listeners.after.event_initialized["dapui_config"] = function() dapui.open() end
    dap.listeners.before.event_terminated["dapui_config"] = function() dapui.close() end
    dap.listeners.before.event_exited["dapui_config"] = function() dapui.close() end
  end

  vim.keymap.set("n", "<F5>", function() dap.continue() end, { desc = "Старт / Продолжить" })
  vim.keymap.set("n", "<F10>", function() dap.step_over() end, { desc = "Шаг с обходом" })
  vim.keymap.set("n", "<F11>", function() dap.step_into() end, { desc = "Шаг с заходом" })
  vim.keymap.set("n", "<F12>", function() dap.step_out() end, { desc = "Шаг с выходом" })
  vim.keymap.set("n", "<leader>b", function() dap.toggle_breakpoint() end, { desc = "Точка останова" })
  vim.keymap.set("n", "<leader>dr", function() dap.restart() end, { desc = "Перезапустить" })
  vim.keymap.set("n", "<leader>du", function() if ok_ui then require("dapui").toggle() end end, { desc = "Toggle DAP UI" })
end

-- ============================================================================
-- 8. НАВИГАЦИЯ CTRL + СТРЕЛКИ
-- ============================================================================
local function win_nav(mode, key, cmd)
  vim.keymap.set(mode, key, cmd, { silent = true })
end

win_nav("n", "<C-Up>", "<C-w>k")
win_nav("n", "<C-Down>", "<C-w>j")
win_nav("n", "<C-Left>", "<C-w>h")
win_nav("n", "<C-Right>", "<C-w>l")

win_nav("v", "<C-Up>", "<C-w>k")
win_nav("v", "<C-Down>", "<C-w>j")
win_nav("v", "<C-Left>", "<C-w>h")
win_nav("v", "<C-Right>", "<C-w>l")

vim.keymap.set("i", "<C-Up>", "<C-Up>", { noremap = true })
vim.keymap.set("i", "<C-Down>", "<C-Down>", { noremap = true })
vim.keymap.set("i", "<C-Left>", "<C-Left>", { noremap = true })
vim.keymap.set("i", "<C-Right>", "<C-Right>", { noremap = true })
