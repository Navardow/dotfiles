vim.g.mapleader = " "
vim.keymap.set("n", "<leader>pv", vim.cmd.Ex)

-- omg my baby alt-up/down. move highlighted text around
vim.keymap.set("v", "J", ":m '>+1<CR>gv=gv")
vim.keymap.set("v", "K", ":m '<-2<CR>gv=gv")

vim.keymap.set("n", "J", "mzJ`z")

-- page up and down
vim.keymap.set("n", "<C-d>", "<C-d>zz")
vim.keymap.set("n", "<C-u>", "<C-u>zz")

-- next and previous
vim.keymap.set("n", "n", "nzzzv")
vim.keymap.set("n", "N", "Nzzzv")

-- greatest remap ever - pasting over text without losing whats in the yank buffer.
vim.keymap.set("x", "<leader>p", [["_dP]])

-- next greatest remap ever : asbjornHaland
vim.keymap.set({ "n", "v" }, "<leader>y", [["+y]])
vim.keymap.set("n", "<leader>Y", [["+Y]])

-- deletes without copying to buffer, dont affect clipboard
vim.keymap.set({ "n", "v" }, "<leader>d", [["_d]])

-- lsp buffer format
vim.keymap.set("n", "<leader>f", vim.lsp.buf.format)

vim.keymap.set("n", "Q", "<nop>")

-- naivgate errors up and down
vim.keymap.set("n", "<C-k>", "<cmd>cnext<CR>zz")
vim.keymap.set("n", "<C-j>", "<cmd>cprev<CR>zz")

-- go to next and previous items - errors, warnings, lsp diagnostics, lint results
vim.keymap.set("n", "<leader>k", "<cmd>lnext<CR>zz")
vim.keymap.set("n", "<leader>j", "<cmd>lprev<CR>zz")

-- search words under a cursor and able to replace all instances
vim.keymap.set("n", "<leader>s", [[:%s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>]])

-- make current excecutable
vim.keymap.set("n", "<leader>x", "<cmd>!chmod +x %<CR>", { silent = true })

vim.keymap.set("n", "<leader><leader>", function()
    vim.cmd("so")
end)


-- screen splitting in vim
vim.keymap.set("n", "<leader>|", "<cmd>vsplit<CR>");
vim.keymap.set("n", "<leader>-", "<cmd>split<CR>");

--navigating windows Alt + hjkl to move between splits
vim.keymap.set("n", "<M-h>", "<C-w>h") 
vim.keymap.set("n", "<M-j>", "<C-w>j")
vim.keymap.set("n", "<M-k>", "<C-w>k")
vim.keymap.set("n", "<M-l>", "<C-w>l")
