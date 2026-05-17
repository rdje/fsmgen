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
  Children: `ISF-REPEAT-BODY-CHILD-ACTIVATION.1`, `ISF-REPEAT-BODY-CHILD-ACTIVATION.2`, `ISF-REPEAT-BODY-CHILD-ACTIVATION.3`, `ISF-REPEAT-BODY-CHILD-ACTIVATION.4`, `ISF-REPEAT-BODY-CHILD-ACTIVATION.5`, `ISF-REPEAT-BODY-CHILD-ACTIVATION.6`, `ISF-REPEAT-BODY-CHILD-ACTIVATION.7`, `ISF-REPEAT-BODY-CHILD-ACTIVATION.8`, `ISF-REPEAT-BODY-CHILD-ACTIVATION.9`, `ISF-REPEAT-BODY-CHILD-ACTIVATION.10`, `ISF-REPEAT-BODY-CHILD-ACTIVATION.11`, `ISF-REPEAT-BODY-CHILD-ACTIVATION.12`, `ISF-REPEAT-BODY-CHILD-ACTIVATION.13`, `ISF-REPEAT-BODY-CHILD-ACTIVATION.14`, `ISF-REPEAT-BODY-CHILD-ACTIVATION.15`, `ISF-REPEAT-BODY-CHILD-ACTIVATION.16`, `ISF-REPEAT-BODY-CHILD-ACTIVATION.17`, `ISF-REPEAT-BODY-CHILD-ACTIVATION.18`, `ISF-REPEAT-BODY-CHILD-ACTIVATION.19`, `ISF-REPEAT-BODY-CHILD-ACTIVATION.20`, `ISF-REPEAT-BODY-CHILD-ACTIVATION.21`, `ISF-REPEAT-BODY-CHILD-ACTIVATION.22`, `ISF-REPEAT-BODY-CHILD-ACTIVATION.23`, `ISF-REPEAT-BODY-CHILD-ACTIVATION.24`, `ISF-REPEAT-BODY-CHILD-ACTIVATION.25`, `ISF-REPEAT-BODY-CHILD-ACTIVATION.26`, `ISF-REPEAT-BODY-CHILD-ACTIVATION.27`, `ISF-REPEAT-BODY-CHILD-ACTIVATION.28`, `ISF-REPEAT-BODY-CHILD-ACTIVATION.29`, `ISF-REPEAT-BODY-CHILD-ACTIVATION.30`, `ISF-REPEAT-BODY-CHILD-ACTIVATION.31`

- ID: `ISF-REPEAT-BODY-CHILD-ACTIVATION.1`
  Status: `done`
  Goal: `Select the next repeat-body child activation subset.`
  Acceptance: `Task tree, roadmap, and book backlog identify the selected leaf, source shape, exclusions, and validation plan.`
  Verification: `mdbook build docs/book; git diff --check`
  Commit: `ISF-REPEAT-BODY-CHILD-ACTIVATION.1: select repeat spawn bindings`

- ID: `ISF-REPEAT-BODY-CHILD-ACTIVATION.2`
  Status: `done`
  Goal: `Ship repeat-body spawn port bindings if selected.`
  Acceptance: `Top-level repeat bodies accept '(spawn child as inst [(params ...)] (bind ...))' only when the same repeat body reaches '(await_all done)' before the repeat check can loop; input and output bindings reuse the shipped static generated-child handoff model, generated-top wiring, diagnostics, docs, and tests while domain overrides, await_any, repeat-body do, nested activation, and sample-after-spawn remain deferred.`
  Verification: `syntax checks; focused repeat/spawn/port-binding/doc tests; mdbook build docs/book; ./bin/ci-regression isf --no-book; git diff --check`
  Commit: `ISF-REPEAT-BODY-CHILD-ACTIVATION.2: implement repeat spawn bindings`

- ID: `ISF-REPEAT-BODY-CHILD-ACTIVATION.3`
  Status: `done`
  Goal: `Ship repeat-body spawn domain overrides if selected.`
  Acceptance: `Repeat-body spawn '(domain NAME)' is accepted only as declared same-domain ownership metadata on the existing top-level repeat plus same-body await_all static-instance subset; omitted domain annotations inherit the owning transaction domain, cross-domain activation and undeclared domains fail closed, and docs/tests/report metadata prove that no CDC behavior is implied.`
  Verification: `syntax checks; focused repeat/spawn/domain/doc tests; mdbook build docs/book; ./bin/ci-regression isf --no-book; git diff --check`
  Commit: `ISF-REPEAT-BODY-CHILD-ACTIVATION.3: implement repeat spawn domains`

- ID: `ISF-REPEAT-BODY-CHILD-ACTIVATION.4`
  Status: `done`
  Goal: `Ship repeat-body await_any semantics if selected.`
  Acceptance: `Repeat-body '(await_any done)' is accepted only when exactly one repeat-body spawn is pending, making its re-entry semantics equivalent to waiting for that one static child instance before the repeat check can loop; zero-pending and multi-pending await_any fail closed, and broader outstanding-child lifetime semantics remain deferred.`
  Verification: `syntax checks; focused repeat/spawn/await-any/doc tests; mdbook build docs/book; ./bin/ci-regression isf --no-book; git diff --check`
  Commit: `ISF-REPEAT-BODY-CHILD-ACTIVATION.4: implement repeat await_any`

- ID: `ISF-REPEAT-BODY-CHILD-ACTIVATION.5`
  Status: `done`
  Goal: `Ship repeat-body blocking do activation if selected.`
  Acceptance: `Top-level repeat bodies accept local '(do child)' only when the child transaction remains local to the scheduled parent; the do state waits for the child's fresh done pulse before the repeat check can loop, local start/done wiring is installed for repeat-body do targets, and generated/parameterized/bound/domain-qualified repeat-body do, nested repeat-body do, cross-domain activation, and sample-before/after-do timing remain fail-closed with docs/tests.`
  Verification: `syntax checks; focused repeat/do/doc tests; mdbook build docs/book; ./bin/ci-regression isf --no-book; git diff --check`
  Commit: `ISF-REPEAT-BODY-CHILD-ACTIVATION.5: implement repeat local do`

- ID: `ISF-REPEAT-BODY-CHILD-ACTIVATION.6`
  Status: `done`
  Goal: `Ship repeat-body sample-after-spawn timing if selected.`
  Acceptance: `Top-level repeat bodies accept samples after repeat-body spawn only when the same body still reaches await_all or single-pending await_any before the repeat check can loop; pending samples materialize in an explicit sample state before the sync state, spawn-after-sample and sample-before/after-do remain fail-closed, and docs/tests show the exact timing.`
  Verification: `syntax checks; focused repeat/spawn/sample/doc tests; mdbook build docs/book; ./bin/ci-regression isf --no-book; git diff --check`
  Commit: `ISF-REPEAT-BODY-CHILD-ACTIVATION.6: implement repeat spawn samples`

- ID: `ISF-REPEAT-BODY-CHILD-ACTIVATION.7`
  Status: `done`
  Goal: `Select the next repeat-body generated blocking-do subset.`
  Acceptance: `Task tree, roadmap, and book backlog select repeat-body generated blocking '(do child (params ...))' as the next bounded implementation; the selected contract is top-level repeat-body only, static parameter overrides only, no repeat-body bind or domain subclauses, no cross-domain activation, no nested branch/loop placement, and no multi-pending await_any widening.`
  Verification: `mdbook build docs/book; git diff --check`
  Commit: `ISF-REPEAT-BODY-CHILD-ACTIVATION.7: select repeat generated do`

- ID: `ISF-REPEAT-BODY-CHILD-ACTIVATION.8`
  Status: `done`
  Goal: `Ship repeat-body generated blocking do with static parameter overrides if selected.`
  Acceptance: `Top-level repeat bodies accept '(do child (params ...))' when the generated child instance is static and the do state waits for that instance's fresh done pulse before the repeat check can loop; the generated top emits one generated do instance and parameter binding for the lexical do site; repeat-body '(bind ...)', '(domain NAME)', generated-child targets not owned by this selected do site, sample-before/after-do timing, nested placement, cross-domain activation, and multi-pending await_any remain fail-closed.`
  Verification: `syntax checks; focused repeat/do/generated-composition/doc tests; mdbook build docs/book; ./bin/ci-regression isf --no-book; git diff --check`
  Commit: `ISF-REPEAT-BODY-CHILD-ACTIVATION.8: implement repeat generated do params`

- ID: `ISF-REPEAT-BODY-CHILD-ACTIVATION.9`
  Status: `done`
  Goal: `Select the next repeat-body generated do binding subset.`
  Acceptance: `Task tree, roadmap, and book backlog select top-level repeat-body generated blocking '(do child (params ...) (bind ...))' as the next bounded implementation; the selected contract reuses the static generated do instance from the parameter subset, adds generated-top input/output binding handoffs once for that lexical do site, and keeps repeat-body domain metadata, nested placement, cross-domain activation, multi-pending await_any, plain generated-child local do targets, and sample-before/after-do timing deferred.`
  Verification: `mdbook build docs/book; git diff --check`
  Commit: `ISF-REPEAT-BODY-CHILD-ACTIVATION.9: select repeat generated do bindings`

- ID: `ISF-REPEAT-BODY-CHILD-ACTIVATION.10`
  Status: `done`
  Goal: `Ship repeat-body generated blocking do with static parameter overrides and port bindings if selected.`
  Acceptance: `Top-level repeat bodies accept '(do child (params ...) (bind ...))' when the generated do instance is static, binding handoff ports are emitted once in the generated top for the lexical do site, input/output binding provenance is visible in reports, and the do state still waits for the generated instance's fresh done handoff before the repeat check can loop; repeat-body '(domain NAME)', nested placement, cross-domain activation, multi-pending await_any, plain generated-child local do targets, and sample-before/after-do timing remain fail-closed.`
  Verification: `syntax checks; focused repeat/do/binding/generated-composition/doc tests; mdbook build docs/book; ./bin/ci-regression isf --no-book; git diff --check`
  Commit: `ISF-REPEAT-BODY-CHILD-ACTIVATION.10: implement repeat generated do bindings`

- ID: `ISF-REPEAT-BODY-CHILD-ACTIVATION.11`
  Status: `done`
  Goal: `Select the next repeat-body child activation subset.`
  Acceptance: `Task tree, roadmap, and book backlog select top-level repeat-body generated blocking '(do child (params ...) [(bind ...)] (domain NAME))' as the next bounded implementation; the selected contract is declared same-domain ownership metadata only on the static generated do instance, with no CDC, cross-domain activation, nested placement, multi-pending await_any, plain generated-child local do target, or sample-before/after-do widening.`
  Verification: `mdbook build docs/book; git diff --check`
  Commit: `ISF-REPEAT-BODY-CHILD-ACTIVATION.11: select repeat generated do domains`

- ID: `ISF-REPEAT-BODY-CHILD-ACTIVATION.12`
  Status: `done`
  Goal: `Ship repeat-body generated blocking do same-domain metadata if selected.`
  Acceptance: `Top-level repeat bodies accept '(do child (params ...) [(bind ...)] (domain NAME))' when NAME is the declared same-domain owner for the parent transaction and generated child; generated composition metadata and schedule-report clock-domain summaries preserve that ownership for the lexical repeat-do instance, while undeclared domains, cross-domain activation, nested placement, multi-pending await_any, plain generated-child local do targets, and sample-before/after-do timing remain fail-closed.`
  Verification: `syntax checks; focused repeat/do/domain/generated-composition/doc tests; mdbook build docs/book; ./bin/ci-regression isf --no-book; git diff --check`
  Commit: `ISF-REPEAT-BODY-CHILD-ACTIVATION.12: implement repeat generated do domains`

