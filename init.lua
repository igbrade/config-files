-- https://github.com/nvim-lua/kickstart.nvim/blob/master/init.lua
vim.o.title = true -- Needs $env:TERM="xterm-256color"
vim.o.number = true
vim.o.showmode = false
vim.o.breakindent = true
vim.o.termguicolors = true
vim.opt.splitright = true
vim.opt.splitbelow = true
vim.opt.list = true
vim.opt.listchars = { tab = '» ', trail = '·', nbsp = '␣' }
vim.opt.signcolumn = "yes"
vim.opt.scrolloff = 5
vim.opt.ignorecase = true

vim.g.have_nerd_font = true
local pmenu_hl = vim.api.nvim_get_hl(0, {name="Pmenu"})
pmenu_hl.bg = "gray15"
vim.api.nvim_set_hl(0, "Pmenu", pmenu_hl)

vim.api.nvim_create_autocmd("TextYankPost", {
	group = vim.api.nvim_create_augroup("highlight-yank", { clear = true }),
	callback = function()
		vim.highlight.on_yank()
	end
})

local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
	vim.fn.system({
		"git",
		"clone",
		"--filter=blob:none",
		"https://github.com/folke/lazy.nvim.git",
		"--branch=stable", -- latest stable release
		lazypath,
	})
