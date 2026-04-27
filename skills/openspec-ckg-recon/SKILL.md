---
name: openspec-ckg-recon
description: CKG-powered structural reconnaissance before proposing a change. Use when user says "recon", "analyze before proposing", "what would this change touch", or before running openspec propose on code that lives in the CKG graph.
license: MIT
compatibility: Requires CKG MCP server. Works with any OpenSpec schema but best with ckg-aware.
metadata:
  author: ckg
  version: "1.0"
---

Structural reconnaissance using the Code Knowledge Graph. Run this BEFORE proposing a change to understand what the change will actually touch, how risky it is, and which functions/files are involved.

**This is a workflow, not a conversation.** Follow the steps in order. Produce the output template exactly. Then present options and wait.

---

## Input

Extract the user's intent. They want to make a change but haven't started the proposal yet. Get:

1. **Target area** — which functions, files, modules, or features they plan to change
2. **Nature of change** — add, modify, remove, refactor, rename

Examples:
- "I want to refactor bm_kick to add a force parameter" -> target: `bm_kick`, nature: modify signature
- "recon before changing the OVSDB init flow" -> target: `cm2_ovsdb_init`, nature: modify flow
- "what would it take to remove legacy_connect?" -> target: `legacy_connect`, nature: remove function

If the target is unclear, ask:
> "What function(s) or file(s) are you planning to change?"

---

## Step 1: Locate Target Functions

For each function or file the user mentioned:

```
ckg search_graph(name_pattern="<name>", limit=10)
```

### If multiple matches:
Present numbered list, ask user to pick. Do not guess.

### If no matches:
Try broader search. If still nothing:
> "No function named '<name>' found in the graph. Is it spelled differently, or is it in a repo that hasn't been ingested?"

Stop here.

### Collect metadata:
For each confirmed function, save: `name`, `qualified_name`, `file`, `repo`, `line_start`, `line_end`.

---

## Step 2: Trace Dependencies

For each target function:

```
ckg trace_call_path(
  function_name="<qualified_name>",
  direction="both",
  depth=3
)
```

Extract:
- **Direct callers** (depth=1 inbound) — count and list
- **Direct callees** (depth=1 outbound) — count and list
- **Cross-repo edges** — caller/callee in different repo

---

## Step 3: Blast Radius

Collect all files containing target functions. Run:

```
ckg get_impact_radius(
  changed_files=[...],
  detail_level="standard"
)
```

If the change is a function removal, also pass `deleted_functions=[...]`.
If the change is a signature modification, also pass `signature_changes=[...]`.

Extract: risk score, affected function count, cross-repo impacts.

---

## Step 4: Get Signatures

For each target function, get the signature (NOT the full body):

```
ckg get_code_snippet(qualified_name="<qualified_name>")
```

From the response, extract only the function signature (first line through the opening `{`) and the `file:line_start-line_end` reference.

If the function is short (< 15 lines), include the full body. Otherwise, signature only.

---

## Step 5: Format Output

```
## CKG Recon — {description of change}

### Target Functions

| Function | Location | Callers | Callees | Cross-Repo |
|----------|----------|---------|---------|------------|
| {name} | {repo}/{file}:{line_start} | {N} | {N} | {yes/no} |

### Signatures

{function_name} — {repo}/{file}:{line_start}-{line_end}
```c
{signature or short body}
```

### Blast Radius

| Metric | Value |
|---|---|
| Risk score | {score} / 10 — {band} |
| Directly affected functions | {N} |
| Repos touched | {list} |
| Cross-repo call edges | {N} |

### Key Callers (most at risk)

| Caller | Repo | File |
|---|---|---|
| {name} | {repo} | {file}:{line} |

### Cross-Repo Edges

| From | To | Direction |
|---|---|---|
| {func} ({repo}) | {func} ({repo}) | {caller->callee} |

(If no cross-repo edges, omit this section.)

### Next Steps

{numbered options — see below}
```

---

## Step 6: Present Options and Wait

After producing the output, present exactly these options:

```
What would you like to do?

1. **Proceed to proposal** — I have enough context, start `openspec propose`
2. **Dig deeper** — trace more functions or explore a specific caller chain
3. **Adjust scope** — the change is bigger/smaller than I thought
4. **Abort** — this is too risky or complex, I need to rethink
```

Wait for the user's response. Do not proceed automatically.

---

## Output Rules

1. **No prose paragraphs.** Tables, lists, and the template. No explanatory text.
2. **No raw JSON.** Extract values from tool responses into the template.
3. **Signatures only, not full bodies** (unless function is < 15 lines). Full function bodies waste context.
4. **Cross-repo edges always highlighted.** This is the highest-value insight.
5. **File references use `file:line` format.** Always include line numbers. Example: `opensync-core/src/bm/bm_kick.c:142`
6. **Risk band labels**: 0-2 Low, 2-5 Medium, 5-8 High, 8-10 Critical.
7. **Key Callers table**: show at most 10 callers, sorted by those most likely to break (cross-repo first, then highest-degree).

---

## Guardrails

- **Read-only.** Never modify code, create files, or write proposals. This skill only reads and analyzes.
- **No hallucinated data.** Only report what the graph returns. If the graph has 0 cross-repo edges, don't speculate.
- **Never auto-proceed.** Always present the options and wait. The user decides what to do next.
- **CKG required.** If CKG MCP is not connected: "CKG MCP server is not connected. I can't run recon without it."
- **One recon at a time.** Don't combine multiple unrelated changes into one recon. If the user mentions several, ask which to start with.