- ID: `ISF-REPEAT-BODY-CHILD-ACTIVATION.13`
  Status: `done`
  Goal: `Select the next repeat-body child activation subset.`
  Acceptance: `Task tree, roadmap, and book backlog select top-level repeat-body spawn-after-sample ordering as the next bounded implementation; the selected contract allows repeat-body samples before a later same-body spawn only when the same body still reaches await_all or single-pending await_any before the repeat check can loop, with pending samples materialized before the spawn state.`
  Verification: `mdbook build docs/book; git diff --check`
  Commit: `ISF-REPEAT-BODY-CHILD-ACTIVATION.13: select repeat spawn after sample`

- ID: `ISF-REPEAT-BODY-CHILD-ACTIVATION.14`
  Status: `done`
  Goal: `Ship repeat-body spawn-after-sample ordering if selected.`
  Acceptance: `Top-level repeat bodies accept samples before later repeat-body spawn only when the same body reaches await_all or single-pending await_any before the repeat check can loop; lowering emits an explicit sample state before the spawn state, then a same-body sync state before the repeat back-edge; sample-before/after-do timing, nested placement, cross-domain activation, multi-pending await_any, and broader outstanding-child semantics remain fail-closed.`
  Verification: `syntax checks; focused repeat/spawn/sample/doc tests; mdbook build docs/book; ./bin/ci-regression isf --no-book; git diff --check`
  Commit: `ISF-REPEAT-BODY-CHILD-ACTIVATION.14: implement repeat spawn after sample`

- ID: `ISF-REPEAT-BODY-CHILD-ACTIVATION.15`
  Status: `done`
  Goal: `Select the next repeat-body child activation subset.`
  Acceptance: `Task tree, roadmap, and book backlog select top-level repeat-body plain '(do child)' targeting an already generated child as the next bounded implementation after repeat-body spawn-after-sample ordering; the selected contract emits a static generated do instance for the lexical repeat-body do site without requiring '(params ...)', '(bind ...)', or '(domain NAME)' on that site, waits for that instance's fresh done handoff before the repeat check can loop, and keeps sample-before/after-do timing, nested placement, cross-domain activation, multi-pending await_any, and broader outstanding-child semantics deferred.`
  Verification: `mdbook build docs/book; git diff --check`
  Commit: `ISF-REPEAT-BODY-CHILD-ACTIVATION.15: select repeat generated-child do`

- ID: `ISF-REPEAT-BODY-CHILD-ACTIVATION.16`
  Status: `done`
  Goal: `Ship repeat-body plain do targeting already generated children if selected.`
  Acceptance: `Top-level repeat bodies accept plain '(do child)' when the target child transaction is already emitted as a generated child by another activation site; lowering emits one deterministic generated do instance for the lexical repeat-body do site, with no parameter override, binding, or domain subclauses on that site, starts that generated instance, waits for its fresh done handoff before the repeat check, and keeps sample-before/after-do timing, nested placement, cross-domain activation, multi-pending await_any, and broader outstanding-child semantics fail-closed.`
  Verification: `syntax checks; focused repeat/do/generated-composition/doc tests; mdbook build docs/book; ./bin/ci-regression isf --no-book; git diff --check`
  Commit: `ISF-REPEAT-BODY-CHILD-ACTIVATION.16: implement repeat generated-child do`

- ID: `ISF-REPEAT-BODY-CHILD-ACTIVATION.17`
  Status: `done`
  Goal: `Select the next repeat-body child activation subset.`
  Acceptance: `Task tree, roadmap, and book backlog select top-level repeat-body sample-before/after-do timing as the next bounded implementation after repeat-body generated-child do; the selected contract allows pending samples immediately before or after shipped repeat-body local or generated do states, materializes them at the source-order timing point before the do state or before the repeat check, and keeps nested placement, cross-domain activation, multi-pending await_any, and broader outstanding-child semantics deferred.`
  Verification: `mdbook build docs/book; git diff --check`
  Commit: `ISF-REPEAT-BODY-CHILD-ACTIVATION.17: select repeat do samples`

- ID: `ISF-REPEAT-BODY-CHILD-ACTIVATION.18`
  Status: `done`
  Goal: `Ship repeat-body sample-before/after-do timing if selected.`
  Acceptance: `Top-level repeat bodies accept samples before or after shipped repeat-body local or generated do states; pending samples before do lower into an explicit sample state before the do state, pending samples after do lower into an explicit sample state after the do state's fresh done guard and before the repeat check, and nested placement, cross-domain activation, multi-pending await_any, and broader outstanding-child semantics remain fail-closed.`
  Verification: `syntax checks; focused repeat/do/generated-composition/doc tests; mdbook build docs/book; ./bin/ci-regression isf --no-book; git diff --check`
  Commit: `ISF-REPEAT-BODY-CHILD-ACTIVATION.18: implement repeat do samples`

- ID: `ISF-REPEAT-BODY-CHILD-ACTIVATION.19`
  Status: `done`
  Goal: `Select the next repeat-body child activation subset.`
  Acceptance: `Task tree, roadmap, and book backlog select multi-pending repeat-body '(await_any done)' as the next bounded subset only when the same repeat body later reaches '(await_all done)' for the same outstanding repeat-body spawns before the repeat check can loop; the selected contract treats await_any as an observation point, forbids new repeat-body spawn or do before the mandatory drain, and keeps nested placement, cross-domain activation, and broader outstanding-child semantics deferred.`
  Verification: `mdbook build docs/book; git diff --check`
  Commit: `ISF-REPEAT-BODY-CHILD-ACTIVATION.19: select repeat await_any drain`

- ID: `ISF-REPEAT-BODY-CHILD-ACTIVATION.20`
  Status: `done`
  Goal: `Ship repeat-body multi-pending await_any with mandatory same-body await_all drain if selected.`
  Acceptance: `Top-level repeat bodies accept multi-pending '(await_any done)' only after multiple repeat-body spawns when a later same-body '(await_all done)' drains those outstanding children before the repeat check can loop; lowering emits the await_any sync state without clearing the outstanding spawn set until await_all, rejects new repeat-body spawn or do before that drain, preserves samples before each sync point, and leaves nested placement, cross-domain activation, and broader outstanding-child semantics fail-closed.`
  Verification: `syntax checks; focused repeat/spawn/await-any/doc tests; mdbook build docs/book; ./bin/ci-regression isf --no-book; git diff --check`
  Commit: `ISF-REPEAT-BODY-CHILD-ACTIVATION.20: implement repeat await_any drain`

- ID: `ISF-REPEAT-BODY-CHILD-ACTIVATION.21`
  Status: `done`
  Goal: `Select the next repeat-body child activation subset.`
  Acceptance: `Task tree, roadmap, and book backlog select top-level when-body nested repeat local '(do child)' as the next bounded implementation subset; the selected contract permits only local child activation inside a repeat that is itself in a top-level when body, preserves done-gated nested repeat re-entry, and keeps repeat-body spawn, generated repeat-body do, bind/domain metadata, switch/loop nesting, cross-domain activation, and broader outstanding-child semantics deferred.`
  Verification: `mdbook build docs/book; git diff --check`
  Commit: `ISF-REPEAT-BODY-CHILD-ACTIVATION.21: select when repeat local do`

- ID: `ISF-REPEAT-BODY-CHILD-ACTIVATION.22`
  Status: `done`
  Goal: `Ship when-body nested repeat local do if selected.`
  Acceptance: `Top-level when bodies accept nested '(repeat COUNT ... (do child) ...)' only for local child transactions that remain in the parent scheduled module; lowering emits the repeat-local do state inside the branch-owned repeat region, waits for the child's fresh done pulse before the nested repeat check, preserves samples around the nested do through existing source-order sample states, and keeps repeat-body spawn, generated repeat-body do, bind/domain metadata, switch/loop nesting, cross-domain activation, and broader outstanding-child semantics fail-closed.`
  Verification: `syntax checks; focused repeat/do/doc tests; mdbook build docs/book; ./bin/ci-regression isf --no-book; git diff --check`
  Commit: `ISF-REPEAT-BODY-CHILD-ACTIVATION.22: implement when repeat local do`

- ID: `ISF-REPEAT-BODY-CHILD-ACTIVATION.23`
  Status: `done`
  Goal: `Select the next repeat-body child activation subset.`
  Acceptance: `Task tree, roadmap, and book backlog select top-level switch-branch nested repeat local '(do child)' as the next bounded implementation subset; the selected contract permits only local child activation inside a repeat that is directly in a top-level switch branch, preserves done-gated nested repeat re-entry, and keeps repeat-body spawn, generated repeat-body do, bind/domain metadata, deeper branch/loop nesting, cross-domain activation, and broader outstanding-child semantics deferred.`
  Verification: `mdbook build docs/book; git diff --check`
  Commit: `ISF-REPEAT-BODY-CHILD-ACTIVATION.23: select switch repeat local do`

- ID: `ISF-REPEAT-BODY-CHILD-ACTIVATION.24`
  Status: `done`
  Goal: `Ship switch-branch nested repeat local do if selected.`
  Acceptance: `Top-level switch branches accept nested '(repeat COUNT ... (do child) ...)' only for local child transactions that remain in the parent scheduled module; lowering emits the repeat-local do state inside the branch-owned repeat region, waits for the child's fresh done pulse before the nested repeat check, preserves samples around the nested do through existing source-order sample states, and keeps repeat-body spawn, generated repeat-body do, bind/domain metadata, deeper branch/loop nesting, cross-domain activation, and broader outstanding-child semantics fail-closed.`
  Verification: `syntax checks; focused switch/repeat/do/doc tests; mdbook build docs/book; ./bin/ci-regression isf --no-book; git diff --check`
  Commit: `ISF-REPEAT-BODY-CHILD-ACTIVATION.24: implement switch repeat local do`

- ID: `ISF-REPEAT-BODY-CHILD-ACTIVATION.25`
  Status: `done`
  Goal: `Select the next repeat-body child activation subset.`
  Acceptance: `Task tree, roadmap, and book backlog select top-level when-body nested repeat plain '(do child)' targeting an already generated child as the next bounded implementation subset; the selected contract emits a deterministic generated do instance for the lexical nested repeat-body do site, waits for that instance's fresh done handoff before the nested repeat check, and keeps activation subclauses, local parameter overrides, bind/domain metadata, spawn nesting, switch/deeper branch/loop nesting, cross-domain activation, and broader outstanding-child semantics deferred.`
  Verification: `mdbook build docs/book; git diff --check`
  Commit: `ISF-REPEAT-BODY-CHILD-ACTIVATION.25: select when repeat generated-child do`

