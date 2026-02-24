# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

This is a personal Neovim configuration with custom local plugins. The configuration uses lazy.nvim for plugin management and includes several custom-built plugins for AI integration, time tracking, code execution, and GitHub integration.

## Architecture

### Directory Structure

- **init.lua**: Entry point that sets leader key to Space and loads the configuration
- **lua/config/**: Auto-loaded configuration modules (settings, keymaps, commands, etc.)
- **lua/plugins/**: Plugin specifications for lazy.nvim (each file returns a table spec)
- **lua/lib/**: Shared utilities used across the configuration
- **local-plugins/**: Custom plugins developed specifically for this config

### Loading Mechanism

1. `init.lua` loads `config.lazy` which bootstraps lazy.nvim
2. Lazy loads all files from `lua/plugins/` as plugin specs
3. `require_all.lua` utility auto-requires all files in `lua/config/`

### Local Plugin System

Local plugins are referenced using `require("lib.local-plugin")("plugin-name")` which returns the full path to `~/.config/nvim/local-plugins/plugin-name`. Each plugin has a corresponding setup file in `lua/plugins/`.

## Local Plugins

### ai.nvim
AI integration plugin that sends prompts to Anthropic Claude or Google Gemini APIs.

**Location**: `local-plugins/ai.nvim/`

**Build commands**:
```bash
cd local-plugins/ai.nvim/runner
bun install
bun run b  # Compiles to bin/ai
```

**Architecture**:
- Lua frontend exposes `:Ai` and `:Ai replace` commands
- TypeScript runner (Bun) handles API calls to Anthropic/Google
- Uses `lib/selection.lua` for getting/setting text with context

### time_track.nvim
Custom tree-sitter grammar for `.time_track` files.

**Location**: `local-plugins/time_track.nvim/`

**Build commands**:
```bash
cd local-plugins/time_track.nvim/tree-sitter
make  # Builds parser.so
```

**Requirements**: tree-sitter CLI must be installed

**Architecture**: Registers custom filetype and tree-sitter parser, loads parser.so dynamically

### runnables.nvim
Execute code snippets in Lua, TypeScript/JavaScript (via Bun), or Nushell.

**Location**: `local-plugins/runnables.nvim/`

**Commands**:
- `:Exp` - Execute selection as expression (wraps with language-specific printer)
- `:Ex` - Execute selection as statements
- `:Case [kab|down|up|camel|snake|ssnake|title]` - Convert selection to different cases

**Architecture**:
- `runner.lua`: Writes code to tempfile, executes with language interpreter
- `langs.lua`: Language definitions with filetypes and programs
- `printers.lua`: Language-specific print wrappers

### oily_octo.nvim
GitHub issues browser with oil.nvim-style interface.

**Location**: `local-plugins/oily_octo.nvim/`

**Commands**: Bound to `<F10>`

**Features**:
- Lists all issues (open and closed)
- Toggle closed issues with `g.`
- View issue details with `<CR>`
- Refresh with `r`
- Navigate back with `-`

**Requirements**: GitHub CLI (`gh`) must be authenticated

## Development Workflow

### Testing Lua Changes
1. Edit configuration files
2. Press `<F2>` to `:source %` current file
3. Or select lines and press `<F1>` to execute as Lua

### Adding New Plugins
1. Create plugin spec in `lua/plugins/new-plugin.lua`
2. Return a table with plugin config (lazy.nvim format)
3. Reload with `:Lazy sync`

### Adding Local Plugins
1. Create directory in `local-plugins/plugin-name/`
2. Add `lua/plugin-name.lua` with `M.setup()` function
3. Create spec in `lua/plugins/plugin-name.lua`:
```lua
return {
    {
        dir = require("lib.local-plugin")("plugin-name"),
        config = function()
            require("plugin-name").setup()
        end
    }
}
```

### Modifying AI Runner
1. Edit files in `local-plugins/ai.nvim/runner/src/`
2. Rebuild: `cd local-plugins/ai.nvim/runner && bun run b`
3. Restart Neovim to load new binary

### Modifying Time Track Grammar
1. Edit `local-plugins/time_track.nvim/tree-sitter/grammar.js`
2. Rebuild: `cd local-plugins/time_track.nvim/tree-sitter && make`
3. Restart Neovim to load new parser

## Key Bindings

- **Leader key**: `<Space>`
- **Window creation**: `<Leader>w[hjkl]`
- **Buffer navigation**: `<Leader>n` (next), `<Leader>p` (previous)
- **Execute Lua**: `<F1>` (selection), `<F2>` (file)
- **GitHub issues**: `<F10>`
- **Case conversion**: `<Leader>t[kdcuts]` in visual mode

## LSP Configuration

Enabled language servers:
- `lua_ls` (Lua)
- `nushell` (Nushell)
- `ts_ls` (TypeScript)

Common LSP keymaps are set via `lib/common-lsp-keymaps.lua` on LspAttach.

## Dependencies

- **Neovim**: Recent version with Lua support
- **Bun**: For building and running ai.nvim runner
- **tree-sitter CLI**: For building time_track parser
- **GitHub CLI**: For oily_octo.nvim
- **Language runtimes**: lua, bun, nu (Nushell) for runnables.nvim
