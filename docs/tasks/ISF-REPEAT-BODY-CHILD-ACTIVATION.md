# ISF-REPEAT-BODY-CHILD-ACTIVATION: Repeat-Body Child Activation Widening

## Metadata

- Tree ID: `ISF-REPEAT-BODY-CHILD-ACTIVATION`
- Status: `active`
- Roadmap lane: `R14`
- Created: `2026-05-17`
- Last updated: `2026-05-17`
- Owner: repo-local workflow

## Goal

Track and ship the remaining repeat-body child activation surfaces after the
closed plain-spawn and static-parameter repeat-spawn subsets.

## Non-Goals

- Reopening already-shipped plain repeat-body spawn behavior.
- Reopening already-shipped repeat-body spawn static `(params ...)` behavior.
- Changing top-level spawn, top-level `do`, top-level `await_all`, or
  top-level `await_any` behavior outside repeat bodies unless a leaf explicitly
  selects that dependency.
- Bundling multiple repeat-body activation semantics into one implementation
  leaf without a bounded contract and focused validation.

## Acceptance Criteria

- Each future repeat-body child activation widening is selected as a bounded
  leaf before implementation.
- The source contract, generated-top wiring, re-entry semantics,
  fail-closed diagnostics, schedule/report visibility, and mdBook behavior are
  documented before or with implementation.
- Unsupported repeat-body child activation forms remain fail-closed until
  their own leaf ships.
- The ISF spec, downstream handoff, public contract, mdBook, roadmap, live
  docs, and focused tests stay synchronized for any shipped behavior.
- Each completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `ISF-REPEAT-BODY-CHILD-ACTIVATION`
  Status: `active`
  Goal: `Ship remaining repeat-body child activation subsets safely.`
  Children: `ISF-REPEAT-BODY-CHILD-ACTIVATION.1`, `ISF-REPEAT-BODY-CHILD-ACTIVATION.2`, `ISF-REPEAT-BODY-CHILD-ACTIVATION.3`, `ISF-REPEAT-BODY-CHILD-ACTIVATION.4`, `ISF-REPEAT-BODY-CHILD-ACTIVATION.5`, `ISF-REPEAT-BODY-CHILD-ACTIVATION.6`

- ID: `ISF-REPEAT-BODY-CHILD-ACTIVATION.1`
  Status: `done`
  Goal: `Select the next repeat-body child activation subset.`
  Acceptance: `Task tree, roadmap, and book backlog identify the selected leaf, source shape, exclusions, and validation plan.`
  Verification: `mdbook build docs/book; git diff --check`
  Commit: `ISF-REPEAT-BODY-CHILD-ACTIVATION.1: select repeat spawn bindings`

- ID: `ISF-REPEAT-BODY-CHILD-ACTIVATION.2`
  Status: `pending`
  Goal: `Ship repeat-body spawn port bindings if selected.`
  Acceptance: `Top-level repeat bodies accept '(spawn child as inst [(params ...)] (bind ...))' only when the same repeat body reaches '(await_all done)' before the repeat check can loop; input and output bindings reuse the shipped static generated-child handoff model, generated-top wiring, diagnostics, docs, and tests while domain overrides, await_any, repeat-body do, nested activation, and sample-after-spawn remain deferred.`
  Verification: `pending`
  Commit: `pending`

- ID: `ISF-REPEAT-BODY-CHILD-ACTIVATION.3`
  Status: `pending`
  Goal: `Ship repeat-body spawn domain overrides if selected.`
  Acceptance: `Repeat-body spawn '(domain ...)' lowering, clock-domain ownership, diagnostics, docs, and tests prove the selected domain subset.`
  Verification: `pending`
  Commit: `pending`

- ID: `ISF-REPEAT-BODY-CHILD-ACTIVATION.4`
  Status: `pending`
  Goal: `Ship repeat-body await_any semantics if selected.`
  Acceptance: `Outstanding-child lifetime semantics, re-entry behavior, diagnostics, docs, and tests prove the selected await_any subset.`
  Verification: `pending`
  Commit: `pending`

- ID: `ISF-REPEAT-BODY-CHILD-ACTIVATION.5`
  Status: `pending`
  Goal: `Ship repeat-body blocking do activation if selected.`
  Acceptance: `Repeat-body do instance naming, generated-top wiring, re-entry behavior, diagnostics, docs, and tests prove the selected do subset.`
  Verification: `pending`
  Commit: `pending`

