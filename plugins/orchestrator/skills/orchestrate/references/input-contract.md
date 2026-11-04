# Input and output contract

The skill command takes exactly one typed object conforming to `input.schema.json`: the verbatim `raw_seed` plus the complete relevant `full_context`. This is the only skill; the raw seed goes straight to `/orchestrator:orchestrate`.

The result follows `output.schema.json`, the PMCR-O output envelope: identity, phase/execution state, typed input and output, accept/deny conditions, evidence references, and an explicit next handoff. Human-readable text is only a projection of this envelope.

The PMCR-O Orchestrator receives `{ raw_seed, context }`; later role calls each receive `raw_seed` unchanged plus their role-specific prior output. See the repo-level `docs/api-grpc-and-trail-contract.md` before changing API or Trail mappings.

## Plugin mention

The first emitted line of the message is the plugin mention. Its plain form is `@orchestrator`; its exact link form for hosts that render mentions is `[@orchestrator](plugin://orchestrator@orchestrator-agent)`.