- ID: `ISF-REPEAT-BODY-CHILD-ACTIVATION.26`
  Status: `done`
  Goal: `Ship when-body nested repeat generated-child do if selected.`
  Acceptance: `Top-level when bodies accept nested '(repeat COUNT ... (do child) ...)' when the plain child target is already emitted as a generated child by another activation site; lowering emits one deterministic generated do instance for the lexical nested repeat-body do site, waits for that instance's fresh done handoff before the nested repeat check, preserves samples around the nested do through existing source-order sample states, and keeps activation subclauses, local parameter overrides, bind/domain metadata, spawn nesting, switch/deeper branch/loop nesting, cross-domain activation, and broader outstanding-child semantics fail-closed.`
  Verification: `syntax checks; focused repeat/do/generated-composition/doc tests; mdbook build docs/book; ./bin/ci-regression isf --no-book; git diff --check`
  Commit: `ISF-REPEAT-BODY-CHILD-ACTIVATION.26: implement when repeat generated-child do`

- ID: `ISF-REPEAT-BODY-CHILD-ACTIVATION.27`
  Status: `done`
  Goal: `Select the next repeat-body child activation subset.`
  Acceptance: `Task tree, roadmap, and book backlog select top-level switch-branch nested repeat plain '(do child)' targeting an already generated child as the next bounded implementation subset; the selected contract emits one deterministic generated do instance for the lexical nested repeat-body do site, waits for that instance's fresh done handoff before the switch-branch nested repeat check, and keeps activation subclauses, local parameter overrides, bind/domain metadata, spawn nesting, deeper branch/loop nesting, cross-domain activation, and broader outstanding-child semantics deferred.`
  Verification: `mdbook build docs/book; git diff --check`
  Commit: `ISF-REPEAT-BODY-CHILD-ACTIVATION.27: select switch repeat generated-child do`

- ID: `ISF-REPEAT-BODY-CHILD-ACTIVATION.28`
  Status: `done`
  Goal: `Ship switch-branch nested repeat generated-child do if selected.`
  Acceptance: `Top-level switch branches accept nested '(repeat COUNT ... (do child) ...)' when the plain child target is already emitted as a generated child by another activation site; lowering emits one deterministic generated do instance for the lexical nested repeat-body do site, waits for that instance's fresh done handoff before the nested repeat check, preserves samples around the nested do through existing source-order sample states, and keeps activation subclauses, local parameter overrides, bind/domain metadata, spawn nesting, deeper branch/loop nesting, cross-domain activation, and broader outstanding-child semantics fail-closed.`
  Verification: `syntax checks; focused switch/repeat/do/generated-composition/doc tests; mdbook build docs/book; ./bin/ci-regression isf --no-book; git diff --check`
  Commit: `ISF-REPEAT-BODY-CHILD-ACTIVATION.28: implement switch repeat generated-child do`

- ID: `ISF-REPEAT-BODY-CHILD-ACTIVATION.29`
  Status: `done`
  Goal: `Select the next repeat-body child activation subset.`
  Acceptance: `Task tree, roadmap, and book backlog select top-level when-body nested repeat generated blocking '(do child (params ...))' as the next bounded implementation subset; the selected contract emits one deterministic generated do instance for the lexical nested repeat-body do site, applies static parameter overrides once in the generated top, waits for that instance's fresh done handoff before the when-body nested repeat check, and keeps bind/domain metadata, spawn nesting, switch-contained parameterized nested do, deeper branch/loop nesting, cross-domain activation, and broader outstanding-child semantics deferred.`
  Verification: `mdbook build docs/book; git diff --check`
  Commit: `ISF-REPEAT-BODY-CHILD-ACTIVATION.29: select when repeat generated do params`

- ID: `ISF-REPEAT-BODY-CHILD-ACTIVATION.30`
  Status: `done`
  Goal: `Ship when-body nested repeat generated do with static parameter overrides if selected.`
  Acceptance: `Top-level when bodies accept nested '(repeat COUNT ... (do child (params ...)) ...)' with static parameter overrides; lowering emits one deterministic generated do instance for the lexical nested repeat-body do site, applies overrides once in the generated top, waits for that instance's fresh done handoff before the nested repeat check, preserves samples around the nested do through existing source-order sample states, and keeps bind/domain metadata, spawn nesting, switch-contained parameterized nested do, deeper branch/loop nesting, cross-domain activation, and broader outstanding-child semantics fail-closed.`
  Verification: `syntax checks; touched test Files=1, Tests=19; repeat/doc suite Files=4, Tests=324; focused suite Files=12, Tests=355; mdbook build docs/book; ./bin/ci-regression isf --no-book Files=227, Tests=1135; git diff --check`
  Commit: `ISF-REPEAT-BODY-CHILD-ACTIVATION.30: implement when repeat generated do params`

- ID: `ISF-REPEAT-BODY-CHILD-ACTIVATION.31`
  Status: `pending`
  Goal: `Select the next repeat-body child activation subset.`
  Acceptance: `Task tree, roadmap, and book backlog select the next bounded repeat-body child activation subset before implementation; likely candidates include switch-contained parameterized generated nested do, nested generated-do bindings, nested generated-do domain metadata, spawn nesting, cross-domain activation, deeper branch/loop nesting, or broader outstanding-child semantics.`
  Verification: `pending`
  Commit: `pending`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `ISF-REPEAT-BODY-CHILD-ACTIVATION.1` | `done` | Selected repeat-body spawn port bindings as the next bounded implementation subset. |
| 2 | `ISF-REPEAT-BODY-CHILD-ACTIVATION.2` | `done` | Shipped repeat-body spawn port-binding handoffs on the top-level repeat plus same-body `await_all` path. |
| 3 | `ISF-REPEAT-BODY-CHILD-ACTIVATION.3` | `done` | Shipped repeat-body spawn same-domain ownership annotations without implying CDC behavior. |
| 4 | `ISF-REPEAT-BODY-CHILD-ACTIVATION.4` | `done` | Shipped repeat-body await_any for the exactly-one-pending-spawn subset. |
| 5 | `ISF-REPEAT-BODY-CHILD-ACTIVATION.5` | `done` | Shipped repeat-body local blocking `do` with local child start/done re-entry proof. |
| 6 | `ISF-REPEAT-BODY-CHILD-ACTIVATION.6` | `done` | Shipped repeat-body sample-after-spawn timing before same-body sync. |
| 7 | `ISF-REPEAT-BODY-CHILD-ACTIVATION.7` | `done` | Selected repeat-body generated blocking `do` with static parameter overrides as the next bounded subset. |
| 8 | `ISF-REPEAT-BODY-CHILD-ACTIVATION.8` | `done` | Shipped repeat-body generated blocking `do` with static parameter overrides. |
| 9 | `ISF-REPEAT-BODY-CHILD-ACTIVATION.9` | `done` | Selected repeat-body generated blocking `do` with static parameter overrides and port bindings. |
| 10 | `ISF-REPEAT-BODY-CHILD-ACTIVATION.10` | `done` | Shipped repeat-body generated blocking `do` with static parameter overrides and port bindings. |
| 11 | `ISF-REPEAT-BODY-CHILD-ACTIVATION.11` | `done` | Selected repeat-body generated blocking `do` same-domain metadata as the next bounded subset. |
| 12 | `ISF-REPEAT-BODY-CHILD-ACTIVATION.12` | `done` | Shipped repeat-body generated blocking `do` same-domain metadata. |
| 13 | `ISF-REPEAT-BODY-CHILD-ACTIVATION.13` | `done` | Selected repeat-body spawn-after-sample ordering as the next bounded subset. |
| 14 | `ISF-REPEAT-BODY-CHILD-ACTIVATION.14` | `done` | Shipped repeat-body spawn-after-sample ordering before same-body sync. |
| 15 | `ISF-REPEAT-BODY-CHILD-ACTIVATION.15` | `done` | Selected repeat-body plain `do` targeting an already generated child as the next bounded subset. |
| 16 | `ISF-REPEAT-BODY-CHILD-ACTIVATION.16` | `done` | Shipped repeat-body generated-child `do` for already generated targets. |
| 17 | `ISF-REPEAT-BODY-CHILD-ACTIVATION.17` | `done` | Selected repeat-body sample-before/after-do timing as the next bounded subset. |
| 18 | `ISF-REPEAT-BODY-CHILD-ACTIVATION.18` | `done` | Shipped repeat-body sample-before/after-do timing around local and generated `do` states. |
| 19 | `ISF-REPEAT-BODY-CHILD-ACTIVATION.19` | `done` | Selected multi-pending repeat-body `await_any` with mandatory same-body `await_all` drain. |
| 20 | `ISF-REPEAT-BODY-CHILD-ACTIVATION.20` | `done` | Shipped multi-pending repeat-body `await_any` with mandatory same-body `await_all` drain. |
| 21 | `ISF-REPEAT-BODY-CHILD-ACTIVATION.21` | `done` | Selected top-level when-body nested repeat local `do`. |
| 22 | `ISF-REPEAT-BODY-CHILD-ACTIVATION.22` | `done` | Shipped the selected when-contained repeat local do subset. |
| 23 | `ISF-REPEAT-BODY-CHILD-ACTIVATION.23` | `done` | Selected top-level switch-branch nested repeat local `do`. |
| 24 | `ISF-REPEAT-BODY-CHILD-ACTIVATION.24` | `done` | Shipped the selected switch-contained repeat local do subset. |
| 25 | `ISF-REPEAT-BODY-CHILD-ACTIVATION.25` | `done` | Selected top-level when-body nested repeat generated-child `do`. |
| 26 | `ISF-REPEAT-BODY-CHILD-ACTIVATION.26` | `done` | Shipped the selected when-contained repeat generated-child do subset. |
| 27 | `ISF-REPEAT-BODY-CHILD-ACTIVATION.27` | `done` | Selected top-level switch-branch nested repeat generated-child `do`. |
| 28 | `ISF-REPEAT-BODY-CHILD-ACTIVATION.28` | `done` | Shipped the selected switch-contained repeat generated-child do subset. |
| 29 | `ISF-REPEAT-BODY-CHILD-ACTIVATION.29` | `done` | Selected top-level when-body nested repeat generated `do` with static parameter overrides. |
| 30 | `ISF-REPEAT-BODY-CHILD-ACTIVATION.30` | `done` | Shipped the selected when-contained repeat generated do static-parameter subset. |
| 31 | `ISF-REPEAT-BODY-CHILD-ACTIVATION.31` | `pending` | Selects the next bounded repeat-body child activation subset before code. |

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
- `2026-05-17`: Leaf `.2` shipped repeat-body spawn `(bind ...)` for top-level
  repeat bodies that reach same-body `(await_all done)` before the repeat check.
  Validation now covers generated parent handoff metadata, generated-top
  wiring, schedule-report `transaction_port_bindings[]` provenance, and
  fail-closed validation for missing/invalid repeat-body bindings.
- `2026-05-17`: Leaf `.3` is bounded to same-domain repeat-body spawn
  `(domain NAME)` annotations on the existing static-instance plus same-body
  `await_all` subset. The annotation selects declared ownership metadata only;
  it does not ship cross-domain activation, CDC handoff, or relaxed binding
  rules.
- `2026-05-17`: Leaf `.3` shipped repeat-body spawn `(domain NAME)` on the
  existing top-level repeat plus same-body `await_all` subset. Declared
  same-domain annotations are preserved in generated-child metadata and
  `clock_domains[].child_instances[]`; undeclared domains and cross-domain
  activation remain fail-closed.
