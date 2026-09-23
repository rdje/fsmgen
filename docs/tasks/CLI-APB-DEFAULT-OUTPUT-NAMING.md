# CLI-APB-DEFAULT-OUTPUT-NAMING: Qualify APB alias output naming

## Metadata

- Tree ID: `CLI-APB-DEFAULT-OUTPUT-NAMING`
- Status: `done`
- Roadmap lane: `R10 / CLI source and artifact consistency`
- Created: `2026-09-07`
- Last updated: `2026-09-23`
- Owner: repo-local workflow

## Goal

Qualify and repair the apparent difference between default HDL output names
for bare APB aliases and explicit APB source paths.

## Non-Goals

- Change protocol semantics, output locality, explicit output selection, or
  the active T1545 launch-investigation frontier.

## Acceptance Criteria

- A repository-local CLI reproduction establishes the filename contract and
  observes the actual bare-name and explicit-path outputs.
- Any confirmed mismatch has a focused repair, a failing-before/passing-after
  regression, synchronized book guidance, and a separate verified commit.

## Task Tree

- ID: `CLI-APB-DEFAULT-OUTPUT-NAMING`
  Status: `done`
  Goal: `Qualify and repair inconsistent default output naming for APB source aliases.`
  Children: `CLI-APB-DEFAULT-OUTPUT-NAMING.1, CLI-APB-DEFAULT-OUTPUT-NAMING.2`

- ID: `CLI-APB-DEFAULT-OUTPUT-NAMING.1`
  Status: `done`
  Goal: `Preserve the startup source-review observation under a concrete repair owner.`
  Acceptance: `Record the exact source locus, uncertainty, reproduction obligation and follow-up owner without claiming an executed CLI failure or changing the active frontier.`
  Verification: `At source revision 50a0d7d393bda48ad1ef7339fa649bc231449577, bin/fsmgen advertises bare_name.apb and accepts APB aliases, but the slash-free default-output branch at line 1321 removes fsm/isf/ppif/axi/ahb and omits apb. The path-containing branch instead uses fileparse to strip the suffix. Knowledge Map default-output lookup returned no existing answer; focused APB test/book search found no default-output assertion. This is an inspected mismatch, not an executed product failure. Child .2 owns runtime qualification and repair. Documentation-only diff, staged doctrine and commit hooks gate this record.`
  Commit: `CLI-APB-DEFAULT-OUTPUT-NAMING.1: own alias output naming investigation`

- ID: `CLI-APB-DEFAULT-OUTPUT-NAMING.2`
  Status: `done`
  Goal: `Reproduce and repair the APB alias default-output mismatch.`
  Acceptance: `Activate only from a clean workspace; use a shipped lowering-clean APB fixture and isolated repository-local outputs to compare bare and explicit source paths, default names and explicit --output. Establish the intended contract from CLI/book and existing alias behavior; fix the confirmed source omission without changing other aliases or HDL semantics, add a focused recurrence check, synchronize the book, remove exact generated outputs, and commit after the required gates.`
  Verification: `The original real CLI fails the bare .apb and uppercase .APB filename controls while explicit absolute/relative paths, generic .ppif and explicit --output pass. Adding apb to the existing suffix rule makes all six cases pass; each emits the same APB module and exact generated outputs are removed. Guarded prove of t/1463 and t/1347 reports All tests successful, Files=2, Tests=10. Perl syntax checks pass. The book and Knowledge Map document the exact filename contract. HIAL launch and hosted/full-CI/push prerequisites are unchanged.`
  Commit: `this commit`

## Decisions

- Preserve this separate CLI finding after the T1545 diagnostic slice was
  committed and the repository verified clean. It does not activate a pivot
  from the launch-evidence task selected by MEMORY.md.

- Selected under the director's unlimited PNT instruction after the clean
  `0af0842ab` Yosys repair. The HIAL launch restriction requires a director
  sequencing answer; this independent R10 defect uses ordinary CLI generation
  without a compiler/proxy/probe capture or submodule access.

## Open Questions

- Resolved by the .2 real CLI reproduction and focused regression.

## Blockers

- None for this completed CLI repair. HIAL sequencing and its full-CI/push
  prerequisites remain tracked in their owning trees.

## Acceptance Checklist (CLI-APB-DEFAULT-OUTPUT-NAMING.2)

- [x] **ROOT CAUSE (WHY + WHERE)** — `git log -S 'fsm|isf|ppif|axi|ahb' -- bin/fsmgen` identifies `49a190e1f`. The slash-free default-output branch omits APB from its source-suffix removal list, while source resolution already accepts it and the path-containing branch removes its suffix. Guarded t/1463 reproduces incorrect extra `.apb`/`.APB` suffixes only for the bare alias forms; the path and explicit-output controls succeed.
- [x] **ADDRESSED (verified)** — `bin/fsmgen` includes APB in the existing case-insensitive suffix rule. Guarded `prove -v -Iperl t/1463-cli-generated-hdl-artifact-placement.t t/1347-cli-quiet-banner-boundary.t` passes at Files=2, Tests=10. The new subtest executes six real CLI routes, asserts exact intended/unintended filenames and APB module identity, and cleans the uniquely owned generated files after each route. The book contains runnable bare/path examples yielding the same documented destination.
- [x] **NO REGRESSION** — All tests successful for the focused placement and quiet-boundary suite. Existing SystemVerilog/VHDL placement, explicit destination selection, escape rejection, implicit multi-file handoff cleanup and quiet diagnostics remain green. Both changed Perl files report syntax OK. Re-derive: actual CLI generation and output filenames; falsify: failing original bare/uppercase controls plus independent explicit-path/output and generic-source controls; durability: committed recurrence tests, source fix, book and canonical fact card. This does not claim broader protocol or hosted-CI qualification.
