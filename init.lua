vim.opt.number=true
vim.opt.termguicolors=true
--vim.opt.autochdir=true
vim.opt.clipboard="unnamedplus"
vim.opt.tabstop=2
vim.opt.softtabstop=2
vim.opt.shiftwidth=2
vim.opt.expandtab=true
vim.opt.splitbelow=true
vim.opt.splitright=true
vim.opt.ignorecase=true

local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
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
  'rcarriga/nvim-notify',
	'fedepujol/move.nvim',
	{'nvim-treesitter/nvim-treesitter', 
      build = ':TSUpdate',
      dependencies = {
        'nvim-treesitter/nvim-treesitter-textobjects'
      }
  },
  {
      'neovim/nvim-lspconfig',
      dependencies = {
          'williamboman/mason.nvim',
          'williamboman/mason-lspconfig.nvim',
          { 'j-hui/fidget.nvim', opts = {} },
          'folke/neodev.nvim',
      }
  },
	{
		'windwp/nvim-autopairs',
		event = "InsertEnter",
		opts = {} -- this is equalent to setup({}) function
	},
	{ 
		'numToStr/Comment.nvim',
		opts = {}
	},
	-- {
	--	'akinsho/bufferline.nvim',
	--	dependencies = { 'kyazdani42/nvim-web-devicons' },
	--	config = function()
	--		require('bufferline').setup({
	--
	--		})
	--	end
	--},
	"sindrets/diffview.nvim",
  "kyazdani42/nvim-web-devicons",
	{
		'mhartington/formatter.nvim',
		config = function()
			local util = require("formatter.util")

			require("formatter").setup({
				logging = true,
				filetype = {
				}
			})
		end
	},
	{
		'folke/todo-comments.nvim',
		dependencies = { 'nvim-lua/plenary.nvim' },
	},
	{
		'nvim-telescope/telescope.nvim',
		dependencies = { 'nvim-lua/plenary.nvim', { "nvim-telescope/telescope-fzf-native.nvim", build = "make" }, 'nvim-telescope/telescope-file-browser.nvim' },
		cmd='Telescope',
    config = function()
        require("telescope").setup({
            extensions = {
                fzf = {
                    fuzzy = true,
                    override_generic_sorter = true,
                    override_file_sorter = true,
                    case_mode = "smart_case",
                }, 
                file_browser = {
                    hijack_netrw = true,
                }
            }
        })
        require("telescope").load_extension("file_browser")
        require("telescope").load_extension("fzf")
    end
	},
	{
		'hiphish/rainbow-delimiters.nvim',
		config = function()
			local rainbow_delimiters = require("rainbow-delimiters")

			vim.g.rainbow_delimiters = {
				strategy = {
					[""] = rainbow_delimiters.strategy["global"],
					vim = rainbow_delimiters.strategy["local"],
				},
				query = {
					[""] = "rainbow-delimiters",
					lua = "rainbow-blocks",
				},
				highlight = {
					"RainbowDelimiterRed",
					"RainbowDelimiterYellow",
					"RainbowDelimiterBlue",
					"RainbowDelimiterOrange",
					"RainbowDelimiterGreen",
					"RainbowDelimiterViolet",
					"RainbowDelimiterCyan",
				}
			}
		end
	},
  {
      'hrsh7th/nvim-cmp',
      dependencies = {
          'L3MON4D3/LuaSnip',
          'hrsh7th/cmp-nvim-lsp',
          'hrsh7th/cmp-path',

      }
  }
})

local function find_git_root()
  -- Use the current buffer's path as the starting point for the git search
  local current_file = vim.api.nvim_buf_get_name(0)
  local current_dir
  local cwd = vim.fn.getcwd()
  -- If the buffer is not associated with a file, return nil
  if current_file == '' then
    current_dir = cwd
  else
    -- Extract the directory from the current file's path
    current_dir = vim.fn.fnamemodify(current_file, ':h')
  end

  -- Find the Git root directory from the current file's path
  local git_root = vim.fn.systemlist('git -C ' .. vim.fn.escape(current_dir, ' ') .. ' rev-parse --show-toplevel')[1]
  if vim.v.shell_error ~= 0 then
    print 'Not a git repository. Searching on current working directory'
    return cwd
  end
  return git_root
end


