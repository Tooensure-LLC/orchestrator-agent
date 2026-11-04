> Deferred: not part of the orchestrator plugin, which ships only the seed skill and command.

# Approval and rejection controls

`/orchestrator:approve` and `/orchestrator:reject` are plain-text controls handled by the single ORCHESTRATE capability. They are not extra agent capabilities. The command text stays text at the conversation boundary; an adapter may resolve the target and create a typed control record downstream.

- **Approve** targets a specific pending message resolved from the thread or explicit plain text. It accepts that message and releases the next handoff only when the message passes its schema and role contract. It does not enlarge the user's existing scope or grant new authority.
- **Reject** targets a pending message resolved from the thread or explicit plain text, blocks the next phase, and requests a corrected structured message. The user may reject an assistant message; the Orchestrator may reject a delegated agent response that is malformed, out of role, or unsupported by evidence.
- An agent's contract validation is not a Checker verdict. Only the independent Checker may return PASS, LOOP, or HALT for work quality.

Do not require JSON arguments after either slash command. If the target cannot be resolved from thread context or its plain-text target, return `BLOCKED` without changing state. The downstream control adapter validates a typed record before it can affect a handoff. An approval/rejection control record is not itself a gRPC phase reply.
