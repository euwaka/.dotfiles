---------------------
-- Neovim Settings -- 
---------------------
vim.g.mapleader = " "

local map  = vim.keymap.set
local opts = { noremap = true, silent = true }
local opt  = vim.opt

map("n", "<leader>cs", ":source $MYVIMRC<CR>", opts)
map("n", "<leader>cc", ":e $MYVIMRC<CR>", opts)
map("n", "td", function() vim.cmd("edit /home/horki/docs/log.md") end)
map("n", "<leader>cd", ":noh <CR>", opts)

opt.number         = true
opt.relativenumber = true
opt.termguicolors  = true
opt.expandtab      = true  -- spaces instead of tabs
opt.shiftwidth     = 4     -- 4 spaces per indent
opt.tabstop        = 4
opt.smartindent    = true
opt.laststatus     = 0     -- disable statusline
opt.updatetime     = 300   -- reduce update time
vim.g.transparency = 0.7

vim.api.nvim_create_autocmd("ColorScheme", {
    pattern = "*",
    callback = function() 
        vim.cmd [[
            highlight Normal guibg=none
            highlight NonText guibg=none
            highlight Normal ctermbg=none
            highlight NonText ctermbg=none
            highlight CursorLine guibg=none ctermbg=none
        ]]
    end
})



---------------------------------
-- Project and Task Management --
---------------------------------
vim.g.current_project = nil
local db = {
    path = "/home/horki/projects/",
    projects = {
        -- "true" github projects
        "rayit", "introGraphics", "intro-ads", "bfcpu", "ThyroCare_project", "audan",
        
        -- hardlinked probe projects
        "OpenGL",

        -- other projects
        ".dotfiles",
    },
}

local select_from = function(data, callback, arg)
    local pickers = require "telescope.pickers"
    local finders = require "telescope.finders"
    local conf    = require("telescope.config").values
    local actions = require "telescope.actions"
    local action_state = require "telescope.actions.state"

    pickers.new({}, {
        finder = finders.new_table {
            results = data 
        },
        sorter = conf.generic_sorter({}),
        attach_mappings = function(prompt_bufnr, map)
            actions.select_default:replace(function()
                actions.close(prompt_bufnr)
                local selection = action_state.get_selected_entry()
                callback(selection[1], arg)
            end)
            return true
        end,
    }):find()
end

local switch_to = function(project, path)
    local project_path = path .. project 

    vim.api.nvim_set_current_dir(project_path)
    vim.cmd.edit(project_path)
    vim.g.current_project = project 

    print("Switched to " .. project_path)
end

local function parse_actions(path)
    -- parse actions.lua file under the given path

    local scan = require 'plenary.scandir'

    -- check whether actions.lua exists under path
    local file = scan.scan_dir(path, { search_pattern = "actions.lua", depth = 1 })[1]
    if not file then
        print("No actions.lua at " .. path)
        return nil
    end

    -- evaluate actions.lua assuming it has valid format
    local actions = dofile(file)
    
    return actions
end

local function needs_tty(cmd)
    -- checks whether the commands needs tty
    local tty_cmds = { "kitten icat", "make preview" }

    for _, term in ipairs(tty_cmds) do
        if cmd:find(term) then
            return true
        end
    end

    return false
end

local function run_in_terminal_smart(cmd)
    -- runs the command either in tmux or floating terminal

    if needs_tty(cmd) then
        local cmd = string.format(
            "tmux split-window -v 'cd %s && %s; exec $SHELL'",
            vim.fn.getcwd(),
            cmd
        )
        os.execute(cmd)
    else
        vim.cmd(":TermExec direction=float cmd=\"" .. cmd .. "\"") 
    end
end

local function parse_action_cmd(actions, action_name)
    for _, action in ipairs(actions) do
        if action.name == action_name then
            return action.cmd
        end
    end

    return nil
end

local function exec_actions()
    if not vim.g.current_project then
        print("Project is nil.")
        return
    end

    -- import actions
    local path = db.path .. vim.g.current_project
    local actions = parse_actions(path)
    if not actions then
        print("No actions in " .. vim.g.current_project)
        return
    end

    -- run action
    select_from(
        vim.tbl_map(function(entry) return entry.name end, actions),
        function(action_name)
            local cmd = parse_action_cmd(actions, action_name)
            run_in_terminal_smart(cmd)
        end,
        nil
    )
