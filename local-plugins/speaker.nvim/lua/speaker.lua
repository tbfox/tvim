local M = {}

local OLLAMA_URL = "http://localhost:11434/api/generate"
local MODEL = "gemma3:1b"
local AI_BIN = vim.fn.stdpath("config") .. "/local-plugins/ai.nvim/runner/bin/ai"
local PROMPT = "Convert the following text to clean prose for text-to-speech. Remove all awkward syntax, verse numbers, footnote markers, reference numbers, brackets, and any other non-prose formatting. Keep the meaning as accurate to the source as possible. Preserve old English words such as thee, thy, thou, thine, hath, doth, yea, and similar archaic language exactly as written. Output ONLY the cleaned prose text with no additional commentary, labels, or explanation.\n\n"

local function ai_bin_clean(text, callback)
    vim.system({ AI_BIN, PROMPT .. text }, { text = true }, function(result)
        local cleaned = vim.trim(result.stdout or "")
        if cleaned == "" then
            vim.schedule(function() print("Speaker: AI fallback returned empty response.") end)
            return
        end
        callback(cleaned)
    end)
end

local function ollama_clean(text, callback)
    local body = vim.json.encode({
        model = MODEL,
        prompt = PROMPT .. text,
        stream = false,
    })
    local cmd = { "curl", "-s", "--max-time", "5", "-X", "POST", OLLAMA_URL,
        "-H", "Content-Type: application/json",
        "-d", body }
    vim.system(cmd, { text = true }, function(result)
        local ok, decoded = pcall(vim.json.decode, result.stdout or "")
        if result.code ~= 0 or not ok or not decoded or not decoded.response then
            vim.schedule(function() print("Ollama unavailable, falling back to ai.nvim...") end)
            ai_bin_clean(text, callback)
            return
        end
        callback(vim.trim(decoded.response))
    end)
end

M.setup = function()
    vim.api.nvim_create_user_command("Say", function()
        local selection = require('lib.selection').get_selection()
        if not selection or selection == "" then
            print("Nothing selected.")
            return
        end
        print("Cleaning text...")
        ollama_clean(selection, function(cleaned)
            vim.schedule(function()
                vim.fn.jobstart({ "say", cleaned }, { detach = true })
            end)
        end)
    end, { range = true })
end

return M