local function lint_cur_file()
  local git_root = find_git_root()
  local current_file = vim.api.nvim_buf_get_name(0)
  if git_root then
    local resp = vim.fn.system('cd ' .. git_root .. '; yarn eslint ' .. current_file .. ' --cache --max-warnings=0')
    local lint_errors = vim.fn.split(resp, '\n')
    -- lint_errors = {unpack(lint_errors, 2, #lint_errors-4)}
    -- vim.print(lint_errors)
    vim.cmd("vnew")
    vim.api.nvim_buf_set_lines(0, 0, 0, false, lint_errors)
  end
end

local function lint_cur_file_fix()
  local git_root = find_git_root()
  local current_file = vim.api.nvim_buf_get_name(0)
  if git_root then
    vim.fn.system('cd ' .. git_root .. '; yarn eslint ' .. current_file .. ' --cache --max-warnings=0 --fix')
  end
end

vim.api.nvim_create_user_command("Lint", lint_cur_file, { desc = "Run eslint"})
vim.api.nvim_create_user_command("LintFix", lint_cur_file_fix, { desc = "Run eslint fix"})

vim.api.nvim_set_hl(0, 'Pmenu', { bg = '#171717'})

vim.notify = require("notify")

--Move.nvim keymaps
local opts = { noremap = true, silent = true }
-- Normal-mode commands
vim.keymap.set('n', '<A-DOWN>', ':MoveLine(1)<CR>', opts)
vim.keymap.set('n', '<A-UP>', ':MoveLine(-1)<CR>', opts)
vim.keymap.set('n', '<A-LEFT>', ':MoveHChar(-1)<CR>', opts)
vim.keymap.set('n', '<A-RIGHT>', ':MoveHChar(1)<CR>', opts)
vim.keymap.set('n', '<leader>wf', ':MoveWord(1)<CR>', opts)
vim.keymap.set('n', '<leader>wb', ':MoveWord(-1)<CR>', opts)

-- Visual-mode commands
vim.keymap.set('v', '<A-DOWN>', ':MoveBlock(1)<CR>', opts)
vim.keymap.set('v', '<A-UP>', ':MoveBlock(-1)<CR>', opts)
vim.keymap.set('v', '<A-LEFT>', ':MoveHBlock(-1)<CR>', opts)
vim.keymap.set('v', '<A-RIGHT>', ':MoveHBlock(1)<CR>', opts)

vim.keymap.set('n', '<space>e', vim.diagnostic.open_float)
vim.keymap.set('n', '[d', vim.diagnostic.goto_prev)
vim.keymap.set('n', ']d', vim.diagnostic.goto_next)

vim.defer_fn(function()
    require('nvim-treesitter.configs').setup {
        ensure_installed = {'c', 'cpp', 'lua', 'python', 'typescript', 'vim', 'bash'},
        highlight = { enable = true },
        indent = { enable = true },
    }
end, 0)

vim.api.nvim_create_user_command('SetLocalWorkingDirectory', 'lcd %:p:h', {})

local servers = {
    tsserver = {},
    lua_ls = {
        Lua = {
            workspace = { checkThirdParty = false },
            telemetry = { enable = false },
        }
    } 
}

local on_attach = function(_, bufnr)

end

require("mason").setup()
require("mason-lspconfig").setup()
require("neodev").setup()
local mason_lspconfig = require("mason-lspconfig")
mason_lspconfig.setup {
    ensure_installed = vim.tbl_keys(servers),
}

local capabilities = vim.lsp.protocol.make_client_capabilities()
capabilities = require('cmp_nvim_lsp').default_capabilities(capabilities)

mason_lspconfig.setup_handlers {
    function(server_name)
        require("lspconfig")[server_name].setup {
            capabilities = capabilities,
            on_attach = on_attach,
            settings = servers[server_name],
            filetypes = (servers[server_name] or {}).filetypes,
        }
    end,
}

local cmp = require 'cmp'
local luasnip = require 'luasnip'
require('luasnip.loaders.from_vscode').lazy_load()
luasnip.config.setup {}

cmp.setup {
    snippet = {
      expand = function(args)
        luasnip.lsp_expand(args.body)
      end
    },
    completion = {
        completeopt='menu,menuone,noinsert'
    },
    mapping = cmp.mapping.preset.insert {
        ['<C-Space>'] = cmp.mapping.complete{},
        ['<Tab>'] = cmp.mapping(function(fallback)
            if cmp.visible() then
                cmp.select_next_item()
            else
                fallback()
            end
        end, { 'i', 's' }),
        ['<S-Tab>'] = cmp.mapping(function(fallback)
            if cmp.visible() then
                cmp.select_prev_item()
            else
                fallback()
            end
        end, { 'i', 's'}),
        ['<CR>'] = cmp.mapping.confirm {
            behavior = cmp.ConfirmBehavior.Replace,
            select = true,
        }
    },
    sources = {
        { name = 'nvim_lsp' },
        { name = 'luasnip' },
        { name = 'path' },
    }
}
