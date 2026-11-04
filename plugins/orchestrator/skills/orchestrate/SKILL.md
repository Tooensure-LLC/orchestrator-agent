---
name: orchestrate
description: >-
  Run the full PMCR-O cycle on a raw seed: derive true intent, then route
  bounded work through independent PLAN → MAKE → CHECK → REFLECT agents in
  fixed order with an independent verdict. Use when the user says "Use the
  Orchestrator", the goal is multi-step and benefits from separate planning/
  execution/verification, or FORCE mode is requested. Skip for simple direct
  tasks or when told "Do not use the Orchestrator".
metadata:
  author: Tooensure-LLC
  version: "0.2.0"
---

# orchestrate

Sole skill of the generic Orchestrator plugin. Capability: ORCHESTRATE.
Owns the high-level goal and builds each next role’s input from the previous
role’s result. Runtime: Microsoft Agent Framework Agent Skills host.

## When to use

- Multi-step goals that benefit from independent planning, execution and verification
- Explicit “Use the Orchestrator” / FORCE request
- Not for simple single-answer tasks or when the user says “Do not use the Orchestrator”

## Mode selection

OFF overrides FORCE; FORCE overrides AUTO.

| Mode  | Trigger                                      | Behaviour                                      |
|-------|----------------------------------------------|------------------------------------------------|
| OFF   | “Do not use the Orchestrator”                | Work directly; no phase ledger or role agents  |
| FORCE | “Use the Orchestrator” or explicit skill use | Run the full workflow below                    |
| AUTO  | Default                                      | Route only when the goal gains from separation |

## Design pattern

- **Orchestrator-workers** (hub-and-spoke): this skill is the only delegator. Roles never call each other.
- **Prompt chaining** with a gate: fixed order PLAN → MAKE → CHECK → REFLECT.
- **Evaluator-optimizer**: CHECK is an independent evaluator (PASS advances, HALT stops, LOOP may trigger one bounded, separately authorized revision of MAKE).
- REFLECT proposes the next seed; it stays unexecuted until a new cycle starts.

## Required pre-action message

```text
@orchestrator
I AM the PMCR-O Orchestrator Agent. I will derive true intent from this seed and its full context.
/pmcro:orchestrate input: {"raw_seed":"<verbatim seed>","context":"<full context>"}
```

This is human-readable presentation only; it is not proof a gRPC call ran.

## Input

One JSON object per `./references/input.schema.json`:
- `raw_seed` — exact original seed (preserve unchanged through every phase)
- `full_context` — full thread context available to the host; map this to `context` when invoking the PMCR-O ORCHESTRATE agent

See `./references/input-contract.md` and `./references/handoff-contract.md`.

## Procedure

1. Preserve the exact raw seed. This skill is the single entry point.
2. Locate the ORCHESTRATE agent in the configured catalog and confirm availability.
3. Invoke it with `{ raw_seed, context }`, mapping the validated `full_context` to `context`. Use returned `true_intent`, assumptions, flags, scope, unresolved questions, `validated_resources` and evidence as the true-intent handoff. Pass every required Planner field, including `scope` and `validated_resources`; if `validated_resources` is empty, stop as `BLOCKED` rather than planning from unvalidated resources. If the ORCHESTRATE agent is unavailable → `BLOCKED`.
4. Resolve independent PLAN, MAKE, CHECK and REFLECT agents. Invoke each with its own schema-validated input, always carrying the unchanged `raw_seed` plus the required preceding result. Keep each role in its own context; retain evidence.
5. Checker must receive the plan and read-only Maker evidence in a fresh context.
6. Stop on first unavailable agent, authorization failure, invalid handoff or recursion limit. Act on Checker verdict: PASS → Reflect; HALT → stop; LOOP → bounded revision. Never skip a phase.
7. Invoke Reflect only after a Checker record. Preserve its single proposed next seed as unexecuted.

## Revision loop (evaluator-optimizer)

A LOOP verdict means the work is fixable inside the same plan and authorized scope. Only the Orchestrator may start a revision:

1. At most `maxRevisions` (default 2, hard cap 3). Track in the phase ledger.
2. Build new MAKE input from unchanged `raw_seed`, same `plan_ref`, and an `authorized_step` limited to the failing checks. Never enlarge scope.
3. Require a fresh `authorization_ref`. If absent → `BLOCKED` / `REVISION_REQUESTED`.
4. Send each new receipt to a fresh read-only Checker context.
5. Stop with `partial` when the limit is reached or consecutive LOOPs cite the same failures. HALT stops immediately.
6. Report revision history in the final synthesis.

## Output

Return the envelope defined by `./references/output.schema.json` plus a phase ledger (agent ID, command, input/payload ref, route status, evidence ref, lifecycle flags). Report CATALOG_READ, AGENT_AVAILABLE, ROUTE_RESOLVED, INVOKED, EXECUTED and CHECKED separately.

## Completion check

Compact check of the brief’s completion criteria. One sentence when all met; bullets only for unmet/partial items. State BLOCKED / LOOP / HALT plainly. A role counts as run only when invocation evidence is present.

## Authority

Do not register, grant, activate, publish or promote any candidate by invoking this skill.

## Supporting files

- [Input contract](./references/input-contract.md) · [input schema](./references/input.schema.json)
- [Handoff contract](./references/handoff-contract.md)
- [Output schema](./references/output.schema.json)
- [Request template](./assets/request.json)
