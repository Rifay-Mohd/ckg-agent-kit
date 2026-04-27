---
name: openspec-ckg-verify
description: Post-spec gap analysis — verify OpenSpec artifacts against the CKG graph. Use when user says "verify change", "check my spec against the graph", "are we missing anything", or after completing openspec propose/specs/design to validate coverage.
license: MIT
compatibility: Requires CKG MCP server. Requires an active OpenSpec change with at least proposal.md.
metadata:
  author: ckg
  version: "1.0"
---

Verify OpenSpec artifacts (proposal, specs, design, tasks) against the Code Knowledge Graph. Finds gaps: functions the spec claims to modify but that don't exist, callers not accounted for in tasks, cross-repo impacts missing from the design, and more.

**This is a workflow, not a conversation.** Follow the steps in order. Produce the output template exactly. Then present options and wait.

---

## Input

The user has an active OpenSpec change. Determine which artifacts exist.

### Locate Artifacts

Check for the active change directory. Try these paths in order:
1. `openspec/changes/current/` (if openspec uses a "current" symlink)
2. Ask the user: "Which change should I verify? Give me the change name or path."

Read whichever artifacts exist:
- `proposal.md` (required — stop if missing)
- `specs/**/*.md` (optional)
- `design.md` (optional)
- `tasks.md` (optional)

If `proposal.md` doesn't exist:
> "No proposal found. Run `openspec propose` first, then I can verify it."

Stop here.

---

## Step 1: Extract Claims from Artifacts

Parse each artifact to build a **claims list** — what the spec says the change will touch.

### From proposal.md:
- Files mentioned in "Impact" or "Blast Radius" sections
- Function names mentioned anywhere
- Repos mentioned

### From specs:
- Function names or APIs referenced in requirements/scenarios
- File paths mentioned

### From design.md:
- Functions listed in "Dependencies from Graph" tables
- Cross-repo impacts claimed
- Risk score claimed (if any)

### From tasks.md:
- Functions or files mentioned in task descriptions
- Tasks marked `[CROSS-REPO]`

Build a combined list:
- **Claimed files**: all files mentioned across all artifacts
- **Claimed functions**: all function names mentioned
- **Claimed repos**: all repos mentioned
- **Claimed cross-repo**: whether any artifact mentions cross-repo impact

---

## Step 2: Query Graph for Ground Truth

### 2a. Verify claimed functions exist

For each claimed function name:

```
ckg search_graph(name_pattern="<function_name>", limit=5)
```

Categorize each as:
- **Found** — exists in graph
- **Not found** — doesn't exist (typo? wrong name? not in ingested repos?)
- **Ambiguous** — multiple matches, spec doesn't clarify which one

### 2b. Get actual blast radius

Collect all claimed files. Run:

```
ckg get_impact_radius(
  changed_files=[...],
  detail_level="standard"
)
```

### 2c. Get actual callers of modified functions

For each claimed function that was found:

```
ckg trace_call_path(
  function_name="<qualified_name>",
  direction="inbound",
  depth=2
)
```

Collect all direct callers (depth=1).

### 2d. Get affected flows

```
ckg get_affected_flows(
  changed_files=[...]
)
```

---

## Step 3: Compute Gaps

Compare claims vs. graph truth. Identify:

### Gap Type A: Missing Functions
Functions the spec mentions but that don't exist in the graph.
> Cause: typo, wrong name, function is in a repo not yet ingested, or function was removed.

### Gap Type B: Uncovered Callers
Functions that call the modified functions (from graph) but are NOT mentioned in tasks.md.
These callers might break and nobody planned to update them.
> This is the highest-value gap. It catches forgotten ripple effects.

### Gap Type C: Missing Cross-Repo Impact
The graph shows cross-repo call edges through the changed code, but design.md doesn't mention cross-repo impact (or the section says "None").

### Gap Type D: Missing Flows
Execution flows that pass through the changed code but aren't mentioned in any artifact.

### Gap Type E: Risk Mismatch
The graph's risk score differs significantly from what was claimed in the proposal/design (if a score was claimed). "Significantly" = more than 2 points difference.

### Gap Type F: Uncovered Repos
The graph shows impact in repos that aren't mentioned in any artifact.

---

## Step 4: Format Output

```
## Spec Verification — {change name}

### Artifacts Analyzed
- [x] proposal.md
- [{x or space}] specs/ ({N} spec files)
- [{x or space}] design.md
- [{x or space}] tasks.md

### Coverage Summary

| Metric | Claimed | Graph Actual | Status |
|---|---|---|---|
| Functions modified | {N} | {N} | {OK / GAP} |
| Files touched | {N} | {N} | {OK / GAP} |
| Repos involved | {list} | {list} | {OK / GAP} |
| Cross-repo impact | {yes/no} | {yes/no} | {OK / GAP} |
| Risk score | {claimed or "—"} | {actual} | {OK / GAP / —} |

### Gaps Found ({total count})

#### {Gap Type}: {title}
{description}

| {columns relevant to gap type} |
|---|
| {data} |

**Severity: {High / Medium / Low}**

(Repeat for each gap found.)

### No Gaps

(If zero gaps found, replace the Gaps section with:)
All claimed functions, files, and cross-repo impacts verified against graph. No coverage gaps detected.

### Next Steps

{numbered options — see below}
```

---

## Step 5: Present Options and Wait

After producing the output, present options based on what gaps were found:

### If gaps were found:

```
Gaps detected. What would you like to do?

1. **Update design** — add missing cross-repo impacts and dependencies to design.md
2. **Add tasks** — create tasks for uncovered callers and flows
3. **Accept gaps** — these are known and acceptable, proceed anyway
4. **Re-scope** — the change scope needs adjustment based on this analysis
5. **Re-run recon** — I want to explore specific gap areas more deeply
```

### If no gaps:

```
Verification passed. What next?

1. **Proceed to implementation** — start `openspec apply`
2. **Run deeper analysis** — trace specific function chains or flows
3. **Done** — no further action needed
```

Wait for the user's response. Do not proceed automatically.

---

## Output Rules

1. **No prose paragraphs.** Tables, checklists, and the template. No explanatory text outside the template.
2. **No raw JSON.** Extract values from tool responses into the template.
3. **Gap severity assignment:**
   - **High**: Uncovered callers (Type B), Missing cross-repo impact (Type C), Uncovered repos (Type F)
   - **Medium**: Missing flows (Type D), Risk mismatch (Type E)
   - **Low**: Missing functions that might be typos (Type A)
4. **Coverage Summary always present**, even if all statuses are OK.
5. **Gaps sorted by severity** — High first, then Medium, then Low.
6. **Uncovered Callers (Type B)** — always show the full list of uncovered callers with their repo and file. This is the most actionable gap.
7. **Max 20 items per gap table.** If more, show 20 and add "(and N more)".

---

## Guardrails

- **Read-only.** Never modify spec artifacts, code, or openspec state. Only read and analyze.
- **No hallucinated gaps.** Only report discrepancies between actual artifact text and actual graph data. If an artifact doesn't mention a function but the function isn't affected either, that's not a gap.
- **Never auto-fix.** Present options and wait. The user decides whether to update specs, add tasks, or accept gaps.
- **CKG required.** If CKG MCP is not connected: "CKG MCP server is not connected. I can't verify specs without it."
- **proposal.md required.** If no proposal exists, stop and tell the user to create one first.
- **Partial artifacts OK.** If only proposal.md exists (no design, no tasks), still run verification on what's available. The gaps will naturally reflect missing artifacts (e.g. "0 tasks cover 14 callers").
