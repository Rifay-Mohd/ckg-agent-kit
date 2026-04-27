## Context

<!-- Background and current state -->

## Goals / Non-Goals

**Goals:**
<!-- What this design aims to achieve -->

**Non-Goals:**
<!-- What is explicitly out of scope -->

## Dependencies from Graph

<!-- If CKG MCP is connected:
     1. Run trace_call_path on each primary function being modified (direction: both, depth: 3)
     2. List callers (inbound) and callees (outbound) in the tables below

     If CKG MCP is NOT connected, replace this section with:
     "Graph unavailable — verify dependencies manually." -->

### Inbound (who calls the modified functions)

| Caller | File | Repo |
|---|---|---|
| | | |

### Outbound (what the modified functions call)

| Callee | File | Repo |
|---|---|---|
| | | |

## Cross-Repo Impact

<!-- If CKG MCP is connected:
     1. Run get_impact_radius on the planned changed files
     2. Summarize cross-repo edges and risk score below

     If no cross-repo impact, write: "None — change is repo-local."
     If CKG MCP is NOT connected, write: "Graph unavailable." -->

| Metric | Value |
|---|---|
| Risk score | |
| Cross-repo call edges affected | |
| Repos touched | |

## Decisions

<!-- Key design decisions and rationale. For each decision:
     - What was decided
     - Why (with alternatives considered)
     - Graph evidence (e.g. "trace_call_path shows 14 callers — wrapper approach safer than signature change") -->

## Risks / Trade-offs

<!-- Known risks and trade-offs. Format: [Risk] → Mitigation
     Include graph-derived risks:
     - High-degree hub functions being modified (list degree from graph)
     - Cross-repo callers that may break
     - Flows passing through modified code -->

## Migration Plan

<!-- Steps to deploy, rollback strategy (if applicable). Skip if not needed. -->

## Open Questions

<!-- Outstanding decisions or unknowns to resolve -->
