return {
	{
		"windwp/nvim-ts-autotag",
		event = "InsertEnter",
		dependencies = { "nvim-treesitter/nvim-treesitter" },
		opts = {
			autotag = {
				enable = true,
				enable_close = true,
				enable_rename = true,
				enable_close_on_slash = false,
			},
		},
	},
}