end
vim.opt.rtp:prepend(lazypath)
require("lazy").setup({
	{
		'nvim-treesitter/nvim-treesitter',
		dependencies = {
			'nvim-treesitter/nvim-treesitter-context'
		},
		build = ':TSUpdate',
		opts = {
			ensure_installed = { 'cpp', 'lua', 'python', 'vim', 'vimdoc', 'json' },
			highlight = { enable = true },
			indent = { enable = true }
		},
		config = function(_, opts)
			require('nvim-treesitter.configs').setup(opts)
		end,
	},
	{
		'folke/todo-comments.nvim',
		event = 'VimEnter',
		dependencies = { 'nvim-lua/plenary.nvim' },
		opts = {}
	},
	{
		'hiphish/rainbow-delimiters.nvim'
	},
	{
		'windwp/nvim-autopairs',
		event = "InsertEnter",
		config = true
	},
	{
		'fedepujol/move.nvim',
		opts = {},
		config = function(_, opts)
			require('move').setup(opts)
			local opts = { noremap = true, silent = true }
			-- Normal-mode commands
			vim.keymap.set('n', '<A-DOWN>', ':MoveLine(1)<CR>', opts)
			vim.keymap.set('n', '<A-UP>', ':MoveLine(-1)<CR>', opts)
			-- Visual-mode commands
			vim.keymap.set('v', '<A-DOWN>', ':MoveBlock(1)<CR>', opts)
			vim.keymap.set('v', '<A-UP>', ':MoveBlock(-1)<CR>', opts)
		end
	},
	{
		'nvim-lualine/lualine.nvim',
		dependencies = { 'nvim-tree/nvim-web-devicons' },
		opts = {
			sections = {
				lualine_c = {'%r', 'filename', lualine_location},
				lualine_z = {'location', '%V'}
			}
		}
	},
	{
		'neovim/nvim-lspconfig',
		dependencies = {
			{ 'j-hui/fidget.nvim', opts = {} },
			{ 'folke/neodev.nvim', opts = {} }
		},
		config = function()
			local capabilities = vim.lsp.protocol.make_client_capabilities()
			capabilities = vim.tbl_deep_extend('force', capabilities, require('cmp_nvim_lsp').default_capabilities())
			--capabilities.textDocument.completion.completionItem.snippetSupport = false
			
			require('lspconfig').clangd.setup{ capabilities = capabilities }
			require('lspconfig').pylsp.setup{ capabilities = capabilities }
			require('lspconfig').lua_ls.setup{
				settings = {
					Lua = {
						completion = {
							callSnippet = "Replace"
						}
					}
				},
				capabilities = capabilities
			}
		end
	},
	{
		'nvim-telescope/telescope.nvim',
		event = 'VimEnter',
		dependencies = {
			{
				'nvim-telescope/telescope-fzf-native.nvim',
				build = 'make',
				cond = function()
					return vim.fn.executable 'make' == 1
				end
			},
			'nvim-lua/plenary.nvim',
			'nvim-telescope/telescope-ui-select.nvim',
			{ 'nvim-tree/nvim-web-devicons', enabled = vim.g.have_nerd_font }
		},
		config = function()
			require('telescope').setup {
				extensions = {
					['ui-select'] = {
						require('telescope.themes').get_dropdown()
					}
				}
			}
			pcall(require('telescope').load_extension, 'fzf')
			pcall(require('telescope').load_extension, 'ui-select')
		end
	},
	{ 'numToStr/Comment.nvim', opts = {} },
	{
		'lewis6991/gitsigns.nvim',
		opts = {
			signs = {
				add = { text = '+' },
				change = { text = '~' },
				delete = { text = '_' },
				topdelete = { text = '‾' },
				changedelete = { text = '~' }
			}
		}
	},
	{
		'hrsh7th/nvim-cmp',
		event = 'InsertEnter',
		dependencies = {
			'hrsh7th/cmp-nvim-lsp',
			'hrsh7th/cmp-path',
			'L3MON4D3/LuaSnip',
			'saadparwaiz1/cmp_luasnip'
		},
		config = function()
			local cmp = require('cmp')
			local luasnip = require('luasnip')
			luasnip.config.setup()

			cmp.setup {
				snippet = {
					expand = function(args)
						luasnip.lsp_expand(args.body)
					end
				},
				mapping = cmp.mapping.preset.insert({
					['<C-Space>'] = cmp.mapping.complete(),
					['<Tab>'] = cmp.mapping.select_next_item(),
					['<S-Tab>'] = cmp.mapping.select_prev_item(),
					['<CR>'] = cmp.mapping.confirm({ select = true }),
					['<C-Right>'] = cmp.mapping(function()
						if luasnip.expand_or_locally_jumpable() then
							luasnip.expand_or_jump()
						end
					end),
					['<C-Left>'] = cmp.mapping(function()
						if luasnip.locally_jumpable(-1) then
							luasnip.jump(-1)
						end
					end)
				}),
				sources = {
					{ name = 'nvim_lsp' },
					{ name = 'luasnip' },
					{ name = 'path' }
				}
			}
		end
	},
	{
		'stevearc/conform.nvim',
		opts = {
			formatters_by_ft = {
				c = { "clang-format" },
				cpp = { "clang-format" },
				python = { "isort", "black" }
			},
			formatters = {
				["clang-format"] = {
					prepend_args = {"-style",'{BasedOnStyle: Microsoft, UseTab: ForIndentation}'}
				}
			}
		},
		config = function(_, opts)
			vim.api.nvim_create_user_command("Format", function(args)
				local range = nil
				if args.count ~= -1 then
					local end_line = vim.api.nvim_buf_get_lines(0, args.line2 - 1, args.line2, true)[1]
					range = {
						start = { args.line1, 0},
						["end"] = { args.line2, end_line:len()}
					}
				end
				require("conform").format({ async = true, lsp_fallback = true, range = range })
			end, { range = true })
			require("conform").setup(opts)
		end
	},
	{
		'stevearc/oil.nvim',
		opts = {
			keymaps = {
				["<A-UP>"] = "actions.parent"
			}
		},
		dependencies = { "nvim-tree/nvim-web-devicons" }
	},
	'tpope/vim-sleuth',
	{
		'nanozuki/tabby.nvim',
		event = 'VimEnter',
		dependencies = 'nvim-tree/nvim-web-devicons',
		config = function()
			require('tabby').setup()
			local lualine = require('lualine')
			require('tabby.tabline').use_preset('tab_only', {
				lualine_theme = lualine.get_config().options.theme
			})
		end
	}
})


