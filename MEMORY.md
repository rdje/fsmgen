# MEMORY — resume pointer (layer A; overwrite-only, keep ≤ ~60 lines)

See `MEMORY_ARCHITECTURE.md` for the four-layer system. Git preserves prior history; this file carries only the current bounded resume state.

## Resume

- repository_revision: derive the current commit and subject with
  `git log -1 --format='%H %s'`; do not store a shadow of `HEAD` here.
- active_work_unit: none selected; `GITHUB-PUSH-OUTCOME-ASSURANCE.6.2.2.23` closes the hosted-CI repair tree.
- current_state: repaired pushed SHA `c0d8b668db2527108d1c23c20d184400c51efea6`
  has exact local/upstream/remote equality. Knowledge Map run `31571508694`
  succeeds 1/1; Publish mdBook run `31571508795` succeeds 2/2; regression run
  `31571508709` succeeds 138/138 with exact family counts 1 doctrine, 1 book,
  16 ordinary, 3 dedicated, 48 corpus, 68 dynamic, and 1 aggregate. Repaired
  mdBook job `94034312605` and t303 jobs `94034313312`/`94034313372` all pass.
- next_action: select the next eligible roadmap/task-tree PNT leaf; after every future push, apply COMMIT.md exact-SHA terminal qualification before declaring success.
- in_flight_uncommitted: none; `.23` terminal evidence and closure are included in the current revision.
- in_flight_background: none; the exact hosted run is terminal.
- blockers: none.
- push_state: remote `c0d8b668d`; all three expected exact-SHA workflows and all required jobs are terminal success. The local closure commit follows normal cadence and must not be pushed early without authorization.

## Durable context
- Decision `0034`: full power underneath, simpler intent above; VIAL is not synthesis-bounded and target methodology stays compiler-private.
- Decisions `0036`/`0037`: logical drive/sample/react/check time and closed directional type-representation proofs remain backend authority.
- Decision `0039`: `.10.1`/`.10.2` ship source tooling and atomic planning;
  transaction-free direct IAL0 never infers transaction facts.
- Decision `0043`: Verilator is the first fast known-value runtime profile,
  never the language ceiling or four-state/UVM authority. `.10.3` keeps one
  generated scheduler as semantic authority; `.10.4` now qualifies compile,
  runtime, and normalized results; `.11` now qualifies only the selected AHB
  handwritten-oracle comparison, not general cross-backend parity.
- Decision `0050`: canonical native output is simulator-neutral Accellera UVM;
  provider-specific requirements stay in isolated adapter/command/evidence
  layers and cannot alter VIAL meaning; commercial simulators remain optional.
- Decision `0051`: portable VHDL is provider-free IEEE 1076-2008; OSVVM is the
  selected advanced provider and GHDL 6.0.0 is the first exact tool profile.
  Provider/tool behavior cannot redefine logical time, values, or results.
- `.15.1-.15.4` ship portable emission/review; `.15.5` qualifies exact GHDL
  6.0.0 LLVM-JIT; `.15.6` ships exact OSVVM materialization/emission; `.15.7`
  qualifies their bounded combined profile with portable semantics unchanged.
- Decisions `0058`/`0059`: action-local SemanticIR IDs follow scenario/parallel
  scope; the current expanded-action cap dominates higher repeat candidates,
  and `.17.4` alone owns any limit-policy repair.
- Decisions `0041`/`0042`/`0044`/`0045` retain containment authority; retired views are Git-retrievable. Decision `0062` sets the 200-commit normal push cadence; PNT is autonomous.
