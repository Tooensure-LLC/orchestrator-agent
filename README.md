# Orchestrator Agent

A provider-neutral agent whose single capability is **ORCHESTRATE**. It accepts a messy user seed together with the full available message context, resolves the PMCR-O marketplace catalog, calls the catalogued Orchestrate agent to derive true intent, then routes bounded handoffs through the independent phase agents in order:

`ORCHESTRATE → PLAN → MAKE → CHECK → REFLECT`

The repository was initialized locally at `G:\orchestrator-agent`. Its one MAF-native skill was created as an **unregistered candidate** with Skill Creator. It is not installed or activated in an agent host.

## Command

- `/orchestrator:seed` accepts the raw seed directly.
- The plugin ships exactly one skill (`seed`) and one command (`/orchestrator:seed`).
- The PMCR-O provider catalog maps `/pmcro:orchestrate`, `/pmcro:plan`, `/pmcro:make`, `/pmcro:check`, and `/pmcro:reflect` to separate marketplace agents and their skills.

The host supplies actual agent invocation. `scripts/Resolve-Agent.ps1` selects a catalog entry only when the host reports that agent as available. It returns a route; it does not invoke an agent, action, model, or MCP tool.

## Input behavior

Preserve the user's raw seed exactly. Pass the full message context to the catalogued PMCR-O Orchestrate agent and accept its true-intent result with assumptions and unresolved questions. Do not invent a richer goal from a short seed. See [the example envelope](docs/examples/seed-envelope.json).

## Layout

- `.agents/` contains this agent's one capability and command projection.
- `providers/pmcro-agent-marketplace.json` points to the separate PMCR-O agent repository/catalog.
- `schemas/` defines the typed seed and handoff envelopes.
- `scripts/` resolves catalog entries and validates envelope structure.
- `plugins/orchestrator/skills/seed/` contains the MAF-native skill candidate.

See [architecture](docs/architecture.md) and [handoff contract](docs/handoff-contract.md).
