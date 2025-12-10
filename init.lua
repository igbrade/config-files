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
vim.opt.undofile = true
vim.opt.foldmethod = 'expr'
vim.opt.foldexpr = 'v:lua.vim.treesitter.foldexpr()'
vim.opt.foldlevelstart = 99

vim.keymap.set('t', '<ESC><ESC>', '<C-\\><C-n>', { desc = "Exit terminal mode"})

vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

-- vim.cmd.colorscheme "vim"

if vim.fn.has("win32") then
	-- :help shell-powershell
	vim.cmd("let $TERM='dumb'")
	vim.opt.shell = "pwsh"
	vim.opt.shellcmdflag = "-NoLogo -Command $PSStyle.OutputRendering='PlainText';"
	vim.opt.shellxquote = ""
	vim.opt.shellquote = ""

	vim.cmd([[
	ca Hash w !cpp.exe -dD -P -fpreprocessed \| ForEach-Object {$_ -replace '\s+', ''} \| Join-String \| md5sum \| ForEach-Object {$_.Hash.ToLower().Substring(0, 6)}
	]])
end


vim.g.have_nerd_font = true
-- local pmenu_hl = vim.api.nvim_get_hl(0, {name="Pmenu"})
-- pmenu_hl.bg = "gray15"
-- vim.api.nvim_set_hl(0, "Pmenu", pmenu_hl)


