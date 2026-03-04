-- Phase 1 Test Script
-- Run this to verify core infrastructure works
--
-- Usage: nvim -c "source local-plugins/linear.nvim/test_phase1.lua"

print("\n========================================")
print("Phase 1: Core Infrastructure Test")
print("========================================\n")

-- Test 1: Module Loading
print("Test 1: Loading modules...")
local ok, linear = pcall(require, "linear")
if not ok then
  print("❌ FAIL: Could not load linear module: " .. linear)
  return
end
print("✓ linear module loaded")

local ok, auth = pcall(require, "linear.auth")
if not ok then
  print("❌ FAIL: Could not load auth module: " .. auth)
  return
end
print("✓ auth module loaded")

local ok, api = pcall(require, "linear.api")
if not ok then
  print("❌ FAIL: Could not load api module: " .. api)
  return
end
print("✓ api module loaded")

local ok, cache = pcall(require, "linear.cache")
if not ok then
  print("❌ FAIL: Could not load cache module: " .. cache)
  return
end
print("✓ cache module loaded")

local ok, ui = pcall(require, "linear.ui")
if not ok then
  print("❌ FAIL: Could not load ui module: " .. ui)
  return
end
print("✓ ui module loaded")

local ok, utils = pcall(require, "linear.utils")
if not ok then
  print("❌ FAIL: Could not load utils module: " .. utils)
  return
end
print("✓ utils module loaded")

-- Test 2: API Key
print("\nTest 2: Checking API key...")
local api_key = auth.get_api_key()
if not api_key then
  print("❌ FAIL: LINEAR_API_KEY environment variable not set")
  print("   Get your key from: https://linear.app/settings/api")
  print("   Then: export LINEAR_API_KEY='lin_api_xxxxx'")
  return
end
print("✓ API key found: " .. api_key:sub(1, 12) .. "..." .. api_key:sub(-4))

-- Test 3: Authentication
print("\nTest 3: Testing authentication...")
local query = [[
  query {
    viewer {
      id
      name
      email
    }
  }
]]

local result, err = api.query(query, {})
if err then
  print("❌ FAIL: Authentication failed: " .. err)
  print("   Check that your API key is valid")
  return
end

if not result.data or not result.data.viewer then
  print("❌ FAIL: Unexpected response format")
  print("   Response: " .. vim.inspect(result))
  return
end

local viewer = result.data.viewer
print("✓ Authenticated as: " .. viewer.name .. " (" .. viewer.email .. ")")

-- Test 4: Cache
print("\nTest 4: Testing cache...")
cache.set("test_key", "test_value")
local cached = cache.get("test_key")
if cached ~= "test_value" then
  print("❌ FAIL: Cache get/set failed")
  return
end
print("✓ Cache get/set works")

cache.clear("test_key")
local cleared = cache.get("test_key")
if cleared ~= nil then
  print("❌ FAIL: Cache clear failed")
  return
end
print("✓ Cache clear works")

-- Test 5: Get Teams
print("\nTest 5: Testing team query...")
local teams_query = [[
  query {
    teams {
      nodes {
        id
        name
        key
      }
    }
  }
]]

local teams_result, teams_err = api.query(teams_query, {})
if teams_err then
  print("❌ FAIL: Could not fetch teams: " .. teams_err)
  return
end

if not teams_result.data or not teams_result.data.teams then
  print("❌ FAIL: Unexpected teams response format")
  return
end

local teams = teams_result.data.teams.nodes
print("✓ Found " .. #teams .. " team(s):")
for _, team in ipairs(teams) do
  print("  - " .. team.key .. ": " .. team.name)
end

-- Cache teams for later use
cache.set("teams", teams)

-- Test 6: Commands
print("\nTest 6: Testing commands...")
local cmds = vim.api.nvim_get_commands({})
if not cmds.Linear then
  print("❌ FAIL: :Linear command not registered")
  return
end
print("✓ :Linear command registered")

-- Test 7: Utils
print("\nTest 7: Testing utility functions...")
local date = utils.format_date("2026-03-10")
if date ~= "2026-03-10" then
  print("❌ FAIL: format_date failed")
  return
end
print("✓ format_date works")

local assignee = utils.format_assignee({ name = "Alice Smith" })
if assignee ~= "@Alice" then
  print("❌ FAIL: format_assignee failed, got: " .. assignee)
  return
end
print("✓ format_assignee works")

-- Summary
print("\n========================================")
print("✓ Phase 1: ALL TESTS PASSED!")
print("========================================")
print("\nCore infrastructure is working:")
print("- ✓ All modules load correctly")
print("- ✓ Authentication works")
print("- ✓ GraphQL queries work")
print("- ✓ Cache works")
print("- ✓ Commands registered")
print("- ✓ Utils work")
print("\nReady to proceed to Phase 2: Issue Listing")
print("\nYou can now use:")
print("  :Linear test-auth  - Test authentication")
print("  <F5>              - Open issues (Phase 2)")
print("")
