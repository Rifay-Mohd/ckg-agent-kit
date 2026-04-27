---
name: get-code-flow
description: Trace the complete call flow for a function — callers, callees, and execution tree. Use when user asks about call chains, code flow, "who calls X", "what does X call", or function dependencies.
license: MIT
compatibility: Requires CKG MCP server.
metadata:
  author: ckg
  version: "1.1"
---

Trace the complete call flow for a function using the Code Knowledge Graph. Shows who calls it, what it calls, and the full execution tree — with cross-repo edges highlighted.

**This is a workflow, not a conversation.** Follow every step exactly. Produce the full output template every time — no sections may be skipped, abbreviated, or omitted regardless of what the data contains.

---

## Input

Extract the function name from the user's request.

Examples:
- "trace the flow of target_init" -> `target_init`
- "who calls bm_kick and what does it call?" -> `bm_kick`
- "code flow for cm2_ovsdb_init" -> `cm2_ovsdb_init`

If no function name can be extracted, ask:
> "Which function do you want to trace? Give me the function name."

---

## Step 1: Get Function Metadata

```
ckg search_graph(name_pattern="<function_name>", limit=5)
```

### If exactly one match:
Save its `name`, `qualified_name`, `file`, `repo`, `line_start`.

### If multiple matches:
Present a numbered list and ask the user to pick:

```
Multiple functions match "<name>":

1. target_init — opensync-platform-rdk/src/lib/target/target_init.c:42
2. target_init — opensync-core/src/lib/target/target_stub.c:18

Which one? (number)
```

Wait for the user's answer before proceeding. Never guess.

### If no matches:
Tell the user clearly:
> "No function named '<name>' found in the graph. Check the spelling or try a partial name."

Stop here. Do not proceed with empty data.

---

## Step 2: Trace Callers and Callees

```
ckg trace_call_path(
  function_name="<qualified_name or name>",
  direction="both",
  depth=3
)
```

From the response, extract:
- **Inbound edges** — functions that call this function (callers). Count them.
- **Outbound edges** — functions this function calls (callees). Count them.
- **Cross-repo edges** — edges where caller repo != callee repo. Note each one.

If `direction="both"` returns no data, retry with `direction="inbound"` then `direction="outbound"` separately.

---

## Step 3: Get Full Outbound Call Tree

```
ckg get_flow(
  flow_name="<function_name>",
  max_depth=5
)
```

This returns the full outbound call tree as a list of nodes with depth levels. Use this to build the tree view in the output.

If the tool returns a warning about the function not being an entry point, ignore the warning and use the call tree data anyway. The outbound tree is always shown.

**If the function has 0 outbound callees** (leaf function): skip this tool call. The Call Tree section will show "(leaf function — no outbound calls)".

---

## Step 4: Format Output

**Produce every section below. No section may be omitted — not even if it is empty.**

```
## Code Flow — {function_name}

**Location:** {repo}/{file}:{line_start}
**Degree:** {total} ({inbound} inbound, {outbound} outbound)

### Callers ({count})
  {caller_name} ({caller_repo}) -> {function_name}
  {caller_name} ({caller_repo}) -> {function_name}  <-cross-repo
  [... all callers listed ...]

### Call Tree
  {function_name}
  |-- {callee_1} ({repo})  <-cross-repo
  |   |-- {sub_callee_a}
  |   +-- {sub_callee_b}
  |-- {callee_2}
  |   +-- {sub_callee_c}
  +-- {callee_3} ({repo})  <-cross-repo
```

### Section: Callers

- List every direct caller (depth=1 from `trace_call_path` inbound results).
- Format: `  {caller_name} ({caller_repo}) -> {function_name}`
- Append `  <-cross-repo` if the caller is in a different repo than the function.
- If 0 callers: show `  (none — this is an entry point)`
- If more than 15 callers: show 15 then `  (and N more)`

### Section: Call Tree

- Build from `get_flow` results using depth levels.
- Root is always the function itself on the first line.
- Use `|--` for intermediate children, `+--` for the last child at each level.
- Use `|   ` (pipe + 3 spaces) for vertical continuation lines.
- Use `    ` (4 spaces) for blank indentation under a last child.
- Annotate cross-repo nodes: append `  <-cross-repo` and show repo in parentheses.
- If 0 outbound callees: show `  (leaf function — no outbound calls)` under the root.

**Correct tree example (copy this style exactly):**
```
bm_events_init
|-- bm_events_setup_timer
|   |-- evsched_task_new
|   +-- evsched_task_start
|-- bm_events_register_cb
|   +-- target_bsal_register  (opensync-platform-rdk)  <-cross-repo
+-- bm_events_log_init
    +-- dlog_open
```

**Leaf function example:**
```
bm_kick_get_kick_type_str
  (leaf function — no outbound calls)
```

---

## Output Rules

Every rule is mandatory. There are no exceptions.

1. **All sections present.** The output must contain exactly these sections in this order: header, Location, Degree, Callers, Call Tree. If a section has no data, show it with the "(none)" or "(leaf)" placeholder. Never omit a section.

2. **No prose paragraphs.** No introductory text, no explanatory sentences, no summaries. The template is the entire output.

3. **No raw JSON.** Never print tool response objects. Extract values and build the template.

4. **Cross-repo always annotated.** Every cross-repo edge gets `<-cross-repo`. No exceptions.

5. **Repo name shown selectively.** Show `(repo_name)` only on nodes in a different repo than the root function. Same-repo nodes have no repo annotation.

6. **Callers = direct callers only.** Do not recurse callers. Show depth=1 callers from `trace_call_path`.

7. **Call Tree depth.** Default 5 levels. If the user asks for more, re-run `get_flow` with a higher `max_depth`.

8. **Degree counts.** `inbound` = count of direct callers. `outbound` = count of direct callees (not the full recursive count).

9. **Never guess on ambiguous matches.** Always present the numbered list and wait for user input.

---

## Guardrails

- **Read-only.** Never write code, create files, or modify anything. Only read the graph.
- **No hallucinated edges.** Only show relationships that exist in the graph data. If 0 callers, say so.
- **Clean errors.** On CKG MCP error: output `CKG MCP error: {message}`. Do not retry silently.
- **One function at a time.** For multiple functions, run the full workflow for each separately. Do not merge outputs.
- **Leaf functions still get the full template.** A function with 0 outbound calls is not a reason to skip sections or produce abbreviated output.

---

## Model Compatibility Note

This skill must produce identical output regardless of the underlying model. Weaker instruction-following models (GPT-family, etc.) must follow the same template as stronger ones (Claude, etc.).

If you are tempted to shorten the output because the function is simple, has no callees, or has few callers — **do not**. The template is always produced in full. A leaf function with 3 callers and 0 callees still produces all four sections.

