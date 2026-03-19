local M = {}

local OLLAMA_URL = "http://localhost:11434/api/generate"
local MODEL = "gemma3:1b"
local AI_BIN = vim.fn.stdpath("config") .. "/local-plugins/ai.nvim/runner/bin/ai"
local PROMPT = "Convert the following text to clean prose for text-to-speech. Remove all awkward syntax, verse numbers, footnote markers, reference numbers, brackets, and any other non-prose formatting. Keep the meaning as accurate to the source as possible. Preserve old English words such as thee, thy, thou, thine, hath, doth, yea, and similar archaic language exactly as written. Output ONLY the cleaned prose text with no additional commentary, labels, or explanation.\n\n"

local ELEVENLABS_VOICE_ID = "cymHWdiF8WjUCg6vvFxx"
local ELEVENLABS_MODEL = "eleven_multilingual_v2"

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

-- Fetch TTS from ElevenLabs and save to file, then call callback(true/false)
local function elevenlabs_save(text, filepath, callback)
    local api_key = vim.fn.getenv("ELEVEN_LABS_NVIM")
    if not api_key or api_key == vim.NIL or api_key == "" then
        vim.notify("ELEVEN_LABS_NVIM env var not set", vim.log.levels.ERROR)
        if callback then callback(false) end
        return
    end
    local url = string.format(
        "https://api.elevenlabs.io/v1/text-to-speech/%s?output_format=mp3_44100_128",
        ELEVENLABS_VOICE_ID
    )
    local body = vim.json.encode({ text = text, model_id = ELEVENLABS_MODEL })
    local cmd = {
        "curl", "-s", "-X", "POST", url,
        "-H", "Content-Type: application/json",
        "-H", "xi-api-key: " .. api_key,
        "-d", body,
        "-o", filepath,
    }
    vim.system(cmd, {}, function(result)
        if result.code ~= 0 then
            vim.schedule(function()
                vim.notify("ElevenLabs request failed (code " .. result.code .. ")", vim.log.levels.ERROR)
                if callback then callback(false) end
            end)
        else
            vim.schedule(function()
                if callback then callback(true) end
            end)
        end
    end)
end

M.ollama_clean = ollama_clean
M.elevenlabs_save = elevenlabs_save

M.setup = function()
    vim.api.nvim_create_user_command("Say", function()
        local selection = require('lib.selection').get_selection()
        if not selection or selection == "" then
            print("Nothing selected.")
            return
        end
        print("Cleaning text...")
        ollama_clean(selection, function(cleaned)
            local tmpfile = os.tmpname() .. ".mp3"
            vim.schedule(function()
                vim.notify("Fetching audio from ElevenLabs...", vim.log.levels.INFO)
                elevenlabs_save(cleaned, tmpfile, function(ok)
                    if ok then
                        vim.fn.jobstart({ "afplay", tmpfile }, { detach = true })
                    end
                end)
            end)
        end)
    end, { range = true })
end

return M