- `2026-05-17`: Leaf `.4` is bounded to the single-pending-spawn
  repeat-body `await_any` subset. Multi-pending `await_any` would leave
  outstanding static children across the repeat back-edge, so it remains
  fail-closed until a broader lifetime contract ships.
- `2026-05-17`: Leaf `.4` shipped repeat-body `(await_any done)` when exactly
  one repeat-body spawn is pending. Zero-pending and multi-pending repeat-body
  `await_any` remain fail-closed with targeted diagnostics.
- `2026-05-17`: Leaf `.5` is bounded to local blocking `(do child)` in a
  top-level repeat body. The child must remain in the parent scheduled module,
  the repeat body must wait on the child's fresh done pulse before the repeat
  check back-edge, and generated/parameterized/bound/domain-qualified
  repeat-body `do`, nested repeat-body `do`, cross-domain activation, and
  sample-before/after-do timing remain deferred.
- `2026-05-17`: Leaf `.5` shipped repeat-body local `(do child)` for the
  top-level repeat subset. Repeat-body local `do` uses parent-module
  start/done wiring and reaches the repeat check only after the child done
  pulse; generated/parameterized/bound/domain-qualified repeat-body `do`,
  generated-child targets, nested repeat-body `do`, cross-domain activation,
  and sample-before/after-do timing remain fail-closed.
- `2026-05-17`: Leaf `.6` is bounded to repeat-body sample-after-spawn timing.
  The selected source shape is top-level repeat-body spawn, then one or more
  samples, then same-body `await_all` or single-pending `await_any`; samples
  must materialize before the sync state so the timing is explicit, while
  spawn-after-sample and sample-before/after-do remain deferred.
- `2026-05-17`: Leaf `.6` shipped repeat-body sample-after-spawn timing for
  the top-level repeat subset. Pending samples after spawn now drain through
  an explicit sample state before same-body `await_all` or single-pending
  `await_any`; spawn-after-sample, sample-before/after-do, multi-pending
  `await_any`, nested activation, and cross-domain activation remain
  fail-closed.
- `2026-05-17`: Leaf `.7` selects repeat-body generated blocking `do` with
  static parameter overrides as the next implementation subset. The selected
  source shape is top-level repeat-body `(do child (params ...))`; it should
  reuse one generated child instance and wait for that instance's fresh done
  pulse before the repeat check. Repeat-body `(bind ...)`, `(domain NAME)`,
  nested placement, cross-domain activation, multi-pending `await_any`, and
  sample-before/after-do timing remain out of scope.
- `2026-05-17`: Leaf `.8` shipped repeat-body generated blocking
  `(do child (params ...))` for top-level repeat bodies. The generated do site
  owns one `{parent}_{child}_repeat_do_{ordinal}` instance, static parameter
  overrides are applied once in the generated top, and the repeat check is
  reachable only after the generated instance's fresh done handoff. Repeat-body
  do bindings, domain metadata, plain local do targeting an already generated
  child, nested placement, cross-domain activation, multi-pending `await_any`,
  and sample-before/after-do timing remained fail-closed at that leaf.
- `2026-05-17`: Leaf `.9` selects repeat-body generated blocking
  `(do child (params ...) (bind ...))` as the next implementation subset. The
  selected contract reuses the `.8` static generated do instance, adds
  generated-top input/output binding handoffs once for the lexical repeat-body
  do site, and keeps repeat-body `(domain NAME)`, nested placement,
  cross-domain activation, multi-pending `await_any`, plain generated-child
  local do targets, and sample-before/after-do timing out of scope.
- `2026-05-17`: Leaf `.10` shipped repeat-body generated blocking
  `(do child (params ...) (bind ...))` for top-level repeat bodies. The
  generated do site owns one `{parent}_{child}_repeat_do_{ordinal}` instance,
  static parameter overrides and input/output binding handoff ports are wired
  once in the generated top, schedule JSON reports the do-site binding
  provenance, and the repeat check is reachable only after the generated
  instance's fresh done handoff. Repeat-body `(domain NAME)`, plain local do
  targeting an already generated child, nested placement, cross-domain
  activation, multi-pending `await_any`, and sample-before/after-do timing
  remain fail-closed.
- `2026-05-17`: Leaf `.11` selects repeat-body generated blocking
  `(do child (params ...) [(bind ...)] (domain NAME))` as the next
  implementation subset. The selected contract is same-domain ownership
  metadata only for the static generated do instance; it should preserve
  generated-composition and schedule-report clock-domain metadata without
  implying CDC, cross-domain activation, nested placement, broader
  outstanding-child semantics, or sample-before/after-do timing.
- `2026-05-17`: Leaf `.12` shipped repeat-body generated blocking
  `(do child (params ...) [(bind ...)] (domain NAME))` for top-level repeat
  bodies. The generated do site preserves declared same-domain ownership on
  the deterministic `{parent}_{child}_repeat_do_{ordinal}` instance,
  generated-composition metadata, and `clock_domains[].child_instances`
  summaries without changing done-gated repeat re-entry. Undeclared domains,
  cross-domain activation, plain local do targeting an already generated
  child, nested placement, multi-pending `await_any`, and
  sample-before/after-do timing remain fail-closed.
- `2026-05-17`: Leaf `.13` selects repeat-body spawn-after-sample ordering as
  the next implementation subset. The selected contract keeps the same
  static-child lifetime proof as the existing repeat-body spawn subset:
  pending samples before the spawn must materialize before the spawn state,
  and the same repeat body must still reach `await_all` or single-pending
  `await_any` before the repeat check can loop.
- `2026-05-17`: Leaf `.14` shipped repeat-body spawn-after-sample ordering.
  Pending samples before a later repeat-body spawn now materialize in an
  explicit sample state before the spawn state, and the same repeat body must
  still reach `await_all` or single-pending `await_any` before the repeat
  check can loop. Sample-before/after-do timing, nested placement,
  cross-domain activation, multi-pending `await_any`, and broader
  outstanding-child semantics remain fail-closed.
- `2026-05-17`: Leaf `.15` selects repeat-body plain `(do child)` targeting
  an already generated child as the next implementation subset. The selected
  contract should mirror top-level generated-child `do`: the lexical
  repeat-body do site owns one deterministic generated activation instance
  without requiring local `(params ...)`, `(bind ...)`, or `(domain NAME)`
  subclauses, and repeat re-entry remains gated by that instance's fresh done
  handoff.
- `2026-05-17`: Leaf `.16` shipped repeat-body plain `(do child)` targeting
  already generated children. The lowerer now emits one deterministic
  `{parent}_{child}_repeat_do_{ordinal}` generated activation instance for the
  lexical repeat-body do site, starts that instance from the repeat body, and
  gates the repeat check on that instance's fresh done handoff without
  requiring local parameter, binding, or domain subclauses.
- `2026-05-17`: Leaf `.17` selects repeat-body sample-before/after-do timing
  as the next implementation subset. The selected contract should drain
  samples before do into an explicit sample state before the do state, and
  samples after do into an explicit sample state after the do state's fresh
  done guard and before the repeat check.
- `2026-05-17`: Leaf `.18` shipped repeat-body sample-before/after-do timing
  around shipped top-level repeat-body local and generated `do` states.
  Pending samples before do materialize before the do state; pending samples
  after do materialize after the do state's fresh done guard and before the
  repeat check.
- `2026-05-17`: Leaf `.19` selects multi-pending repeat-body
  `(await_any done)` only as an observation point when a later same-body
  `(await_all done)` drains the same outstanding repeat-body spawns before the
  repeat check can loop. New repeat-body `spawn` or `do` clauses before that
  mandatory drain remain out of scope for the selected implementation.
- `2026-05-17`: Leaf `.20` shipped the selected multi-pending repeat-body
  `await_any` drain subset. Lowering emits the `await_any` sync state without
  clearing the outstanding spawned done-port set, then uses the later
  same-body `await_all` drain to gate the repeat check.
- `2026-05-17`: Leaf `.21` selects top-level `when` bodies containing nested
  repeats with local repeat-body `(do child)` as the next bounded nested
  placement subset. Generated nested repeat activation, spawn nesting,
  bind/domain metadata, switch/loop nesting, cross-domain activation, and
  broader outstanding-child semantics remain deferred.
- `2026-05-17`: Leaf `.22` shipped the selected top-level when-body nested
  repeat local `(do child)` subset. The lowerer collects local child refs from
  repeats directly inside top-level `when` bodies, wires local start/done
  handoffs, lowers samples around the nested do in source order, and rejects
  generated targets, `(params ...)`, `(bind ...)`, `(domain NAME)`,
  deeper branch/loop repeats, and generated/spawn nested activation.
- `2026-05-17`: Leaf `.23` is the next frontier and must select the next
  bounded repeat-body child-activation subset before code changes begin.
- `2026-05-17`: Leaf `.23` selects top-level switch-branch nested repeat local
  `(do child)` as the next bounded nested-placement subset. The selected
  source shape is a repeat directly inside a top-level `switch` branch body,
  with only local child activation, source-order samples around the nested do,
  and a nested repeat check gated by the child's fresh done pulse. Generated
  targets, activation subclauses, repeat-body spawn, deeper branch/loop
  nesting, cross-domain activation, and broader outstanding-child semantics
  remain deferred for this selected subset.
- `2026-05-17`: Leaf `.24` shipped the selected top-level switch-branch
  nested repeat local `(do child)` subset. The lowerer collects local child
  refs from repeats directly inside top-level `switch` branch bodies, wires
  local start/done handoffs, lowers samples around the nested do in source
  order, and rejects generated targets, `(params ...)`, `(bind ...)`,
  `(domain NAME)`, repeat-body spawn, deeper branch/loop nesting, and
  generated/spawn nested activation.
- `2026-05-17`: Leaf `.25` is the next frontier and must select the next
  bounded repeat-body child-activation subset before code changes begin.
- `2026-05-17`: Leaf `.25` selects top-level when-body nested repeat plain
  `(do child)` targeting an already generated child as the next bounded
  nested generated-child subset. The selected source shape is a repeat directly
  inside a top-level `when` body, with no activation subclauses at that nested
  do site; lowering should emit one deterministic generated do instance for
  the lexical nested do site and gate the nested repeat check on that
  instance's fresh done handoff.
- `2026-05-17`: Leaf `.26` shipped the selected top-level when-body nested
  repeat generated-child `do` subset. The lowerer now threads generated-child
  instance context into repeats that are direct clauses of a top-level `when`
  body, emits one deterministic generated do instance for a plain nested
  `(do child)` target already generated elsewhere, keeps source-order samples
  around that do, and gates the nested repeat check on the generated instance's
  fresh done handoff. Activation subclauses, spawn nesting,
  switch-contained generated-child `do`, deeper branch/loop nesting,
  cross-domain activation, and broader outstanding-child semantics remain
  fail-closed.
- `2026-05-17`: Leaf `.27` is the next frontier and must select the next
  bounded repeat-body child activation subset before any further code changes.
- `2026-05-17`: Leaf `.27` selects top-level switch-branch nested repeat
  plain `(do child)` targeting an already generated child as the next bounded
  nested generated-child subset. The selected source shape is a repeat
  directly inside a top-level `switch` branch, with no activation subclauses
  at that nested do site; lowering should emit one deterministic generated do
  instance for the lexical nested do site and gate the switch-branch repeat
  check on that instance's fresh done handoff.
