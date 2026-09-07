# CLI-APB-DEFAULT-OUTPUT-NAMING: Qualify APB alias output naming

## Metadata

- Tree ID: `CLI-APB-DEFAULT-OUTPUT-NAMING`
- Status: `proposed`
- Roadmap lane: `R10 / CLI source and artifact consistency`
- Created: `2026-09-07`
- Last updated: `2026-09-07`
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
  Status: `proposed`
  Goal: `Qualify and repair inconsistent default output naming for APB source aliases.`
  Children: `CLI-APB-DEFAULT-OUTPUT-NAMING.1, CLI-APB-DEFAULT-OUTPUT-NAMING.2`

- ID: `CLI-APB-DEFAULT-OUTPUT-NAMING.1`
  Status: `done`
  Goal: `Preserve the startup source-review observation under a concrete repair owner.`
  Acceptance: `Record the exact source locus, uncertainty, reproduction obligation and follow-up owner without claiming an executed CLI failure or changing the active frontier.`
  Verification: `At source revision 50a0d7d393bda48ad1ef7339fa649bc231449577, bin/fsmgen advertises bare_name.apb and accepts APB aliases, but the slash-free default-output branch at line 1321 removes fsm/isf/ppif/axi/ahb and omits apb. The path-containing branch instead uses fileparse to strip the suffix. Knowledge Map default-output lookup returned no existing answer; focused APB test/book search found no default-output assertion. This is an inspected mismatch, not an executed product failure. Child .2 owns runtime qualification and repair. Documentation-only diff, staged doctrine and commit hooks gate this record.`
  Commit: `CLI-APB-DEFAULT-OUTPUT-NAMING.1: own alias output naming investigation`

- ID: `CLI-APB-DEFAULT-OUTPUT-NAMING.2`
  Status: `proposed`
  Goal: `Reproduce and repair the APB alias default-output mismatch.`
  Acceptance: `Activate only from a clean workspace; use a shipped lowering-clean APB fixture and isolated repository-local outputs to compare bare and explicit source paths, default names and explicit --output. Establish the intended contract from CLI/book and existing alias behavior; fix the confirmed source omission without changing other aliases or HDL semantics, add a focused recurrence check, synchronize the book, remove exact generated outputs, and commit after the required gates.`
  Verification: `Pending runtime reproduction and contract qualification.`
  Commit: `pending selection`

## Decisions

- Preserve this separate CLI finding after the T1545 diagnostic slice was
  committed and the repository verified clean. It does not activate a pivot
  from the launch-evidence task selected by MEMORY.md.

## Open Questions

- Confirm the actual bare-alias output and intended naming before publishing
  a defect or changing behavior; source inspection alone is insufficient.

## Blockers

- Proposed behind the active verification-infrastructure frontier.
