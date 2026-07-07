-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

local map = vim.keymap.set

-- ── insert mode ──────────────────────────────────────────────────────────
map("i", "jk", "<Esc>", { desc = "Exit Insert Mode" })
map("i", "kj", "<Esc>", { desc = "Exit Insert Mode" })
map("i", "<C-s>", "<cmd>w<cr><Esc>", { desc = "Save File" })

-- ── centered scrolling (ported from your Zed ctrl-j/ctrl-k half-page+center setup) ──
map("n", "<C-d>", "<C-d>zz", { desc = "Scroll Down (Centered)" })
map("n", "<C-u>", "<C-u>zz", { desc = "Scroll Up (Centered)" })
map("n", "<C-j>", "<C-d>zz", { desc = "Scroll Down (Centered)" })
map("n", "<C-k>", "<C-u>zz", { desc = "Scroll Up (Centered)" })

-- centered search cycling
map("n", "n", "nzzzv", { desc = "Next Search Result (Centered)" })
map("n", "N", "Nzzzv", { desc = "Prev Search Result (Centered)" })

-- ── faster vertical movement ─────────────────────────────────────────────
map({ "n", "v" }, "J", "5j", { desc = "Down Faster" })
map({ "n", "v" }, "K", "5k", { desc = "Up Faster" })
-- move the originals (join lines / hover) under leader since J/K are remapped above
map({ "n", "v" }, "<leader>j", "J", { desc = "Join Lines" })
map({ "n", "v" }, "<leader>k", "K", { desc = "Keyword/Hover" })

-- ── editing ───────────────────────────────────────────────────────────────
map("x", "<leader>p", '"_dP', { desc = "Paste Without Yanking" })
map({ "n", "v" }, "<leader>d", '"_d', { desc = "Delete Without Yanking" })
map("n", "<Esc>", "<cmd>noh<cr>", { desc = "Clear Search Highlight" })

-- ── window resizing ───────────────────────────────────────────────────────
map("n", "<C-Up>", "<cmd>resize +2<cr>", { desc = "Resize Split Up" })
map("n", "<C-Down>", "<cmd>resize -2<cr>", { desc = "Resize Split Down" })

-- ── terminal splits (using <leader>T to avoid LazyVim's existing <leader>t prefix) ──
map("n", "<leader>Th", "<cmd>split | terminal<cr>", { desc = "Terminal (Horizontal Split)" })
map("n", "<leader>Tv", "<cmd>vsplit | terminal<cr>", { desc = "Terminal (Vertical Split)" })

-- ── themery ──────────────────────────────────────────────────────────────
map("n", "<leader>tt", "<cmd>Themery<cr>", { desc = "Theme Picker (Themery)" })


-- ── tabs: Ctrl+1..9 jumps directly to tab N ─────────────────────────────────
map("n", "<C-t>", "<cmd>tabnew<cr>", { desc = "New Tab" })
for i = 1, 9 do
  map("n", "<C-" .. i .. ">", "<cmd>tabnext " .. i .. "<cr>", { desc = "Go to Tab " .. i })
end
map("n", "<C-w>", "<cmd>tabclose<cr>", { desc = "Close Tab" })
