local utils = require("advanced_git_search.utils")
local entry_display = require("telescope.pickers.entry_display")
local config = require("advanced_git_search.utils.config")

local display_mode

local function get_display_mode()
    if not display_mode then
        display_mode = config.entry_default_author_or_date()
    end
    return display_mode
end

local M = {}
local last_prompt = nil

M.toggle_show_date_instead_of_author = function()
    local mode = get_display_mode()
    if mode == "author" then
        display_mode = "date"
    elseif mode == "date" then
        display_mode = "both"
    else
        display_mode = "author"
    end
end

--- Parse "--format=%C(auto)%h %as %C(green)%an _ %Creset %s" to table
--- with opts: commit_hash, date, author, message, prompt
--- @param entry string
M.git_log_entry_maker = function(entry)
    -- dce3b0743 2022-09-09 author _ message
    -- FIXME: will break if author contains _
    local cleaned = string.gsub(entry, "'", "")
    local split = utils.split_string(cleaned, "_")
    local attrs = utils.split_string(split[1])
    local hash = string.sub(attrs[1], 1, 7)
    local date = attrs[2]
    local author = attrs[3]
    for i = 4, #attrs do
        author = author .. " " .. attrs[i]
    end

    -- join split from second element
    local message = split[2]
    if #split > 2 then
        for i = 3, #split do
            message = message .. " " .. split[i]
        end
    end

    local displayer
    local make_display
    local mode = get_display_mode()

    if mode == "both" then
        displayer = entry_display.create({
            separator = " ",
            items = {
                { width = 7 },
                { width = 10 },
                { width = #author },
                { remaining = true },
            },
        })
        make_display = function(display_entry)
            return displayer({
                {
                    display_entry.opts.commit_hash,
                    "TelescopeResultsIdentifier",
                },
                { display_entry.opts.date, "TelescopeResultsVariable" },
                { display_entry.opts.author, "TelescopeResultsVariable" },
                { display_entry.opts.message, "TelescopeResultsConstant" },
            })
        end
    else
        local second_width = mode == "date" and 10 or #author
        displayer = entry_display.create({
            separator = " ",
            items = {
                { width = 7 },
                { width = second_width },
                { remaining = true },
            },
        })
        make_display = function(display_entry)
            if mode == "date" then
                return displayer({
                    {
                        display_entry.opts.commit_hash,
                        "TelescopeResultsIdentifier",
                    },
                    { display_entry.opts.date, "TelescopeResultsVariable" },
                    { display_entry.opts.message, "TelescopeResultsConstant" },
                })
            else
                return displayer({
                    {
                        display_entry.opts.commit_hash,
                        "TelescopeResultsIdentifier",
                    },
                    { display_entry.opts.author, "TelescopeResultsVariable" },
                    { display_entry.opts.message, "TelescopeResultsConstant" },
                })
            end
        end
    end

    return {
        value = entry,
        -- display = date .. " by " .. author .. " --" .. message,
        display = make_display,
        ordinal = author .. " " .. message,
        preview_title = hash .. " -- " .. message,
        opts = {
            commit_hash = hash,
            date = date,
            author = author,
            message = message,
            prompt = last_prompt,
        },
    }
end

M.set_last_prompt = function(prompt)
    last_prompt = prompt
end

return M
