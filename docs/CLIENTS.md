# MCP Client Configuration

How to connect your AI agent client to the CKG MCP server (`ckg-mcp`).

---

## Prerequisites

Install the CKG MCP server:
```bash
pip install ckg-mcp
```

Or install from source:
```bash
git clone https://github.com/your-org/joern-KG-builder
pip install -e joern-KG-builder/ckg/mcp
```

The server requires:
- Neo4j running at `bolt://localhost:7687` (or set `NEO4J_URI`)
- A CKG profile already ingested (see [joern-KG-builder pipeline docs](https://github.com/your-org/joern-KG-builder))

---

## Environment Variables

| Variable | Default | Description |
|---|---|---|
| `NEO4J_URI` | `bolt://localhost:7687` | Neo4j Bolt URI |
| `NEO4J_USERNAME` | `neo4j` | Neo4j username (`NEO4J_USER` also accepted) |
| `NEO4J_PASSWORD` | _(empty)_ | Neo4j password |
| `NEO4J_DATABASE` | `neo4j` | Target database name |

---

## OpenCode — stdio (recommended)

`.opencode/config.json`:
```json
{
  "mcp": {
    "ckg": {
      "type": "local",
      "command": [
        "/path/to/python3",
        "-m", "ckg_mcp.server",
        "--profile", "your-profile-name"
      ],
      "environment": {
        "NEO4J_URI": "bolt://localhost:7687",
        "NEO4J_USERNAME": "neo4j",
        "NEO4J_PASSWORD": "your-password",
        "NEO4J_DATABASE": "neo4j"
      }
    }
  }
}
```

Replace `/path/to/python3` with your Python binary (e.g. `~/.pyenv/versions/3.12.0/bin/python3`).

---

## OpenCode — HTTP

Start the server first (set env vars in your shell or `.env`):
```bash
NEO4J_PASSWORD=your-password ckg-mcp --profile your-profile --transport streamable-http --port 8000
```

`.opencode/config.json`:
```json
{
  "mcp": {
    "ckg": {
      "type": "remote",
      "url": "http://127.0.0.1:8000/mcp"
    }
  }
}
```

---

## Claude Desktop

`~/Library/Application Support/Claude/claude_desktop_config.json`:
```json
{
  "mcpServers": {
    "ckg": {
      "command": "/path/to/python3",
      "args": ["-m", "ckg_mcp.server", "--profile", "your-profile-name"],
      "env": {
        "NEO4J_URI": "bolt://localhost:7687",
        "NEO4J_USERNAME": "neo4j",
        "NEO4J_PASSWORD": "your-password",
        "NEO4J_DATABASE": "neo4j"
      }
    }
  }
}
```

---

## VS Code (Copilot Chat)

`.vscode/mcp.json`:
```json
{
  "servers": {
    "ckg": {
      "type": "stdio",
      "command": "/path/to/python3",
      "args": ["-m", "ckg_mcp.server", "--profile", "your-profile-name"],
      "env": {
        "NEO4J_URI": "bolt://localhost:7687",
        "NEO4J_USERNAME": "neo4j",
        "NEO4J_PASSWORD": "your-password",
        "NEO4J_DATABASE": "neo4j"
      }
    }
  }
}
```

To register skills in VS Code Copilot, add to `.vscode/settings.json`:
```json
{
  "github.copilot.chat.codeGeneration.instructions": [
    { "file": ".opencode/skills/blast-radius/SKILL.md" },
    { "file": ".opencode/skills/get-code-flow/SKILL.md" },
    { "file": ".opencode/skills/openspec-ckg-recon/SKILL.md" },
    { "file": ".opencode/skills/openspec-ckg-verify/SKILL.md" }
  ]
}
```

This requires a project-scoped install (`./install.sh --project`).

---

## LibreChat

1. Go to **Agents** → create a new Agent
2. Set the model (Claude, GPT-4o, etc.)
3. Paste the content of `skills/<skill-name>/SKILL.md` (everything after the `---` frontmatter) as the **System Prompt**
4. Connect the CKG MCP server as a tool (via LibreChat's MCP tool integration)
5. Save the Agent

Create one Agent per skill for clarity. The `blast-radius` skill also benefits from a GitHub MCP tool attached to the same Agent.

---

## Verifying the Connection

Once configured, ask your agent:
```
Use the CKG MCP tool get_graph_schema and tell me what's in the graph.
```

A working connection returns node counts, edge counts, repo breakdown, and schema version.