- `2026-05-17`: Leaf `.28` is the next implementation frontier for the
  selected switch-contained repeat generated-child do subset.
- `2026-05-17`: Leaf `.28` shipped the selected top-level switch-branch
  nested repeat generated-child `do` subset. The lowerer now threads
  generated-child instance context into repeats that are direct clauses of a
  top-level `switch` branch, emits one deterministic generated do instance for
  a plain nested `(do child)` target already generated elsewhere, keeps
  source-order samples around that do, and gates the switch-branch repeat
  check on the generated instance's fresh done handoff. Activation subclauses,
  spawn nesting, deeper branch/loop nesting, cross-domain activation, and
  broader outstanding-child semantics remain fail-closed.
- `2026-05-17`: Leaf `.29` is the next frontier and must select the next
  bounded repeat-body child activation subset before any further code changes.
- `2026-05-17`: Leaf `.29` selects top-level when-body nested repeat
  generated blocking `(do child (params ...))` as the next bounded nested
  generated-do subset. The selected source shape is a repeat directly inside a
  top-level `when` body, with static parameter overrides only at that nested
  do site; lowering should emit one deterministic generated do instance for
  the lexical nested do site, apply overrides once in the generated top, and
  gate the when-body repeat check on that instance's fresh done handoff.
- `2026-05-17`: Leaf `.30` is the next implementation frontier for the
  selected when-contained repeat generated do static-parameter subset.
- `2026-05-17`: Leaf `.30` shipped the selected top-level when-body nested
  repeat generated blocking `(do child (params ...))` subset. The lowerer now
  allows static parameter overrides on generated `do` sites inside repeats
  that are direct clauses of a top-level `when` body, emits one deterministic
  generated do instance for that lexical nested site, applies overrides once
  in the generated top, keeps source-order samples around the nested do, and
  gates the when-body repeat check on the generated instance's fresh done
  handoff. `(bind ...)`, `(domain NAME)`, spawn nesting,
  switch-contained parameterized generated nested do, deeper branch/loop
  nesting, cross-domain activation, and broader outstanding-child semantics
  remain fail-closed.
- `2026-05-17`: Leaf `.31` is the next frontier and must select the next
  bounded repeat-body child activation subset before any further code changes.

## Open Questions

- Which deferred repeat-body activation subset should leaf `.31` select next:
  switch-contained parameterized generated nested do, generated nested do
  bindings, generated nested do domain metadata, spawn nesting, cross-domain
  activation, deeper branch/loop nesting, or broader outstanding-child
  semantics.

## Blockers

