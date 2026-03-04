# TBFox Configuration Docs (tvim)

Documentation and setup guides for this Neovim configuration.

## Setup Guides

- [**Roslyn C# LSP Setup**](./roslyn-setup.md) - Manual installation guide for the Roslyn language server

## Quick Reference

### Local Plugins

This config uses custom local plugins in `local-plugins/`:

- **ai.nvim** - AI integration (Claude/Gemini API)
  - Build: `cd local-plugins/ai.nvim/runner && bun install && bun run b`

- **time_track.nvim** - Tree-sitter grammar for `.time_track` files
  - Build: `cd local-plugins/time_track.nvim/tree-sitter && make`

- **runnables.nvim** - Execute code snippets (Lua, TypeScript, Nushell)
  - Commands: `:Exp`, `:Ex`, `:Case`

- **oily_octo.nvim** - GitHub issues browser
  - Keybinding: `<F10>`

### Key Dependencies

- **Bun** - For building and running ai.nvim runner
- **tree-sitter CLI** - For building time_track parser
- **GitHub CLI** (`gh`) - For oily_octo.nvim

## Architecture

See [CLAUDE.md](../CLAUDE.md) for full architecture documentation.
