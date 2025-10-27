local function require_all(name)
    local dir = vim.fn.stdpath("config") .. "/lua/" .. name
    local contents = vim.fn.readdir(dir)
    if contents and #contents > 0 then
        for _, item in ipairs(contents) do
            local file = {}
            for token in string.gmatch(item, '[^.]+') do
                table.insert(file, token)
            end
            if file[2] == "lua" and file[1] ~= "lazy" then
                require(name .. ".".. file[1])
            end
        end
    else
      print("Could not find dir: ", dir)
    end
end

return { require_all = require_all }
