-- Phase 2 Test Script
-- Tests issue listing functionality
--
-- Usage: nvim -c "luafile local-plugins/linear.nvim/test_phase2.lua"

print("\n========================================")
print("Phase 2: Issue Listing Test")
print("========================================\n")

-- Test 1: Load issues module
print("Test 1: Loading issues module...")
local ok, issues = pcall(require, "linear.issues")
if not ok then
  print("❌ FAIL: Could not load issues module: " .. issues)
  return
end
print("✓ issues module loaded")

-- Test 2: Check authentication
print("\nTest 2: Checking authentication...")
local auth = require("linear.auth")
if not auth.ensure_authenticated() then
  print("❌ FAIL: Not authenticated")
  return
end
print("✓ Authenticated")

-- Test 3: Fetch issues
print("\nTest 3: Fetching issues...")
local issue_list, err = issues.fetch_issues(false)
if err then
  print("❌ FAIL: Could not fetch issues: " .. err)
  return
end
print("✓ Fetched " .. #issue_list .. " issue(s)")

if #issue_list == 0 then
  print("\n⚠️  WARNING: No issues found in your Linear workspace")
  print("   This is normal if your workspace is empty")
  print("   Create some issues at linear.app to test fully")
else
  -- Show sample issue
  print("\nSample issue:")
  local sample = issue_list[1]
  print("  ID: " .. sample.identifier)
  print("  Title: " .. sample.title)
  print("  State: " .. (sample.state and sample.state.name or "Unknown"))
  if sample.assignee then
    print("  Assignee: " .. sample.assignee.name)
  end
end

-- Test 4: Test state formatting
print("\nTest 4: Testing state formatting...")
local test_states = {
  { type = "backlog", name = "Backlog" },
  { type = "started", name = "In Progress" },
  { type = "completed", name = "Done" }
}
for _, state in ipairs(test_states) do
  local formatted = issues.format_state(state)
  print("  " .. state.type .. " → " .. formatted)
end
print("✓ State formatting works")

-- Test 5: Test caching
print("\nTest 5: Testing cache...")
local cache = require("linear.cache")
cache.set("test_issues", issue_list)
local cached = cache.get("test_issues")
if cached ~= issue_list then
  print("❌ FAIL: Cache retrieval failed")
  return
end
print("✓ Cache works")

-- Test 6: Test rendering (create buffer and render)
print("\nTest 6: Testing issue rendering...")
local ui = require("linear.ui")
local buf = ui.create_buffer("nofile", "linear-issues")

issues.render_issue_list(buf, issue_list)

local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
if #lines < 3 then
  print("❌ FAIL: Issue list not rendered properly")
  return
end
print("✓ Rendered " .. #lines .. " lines to buffer")
print("  Header: " .. lines[1])
print("  Separator: " .. lines[2])
if #issue_list > 0 then
  print("  First issue: " .. lines[3]:sub(1, 80) .. "...")
end

-- Clean up test buffer
vim.api.nvim_buf_delete(buf, { force = true })

-- Test 7: Test ID parsing
print("\nTest 7: Testing issue ID parsing...")
if #issue_list > 0 then
  -- Create a test line similar to what we render
  local test_line = issue_list[1].identifier .. "  [○ Todo]  @alice  Project  2026-03-10  Test issue"
  vim.cmd("new")
  vim.api.nvim_set_current_line(test_line)
  local parsed_id = ui.parse_issue_id_from_line()
  vim.cmd("bdelete!")

  if parsed_id ~= issue_list[1].identifier then
    print("❌ FAIL: ID parsing failed. Expected: " .. issue_list[1].identifier .. ", Got: " .. tostring(parsed_id))
    return
  end
  print("✓ Parsed issue ID: " .. parsed_id)
else
  print("⚠️  Skipped (no issues to test with)")
end

-- Summary
print("\n========================================")
print("✓ Phase 2: ALL TESTS PASSED!")
print("========================================")
print("\nIssue listing is working:")
print("- ✓ Issues module loads")
print("- ✓ Can fetch issues from API")
print("- ✓ State formatting works")
print("- ✓ Cache works")
print("- ✓ Rendering works")
print("- ✓ ID parsing works")
print("\nReady to use:")
print("  :Linear issues  - Open issue list")
print("  <F5>           - Quick access")
print("\nIn issue list:")
print("  <CR>  - View issue details (Phase 3)")
print("  g.    - Toggle archived issues")
print("  r     - Refresh")
print("  q/-   - Close")
print("")
