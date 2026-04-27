# Skill Reference

Quick reference for all four CKG agent skills — trigger phrases, what each does, tools used, and output format.

---

## blast-radius

**When to use:** Any time you want to know the risk/impact of code changes before merging or reviewing.

**Trigger phrases:**
- "What's the blast radius of my current changes?"
- "Analyze the risk of PR #42"
- "What does this change break?"
- "Impact analysis for these files"

**MCP tools used:** `get_impact_radius`, `get_affected_flows` (+ GitHub MCP for PR analysis)

**Input paths:**
1. PR URL or number → fetches files + diff via GitHub MCP
2. "my current changes" → runs `git diff` locally
3. Manual file list → skips diff parsing

**Output:** Risk score (0–10 with label), risk breakdown table by component, affected flows, cross-repo impacts.

**Degrades gracefully:** If CKG MCP is not connected, says so clearly and stops.

---

## get-code-flow

**When to use:** You need to understand how a function fits into the codebase — who calls it, what it calls, cross-repo wiring.

**Trigger phrases:**
- "Trace the call flow for bm_kick"
- "Who calls target_init?"
- "What does cm2_ovsdb_init call?"
- "Show me the call chain for wifi_hal_init"

**MCP tools used:** `search_graph`, `trace_call_path`, `get_flow`

**Steps:**
1. `search_graph` — locate function, handle ambiguous matches
2. `trace_call_path(direction="both", depth=3)` — callers + callees
3. `get_flow(max_depth=5)` — full outbound call tree

**Output:** Location, degree (inbound/outbound counts), Callers list, Call Tree with cross-repo annotations.

**Rules:** All sections always present. Leaf functions still get the full template. Cross-repo edges always annotated.

---

## openspec-ckg-recon

**When to use:** Before proposing a change — get the structural landscape so the proposal is grounded in real code.

**Trigger phrases:**
- "Run recon on bm_kick before I propose changes"
- "Recon the bm module for OVSDB event tracking"
- "What would it take to change target_init?"
- "Analyze before proposing"

**MCP tools used:** `search_graph`, `trace_call_path`, `get_impact_radius`, `get_code_snippet`

**Steps:**
1. `search_graph` — locate target functions
2. `trace_call_path(direction="both", depth=3)` — direct callers and callees
3. `get_impact_radius` — blast radius + risk score
4. `get_code_snippet` — signatures only (full body if < 15 lines)

**Output:** Target Functions table, signatures with `file:line` references, Blast Radius table, Key Callers table, Cross-Repo Edges table (if any).

**Ends with:** Numbered options — proceed to proposal / dig deeper / adjust scope / abort. Waits for user response.

---

## openspec-ckg-verify

**When to use:** After writing an OpenSpec proposal (and optionally specs/design/tasks) — verify coverage against actual graph data.

**Trigger phrases:**
- "Verify my change bm-kick-event-tracking against the graph"
- "Check if my spec covers all callers"
- "Are we missing anything in the design?"
- "Gap analysis for my current change"

**MCP tools used:** `search_graph`, `trace_call_path`, `get_impact_radius`, `get_affected_flows`

**Steps:**
1. Read all artifacts: `proposal.md`, `specs/**/*.md`, `design.md`, `tasks.md`
2. Extract claims (functions, files, repos, cross-repo impact)
3. `search_graph` — verify each claimed function exists
4. `get_impact_radius` — actual blast radius
5. `trace_call_path(direction="inbound")` — actual callers of modified functions
6. `get_affected_flows` — actual execution flows through changed code

**Gap types detected:**
| Type | Description | Severity |
|---|---|---|
| A | Function in spec doesn't exist in graph | Low |
| B | Callers of modified functions not in tasks | **High** |
| C | Cross-repo impact not mentioned in design | **High** |
| D | Affected flows not mentioned in any artifact | Medium |
| E | Risk score significantly differs from claim | Medium |
| F | Repos touched not mentioned in artifacts | **High** |

**Output:** Artifacts checklist, Coverage Summary table (Claimed vs. Actual), gap list sorted by severity.

**Ends with:** Numbered options — update design / add tasks / accept gaps / re-scope / re-run recon. Waits for user response.
