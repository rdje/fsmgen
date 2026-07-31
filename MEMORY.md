# MEMORY — resume pointer (layer A; overwrite-only, keep ≤ ~60 lines)

See `MEMORY_ARCHITECTURE.md` for the four-layer system. Git preserves prior
history; this file carries only the current bounded resume state.

## Resume

- latest_commit: this commit
  (`LIVE-DOCUMENT-SIZE-CONTAINMENT-ADOPTION.14: publish external review packet`).
- active_work_unit: `LIVE-DOCUMENT-SIZE-CONTAINMENT-ADOPTION`; `.14` is complete
  and no implementation leaf is active across this commit boundary.
- current_state: the tracked external packet explains the full doctrine,
  JSONL/task implementation, measured migration, limitations, 31 questions,
  and response template. Utility now precedes size in the review model, with
  measured retain/merge/supersede/archive/delete examples. `.15` owns common
  registry self-bounds/hard semantics; `.16` owns the utility/retirement audit.
- next_action: circulate the packet and route returned reviews; before further
  containment implementation, cleanly activate `.15`, `.16`, or the independent
  `.8` family migration according to the reviewed priority.
- in_flight_uncommitted: none after this commit; no background job and all
  repository-local mdBook output is removed exactly.
- blockers: none for `.15`, `.16`, `.8`-.10, or `.13`; `.3`-.5/.11 wait for the
  separately owned four-file review, and final `.12` waits for all migrations.

## Durable context

- Decision `0038` owns README policy authority, template independence,
  duplicate proof, derived 275-line/12,288-byte caps, and unconditional guard.
- Decision `0040` adds routed-destination ownership/lifecycle controls and
  pins frozen legacy records; current large ceilings are debt, not defaults.
- Decision `0041` generalizes containment project-wide while keeping its body
  project-neutral, project-agnostic, and harness-neutral. Local 80/90/100
  milestones, JSONL data, immutable baselines, transition allowances, and
  migration paths remain fenced local state.
- Decisions `0025` freezes legacy status files. Push only on explicit request
  (`0005`); PNT runs autonomously (`0003`). Consult the Knowledge Map first.
