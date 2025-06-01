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

-- Opens todo file
map("n", "td", function()
    vim.cmd("edit /home/horki/Documents/todo.txt")
end)

-- Project and Task Management
vim.g.current_project = nil
projects = {
    {
        name = "log",
        path = "/home/horki/Documents/log",
    },
    {
        name = "mugen",
        path = "/home/horki/projects/mugen",
        actions = {
            {name = "build", cmd = "cd src/; make"},
            {name = "clean", cmd = "cd src/; make clean"},
            {name = "run",   cmd = "./src/mugen examples/bfcpu.mu results/microcode.bin"},
        },
    },
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
        name = "rayit",
        path = "/home/horki/projects/rayit",
        actions = {
            {name = "build",  cmd = "make"},
            {name = "run",    cmd = "./build/rayit"},
            {name = "clean",  cmd = "make clean"},
            {name = "test",   cmd = "make test"},
            {name = "vendor", cmd = "make vendor"},
        },
    },
    {
        name = ".dotfiles",
        path = "/home/horki/.dotfiles"
    },
    {
        name = "neovim",
        path = "/home/horki/.dotfiles/.config/nvim",
    },
    {
        name = "Introduction to Computer Graphics and Visualization",
        path = "/home/horki/projects/introGraphics",
        actions = {
            {name = "build exercise 1", cmd = "make MODE=compile AS=3 EX=1 IN=1.0"},
            {name = "build exercise 2", cmd = "make MODE=compile AS=3 EX=2 IN=2.0"},
            {name = "build exercise 3", cmd = "make MODE=compile AS=3 EX=3 IN=3.1"},
            {name = "build exercise 4", cmd = "make MODE=compile AS=3 EX=4 IN=4.1"},
            {name = "build exercise 5", cmd = "make MODE=compile AS=3 EX=5 IN=5.1"},
            {name = "test exercise 1",  cmd = "make MODE=test AS=3 EX=1 IN=1.0; make preview AS=3 EX=1"},
            {name = "test exercise 2",  cmd = "make MODE=test AS=3 EX=2 IN=2.0; make preview AS=3 EX=2"},
            {name = "test exercise 3",  cmd = "make MODE=test AS=3 EX=3 IN=3.1; make preview AS=3 EX=3"},
            {name = "test exercise 4",  cmd = "make MODE=test AS=3 EX=4 IN=4.1; make preview AS=3 EX=4"},
            {name = "test exercise 5",  cmd = "make MODE=test AS=3 EX=5 IN=5.0; make preview AS=3 EX=5"},
            {name = "clean",            cmd = "make MODE=clean"}
        }, 
    },
    {
        name = "Algorithms and Data Structures in C",
        path = "/home/horki/projects/intro-ads",
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

-- checks whether the commands needs tty
local tty_cmds = { "kitten icat", "make preview" }
local function needs_tty(cmd)
    for _, term in ipairs(tty_cmds) do
        if cmd:find(term) then
            return true
        end
    end

    return false
end

-- runs the commands either in tmux split or toggleterm,
-- depending on whether the commands requires tty
local function run_in_terminal_smart(cmd)
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
                    run_in_terminal_smart(entry.cmd)                   
                    break
                end
            end
        end)
end)

-- Open Floating Terminal with a keybinding
map("n", "tt", function()
    vim.cmd(":TermExec direction=float cmd=\"clear; echo damn you are sexy, Artur...\"")
end) 

-- Setup tags system
vim.opt.tags = { "./tags;" }
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
    {'akinsho/toggleterm.nvim', version = "*", config = true},
    {
        "iamcco/markdown-preview.nvim",
        cmd = { "MarkdownPreviewToggle", "MarkdownPreview", "MarkdownPreviewStop" },
        ft = { "markdown" },
        build = "cd app && npm install",
        init = function()
            vim.g.mkdp_filetypes = { "markdown" }
        end,
    }
}