- None for tracking. Implementation leaves must resolve their own timing,
  generated-top, domain, and report contracts before shipping.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-17` | `ISF-REPEAT-BODY-CHILD-ACTIVATION` | `mdbook build docs/book`; `git diff --check` | `book and diff checks passed after task-tree gate policy sync` |
| `2026-05-17` | `ISF-REPEAT-BODY-CHILD-ACTIVATION.1` | `mdbook build docs/book`; `git diff --check` | `book and diff checks passed` |
| `2026-05-17` | `ISF-REPEAT-BODY-CHILD-ACTIVATION.2` | `perl -Iperl -c perl/FSM/Scheduler/ISF/LoweringIR.pm`; `perl -Iperl -c t/1215-isf-spawn-parameter-binding.t`; `perl -Iperl -c t/1305-isf-book-feature-matrix-audit.t`; `prove -l t/1215-isf-spawn-parameter-binding.t t/1304-isf-repeat-body-doc-truth-audit.t t/1305-isf-book-feature-matrix-audit.t t/1307-isf-loop-body-doc-truth-audit.t`; `prove -l t/1241-isf-transaction-port-bindings.t t/1242-isf-port-binding-conflict-semantics.t t/1243-isf-port-binding-schedule-report.t`; `mdbook build docs/book`; `./bin/ci-regression isf --no-book`; `git diff --check` | `syntax, focused repeat/spawn/doc checks, adjacent port-binding/report checks, book build, full ISF gate, and diff check passed` |
| `2026-05-17` | `ISF-REPEAT-BODY-CHILD-ACTIVATION.3` | `perl -Iperl -c perl/FSM/Scheduler/ISF/LoweringIR.pm`; `perl -Iperl -c t/1215-isf-spawn-parameter-binding.t`; `perl -Iperl -c t/1304-isf-repeat-body-doc-truth-audit.t`; `perl -Iperl -c t/1305-isf-book-feature-matrix-audit.t`; `perl -Iperl -c t/1307-isf-loop-body-doc-truth-audit.t`; `prove -l t/1215-isf-spawn-parameter-binding.t t/1304-isf-repeat-body-doc-truth-audit.t t/1305-isf-book-feature-matrix-audit.t t/1307-isf-loop-body-doc-truth-audit.t t/1247-isf-clock-domain-partition.t`; `prove -l t/1204-isf-child-composition-clause-boundary.t t/1203-isf-await-sync-clause-boundary.t t/1241-isf-transaction-port-bindings.t t/1242-isf-port-binding-conflict-semantics.t t/1243-isf-port-binding-schedule-report.t`; `mdbook build docs/book`; `./bin/ci-regression isf --no-book`; `git diff --check` | `syntax, focused repeat/spawn/domain/doc checks, adjacent activation/binding/report checks, book build, full ISF gate, and diff check passed` |
| `2026-05-17` | `ISF-REPEAT-BODY-CHILD-ACTIVATION.4` | `perl -Iperl -c perl/FSM/Scheduler/ISF/LoweringIR.pm`; `perl -Iperl -c t/1215-isf-spawn-parameter-binding.t`; `perl -Iperl -c t/1304-isf-repeat-body-doc-truth-audit.t`; `perl -Iperl -c t/1305-isf-book-feature-matrix-audit.t`; `perl -Iperl -c t/1307-isf-loop-body-doc-truth-audit.t`; `prove -l t/1215-isf-spawn-parameter-binding.t t/1203-isf-await-sync-clause-boundary.t t/1304-isf-repeat-body-doc-truth-audit.t t/1305-isf-book-feature-matrix-audit.t t/1307-isf-loop-body-doc-truth-audit.t`; `mdbook build docs/book`; `./bin/ci-regression isf --no-book`; `git diff --check` | `syntax, focused repeat/spawn/await-any/doc checks, book build, full ISF gate, and diff check passed` |
| `2026-05-17` | `ISF-REPEAT-BODY-CHILD-ACTIVATION.5` | `perl -Iperl -c perl/FSM/Scheduler/ISF/LoweringIR.pm`; `perl -Iperl -c t/1215-isf-spawn-parameter-binding.t`; `perl -Iperl -c t/1304-isf-repeat-body-doc-truth-audit.t`; `perl -Iperl -c t/1305-isf-book-feature-matrix-audit.t`; `perl -Iperl -c t/1307-isf-loop-body-doc-truth-audit.t`; `prove -l t/1215-isf-spawn-parameter-binding.t t/1177-isf-do-child-done-pulse.t t/1184-isf-child-transaction-target-boundary.t t/1203-isf-await-sync-clause-boundary.t t/1304-isf-repeat-body-doc-truth-audit.t t/1305-isf-book-feature-matrix-audit.t t/1307-isf-loop-body-doc-truth-audit.t`; `mdbook build docs/book`; `./bin/ci-regression isf --no-book`; `git diff --check` | `syntax, focused repeat/do/doc checks (Files=7, Tests=291), book build, full ISF gate (Files=227, Tests=1089), and diff check passed` |
| `2026-05-17` | `ISF-REPEAT-BODY-CHILD-ACTIVATION.6` | `perl -Iperl -c perl/FSM/Scheduler/ISF/LoweringIR.pm`; `perl -Iperl -c t/1215-isf-spawn-parameter-binding.t`; `perl -Iperl -c t/1304-isf-repeat-body-doc-truth-audit.t`; `perl -Iperl -c t/1305-isf-book-feature-matrix-audit.t`; `perl -Iperl -c t/1307-isf-loop-body-doc-truth-audit.t`; `prove -l t/1215-isf-spawn-parameter-binding.t t/1177-isf-do-child-done-pulse.t t/1184-isf-child-transaction-target-boundary.t t/1203-isf-await-sync-clause-boundary.t t/1304-isf-repeat-body-doc-truth-audit.t t/1305-isf-book-feature-matrix-audit.t t/1307-isf-loop-body-doc-truth-audit.t`; `mdbook build docs/book`; `./bin/ci-regression isf --no-book`; `git diff --check` | `syntax, focused repeat/spawn/sample/doc checks (Files=7, Tests=297), book build, full ISF gate (Files=227, Tests=1095), and diff check passed` |
| `2026-05-17` | `ISF-REPEAT-BODY-CHILD-ACTIVATION.7` | `mdbook build docs/book`; `git diff --check` | `book and diff checks passed after selecting repeat-body generated blocking do with static parameters` |
| `2026-05-17` | `ISF-REPEAT-BODY-CHILD-ACTIVATION.8` | `perl -Iperl -c perl/FSM/Scheduler/ISF/LoweringIR.pm`; `perl -Iperl -c t/1215-isf-spawn-parameter-binding.t`; `perl -Iperl -c t/1304-isf-repeat-body-doc-truth-audit.t`; `prove -l t/1215-isf-spawn-parameter-binding.t t/1177-isf-do-child-done-pulse.t t/1184-isf-child-transaction-target-boundary.t t/1203-isf-await-sync-clause-boundary.t t/1204-isf-child-composition-clause-boundary.t t/1304-isf-repeat-body-doc-truth-audit.t t/1305-isf-book-feature-matrix-audit.t t/1307-isf-loop-body-doc-truth-audit.t`; `mdbook build docs/book`; `./bin/ci-regression isf --no-book`; `git diff --check` | `syntax, focused repeat/do/generated-composition/doc checks (Files=8, Tests=294), book build, full ISF gate (Files=227, Tests=1090), and diff check passed` |
| `2026-05-17` | `ISF-REPEAT-BODY-CHILD-ACTIVATION.9` | `mdbook build docs/book`; `git diff --check` | `book and diff checks passed after selecting repeat-body generated blocking do bindings` |
| `2026-05-17` | `ISF-REPEAT-BODY-CHILD-ACTIVATION.10` | `perl -Iperl -c perl/FSM/Scheduler/ISF/LoweringIR.pm`; `perl -Iperl -c t/1215-isf-spawn-parameter-binding.t`; `perl -Iperl -c t/1304-isf-repeat-body-doc-truth-audit.t`; `perl -Iperl -c t/1305-isf-book-feature-matrix-audit.t`; `perl -Iperl -c t/1307-isf-loop-body-doc-truth-audit.t`; `prove -l t/1215-isf-spawn-parameter-binding.t t/1177-isf-do-child-done-pulse.t t/1184-isf-child-transaction-target-boundary.t t/1203-isf-await-sync-clause-boundary.t t/1204-isf-child-composition-clause-boundary.t t/1241-isf-transaction-port-bindings.t t/1242-isf-port-binding-conflict-semantics.t t/1243-isf-port-binding-schedule-report.t t/1304-isf-repeat-body-doc-truth-audit.t t/1305-isf-book-feature-matrix-audit.t t/1307-isf-loop-body-doc-truth-audit.t`; `mdbook build docs/book`; `./bin/ci-regression isf --no-book`; `git diff --check` | `syntax, focused repeat/do/binding/generated-composition/doc checks (Files=11, Tests=305), book build, full ISF gate (Files=227, Tests=1089), and diff check passed` |
| `2026-05-17` | `ISF-REPEAT-BODY-CHILD-ACTIVATION.11` | `mdbook build docs/book`; `git diff --check` | `book and diff checks passed after selecting repeat-body generated blocking do same-domain metadata` |
| `2026-05-17` | `ISF-REPEAT-BODY-CHILD-ACTIVATION.12` | `perl -Iperl -c perl/FSM/Scheduler/ISF/LoweringIR.pm`; `perl -Iperl -c t/1215-isf-spawn-parameter-binding.t`; `perl -Iperl -c t/1247-isf-clock-domain-partition.t`; `perl -Iperl -c t/1304-isf-repeat-body-doc-truth-audit.t`; `perl -Iperl -c t/1305-isf-book-feature-matrix-audit.t`; `perl -Iperl -c t/1307-isf-loop-body-doc-truth-audit.t`; `prove -l t/1215-isf-spawn-parameter-binding.t t/1177-isf-do-child-done-pulse.t t/1184-isf-child-transaction-target-boundary.t t/1203-isf-await-sync-clause-boundary.t t/1204-isf-child-composition-clause-boundary.t t/1241-isf-transaction-port-bindings.t t/1242-isf-port-binding-conflict-semantics.t t/1243-isf-port-binding-schedule-report.t t/1247-isf-clock-domain-partition.t t/1304-isf-repeat-body-doc-truth-audit.t t/1305-isf-book-feature-matrix-audit.t t/1307-isf-loop-body-doc-truth-audit.t`; `mdbook build docs/book`; `./bin/ci-regression isf --no-book`; `git diff --check` | `syntax, focused repeat/do/domain/generated-composition/doc checks (Files=12, Tests=317), book build, full ISF gate (Files=227, Tests=1093), and diff check passed` |
| `2026-05-17` | `ISF-REPEAT-BODY-CHILD-ACTIVATION.13` | `mdbook build docs/book`; `git diff --check` | `book and diff checks passed after selecting repeat-body spawn-after-sample ordering` |
| `2026-05-17` | `ISF-REPEAT-BODY-CHILD-ACTIVATION.14` | `perl -Iperl -c perl/FSM/Scheduler/ISF/LoweringIR.pm`; `perl -Iperl -c t/1215-isf-spawn-parameter-binding.t`; `perl -Iperl -c t/1304-isf-repeat-body-doc-truth-audit.t`; `perl -Iperl -c t/1305-isf-book-feature-matrix-audit.t`; `perl -Iperl -c t/1307-isf-loop-body-doc-truth-audit.t`; `prove -l t/1215-isf-spawn-parameter-binding.t t/1177-isf-do-child-done-pulse.t t/1184-isf-child-transaction-target-boundary.t t/1203-isf-await-sync-clause-boundary.t t/1204-isf-child-composition-clause-boundary.t t/1241-isf-transaction-port-bindings.t t/1242-isf-port-binding-conflict-semantics.t t/1243-isf-port-binding-schedule-report.t t/1304-isf-repeat-body-doc-truth-audit.t t/1305-isf-book-feature-matrix-audit.t t/1307-isf-loop-body-doc-truth-audit.t`; `mdbook build docs/book`; `./bin/ci-regression isf --no-book`; `git diff --check` | `syntax, focused repeat/spawn/sample/doc checks (Files=11, Tests=307), book build, full ISF gate (Files=227, Tests=1092), and diff check passed` |
| `2026-05-17` | `ISF-REPEAT-BODY-CHILD-ACTIVATION.15` | `mdbook build docs/book`; `git diff --check` | `book and diff checks passed after selecting repeat-body generated-child do` |
| `2026-05-17` | `ISF-REPEAT-BODY-CHILD-ACTIVATION.16` | `perl -Iperl -c perl/FSM/Scheduler/ISF/LoweringIR.pm`; `perl -Iperl -c t/1215-isf-spawn-parameter-binding.t`; `perl -Iperl -c t/1304-isf-repeat-body-doc-truth-audit.t`; `perl -Iperl -c t/1305-isf-book-feature-matrix-audit.t`; `perl -Iperl -c t/1307-isf-loop-body-doc-truth-audit.t`; `prove -l t/1215-isf-spawn-parameter-binding.t t/1177-isf-do-child-done-pulse.t t/1184-isf-child-transaction-target-boundary.t t/1203-isf-await-sync-clause-boundary.t t/1204-isf-child-composition-clause-boundary.t t/1241-isf-transaction-port-bindings.t t/1242-isf-port-binding-conflict-semantics.t t/1243-isf-port-binding-schedule-report.t t/1304-isf-repeat-body-doc-truth-audit.t t/1305-isf-book-feature-matrix-audit.t t/1307-isf-loop-body-doc-truth-audit.t`; `mdbook build docs/book`; `./bin/ci-regression isf --no-book`; `git diff --check` | `syntax, focused repeat/do/generated-composition/doc checks (Files=11, Tests=312), book build, full ISF gate (Files=227, Tests=1097), and diff check passed` |
| `2026-05-17` | `ISF-REPEAT-BODY-CHILD-ACTIVATION.17` | `mdbook build docs/book`; `git diff --check` | `book and diff checks passed after selecting repeat-body sample-before/after-do timing` |
| `2026-05-17` | `ISF-REPEAT-BODY-CHILD-ACTIVATION.18` | `perl -Iperl -c perl/FSM/Scheduler/ISF/LoweringIR.pm`; `perl -Iperl -c t/1215-isf-spawn-parameter-binding.t`; `perl -Iperl -c t/1304-isf-repeat-body-doc-truth-audit.t`; `perl -Iperl -c t/1305-isf-book-feature-matrix-audit.t`; `perl -Iperl -c t/1307-isf-loop-body-doc-truth-audit.t`; `prove -l t/1215-isf-spawn-parameter-binding.t t/1177-isf-do-child-done-pulse.t t/1184-isf-child-transaction-target-boundary.t t/1203-isf-await-sync-clause-boundary.t t/1204-isf-child-composition-clause-boundary.t t/1241-isf-transaction-port-bindings.t t/1242-isf-port-binding-conflict-semantics.t t/1243-isf-port-binding-schedule-report.t t/1304-isf-repeat-body-doc-truth-audit.t t/1305-isf-book-feature-matrix-audit.t t/1307-isf-loop-body-doc-truth-audit.t`; `mdbook build docs/book`; `git diff --check`; `./bin/ci-regression isf --no-book`; `git diff --check` | `syntax, focused repeat/do/generated-composition/doc checks (Files=11, Tests=317), book build, full ISF gate (Files=227, Tests=1102), and diff checks passed` |
| `2026-05-17` | `ISF-REPEAT-BODY-CHILD-ACTIVATION.19` | `mdbook build docs/book`; `git diff --check` | `book and diff checks passed after selecting multi-pending repeat-body await_any with mandatory same-body await_all drain` |
| `2026-05-17` | `ISF-REPEAT-BODY-CHILD-ACTIVATION.20` | `perl -Iperl -c perl/FSM/Scheduler/ISF/LoweringIR.pm`; `perl -Iperl -c t/1215-isf-spawn-parameter-binding.t`; `perl -Iperl -c t/1304-isf-repeat-body-doc-truth-audit.t`; `perl -Iperl -c t/1305-isf-book-feature-matrix-audit.t`; `perl -Iperl -c t/1307-isf-loop-body-doc-truth-audit.t`; `prove -l t/1215-isf-spawn-parameter-binding.t`; `prove -l t/1215-isf-spawn-parameter-binding.t t/1177-isf-do-child-done-pulse.t t/1184-isf-child-transaction-target-boundary.t t/1203-isf-await-sync-clause-boundary.t t/1204-isf-child-composition-clause-boundary.t t/1241-isf-transaction-port-bindings.t t/1242-isf-port-binding-conflict-semantics.t t/1243-isf-port-binding-schedule-report.t t/1304-isf-repeat-body-doc-truth-audit.t t/1305-isf-book-feature-matrix-audit.t t/1307-isf-loop-body-doc-truth-audit.t`; `mdbook build docs/book`; `git diff --check`; `./bin/ci-regression isf --no-book`; `git diff --check` | `syntax, focused repeat/spawn/await-any/doc checks (single touched test Files=1, Tests=14; focused suite Files=11, Tests=327), book build, full ISF gate (Files=227, Tests=1112), and diff checks passed` |
| `2026-05-17` | `ISF-REPEAT-BODY-CHILD-ACTIVATION.21` | `mdbook build docs/book`; `git diff --check` | `book and diff checks passed after selecting top-level when-body nested repeat local do` |
| `2026-05-17` | `ISF-REPEAT-BODY-CHILD-ACTIVATION.22` | `perl -Iperl -c perl/FSM/Scheduler/ISF/LoweringIR.pm`; `perl -Iperl -c t/1215-isf-spawn-parameter-binding.t`; `perl -Iperl -c t/1177-isf-do-child-done-pulse.t`; `perl -Iperl -c t/1184-isf-child-transaction-target-boundary.t`; `perl -Iperl -c t/1203-isf-await-sync-clause-boundary.t`; `perl -Iperl -c t/1204-isf-child-composition-clause-boundary.t`; `perl -Iperl -c t/1241-isf-transaction-port-bindings.t`; `perl -Iperl -c t/1242-isf-port-binding-conflict-semantics.t`; `perl -Iperl -c t/1243-isf-port-binding-schedule-report.t`; `perl -Iperl -c t/1304-isf-repeat-body-doc-truth-audit.t`; `perl -Iperl -c t/1305-isf-book-feature-matrix-audit.t`; `perl -Iperl -c t/1307-isf-loop-body-doc-truth-audit.t`; `prove -l t/1215-isf-spawn-parameter-binding.t`; `prove -l t/1304-isf-repeat-body-doc-truth-audit.t t/1305-isf-book-feature-matrix-audit.t t/1307-isf-loop-body-doc-truth-audit.t`; `mdbook build docs/book`; `prove -l t/1215-isf-spawn-parameter-binding.t t/1177-isf-do-child-done-pulse.t t/1184-isf-child-transaction-target-boundary.t t/1203-isf-await-sync-clause-boundary.t t/1204-isf-child-composition-clause-boundary.t t/1241-isf-transaction-port-bindings.t t/1242-isf-port-binding-conflict-semantics.t t/1243-isf-port-binding-schedule-report.t t/1304-isf-repeat-body-doc-truth-audit.t t/1305-isf-book-feature-matrix-audit.t t/1307-isf-loop-body-doc-truth-audit.t`; `./bin/ci-regression isf --no-book`; `git diff --check` | `syntax, focused repeat/do/doc checks (single touched test Files=1, Tests=15; doc audits Files=3, Tests=296; focused suite Files=11, Tests=337), book build, full ISF gate (Files=227, Tests=1122), and diff checks passed` |
| `2026-05-17` | `ISF-REPEAT-BODY-CHILD-ACTIVATION.23` | `mdbook build docs/book`; `git diff --check` | `book and diff checks passed after selecting top-level switch-branch nested repeat local do` |
| `2026-05-17` | `ISF-REPEAT-BODY-CHILD-ACTIVATION.24` | `perl -Iperl -c perl/FSM/Scheduler/ISF/LoweringIR.pm`; `perl -Iperl -c t/1215-isf-spawn-parameter-binding.t`; `perl -Iperl -c t/1103-isf-switch-branch-exits.t`; `perl -Iperl -c t/1177-isf-do-child-done-pulse.t`; `perl -Iperl -c t/1184-isf-child-transaction-target-boundary.t`; `perl -Iperl -c t/1203-isf-await-sync-clause-boundary.t`; `perl -Iperl -c t/1204-isf-child-composition-clause-boundary.t`; `perl -Iperl -c t/1241-isf-transaction-port-bindings.t`; `perl -Iperl -c t/1242-isf-port-binding-conflict-semantics.t`; `perl -Iperl -c t/1243-isf-port-binding-schedule-report.t`; `perl -Iperl -c t/1304-isf-repeat-body-doc-truth-audit.t`; `perl -Iperl -c t/1305-isf-book-feature-matrix-audit.t`; `perl -Iperl -c t/1307-isf-loop-body-doc-truth-audit.t`; `prove -l t/1215-isf-spawn-parameter-binding.t`; `prove -l t/1215-isf-spawn-parameter-binding.t t/1304-isf-repeat-body-doc-truth-audit.t t/1305-isf-book-feature-matrix-audit.t t/1307-isf-loop-body-doc-truth-audit.t`; `mdbook build docs/book`; `prove -l t/1103-isf-switch-branch-exits.t t/1215-isf-spawn-parameter-binding.t t/1177-isf-do-child-done-pulse.t t/1184-isf-child-transaction-target-boundary.t t/1203-isf-await-sync-clause-boundary.t t/1204-isf-child-composition-clause-boundary.t t/1241-isf-transaction-port-bindings.t t/1242-isf-port-binding-conflict-semantics.t t/1243-isf-port-binding-schedule-report.t t/1304-isf-repeat-body-doc-truth-audit.t t/1305-isf-book-feature-matrix-audit.t t/1307-isf-loop-body-doc-truth-audit.t`; `./bin/ci-regression isf --no-book`; `git diff --check` | `syntax, focused switch/repeat/do/doc checks (single touched test Files=1, Tests=16; repeat/doc suite Files=4, Tests=321; focused suite Files=12, Tests=352), book build, full ISF gate (Files=227, Tests=1132), and diff checks passed` |
| `2026-05-17` | `ISF-REPEAT-BODY-CHILD-ACTIVATION.25` | `mdbook build docs/book`; `git diff --check` | `book and diff checks passed after selecting top-level when-body nested repeat generated-child do` |
| `2026-05-17` | `ISF-REPEAT-BODY-CHILD-ACTIVATION.26` | `perl -Iperl -c perl/FSM/Scheduler/ISF/LoweringIR.pm`; `perl -Iperl -c t/1215-isf-spawn-parameter-binding.t`; `perl -Iperl -c t/1103-isf-switch-branch-exits.t`; `perl -Iperl -c t/1177-isf-do-child-done-pulse.t`; `perl -Iperl -c t/1184-isf-child-transaction-target-boundary.t`; `perl -Iperl -c t/1203-isf-await-sync-clause-boundary.t`; `perl -Iperl -c t/1204-isf-child-composition-clause-boundary.t`; `perl -Iperl -c t/1241-isf-transaction-port-bindings.t`; `perl -Iperl -c t/1242-isf-port-binding-conflict-semantics.t`; `perl -Iperl -c t/1243-isf-port-binding-schedule-report.t`; `perl -Iperl -c t/1304-isf-repeat-body-doc-truth-audit.t`; `perl -Iperl -c t/1305-isf-book-feature-matrix-audit.t`; `perl -Iperl -c t/1307-isf-loop-body-doc-truth-audit.t`; `prove -l t/1215-isf-spawn-parameter-binding.t`; `prove -l t/1215-isf-spawn-parameter-binding.t t/1304-isf-repeat-body-doc-truth-audit.t t/1305-isf-book-feature-matrix-audit.t t/1307-isf-loop-body-doc-truth-audit.t`; `mdbook build docs/book`; `prove -l t/1103-isf-switch-branch-exits.t t/1215-isf-spawn-parameter-binding.t t/1177-isf-do-child-done-pulse.t t/1184-isf-child-transaction-target-boundary.t t/1203-isf-await-sync-clause-boundary.t t/1204-isf-child-composition-clause-boundary.t t/1241-isf-transaction-port-bindings.t t/1242-isf-port-binding-conflict-semantics.t t/1243-isf-port-binding-schedule-report.t t/1304-isf-repeat-body-doc-truth-audit.t t/1305-isf-book-feature-matrix-audit.t t/1307-isf-loop-body-doc-truth-audit.t`; `./bin/ci-regression isf --no-book`; `git diff --check` | `syntax, focused when/repeat/do/generated-composition/doc checks (single touched test Files=1, Tests=17; repeat/doc suite Files=4, Tests=322; focused suite Files=12, Tests=353), book build, full ISF gate (Files=227, Tests=1133), and diff checks passed` |
| `2026-05-17` | `ISF-REPEAT-BODY-CHILD-ACTIVATION.27` | `mdbook build docs/book`; `git diff --check` | `book and diff checks passed after selecting top-level switch-branch nested repeat generated-child do` |
| `2026-05-17` | `ISF-REPEAT-BODY-CHILD-ACTIVATION.28` | `perl -Iperl -c perl/FSM/Scheduler/ISF/LoweringIR.pm`; `perl -Iperl -c t/1215-isf-spawn-parameter-binding.t`; `perl -Iperl -c t/1103-isf-switch-branch-exits.t`; `perl -Iperl -c t/1177-isf-do-child-done-pulse.t`; `perl -Iperl -c t/1184-isf-child-transaction-target-boundary.t`; `perl -Iperl -c t/1203-isf-await-sync-clause-boundary.t`; `perl -Iperl -c t/1204-isf-child-composition-clause-boundary.t`; `perl -Iperl -c t/1241-isf-transaction-port-bindings.t`; `perl -Iperl -c t/1242-isf-port-binding-conflict-semantics.t`; `perl -Iperl -c t/1243-isf-port-binding-schedule-report.t`; `perl -Iperl -c t/1304-isf-repeat-body-doc-truth-audit.t`; `perl -Iperl -c t/1305-isf-book-feature-matrix-audit.t`; `perl -Iperl -c t/1307-isf-loop-body-doc-truth-audit.t`; `prove -l t/1215-isf-spawn-parameter-binding.t`; `prove -l t/1215-isf-spawn-parameter-binding.t t/1304-isf-repeat-body-doc-truth-audit.t t/1305-isf-book-feature-matrix-audit.t t/1307-isf-loop-body-doc-truth-audit.t`; `mdbook build docs/book`; `prove -l t/1103-isf-switch-branch-exits.t t/1215-isf-spawn-parameter-binding.t t/1177-isf-do-child-done-pulse.t t/1184-isf-child-transaction-target-boundary.t t/1203-isf-await-sync-clause-boundary.t t/1204-isf-child-composition-clause-boundary.t t/1241-isf-transaction-port-bindings.t t/1242-isf-port-binding-conflict-semantics.t t/1243-isf-port-binding-schedule-report.t t/1304-isf-repeat-body-doc-truth-audit.t t/1305-isf-book-feature-matrix-audit.t t/1307-isf-loop-body-doc-truth-audit.t`; `./bin/ci-regression isf --no-book`; `git diff --check` | `syntax, focused switch/repeat/do/generated-composition/doc checks (single touched test Files=1, Tests=18; repeat/doc suite Files=4, Tests=323; focused suite Files=12, Tests=354), book build, full ISF gate (Files=227, Tests=1134), and diff checks passed` |
| `2026-05-17` | `ISF-REPEAT-BODY-CHILD-ACTIVATION.29` | `mdbook build docs/book`; `git diff --check` | `book and diff checks passed after selecting top-level when-body nested repeat generated do static params` |
| `2026-05-17` | `ISF-REPEAT-BODY-CHILD-ACTIVATION.30` | `perl -Iperl -c perl/FSM/Scheduler/ISF/LoweringIR.pm`; `perl -Iperl -c t/1215-isf-spawn-parameter-binding.t`; `perl -Iperl -c t/1103-isf-switch-branch-exits.t`; `perl -Iperl -c t/1177-isf-do-child-done-pulse.t`; `perl -Iperl -c t/1184-isf-child-transaction-target-boundary.t`; `perl -Iperl -c t/1203-isf-await-sync-clause-boundary.t`; `perl -Iperl -c t/1204-isf-child-composition-clause-boundary.t`; `perl -Iperl -c t/1241-isf-transaction-port-bindings.t`; `perl -Iperl -c t/1242-isf-port-binding-conflict-semantics.t`; `perl -Iperl -c t/1243-isf-port-binding-schedule-report.t`; `perl -Iperl -c t/1304-isf-repeat-body-doc-truth-audit.t`; `perl -Iperl -c t/1305-isf-book-feature-matrix-audit.t`; `perl -Iperl -c t/1307-isf-loop-body-doc-truth-audit.t`; `prove -l t/1215-isf-spawn-parameter-binding.t`; `prove -l t/1215-isf-spawn-parameter-binding.t t/1304-isf-repeat-body-doc-truth-audit.t t/1305-isf-book-feature-matrix-audit.t t/1307-isf-loop-body-doc-truth-audit.t`; `prove -l t/1103-isf-switch-branch-exits.t t/1215-isf-spawn-parameter-binding.t t/1177-isf-do-child-done-pulse.t t/1184-isf-child-transaction-target-boundary.t t/1203-isf-await-sync-clause-boundary.t t/1204-isf-child-composition-clause-boundary.t t/1241-isf-transaction-port-bindings.t t/1242-isf-port-binding-conflict-semantics.t t/1243-isf-port-binding-schedule-report.t t/1304-isf-repeat-body-doc-truth-audit.t t/1305-isf-book-feature-matrix-audit.t t/1307-isf-loop-body-doc-truth-audit.t`; `mdbook build docs/book`; `./bin/ci-regression isf --no-book`; `git diff --check` | `syntax, focused when/repeat/do/generated-composition/doc checks (single touched test Files=1, Tests=19; repeat/doc suite Files=4, Tests=324; focused suite Files=12, Tests=355), book build, full ISF gate (Files=227, Tests=1135), and diff checks passed` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `ISF-REPEAT-BODY-CHILD-ACTIVATION` | `ISF-REPEAT-BODY-CHILD-ACTIVATION: track repeat activation backlog` | `e942bfc6; proposed tracking tree created` |
| `ISF-REPEAT-BODY-CHILD-ACTIVATION.1` | `ISF-REPEAT-BODY-CHILD-ACTIVATION.1: select repeat spawn bindings` | `47715e55; selected repeat-body spawn binding subset` |
| `ISF-REPEAT-BODY-CHILD-ACTIVATION.2` | `ISF-REPEAT-BODY-CHILD-ACTIVATION.2: implement repeat spawn bindings` | `0bc68c85; repeat-body spawn binding handoffs shipped` |
| `ISF-REPEAT-BODY-CHILD-ACTIVATION.3` | `ISF-REPEAT-BODY-CHILD-ACTIVATION.3: implement repeat spawn domains` | `027c3d1b; repeat-body spawn same-domain metadata shipped` |
| `ISF-REPEAT-BODY-CHILD-ACTIVATION.4` | `ISF-REPEAT-BODY-CHILD-ACTIVATION.4: implement repeat await_any` | `2d349f08; single-pending repeat-body await_any shipped` |
| `ISF-REPEAT-BODY-CHILD-ACTIVATION.5` | `ISF-REPEAT-BODY-CHILD-ACTIVATION.5: implement repeat local do` | `repeat-body local blocking do shipped` |
| `ISF-REPEAT-BODY-CHILD-ACTIVATION.6` | `ISF-REPEAT-BODY-CHILD-ACTIVATION.6: implement repeat spawn samples` | `repeat-body sample-after-spawn timing shipped` |
| `ISF-REPEAT-BODY-CHILD-ACTIVATION.7` | `ISF-REPEAT-BODY-CHILD-ACTIVATION.7: select repeat generated do` | `selected repeat-body generated blocking do with static parameters` |
| `ISF-REPEAT-BODY-CHILD-ACTIVATION.8` | `ISF-REPEAT-BODY-CHILD-ACTIVATION.8: implement repeat generated do params` | `repeat-body generated blocking do static parameters shipped` |
| `ISF-REPEAT-BODY-CHILD-ACTIVATION.9` | `ISF-REPEAT-BODY-CHILD-ACTIVATION.9: select repeat generated do bindings` | `selected repeat-body generated blocking do bindings` |
| `ISF-REPEAT-BODY-CHILD-ACTIVATION.10` | `ISF-REPEAT-BODY-CHILD-ACTIVATION.10: implement repeat generated do bindings` | `repeat-body generated blocking do binding handoffs shipped` |
| `ISF-REPEAT-BODY-CHILD-ACTIVATION.11` | `ISF-REPEAT-BODY-CHILD-ACTIVATION.11: select repeat generated do domains` | `selected repeat-body generated blocking do same-domain metadata` |
| `ISF-REPEAT-BODY-CHILD-ACTIVATION.12` | `ISF-REPEAT-BODY-CHILD-ACTIVATION.12: implement repeat generated do domains` | `repeat-body generated blocking do same-domain metadata shipped` |
| `ISF-REPEAT-BODY-CHILD-ACTIVATION.13` | `ISF-REPEAT-BODY-CHILD-ACTIVATION.13: select repeat spawn after sample` | `selected repeat-body spawn-after-sample ordering` |
| `ISF-REPEAT-BODY-CHILD-ACTIVATION.14` | `ISF-REPEAT-BODY-CHILD-ACTIVATION.14: implement repeat spawn after sample` | `repeat-body spawn-after-sample ordering shipped` |
| `ISF-REPEAT-BODY-CHILD-ACTIVATION.15` | `ISF-REPEAT-BODY-CHILD-ACTIVATION.15: select repeat generated-child do` | `selected repeat-body plain do targeting already generated children` |
| `ISF-REPEAT-BODY-CHILD-ACTIVATION.16` | `ISF-REPEAT-BODY-CHILD-ACTIVATION.16: implement repeat generated-child do` | `repeat-body generated-child do shipped` |
| `ISF-REPEAT-BODY-CHILD-ACTIVATION.17` | `ISF-REPEAT-BODY-CHILD-ACTIVATION.17: select repeat do samples` | `selected repeat-body sample-before/after-do timing` |
| `ISF-REPEAT-BODY-CHILD-ACTIVATION.18` | `ISF-REPEAT-BODY-CHILD-ACTIVATION.18: implement repeat do samples` | `repeat-body sample-before/after-do timing shipped` |
| `ISF-REPEAT-BODY-CHILD-ACTIVATION.19` | `ISF-REPEAT-BODY-CHILD-ACTIVATION.19: select repeat await_any drain` | `selected multi-pending repeat-body await_any with mandatory same-body await_all drain` |
| `ISF-REPEAT-BODY-CHILD-ACTIVATION.20` | `ISF-REPEAT-BODY-CHILD-ACTIVATION.20: implement repeat await_any drain` | `multi-pending repeat-body await_any drain shipped` |
| `ISF-REPEAT-BODY-CHILD-ACTIVATION.21` | `ISF-REPEAT-BODY-CHILD-ACTIVATION.21: select when repeat local do` | `selected when-contained repeat local do` |
| `ISF-REPEAT-BODY-CHILD-ACTIVATION.22` | `ISF-REPEAT-BODY-CHILD-ACTIVATION.22: implement when repeat local do` | `when-contained repeat local do shipped` |
| `ISF-REPEAT-BODY-CHILD-ACTIVATION.23` | `ISF-REPEAT-BODY-CHILD-ACTIVATION.23: select switch repeat local do` | `selected switch-contained repeat local do` |
| `ISF-REPEAT-BODY-CHILD-ACTIVATION.24` | `ISF-REPEAT-BODY-CHILD-ACTIVATION.24: implement switch repeat local do` | `switch-contained repeat local do shipped` |
| `ISF-REPEAT-BODY-CHILD-ACTIVATION.25` | `ISF-REPEAT-BODY-CHILD-ACTIVATION.25: select when repeat generated-child do` | `selected when-contained repeat generated-child do` |
| `ISF-REPEAT-BODY-CHILD-ACTIVATION.26` | `ISF-REPEAT-BODY-CHILD-ACTIVATION.26: implement when repeat generated-child do` | `when-contained repeat generated-child do shipped` |
| `ISF-REPEAT-BODY-CHILD-ACTIVATION.27` | `ISF-REPEAT-BODY-CHILD-ACTIVATION.27: select switch repeat generated-child do` | `selected switch-contained repeat generated-child do` |
| `ISF-REPEAT-BODY-CHILD-ACTIVATION.28` | `ISF-REPEAT-BODY-CHILD-ACTIVATION.28: implement switch repeat generated-child do` | `switch-contained repeat generated-child do shipped` |
| `ISF-REPEAT-BODY-CHILD-ACTIVATION.29` | `ISF-REPEAT-BODY-CHILD-ACTIVATION.29: select when repeat generated do params` | `selected when-contained repeat generated do static params` |
| `ISF-REPEAT-BODY-CHILD-ACTIVATION.30` | `ISF-REPEAT-BODY-CHILD-ACTIVATION.30: implement when repeat generated do params` | `when-contained repeat generated do static params shipped` |

## Changelog

- `2026-05-17`: Created proposed task tree so the remaining repeat-body child
  activation backlog has explicit task-tree ownership before future code work.
- `2026-05-17`: Strengthened the surrounding workflow docs so the task-tree
  preflight is mandatory for all future implementation work, not only this ISF
  backlog.
- `2026-05-17`: Activated the tree and selected repeat-body spawn
  `(bind ...)` as the next bounded implementation leaf.
- `2026-05-17`: Shipped repeat-body spawn `(bind ...)` on the existing
  top-level repeat plus same-body `await_all` subset.
- `2026-05-17`: Shipped repeat-body spawn `(domain NAME)` as declared
  same-domain ownership metadata on the same static-instance subset.
- `2026-05-17`: Shipped repeat-body `(await_any done)` for the exactly-one
  pending spawn subset while keeping broader outstanding-child semantics
  deferred.
- `2026-05-17`: Shipped repeat-body local `(do child)` for top-level repeat
  bodies while keeping generated/parameterized/bound/domain-qualified and
  sample-before/after-do forms deferred.
- `2026-05-17`: Shipped repeat-body sample-after-spawn timing before
  same-body `await_all` or single-pending `await_any`, while keeping
  spawn-after-sample ordering and broader outstanding-child forms deferred.
- `2026-05-17`: Selected repeat-body generated blocking `do` with static
  parameter overrides as the next bounded implementation subset.
- `2026-05-17`: Shipped repeat-body generated blocking `do` with static
  parameter overrides, while keeping generated-do binding handoffs, domain
  metadata, and broader outstanding-child forms deferred at that leaf.
- `2026-05-17`: Selected repeat-body generated blocking `do` bindings as the
  next bounded implementation subset.
- `2026-05-17`: Shipped repeat-body generated blocking `do` bindings for the
  top-level static-parameter subset, with generated-top handoff ports,
  report-visible do-site binding provenance, and done-gated repeat re-entry.
- `2026-05-17`: Selected repeat-body generated blocking `do` same-domain
  metadata as the next bounded implementation subset.
- `2026-05-17`: Shipped repeat-body generated blocking `do` same-domain
  metadata for the top-level static-parameter subset, with generated-child
  instance metadata and clock-domain child-instance summaries.
- `2026-05-17`: Selected repeat-body spawn-after-sample ordering as the next
  bounded implementation subset.
- `2026-05-17`: Shipped repeat-body spawn-after-sample ordering before
  same-body sync.
- `2026-05-17`: Selected repeat-body plain `(do child)` targeting an already
  generated child as the next bounded implementation subset.
- `2026-05-17`: Shipped repeat-body plain `(do child)` targeting already
  generated children through deterministic generated do instances.
- `2026-05-17`: Selected repeat-body sample-before/after-do timing as the next
  bounded implementation subset.
- `2026-05-17`: Shipped repeat-body sample-before/after-do timing around
  shipped local and generated repeat-body `do` states.
- `2026-05-17`: Selected multi-pending repeat-body `await_any` with a
  mandatory later same-body `await_all` drain as the next bounded
  implementation subset.
- `2026-05-17`: Shipped multi-pending repeat-body `await_any` with mandatory
  later same-body `await_all` drain.
- `2026-05-17`: Selected top-level when-body nested repeat local `do` as the
  next bounded nested-placement subset.
- `2026-05-17`: Shipped top-level when-body nested repeat local `do`, while
  keeping generated targets, activation subclauses, switch/loop/deeper branch
  nesting, cross-domain activation, and broader outstanding-child semantics
  fail-closed.
- `2026-05-17`: Selected top-level switch-branch nested repeat local `do` as
  the next bounded nested-placement subset.
- `2026-05-17`: Shipped top-level switch-branch nested repeat local `do`,
  while keeping generated targets, activation subclauses, deeper branch/loop
  nesting, cross-domain activation, and broader outstanding-child semantics
  fail-closed.
- `2026-05-17`: Selected top-level when-body nested repeat generated-child
  `do` as the next bounded nested generated-child subset.
- `2026-05-17`: Shipped top-level when-body nested repeat generated-child
  `do`, while keeping activation subclauses, spawn nesting,
  switch-contained generated-child `do`, deeper branch/loop nesting,
  cross-domain activation, and broader outstanding-child semantics
  fail-closed.
- `2026-05-17`: Selected top-level switch-branch nested repeat generated-child
  `do` as the next bounded nested generated-child subset.
- `2026-05-17`: Shipped top-level switch-branch nested repeat generated-child
  `do`, while keeping activation subclauses, spawn nesting, deeper
  branch/loop nesting, cross-domain activation, and broader outstanding-child
  semantics fail-closed.
- `2026-05-17`: Selected top-level when-body nested repeat generated `do`
  with static parameter overrides as the next bounded nested generated-do
  subset.
- `2026-05-17`: Shipped top-level when-body nested repeat generated `do`
  with static parameter overrides, while keeping bind/domain metadata, spawn
  nesting, switch-contained parameterized generated nested `do`, deeper
  branch/loop nesting, cross-domain activation, and broader outstanding-child
  semantics fail-closed.
