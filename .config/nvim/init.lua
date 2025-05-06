vim.g.mapleader = " "

local map = vim.keymap.set
local opts = { noremap = true, silent = true }

-- Source config
map("n", "<leader>cs", ":source $MYVIMRC<CR>", opts)
map("n", "<leader>cc", ":e $MYVIMRC<CR>", opts)

local opt = vim.opt

-- UI
opt.number = true
opt.relativenumber = true
opt.cursorline = true
opt.termguicolors = true
opt.background = "dark"

-- Indentation
opt.expandtab   = true     -- spaces instead of tabs
opt.shiftwidth  = 4        -- 4 spaces per indent
opt.tabstop     = 4
opt.smartindent = true

-- Transparency
vim.g.transparency = 0.8
vim.cmd [[
  highlight Normal guibg=none
  highlight NonText guibg=none
  highlight Normal ctermbg=none
  highlight NonText ctermbg=none
  highlight CursorLine guibg=none
]]

-- Disable statusline
opt.laststatus = 0

opt.scrolloff  = 8
opt.signcolumn = "no"
opt.incsearch  = true -- incremental search

-- Disable swap & backup files
opt.swapfile = false
opt.backup = false
opt.writebackup = false

-- Reduce update time
opt.updatetime = 300

-- Project and Task Management
vim.g.current_project = nil
projects = {
    {
        name = "gordon",
        path = "/home/horki/projects/gordon",
        actions = {
            {name = "build", cmd = "cmake -S. -Bbuild/"},
            {name = "clean", cmd = "rm -rf build/"},
            {name = "run",   cmd = "./build/gordon"},
        },
    },
    {
        name = ".dotfiles",
        path = "/home/horki/.dotfiles"
    },
    {
        name = "neovim",
        path = "/home/horki/.dotfiles/.config/nvim",
    }
}

local parse_project = function(proj_name, setting)
    for _, project in ipairs(projects) do
        if project.name == proj_name then
            if setting == "path" then return project.path end
            if setting == "actions" then return project.actions end
        end
    end

    return nil
end

local select_from = function(data, callback)
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
                callback(selection[1])
            end)
            return true
        end,
    }):find()
end

map("n", "<leader>pp", function()
    select_from(
        vim.tbl_map(function(proj) return proj.name end, projects), 
        function(proj_name)
            local path = parse_project(proj_name, "path")
            if path then
                vim.api.nvim_set_current_dir(path)
                vim.cmd.edit(path)
                vim.g.current_project = proj_name
                print("Switched to " .. path)
            else
                print("Project not found: " .. proj_name)
            end
        end)
end, opts)

map("n", "<leader>pe", function()
    if not vim.g.current_project then
        print("Project is nil.") 
        return
    end

    local current = vim.g.current_project
    local actions = parse_project(current, "actions")

    select_from(
        vim.tbl_map(function(entry) return entry.name end, actions),
        function(action_name)
            -- find the command
            for _, entry in ipairs(actions) do
                if entry.name == action_name then
                    -- TODO: perform the action in the floating terminal                    
                    vim.cmd(":TermExec direction=float cmd=\"" .. entry.cmd .. "\"") 
                    break
                end
            end
        end)
end)

-- Setup tags system
vim.o.tags = "./tags"
map("n", "gd", "<C-]>", opts)
map("n", "gb", "<C-t>", opts)
map("n", "<leader>gt", function()
    local tag_functions = {
        { label="C", cmd="ctags -R . /usr/include/"},
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
        config = function()
            require("harpoon").setup()

            local set = vim.api.nvim_set_keymap
            local opts = { noremap = true, silent = true }
            set('n', '<leader>a', '<cmd>lua require("harpoon.mark").add_file()<CR>', opts)
            set('n', '<leader>1', '<cmd>lua require("harpoon.ui").nav_file(1)<CR>', opts)
            set('n', '<leader>2', '<cmd>lua require("harpoon.ui").nav_file(2)<CR>', opts)
            set('n', '<leader>3', '<cmd>lua require("harpoon.ui").nav_file(3)<CR>', opts)
            set('n', '<leader>4', '<cmd>lua require("harpoon.ui").nav_file(4)<CR>', opts)
            set('n', '<leader>5', '<cmd>lua require("harpoon.ui").nav_file(5)<CR>', opts)
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
            vim.keymap.set("n", "<leader>e", "<CMD>Oil<CR>", { desc = "Open parent directory" })
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
            }

            -- Keybindings for opening Telescope pickers
            local set = vim.api.nvim_set_keymap
            local opts = { noremap = true, silent = true }
            set('n', '<leader>ff', '<cmd>Telescope find_files<CR>', opts)
            set('n', '<leader>fg', '<cmd>Telescope live_grep<CR>', opts)
            set('n', '<leader>fb', '<cmd>Telescope buffers<CR>', opts)
            set('n', '<leader>fh', '<cmd>Telescope help_tags<CR>', opts)
        end,
    },
    {
        "christoomey/vim-tmux-navigator",
        config = function()
            vim.api.nvim_set_keymap('n', '<C-h>', '<cmd>TmuxNavigateLeft<cr>', { noremap = true, silent = true })
            vim.api.nvim_set_keymap('n', '<C-j>', '<cmd>TmuxNavigateDown<cr>', { noremap = true, silent = true })
            vim.api.nvim_set_keymap('n', '<C-k>', '<cmd>TmuxNavigateUp<cr>', { noremap = true, silent = true })
            vim.api.nvim_set_keymap('n', '<C-l>', '<cmd>TmuxNavigateRight<cr>', { noremap = true, silent = true })
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
                flavour = "frappe",
                transparent_background = true,
                term_colors = true,
                no_italic = true,
            })

            vim.cmd.colorscheme "catppuccin"
        end
    },
    {'akinsho/toggleterm.nvim', version = "*", config = true}
}