end

map("n", "<leader>pp", function() select_from(db.projects, switch_to, db.path) end, opts)
map("n", "<leader>pe", exec_actions, opts)

-- Floating Terminal -- 
map("n", "tt", function()
    local phrases = {
        "Damn you are sexy, Artur...",
        "Why are you opening a terminal emulator inside vim inside kitty?",
        "Remember, you are you.",
        "You can do it.",
        "ssh is not secure, buddy",
        "I am just me, and I can tackle any obstacle since I can do literally anything given time.",
        "Maybe switch to IDE or vscode?", 
        "Still no Mini?",
        "You can deliberately improve any skill if you actually want to.",
        "Given enough time, you can surpass almost anyone in anything.",
        "Motherfucker",
    }
    local phrase = phrases[ math.random( #phrases ) ]
    vim.cmd(string.format(":TermExec direction=float cmd=\"clear; echo %s\"", phrase))
end) 




---------------------
-- Tags Management --
---------------------
vim.opt.tags = { "./tags;" }
map("n", "gd", "<C-]>", opts)
map("n", "gb", "<C-t>", opts)
map("n", "<leader>gt", function()
    local tag_functions = {
        { label="C", cmd="ctags -R . /usr/include/"},
        { label="ESP32 C/C++", cmd="ctags -R . /usr/include/ ~/repos/esp/esp-idf/components/"},
    }

    local labels = {}
    for _, choice in ipairs(tag_functions) do
        table.insert(labels, choice.label)
    end

    vim.ui.select(
        labels, 
        {prompt = "Select language for tags generation: "},
        function(selected)
            local found = "false"
            for _, choice in ipairs(tag_functions) do
                if choice.label == selected then
                    vim.fn.jobstart(choice.cmd, { detach = true })
                    vim.notify("Running tags for " .. selected .. ": " .. choice.cmd)
                    found = "true"
                    break
                end
            end

            if found == "false" then  
                vim.notify("WARNING: No tags generation action for " .. selected)
            end
        end
    )
end, opts)




-------------
-- Plugins --
-------------
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

require("lazy").setup{
    {
	       "ThePrimeagen/harpoon",
	       branch = "harpoon2",
	       dependencies = { "nvim-lua/plenary.nvim" },
	       config = function()
	           local harpoon = require("harpoon")
	           harpoon:setup()

	           map("n", "<leader>a", function() harpoon:list():add() end)
	           map("n", "<C-e>", function() harpoon.ui:toggle_quick_menu(harpoon:list()) end)
	           map("n", "<leader>1", function() harpoon:list():select(1) end)
	           map("n", "<leader>2", function() harpoon:list():select(2) end)
	           map("n", "<leader>3", function() harpoon:list():select(3) end)
	           map("n", "<leader>4", function() harpoon:list():select(4) end)
	           map("n", "<leader>5", function() harpoon:list():select(5) end)
    	end,
	},
    {
        "stevearc/oil.nvim",
        config = function()
            require("oil").setup({
                default_file_explorer = true,
                columns = {
                    "icon",
                    -- "size"
                },
                keymaps = {
                    ["<CR>"]  = {"actions.select"},
                    ["g?"]    = {"actions.show_help", mode="n"},
                    ["<C-v>"] = {"actions.select", opts={ vertical = true, noremap = true }},
                    ["<C-h>"] = {"actions.select", opts={ horizontal = true }},
                    ["<C-p>"] = {"actions.preview"},
                    ["<C-r>"] = {"actions.refresh"},
                    ["-"]     = {"actions.parent", mode="n"},
                    ["gs"]    = {"actions.change_sort", mode="n"},
                    ["gx"]    = {"actions.open_external"},
                    ["g."]    = {"actions.toggle_hidden", mode="n"}
                },
                use_default_keymaps = false,
                delete_to_trash = true,
                view_options = {
                    show_hidden = true
                }
            })
            map("n", "<leader>e", "<CMD>Oil<CR>", { desc = "Open parent directory" }, opts)
        end
    },
    {
        "nvim-telescope/telescope.nvim",
        dependencies = { "nvim-lua/plenary.nvim" },
        config = function()
            local actions = require("telescope.actions")
            require("telescope").setup {
                defaults = {
                    mappings = {
                        i = {
                            ["<C-j>"] = actions.move_selection_next,
                            ["<C-k>"] = actions.move_selection_previous,
                        },
                    }
                },
                pickers = {
                    find_files = {
                        hidden = true,
                    },
                },
            }

            -- Keybindings for opening Telescope pickers
            map('n', '<leader>ff', '<cmd>Telescope find_files<CR>', opts)
            map('n', '<leader>fg', '<cmd>Telescope live_grep<CR>', opts)
            map('n', '<leader>fb', '<cmd>Telescope buffers<CR>', opts)
            map('n', '<leader>fh', '<cmd>Telescope help_tags<CR>', opts)
            map('n', '<leader>fm', '<cmd>Telescope man_pages<CR>', opts)
            map('n', '<leader>ft', '<cmd>Telescope tags<CR>', opts)
            map('n', '<leader>fs', '<cmd>Telescope treesitter<CR>', opts)
        end,
    },
    {
        "christoomey/vim-tmux-navigator",
        config = function()
            map('n', '<C-h>', '<cmd>TmuxNavigateLeft<cr>', opts)
            map('n', '<C-j>', '<cmd>TmuxNavigateDown<cr>', opts)
            map('n', '<C-k>', '<cmd>TmuxNavigateUp<cr>', opts)
            map('n', '<C-l>', '<cmd>TmuxNavigateRight<cr>', opts)
        end
    },
    {
        "nvim-treesitter/nvim-treesitter",
        run = ":TSUpdate", -- to update parsers
        config = function()
            require("nvim-treesitter.configs").setup {
                ensure_installed = {"lua", "c", "cpp", "python", "bash", "java"},
                highlight = { enable = true },
                indent = { enable = true },
                matchup = { enable = true },
                autotag = { enable = true }
            }
        end
    },
    {
        "catppuccin/nvim",
        priority=1000,
        name="catppuccin",
        config = function()
            require("catppuccin").setup({
                flavour = "mocha",
                transparent_background = true,
                show_end_of_buffer = false,
                term_colors = false,
                no_italic = false,
                no_bold = false,
                no_underline = false
            })

            vim.cmd.colorscheme "catppuccin"
        end
    },
    {'akinsho/toggleterm.nvim', version = "*", config = true},
    {
        "iamcco/markdown-preview.nvim",
        cmd = { "MarkdownPreviewToggle", "MarkdownPreview", "MarkdownPreviewStop" },
        ft = { "markdown" },
        build = "cd app && npm install",
        init = function()
            vim.g.mkdp_filetypes = { "markdown" }
        end,
    },
    {
        "karb94/neoscroll.nvim",
        config = function()
            neoscroll = require('neoscroll')
            local keymap = {
                ["<C-p>"] = function() neoscroll.ctrl_u({ duration = 250 }) end;
                ["<C-n>"] = function() neoscroll.ctrl_d({ duration = 250 }) end;
                ["<C-b>"] = function() neoscroll.ctrl_b({ duration = 450 }) end;
                ["<C-f>"] = function() neoscroll.ctrl_f({ duration = 450 }) end;
            }
            local modes = { 'n', 'v', 'x' }
            for key, func in pairs(keymap) do
                vim.keymap.set(modes, key, func)
            end
        end,
    },
    {
        'stevearc/aerial.nvim',
        dependencies = { "nvim-treesitter/nvim-treesitter" },
        config = function()
            require("aerial").setup({
                on_attach = function(bufnr)
                    map("n", "{", "<cmd>AerialPrev<CR>", { buffer = bufnr })
                    map("n", "}", "<cmd>AerialNext<CR>", { buffer = bufnr })
                end,
            })

            map("n", "<leader>a", "<cmd>AerialToggle!<CR>")
        end,
    },
}
