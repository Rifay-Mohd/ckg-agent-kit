---
name: blast-radius
description: Analyze blast radius and risk score for a PR or local diff. Use when user asks about impact, risk, blast radius, or "what does this change break".
license: MIT
compatibility: Requires CKG MCP server. Optionally uses GitHub MCP for PR analysis.
metadata:
  author: ckg
  version: "1.0"
---

Analyze the blast radius and risk of code changes. Combines GitHub MCP (for PR data) and CKG MCP (for graph-based impact analysis) to produce a structured risk assessment.

**This is a workflow, not a conversation.** Follow the steps in order. Produce the output template exactly. No prose paragraphs, no info dumping.

---

## Input Detection

Determine the input source. Try in this order:

**1. PR link or number provided**
The user gave a GitHub PR URL (`https://github.com/owner/repo/pull/N`) or `owner/repo#N` or just `#N` with known context.
- Extract `owner`, `repo`, `pull_number`.
- Proceed to **Path A: PR Analysis**.

**2. No PR — use local git diff**
The user said "current changes", "my diff", "local changes", or gave no specific PR.
- Use shell to get the diff.
- Proceed to **Path B: Local Diff**.

**3. No shell available — ask user**
If shell commands are unavailable (e.g. LibreChat without shell access):
- Ask the user: "I don't have shell access. Please provide the list of changed files (one per line)."
- Proceed to **Path C: Manual Input** — skip diff parsing (Steps 2a and 2b).

---

## Step 1: Get Changed Files and Diff

### Path A: PR Analysis

```
github pull_request_read(method="get_files", owner=OWNER, repo=REPO, pullNumber=N)
→ Save the file list (path field from each entry)

github pull_request_read(method="get_diff", owner=OWNER, repo=REPO, pullNumber=N)
→ Save the raw diff for parsing in Step 2
```

### Path B: Local Diff

```bash
git diff --name-only          # changed files (unstaged)
git diff --cached --name-only # changed files (staged)
git diff                      # full diff (unstaged)
git diff --cached             # full diff (staged)
```

Combine both staged and unstaged. If both are empty, try `git diff HEAD~1 --name-only` for the last commit.

### Path C: Manual Input

Use the file list provided by the user. No diff available — skip Step 2.

---

## Step 2: Parse Diff for High-Risk Signals

Scan the diff to extract two lists. These are optional but significantly improve the risk score accuracy.

### 2a. Deleted Functions

Look for function definitions that appear in `-` (removed) lines but have no corresponding `+` (added) line re-adding them in the same hunk or file.

A function definition is a line containing a name followed by `(` that looks like a definition (not a call). Examples:
- `-void my_function(int arg1, char *arg2)`
- `-static int helper_func(void)`

Collect the function names (just the name, not the full signature).

### 2b. Signature Changes

Look for function definitions where the same function name appears in both `-` and `+` lines but with different parameter lists.

Example:
```diff
-void bm_kick(client_t *client, int reason)
+void bm_kick(client_t *client, int reason, bool force)
```

Collect the function names.

### Fallback

If you cannot confidently parse the diff (unfamiliar language, complex refactoring, etc.), skip this step entirely. The risk score still works without these inputs — it just won't include the deletion and signature components.

---

## Step 3: Query CKG

Make these two CKG MCP calls. Always make both.

### 3a. Impact Radius + Risk Score

```
ckg get_impact_radius(
  changed_files=[...],           # from Step 1
  deleted_functions=[...],       # from Step 2a (or omit)
  signature_changes=[...],       # from Step 2b (or omit)
  detail_level="standard"
)
```

This returns: affected functions, cross-repo impacts, and a deterministic risk score (0-10).

### 3b. Affected Flows

```
ckg get_affected_flows(
  changed_files=[...]            # from Step 1
)
```

This returns: which execution flows (entry-point call trees) pass through the changed code.

---

## Step 4: Format Output

Use this exact template. Fill in values from the tool responses.

```
## Blast Radius — {PR #N title | "Local Diff"}

**Risk: {score} / 10 — {label}**

### Changed Files ({count})
- {file1}
- {file2}
...

### Risk Breakdown
| Component     | Score | Weighted | Detail                       |
|---------------|-------|----------|------------------------------|
| Deleted funcs | {raw} | {w}      | {N} callers break            |
| Signature chg | {raw} | {w}      | {N} callers need updating    |
| Cross-repo    | {raw} | {w}      | {N} cross-repo edges         |
| Blast radius  | {raw} | {w}      | {affected}/{total} reached   |
| File spread   | {raw} | {w}      | {N} files                    |

### Affected Flows ({count})
1. {entry_func} -> ... -> {changed_func}
2. {entry_func} -> ... -> {changed_func}
...

### Cross-Repo Impacts
- {repo_a} -> {repo_b} ({N} edges)
...
```

---

## Output Rules

These rules are **mandatory**. Follow them exactly.

1. **No prose paragraphs.** Use tables, lists, and the template above. Never write explanatory paragraphs.

2. **No raw JSON.** Never dump tool response JSON to the user. Extract values into the template.

3. **Cross-repo impacts always shown** if any exist. This is the highest-value insight from the graph. If there are none, omit the "Cross-Repo Impacts" section entirely.

4. **Low risk = minimal output.** If the risk score is below 2.0 (Low), use a shortened format:
   ```
   ## Blast Radius — {title}

   **Risk: {score} / 10 — Low**

   {count} files changed, {affected} functions affected. No high-risk signals.
   ```

5. **Affected Flows** — show at most 10. Sort by number of affected-through functions (most impacted first). If more than 10, add "(and N more)" at the end.

6. **Risk Breakdown table** — omit rows where the raw score is 0.00 (e.g. if no functions were deleted, omit that row).

7. **File paths** — show the repo-relative path (e.g. `opensync-core/src/bm/src/bm_kick.c`), not absolute paths.

---

## Guardrails

- **Read-only.** This skill never modifies code, creates files, or writes to GitHub. It only reads and analyzes.
- **No hallucinated risk.** Only report what the graph data shows. If CKG returns 0 cross-repo impacts, don't speculate about hidden ones.
- **Score is deterministic.** The CKG risk score is a mathematical formula. Present it as-is. You may add a one-line assessment (e.g. "The cross-repo impact drives most of the risk") but keep it to one line.
- **Missing tools degrade gracefully.** If GitHub MCP is unavailable, fall back to local diff. If CKG MCP is unavailable, tell the user clearly: "CKG MCP server is not connected. I can't analyze blast radius without it."
