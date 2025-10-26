local function local_plugin(name)
    return vim.fn.stdpath("config") .. "/local-plugins/" .. name
end

return local_plugin
