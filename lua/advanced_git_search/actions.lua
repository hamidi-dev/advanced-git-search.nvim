local config = require("advanced_git_search.utils.config")
local command_utils = require("advanced_git_search.commands.utils")
local command_util = require("advanced_git_search.utils.command")
local file_utils = require("advanced_git_search.utils.file")
local git_utils = require("advanced_git_search.utils.git")

local M = {}

---General action: Open entire commit with fugitive or diffview
---@param commit_hash string
M.open_commit = function(commit_hash)
    local diff_plugin = config.diff_plugin()

    if diff_plugin == "diffview" then
        vim.api.nvim_command(
            ":DiffviewOpen -uno " .. commit_hash .. "~.." .. commit_hash
        )
    elseif diff_plugin == "fugitive" then
        vim.api.nvim_command(":Gedit " .. commit_hash)
    end
end

---General action: open diff for current file
---@param commit string commit or branch to diff with
---@param file_name string|nil file name to diff
M.open_diff_view = function(commit, file_name)
    local diff_plugin = config.diff_plugin()

    if file_name ~= nil and file_name ~= "" then
        if diff_plugin == "diffview" then
            vim.api.nvim_command(
                ":DiffviewOpen -uno " .. commit .. " -- " .. file_name
            )
        elseif diff_plugin == "fugitive" then
            vim.api.nvim_command(":Gvdiffsplit " .. commit .. ":" .. file_name)
        end
    else
        if diff_plugin == "diffview" then
            vim.api.nvim_command(":DiffviewOpen -uno " .. commit)
        elseif diff_plugin == "fugitive" then
            vim.api.nvim_command(":Gvdiffsplit " .. commit)
        end
    end
end

---General action: Copy commit hash to system clipboard
---@param commit_hash string
M.copy_to_clipboard = function(commit_hash)
    vim.notify(
        "Copied commit hash " .. commit_hash .. " to clipboard",
        vim.log.levels.INFO,
        { title = "Advanced Git Search" }
    )

    vim.fn.setreg("+", commit_hash)
    vim.fn.setreg("*", commit_hash)
end

---General action: Copy commit patch to system clipboard
---@param commit_hash string
---@param bufnr? number
M.copy_patch_to_clipboard = function(commit_hash, bufnr)
    local command = { "git", "show" }
    command = command_utils.format_git_diff_command(command)
    table.insert(command, commit_hash)

    if bufnr ~= nil then
        local filename = file_utils.git_relative_path(bufnr)
        local commit_file = git_utils.file_name_on_commit(commit_hash, filename)
        table.insert(command, "--")
        table.insert(command, commit_file or filename)
    end

    local patch = command_util.execute(table.concat(command, " "))

    vim.notify(
        "Copied commit patch " .. commit_hash .. " to clipboard",
        vim.log.levels.INFO,
        { title = "Advanced Git Search" }
    )

    vim.fn.setreg("+", patch)
    vim.fn.setreg("*", patch)
end

---General action: Open commit in browser
---@param commit_hash string
M.open_in_browser = function(commit_hash)
    vim.api.nvim_command(":" .. config.get_browse_command(commit_hash))
end

---General action: Checkout commit
---@param commit_hash string
M.checkout_commit = function(commit_hash)
    vim.api.nvim_command(":!git checkout " .. commit_hash)
end

return M
