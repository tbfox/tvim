local M = {}

local AI_BIN_LOCATION = "/local-plugins/ai.nvim/runner/bin/ai"

local default_lambda = function(input) return input end

local function get_ai_response(prompt)
    local api_file = vim.fn.stdpath("config") .. AI_BIN_LOCATION
    return vim.system({ api_file, prompt }, { text = true }):wait().stdout
end

local completions = { "print", "replace", "sum", "cat" }

M.setup = function()
    vim.api.nvim_create_user_command("Ai", function(opts)
        local args = vim.split(opts.args, ' ')
        local open_prompt = require('open_prompt').open_prompt
        if (args[1] == '') then
            open_prompt(function(content)
                vim.print(get_ai_response(content))
            end)
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
