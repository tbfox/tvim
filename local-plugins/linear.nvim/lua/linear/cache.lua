-- Simple in-memory cache for API responses
-- Used to avoid re-fetching data when toggling views or refreshing

local M = {}

-- Cache storage
M._cache = {}

-- Get value from cache
-- @param key string: Cache key
-- @return value any|nil: Cached value or nil if not found
function M.get(key)
  return M._cache[key]
end

-- Set value in cache
-- @param key string: Cache key
-- @param value any: Value to cache
function M.set(key, value)
  M._cache[key] = value
end

-- Clear specific cache key
-- @param key string: Cache key to clear
function M.clear(key)
  M._cache[key] = nil
end

-- Clear all cached data
function M.clear_all()
  M._cache = {}
end

return M
