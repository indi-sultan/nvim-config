local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"

if not vim.loop.fs_stat(lazypath) then
	vim.fn.system({
		"git",
		"clone",
		"--filter=blob:none",
		"https://github.com/folke/lazy.nvim.git",
		"--branch=stable",
		lazypath,
	})
end

vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
	-- {
	-- 	"folke/tokyonight.nvim",
	-- 	priority = 1000,
	--
	-- 	config = function()
	-- 		vim.cmd.colorscheme("tokyonight")
	-- 	end,
	-- },
	-- {
	-- 	"rebelot/kanagawa.nvim",
	-- 	priority = 1000,
	-- 	config = function()
	-- 		vim.cmd.colorscheme("kanagawa")
	-- 	end,
	-- },
	{
		"catppuccin/nvim",
		name = "catppuccin",
		priority = 1000,
		config = function()
			vim.cmd.colorscheme("catppuccin-mocha")
		end,
	},
	{
		"nvim-treesitter/nvim-treesitter",
		build = ":TSUpdate",

		config = function()
			require("nvim-treesitter").setup({
				ensure_installed = { "c", "cpp", "lua", "vim" },

				highlight = {
					enable = true,
				},
			})
		end,
	},

	{
		"neovim/nvim-lspconfig",

		config = function()
			local capabilities = require("cmp_nvim_lsp").default_capabilities()

			vim.lsp.config("clangd", {
				capabilities = capabilities,
			})
			vim.lsp.enable("clangd")

			vim.keymap.set("n", "K", vim.lsp.buf.hover, {})
			vim.keymap.set("n", "gd", vim.lsp.buf.definition, {})
			vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, {})
		end,
	},
	{
		"hrsh7th/nvim-cmp",
		dependencies = {
			"hrsh7th/cmp-nvim-lsp"
		},

		config = function()
			local cmp = require("cmp")

			cmp.setup({
				mapping = cmp.mapping.preset.insert({
					["<Tab>"] = cmp.mapping.select_next_item(),
					["<S-Tab>"] = cmp.mapping.select_prev_item(),
					["<CR>"] = cmp.mapping.confirm({ select = true}),
				}),
				sources = {
					{ name = "nvim_lsp" },
				},
			})
		end,
	},
	{
		"nvim-telescope/telescope.nvim",
		dependencies = {
			"nvim-lua/plenary.nvim"
		},

		config = function()
			local builtin = require("telescope.builtin")

			vim.keymap.set("n", "<leader>ff", builtin.find_files, {})
			vim.keymap.set("n", "<leader>fg", builtin.live_grep, {})
			vim.keymap.set("n", "<leader>fb", builtin.buffers, {})
			vim.keymap.set("n", "<leader>fh", builtin.help_tags, {})
		end,
	},
	{
		"lewis6991/gitsigns.nvim",

		config = function()
			require("gitsigns").setup()
		end,
	},

	{
		"rcarriga/nvim-dap-ui",
		dependencies = {
			"mfussenegger/nvim-dap",
			"nvim-neotest/nvim-nio",
		},
		
		config = function()
			local dap = require("dap")
			local dapui = require("dapui")

			dapui.setup()

			dap.listeners.before.attach.dapui_config = function()
				dapui.open()
			end

			dap.listeners.before.launch.dapui_config = function()
				dapui.open()
			end

			dap.listeners.before.event_terminated.dapui_config = function()
				dapui.close()
			end

			dap.listeners.before.event_exited.dapui_config = function()
				dapui.close()
			end

		end,
	},

	{
		"mfussenegger/nvim-dap",

		config = function()
			local dap = require("dap")

			-- ===========================
			-- Code lldb adapter
			-- ===========================
			
			dap.adapters.codelldb = {
				type = "server",
				port = "${port}",

				executable = {
					command = "/opt/codelldb/codelldb/extension/adapter/codelldb",
					args = {
						"--port",
						"${port}",
					},
				}
			}
			--======================
			--c/c++ and rust config
			--======================
			dap.configurations.cpp = {
				{
					name = "Launch file",
					type = "codelldb",
					request = "launch",

					program = function()
						return vim.fn.input(
						'Path to executable: ',
						vim.fn.getcwd() .. '/',
						'file'
						)
					end,

					cwd = "${workspaceFolder}",
					stopOnEntry = false,
				},
			}
			dap.configurations.c = dap.configurations.cpp
			dap.configurations.rust = dap.configurations.cpp

			--========================
			--Break point signs
			--========================
			vim.fn.sign_define(
			'DapBreakpoint',
			{
				text = '🔴',
				texthl = '',
				linehl = '',
				numhl = ''
			}
			)

			--=========================
			--keymaps
			--========================
			vim.keymap.set("n", "<leader>c", dap.continue)
			vim.keymap.set("n", "<leader>u", dap.step_over)
			vim.keymap.set("n", "<leader>i", dap.step_into)
			vim.keymap.set("n", "<leader>o", dap.step_out)

			vim.keymap.set("n", "<leader>b", dap.toggle_breakpoint)

			vim.keymap.set("n", "<leader>dr", dap.repl.open)
			vim.keymap.set("n", "<leader>dl", dap.run_last)
			vim.keymap.set("n", "<leader>dq", function() require("dap").terminate() end)
			vim.keymap.set("n", "<leader>du", function() require("dapui").toggle() end)
		end,
	},
	{
		"windwp/nvim-autopairs",
		event = "InsertEnter",
		config = function()
			require("nvim-autopairs").setup({})
		end,
	},
	{        -- ===========================
		 -- plugin for status bar
		 -- ===========================
		"nvim-lualine/lualine.nvim",
		dependencies = {
			"nvim-tree/nvim-web-devicons",
		},

		config = function()

			local function lsp_name()
				local clients = vim.lsp.get_clients({ bufnr = 0 })

				if #clients == 0 then
					return "No LSP"
				end

				return clients[1].name
			end

			local function dap_status()
				local ok, dap = pcall(require, "dap")

				if not ok then
					return ""
				end

				local status = dap.status()

				if status == "" then
					return ""
				end

				return "🐞 " .. status
			end

			local function cmake_build_type()

				local cwd = vim.fn.getcwd()

				local cache = cwd .. "/build/CMakeCache.txt"

				if vim.fn.filereadable(cache) == 0 then
					return ""
				end

				for _, line in ipairs(vim.fn.readfile(cache)) do
					local build_type = line:match("^CMAKE_BUILD_TYPE:STRING=(.+)$")
					if build_type then
						return build_type
					end
				end
				return ""
			end
			require("lualine").setup({
				options = {
					theme = "auto",
					globalstatus = true,
					icons_enabled = false,
					component_separators = "|",
					section_separators = "|",
				},
				sections = {
					lualine_a = {
						"mode",
					},
					lualine_b = {
						"branch",
					},
					lualine_c = {
						{
							"filename",
							path = 3,
						},
					},
					lualine_x = {
						{
							"diagnostics",
							sources = { "nvim_diagnostic" },
						},
						lsp_name,
						dap_status,
						cmake_build_type,
						"filetype",
					},
					lualine_y = {
						"progress",
					},
					lualine_z = {
						"location",
					},
				},
			})
		end,
	},
	{
		--==================
		--multiline comment plugin
		--===================
		"numToStr/Comment.nvim",
		opts = {},
	},

})
