-- GraphQL API client for Linear
-- Handles all HTTP requests to Linear's GraphQL API

local M = {}

-- Linear GraphQL endpoint
M.ENDPOINT = "https://api.linear.app/graphql"

-- Make a GraphQL query/mutation
-- @param query_string string: The GraphQL query/mutation
-- @param variables table: Variables for the query
-- @return result table|nil: Parsed JSON response with {data: ...}
-- @return error string|nil: Error message if request failed
function M.query(query_string, variables)
  local auth = require("linear.auth")

  local api_key = auth.get_api_key()
  if not api_key then
    return nil, "No API key found"
  end

  -- Build GraphQL request body
  local body = vim.json.encode({
    query = query_string,
    variables = variables or {}
  })

  -- Create temporary file for request body
  local body_file = vim.fn.tempname()
  local f = io.open(body_file, "w")
  if not f then
    return nil, "Failed to create temp file"
  end
  f:write(body)
  f:close()

  -- Make curl request
  local cmd = {
    "curl",
    "-X", "POST",
    "-H", "Content-Type: application/json",
    "-H", "Authorization: " .. api_key,
    "--silent",
    "--show-error",
    "--data", "@" .. body_file,
    M.ENDPOINT
  }

  local obj = vim.system(cmd, { text = true }):wait()

  -- Clean up temp file
  vim.fn.delete(body_file)

  -- Check for curl errors
  if obj.code ~= 0 then
    return nil, "HTTP request failed: " .. (obj.stderr or "Unknown error")
  end

  -- Parse JSON response
  local success, result = pcall(vim.json.decode, obj.stdout)
  if not success then
    return nil, "Failed to parse JSON response: " .. result
  end

  -- Check for GraphQL errors
  if result.errors then
    local error_msgs = {}
    for _, err in ipairs(result.errors) do
      table.insert(error_msgs, err.message)
    end
    return nil, "GraphQL error: " .. table.concat(error_msgs, ", ")
  end

  return result, nil
end

return M
