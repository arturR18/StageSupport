# Sequential Thinking MCP Server Setup Guide

## Installation Instructions

### For Claude Desktop

1. **Create/Edit the MCP configuration file:**
   - Location: `~/.config/claude/mcp.json` (macOS/Linux)
   - Location: `%APPDATA%\Claude\mcp.json` (Windows)

2. **Add this configuration:**

```json
{
  "mcpServers": {
    "sequential-thinking": {
      "command": "npx",
      "args": [
        "-y",
        "@modelcontextprotocol/server-sequential-thinking"
      ]
    }
  }
}
```

3. **Restart Claude Desktop** for the changes to take effect.

### For VS Code / Cursor

1. **Create/Edit the MCP configuration file:**
   - Project-specific: `.cursor/mcp.json` or `.vscode/mcp.json`
   - User-specific: Open Command Palette (Cmd+Shift+P) → "MCP: Open User Configuration"

2. **Add the same configuration as above**

3. **Refresh MCP servers** in Settings → MCP (for Cursor)

## Alternative Installation Methods

### Using NPM (for local installation):
```bash
npm install -g @modelcontextprotocol/server-sequential-thinking
```

Then use this configuration:
```json
{
  "mcpServers": {
    "sequential-thinking": {
      "command": "sequential-thinking"
    }
  }
}
```

### Using Docker:
```json
{
  "mcpServers": {
    "sequential-thinking": {
      "command": "docker",
      "args": [
        "run",
        "--rm",
        "-i",
        "mcp/sequentialthinking"
      ]
    }
  }
}
```

## Features

- **Structured Problem Solving**: Breaks down complex problems into manageable steps
- **Iterative Refinement**: Continuously improves solutions through multiple iterations
- **Multiple Reasoning Paths**: Explores different approaches to find optimal solutions
- **Detailed Analysis**: Provides step-by-step thinking process for transparency

## Configuration Options

- To disable logging: Set environment variable `DISABLE_THOUGHT_LOGGING=true`

## Verification

After installation, the Sequential Thinking tools should be available in your Claude/Cursor interface. You can verify by checking if sequential thinking tools appear in the available MCP tools list.

## Troubleshooting

1. **If the server doesn't appear:**
   - Ensure Node.js and npm are installed
   - Check that the configuration file is in the correct location
   - Restart the application after adding configuration

2. **For permission issues:**
   - Ensure the configuration file has proper read permissions
   - On macOS/Linux: `chmod 644 ~/.config/claude/mcp.json`

## Resources

- [NPM Package](https://www.npmjs.com/package/@modelcontextprotocol/server-sequential-thinking)
- [GitHub Repository](https://github.com/modelcontextprotocol/servers/tree/main/src/sequentialthinking)
- [MCP Documentation](https://mcpservers.org/servers/modelcontextprotocol/sequentialthinking)