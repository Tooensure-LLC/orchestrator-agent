# Repository instructions

- The `orchestrator` plugin (repo `orchestrator-agent`) has exactly one capability: ORCHESTRATE, exposed as one skill (`orchestrate`) and one command (`/orchestrator:orchestrate`).
- `/orchestrator:orchestrate` is the only entry point and accepts the user's raw seed directly. Do not add other skills or commands to this plugin.
- Resolve true intent by invoking the selected Orchestrate agent from the configured PMCR-O marketplace catalog with the full available user-message context.
- Resolve role agents through the catalog; pass one bounded handoff at a time in ORCHESTRATE, PLAN, MAKE, CHECK, REFLECT order.
- A catalog listing is not invocation, execution, authority, registration, grant, or activation.
- Keep role capabilities in their separate agents/repository. The Orchestrator Agent does not directly plan, make, check, or reflect.
- Require Checker context to be separate from Maker context. If the host cannot establish that boundary, report it precisely and do not self-certify.
- Stop on unavailable agents, missing contracts, failed authorization, malformed handoffs, or non-PASS Checker verdicts.
- Scripts may validate typed structure and resolve catalog IDs. Models and agents interpret intent and perform their declared role.