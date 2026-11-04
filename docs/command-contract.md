# Command contract

## Seed and run

1. Call `/orchestrator:orchestrate` with `{ raw_seed, full_context }`. It is the plugin's only command.
2. Call the catalogued `/pmcro:orchestrate` with `{ raw_seed, context }`. It derives true intent and does not rewrite the raw seed.
3. Invoke each phase command with its own required typed payload. Every payload carries the unchanged `raw_seed` and the required prior phase result:
   - `/pmcro:orchestrate` — `{ raw_seed, context }`
   - `/pmcro:plan` — `{ raw_seed, true_intent, assumptions, flags, scope, unresolved_questions, validated_resources }`
   - `/pmcro:make` — `{ raw_seed, plan_ref, authorized_step }`
   - `/pmcro:check` — `{ raw_seed, plan_ref, make_receipt }`
   - `/pmcro:reflect` — `{ raw_seed, check_verdict, evidence }`
4. Stop on a missing capability, failed authorization, unavailable independent Checker, invalid output, or non-PASS Checker verdict. Report the precise state and reason.

## Optional PMCR-O aliases

When the host confirms these skills are available, aliases can be invoked as:

- `/pmcro:orchestrate` → `/orchestrator:orchestrate`
- `/pmcro:plan` → `/planner:plan`
- `/pmcro:make` → `/maker:make`
- `/pmcro:check` → `/checker:check`
- `/pmcro:reflect` → `/reflector:reflect`

The command catalog stores an input mode and schema for every command. Phase skill commands require their typed `input` object. Approve/reject controls are not part of this plugin (see `docs/deferred/approval-controls.md`).

If a short alias is not recognized by the host, use its canonical namespaced command. Do not describe a command as invoked until the host returns a result for it.

## Missing capability

If the catalog has no suitable capability, stop and ask the Skill Creator to produce a candidate using a typed contract and progressive disclosure. The candidate must be checked and added to the catalog before a later run can select it. Candidate creation does not invoke it in the current run.
