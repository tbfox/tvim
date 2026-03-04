# Roslyn C# LSP Setup

Manual installation guide for the Roslyn language server (used in `lua/plugins/roslyn.lua`).

## Requirements

- .NET 10.0+ runtime (Roslyn 5.4.0+ requires .NET 10.0)
- roslyn.nvim plugin (installed via lazy.nvim)

## Installation Steps

### 1. Install .NET 10.0

```bash
curl -sSL https://dot.net/v1/dotnet-install.sh | bash /dev/stdin --channel 10.0
```

This installs to `~/.dotnet/dotnet`.

Verify installation:
```bash
~/.dotnet/dotnet --version
~/.dotnet/dotnet --list-runtimes
```

### 2. Add Azure DevOps NuGet Source

```bash
dotnet nuget add source \
  https://pkgs.dev.azure.com/azure-public/vside/_packaging/vs-impl/nuget/v3/index.json \
  --name roslyn-ls
```

### 3. Download Roslyn Language Server

```bash
mkdir -p ~/.local/share/nvim/roslyn
cd ~/.local/share/nvim/roslyn
```

#### Check Available Versions

Replace `<PLATFORM>` with your platform:
- `osx-arm64` (Apple Silicon Mac)
- `osx-x64` (Intel Mac)
- `linux-x64` (Linux)
- `win-x64` (Windows)

```bash
curl -sSL "https://pkgs.dev.azure.com/azure-public/vside/_packaging/vs-impl/nuget/v3/flat2/microsoft.codeanalysis.languageserver.<PLATFORM>/index.json" | jq '.versions[-10:]'
```

#### Download the Package

Replace `<VERSION>` and `<PLATFORM>` with the latest version and your platform:

```bash
curl -L -o roslyn.nupkg "https://pkgs.dev.azure.com/azure-public/vside/_packaging/vs-impl/nuget/v3/flat2/microsoft.codeanalysis.languageserver.<PLATFORM>/<VERSION>/microsoft.codeanalysis.languageserver.<PLATFORM>.<VERSION>.nupkg"
```

**Example for macOS ARM64:**
```bash
curl -L -o roslyn.nupkg "https://pkgs.dev.azure.com/azure-public/vside/_packaging/vs-impl/nuget/v3/flat2/microsoft.codeanalysis.languageserver.osx-arm64/5.4.0-2.26153.3/microsoft.codeanalysis.languageserver.osx-arm64.5.4.0-2.26153.3.nupkg"
```

### 4. Extract the Package

NuGet packages are ZIP files:

```bash
unzip -q roslyn.nupkg
```

The DLL will be at: `content/LanguageServer/<PLATFORM>/Microsoft.CodeAnalysis.LanguageServer.dll`

### 5. Update Configuration

Edit `lua/plugins/roslyn.lua` and update these paths:

```lua
local roslyn_path = home .. "/.local/share/nvim/roslyn/content/LanguageServer/<PLATFORM>"
local dotnet_path = home .. "/.dotnet/dotnet"
```

For example, on macOS ARM64:
```lua
local roslyn_path = home .. "/.local/share/nvim/roslyn/content/LanguageServer/osx-arm64"
```

## Verification

1. Restart Neovim
2. Open a `.cs` file
3. Run `:LspInfo` to check if Roslyn is attached
4. Check logs if needed: `~/.local/state/nvim/lsp.log`

## Available Commands

- `:Roslyn restart` - Restart the language server
- `:Roslyn target` - Switch between multiple solutions
- `:Roslyn start` / `:Roslyn stop` - Manage server lifecycle

## Troubleshooting

### Exit Code 150

If the LSP quits with exit code 150, check the .NET version:

```bash
~/.dotnet/dotnet --list-runtimes
```

Ensure you have `Microsoft.NETCore.App 10.0.x` listed.

### Check Logs

```bash
tail -100 ~/.local/state/nvim/lsp.log
```

Look for errors from the `roslyn` or `dotnet` process.

### Verify Command

Run `:LspInfo` in a C# file and check the `cmd` field shows:
```
{ "~/.dotnet/dotnet", "~/.local/share/nvim/roslyn/content/LanguageServer/osx-arm64/Microsoft.CodeAnalysis.LanguageServer.dll", ... }
```

