local M = {}

local AI_BIN = vim.fn.stdpath("config") .. "/local-plugins/ai.nvim/runner/bin/ai"

local PROMPT = "Convert the following text to clean prose for text-to-speech. Remove all awkward syntax, verse numbers, footnote markers, reference numbers, brackets, and any other non-prose formatting. Keep the meaning as accurate to the source as possible. Output ONLY the cleaned prose text with no additional commentary, labels, or explanation.\n\n"

M.setup = function()
    vim.api.nvim_create_user_command("Say", function()
        local selection = require('lib.selection').get_selection()
        if not selection or selection == "" then
            print("Nothing selected.")
            return
        end
        print("Cleaning text...")
        vim.system({ AI_BIN, PROMPT .. selection }, { text = true }, function(result)
            local cleaned = vim.trim(result.stdout or "")
            if cleaned == "" then
                vim.schedule(function() print("AI returned empty response.") end)
                return
            end
            vim.schedule(function()
            vim.fn.jobstart({ "say", cleaned }, { detach = true })
        end)
        end)
    end, { range = true })
end

return M
