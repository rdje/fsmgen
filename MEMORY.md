# MEMORY — resume pointer (layer A; overwrite-only, keep ≤ ~60 lines)

See `MEMORY_ARCHITECTURE.md` for the four-layer system. Git preserves prior
history; this file carries only the current bounded resume state.

## Resume

- repository_revision: derive the current commit and subject with
  `git log -1 --format='%H %s'`; do not store a shadow of `HEAD` here.
- active_work_unit: `GITHUB-PUSH-OUTCOME-ASSURANCE.6.2.1.1`; downstream source-path provenance decision.
- current_state: all 19 pre-audit commits are classified; exact upstream/current
  probes show no CI-repair drift in public CLI/schema meaning;
  19 stale downstream handoff commands now use repository-local `.artifacts`
  destinations. The branch is 20 commits ahead after this commit and remains
  below the 200-commit automatic push cadence.
- next_action: director selects a compatible repository-relative migration or
  a narrow explicit exemption for public JSON `source.resolved_path`; implement
  that choice in code/contracts/book/tests before `.6.2.2` may push-qualify.
- in_flight_uncommitted: none after this commit.
- blockers: `.6.2.1.1` requires the director's compatibility/policy judgment; no push is authorized meanwhile.
- push_state: decision `0062`; derive with `git rev-list --count @{upstream}..HEAD`.

## Durable context
- Decision `0034`: full power underneath, simpler intent above; VIAL is not
  synthesis-bounded and target methodology stays compiler-private.
- Decisions `0036`/`0037`: logical drive/sample/react/check time and closed
  directional type-representation proofs remain backend authority.
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
