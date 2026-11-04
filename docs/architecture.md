# Architecture

`providers/pmcro-agent-marketplace.json` points to the sibling PMCR-O catalog. In that catalog, Orchestrator remains available as the PMCR-O orchestrator skill projection. PLAN, MAKE, CHECK, and REFLECT resolve to their standalone role repositories (`G:\planner-agent`, `G:\maker-agent`, `G:\checker-agent`, `G:\reflector-agent`) using each catalog entry's `sourceRepositoryPath` and `source*` paths. Packaged marketplace copies are explicitly marked as projections.

`scripts/Resolve-Agent.ps1` returns source repository and schema paths only when the host reports the agent ID available and the referenced files exist. A resolved route is not an invocation, registration, grant, activation, or execution. The Checker is required to use a fresh, separate read-only context.
