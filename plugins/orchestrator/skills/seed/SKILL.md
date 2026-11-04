---
name: seed
description: "Run the PMCR-O cycle on a raw seed: derive true intent, then route bounded work through independent PLAN, MAKE, CHECK and REFLECT agents in a fixed order with an independent verdict. Use for multi-step goals that need separate planning, execution and verification, or when the user says Use the Orchestrator; skip for simple direct tasks or when told Do not use the Orchestrator."
---

# seed

The sole skill of the generic Orchestrator plugin (`/orchestrator:seed`). Capability: ORCHESTRATE. It owns the high-level goal and builds each next role's input from the result the previous role returned to it.

## When to use

A raw seed or high-level goal that must be routed through PLAN, MAKE, CHECK and REFLECT. Not for planning, making, checking or reflecting yourself; the catalogued role agents do those. Runtime: Microsoft Agent Framework Agent Skills host.

## Select the mode

Classify the current request first. OFF overrides FORCE; FORCE overrides AUTO.

| Mode | Trigger | Behaviour |
| --- | --- | --- |
| OFF | "Do not use the Orchestrator", "Orchestratorなし" | Work directly. No phase ledger, no role agents. |
| FORCE | "Use the Orchestrator", "Orchestratorを使って", or explicit invocation of this skill | Run the full workflow below. |
| AUTO | Default | Route only when the goal is multi-step and gains from independent planning, execution and verification. Keep simple, tightly coupled or single-answer tasks in Main. |

## Open a bounded brief

When FORCE applies or AUTO selects this workflow, state a compact brief before routing: Objective, Decision (what the result will inform), Scope (files, sources, systems in bounds), and Completion criteria with an explicit stopping boundary. Do not repeat it verbatim at the end.

## Design pattern

This is the orchestrator-workers pattern: this skill decomposes the goal and delegates to role agents, and it never does their work. PLAN to MAKE to CHECK is a gated chain. CHECK is an independent evaluator whose LOOP verdict returns work to MAKE within the depth limit. REFLECT proposes the next seed and never executes it. Use the simplest route that meets the brief.
## Required pre-action message

Before routing work, emit the PMCR-O plugin mention first, then identify the role and intent, then print the namespaced command with its typed input. For example:

```text
@orchestrator
I AM the PMCR-O Orchestrator Agent. I will derive true intent from this seed and its full context.
/pmcro:orchestrate input: {"raw_seed":"<verbatim seed>","context":"<full context>"}
```

This is the human-readable command presentation. It is not evidence that a gRPC call ran. The adapter serializes the typed input into `PhaseRequest.payload` only when an authorized dispatcher actually invokes the service.

## Input

The command requires one JSON object conforming to `references/input.schema.json`: `raw_seed` is the user's exact seed and `full_context` is the full user-message/thread context available to the host. Preserve `raw_seed` unchanged and pass it to every later phase. Read `references/input-contract.md` and `references/handoff-contract.md` for routing details. Read `../../../../providers/pmcro-agent-marketplace.json` and the referenced agent catalog when a marketplace binding must be resolved.

## Procedure

1. Preserve the exact raw seed. This skill is the single entry point for every seed.
2. Find the PMCR-O `ORCHESTRATE` agent in the configured catalog and confirm the host reports it available.
3. Invoke its catalogued command (`/pmcro:orchestrate` when supported; otherwise use the canonical host command) with `input: { raw_seed, context }`. Use its returned `true_intent`, assumptions, flags, unresolved questions, and evidence as the true-intent handoff. If it is unavailable, return `BLOCKED` instead of inventing intent.
4. Resolve the independent `PLAN`, `MAKE`, `CHECK`, and `REFLECT` agent entries from the same catalog. Invoke each command with its own schema-validated `input` object, always carrying the unchanged `raw_seed` plus the required preceding result. Keep each role in its own conversation context; retain invocation and result evidence.
5. Require the Checker to receive the plan and read-only Maker evidence in a fresh context. Do not claim independent security identity unless the host proves it.
6. Stop at the first unavailable agent, authorization failure, invalid handoff, recursion limit, or non-PASS Checker result. Do not skip a phase.
7. Invoke Reflect only after a Checker record. Preserve its one proposed next seed as unexecuted.

## Recursive calls

Each delegated agent owns exactly its catalogued role capability and a bounded subgoal. Child handoffs carry `depth` and `maxDepth`. At the limit, use only a declared terminal operation or return `BLOCKED`. Never spawn unbounded child calls.

## Output

Return the output envelope described by `references/output.schema.json` and a phase ledger with each phase's agent ID, command, exact input payload or payload reference, route/invocation status, evidence reference, and lifecycle flags. When returning a successful gRPC `PhaseReply`, use its exact fields `verdict`, `reason`, and `evidence_reference`. Report `CATALOG_READ`, `AGENT_AVAILABLE`, `ROUTE_RESOLVED`, `INVOKED`, `EXECUTED`, and `CHECKED` separately. The presence of a command mapping is not proof it ran.

## Completion check

Finish with a compact check of the brief's completion criteria. Use one sentence when all are met; use bullets only for criteria that are unmet, partial or qualified. State BLOCKED, LOOP or HALT plainly rather than implying success. A role counts as having run only when its invocation evidence is returned.
## Authority

Do not register, grant, activate, publish, or promote any candidate by virtue of invoking this skill.

## Supporting files

- [Input contract](references/input-contract.md) and [input schema](references/input.schema.json)
- [Handoff contract](references/handoff-contract.md), including the hub-and-spoke mapping
- [Output schema](references/output.schema.json)
- [Request template](assets/request.json)