-- Very useful when remoting to a headless server
-- Using terminal osc capabilities to provide clipboard handling
-- vim.g.clipboard = {
-- 	name = 'OSC 52',
-- 	copy = {
-- 		['+'] = require('vim.ui.clipboard.osc52').copy('+'),
-- 		['*'] = require('vim.ui.clipboard.osc52').copy('*'),
-- 	},
-- 	paste = {
-- 		['+'] = require('vim.ui.clipboard.osc52').paste('+'),
-- 		['*'] = require('vim.ui.clipboard.osc52').paste('*'),
-- 	}
-- }

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
	spec = {
	{
		'nvim-treesitter/nvim-treesitter',
		dependencies = {
			'nvim-treesitter/nvim-treesitter-context',
			'nvim-treesitter/nvim-treesitter-textobjects'
		},
		build = ':TSUpdate',
		opts = {
			ensure_installed = { 'c', 'cpp', 'diff', 'lua', 'luadoc', 'markdown', 'markdown_inline', 'python', 'vim', 'vimdoc', 'json', 'powershell', 'javascript', 'html', 'yaml', 'go'},
			highlight = { enable = true },
			indent = { enable = true },
			textobjects = {
				select = {
					enable = true,
					keymaps = {
						["af"] = { query = "@function.outer", desc = "Around function" },
						["if"] = { query = "@function.inner", desc = "Inside function"},
						["ip"] = { query = "@parameter.inner", desc = "Inside parameter" },
						["ap"] = { query = "@parameter.outer", desc = "Around parameter"}
					}
				}
			}
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
		'folke/which-key.nvim',
		event = 'VimEnter',
		config = function()
			require('which-key').setup()
		end
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
		event = { "BufReadPre", "BufNewFile" },
		opts = {},
		config = function(_, opts)
			require('move').setup(opts)
			local mapopts = { noremap = true, silent = true }
			-- Normal-mode commands
			vim.keymap.set('n', '<A-DOWN>', ':MoveLine(1)<CR>', mapopts)
			vim.keymap.set('n', '<A-UP>', ':MoveLine(-1)<CR>', mapopts)
			-- Visual-mode commands
			vim.keymap.set('v', '<A-DOWN>', ':MoveBlock(1)<CR>', mapopts)
			vim.keymap.set('v', '<A-UP>', ':MoveBlock(-1)<CR>', mapopts)
		end
	},
	{
		'nvim-lualine/lualine.nvim',
		dependencies = { 'nvim-tree/nvim-web-devicons' },
		opts = {
			options = {
				theme = "ayu_dark"
			},
			sections = {
				lualine_c = {'%r', 'filename', lualine_location},
				lualine_z = {'location', '%V'}
			}
		}
	},
	{
		'neovim/nvim-lspconfig',
		event = { "BufReadPre", "BufNewFile" },
		dependencies = {
			{ 'j-hui/fidget.nvim', opts = {} },
			{ 'Bilal2453/luvit-meta', lazy = true },
			{ 'folke/lazydev.nvim', ft="lua", opts = {
				library = {
					 { path = 'luvit-meta/library', words = { 'vim%.uv' } }
				}
			} },
		},
		config = function()
			local capabilities = vim.lsp.protocol.make_client_capabilities()
			capabilities = vim.tbl_deep_extend('force', capabilities, require('cmp_nvim_lsp').default_capabilities())
			--capabilities.textDocument.completion.completionItem.snippetSupport = false
		
			vim.api.nvim_create_autocmd('LspAttach', {
				group = vim.api.nvim_create_augroup('lsp-attach', { clear = true }),
				callback = function(event)

					vim.keymap.set('n', 'gd', require('telescope.builtin').lsp_definitions, { buffer = event.buf, desc = 'LSP: Goto Definition'})
					vim.keymap.set('n', '<Space>sf', require('telescope.builtin').find_files, { desc = '[S]earch [F]iles'})
					vim.keymap.set('n', '<Space>sg', require('telescope.builtin').live_grep, { desc = '[S]earch [G]rep'})

					local client = vim.lsp.get_client_by_id(event.data.client_id)
					if client and client.server_capabilities.documentHighlightProvider then
						local highlight_augroup = vim.api.nvim_create_augroup('lsp-highlight', { clear = false})
						vim.api.nvim_create_autocmd({'CursorHold', 'CursorHoldI'}, {
							buffer = event.buf,
							group = highlight_augroup,
							callback = vim.lsp.buf.document_highlight
						})
						vim.api.nvim_create_autocmd({'CursorMoved', 'CursorMovedI'}, {
							buffer = event.buf,
							group = highlight_augroup,
							callback = vim.lsp.buf.clear_references
						})

						vim.api.nvim_create_autocmd('LspDetach', {
							group = vim.api.nvim_create_augroup('lsp-detach', {clear = true}),
							callback = function(event2)
								vim.lsp.buf.clear_references()
								vim.api.nvim_clear_autocmds { group = 'lsp-highlight', buffer = event2.buf }
							end
						})
					end

					if client and client.server_capabilities.inlayHintProvider and vim.lsp.inlay_hint then
						vim.keymap.set('n', 'th', function()
							vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled())
						end, { desc = 'Toggle Inlay hints'})
					end
				end
			})

			--FIXME: Clangd for some reason randomly throws an error: Trying to get AST for non added document
			require('lspconfig').clangd.setup{ capabilities = capabilities }
			require('lspconfig').pylsp.setup{ capabilities = capabilities }
			require('lspconfig').lua_ls.setup{
				settings = {
					Lua = {
						completion = {
							callSnippet = "Replace"
						},
					}
				},
				capabilities = capabilities
			}
			require('lspconfig').ts_ls.setup { capabilities = capabilities }
			require('lspconfig').marksman.setup { capabilities = capabilities }
			require('lspconfig').gopls.setup { capabilities = capabilities }
			-- Maybe take a look at marksman https://github.com/artempyanykh/marksman later
			--
			vim.diagnostic.config({ virtual_text = true })
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

			local builtin = require('telescope.builtin')

			vim.keymap.set('n', '<Space>/', function()
				builtin.current_buffer_fuzzy_find(require('telescope.themes').get_dropdown({
					winblend=10,
					previewer=false
				}))
			end, { desc = '[/] Fuzzily search in current buffer' })
		end
	},
	{ 'numToStr/Comment.nvim', opts = {} },
	{
		'lewis6991/gitsigns.nvim',
		event = { "BufReadPost", "BufNewFile", "BufWritePre" },
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
			'L3MON4D3/LuaSnip',
			'saadparwaiz1/cmp_luasnip',
			'hrsh7th/cmp-nvim-lsp',
			'hrsh7th/cmp-path',
			'hrsh7th/cmp-buffer'
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
					{ name = "lazydev" },
					{ name = 'nvim_lsp' },
					{ name = 'luasnip' },
					{ name = 'path' },
					{ name = "buffer" }
				}
			}

			-- cmp.setup.filetype({ "sql" }, {
			-- 	sources = {
			-- 		{ name = "vim-dadbod-completion"},
			-- 		{ name = "buffer"}
			-- 	}
			-- })
		end
	},
	{
		'stevearc/conform.nvim',
		event = 'VeryLazy',
		opts = {
			formatters_by_ft = {
				c = { "clang-format" },
				cpp = { "clang-format" },
				python = { "isort", "black" },
				javascript = {"prettier"}
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
		-- SCP Bug
		-- https://github.com/neovim/neovim/issues/23962
		'stevearc/oil.nvim',
		opts = {
			keymaps = {
				["<A-UP>"] = "actions.parent"
			},
			view_options = {
				show_hidden = true
			},
			win_options = {
				winbar = "%{v:lua.require('oil').get_current_dir()}"
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
	},
	{
		'kylechui/nvim-surround',
		version = "*",
		event = 'VeryLazy',
		opts = {}
	},
	{
		"ej-shafran/compile-mode.nvim",
		event = 'VeryLazy',
		config = function()
			vim.g.compile_mode = {}
		end
	},
	{
		"sindrets/diffview.nvim"
	},
	{
		'tpope/vim-dadbod',
		dependencies = {
			'kristijanhusak/vim-dadbod-ui',
			-- 'kristijanhusak/vim-dadbod-completion'
		}
	},
	-- {
	-- 	'nvim-neo-tree/neo-tree.nvim',
	-- 	dependencies = {
	-- 		"nvim-lua/plenary.nvim",
	-- 		"nvim-tree/nvim-web-devicons", -- not strictly required, but recommended
	-- 		"MunifTanjim/nui.nvim",
	-- 	}
	-- },
	{
		'junegunn/vim-easy-align'
	},
	{ 'akinsho/git-conflict.nvim', version = "*", config = true },
	-- {
	-- 	"iamcco/markdown-preview.nvim",
	-- 	cmd = { "MarkdownPreviewToggle", "MarkdownPreview", "MarkdownPreviewStop" },
	-- 	ft = { "markdown" },
	-- 	build = function() vim.fn["mkdp#util#install"]() end,
	-- }
	{
		"folke/flash.nvim",
		event = "VeryLazy",
		---@type Flash.Config
		opts = {
			modes = {
				search = {
					enabled = true
				}
			}
		},
		-- stylua: ignore
	},
	{
		"catgoose/nvim-colorizer.lua",
		event = "BufReadPre",
		opts = {}
	}
	},
	install = { colorscheme = {"default"}}
})

