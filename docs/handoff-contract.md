# Handoff contract

## Initial call

Invoke `/orchestrator:seed` with the user's exact messy seed and the full available message/thread context. Do not ask for a normalized seed first and do not rewrite `raw_seed`.

The Orchestrator resolves `orchestrator` from the configured agent catalog and calls `/pmcro:orchestrate` (or the catalogued canonical host command) with `{ raw_seed, context }`. That independent agent returns `true_intent`, assumptions, flags, unresolved questions, and evidence/context references. If the agent is unavailable, return `BLOCKED`; do not guess true intent.

## Sequential role handoffs

Every phase command must carry its own typed `input` payload and the exact unchanged `raw_seed`. Pass `{ raw_seed, true_intent, assumptions, flags }` to the Planner; `{ raw_seed, plan_ref, authorized_step }` to the Maker; `{ raw_seed, plan_ref, make_receipt }` to the Checker; and `{ raw_seed, check_verdict, evidence }` to the Reflector. Each invocation names the agent ID, command, parent handoff, bounded goal, scope, depth, and expected output type.

Use one independent conversation context per role. A task title uses the pattern `Role: concise bounded goal`, for example `Plan: speech-to-text requirements`. Keep the Checker context fresh and read-only. A title or separate chat does not establish security-principal independence.

## Stop rules

Stop when any required agent cannot be resolved or invoked, a handoff fails validation, authorization is absent, recursion reaches its depth limit without a terminal operation, or the Checker returns anything other than PASS. Reflect only after a Checker record. Do not treat a proposed next seed as executed work.

## Output states

Use `TRUE_INTENT_READY`, `PLAN_READY`, `STEP_EXECUTED`, `CHECK_PASS`, `REFLECTED`, `PARTIAL`, `BLOCKED`, and `UNEXECUTED` with evidence and owner. Never infer a later lifecycle state from catalog discovery or command resolution.


## Hub-and-spoke handoff mapping

Roles never call each other. Each role returns its result to the Orchestrator, and the Orchestrator builds the next role's input from that result. Order is fixed: ORCHESTRATE, PLAN, MAKE, CHECK, REFLECT. `raw_seed` is carried unchanged into every input.

| Returned to Orchestrator | Next command input built by the Orchestrator |
| --- | --- |
| ORCHESTRATE result: `true_intent`, `assumptions`, `flags`, `scope`, `unresolved_questions`, `validated_resources` | `/planner:plan` (route alias `/pmcro:plan`): `{ raw_seed, true_intent, assumptions, flags, scope, unresolved_questions, validated_resources }` |
| PLAN result: `plan_ref`, `steps`, `acceptance_criteria` | `/maker:make` (`/pmcro:make`): `{ raw_seed, plan_ref, authorized_step }`, where `authorized_step` is one entry of `steps` that the user or an approval control has authorized |
| MAKE result: `plan_ref`, `make_receipt` | `/checker:check` (`/pmcro:check`): `{ raw_seed, plan_ref, make_receipt }`, run in a fresh read-only context |
| CHECK result: `verdict`, `checks` | `/reflector:reflect` (`/pmcro:reflect`): `{ raw_seed, check_verdict, evidence }`, where `check_verdict` is the Checker `verdict` and `evidence` is the Checker `checks` |

The Orchestrator owns the high-level goal and validates resources against the catalog before PLAN. If `validated_resources` is empty, PLAN returns blocked rather than planning from unvalidated resources.