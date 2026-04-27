# End-to-End Workflow Guide

Complete guide for using CKG-powered, spec-driven development on any project backed by a CKG graph.

**Workflow:** `recon → propose → specs → design → tasks → verify → apply → archive`

---

## Prerequisites

- Neo4j running with your codebase ingested as a CKG profile
- CKG MCP server running and connected to your agent client
- OpenSpec initialized in your project (`openspec/` directory exists)
- `ckg-aware` schema active (`schema: ckg-aware` in `openspec/config.yaml`)

Start the MCP server:
```bash
ckg-mcp --profile your-profile-name
```

Verify everything is working:
```bash
openspec schemas   # should list "ckg-aware"
```

---

## Step 0: (Optional) Check Graph Health

Ask your agent:
```
Use CKG get_graph_schema and give me an overview of the graph.
```

Expected output: function/file counts, repo breakdown, schema version.

---

## Step 1: Recon

Before proposing, understand the structural landscape.

Ask your agent:
```
I want to <describe your change>. Run recon first.
```

**Examples:**
```
I want to add OVSDB event tracking when bm_kick fires. Run recon on bm_kick first.
I want to refactor target_init to accept a config struct. Run recon.
Recon the wifi_hal module before I propose changes.
```

The `openspec-ckg-recon` skill runs:
1. Locates target functions in the graph
2. Traces callers and callees (depth 3)
3. Computes blast radius and risk score
4. Shows function signatures with `file:line` references
5. Presents options: **proceed / dig deeper / adjust scope / abort**

Pick an option. If "proceed", continue to Step 2.

---

## Step 2: Create the Change

```bash
openspec change new --name your-change-name
```

Use kebab-case. Example:
```bash
openspec change new --name bm-kick-event-tracking
```

This creates `openspec/changes/your-change-name/` ready for artifacts.

---

## Step 3: Propose

Ask your agent:
```
openspec propose --change your-change-name
```

The `ckg-aware` proposal template prompts the agent to:
- Describe **Why** and **What Changes**
- List capabilities (each becomes a spec file)
- Fill **Blast Radius (from CKG)** using `get_impact_radius`

**Output:** `openspec/changes/your-change-name/proposal.md`

Review the blast radius table. If the risk score is unexpectedly high, re-run recon to dig into the callers.

---

## Step 4: Specs

```
openspec instructions specs --change your-change-name
```

The agent creates one spec file per capability listed in the proposal:
`openspec/changes/your-change-name/specs/<capability>/spec.md`

The `ckg-aware` schema instructs the agent to use `get_code_snippet` to verify function signatures before specifying interfaces.

Specs use `### Requirement:` + `#### Scenario:` format (WHEN/THEN). Each scenario is a potential test case.

---

## Step 5: Design

```
openspec instructions design --change your-change-name
```

The `ckg-aware` design template prompts the agent to fill:
- **Dependencies from Graph** — `trace_call_path` inbound/outbound tables
- **Cross-Repo Impact** — `get_impact_radius` cross-repo summary
- **Decisions** — with graph evidence (e.g. "bm_kick has 14 callers — wrapper approach safer")
- **Risks** — including high-degree hub function risks from the graph

**Output:** `openspec/changes/your-change-name/design.md`

---

## Step 6: Tasks

```
openspec instructions tasks --change your-change-name
```

The `ckg-aware` tasks template instructs the agent to:
- Order tasks **leaf-first** (modify low-caller functions before hub functions)
- Mark cross-repo tasks with `[CROSS-REPO]`
- Group by repo when changes span multiple repositories

**Output:** `openspec/changes/your-change-name/tasks.md`

---

## Step 7: Verify (Gap Analysis)

Ask your agent:
```
Verify my change your-change-name against the graph.
```

The `openspec-ckg-verify` skill:
1. Reads all 4 artifacts
2. Extracts every claimed function, file, and repo
3. Queries the graph for ground truth
4. Reports gaps (uncovered callers, missing cross-repo impact, etc.)
5. Presents options: **update design / add tasks / accept gaps / re-scope**

**High-value gaps to act on:**
- **Type B: Uncovered Callers** — functions that call your modified code but aren't in tasks
- **Type C: Missing Cross-Repo Impact** — the graph shows cross-repo edges your design doesn't mention
- **Type F: Uncovered Repos** — repos touched by the change not mentioned anywhere

---

## Step 8: Apply

Once the plan looks solid:
```
openspec apply --change your-change-name
```

Or ask your agent:
```
Implement the tasks in change your-change-name.
```

The agent works through `tasks.md` checkbox by checkbox. The `ckg-aware` apply instruction tells it to run `trace_call_path` before modifying hub functions to confirm all callers are accounted for.

---

## Step 9: Archive

When implementation is complete and reviewed:
```bash
openspec archive your-change-name
```

This merges the delta specs into the main specs at `openspec/specs/<capability>/spec.md` and closes the change.

---

## Quick Reference

| Step | Command / Prompt |
|---|---|
| Start MCP server | `ckg-mcp --profile your-profile` |
| Recon | "Run recon on `<function>` before I propose changes" |
| Create change | `openspec change new --name your-change-name` |
| Propose | `openspec propose --change your-change-name` (in agent) |
| Specs | `openspec instructions specs --change your-change-name` |
| Design | `openspec instructions design --change your-change-name` |
| Tasks | `openspec instructions tasks --change your-change-name` |
| Verify | "Verify change `your-change-name` against the graph" |
| Apply | `openspec apply --change your-change-name` (in agent) |
| Archive | `openspec archive your-change-name` |

---

## What Happens Without the Graph

The `ckg-aware` schema degrades gracefully when CKG MCP is not connected:
- Template sections say "Graph unavailable — verify manually"
- Skills say "CKG MCP server is not connected" and stop

You can still run the full OpenSpec workflow manually — you just lose the structural intelligence. Reconnect the MCP server and re-run the relevant step to fill in graph data.

---

## Example: bm Kick Event Tracking (opensync)

```
Feature: Write a row to Band_Steering_Kick_Events table whenever
         bm_kick or bm_sticky triggers a steering kick.
Profile: opensync-xb8 (3 repos: opensync-core, opensync-platform-rdk, opensync-vendor-comcast)
```

Full walk-through:

1. `"Run recon on bm_kick and bm_sticky_kick for OVSDB event tracking"`
   → Graph shows bm_kick has 14 callers, 2 cross-repo edges. Risk: Medium.

2. `openspec change new --name bm-kick-event-tracking`

3. Agent proposes: new capability `kick-event-tracking`, blast radius table shows 14 directly affected functions.

4. Specs: `### Requirement: Kick event SHALL be recorded in OVSDB` with scenarios.

5. Design: Dependencies from Graph table shows all 14 callers. Decision: new `bm_kick_event_record()` wrapper to avoid touching callers.

6. Tasks ordered leaf-first: create helper → integrate into bm_kick → integrate into bm_sticky_kick → add dedup logic → tests.

7. Verify: Coverage Summary shows all callers accounted for. 0 gaps. Proceed.

8. Apply: agent implements tasks in order.

9. `openspec archive bm-kick-event-tracking`
