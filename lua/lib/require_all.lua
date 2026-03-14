local function require_all(name)
    local dir = vim.fn.stdpath("config") .. "/lua/" .. name
    local contents = vim.fn.readdir(dir)
    if contents and #contents > 0 then
        for _, item in ipairs(contents) do
            local stem, ext = item:match('^(.+)%.(.+)$')
            if ext == "lua" and stem ~= "lazy" then
                require(name .. "." .. stem)
            end
        end
    else
      print("Could not find dir: ", dir)
    end
end

return { require_all = require_all }
