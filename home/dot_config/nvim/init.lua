-- lean neovim config: quick edits, not an IDE. plugins via lazy.nvim.

-- leader + disable netrw (nvim-tree replaces it); set before plugins load
vim.g.mapleader = " "
vim.g.maplocalleader = " "
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

-- --- options ---
local o = vim.opt
o.number = true
o.colorcolumn = "80"
o.mouse = "a"
o.termguicolors = true          -- truecolor for dracula
o.clipboard = "unnamedplus"     -- system clipboard via wl-clipboard on wayland
o.expandtab = true
o.shiftwidth = 4                -- indent width
o.softtabstop = 4
o.tabstop = 8                   -- literal tabs (e.g. Makefiles) show as 8
o.list = true
o.listchars = { tab = "→ ", eol = "↲", nbsp = "␣", trail = "•", extends = "⟩", precedes = "⟨" }
o.showbreak = "↪ "
o.foldmethod = "syntax"
o.foldlevelstart = 20
o.foldcolumn = "4"

-- Makefiles need real tabs
vim.api.nvim_create_autocmd("FileType", {
  pattern = "make",
  callback = function() vim.opt_local.expandtab = false end,
})

-- per-repo settings: `git config vim.settings "expandtab sw=4 sts=4"`
local gs = vim.fn.system("git config --get vim.settings"):gsub("%s+$", "")
if vim.v.shell_error == 0 and #gs > 0 then vim.cmd("set " .. gs) end

-- --- keymaps (leader = space; C-o/C-w/C-t keep their vim defaults) ---
local map = vim.keymap.set
map("n", "<leader>n", "<cmd>NvimTreeToggle<cr>", { desc = "file tree" })
map("n", "<leader>t", "<cmd>tabnew<cr>", { desc = "new tab" })
map("n", "<leader>c", "<cmd>lclose<cr>", { desc = "close location list" })
map("n", "<leader>f", function() require("conform").format({ async = true }) end, { desc = "format" })

-- --- plugins (lazy.nvim, bootstrapped on first launch) ---
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  vim.fn.system({ "git", "clone", "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git", "--branch=stable", lazypath })
end
o.rtp:prepend(lazypath)

require("lazy").setup({
  { "Mofiqul/dracula.nvim", priority = 1000, config = function()
      vim.cmd.colorscheme("dracula")
      vim.cmd("hi Normal guibg=NONE ctermbg=NONE")   -- keep terminal transparency
    end },
  { "nvim-tree/nvim-web-devicons", lazy = true },
  { "nvim-lualine/lualine.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    opts = { options = { theme = "auto", globalstatus = true } } },
  { "nvim-tree/nvim-tree.lua",
    dependencies = { "nvim-tree/nvim-web-devicons" }, opts = {} },
  { "kylechui/nvim-surround", event = "VeryLazy", opts = {} },
  { "catgoose/nvim-colorizer.lua", event = "BufReadPre", opts = {} },
  { "stevearc/conform.nvim", opts = {
      formatters_by_ft = { c = { "clang_format" }, cpp = { "clang_format" } } } },
  { "tikhomirov/vim-glsl", ft = "glsl" },
  { "github/copilot.vim" },
}, { change_detection = { notify = false } })