- ID: `ISF-REPEAT-BODY-CHILD-ACTIVATION.6`
  Status: `pending`
  Goal: `Ship nested repeat-body child activation or sample-after-spawn forms if selected.`
  Acceptance: `Nested branch/loop placement or sample-after-spawn ordering has explicit timing, diagnostics, docs, and tests.`
  Verification: `pending`
  Commit: `pending`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `ISF-REPEAT-BODY-CHILD-ACTIVATION.1` | `done` | Selected repeat-body spawn port bindings as the next bounded implementation subset. |
| 2 | `ISF-REPEAT-BODY-CHILD-ACTIVATION.2` | `pending` | Reuses the static generated-child spawn handoff model on the shipped top-level repeat plus same-body `await_all` path. |
| 3 | `ISF-REPEAT-BODY-CHILD-ACTIVATION.3` | `pending` | Tracks repeat-body spawn clock-domain ownership. |
| 4 | `ISF-REPEAT-BODY-CHILD-ACTIVATION.4` | `pending` | Tracks repeat-body await_any outstanding-child semantics. |
| 5 | `ISF-REPEAT-BODY-CHILD-ACTIVATION.5` | `pending` | Tracks repeat-body blocking do activation. |
| 6 | `ISF-REPEAT-BODY-CHILD-ACTIVATION.6` | `pending` | Tracks nested repeat-body child activation and sample-after-spawn timing. |

## Decisions

- `2026-05-17`: This proposed tree owns the remaining repeat-body child
  activation backlog that is not covered by the closed
  `ISF-SPAWN-IN-REPEAT` and `ISF-REPEAT-SPAWN-PARAMS` trees.
- `2026-05-17`: No remaining repeat-body activation surface is PNT-ready for
  implementation until leaf `.1` selects the exact next subset.
- `2026-05-17`: The repository workflow now makes task-tree ownership a
  precondition before any future code, test, source, generated-artifact, or
  config change.
- `2026-05-17`: Leaf `.1` selects repeat-body spawn port bindings as the next
  implementation subset. The selected source shape is top-level
  `(repeat count (spawn child as inst [(params ...)] (bind ...)) ... (await_all done))`.
  The binding model remains static: the lexical spawn name denotes one
  generated child instance, binding payload ports are generated once in the
  composition top, and repeat iterations reuse that instance.
- `2026-05-17`: Repeat-body spawn `(domain ...)`, `await_any`, repeat-body
  `do`, nested branch/loop activation, and sample-after-spawn timing remain
  deferred after the binding selection.

## Open Questions

- Which deferred repeat-body activation subset should ship after spawn
  bindings: spawn `(domain ...)`, `await_any`, blocking `do`, nested
  branch/loop activation, or sample-after-spawn timing.

## Blockers

- None for tracking. Implementation leaves must resolve their own timing,
  generated-top, domain, and report contracts before shipping.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-17` | `ISF-REPEAT-BODY-CHILD-ACTIVATION` | `mdbook build docs/book`; `git diff --check` | `book and diff checks passed after task-tree gate policy sync` |
| `2026-05-17` | `ISF-REPEAT-BODY-CHILD-ACTIVATION.1` | `mdbook build docs/book`; `git diff --check` | `book and diff checks passed` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `ISF-REPEAT-BODY-CHILD-ACTIVATION` | `ISF-REPEAT-BODY-CHILD-ACTIVATION: track repeat activation backlog` | `e942bfc6; proposed tracking tree created` |
| `ISF-REPEAT-BODY-CHILD-ACTIVATION.1` | `ISF-REPEAT-BODY-CHILD-ACTIVATION.1: select repeat spawn bindings` | `pending commit hash; leaf completed and ready for COMMIT.md workflow` |

## Changelog

- `2026-05-17`: Created proposed task tree so the remaining repeat-body child
  activation backlog has explicit task-tree ownership before future code work.
- `2026-05-17`: Strengthened the surrounding workflow docs so the task-tree
  preflight is mandatory for all future implementation work, not only this ISF
  backlog.
- `2026-05-17`: Activated the tree and selected repeat-body spawn
  `(bind ...)` as the next bounded implementation leaf.
