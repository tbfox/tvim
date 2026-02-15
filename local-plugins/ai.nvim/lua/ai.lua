local M = {}

local AI_BIN_LOCATION = "/local-plugins/ai.nvim/runner/bin/ai"

local function get_ai_response(prompt)
    local api_file = vim.fn.stdpath("config") .. AI_BIN_LOCATION
    return vim.system({ api_file, prompt }, { text = true }):wait().stdout
end

local completions = { }

M.setup = function()
    vim.api.nvim_create_user_command("Ai", function(opts)
        local args = vim.split(vim.trim(opts.args), ' ')
        local open_prompt = require('open_prompt').open_prompt
        local selection = require('lib.selection').get_selection()
        if (args[1] == '') then
            if (selection == nil) then
                open_prompt(' AI prompt (print mode) ', function(content)
                    vim.print(get_ai_response(content))
                end)
            else
                open_prompt(' AI prompt (print mode) ', function(content)
                    vim.print(get_ai_response(content .. "\n\n" .. selection))
                end)
            end
            return
        end
    end, {
        nargs = '*',
        desc = "Briefly send a snippit to AI for various things.",
        range = true,
        complete = function() return completions end
    })
end

-- M.setup()

return M
