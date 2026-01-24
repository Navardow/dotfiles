return {
	'nvim-telescope/telescope.nvim', tag = '0.1.8',
	-- or                              , branch = '0.1.x',
	dependencies = { 'nvim-lua/plenary.nvim' },
	config = function()
		require("telescope").setup({})

		local builtin = require('telescope.builtin')

		--keymaps
		vim.keymap.set('n', '<leader>pf', builtin.find_files, { desc = 'Telescope project files' })
		vim.keymap.set('n', '<C-p>', builtin.git_files, { desc = 'Telescope git files' })
		vim.keymap.set('n', '<leader>ps', function()
			builtin.grep_string({ search = vim.fn.input("Grep > ") })
		end, {desc = "Telescope grep string" })
	end,
}
