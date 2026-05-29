# BOOK-NONISF-FSM-EXAMPLE-CORRECTNESS: Non-ISF `.fsm` Book Example Correctness + Build Gate

## Metadata

- Tree ID: `BOOK-NONISF-FSM-EXAMPLE-CORRECTNESS`
- Status: `done`
- Roadmap lane: `R14` (documentation-synchronization invariant)
- Created: `2026-05-29`
- Last updated: `2026-05-29`
- Owner: repo-local workflow

## Goal

Last session's `ISF-BOOK-EXAMPLE-LOWERING-BUILD-GATE` slice added
`t/1376-isf-book-example-lowering-audit.t`, which extracts every
`lisp`-tagged ISF book block (`(actor ...)`) and verifies it parses
and lowers cleanly. That gate covers only the ISF (`13*.md` and the
ISF cookbook recipes) surface.

The non-ISF `.fsm` (IAL0) chapters (`01`-`08` and the `.fsm`
cookbook recipes `1`-`8`) carry ~103 `lisp` code blocks that are
NOT covered by any build gate. A scoping audit of every complete
`(?fsm:` / `(?dt:` / `(?top:` root among them found:

- 11 complete blocks pass `--check` (parse + generate) standalone.
- 16 complete-looking blocks fail `--check` because they are
  inherently multi-file or schematic teaching shapes:
    - 8 `?top:` composition examples reference external `?fsmc`
      child sources not present in the block
      (`needs-external-child`).
    - 3 `?top:` composition examples reference external `?rtl`
      modules needing `.rtlif` metadata (`needs-rtlif`).
    - 1 `?top:` example selects the C2 lane with a single
      generated child (`C2-needs-2-children`).
    - 4 examples consume package/aggregate material from a sibling
      `?pkg:` source or are schematic typed-actual tops (`other`).

The user mandate is explicit: book examples must be copy-paste
runnable, because the book is the user's only window into the
project and "it would be embarrassing if they fail to lower."

This tree applies the same `lisp` vs `text` block-tag convention
adopted last session for the ISF surface:

- `lisp` blocks are reserved for standalone fixtures that parse and
  generate cleanly.
- `text` blocks are for schematics, elided bodies, and inherently
  multi-file illustrations.

## Scope (the 16 blocks to convert to `text`)

| Chapter | Block | Category | Head |
| --- | --- | --- | --- |
| `05-composition-basics.md` | #1 | needs-external-child | `(?top:top_name` |
| `05-composition-basics.md` | #9 | needs-external-child | `(?top:two_child_top` |
| `05-composition-basics.md` | #11 | needs-external-child | `(?top:dtc_top` |
| `05-composition-basics.md` | #12 | needs-external-child | `(?top:single_by_name_top` |
| `05-composition-basics.md` | #13 | needs-external-child | `(?top:fsm_plus_rtl_top` |
| `06-composition-advanced.md` | #7 | needs-rtlif | `(?top:uart_slice_top` |
| `06-composition-advanced.md` | #9 | needs-external-child | `(?top:shared_status_top` |
| `06-composition-advanced.md` | #10 | other (typed actual) | `(?top:typed_actual_top` |
| `06-composition-advanced.md` | #15 | needs-rtlif | `(?top:top` |
| `06-composition-advanced.md` | #16 | C2-needs-2-children | `(?top:parameterized_generated_child_top` |
| `07-packages-and-sharing.md` | #3 | other (package) | `(?fsm:uses_shared_values` |
| `07-packages-and-sharing.md` | #4 | other (package) | `(?top:uses_shared_pkg` |
| `12-cookbook.md` | #3 | needs-external-child | `(?top:single_child_top` |
| `12-cookbook.md` | #4 | needs-external-child | `(?top:two_child_top` |
| `12-cookbook.md` | #5 | needs-rtlif | `(?top:uart_defaults_top` |
| `12-cookbook.md` | #7 | other (typed actual) | `(?top:typed_actual_top` |

### Predicate-surfaced additions (3 more, total 19)

The authoritative build-gate predicate (a `lisp` block *containing*
a generation root, not merely one whose first root is a generation
root) surfaced 3 additional same-category blocks the initial
first-root heuristic skipped. These were demoted to `text` as well:

| Chapter | Block | Category | Head |
| --- | --- | --- | --- |
| `03-decision-trees-and-fsms.md` | #1 | schematic `+fsm` shape with `(idle ...)` ellipsis | `(+fsm my_module)` |
| `03-decision-trees-and-fsms.md` | #2 | schematic `+fsm` shape with `(idle ...)` ellipsis | `(+fsm my_module` |
| `12-cookbook.md` | recipe 6 | `?pkg:` package container + consuming `?fsm:` (multi-file) | `(?pkg:shared` |

Total blocks demoted: **19** (16 listed above + 3 here). After
demotion, all 11 remaining gate-eligible `lisp` `.fsm` blocks pass
`--check-json`.

## Non-Goals

- Do not roll back or alter the 11 standalone blocks that already
  pass.
- Do not change any validator behavior, parser, scheduler, backend,
  generated `.fsm`, HDL, public API, manifests, or runtime behavior.
- Do not attempt to make composition/package examples fully
  inline-runnable in this slice. Composition fundamentally needs
  sidecar children (or ≥2 embedded children with exact wiring), and
  package sources cannot be co-located with a direct generation
  root. That upgrade is recorded as a deferred follow-up.

## Acceptance Criteria

