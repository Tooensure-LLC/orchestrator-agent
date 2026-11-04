# API, gRPC, and Trail boundary

This product keeps the human command text, typed phase payload, gRPC reply, and Trail evidence as separate representations.

## Command text and phase payload

Before dispatch, emit a plain-text projection in this order: the invoked plugin mention, an `I AM the <role> Agent. ...` identity/intent line, then the slash skill command with its typed input. Each phase command carries its own typed `input` object from the command catalog. The slash command itself is not a Trail frame.

Every PMCR-O phase input carries the verbatim `raw_seed` and the immediately preceding phase result required by that role. The adapter serializes the typed payload into the `payload` string in the ProjectName `PhaseRequest`; it does not change the protobuf fields.

## Existing ProjectName contracts observed read-only

The current `PhaseWorker.Execute` request has `trail_id`, `actor_id`, `capability_id`, `phase`, and `payload`. Its reply has exactly `verdict`, `reason`, and `evidence_reference`. The current `DenyAllPhaseWorker` returns gRPC `PermissionDenied` with `NO_WORKER_ADMISSION`; there is no successful phase text output in the current runtime.

The current development `TrailFrame` contains `trailId`, `phase`, `evidenceReference`, `previousDigest`, `recordedAt`, and `digest`. Its digest chains the phase and evidence reference. It does not currently expose a frame-type field.

## Candidate Trail event design

The role-owned PMCR-O message frame is the event payload: `orchestrator.route`, `planner.plan`, `maker.result`, `checker.verdict`, or `reflector.reflect`. A human approval/rejection is text at the conversation boundary and may be recorded as an Orchestrator-owned `orchestrator.control.approval` or `orchestrator.control.rejection` event after the adapter resolves actor and target. `SEED` is a user-facing message label; it is not a sixth PMCR-O phase or a gRPC reply field.

For the current Trail store, persist the message frame as an evidence artifact and place its immutable evidence reference in `evidenceReference`. Do not claim the current TrailFrame has `frameType`. Any future TrailFrame type extension requires a separately versioned schema and implementation.

The proposed `I AM` display text is a projection of the typed role message. It carries participant, domain, parent run, phase, evidence reference, authority state, outcome, and simulation/verification status. It is not the protobuf `PhaseReply` and does not mutate Trail authority.
