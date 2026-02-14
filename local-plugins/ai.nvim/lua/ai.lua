local M = {}

local AI_BIN_LOCATION = "/local-plugins/ai.nvim/runner/bin/ai"

local function ai_summarize()
    local selection = require('lib.selection')
    local api_file = vim.fn.stdpath("config") .. AI_BIN_LOCATION
    local result = vim.system({ api_file, "Summarize the following content in a few short sentences:" .. selection.get_selection() .. " end content" }, { text = true }):wait()
    vim.print(result.stdout)
end

local function ai_replace()
    local selection = require('lib.selection')
    local api_file = vim.fn.stdpath("config") .. AI_BIN_LOCATION
    local result = vim.system({ api_file, selection.get_selection() }, { text = true }):wait()
    selection.set_selection(result.stdout)
end

local function ai_concat()
    local selection = require('lib.selection')
    local selected_text = selection.get_selection()
    local api_file = vim.fn.stdpath("config") .. AI_BIN_LOCATION

    local result = vim.system({ api_file, selected_text }, { text = true }):wait()
    selection.set_selection(selected_text .. "\n\n".. result.stdout)
end

local function ai_print()
    local selection = require('lib.selection').get_selection()
    local api_file = vim.fn.stdpath("config") .. AI_BIN_LOCATION
    local result = vim.system({ api_file, selection }, { text = true }):wait()
    vim.print(result.stdout)
end

M.setup = function()
    vim.api.nvim_create_user_command("Ai", function(opts)
        local arg = opts.args:lower()
        if arg == "print" then
            ai_print()
        elseif arg == "replace" then
            ai_replace()
        elseif arg == "sum" then
            ai_summarize()
        elseif arg == "cat" then
            ai_concat()
        else
            print("Error: Unknown argument '" .. arg .."'.")
        end
    end, { nargs = 1, desc = "Briefly send a snippit to AI for various things.", range = true, complete = function() return { "print", "replace", "sum", "cat" } end })
end

M.setup()

return M
