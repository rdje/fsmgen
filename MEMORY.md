# MEMORY — resume pointer (layer A; overwrite-only, keep ≤ ~60 lines)

See `MEMORY_ARCHITECTURE.md` for the four-layer system. Git preserves prior history; this file carries only the current bounded resume state.

## Resume

- repository_revision: derive the current commit and subject with
  `git log -1 --format='%H %s'`; do not store a shadow of `HEAD` here.
- active_work_unit: `GITHUB-PUSH-OUTCOME-ASSURANCE.6.2.2`; `.22` closes the exact pushed-SHA inventory after completed repairs `.19`–`.21`.
- current_state: pushed SHA `a51dcdad0a7e752e638abfe3ab414f7f3911889d`
  is fully terminal. Knowledge Map run `31529600931` succeeds. Publish mdBook
  run `31529600916` fails only on the `.19` broken-action mechanism and skips
  dependent deploy. Regression run `31529600915` closes at 138 jobs: 134
  success; three independent repaired failures; and their dependent aggregate
  failure. Repairs `.19`/`8dcab8c99`, `.20`/`e746fc4ba`, and `.21`/`2dcd29942`
  are locally qualified; dedicated job `93906174333` succeeds.
- next_action: obtain fresh authorization, push the repaired current HEAD, prove exact remote equality, and consume every new exact-SHA workflow/job to terminal success.
- in_flight_uncommitted: none; `.22` is locally qualified and included in the current revision.
- in_flight_background: none.
- blockers: none for local repair; a repair push will require authorization under `COMMIT.md`.
- push_state: remote `a51dcdad0`; all workflows terminal, every failure locally repaired, fresh authorization required before the repair push.

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
