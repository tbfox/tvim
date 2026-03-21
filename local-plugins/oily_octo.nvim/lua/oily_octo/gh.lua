local M = {}

function M.list_issues(callback)
    local cmd = {
        "gh", "issue", "list",
        "--state", "all",
        "--limit", "100",
        "--json", "number,title,state"
    }
    local obj = vim.system(cmd, { text = true }):wait()
    if obj.code ~= 0 then
        vim.notify("GH CLI Error: " .. (obj.stderr or "Check 'gh auth status'"), vim.log.levels.ERROR)
        return
    end
    local ok, issues = pcall(vim.json.decode, obj.stdout)
    if not ok or not issues then
        vim.notify("Failed to parse JSON", vim.log.levels.ERROR)
        return
    end
    callback(issues)
end

function M.view_issue(id, callback)
    local cmd = { "gh", "issue", "view", id, "--json", "title,body,assignees,labels,projectItems,comments" }
    local obj = vim.system(cmd, { text = true }):wait()
    if obj.code ~= 0 then
        vim.notify("GH CLI Error: " .. (obj.stderr or ""), vim.log.levels.ERROR)
        return
    end
    local ok, data = pcall(vim.json.decode, obj.stdout)
    if not ok or not data then
        vim.notify("Failed to parse issue JSON", vim.log.levels.ERROR)
        return
    end
    callback(data)
end

function M.create_issue(title, body, callback)
    local cmd = { "gh", "issue", "create", "--title", title, "--body", body }
    local obj = vim.system(cmd, { text = true }):wait()
    if obj.code ~= 0 then
        vim.notify("Failed to create issue: " .. (obj.stderr or ""), vim.log.levels.ERROR)
    else
        vim.notify("Issue created successfully!", vim.log.levels.INFO)
        callback()
    end
end

function M.edit_issue(id, title, body, callback)
    local cmd = { "gh", "issue", "edit", tostring(id), "--title", title, "--body", body }
    local obj = vim.system(cmd, { text = true }):wait()
    if obj.code ~= 0 then
        vim.notify("Failed to update issue: " .. (obj.stderr or ""), vim.log.levels.ERROR)
    else
        vim.notify("Issue #" .. id .. " updated successfully!", vim.log.levels.INFO)
        callback()
    end
end

function M.close_issue(id, callback)
    local cmd = { "gh", "issue", "close", tostring(id) }
    local obj = vim.system(cmd, { text = true }):wait()
    if obj.code ~= 0 then
        vim.notify("Failed to close issue: " .. (obj.stderr or ""), vim.log.levels.ERROR)
    else
        vim.notify("Issue #" .. id .. " closed successfully!", vim.log.levels.INFO)
        callback()
    end
end

function M.list_comments(id, callback)
    local cmd = { "gh", "issue", "view", tostring(id), "--json", "comments" }
    local obj = vim.system(cmd, { text = true }):wait()
    if obj.code ~= 0 then
        vim.notify("GH CLI Error: " .. (obj.stderr or ""), vim.log.levels.ERROR)
        return
    end
    local ok, data = pcall(vim.json.decode, obj.stdout)
    if not ok or not data then
        vim.notify("Failed to parse comments JSON", vim.log.levels.ERROR)
        return
    end
    callback(data.comments or {})
end

function M.edit_assignees(id, add, remove, callback)
    local cmd = { "gh", "issue", "edit", tostring(id) }
    for _, login in ipairs(add) do
        table.insert(cmd, "--add-assignee")
        table.insert(cmd, login)
    end
    for _, login in ipairs(remove) do
        table.insert(cmd, "--remove-assignee")
        table.insert(cmd, login)
    end
    local obj = vim.system(cmd, { text = true }):wait()
    if obj.code ~= 0 then
        vim.notify("Failed to update assignees: " .. (obj.stderr or ""), vim.log.levels.ERROR)
    else
        vim.notify("Assignees updated", vim.log.levels.INFO)
        callback()
    end
end

function M.list_labels(callback)
    local cmd = { "gh", "label", "list", "--json", "name", "--jq", "[.[].name]" }
    local obj = vim.system(cmd, { text = true }):wait()
    if obj.code ~= 0 then
        vim.notify("GH CLI Error: " .. (obj.stderr or ""), vim.log.levels.ERROR)
        return
    end
    local ok, data = pcall(vim.json.decode, obj.stdout)
    if not ok or not data then
        vim.notify("Failed to parse labels JSON", vim.log.levels.ERROR)
        return
    end
    callback(data)
end

function M.edit_labels(id, add, remove, callback)
    local cmd = { "gh", "issue", "edit", tostring(id) }
    for _, name in ipairs(add) do
        table.insert(cmd, "--add-label")
        table.insert(cmd, name)
    end
    for _, name in ipairs(remove) do
        table.insert(cmd, "--remove-label")
        table.insert(cmd, name)
    end
    local obj = vim.system(cmd, { text = true }):wait()
    if obj.code ~= 0 then
        vim.notify("Failed to update labels: " .. (obj.stderr or ""), vim.log.levels.ERROR)
    else
        vim.notify("Labels updated", vim.log.levels.INFO)
        callback()
    end
end

function M.list_assignees(callback)
    local cmd = { "gh", "api", "repos/:owner/:repo/assignees", "--jq", "[.[].login]" }
    local obj = vim.system(cmd, { text = true }):wait()
    if obj.code ~= 0 then
        vim.notify("GH CLI Error: " .. (obj.stderr or ""), vim.log.levels.ERROR)
        return
    end
    local ok, data = pcall(vim.json.decode, obj.stdout)
    if not ok or not data then
        vim.notify("Failed to parse assignees JSON", vim.log.levels.ERROR)
        return
    end
    callback(data)
end

function M.add_comment(id, body, callback)
    local cmd = { "gh", "issue", "comment", tostring(id), "--body", body }
    local obj = vim.system(cmd, { text = true }):wait()
    if obj.code ~= 0 then
        vim.notify("Failed to add comment: " .. (obj.stderr or ""), vim.log.levels.ERROR)
    else
        vim.notify("Comment added to #" .. id, vim.log.levels.INFO)
        callback()
    end
end

return M
