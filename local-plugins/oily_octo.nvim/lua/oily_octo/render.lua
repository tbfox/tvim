local state = require("oily_octo.state")

local M = {}

function M.issue_list(buf, issues)
    local lines = {}
    table.insert(lines, string.format("%-6s   %-8s   %s", "ID", "STATUS", "TITLE"))
    table.insert(lines, string.rep("-", 40))

    for _, issue in ipairs(issues) do
        local is_open = issue.state:upper() == "OPEN"
        if state.show_closed or is_open then
            local status = is_open and "[!]" or "[x]"
            local row = string.format("%-6d   %-8s   %s", issue.number, status, issue.title)
            table.insert(lines, row)
        end
    end

    vim.bo[buf].modifiable = true
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
    vim.bo[buf].modifiable = false
end

function M.parse_issue_content(lines)
    local title = ""
    local body_lines = {}
    local in_body = false

    for i, line in ipairs(lines) do
        if i == 1 and line:match("^Title:%s*") then
            title = line:match("^Title:%s*(.*)") or ""
        elseif line:match("^%-%-%-+$") and not in_body then
            in_body = true
        elseif in_body then
            table.insert(body_lines, line)
        end
    end

    while #body_lines > 0 and body_lines[#body_lines]:match("^%s*$") do
        table.remove(body_lines)
    end

    return title, table.concat(body_lines, "\n")
end

return M