- The 16 listed blocks are converted from `lisp` to `text`, each
  with a one-line lead-in clarifying that it is a schematic /
  multi-file shape and pointing at the relevant workflow (sidecar
  child files, `--path DIR`, the composition chapter, or the
  package import model).
- A new `t/1377-book-fsm-example-generation-audit.t` extracts every
  remaining `lisp` `(?fsm:` / `(?dt:` / `(?top:` block from the
  non-ISF chapters and asserts each passes `./bin/fsmgen
  --check-json` (success: true), mirroring the black-box idiom in
  `t/300`.
- `prove -Iperl t/1377` passes with the post-conversion standalone
  count and zero failures.
- mdBook builds clean; `git diff --check` clean.
- Live docs synchronized (MEMORY, ROADMAP_STATUS, TASK_TREE, this
  file, CHANGES, DEVELOPMENT_NOTES, LIVE_ACHIEVEMENT_STATUS, README).
- Each completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `BOOK-NONISF-FSM-EXAMPLE-CORRECTNESS`
  Status: `pending`
  Goal: `Make every lisp-tagged non-ISF book example copy-paste runnable, gate it, and honestly demote multi-file schematics to text.`
  Children:
    `BOOK-NONISF-FSM-EXAMPLE-CORRECTNESS.1`,
    `BOOK-NONISF-FSM-EXAMPLE-CORRECTNESS.2`

- ID: `BOOK-NONISF-FSM-EXAMPLE-CORRECTNESS.1`
  Status: `pending`
  Goal: `Select the slice; record scope (16 blocks), plan, and deferred follow-up.`
  Acceptance: `Task tree exists and is committed before any book or test change.`
  Verification: `mdbook build docs/book; git diff --check`
  Commit: `pending`

- ID: `BOOK-NONISF-FSM-EXAMPLE-CORRECTNESS.2`
  Status: `pending`
  Goal: `Convert the 16 blocks to text; add t/1377 build gate; verify standalone non-ISF lisp examples all pass --check.`
  Acceptance: `t/1377 passes with 0 failures; mdBook clean; live docs synced.`
  Verification: `prove -Iperl t/1377; mdbook build docs/book; git diff --check`
  Commit: `pending`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `BOOK-NONISF-FSM-EXAMPLE-CORRECTNESS.1` | `done` | Selection commit `84566349` landed before any book/test change. |
| 2 | `BOOK-NONISF-FSM-EXAMPLE-CORRECTNESS.2` | `done` | Demoted 19 blocks to `text`; added `t/1377`; all 11 standalone blocks pass. Tree closed. |

## Decisions

- `2026-05-29`: Reuse the `lisp`/`text` convention rather than
  authoring inline composition fixtures. A file containing a
  `?pkg:` root is treated as a package container that "does not
  generate HDL directly," and composition `?top:` examples need
  sidecar children, so the 16 cannot be cheaply made
  inline-runnable without authoring complete multi-file fixtures —
  which is a larger, distinct effort.

## Deferred Follow-Up

- A future PNT slice may upgrade specific composition/cookbook
  recipes to fully inline-runnable form (embedded `?fsmc` children
  with correct C1/C2 lane selection and wiring, or co-resolved
  package sidecars demonstrated via `--path`). That is out of scope
  here; this slice ensures no `lisp` block falsely implies
  copy-paste runnability and gates the standalone set.

## Open Questions

- None blocking this slice.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-29` | `BOOK-NONISF-FSM-EXAMPLE-CORRECTNESS.1` | `mdbook build docs/book`; `git diff --check` | `PASS` (doc-only selection) |
| `2026-05-29` | `BOOK-NONISF-FSM-EXAMPLE-CORRECTNESS.2` | `prove -Iperl t/1377 t/1376 t/1305 t/1307 t/1332` (`Files=5, Tests=713`); `mdbook build docs/book`; `git diff --check` | `PASS`; t/1377 reports 11 standalone `.fsm` fixtures generate cleanly, 73 non-generation-root lisp blocks skipped; t/1376 still 32 ISF fixtures lowered |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `BOOK-NONISF-FSM-EXAMPLE-CORRECTNESS.1` | `84566349 BOOK-NONISF-FSM-EXAMPLE-CORRECTNESS.1: select non-ISF .fsm example correctness + build gate` | Selection commit. |
| `BOOK-NONISF-FSM-EXAMPLE-CORRECTNESS.2` | `BOOK-NONISF-FSM-EXAMPLE-CORRECTNESS.2: ship non-ISF .fsm example correctness + build gate` | `pending commit hash` |

## Changelog

- `2026-05-29`: Created task tree extending the example-correctness
  build gate from the ISF surface to the non-ISF `.fsm` (IAL0)
  chapters. Scoping audit identified 16 multi-file/schematic blocks
  to demote to `text` and 11 standalone blocks to gate.
- `2026-05-29`: Shipped `.2`. Demoted **19** `lisp` blocks to
  `text` (the 16 listed plus 3 predicate-surfaced: `03` #1/#2
  schematic `+fsm` shapes and cookbook recipe 6's `?pkg:`+`?fsm:`
  package illustration). Added
  `t/1377-book-fsm-example-generation-audit.t`, a black-box gate
  (`./bin/fsmgen --check-json` via `IPC::Cmd::run`, mirroring
  `t/300`) that asserts every `lisp` block containing a generation
  root in chapters `01`-`08` and `12` passes generation. Post-state:
  11 standalone `.fsm` fixtures generate cleanly, 0 failures. The
  book-audit family (`t/1377`, `t/1376`, `t/1305`, `t/1307`,
  `t/1332`) passes at `Files=5, Tests=713`. Tree closed.
