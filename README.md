# ckg-agent-kit

Agent skills and OpenSpec schema for projects backed by the [Code Knowledge Graph (CKG)](https://github.com/rdk-gdcs/ml-smart-guidance/).

Drop into any project to get graph-powered AI workflows: blast radius analysis, call flow tracing, and spec-driven development with real structural data baked in.

---

## What's Inside

| Component | Location | Purpose |
|---|---|---|
| **blast-radius** skill | `skills/blast-radius/` | Risk score + blast radius for a PR or local diff |
| **get-code-flow** skill | `skills/get-code-flow/` | Full call flow for a function (callers + call tree) |
| **openspec-ckg-recon** skill | `skills/openspec-ckg-recon/` | Structural recon before proposing a change |
| **openspec-ckg-verify** skill | `skills/openspec-ckg-verify/` | Post-spec gap analysis against the graph |
| **ckg-aware** schema | `schema/ckg-aware/` | OpenSpec schema with CKG sections in every template |
| **Example config** | `config/openspec-config.example.yaml` | Drop-in `openspec/config.yaml` for any project |

All skills are **harness-agnostic** — they work in OpenCode, Claude Desktop, LibreChat, VS Code Copilot, or any MCP-capable agent.

---

## Prerequisites

1. **CKG MCP server** — the skills call CKG MCP tools. Install and run it:
   ```bash
   pip install ckg-mcp
   ckg-mcp --profile <your-profile>
   ```
   See the [ckg-mcp docs](https://github.com/your-org/joern-KG-builder/tree/main/ckg/mcp) for Neo4j setup and client configuration.

2. **OpenSpec** (for `openspec-ckg-recon` and `openspec-ckg-verify`):
   ```bash
   npm install -g @fission-ai/openspec
   ```

---

## Install

```bash
git clone https://github.com/your-org/ckg-agent-kit
cd ckg-agent-kit

# Global install (skills available in every project)
./install.sh --global

# Project-scoped install (skills only in current project)
cd /path/to/your/project
/path/to/ckg-agent-kit/install.sh --project
```

### What `--global` installs

```
~/.config/opencode/skills/
  blast-radius/SKILL.md
  get-code-flow/SKILL.md
  openspec-ckg-recon/SKILL.md
  openspec-ckg-verify/SKILL.md

~/.local/share/openspec/schemas/
  ckg-aware/
    schema.yaml
    templates/{proposal,design,tasks,spec}.md
```

OpenCode auto-discovers skills from `~/.config/opencode/skills/`. No further configuration needed for OpenCode.

For other clients (LibreChat, VS Code Copilot), see [docs/CLIENTS.md](docs/CLIENTS.md).

---

## Activate in a Project

After installing, tell your project to use the `ckg-aware` OpenSpec schema:

```bash
# Option A: copy the example config
cp /path/to/ckg-agent-kit/config/openspec-config.example.yaml openspec/config.yaml

# Option B: manually set
echo 'schema: ckg-aware' > openspec/config.yaml
```

Verify:
```bash
openspec schemas   # should list "ckg-aware" with description
```

---

## Usage

### Skill: blast-radius

Ask your agent:
```
What's the blast radius of my current changes?
Analyze the risk of PR #42.
```

### Skill: get-code-flow

Ask your agent:
```
Trace the call flow for bm_kick.
Who calls target_init and what does it call?
```

### Skill: openspec-ckg-recon

Ask your agent before starting a proposal:
```
I want to add OVSDB event tracking for bm kick events. Run recon first.
Recon the bm_sticky module before I propose changes.
```

### Skill: openspec-ckg-verify

Ask your agent after writing specs/design:
```
Verify my change bm-kick-event-tracking against the graph.
Check if my design covers all callers of bm_kick.
```

---

## Full Workflow

See [docs/WORKFLOW.md](docs/WORKFLOW.md) for the complete end-to-end guide:  
`recon → propose → specs → design → tasks → verify → apply → archive`

---

## Skill Reference

See [docs/SKILLS.md](docs/SKILLS.md) for trigger phrases, step-by-step logic, and output format for each skill.

---

## MCP Client Configuration

See [docs/CLIENTS.md](docs/CLIENTS.md) for connection instructions for:
- OpenCode (stdio + HTTP)
- Claude Desktop
- VS Code Copilot
- LibreChat

---

## Uninstall

```bash
./uninstall.sh --global    # remove global install
./uninstall.sh --project   # remove project-scoped install
```

---

## License

MIT
