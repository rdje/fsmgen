# ISF-REPEAT-BODY-CHILD-ACTIVATION: Repeat-Body Child Activation Widening

## Metadata

- Tree ID: `ISF-REPEAT-BODY-CHILD-ACTIVATION`
- Status: `active`
- Roadmap lane: `R14`
- Created: `2026-05-17`
- Last updated: `2026-05-18`
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
  Children: `ISF-REPEAT-BODY-CHILD-ACTIVATION.1`, `ISF-REPEAT-BODY-CHILD-ACTIVATION.2`, `ISF-REPEAT-BODY-CHILD-ACTIVATION.3`, `ISF-REPEAT-BODY-CHILD-ACTIVATION.4`, `ISF-REPEAT-BODY-CHILD-ACTIVATION.5`, `ISF-REPEAT-BODY-CHILD-ACTIVATION.6`, `ISF-REPEAT-BODY-CHILD-ACTIVATION.7`, `ISF-REPEAT-BODY-CHILD-ACTIVATION.8`, `ISF-REPEAT-BODY-CHILD-ACTIVATION.9`, `ISF-REPEAT-BODY-CHILD-ACTIVATION.10`, `ISF-REPEAT-BODY-CHILD-ACTIVATION.11`, `ISF-REPEAT-BODY-CHILD-ACTIVATION.12`, `ISF-REPEAT-BODY-CHILD-ACTIVATION.13`, `ISF-REPEAT-BODY-CHILD-ACTIVATION.14`, `ISF-REPEAT-BODY-CHILD-ACTIVATION.15`, `ISF-REPEAT-BODY-CHILD-ACTIVATION.16`, `ISF-REPEAT-BODY-CHILD-ACTIVATION.17`, `ISF-REPEAT-BODY-CHILD-ACTIVATION.18`, `ISF-REPEAT-BODY-CHILD-ACTIVATION.19`, `ISF-REPEAT-BODY-CHILD-ACTIVATION.20`, `ISF-REPEAT-BODY-CHILD-ACTIVATION.21`, `ISF-REPEAT-BODY-CHILD-ACTIVATION.22`, `ISF-REPEAT-BODY-CHILD-ACTIVATION.23`, `ISF-REPEAT-BODY-CHILD-ACTIVATION.24`, `ISF-REPEAT-BODY-CHILD-ACTIVATION.25`, `ISF-REPEAT-BODY-CHILD-ACTIVATION.26`, `ISF-REPEAT-BODY-CHILD-ACTIVATION.27`, `ISF-REPEAT-BODY-CHILD-ACTIVATION.28`, `ISF-REPEAT-BODY-CHILD-ACTIVATION.29`, `ISF-REPEAT-BODY-CHILD-ACTIVATION.30`, `ISF-REPEAT-BODY-CHILD-ACTIVATION.31`, `ISF-REPEAT-BODY-CHILD-ACTIVATION.32`, `ISF-REPEAT-BODY-CHILD-ACTIVATION.33`, `ISF-REPEAT-BODY-CHILD-ACTIVATION.34`, `ISF-REPEAT-BODY-CHILD-ACTIVATION.35`, `ISF-REPEAT-BODY-CHILD-ACTIVATION.36`, `ISF-REPEAT-BODY-CHILD-ACTIVATION.37`, `ISF-REPEAT-BODY-CHILD-ACTIVATION.38`, `ISF-REPEAT-BODY-CHILD-ACTIVATION.39`, `ISF-REPEAT-BODY-CHILD-ACTIVATION.40`, `ISF-REPEAT-BODY-CHILD-ACTIVATION.41`, `ISF-REPEAT-BODY-CHILD-ACTIVATION.42`, `ISF-REPEAT-BODY-CHILD-ACTIVATION.43`, `ISF-REPEAT-BODY-CHILD-ACTIVATION.44`, `ISF-REPEAT-BODY-CHILD-ACTIVATION.45`, `ISF-REPEAT-BODY-CHILD-ACTIVATION.46`, `ISF-REPEAT-BODY-CHILD-ACTIVATION.47`, `ISF-REPEAT-BODY-CHILD-ACTIVATION.48`, `ISF-REPEAT-BODY-CHILD-ACTIVATION.49`, `ISF-REPEAT-BODY-CHILD-ACTIVATION.50`, `ISF-REPEAT-BODY-CHILD-ACTIVATION.51`, `ISF-REPEAT-BODY-CHILD-ACTIVATION.52`, `ISF-REPEAT-BODY-CHILD-ACTIVATION.53`, `ISF-REPEAT-BODY-CHILD-ACTIVATION.54`, `ISF-REPEAT-BODY-CHILD-ACTIVATION.55`, `ISF-REPEAT-BODY-CHILD-ACTIVATION.56`, `ISF-REPEAT-BODY-CHILD-ACTIVATION.57`, `ISF-REPEAT-BODY-CHILD-ACTIVATION.58`, `ISF-REPEAT-BODY-CHILD-ACTIVATION.59`, `ISF-REPEAT-BODY-CHILD-ACTIVATION.60`, `ISF-REPEAT-BODY-CHILD-ACTIVATION.61`, `ISF-REPEAT-BODY-CHILD-ACTIVATION.62`, `ISF-REPEAT-BODY-CHILD-ACTIVATION.63`, `ISF-REPEAT-BODY-CHILD-ACTIVATION.64`, `ISF-REPEAT-BODY-CHILD-ACTIVATION.65`, `ISF-REPEAT-BODY-CHILD-ACTIVATION.66`, `ISF-REPEAT-BODY-CHILD-ACTIVATION.67`, `ISF-REPEAT-BODY-CHILD-ACTIVATION.68`, `ISF-REPEAT-BODY-CHILD-ACTIVATION.69`, `ISF-REPEAT-BODY-CHILD-ACTIVATION.70`, `ISF-REPEAT-BODY-CHILD-ACTIVATION.71`, `ISF-REPEAT-BODY-CHILD-ACTIVATION.72`, `ISF-REPEAT-BODY-CHILD-ACTIVATION.73`, `ISF-REPEAT-BODY-CHILD-ACTIVATION.74`, `ISF-REPEAT-BODY-CHILD-ACTIVATION.75`, `ISF-REPEAT-BODY-CHILD-ACTIVATION.76`, `ISF-REPEAT-BODY-CHILD-ACTIVATION.77`

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
  Status: `done`
  Goal: `Select the next repeat-body child activation subset.`
  Acceptance: `Task tree, roadmap, and book backlog select top-level switch-branch nested repeat generated blocking '(do child (params ...))' as the next bounded implementation subset; the selected contract mirrors the shipped when-contained static-parameter generated nested do subset, emits one deterministic generated do instance for the lexical nested repeat-body do site, applies static parameter overrides once in the generated top, waits for that instance's fresh done handoff before the switch-branch nested repeat check, and keeps bind/domain metadata, spawn nesting, deeper branch/loop nesting, cross-domain activation, and broader outstanding-child semantics deferred.`
  Verification: `mdbook build docs/book; git diff --check`
  Commit: `ISF-REPEAT-BODY-CHILD-ACTIVATION.31: select switch repeat generated do params`

- ID: `ISF-REPEAT-BODY-CHILD-ACTIVATION.32`
  Status: `done`
  Goal: `Ship switch-branch nested repeat generated do with static parameter overrides if selected.`
  Acceptance: `Top-level switch branches accept nested '(repeat COUNT ... (do child (params ...)) ...)' with static parameter overrides; lowering emits one deterministic generated do instance for the lexical nested repeat-body do site, applies overrides once in the generated top, waits for that instance's fresh done handoff before the nested repeat check, preserves samples around the nested do through existing source-order sample states, and keeps bind/domain metadata, spawn nesting, deeper branch/loop nesting, cross-domain activation, and broader outstanding-child semantics fail-closed.`
  Verification: `syntax checks; touched test Files=1, Tests=20; repeat/doc suite Files=4, Tests=325; focused suite Files=12, Tests=356; mdbook build docs/book; ./bin/ci-regression isf --no-book Files=227, Tests=1136; git diff --check`
  Commit: `ISF-REPEAT-BODY-CHILD-ACTIVATION.32: implement switch repeat generated do params`

- ID: `ISF-REPEAT-BODY-CHILD-ACTIVATION.33`
  Status: `done`
  Goal: `Select the next repeat-body child activation subset.`
  Acceptance: `Task tree, roadmap, and book backlog select top-level when-body nested repeat generated blocking '(do child (params ...) (bind ...))' as the next bounded implementation subset; the selected contract reuses the static generated do instance from the when-contained parameter subset, adds generated-top input/output binding handoffs once for the lexical nested do site, waits for that instance's fresh done handoff before the when-body nested repeat check, and keeps domain metadata, switch-contained bound nested do, spawn nesting, deeper branch/loop nesting, cross-domain activation, and broader outstanding-child semantics deferred.`
  Verification: `mdbook build docs/book; git diff --check`
  Commit: `ISF-REPEAT-BODY-CHILD-ACTIVATION.33: select when repeat generated do bindings`

- ID: `ISF-REPEAT-BODY-CHILD-ACTIVATION.34`
  Status: `done`
  Goal: `Ship when-body nested repeat generated do with static parameter overrides and port bindings if selected.`
  Acceptance: `Top-level when bodies accept nested '(repeat COUNT ... (do child (params ...) (bind ...)) ...)' with static parameter overrides and input/output port bindings; lowering emits one deterministic generated do instance for the lexical nested repeat-body do site, applies overrides once in the generated top, wires binding handoff ports once for that instance, waits for the instance's fresh done handoff before the nested repeat check, preserves samples around the nested do through existing source-order sample states, and keeps domain metadata, switch-contained bound nested do, spawn nesting, deeper branch/loop nesting, cross-domain activation, and broader outstanding-child semantics fail-closed.`
  Verification: `syntax checks; touched test Files=1, Tests=21; repeat/doc suite Files=4, Tests=326; focused suite Files=12, Tests=357; mdbook build docs/book; ./bin/ci-regression isf --no-book Files=227, Tests=1137; git diff --check`
  Commit: `ISF-REPEAT-BODY-CHILD-ACTIVATION.34: implement when repeat generated do bindings`

- ID: `ISF-REPEAT-BODY-CHILD-ACTIVATION.35`
  Status: `done`
  Goal: `Select the next repeat-body child activation subset.`
  Acceptance: `Task tree, roadmap, and book backlog select top-level switch-branch nested repeat generated blocking '(do child (params ...) (bind ...))' as the next bounded implementation subset; the selected contract mirrors the shipped when-contained binding subset, reuses the deterministic generated do instance from the switch-contained parameter subset, adds generated-top input/output binding handoffs once for the lexical nested do site, waits for that instance's fresh done handoff before the switch-branch nested repeat check, and keeps domain metadata, spawn nesting, deeper branch/loop nesting, cross-domain activation, and broader outstanding-child semantics deferred.`
  Verification: `mdbook build docs/book; git diff --check`
  Commit: `ISF-REPEAT-BODY-CHILD-ACTIVATION.35: select switch repeat generated do bindings`

- ID: `ISF-REPEAT-BODY-CHILD-ACTIVATION.36`
  Status: `done`
  Goal: `Ship switch-branch nested repeat generated do with static parameter overrides and port bindings if selected.`
  Acceptance: `Top-level switch branches accept nested '(repeat COUNT ... (do child (params ...) (bind ...)) ...)' with static parameter overrides and input/output port bindings; lowering emits one deterministic generated do instance for the lexical nested repeat-body do site, applies overrides once in the generated top, wires binding handoff ports once for that instance, waits for the instance's fresh done handoff before the nested repeat check, preserves samples around the nested do through existing source-order sample states, and keeps domain metadata, spawn nesting, deeper branch/loop nesting, cross-domain activation, and broader outstanding-child semantics fail-closed.`
  Verification: `syntax checks; touched test Files=1, Tests=22; repeat/doc suite Files=4, Tests=327; focused suite Files=12, Tests=358; mdbook build docs/book; ./bin/ci-regression isf --no-book Files=227, Tests=1138; git diff --check`
  Commit: `ISF-REPEAT-BODY-CHILD-ACTIVATION.36: implement switch repeat generated do bindings`

- ID: `ISF-REPEAT-BODY-CHILD-ACTIVATION.37`
  Status: `done`
  Goal: `Select the next repeat-body child activation subset.`
  Acceptance: `Task tree, roadmap, and book backlog select top-level when-body nested repeat generated blocking '(do child (params ...) [(bind ...)] (domain NAME))' as the next bounded implementation subset; the selected contract is declared same-domain ownership metadata only on the static generated do instance, preserves generated-composition and schedule-report clock-domain metadata for that lexical nested do site, and keeps switch-contained domain metadata, spawn nesting, cross-domain activation, deeper branch/loop nesting, and broader outstanding-child semantics deferred.`
  Verification: `mdbook build docs/book; git diff --check`
  Commit: `ISF-REPEAT-BODY-CHILD-ACTIVATION.37: select when repeat generated do domains`

- ID: `ISF-REPEAT-BODY-CHILD-ACTIVATION.38`
  Status: `done`
  Goal: `Ship when-body nested repeat generated do same-domain metadata if selected.`
  Acceptance: `Top-level when bodies accept nested '(repeat COUNT ... (do child (params ...) [(bind ...)] (domain NAME)) ...)' when NAME is the declared same-domain owner for the parent transaction and generated child; generated composition metadata and schedule-report clock-domain summaries preserve that ownership for the lexical nested repeat-do instance, while undeclared domains, cross-domain activation, switch-contained domain metadata, spawn nesting, deeper branch/loop nesting, and broader outstanding-child semantics remain fail-closed.`
  Verification: `syntax checks; touched test Files=2, Tests=32; repeat/domain/doc suite Files=5, Tests=337; focused suite Files=13, Tests=368; mdbook build docs/book; ./bin/ci-regression isf --no-book Files=227, Tests=1139; git diff --check`
  Commit: `ISF-REPEAT-BODY-CHILD-ACTIVATION.38: implement when repeat generated do domains`

- ID: `ISF-REPEAT-BODY-CHILD-ACTIVATION.39`
  Status: `done`
  Goal: `Select the next repeat-body child activation subset.`
  Acceptance: `Task tree, roadmap, and book backlog select top-level switch-branch nested repeat generated blocking '(do child (params ...) [(bind ...)] (domain NAME))' as the next bounded implementation subset; the selected contract is declared same-domain ownership metadata only on the static generated do instance, mirrors the shipped when-contained domain subset, preserves generated-composition and schedule-report clock-domain metadata for that lexical nested do site, and keeps spawn nesting, cross-domain activation, deeper branch/loop nesting, and broader outstanding-child semantics deferred.`
  Verification: `mdbook build docs/book; git diff --check`
  Commit: `ISF-REPEAT-BODY-CHILD-ACTIVATION.39: select switch repeat generated do domains`

- ID: `ISF-REPEAT-BODY-CHILD-ACTIVATION.40`
  Status: `done`
  Goal: `Ship switch-branch nested repeat generated do same-domain metadata if selected.`
  Acceptance: `Top-level switch branches accept nested '(repeat COUNT ... (do child (params ...) [(bind ...)] (domain NAME)) ...)' when NAME is the declared same-domain owner for the parent transaction and generated child; generated composition metadata and schedule-report clock-domain summaries preserve that ownership for the lexical nested repeat-do instance, while undeclared domains, cross-domain activation, spawn nesting, deeper branch/loop nesting, and broader outstanding-child semantics remain fail-closed.`
  Verification: `syntax checks; touched test Files=2, Tests=33; repeat/domain/doc suite Files=5, Tests=338; focused suite Files=13, Tests=369; mdbook build docs/book; ./bin/ci-regression isf --no-book Files=227, Tests=1140; git diff --check`
  Commit: `ISF-REPEAT-BODY-CHILD-ACTIVATION.40: implement switch repeat generated do domains`

- ID: `ISF-REPEAT-BODY-CHILD-ACTIVATION.41`
  Status: `done`
  Goal: `Select the next repeat-body child activation subset.`
  Acceptance: `Task tree, roadmap, and book backlog select top-level when-body nested repeat single generated spawn with same-body await_all drain as the next bounded spawn-nesting subset; the selected source shape is a repeat directly inside a top-level when body containing exactly one '(spawn child as inst [(params ...)] [(bind ...)] [(domain NAME)])' that must reach same-body '(await_all done)' before the nested repeat check can loop; the selected contract reuses the static generated-child handoff model, preserves source-order samples before the spawn or sync states, and keeps await_any, multiple pending nested spawns, switch-contained spawn nesting, do while a nested spawn is pending, cross-domain activation, deeper branch/loop nesting, and broader outstanding-child semantics deferred.`
  Verification: `mdbook build docs/book; git diff --check`
  Commit: `ISF-REPEAT-BODY-CHILD-ACTIVATION.41: select when repeat spawn await_all`

- ID: `ISF-REPEAT-BODY-CHILD-ACTIVATION.42`
  Status: `done`
  Goal: `Ship when-body nested repeat single generated spawn with same-body await_all if selected.`
  Acceptance: `Top-level when bodies accept nested '(repeat COUNT ... (spawn child as inst [(params ...)] [(bind ...)] [(domain NAME)]) ... (await_all done) ...)' only for exactly one pending nested spawn in that repeat body; generated-child metadata, generated-top static parameter/binding/domain handoffs, source-order sample timing before spawn or sync states, and done-gated nested repeat re-entry are preserved, while await_any, multiple pending nested spawns, switch-contained spawn nesting, do while a nested spawn is pending, cross-domain activation, deeper branch/loop nesting, and broader outstanding-child semantics remain fail-closed.`
  Verification: `syntax checks; touched/doc suite Files=4, Tests=333; focused activation/domain/doc suite Files=13, Tests=375; mdbook build docs/book; ./bin/ci-regression isf --no-book Files=227, Tests=1146; git diff --check`
  Commit: `ISF-REPEAT-BODY-CHILD-ACTIVATION.42: implement when repeat spawn await_all`

- ID: `ISF-REPEAT-BODY-CHILD-ACTIVATION.43`
  Status: `done`
  Goal: `Select the next repeat-body child activation subset.`
  Acceptance: `Task tree, roadmap, and book backlog select top-level switch-branch nested repeat single generated spawn with same-body await_all drain as the next bounded spawn-nesting subset; the selected source shape is a repeat directly inside a top-level switch branch containing exactly one '(spawn child as inst [(params ...)] [(bind ...)] [(domain NAME)])' that must reach same-body '(await_all done)' before the nested repeat check can loop; the selected contract mirrors the shipped when-contained single-spawn leaf, reuses the static generated-child handoff model, preserves source-order samples before the spawn or sync states, and keeps await_any, multiple pending nested spawns, do while a nested spawn is pending, cross-domain activation, deeper branch/loop nesting, and broader outstanding-child semantics deferred.`
  Verification: `mdbook build docs/book; git diff --check`
  Commit: `ISF-REPEAT-BODY-CHILD-ACTIVATION.43: select switch repeat spawn await_all`

- ID: `ISF-REPEAT-BODY-CHILD-ACTIVATION.44`
  Status: `done`
  Goal: `Ship switch-branch nested repeat single generated spawn with same-body await_all if selected.`
  Acceptance: `Top-level switch branches accept nested '(repeat COUNT ... (spawn child as inst [(params ...)] [(bind ...)] [(domain NAME)]) ... (await_all done) ...)' only for exactly one pending nested spawn in that repeat body; generated-child metadata, generated-top static parameter/binding/domain handoffs, source-order sample timing before spawn or sync states, and done-gated nested repeat re-entry are preserved, while await_any, multiple pending nested spawns, do while a nested spawn is pending, cross-domain activation, deeper branch/loop nesting, and broader outstanding-child semantics remain fail-closed.`
  Verification: `syntax checks; touched/doc suite Files=4, Tests=338; focused activation/domain/doc suite Files=13, Tests=380; mdbook build docs/book; ./bin/ci-regression isf --no-book Files=227, Tests=1151; git diff --check`
  Commit: `ISF-REPEAT-BODY-CHILD-ACTIVATION.44: implement switch repeat spawn await_all`

- ID: `ISF-REPEAT-BODY-CHILD-ACTIVATION.45`
  Status: `done`
  Goal: `Select the next repeat-body child activation subset.`
  Acceptance: `Task tree, roadmap, and book backlog select top-level when-body nested repeat single generated spawn with same-body single-pending await_any as the next bounded spawn-nesting subset; the selected source shape is a repeat directly inside a top-level when body containing exactly one '(spawn child as inst [(params ...)] [(bind ...)] [(domain NAME)])' that may drain through same-body '(await_any done)' because exactly one nested spawn is pending; the selected contract mirrors top-level repeat-body single-pending await_any, preserves source-order samples before spawn or sync states, and keeps multiple pending nested spawns, switch-contained await_any, do while a nested spawn is pending, cross-domain activation, deeper branch/loop nesting, and broader outstanding-child semantics deferred.`
  Verification: `mdbook build docs/book; git diff --check`
  Commit: `ISF-REPEAT-BODY-CHILD-ACTIVATION.45: select when repeat spawn await_any`

- ID: `ISF-REPEAT-BODY-CHILD-ACTIVATION.46`
  Status: `done`
  Goal: `Ship when-body nested repeat single generated spawn with same-body await_any if selected.`
  Acceptance: `Top-level when bodies accept nested '(repeat COUNT ... (spawn child as inst [(params ...)] [(bind ...)] [(domain NAME)]) ... (await_any done) ...)' only when exactly one nested spawn is pending in that repeat body; same-body await_any has the same re-entry proof as await_all for that one static generated child, source-order sample timing before spawn or sync states is preserved, and multiple pending nested spawns, switch-contained await_any, do while a nested spawn is pending, cross-domain activation, deeper branch/loop nesting, and broader outstanding-child semantics remain fail-closed.`
  Verification: `syntax checks; touched/doc suite Files=4, Tests=342; focused activation/domain/doc suite Files=13, Tests=384; mdbook build docs/book; ./bin/ci-regression isf --no-book Files=227, Tests=1155; git diff --check`
  Commit: `ISF-REPEAT-BODY-CHILD-ACTIVATION.46: implement when repeat spawn await_any`

- ID: `ISF-REPEAT-BODY-CHILD-ACTIVATION.47`
  Status: `done`
  Goal: `Select the next repeat-body child activation subset.`
  Acceptance: `Task tree, roadmap, and book backlog select top-level switch-branch nested repeat single generated spawn with same-body single-pending await_any as the next bounded spawn-nesting subset; the selected source shape is a repeat directly inside a top-level switch branch containing exactly one '(spawn child as inst [(params ...)] [(bind ...)] [(domain NAME)])' that may drain through same-body '(await_any done)' because exactly one nested spawn is pending; the selected contract mirrors the shipped when-contained single-pending await_any leaf, preserves source-order samples before spawn or sync states, and keeps multiple pending nested spawns, do while a nested spawn is pending, cross-domain activation, deeper branch/loop nesting, and broader outstanding-child semantics deferred.`
  Verification: `mdbook build docs/book; git diff --check`
  Commit: `ISF-REPEAT-BODY-CHILD-ACTIVATION.47: select switch repeat spawn await_any`

- ID: `ISF-REPEAT-BODY-CHILD-ACTIVATION.48`
  Status: `done`
  Goal: `Ship switch-branch nested repeat single generated spawn with same-body await_any if selected.`
  Acceptance: `Top-level switch branches accept nested '(repeat COUNT ... (spawn child as inst [(params ...)] [(bind ...)] [(domain NAME)]) ... (await_any done) ...)' only when exactly one nested spawn is pending in that repeat body; same-body await_any has the same re-entry proof as await_all for that one static generated child, source-order sample timing before spawn or sync states is preserved, and multiple pending nested spawns, do while a nested spawn is pending, cross-domain activation, deeper branch/loop nesting, and broader outstanding-child semantics remain fail-closed.`
  Verification: `syntax checks; touched repeat/spawn test Files=1, Tests=26; touched repeat/spawn/doc checks Files=4, Tests=346; focused activation/domain/doc suite Files=13, Tests=388; mdbook build docs/book; ./bin/ci-regression isf --no-book Files=227, Tests=1159; git diff --check`
  Commit: `ISF-REPEAT-BODY-CHILD-ACTIVATION.48: implement switch repeat spawn await_any`

- ID: `ISF-REPEAT-BODY-CHILD-ACTIVATION.49`
  Status: `done`
  Goal: `Select the next repeat-body child activation subset.`
  Acceptance: `Task tree, roadmap, and book backlog select top-level when-body nested repeat multiple generated spawns with mandatory same-body await_all drain as the next bounded implementation subset; the selected source shape is a repeat directly inside a top-level when body containing two or more '(spawn child as inst [(params ...)] [(bind ...)] [(domain NAME)])' sites that must reach same-body '(await_all done)' before the nested repeat check can loop; the selected contract reuses the static generated-child handoff model, preserves source-order samples before nested spawn or sync states, and keeps nested await_any for multiple pending children, switch-contained multiple nested spawns, do while a nested spawn is pending, cross-domain activation, deeper branch/loop nesting, and broader outstanding-child semantics deferred.`
  Verification: `mdbook build docs/book; git diff --check`
  Commit: `ISF-REPEAT-BODY-CHILD-ACTIVATION.49: select when repeat multiple spawns`

- ID: `ISF-REPEAT-BODY-CHILD-ACTIVATION.50`
  Status: `done`
  Goal: `Ship when-body nested repeat multiple generated spawns with same-body await_all if selected.`
  Acceptance: `Top-level when bodies accept nested '(repeat COUNT ... (spawn child as inst [(params ...)] [(bind ...)] [(domain NAME)]) ... (spawn child as inst2 [(params ...)] [(bind ...)] [(domain NAME)]) ... (await_all done) ...)' only when all pending nested generated spawns in that repeat body are drained by the same-body await_all before the nested repeat check can loop; generated-child metadata, generated-top static parameter/binding/domain handoffs, source-order sample timing before spawn or sync states, and done-gated nested repeat re-entry are preserved, while nested await_any for multiple pending children, switch-contained multiple nested spawns, do while a nested spawn is pending, cross-domain activation, deeper branch/loop nesting, and broader outstanding-child semantics remain fail-closed.`
  Verification: `syntax checks; touched repeat/spawn test Files=1, Tests=27; touched repeat/spawn/doc checks Files=4, Tests=351; focused activation/domain/doc suite Files=13, Tests=393; mdbook build docs/book; ./bin/ci-regression isf --no-book Files=227, Tests=1164; git diff --check`
  Commit: `ISF-REPEAT-BODY-CHILD-ACTIVATION.50: implement when repeat multiple spawns`

- ID: `ISF-REPEAT-BODY-CHILD-ACTIVATION.51`
  Status: `done`
  Goal: `Select the next repeat-body child activation subset.`
  Acceptance: `Task tree, roadmap, and book backlog select top-level switch-branch nested repeat multiple generated spawns with mandatory same-body await_all drain as the next bounded implementation subset; the selected source shape is a repeat directly inside a top-level switch branch containing two or more '(spawn child as inst [(params ...)] [(bind ...)] [(domain NAME)])' sites that must reach same-body '(await_all done)' before the nested repeat check can loop; the selected contract mirrors the shipped when-contained multiple-spawn leaf, reuses the static generated-child handoff model, preserves source-order samples before nested spawn or sync states, and keeps nested await_any for multiple pending children, do while a nested spawn is pending, cross-domain activation, deeper branch/loop nesting, and broader outstanding-child semantics deferred.`
  Verification: `mdbook build docs/book; git diff --check`
  Commit: `ISF-REPEAT-BODY-CHILD-ACTIVATION.51: select switch repeat multiple spawns`

- ID: `ISF-REPEAT-BODY-CHILD-ACTIVATION.52`
  Status: `done`
  Goal: `Ship switch-branch nested repeat multiple generated spawns with same-body await_all if selected.`
  Acceptance: `Top-level switch branches accept nested '(repeat COUNT ... (spawn child as inst [(params ...)] [(bind ...)] [(domain NAME)]) ... (spawn child as inst2 [(params ...)] [(bind ...)] [(domain NAME)]) ... (await_all done) ...)' only when all pending nested generated spawns in that repeat body are drained by the same-body await_all before the nested repeat check can loop; generated-child metadata, generated-top static parameter/binding/domain handoffs, source-order sample timing before spawn or sync states, and done-gated nested repeat re-entry are preserved, while nested await_any for multiple pending children, do while a nested spawn is pending, cross-domain activation, deeper branch/loop nesting, and broader outstanding-child semantics remain fail-closed.`
  Verification: `syntax checks; touched repeat/spawn test Files=1, Tests=28; touched repeat/spawn/doc checks Files=4, Tests=354; focused activation/domain/doc suite Files=13, Tests=396; mdbook build docs/book; ./bin/ci-regression isf --no-book Files=227, Tests=1167; git diff --check`
  Commit: `ISF-REPEAT-BODY-CHILD-ACTIVATION.52: implement switch repeat multiple spawns`

- ID: `ISF-REPEAT-BODY-CHILD-ACTIVATION.53`
  Status: `done`
  Goal: `Select the next repeat-body child activation subset.`
  Acceptance: `Task tree, roadmap, and book backlog select top-level when-body nested repeat multi-pending await_any with mandatory same-body await_all drain as the next bounded implementation subset; the selected source shape is a repeat directly inside a top-level when body containing two or more generated '(spawn child as inst [(params ...)] [(bind ...)] [(domain NAME)])' sites, an observation-point '(await_any done)', no new spawn or do before the mandatory later same-body '(await_all done)' drains the same outstanding generated children, and a nested repeat check that cannot loop until that drain completes; switch-contained multi-pending await_any, do while a nested spawn is pending, cross-domain activation, deeper branch/loop nesting, and broader outstanding-child semantics remain deferred.`
  Verification: `mdbook build docs/book; git diff --check`
  Commit: `ISF-REPEAT-BODY-CHILD-ACTIVATION.53: select when repeat await_any drain`

- ID: `ISF-REPEAT-BODY-CHILD-ACTIVATION.54`
  Status: `done`
  Goal: `Ship when-body nested repeat multi-pending await_any with mandatory same-body await_all drain if selected.`
  Acceptance: `Top-level when bodies accept nested '(repeat COUNT ... (spawn child as inst ...) ... (spawn child as inst2 ...) ... (await_any done) ... (await_all done) ...)' only when the await_any observes multiple pending generated children and a later same-body await_all drains those same outstanding children before the nested repeat check can loop; no new nested spawn or do may appear between the await_any observation and the mandatory drain, source-order samples before either sync remain explicit, and switch-contained multi-pending await_any, do while a nested spawn is pending, cross-domain activation, deeper branch/loop nesting, and broader outstanding-child semantics remain fail-closed.`
  Verification: `syntax checks; touched repeat/spawn test Files=1, Tests=29; touched repeat/spawn/doc checks Files=4, Tests=358; focused activation/domain/doc suite Files=13, Tests=400; mdbook build docs/book; ./bin/ci-regression isf --no-book Files=227, Tests=1171; git diff --check`
  Commit: `ISF-REPEAT-BODY-CHILD-ACTIVATION.54: implement when repeat await_any drain`

- ID: `ISF-REPEAT-BODY-CHILD-ACTIVATION.55`
  Status: `done`
  Goal: `Select the next repeat-body child activation subset.`
  Acceptance: `Task tree, roadmap, and book backlog select top-level switch-branch nested repeat multi-pending await_any with mandatory same-body await_all drain as the next bounded implementation subset; the selected source shape is a repeat directly inside a top-level switch branch containing two or more generated '(spawn child as inst [(params ...)] [(bind ...)] [(domain NAME)])' sites, an observation-point '(await_any done)', no new spawn or do before the mandatory later same-body '(await_all done)' drains the same outstanding generated children, and a nested repeat check that cannot loop until that drain completes; do while a nested spawn is pending, cross-domain activation, deeper branch/loop nesting, and broader outstanding-child semantics remain deferred.`
  Verification: `mdbook build docs/book; git diff --check`
  Commit: `ISF-REPEAT-BODY-CHILD-ACTIVATION.55: select switch repeat await_any drain`

- ID: `ISF-REPEAT-BODY-CHILD-ACTIVATION.56`
  Status: `done`
  Goal: `Ship switch-branch nested repeat multi-pending await_any with mandatory same-body await_all drain if selected.`
  Acceptance: `Top-level switch branches accept nested '(repeat COUNT ... (spawn child as inst ...) ... (spawn child as inst2 ...) ... (await_any done) ... (await_all done) ...)' only when the await_any observes multiple pending generated children and a later same-body await_all drains those same outstanding children before the nested repeat check can loop; no new nested spawn or do may appear between the await_any observation and the mandatory drain, source-order samples before either sync remain explicit, and do while a nested spawn is pending, cross-domain activation, deeper branch/loop nesting, and broader outstanding-child semantics remain fail-closed.`
  Verification: `syntax checks; touched repeat/spawn test Files=1, Tests=30; touched repeat/spawn/doc checks Files=4, Tests=362; focused activation/domain/doc suite Files=13, Tests=404; mdbook build docs/book; ./bin/ci-regression isf --no-book Files=227, Tests=1175; git diff --check`
  Commit: `ISF-REPEAT-BODY-CHILD-ACTIVATION.56: implement switch repeat await_any drain`

- ID: `ISF-REPEAT-BODY-CHILD-ACTIVATION.57`
  Status: `done`
  Goal: `Select the next repeat-body child activation subset.`
  Acceptance: `Task tree, roadmap, and book backlog select top-level when-body nested repeat local do while a generated nested spawn is pending as the next bounded implementation subset; the selected source shape is a repeat directly inside a top-level when body containing one or more generated '(spawn child as inst [(params ...)] [(bind ...)] [(domain NAME)])' sites, then local '(do child)' for a child that remains in the parent scheduled module before a later same-body '(await_all done)' drains the outstanding generated spawns and before the nested repeat check can loop; generated do while spawn pending, switch-contained analogue, await_any observation before the do, new spawn after the do before drain, cross-domain activation, deeper branch/loop nesting, and broader outstanding-child semantics remain deferred.`
  Verification: `mdbook build docs/book; git diff --check`
  Commit: `ISF-REPEAT-BODY-CHILD-ACTIVATION.57: select when repeat do while spawn pending`

- ID: `ISF-REPEAT-BODY-CHILD-ACTIVATION.58`
  Status: `done`
  Goal: `Ship when-body nested repeat local do while generated nested spawn is pending if selected.`
  Acceptance: `Top-level when bodies accept nested '(repeat COUNT ... (spawn child as inst ...) ... (do local_child) ... (await_all done) ...)' only when the do target is local to the parent scheduled module and a later same-body await_all drains every outstanding generated nested spawn before the nested repeat check can loop; the do waits for the local child's fresh done pulse without clearing the pending generated-spawn set, source-order samples around spawn/do/sync remain explicit, and generated do while spawn pending, switch-contained analogue, await_any observation before the do, new spawn after the do before drain, cross-domain activation, deeper branch/loop nesting, and broader outstanding-child semantics remain fail-closed.`
  Verification: `syntax checks; touched repeat/spawn test Files=1, Tests=31; touched repeat/spawn/doc checks Files=4, Tests=368; focused activation/domain/doc suite Files=13, Tests=410; mdbook build docs/book; ./bin/ci-regression isf --no-book Files=227, Tests=1181; git diff --check`
  Commit: `ISF-REPEAT-BODY-CHILD-ACTIVATION.58: implement when repeat do while spawn pending`

- ID: `ISF-REPEAT-BODY-CHILD-ACTIVATION.59`
  Status: `done`
  Goal: `Select the next repeat-body child activation subset.`
  Acceptance: `Task tree, roadmap, and book backlog select top-level switch-branch nested repeat local do while a generated nested spawn is pending as the next bounded implementation subset; the selected source shape is a repeat directly inside a top-level switch branch containing one or more generated '(spawn child as inst [(params ...)] [(bind ...)] [(domain NAME)])' sites, then local '(do child)' for a child that remains in the parent scheduled module before a later same-body '(await_all done)' drains the outstanding generated spawns and before the nested repeat check can loop; generated do while spawn pending, await_any observation before or after the do, new spawn after the do before drain, cross-domain activation, deeper branch/loop nesting, and broader outstanding-child semantics remain deferred.`
  Verification: `mdbook build docs/book; git diff --check`
  Commit: `ISF-REPEAT-BODY-CHILD-ACTIVATION.59: select switch repeat do while spawn pending`

- ID: `ISF-REPEAT-BODY-CHILD-ACTIVATION.60`
  Status: `done`
  Goal: `Ship switch-branch nested repeat local do while generated nested spawn is pending if selected.`
  Acceptance: `Top-level switch branches accept nested '(repeat COUNT ... (spawn child as inst ...) ... (do local_child) ... (await_all done) ...)' only when the do target is local to the parent scheduled module and a later same-body await_all drains every outstanding generated nested spawn before the nested repeat check can loop; the do waits for the local child's fresh done pulse without clearing the pending generated-spawn set, source-order samples around spawn/do/sync remain explicit, and generated do while spawn pending, await_any observation before or after the local do, new spawn after the local do before drain, cross-domain activation, deeper branch/loop nesting, and broader outstanding-child semantics remain fail-closed.`
  Verification: `syntax checks; touched repeat/spawn test Files=1, Tests=33; touched repeat/spawn/doc checks Files=4, Tests=380; focused activation/domain/doc suite Files=13, Tests=422; mdbook build docs/book; ./bin/ci-regression isf --no-book Files=227, Tests=1193; git diff --check`
  Commit: `ISF-REPEAT-BODY-CHILD-ACTIVATION.60: implement switch repeat do while spawn pending`

- ID: `ISF-REPEAT-BODY-CHILD-ACTIVATION.61`
  Status: `done`
  Goal: `Select the next repeat-body child activation subset.`
  Acceptance: `Task tree, roadmap, and book backlog select top-level when-body nested repeat generated-child plain do while a generated nested spawn is pending as the next bounded implementation subset; the selected source shape is a repeat directly inside a top-level when body containing one or more generated '(spawn child as inst [(params ...)] [(bind ...)] [(domain NAME)])' sites, then plain '(do child)' targeting a child already emitted as a generated child by another activation site, and then a later same-body '(await_all done)' drain before the nested repeat check can loop; static params, bind/domain subclauses on that do, switch-contained analogue, await_any observation before or after the do, new spawn after the do before drain, cross-domain activation, deeper branch/loop nesting, and broader outstanding-child semantics remain deferred.`
  Verification: `mdbook build docs/book; git diff --check`
  Commit: `ISF-REPEAT-BODY-CHILD-ACTIVATION.61: select when repeat generated do while spawn pending`

- ID: `ISF-REPEAT-BODY-CHILD-ACTIVATION.62`
  Status: `done`
  Goal: `Ship when-body nested repeat generated-child plain do while generated nested spawn is pending if selected.`
  Acceptance: `Top-level when bodies accept nested '(repeat COUNT ... (spawn child as inst ...) ... (do child) ... (await_all done) ...)' only when the do target is already emitted as a generated child by another activation site and a later same-body await_all drains every outstanding generated nested spawn before the nested repeat check can loop; the generated do site uses one deterministic generated do instance, waits for that instance's fresh done handoff without clearing the pending generated-spawn set, preserves source-order samples around spawn/do/sync, and keeps parameterized/bound/domain-qualified generated do while spawn pending, switch-contained analogue, await_any around the do, new spawn after the do before drain, cross-domain activation, deeper branch/loop nesting, and broader outstanding-child semantics fail-closed.`
  Verification: `syntax checks; focused repeat/spawn/doc tests; mdbook build docs/book; ./bin/ci-regression isf --no-book; git diff --check`
  Commit: `ISF-REPEAT-BODY-CHILD-ACTIVATION.62: implement when repeat generated do while spawn pending`

- ID: `ISF-REPEAT-BODY-CHILD-ACTIVATION.63`
  Status: `done`
  Goal: `Select the next repeat-body child activation subset.`
  Acceptance: `Task tree, roadmap, and book backlog select top-level switch-branch nested repeat generated-child plain do while a generated nested spawn is pending as the next bounded implementation subset; the selected source shape is a repeat directly inside a top-level switch branch containing one or more generated '(spawn child as inst [(params ...)] [(bind ...)] [(domain NAME)])' sites, then plain '(do child)' targeting a child already emitted as a generated child by another activation site, and then a later same-body '(await_all done)' drain before the nested repeat check can loop; static params, bind/domain subclauses on that do, await_any observation before or after the do, new spawn after the do before drain, cross-domain activation, deeper branch/loop nesting, and broader outstanding-child semantics remain deferred.`
  Verification: `mdbook build docs/book; git diff --check`
  Commit: `ISF-REPEAT-BODY-CHILD-ACTIVATION.63: select switch repeat generated do while spawn pending`

- ID: `ISF-REPEAT-BODY-CHILD-ACTIVATION.64`
  Status: `done`
  Goal: `Ship switch-branch nested repeat generated-child plain do while generated nested spawn is pending if selected.`
  Acceptance: `Top-level switch branches accept nested '(repeat COUNT ... (spawn child as inst ...) ... (do child) ... (await_all done) ...)' only when the do target is already emitted as a generated child by another activation site and a later same-body await_all drains every outstanding generated nested spawn before the nested repeat check can loop; the generated do site uses one deterministic generated do instance, waits for that instance's fresh done handoff without clearing the pending generated-spawn set, preserves source-order samples around spawn/do/sync, and keeps parameterized/bound/domain-qualified generated do while spawn pending, await_any around the do, new spawn after the do before drain, cross-domain activation, deeper branch/loop nesting, and broader outstanding-child semantics fail-closed.`
  Verification: `syntax checks; touched repeat/spawn test Files=1, Tests=34; touched repeat/spawn/doc checks Files=4, Tests=386; focused activation/domain/doc suite Files=13, Tests=428; mdbook build docs/book; ./bin/ci-regression isf --no-book Files=227, Tests=1199; git diff --check`
  Commit: `ISF-REPEAT-BODY-CHILD-ACTIVATION.64: implement switch repeat generated do while spawn pending`

- ID: `ISF-REPEAT-BODY-CHILD-ACTIVATION.65`
  Status: `done`
  Goal: `Select the next repeat-body child activation subset.`
  Acceptance: `Task tree, roadmap, and book backlog select top-level when-body nested repeat generated blocking '(do child (params ...))' while generated nested spawns are pending as the next bounded implementation subset; the selected source shape is a repeat directly inside a top-level when body containing one or more generated '(spawn child as inst [(params ...)] [(bind ...)] [(domain NAME)])' sites, then generated '(do child (params ...))' with static parameter overrides while those generated spawns remain pending, and then a later same-body '(await_all done)' drain before the nested repeat check can loop; bind/domain subclauses on that do, the switch-contained analogue, await_any observation before or after the do, new spawn after the do before drain, cross-domain activation, deeper branch/loop nesting, and broader outstanding-child semantics remain deferred.`
  Verification: `mdbook build docs/book; git diff --check`
  Commit: `ISF-REPEAT-BODY-CHILD-ACTIVATION.65: select when repeat parameterized do while spawn pending`

- ID: `ISF-REPEAT-BODY-CHILD-ACTIVATION.66`
  Status: `done`
  Goal: `Ship when-body nested repeat generated blocking do with static parameter overrides while generated nested spawn is pending if selected.`
  Acceptance: `Top-level when bodies accept nested '(repeat COUNT ... (spawn child as inst ...) ... (do child (params ...)) ... (await_all done) ...)' only when the generated do uses static parameter overrides and a later same-body await_all drains every outstanding generated nested spawn before the nested repeat check can loop; the generated do site uses one deterministic generated do instance with static parameter binding, waits for that instance's fresh done handoff without clearing the pending generated-spawn set, preserves source-order samples around spawn/do/sync, and keeps bind/domain subclauses on that do, switch-contained analogue, await_any around the do, new spawn after the do before drain, cross-domain activation, deeper branch/loop nesting, and broader outstanding-child semantics fail-closed.`
  Verification: `syntax checks; touched repeat/spawn test Files=1, Tests=35; touched repeat/spawn/doc checks Files=4, Tests=392; focused activation/domain/doc suite Files=13, Tests=434; mdbook build docs/book; ./bin/ci-regression isf --no-book Files=227, Tests=1205; git diff --check`
  Commit: `ISF-REPEAT-BODY-CHILD-ACTIVATION.66: implement when repeat parameterized do while spawn pending`

- ID: `ISF-REPEAT-BODY-CHILD-ACTIVATION.67`
  Status: `done`
  Goal: `Select the next repeat-body child activation subset.`
  Acceptance: `Task tree, roadmap, and book backlog select top-level switch-branch nested repeat generated blocking '(do child (params ...))' while generated nested spawns are pending as the next bounded implementation subset; the selected source shape is a repeat directly inside a top-level switch branch containing one or more generated '(spawn child as inst [(params ...)] [(bind ...)] [(domain NAME)])' sites, then generated '(do child (params ...))' with static parameter overrides while those generated spawns remain pending, and then a later same-body '(await_all done)' drain before the nested repeat check can loop; bind/domain subclauses on that do, await_any observation before or after the do, new spawn after the do before drain, cross-domain activation, deeper branch/loop nesting, and broader outstanding-child semantics remain deferred.`
  Verification: `mdbook build docs/book; git diff --check`
  Commit: `ISF-REPEAT-BODY-CHILD-ACTIVATION.67: select switch repeat parameterized do while spawn pending`

- ID: `ISF-REPEAT-BODY-CHILD-ACTIVATION.68`
  Status: `done`
  Goal: `Ship switch-branch nested repeat generated blocking do with static parameter overrides while generated nested spawn is pending if selected.`
  Acceptance: `Top-level switch branches accept nested '(repeat COUNT ... (spawn child as inst ...) ... (do child (params ...)) ... (await_all done) ...)' only when the generated do uses static parameter overrides and a later same-body await_all drains every outstanding generated nested spawn before the nested repeat check can loop; the generated do site uses one deterministic generated do instance with static parameter binding, waits for that instance's fresh done handoff without clearing the pending generated-spawn set, preserves source-order samples around spawn/do/sync, and keeps bind/domain subclauses on that do, await_any around the do, new spawn after the do before drain, cross-domain activation, deeper branch/loop nesting, and broader outstanding-child semantics fail-closed.`
  Verification: `syntax checks; touched repeat/spawn test Files=1, Tests=36; touched repeat/spawn/doc checks Files=4, Tests=398; focused activation/domain/doc suite Files=13, Tests=440; mdbook build docs/book; ./bin/ci-regression isf --no-book Files=227, Tests=1211; git diff --check`
  Commit: `ISF-REPEAT-BODY-CHILD-ACTIVATION.68: implement switch repeat parameterized do while spawn pending`

- ID: `ISF-REPEAT-BODY-CHILD-ACTIVATION.69`
  Status: `done`
  Goal: `Select the next repeat-body child activation subset.`
  Acceptance: `Task tree, roadmap, and book backlog select top-level when-body nested repeat generated blocking '(do child (params ...) (bind ...))' while generated nested spawns are pending as the next bounded implementation subset; the selected source shape is a repeat directly inside a top-level when body containing one or more generated '(spawn child as inst [(params ...)] [(bind ...)] [(domain NAME)])' sites, then generated '(do child (params ...) (bind ...))' with static parameter overrides and input/output port bindings while those generated spawns remain pending, and then a later same-body '(await_all done)' drain before the nested repeat check can loop; domain metadata on that do, switch-contained bound analogue, await_any observation before or after the do, new spawn after the do before drain, cross-domain activation, deeper branch/loop nesting, and broader outstanding-child semantics remain deferred.`
  Verification: `mdbook build docs/book; git diff --check`
  Commit: `ISF-REPEAT-BODY-CHILD-ACTIVATION.69: select when repeat bound do while spawn pending`

- ID: `ISF-REPEAT-BODY-CHILD-ACTIVATION.70`
  Status: `done`
  Goal: `Ship when-body nested repeat generated blocking do with static parameter overrides and port bindings while generated nested spawn is pending if selected.`
  Acceptance: `Top-level when bodies accept nested '(repeat COUNT ... (spawn child as inst ...) ... (do child (params ...) (bind ...)) ... (await_all done) ...)' only when the generated do uses static parameter overrides plus input/output port bindings and a later same-body await_all drains every outstanding generated nested spawn before the nested repeat check can loop; the generated do site uses one deterministic generated do instance with static parameter binding and generated-top binding handoff ports, waits for that instance's fresh done handoff without clearing the pending generated-spawn set, preserves source-order samples around spawn/do/sync, and keeps domain metadata on that do, switch-contained bound analogue, await_any around the do, new spawn after the do before drain, cross-domain activation, deeper branch/loop nesting, and broader outstanding-child semantics fail-closed.`
  Verification: `syntax checks; touched repeat/spawn test Files=1, Tests=37; touched repeat/spawn/doc checks Files=4, Tests=404; focused activation/domain/doc suite Files=13, Tests=446; mdbook build docs/book; ./bin/ci-regression isf --no-book Files=227, Tests=1217; git diff --check`
  Commit: `ISF-REPEAT-BODY-CHILD-ACTIVATION.70: implement when repeat bound do while spawn pending`

- ID: `ISF-REPEAT-BODY-CHILD-ACTIVATION.71`
  Status: `done`
  Goal: `Select the next repeat-body child activation subset.`
  Acceptance: `Task tree, roadmap, and book backlog select top-level switch-branch nested repeat generated blocking '(do child (params ...) (bind ...))' while generated nested spawns are pending as the next bounded implementation subset; the selected source shape is a repeat directly inside a top-level switch branch containing one or more generated '(spawn child as inst [(params ...)] [(bind ...)] [(domain NAME)])' sites, then generated '(do child (params ...) (bind ...))' with static parameter overrides and input/output port bindings while those generated spawns remain pending, and then a later same-body '(await_all done)' drain before the nested repeat check can loop; domain metadata on that do, await_any observation before or after the do, new spawn after the do before drain, cross-domain activation, deeper branch/loop nesting, and broader outstanding-child semantics remain deferred.`
  Verification: `mdbook build docs/book; git diff --check`
  Commit: `ISF-REPEAT-BODY-CHILD-ACTIVATION.71: select switch repeat bound do while spawn pending`

- ID: `ISF-REPEAT-BODY-CHILD-ACTIVATION.72`
  Status: `done`
  Goal: `Ship switch-branch nested repeat generated blocking do with static parameter overrides and port bindings while generated nested spawn is pending if selected.`
  Acceptance: `Top-level switch branches accept nested '(repeat COUNT ... (spawn child as inst ...) ... (do child (params ...) (bind ...)) ... (await_all done) ...)' only when the generated do uses static parameter overrides plus input/output port bindings and a later same-body await_all drains every outstanding generated nested spawn before the nested repeat check can loop; the generated do site uses one deterministic generated do instance with static parameter binding and generated-top binding handoff ports, waits for that instance's fresh done handoff without clearing the pending generated-spawn set, preserves source-order samples around spawn/do/sync, and keeps domain metadata on that do, await_any around the do, new spawn after the do before drain, cross-domain activation, deeper branch/loop nesting, and broader outstanding-child semantics fail-closed.`
  Verification: `syntax checks; touched repeat/spawn test Files=1, Tests=38; touched repeat/spawn/doc checks Files=4, Tests=410; focused activation/domain/doc suite Files=13, Tests=452; mdbook build docs/book; ./bin/ci-regression isf --no-book Files=227, Tests=1223; git diff --check`
  Commit: `ISF-REPEAT-BODY-CHILD-ACTIVATION.72: implement switch repeat bound do while spawn pending`

- ID: `ISF-REPEAT-BODY-CHILD-ACTIVATION.73`
  Status: `done`
  Goal: `Select the next repeat-body child activation subset.`
  Acceptance: `Task tree, roadmap, and book backlog select top-level when-body nested repeat generated blocking '(do child (params ...) [(bind ...)] (domain NAME))' while generated nested spawns are pending as the next bounded implementation subset; the selected source shape is a repeat directly inside a top-level when body containing one or more generated '(spawn child as inst [(params ...)] [(bind ...)] [(domain NAME)])' sites, then generated '(do child (params ...) [(bind ...)] (domain NAME))' with static parameter overrides, optional input/output port bindings, and declared same-domain metadata while those generated spawns remain pending, and then a later same-body '(await_all done)' drain before the nested repeat check can loop; the domain annotation is ownership metadata only and must not imply CDC or cross-domain activation; switch-contained domain analogue, await_any observation before or after the do, new spawn after the do before drain, cross-domain activation, deeper branch/loop nesting, and broader outstanding-child semantics remain deferred.`
  Verification: `mdbook build docs/book; git diff --check`
  Commit: `ISF-REPEAT-BODY-CHILD-ACTIVATION.73: select when repeat domain do while spawn pending`

- ID: `ISF-REPEAT-BODY-CHILD-ACTIVATION.74`
  Status: `done`
  Goal: `Ship when-body nested repeat generated blocking do with static parameter overrides, optional port bindings, and same-domain metadata while generated nested spawn is pending if selected.`
  Acceptance: `Top-level when bodies accept nested '(repeat COUNT ... (spawn child as inst ...) ... (do child (params ...) [(bind ...)] (domain NAME)) ... (await_all done) ...)' only when the generated do uses static parameter overrides, optional input/output port bindings, and declared same-domain metadata, and a later same-body await_all drains every outstanding generated nested spawn before the nested repeat check can loop; the generated do site uses one deterministic generated do instance with static parameter binding, optional generated-top binding handoff ports, and same-domain generated-composition and clock-domain report metadata, waits for that instance's fresh done handoff without clearing the pending generated-spawn set, preserves source-order samples around spawn/do/sync, and keeps switch-contained domain analogue, await_any around the do, new spawn after the do before drain, cross-domain activation, deeper branch/loop nesting, and broader outstanding-child semantics fail-closed.`
  Verification: `syntax checks; touched repeat/spawn test Files=1, Tests=39; touched repeat/spawn/doc checks Files=4, Tests=416; focused activation/domain/doc suite Files=13, Tests=458; mdbook build docs/book; ./bin/ci-regression isf --no-book Files=227, Tests=1229; git diff --check`
  Commit: `ISF-REPEAT-BODY-CHILD-ACTIVATION.74: implement when repeat domain do while spawn pending`

- ID: `ISF-REPEAT-BODY-CHILD-ACTIVATION.75`
  Status: `done`
  Goal: `Select the next repeat-body child activation subset.`
  Acceptance: `Task tree, roadmap, and book backlog select top-level switch-branch nested repeat generated blocking '(do child (params ...) [(bind ...)] (domain NAME))' while generated nested spawns are pending as the next bounded implementation subset; the selected source shape is a repeat directly inside a top-level switch branch containing one or more generated '(spawn child as inst [(params ...)] [(bind ...)] [(domain NAME)])' sites, then generated '(do child (params ...) [(bind ...)] (domain NAME))' with static parameter overrides, optional input/output port bindings, and declared same-domain metadata while those generated spawns remain pending, and then a later same-body '(await_all done)' drain before the nested repeat check can loop; the domain annotation is ownership metadata only and must not imply CDC or cross-domain activation; await_any observation before or after the do, new spawn after the do before drain, cross-domain activation, deeper branch/loop nesting, and broader outstanding-child semantics remain deferred.`
  Verification: `mdbook build docs/book; git diff --check`
  Commit: `ISF-REPEAT-BODY-CHILD-ACTIVATION.75: select switch repeat domain do while spawn pending`

- ID: `ISF-REPEAT-BODY-CHILD-ACTIVATION.76`
  Status: `done`
  Goal: `Ship switch-branch nested repeat generated blocking do with static parameter overrides, optional port bindings, and same-domain metadata while generated nested spawn is pending if selected.`
  Acceptance: `Top-level switch branches accept nested '(repeat COUNT ... (spawn child as inst ...) ... (do child (params ...) [(bind ...)] (domain NAME)) ... (await_all done) ...)' only when the generated do uses static parameter overrides, optional input/output port bindings, and declared same-domain metadata, and a later same-body await_all drains every outstanding generated nested spawn before the nested repeat check can loop; the generated do site uses one deterministic generated do instance with static parameter binding, optional generated-top binding handoff ports, and same-domain generated-composition and clock-domain report metadata, waits for that instance's fresh done handoff without clearing the pending generated-spawn set, preserves source-order samples around spawn/do/sync, and keeps await_any around the do, new spawn after the do before drain, cross-domain activation, deeper branch/loop nesting, and broader outstanding-child semantics fail-closed.`
  Verification: `syntax checks; touched repeat/spawn test Files=1, Tests=40; touched repeat/spawn/doc checks Files=4, Tests=422; focused activation/domain/doc suite Files=13, Tests=464; mdbook build docs/book; ./bin/ci-regression isf --no-book Files=227, Tests=1235; git diff --check`
  Commit: `ISF-REPEAT-BODY-CHILD-ACTIVATION.76: implement switch repeat domain do while spawn pending`

- ID: `ISF-REPEAT-BODY-CHILD-ACTIVATION.77`
  Status: `pending`
  Goal: `Select the next repeat-body child activation subset.`
  Acceptance: `Task tree, roadmap, and book backlog select the exact next bounded repeat-body child activation implementation subset before code changes; the selected leaf records source shape, shipped dependencies, exclusions, validation plan, and mdBook-facing truth.`
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
| 31 | `ISF-REPEAT-BODY-CHILD-ACTIVATION.31` | `done` | Selected top-level switch-branch nested repeat generated `do` with static parameter overrides. |
| 32 | `ISF-REPEAT-BODY-CHILD-ACTIVATION.32` | `done` | Shipped the selected switch-contained repeat generated do static-parameter subset. |
| 33 | `ISF-REPEAT-BODY-CHILD-ACTIVATION.33` | `done` | Selected top-level when-body nested repeat generated `do` with static params and port bindings. |
| 34 | `ISF-REPEAT-BODY-CHILD-ACTIVATION.34` | `done` | Shipped the selected when-contained repeat generated do binding subset. |
| 35 | `ISF-REPEAT-BODY-CHILD-ACTIVATION.35` | `done` | Selected top-level switch-branch nested repeat generated `do` with static params and port bindings. |
| 36 | `ISF-REPEAT-BODY-CHILD-ACTIVATION.36` | `done` | Shipped the selected switch-contained repeat generated do binding subset. |
| 37 | `ISF-REPEAT-BODY-CHILD-ACTIVATION.37` | `done` | Selected top-level when-body nested repeat generated `do` same-domain metadata. |
| 38 | `ISF-REPEAT-BODY-CHILD-ACTIVATION.38` | `done` | Shipped the selected when-contained repeat generated do domain subset. |
| 39 | `ISF-REPEAT-BODY-CHILD-ACTIVATION.39` | `done` | Selected top-level switch-branch nested repeat generated `do` same-domain metadata. |
| 40 | `ISF-REPEAT-BODY-CHILD-ACTIVATION.40` | `done` | Shipped the selected switch-contained repeat generated do domain subset. |
| 41 | `ISF-REPEAT-BODY-CHILD-ACTIVATION.41` | `done` | Selected top-level when-body nested repeat single generated spawn with same-body `await_all`. |
| 42 | `ISF-REPEAT-BODY-CHILD-ACTIVATION.42` | `done` | Shipped the selected when-contained repeat spawn await_all subset. |
| 43 | `ISF-REPEAT-BODY-CHILD-ACTIVATION.43` | `done` | Selected top-level switch-branch nested repeat single generated spawn with same-body `await_all`. |
| 44 | `ISF-REPEAT-BODY-CHILD-ACTIVATION.44` | `done` | Shipped the selected switch-contained repeat spawn await_all subset. |
| 45 | `ISF-REPEAT-BODY-CHILD-ACTIVATION.45` | `done` | Selected top-level when-body nested repeat single generated spawn with same-body `await_any`. |
| 46 | `ISF-REPEAT-BODY-CHILD-ACTIVATION.46` | `done` | Shipped the selected when-contained repeat spawn await_any subset. |
| 47 | `ISF-REPEAT-BODY-CHILD-ACTIVATION.47` | `done` | Selected top-level switch-branch nested repeat single generated spawn with same-body `await_any`. |
| 48 | `ISF-REPEAT-BODY-CHILD-ACTIVATION.48` | `done` | Shipped the selected switch-contained repeat spawn await_any subset. |
| 49 | `ISF-REPEAT-BODY-CHILD-ACTIVATION.49` | `done` | Selected top-level when-body nested repeat multiple generated spawns with mandatory same-body `await_all`. |
| 50 | `ISF-REPEAT-BODY-CHILD-ACTIVATION.50` | `done` | Shipped the selected when-contained multiple nested spawn await_all subset. |
| 51 | `ISF-REPEAT-BODY-CHILD-ACTIVATION.51` | `done` | Selected top-level switch-branch nested repeat multiple generated spawns with mandatory same-body `await_all`. |
| 52 | `ISF-REPEAT-BODY-CHILD-ACTIVATION.52` | `done` | Shipped the selected switch-contained multiple nested spawn await_all subset. |
| 53 | `ISF-REPEAT-BODY-CHILD-ACTIVATION.53` | `done` | Selected top-level when-body nested repeat multi-pending `await_any` with mandatory same-body `await_all` drain. |
| 54 | `ISF-REPEAT-BODY-CHILD-ACTIVATION.54` | `done` | Shipped the selected when-contained nested await_any drain subset. |
| 55 | `ISF-REPEAT-BODY-CHILD-ACTIVATION.55` | `done` | Selected top-level switch-branch nested repeat multi-pending `await_any` with mandatory same-body `await_all` drain. |
| 56 | `ISF-REPEAT-BODY-CHILD-ACTIVATION.56` | `done` | Shipped the selected switch-contained nested await_any drain subset. |
| 57 | `ISF-REPEAT-BODY-CHILD-ACTIVATION.57` | `done` | Selected top-level when-body nested repeat local do while a generated nested spawn is pending. |
| 58 | `ISF-REPEAT-BODY-CHILD-ACTIVATION.58` | `done` | Shipped the selected when-contained nested do-while-spawn-pending subset. |
| 59 | `ISF-REPEAT-BODY-CHILD-ACTIVATION.59` | `done` | Selected top-level switch-branch nested repeat local do while generated nested spawn is pending. |
| 60 | `ISF-REPEAT-BODY-CHILD-ACTIVATION.60` | `done` | Shipped the selected switch-contained do-while-spawn-pending subset. |
| 61 | `ISF-REPEAT-BODY-CHILD-ACTIVATION.61` | `done` | Selected when-contained generated-child do while generated nested spawn is pending. |
| 62 | `ISF-REPEAT-BODY-CHILD-ACTIVATION.62` | `done` | Shipped the selected when-contained generated-child do-while-spawn-pending subset. |
| 63 | `ISF-REPEAT-BODY-CHILD-ACTIVATION.63` | `done` | Selected switch-contained generated-child do while generated nested spawn is pending. |
| 64 | `ISF-REPEAT-BODY-CHILD-ACTIVATION.64` | `done` | Shipped the selected switch-contained generated-child do-while-spawn-pending subset. |
| 65 | `ISF-REPEAT-BODY-CHILD-ACTIVATION.65` | `done` | Selected when-contained generated do with static parameter overrides while generated nested spawn is pending. |
| 66 | `ISF-REPEAT-BODY-CHILD-ACTIVATION.66` | `done` | Shipped the selected when-contained generated static-parameter do-while-spawn-pending subset. |
| 67 | `ISF-REPEAT-BODY-CHILD-ACTIVATION.67` | `done` | Selected switch-contained generated do with static parameter overrides while generated nested spawn is pending. |
| 68 | `ISF-REPEAT-BODY-CHILD-ACTIVATION.68` | `done` | Shipped the selected switch-contained generated static-parameter do-while-spawn-pending subset. |
| 69 | `ISF-REPEAT-BODY-CHILD-ACTIVATION.69` | `done` | Selected when-contained generated do with static parameter overrides and port bindings while generated nested spawn is pending. |
| 70 | `ISF-REPEAT-BODY-CHILD-ACTIVATION.70` | `done` | Shipped the selected when-contained generated bound do-while-spawn-pending subset. |
| 71 | `ISF-REPEAT-BODY-CHILD-ACTIVATION.71` | `done` | Selected switch-contained generated do with static parameter overrides and port bindings while generated nested spawn is pending. |
| 72 | `ISF-REPEAT-BODY-CHILD-ACTIVATION.72` | `done` | Shipped the selected switch-contained generated bound do-while-spawn-pending subset. |
| 73 | `ISF-REPEAT-BODY-CHILD-ACTIVATION.73` | `done` | Selected when-contained generated do same-domain metadata while generated nested spawn is pending. |
| 74 | `ISF-REPEAT-BODY-CHILD-ACTIVATION.74` | `done` | Shipped the selected when-contained same-domain pending-spawn generated do subset. |
| 75 | `ISF-REPEAT-BODY-CHILD-ACTIVATION.75` | `done` | Selected switch-contained generated do same-domain metadata while generated nested spawn is pending. |
| 76 | `ISF-REPEAT-BODY-CHILD-ACTIVATION.76` | `done` | Shipped the selected switch-contained same-domain pending-spawn generated do subset. |
| 77 | `ISF-REPEAT-BODY-CHILD-ACTIVATION.77` | `pending` | Selects the next bounded repeat-body child activation subset. |

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
- `2026-05-17`: Leaf `.31` selects top-level switch-branch nested repeat
  generated blocking `(do child (params ...))` as the next bounded nested
  generated-do subset. The selected source shape is a repeat directly inside
  a top-level `switch` branch, with static parameter overrides only at that
  nested do site; lowering should emit one deterministic generated do
  instance for the lexical nested do site, apply overrides once in the
  generated top, and gate the switch-branch repeat check on that instance's
  fresh done handoff.
- `2026-05-17`: Leaf `.32` is the next implementation frontier for the
  selected switch-contained repeat generated do static-parameter subset.
- `2026-05-17`: Leaf `.32` shipped the selected top-level switch-branch
  nested repeat generated blocking `(do child (params ...))` subset. The
  lowerer now allows static parameter overrides on generated `do` sites
  inside repeats that are direct clauses of a top-level `switch` branch,
  emits one deterministic generated do instance for that lexical nested site,
  applies overrides once in the generated top, keeps source-order samples
  around the nested do, and gates the switch-branch repeat check on the
  generated instance's fresh done handoff. `(bind ...)`, `(domain NAME)`,
  spawn nesting, deeper branch/loop nesting, cross-domain activation, and
  broader outstanding-child semantics remain fail-closed.
- `2026-05-17`: Leaf `.33` is the next frontier and must select the next
  bounded repeat-body child activation subset before any further code changes.
- `2026-05-17`: Leaf `.33` selects top-level when-body nested repeat
  generated blocking `(do child (params ...) (bind ...))` as the next bounded
  nested generated-do binding subset. The selected source shape is a repeat
  directly inside a top-level `when` body, with static parameter overrides and
  input/output port bindings at that nested do site; lowering should reuse the
  deterministic generated do instance for the lexical nested do site, wire
  binding handoffs once in the generated top, and gate the when-body repeat
  check on that instance's fresh done handoff.
- `2026-05-17`: Leaf `.34` is the next implementation frontier for the
  selected when-contained repeat generated do binding subset.
- `2026-05-17`: Leaf `.34` shipped the selected top-level when-body nested
  repeat generated blocking `(do child (params ...) (bind ...))` subset. The
  lowerer now allows static parameter overrides plus input/output port
  bindings on generated `do` sites inside repeats that are direct clauses of a
  top-level `when` body, emits one deterministic generated do instance for
  that lexical nested site, applies overrides and wires binding handoffs once
  in the generated top, preserves source-order samples around the nested do,
  and gates the when-body repeat check on the generated instance's fresh done
  handoff. `(domain NAME)`, switch-contained bound nested `do`, spawn nesting,
  deeper branch/loop nesting, cross-domain activation, and broader
  outstanding-child semantics remain fail-closed.
- `2026-05-17`: Leaf `.35` is the next frontier and must select the next
  bounded repeat-body child activation subset before any further code changes.
- `2026-05-17`: Leaf `.35` selects top-level switch-branch nested repeat
  generated blocking `(do child (params ...) (bind ...))` as the next bounded
  nested generated-do binding subset. The selected source shape is a repeat
  directly inside a top-level `switch` branch, with static parameter
  overrides and input/output port bindings at that nested do site; lowering
  should reuse the deterministic generated do instance for the lexical nested
  do site, wire binding handoffs once in the generated top, and gate the
  switch-branch repeat check on that instance's fresh done handoff.
- `2026-05-17`: Leaf `.36` is the next implementation frontier for the
  selected switch-contained repeat generated do binding subset.
- `2026-05-17`: Leaf `.36` shipped the selected top-level switch-branch
  nested repeat generated blocking `(do child (params ...) (bind ...))`
  subset. The lowerer now allows static parameter overrides plus input/output
  port bindings on generated `do` sites inside repeats that are direct
  clauses of a top-level `switch` branch, emits one deterministic generated
  do instance for that lexical nested site, applies overrides and wires
  binding handoffs once in the generated top, preserves source-order samples
  around the nested do, and gates the switch-branch repeat check on the
  generated instance's fresh done handoff. `(domain NAME)`, spawn nesting,
  deeper branch/loop nesting, cross-domain activation, and broader
  outstanding-child semantics remain fail-closed.
- `2026-05-17`: Leaf `.37` is the next frontier and must select the next
  bounded repeat-body child activation subset before any further code changes.
- `2026-05-17`: Leaf `.37` selects top-level when-body nested repeat
  generated blocking `(do child (params ...) [(bind ...)] (domain NAME))` as
  the next bounded nested generated-do domain subset. The selected contract is
  declared same-domain ownership metadata only for the deterministic generated
  do instance at the lexical nested site, with generated-composition and
  schedule-report clock-domain metadata preserved but no CDC or cross-domain
  activation semantics.
- `2026-05-17`: Leaf `.38` is the next implementation frontier for the
  selected when-contained repeat generated do same-domain metadata subset.
- `2026-05-17`: Leaf `.38` shipped the selected top-level when-body nested
  repeat generated blocking `(do child (params ...) [(bind ...)] (domain NAME))`
  subset. The lowerer now accepts declared same-domain ownership metadata on
  generated `do` sites inside repeats that are direct clauses of a top-level
  `when` body, preserves generated-composition and schedule-report
  clock-domain metadata for the deterministic nested generated do instance,
  and keeps cross-domain activation, switch-contained domain metadata, spawn
  nesting, deeper branch/loop nesting, and broader outstanding-child semantics
  fail-closed.
- `2026-05-17`: Leaf `.39` is the next frontier and must select the next
  bounded repeat-body child activation subset before any further code changes.
- `2026-05-17`: Leaf `.39` selects top-level switch-branch nested repeat
  generated blocking `(do child (params ...) [(bind ...)] (domain NAME))` as
  the next bounded nested generated-do domain subset. The selected contract is
  declared same-domain ownership metadata only for the deterministic generated
  do instance at the lexical nested site, mirrors the shipped when-contained
  domain subset, preserves generated-composition and schedule-report
  clock-domain metadata, and does not imply CDC or cross-domain activation.
- `2026-05-17`: Leaf `.40` is the next implementation frontier for the
  selected switch-contained repeat generated do same-domain metadata subset.
- `2026-05-17`: Leaf `.40` shipped the selected top-level switch-branch
  nested repeat generated blocking `(do child (params ...) [(bind ...)] (domain NAME))`
  subset. The lowerer now accepts declared same-domain ownership metadata on
  generated `do` sites inside repeats that are direct clauses of a top-level
  `switch` branch, preserves generated-composition and schedule-report
  clock-domain metadata for the deterministic nested generated do instance,
  and keeps cross-domain activation, spawn nesting, deeper branch/loop
  nesting, and broader outstanding-child semantics fail-closed.
- `2026-05-17`: Leaf `.41` is the next frontier and must select the next
  bounded repeat-body child activation subset before any further code changes.
- `2026-05-17`: Leaf `.41` selects top-level when-body nested repeat single
  generated `(spawn child as inst [(params ...)] [(bind ...)] [(domain NAME)])`
  with same-body `(await_all done)` as the next bounded spawn-nesting subset.
  The selected source shape is a repeat directly inside a top-level `when`
  body, exactly one pending nested spawn, same-body drain before the nested
  repeat check can loop, and existing static generated-child handoffs for
  params, bindings, and declared same-domain metadata.
- `2026-05-17`: Leaf `.42` is the next implementation frontier for the
  selected when-contained repeat spawn await_all subset.
- `2026-05-17`: Leaf `.42` shipped the selected top-level when-body nested
  repeat single generated
  `(spawn child as inst [(params ...)] [(bind ...)] [(domain NAME)])` subset
  with same-body `(await_all done)`. The lowerer now accepts exactly one
  pending generated spawn in a repeat directly inside a top-level `when`
  body, preserves generated-child metadata plus generated-top parameter,
  binding, and declared same-domain handoffs, keeps samples before nested
  spawn or sync states in source order, and rejects `await_any`, multiple
  pending nested spawns, switch-contained spawn nesting, `do` while nested
  spawn is pending, cross-domain activation, deeper branch/loop nesting, and
  broader outstanding-child semantics.
- `2026-05-17`: Leaf `.43` is the next frontier and must select the next
  bounded repeat-body child activation subset before any further code
  changes. Candidate frontiers include when-contained `await_any` or multiple
  nested spawns, switch-contained spawn nesting, `do` while a nested spawn is
  pending, cross-domain activation, deeper branch/loop nesting, and broader
  outstanding-child semantics.
- `2026-05-17`: Leaf `.43` selects top-level switch-branch nested repeat
  single generated `(spawn child as inst [(params ...)] [(bind ...)] [(domain NAME)])`
  with same-body `(await_all done)` as the next bounded spawn-nesting subset.
  The selected source shape is a repeat directly inside a top-level `switch`
  branch, exactly one pending nested spawn, same-body drain before the nested
  repeat check can loop, and existing static generated-child handoffs for
  params, bindings, and declared same-domain metadata.
- `2026-05-17`: Leaf `.44` is the next implementation frontier for the
  selected switch-contained repeat spawn await_all subset.
- `2026-05-17`: Leaf `.44` shipped the selected top-level switch-branch
  nested repeat single generated
  `(spawn child as inst [(params ...)] [(bind ...)] [(domain NAME)])` subset
  with same-body `(await_all done)`. The lowerer now accepts exactly one
  pending generated spawn in a repeat directly inside a top-level `switch`
  branch, preserves generated-child metadata plus generated-top parameter,
  binding, and declared same-domain handoffs, keeps samples before nested
  spawn or sync states in source order, and rejects `await_any`, multiple
  pending nested spawns, `do` while nested spawn is pending, cross-domain
  activation, deeper branch/loop nesting, and broader outstanding-child
  semantics.
- `2026-05-17`: Leaf `.45` is the next frontier and must select the next
  bounded repeat-body child activation subset before any further code
  changes. Candidate frontiers include branch-contained `await_any` or
  multiple nested spawns, `do` while a nested spawn is pending, cross-domain
  activation, deeper branch/loop nesting, and broader outstanding-child
  semantics.
- `2026-05-17`: Leaf `.45` selects top-level `when` bodies containing nested
  repeats with exactly one generated
  `(spawn child as inst [(params ...)] [(bind ...)] [(domain NAME)])` that
  may drain through same-body single-pending `(await_any done)`. Because only
  one nested static child is pending, the selected proof is equivalent to the
  shipped `await_all` leaf: the nested repeat check cannot loop until that one
  child's done handoff is observed.
- `2026-05-17`: Leaf `.46` is the next implementation frontier for the
  selected when-contained repeat spawn `await_any` subset. Multiple pending
  nested spawns, switch-contained `await_any`, `do` while a nested spawn is
  pending, cross-domain activation, deeper branch/loop nesting, and broader
  outstanding-child semantics remain separate contracts.
- `2026-05-17`: Leaf `.46` shipped top-level `when` bodies containing nested
  repeats with exactly one generated
  `(spawn child as inst [(params ...)] [(bind ...)] [(domain NAME)])` that
  drains through same-body single-pending `(await_any done)`.
  Source-order samples before nested spawn or sync states, generated-top
  static parameter overrides, input/output binding handoffs, declared
  same-domain metadata, and report metadata are preserved.
- `2026-05-17`: Leaf `.47` is the next frontier and must select the next
  bounded repeat-body child activation subset before any further code changes.
  Candidate frontiers include switch-contained `await_any`, multiple nested
  spawns, `do` while a nested spawn is pending, cross-domain activation,
  deeper branch/loop nesting, and broader outstanding-child semantics.
- `2026-05-17`: Leaf `.47` selects top-level `switch` branches containing
  nested repeats with exactly one generated
  `(spawn child as inst [(params ...)] [(bind ...)] [(domain NAME)])` that
  may drain through same-body single-pending `(await_any done)`. Because only
  one nested static child is pending, the selected proof mirrors the shipped
  when-contained `await_any` leaf and the existing switch-contained
  `await_all` leaf.
- `2026-05-17`: Leaf `.48` is the next implementation frontier for the
  selected switch-contained repeat spawn `await_any` subset. Multiple pending
  nested spawns, `do` while a nested spawn is pending, cross-domain
  activation, deeper branch/loop nesting, and broader outstanding-child
  semantics remain separate contracts.
- `2026-05-17`: Leaf `.48` shipped top-level `switch` branches containing
  nested repeats with exactly one generated
  `(spawn child as inst [(params ...)] [(bind ...)] [(domain NAME)])` that
  drains through same-body single-pending `(await_any done)`.
  Source-order samples before nested spawn or sync states, generated-top
  static parameter overrides, input/output binding handoffs, declared
  same-domain metadata, and report metadata are preserved.
- `2026-05-17`: Leaf `.49` is the next frontier and must select the next
  bounded repeat-body child activation subset before any further code changes.
  Candidate frontiers include multiple nested spawns, `do` while a nested
  spawn is pending, cross-domain activation, deeper branch/loop nesting, and
  broader outstanding-child semantics.
- `2026-05-17`: Leaf `.49` selects top-level `when` bodies containing nested
  repeats with two or more generated
  `(spawn child as inst [(params ...)] [(bind ...)] [(domain NAME)])` sites
  that must drain through same-body `(await_all done)`. The selected contract
  reuses the static generated-child handoff model and source-order samples
  before nested spawn or sync states, while keeping nested `await_any` for
  multiple pending children, switch-contained multiple nested spawns, `do`
  while a nested spawn is pending, cross-domain activation, deeper
  branch/loop nesting, and broader outstanding-child semantics deferred.
- `2026-05-17`: Leaf `.50` is the next implementation frontier for the
  selected when-contained multiple nested spawn `await_all` subset.
- `2026-05-17`: Leaf `.50` shipped top-level `when` bodies containing nested
  repeats with two or more generated
  `(spawn child as inst [(params ...)] [(bind ...)] [(domain NAME)])` sites
  that drain through same-body `(await_all done)`. Generated-child metadata,
  generated-top static parameter overrides, input/output binding handoffs,
  declared same-domain metadata, source-order samples before nested spawn or
  sync states, schedule-report port-binding provenance, and clock-domain
  child-instance metadata are preserved.
- `2026-05-17`: Leaf `.51` is the next frontier and must select the next
  bounded repeat-body child activation subset before any further code changes.
  Candidate frontiers include switch-contained multiple nested spawns, nested
  `await_any` for multiple pending children, `do` while a nested spawn is
  pending, cross-domain activation, deeper branch/loop nesting, and broader
  outstanding-child semantics.
- `2026-05-17`: Leaf `.51` selects top-level `switch` branches containing
  nested repeats with two or more generated
  `(spawn child as inst [(params ...)] [(bind ...)] [(domain NAME)])` sites
  that must drain through same-body `(await_all done)`. The selected contract
  mirrors the shipped when-contained multiple-spawn leaf, reuses the static
  generated-child handoff model, and preserves source-order samples before
  nested spawn or sync states while keeping nested `await_any` for multiple
  pending children, `do` while a nested spawn is pending, cross-domain
  activation, deeper branch/loop nesting, and broader outstanding-child
  semantics deferred.
- `2026-05-17`: Leaf `.52` is the next implementation frontier for the
  selected switch-contained multiple nested spawn `await_all` subset.
- `2026-05-17`: Leaf `.52` shipped top-level `switch` branches containing
  nested repeats with two or more generated
  `(spawn child as inst [(params ...)] [(bind ...)] [(domain NAME)])` sites
  that drain through same-body `(await_all done)`. Generated-child metadata,
  generated-top static parameter overrides, input/output binding handoffs,
  declared same-domain metadata, source-order samples before nested spawn or
  sync states, schedule-report port-binding provenance, and clock-domain
  child-instance metadata are preserved.
- `2026-05-17`: Leaf `.53` is the next frontier and must select the next
  bounded repeat-body child activation subset before any further code changes.
  Candidate frontiers include nested `await_any` for multiple pending
  branch-contained generated children, `do` while a nested spawn is pending,
  cross-domain activation, deeper branch/loop nesting, and broader
  outstanding-child semantics.
- `2026-05-17`: Leaf `.53` selects top-level `when` bodies containing nested
  repeats with two or more generated
  `(spawn child as inst [(params ...)] [(bind ...)] [(domain NAME)])` sites, a
  multi-pending `(await_any done)` observation point, and a mandatory later
  same-body `(await_all done)` drain before the nested repeat check can loop.
  New nested `spawn` or `do` clauses between the observation and the drain,
  switch-contained multi-pending `await_any`, cross-domain activation, deeper
  branch/loop nesting, and broader outstanding-child semantics remain
  deferred.
- `2026-05-17`: Leaf `.54` is the next implementation frontier for the
  selected when-contained nested multi-pending `await_any` drain subset.
- `2026-05-17`: Leaf `.54` shipped top-level `when` bodies containing nested
  repeats with two or more generated
  `(spawn child as inst [(params ...)] [(bind ...)] [(domain NAME)])` sites, a
  multi-pending `(await_any done)` observation point, and a mandatory later
  same-body `(await_all done)` drain before the nested repeat check can loop.
  Source-order samples before either sync remain explicit, and no new nested
  `spawn` or `do` may appear before the mandatory drain.
- `2026-05-17`: Leaf `.55` is the next frontier and must select the next
  bounded repeat-body child activation subset before any further code changes.
  Candidate frontiers include switch-contained multi-pending `await_any`
  drain, `do` while a nested spawn is pending, cross-domain activation, deeper
  branch/loop nesting, and broader outstanding-child semantics.
- `2026-05-17`: Leaf `.55` selects top-level `switch` branches containing
  nested repeats with two or more generated
  `(spawn child as inst [(params ...)] [(bind ...)] [(domain NAME)])` sites, a
  multi-pending `(await_any done)` observation point, and a mandatory later
  same-body `(await_all done)` drain before the nested repeat check can loop.
  New nested `spawn` or `do` clauses between the observation and the drain,
  cross-domain activation, deeper branch/loop nesting, and broader
  outstanding-child semantics remain deferred.
- `2026-05-17`: Leaf `.56` is the next implementation frontier for the
  selected switch-contained nested multi-pending `await_any` drain subset.
- `2026-05-17`: Leaf `.56` shipped top-level `switch` branches containing
  nested repeats with two or more generated
  `(spawn child as inst [(params ...)] [(bind ...)] [(domain NAME)])` sites, a
  multi-pending `(await_any done)` observation point, and a mandatory later
  same-body `(await_all done)` drain before the nested repeat check can loop.
  Source-order samples before either sync remain explicit, and no new nested
  `spawn` or `do` may appear before the mandatory drain.
- `2026-05-17`: Leaf `.57` is the next frontier and must select the next
  bounded repeat-body child activation subset before any further code changes.
  Candidate frontiers include `do` while a nested spawn is pending,
  cross-domain activation, deeper branch/loop nesting, and broader
  outstanding-child semantics.
- `2026-05-17`: Leaf `.57` selects top-level `when` bodies containing nested
  repeats with one or more generated
  `(spawn child as inst [(params ...)] [(bind ...)] [(domain NAME)])` sites
  followed by local `(do child)` before a later same-body `(await_all done)`
  drains the outstanding generated nested spawns and before the nested repeat
  check can loop. Generated `do` while spawn pending, the switch-contained
  analogue, `await_any` observation before the do, new spawn after the do
  before drain, cross-domain activation, deeper branch/loop nesting, and
  broader outstanding-child semantics remain deferred.
- `2026-05-17`: Leaf `.58` is the next implementation frontier for the
  selected when-contained nested local do-while-spawn-pending subset.
- `2026-05-17`: Leaf `.58` shipped top-level `when` body nested repeats that
  run local plain `(do child)` while generated nested spawns remain pending,
  before a later same-body `(await_all done)` drain. The local do waits for
  the local child's fresh done pulse without clearing the generated-spawn done
  set; the later drain still gates nested repeat re-entry on every outstanding
  generated child. Generated `do` while spawn pending, the switch-contained
  analogue, `await_any` before or after the do, new spawn after the do before
  drain, cross-domain activation, deeper branch/loop nesting, and broader
  outstanding-child semantics remain fail-closed.
- `2026-05-17`: Leaf `.59` is the next frontier and must select the next
  bounded repeat-body child activation subset before any further code changes.
- `2026-05-18`: Leaf `.59` selects the direct top-level switch-branch
  analogue of the shipped when-contained local-do-while-generated-spawn-pending
  subset. The selected implementation must keep the local do target in the
  parent scheduled module, keep generated-spawn done handoffs live until a
  later same-body `await_all` drain, and reject `await_any` around the do, new
  spawn after the do before drain, generated do while pending, cross-domain
  activation, deeper branch/loop nesting, and broader outstanding-child
  semantics.
- `2026-05-18`: Leaf `.60` shipped the selected top-level switch-branch
  nested repeat local-do-while-generated-spawn-pending subset. The local do
  remains in the parent scheduled module, waits for the local child's fresh
  done pulse, leaves generated nested spawn done handoffs pending, and
  requires a later same-body `(await_all done)` drain before the switch-branch
  nested repeat check can loop. Generated do while pending, `await_any` before
  or after the local do, new nested spawn after the local do before the drain,
  cross-domain activation, deeper branch/loop nesting, and broader
  outstanding-child semantics remain fail-closed.
- `2026-05-18`: Leaf `.61` is the next frontier and must select the next
  bounded repeat-body child activation subset before any further code changes.
- `2026-05-18`: Leaf `.61` selects top-level when-body nested repeat
  generated-child plain `do` while generated nested spawns are pending as the
  next bounded implementation subset. The selected do target must already be
  emitted as a generated child by another activation site, the generated do
  site should own one deterministic instance, the do must wait for that
  instance's fresh done handoff without clearing pending generated-spawn
  handoffs, and a later same-body `(await_all done)` drain must still gate the
  nested repeat check. Static params, bind/domain subclauses on that do,
  switch-contained analogue, `await_any` before or after the do, new spawn
  after the do before drain, cross-domain activation, deeper branch/loop
  nesting, and broader outstanding-child semantics remain deferred.
- `2026-05-18`: Leaf `.62` is the next implementation frontier for the
  selected when-contained generated-child do-while-spawn-pending subset.
- `2026-05-18`: Leaf `.62` shipped top-level when-body nested repeats that
  run plain generated-child `(do child)` while generated nested spawns remain
  pending, before a later same-body `(await_all done)` drain. The generated
  do site owns one deterministic generated instance, waits for that
  instance's fresh done handoff, leaves pending generated-spawn done handoffs
  live for the later drain, and preserves source-order samples around
  spawn/do/sync. Parameterized, bound, or domain-qualified generated do while
  pending, the switch-contained generated-child analogue, `await_any` before
  or after the do, new nested spawn after the do before the drain,
  cross-domain activation, deeper branch/loop nesting, and broader
  outstanding-child semantics remain fail-closed.
- `2026-05-18`: Leaf `.63` is the next frontier and must select the next
  bounded repeat-body child activation subset before any further code changes.
- `2026-05-18`: Leaf `.63` selects the direct top-level switch-branch
  analogue of the shipped when-contained generated-child-do-while-spawn-pending
  subset. The selected implementation must keep the generated do target
  limited to a plain child already emitted as a generated child elsewhere,
  keep generated-spawn done handoffs live until a later same-body `await_all`
  drain, and reject parameterized/bound/domain-qualified generated do while
  pending, `await_any` around the do, new spawn after the do before drain,
  cross-domain activation, deeper branch/loop nesting, and broader
  outstanding-child semantics.
- `2026-05-18`: Leaf `.64` is the next implementation frontier for the
  selected switch-contained generated-child do-while-spawn-pending subset.
- `2026-05-18`: Leaf `.64` shipped top-level switch-branch nested repeats that
  run plain generated-child `(do child)` while generated nested spawns remain
  pending, before a later same-body `(await_all done)` drain. The generated
  do site owns one deterministic generated instance, waits for that
  instance's fresh done handoff, leaves pending generated-spawn done handoffs
  live for the later drain, and preserves source-order samples around
  spawn/do/sync. Parameterized, bound, or domain-qualified generated do while
  pending, `await_any` before or after the do, new nested spawn after the do
  before the drain, cross-domain activation, deeper branch/loop nesting, and
  broader outstanding-child semantics remain fail-closed.
- `2026-05-18`: Leaf `.65` is the next frontier and must select the next
  bounded repeat-body child activation subset before any further code changes.
- `2026-05-18`: Leaf `.65` selects top-level when-body nested repeat
  generated blocking `(do child (params ...))` with static parameter
  overrides while generated nested spawns are pending as the next bounded
  implementation subset. The selected implementation must keep the generated
  do target limited to static params, keep generated-spawn done handoffs live
  until a later same-body `await_all` drain, and reject bind/domain subclauses
  on that do, the switch-contained analogue, `await_any` around the do, new
  spawn after the do before drain, cross-domain activation, deeper
  branch/loop nesting, and broader outstanding-child semantics.
- `2026-05-18`: Leaf `.66` is the next implementation frontier for the
  selected when-contained generated static-parameter do-while-spawn-pending
  subset.
- `2026-05-18`: Leaf `.66` shipped top-level when-body nested repeats that run
  generated blocking `(do child (params ...))` with static parameter
  overrides while generated nested spawns remain pending, before a later
  same-body `(await_all done)` drain. The generated do site owns one
  deterministic generated instance, preserves static generated-top parameter
  binding, waits for that instance's fresh done handoff, leaves pending
  generated-spawn done handoffs live for the later drain, and preserves
  source-order samples around spawn/do/sync. Bind/domain subclauses on that
  do, the switch-contained analogue, `await_any` before or after the do, new
  nested spawn after the do before the drain, cross-domain activation, deeper
  branch/loop nesting, and broader outstanding-child semantics remain
  fail-closed.
- `2026-05-18`: Leaf `.67` is the next frontier and must select the next
  bounded repeat-body child activation subset before any further code changes.
- `2026-05-18`: Leaf `.67` selects the direct top-level switch-branch
  analogue of the shipped when-contained static-parameter-generated-do-while-
  spawn-pending subset. The selected implementation must keep the generated do
  target limited to static params, keep generated-spawn done handoffs live
  until a later same-body `await_all` drain, and reject bind/domain subclauses
  on that do, `await_any` around the do, new spawn after the do before drain,
  cross-domain activation, deeper branch/loop nesting, and broader
  outstanding-child semantics.
- `2026-05-18`: Leaf `.68` is the next implementation frontier for the
  selected switch-contained generated static-parameter do-while-spawn-pending
  subset.
- `2026-05-18`: Leaf `.68` ships the selected switch-contained generated
  static-parameter do-while-spawn-pending subset. The validator now allows
  the top-level switch-branch analogue of the when-contained static-parameter
  generated do while generated nested spawns remain pending, while keeping
  bind/domain subclauses on that do, `await_any` around the do, spawn after
  that do before drain, cross-domain activation, deeper branch/loop nesting,
  and broader outstanding-child semantics fail-closed.
- `2026-05-18`: Leaf `.69` is the next selection frontier and must choose the
  next bounded repeat-body child activation subset before any further code
  changes.
- `2026-05-18`: Leaf `.69` selects top-level when-body nested repeat
  generated blocking `(do child (params ...) (bind ...))` while generated
  nested spawns are pending as the next bounded implementation subset. The
  selected implementation must preserve static generated-top parameter
  binding and generated-top input/output binding handoffs on the generated do
  instance while leaving generated-spawn done handoffs live until a later
  same-body `await_all` drain; domain metadata on that do, the switch-contained
  bound analogue, `await_any` around the do, new spawn after the do before
  drain, cross-domain activation, deeper branch/loop nesting, and broader
  outstanding-child semantics remain deferred.
- `2026-05-18`: Leaf `.70` is the next implementation frontier for the
  selected when-contained generated bound do-while-spawn-pending subset.
- `2026-05-18`: Leaf `.70` ships the selected when-contained generated bound
  do-while-spawn-pending subset. The validator now allows static-parameter
  generated `(do child (params ...) (bind ...))` in a repeat directly under a
  top-level `when` body while generated nested spawns remain pending, provided
  a later same-body `await_all` drains every outstanding generated child before
  the nested repeat check can loop. Domain metadata on that do, the
  switch-contained bound analogue, `await_any` around the do, spawn after that
  do before drain, cross-domain activation, deeper branch/loop nesting, and
  broader outstanding-child semantics remain fail-closed.
- `2026-05-18`: Leaf `.71` is the next selection frontier and must choose the
  next bounded repeat-body child activation subset before any further code
  changes.
- `2026-05-18`: Leaf `.71` selects top-level switch-branch nested repeat
  generated blocking `(do child (params ...) (bind ...))` while generated
  nested spawns are pending as the next bounded implementation subset. The
  selected implementation must preserve static generated-top parameter
  binding and generated-top input/output binding handoffs on the generated do
  instance while leaving generated-spawn done handoffs live until a later
  same-body `await_all` drain; domain metadata on that do, `await_any` around
  the do, new spawn after the do before drain, cross-domain activation, deeper
  branch/loop nesting, and broader outstanding-child semantics remain
  deferred.
- `2026-05-18`: Leaf `.72` is the next implementation frontier for the
  selected switch-contained generated bound do-while-spawn-pending subset.
- `2026-05-18`: Leaf `.72` ships the selected switch-contained generated
  bound do-while-spawn-pending subset. The validator now allows the top-level
  switch-branch analogue of the when-contained static-parameter bound
  generated do while generated nested spawns remain pending, while keeping
  domain metadata on that do, `await_any` around the do, spawn after that do
  before drain, cross-domain activation, deeper branch/loop nesting, and
  broader outstanding-child semantics fail-closed.
- `2026-05-18`: Leaf `.73` is the next selection frontier and must choose the
  next bounded repeat-body child activation subset before any further code
  changes.
- `2026-05-18`: Leaf `.73` selects the top-level when-body nested repeat
  generated blocking `(do child (params ...) [(bind ...)] (domain NAME))`
  while generated nested spawns are pending as the next bounded
  implementation subset. The selected contract is declared same-domain
  ownership metadata only on the generated do instance, layered on the shipped
  static-parameter plus optional binding handoff proof, with a later
  same-body `(await_all done)` still draining every pending generated spawn
  before the nested repeat check can loop.
- `2026-05-18`: Leaf `.74` is the next implementation frontier. It must keep
  the switch-contained domain analogue, `await_any` before or after the do,
  new nested spawn after the do before drain, cross-domain activation, deeper
  branch/loop nesting, and broader outstanding-child semantics fail-closed.
- `2026-05-18`: Leaf `.74` ships the selected when-contained generated
  same-domain do-while-spawn-pending subset. The validator now allows a
  top-level `when` body nested repeat to run generated
  `(do child (params ...) [(bind ...)] (domain NAME))` while generated nested
  spawns are pending, only when a later same-body `(await_all done)` drains
  every pending generated child before repeat re-entry; the domain annotation
  remains declared ownership metadata only.
- `2026-05-18`: Leaf `.75` is the next selection frontier and must choose the
  next bounded repeat-body child activation subset before any further code
  changes.
- `2026-05-18`: Leaf `.75` selects the top-level switch-branch nested repeat
  generated blocking `(do child (params ...) [(bind ...)] (domain NAME))`
  while generated nested spawns are pending as the next bounded
  implementation subset. The selected contract is declared same-domain
  ownership metadata only on the generated do instance, layered on the shipped
  switch-contained static-parameter plus optional binding handoff proof, with
  a later same-body `(await_all done)` still draining every pending generated
  spawn before the nested repeat check can loop.
- `2026-05-18`: Leaf `.76` is the next implementation frontier. It must keep
  `await_any` before or after the do, new nested spawn after the do before
  drain, cross-domain activation, deeper branch/loop nesting, and broader
  outstanding-child semantics fail-closed.
- `2026-05-18`: Leaf `.76` ships the selected switch-contained generated
  same-domain do-while-spawn-pending subset. The validator now allows a
  top-level `switch` branch nested repeat to run generated
  `(do child (params ...) [(bind ...)] (domain NAME))` while generated nested
  spawns are pending, only when a later same-body `(await_all done)` drains
  every pending generated child before repeat re-entry; the domain annotation
  remains declared ownership metadata only.
- `2026-05-18`: Leaf `.77` is the next selection frontier and must choose the
  next bounded repeat-body child activation subset before any further code
  changes.

## Open Questions

- None for tracking. Leaf `.77` must select the next bounded repeat-body
  child activation subset.

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
| `2026-05-17` | `ISF-REPEAT-BODY-CHILD-ACTIVATION.31` | `mdbook build docs/book`; `git diff --check` | `book and diff checks passed after selecting top-level switch-branch nested repeat generated do static params` |
| `2026-05-17` | `ISF-REPEAT-BODY-CHILD-ACTIVATION.32` | `perl -Iperl -c perl/FSM/Scheduler/ISF/LoweringIR.pm`; `perl -Iperl -c t/1215-isf-spawn-parameter-binding.t`; `perl -Iperl -c t/1103-isf-switch-branch-exits.t`; `perl -Iperl -c t/1177-isf-do-child-done-pulse.t`; `perl -Iperl -c t/1184-isf-child-transaction-target-boundary.t`; `perl -Iperl -c t/1203-isf-await-sync-clause-boundary.t`; `perl -Iperl -c t/1204-isf-child-composition-clause-boundary.t`; `perl -Iperl -c t/1241-isf-transaction-port-bindings.t`; `perl -Iperl -c t/1242-isf-port-binding-conflict-semantics.t`; `perl -Iperl -c t/1243-isf-port-binding-schedule-report.t`; `perl -Iperl -c t/1304-isf-repeat-body-doc-truth-audit.t`; `perl -Iperl -c t/1305-isf-book-feature-matrix-audit.t`; `perl -Iperl -c t/1307-isf-loop-body-doc-truth-audit.t`; `prove -l t/1215-isf-spawn-parameter-binding.t`; `prove -l t/1215-isf-spawn-parameter-binding.t t/1304-isf-repeat-body-doc-truth-audit.t t/1305-isf-book-feature-matrix-audit.t t/1307-isf-loop-body-doc-truth-audit.t`; `prove -l t/1103-isf-switch-branch-exits.t t/1215-isf-spawn-parameter-binding.t t/1177-isf-do-child-done-pulse.t t/1184-isf-child-transaction-target-boundary.t t/1203-isf-await-sync-clause-boundary.t t/1204-isf-child-composition-clause-boundary.t t/1241-isf-transaction-port-bindings.t t/1242-isf-port-binding-conflict-semantics.t t/1243-isf-port-binding-schedule-report.t t/1304-isf-repeat-body-doc-truth-audit.t t/1305-isf-book-feature-matrix-audit.t t/1307-isf-loop-body-doc-truth-audit.t`; `mdbook build docs/book`; `./bin/ci-regression isf --no-book`; `git diff --check` | `syntax, focused switch/repeat/do/generated-composition/doc checks (single touched test Files=1, Tests=20; repeat/doc suite Files=4, Tests=325; focused suite Files=12, Tests=356), book build, full ISF gate (Files=227, Tests=1136), and diff checks passed` |
| `2026-05-17` | `ISF-REPEAT-BODY-CHILD-ACTIVATION.33` | `mdbook build docs/book`; `git diff --check` | `book and diff checks passed after selecting top-level when-body nested repeat generated do bindings` |
| `2026-05-17` | `ISF-REPEAT-BODY-CHILD-ACTIVATION.34` | `perl -Iperl -c perl/FSM/Scheduler/ISF/LoweringIR.pm`; `perl -Iperl -c t/1215-isf-spawn-parameter-binding.t`; `perl -Iperl -c t/1103-isf-switch-branch-exits.t`; `perl -Iperl -c t/1177-isf-do-child-done-pulse.t`; `perl -Iperl -c t/1184-isf-child-transaction-target-boundary.t`; `perl -Iperl -c t/1203-isf-await-sync-clause-boundary.t`; `perl -Iperl -c t/1204-isf-child-composition-clause-boundary.t`; `perl -Iperl -c t/1241-isf-transaction-port-bindings.t`; `perl -Iperl -c t/1242-isf-port-binding-conflict-semantics.t`; `perl -Iperl -c t/1243-isf-port-binding-schedule-report.t`; `perl -Iperl -c t/1304-isf-repeat-body-doc-truth-audit.t`; `perl -Iperl -c t/1305-isf-book-feature-matrix-audit.t`; `perl -Iperl -c t/1307-isf-loop-body-doc-truth-audit.t`; `prove -l t/1215-isf-spawn-parameter-binding.t`; `prove -l t/1215-isf-spawn-parameter-binding.t t/1304-isf-repeat-body-doc-truth-audit.t t/1305-isf-book-feature-matrix-audit.t t/1307-isf-loop-body-doc-truth-audit.t`; `prove -l t/1103-isf-switch-branch-exits.t t/1215-isf-spawn-parameter-binding.t t/1177-isf-do-child-done-pulse.t t/1184-isf-child-transaction-target-boundary.t t/1203-isf-await-sync-clause-boundary.t t/1204-isf-child-composition-clause-boundary.t t/1241-isf-transaction-port-bindings.t t/1242-isf-port-binding-conflict-semantics.t t/1243-isf-port-binding-schedule-report.t t/1304-isf-repeat-body-doc-truth-audit.t t/1305-isf-book-feature-matrix-audit.t t/1307-isf-loop-body-doc-truth-audit.t`; `mdbook build docs/book`; `./bin/ci-regression isf --no-book`; `git diff --check` | `syntax, focused when/repeat/do/binding/generated-composition/doc checks (single touched test Files=1, Tests=21; repeat/doc suite Files=4, Tests=326; focused suite Files=12, Tests=357), book build, full ISF gate (Files=227, Tests=1137), and diff checks passed` |
| `2026-05-17` | `ISF-REPEAT-BODY-CHILD-ACTIVATION.35` | `mdbook build docs/book`; `git diff --check` | `book and diff checks passed after selecting top-level switch-branch nested repeat generated do bindings` |
| `2026-05-17` | `ISF-REPEAT-BODY-CHILD-ACTIVATION.36` | `perl -Iperl -c perl/FSM/Scheduler/ISF/LoweringIR.pm`; `perl -Iperl -c t/1215-isf-spawn-parameter-binding.t`; `perl -Iperl -c t/1103-isf-switch-branch-exits.t`; `perl -Iperl -c t/1177-isf-do-child-done-pulse.t`; `perl -Iperl -c t/1184-isf-child-transaction-target-boundary.t`; `perl -Iperl -c t/1203-isf-await-sync-clause-boundary.t`; `perl -Iperl -c t/1204-isf-child-composition-clause-boundary.t`; `perl -Iperl -c t/1241-isf-transaction-port-bindings.t`; `perl -Iperl -c t/1242-isf-port-binding-conflict-semantics.t`; `perl -Iperl -c t/1243-isf-port-binding-schedule-report.t`; `perl -Iperl -c t/1304-isf-repeat-body-doc-truth-audit.t`; `perl -Iperl -c t/1305-isf-book-feature-matrix-audit.t`; `perl -Iperl -c t/1307-isf-loop-body-doc-truth-audit.t`; `prove -l t/1215-isf-spawn-parameter-binding.t`; `prove -l t/1215-isf-spawn-parameter-binding.t t/1304-isf-repeat-body-doc-truth-audit.t t/1305-isf-book-feature-matrix-audit.t t/1307-isf-loop-body-doc-truth-audit.t`; `prove -l t/1103-isf-switch-branch-exits.t t/1215-isf-spawn-parameter-binding.t t/1177-isf-do-child-done-pulse.t t/1184-isf-child-transaction-target-boundary.t t/1203-isf-await-sync-clause-boundary.t t/1204-isf-child-composition-clause-boundary.t t/1241-isf-transaction-port-bindings.t t/1242-isf-port-binding-conflict-semantics.t t/1243-isf-port-binding-schedule-report.t t/1304-isf-repeat-body-doc-truth-audit.t t/1305-isf-book-feature-matrix-audit.t t/1307-isf-loop-body-doc-truth-audit.t`; `mdbook build docs/book`; `./bin/ci-regression isf --no-book`; `git diff --check` | `syntax, focused switch/repeat/do/binding/generated-composition/doc checks (single touched test Files=1, Tests=22; repeat/doc suite Files=4, Tests=327; focused suite Files=12, Tests=358), book build, full ISF gate (Files=227, Tests=1138), and diff checks passed` |
| `2026-05-17` | `ISF-REPEAT-BODY-CHILD-ACTIVATION.37` | `mdbook build docs/book`; `git diff --check` | `book and diff checks passed after selecting top-level when-body nested repeat generated do same-domain metadata` |
| `2026-05-17` | `ISF-REPEAT-BODY-CHILD-ACTIVATION.38` | `perl -Iperl -c perl/FSM/Scheduler/ISF/LoweringIR.pm`; `perl -Iperl -c t/1215-isf-spawn-parameter-binding.t`; `perl -Iperl -c t/1247-isf-clock-domain-partition.t`; `perl -Iperl -c t/1304-isf-repeat-body-doc-truth-audit.t`; `perl -Iperl -c t/1305-isf-book-feature-matrix-audit.t`; `perl -Iperl -c t/1307-isf-loop-body-doc-truth-audit.t`; `prove -l t/1215-isf-spawn-parameter-binding.t t/1247-isf-clock-domain-partition.t`; `prove -l t/1215-isf-spawn-parameter-binding.t t/1247-isf-clock-domain-partition.t t/1304-isf-repeat-body-doc-truth-audit.t t/1305-isf-book-feature-matrix-audit.t t/1307-isf-loop-body-doc-truth-audit.t`; `prove -l t/1103-isf-switch-branch-exits.t t/1215-isf-spawn-parameter-binding.t t/1177-isf-do-child-done-pulse.t t/1184-isf-child-transaction-target-boundary.t t/1203-isf-await-sync-clause-boundary.t t/1204-isf-child-composition-clause-boundary.t t/1241-isf-transaction-port-bindings.t t/1242-isf-port-binding-conflict-semantics.t t/1243-isf-port-binding-schedule-report.t t/1247-isf-clock-domain-partition.t t/1304-isf-repeat-body-doc-truth-audit.t t/1305-isf-book-feature-matrix-audit.t t/1307-isf-loop-body-doc-truth-audit.t`; `mdbook build docs/book`; `./bin/ci-regression isf --no-book`; `git diff --check` | `syntax, touched repeat/do/domain checks (Files=2, Tests=32), repeat/domain/doc suite (Files=5, Tests=337), focused suite (Files=13, Tests=368), book build, full ISF gate (Files=227, Tests=1139), and diff check passed` |
| `2026-05-17` | `ISF-REPEAT-BODY-CHILD-ACTIVATION.39` | `mdbook build docs/book`; `git diff --check` | `book and diff checks passed after selecting top-level switch-branch nested repeat generated do same-domain metadata` |
| `2026-05-17` | `ISF-REPEAT-BODY-CHILD-ACTIVATION.40` | `perl -Iperl -c perl/FSM/Scheduler/ISF/LoweringIR.pm`; `perl -Iperl -c t/1215-isf-spawn-parameter-binding.t`; `perl -Iperl -c t/1247-isf-clock-domain-partition.t`; `perl -Iperl -c t/1304-isf-repeat-body-doc-truth-audit.t`; `perl -Iperl -c t/1305-isf-book-feature-matrix-audit.t`; `perl -Iperl -c t/1307-isf-loop-body-doc-truth-audit.t`; `prove -l t/1215-isf-spawn-parameter-binding.t t/1247-isf-clock-domain-partition.t`; `prove -l t/1215-isf-spawn-parameter-binding.t t/1247-isf-clock-domain-partition.t t/1304-isf-repeat-body-doc-truth-audit.t t/1305-isf-book-feature-matrix-audit.t t/1307-isf-loop-body-doc-truth-audit.t`; `prove -l t/1103-isf-switch-branch-exits.t t/1215-isf-spawn-parameter-binding.t t/1177-isf-do-child-done-pulse.t t/1184-isf-child-transaction-target-boundary.t t/1203-isf-await-sync-clause-boundary.t t/1204-isf-child-composition-clause-boundary.t t/1241-isf-transaction-port-bindings.t t/1242-isf-port-binding-conflict-semantics.t t/1243-isf-port-binding-schedule-report.t t/1247-isf-clock-domain-partition.t t/1304-isf-repeat-body-doc-truth-audit.t t/1305-isf-book-feature-matrix-audit.t t/1307-isf-loop-body-doc-truth-audit.t`; `mdbook build docs/book`; `./bin/ci-regression isf --no-book`; `git diff --check` | `syntax, touched repeat/do/domain checks (Files=2, Tests=33), repeat/domain/doc suite (Files=5, Tests=338), focused suite (Files=13, Tests=369), book build, full ISF gate (Files=227, Tests=1140), and diff check passed` |
| `2026-05-17` | `ISF-REPEAT-BODY-CHILD-ACTIVATION.41` | `mdbook build docs/book`; `git diff --check` | `book and diff checks passed after selecting top-level when-body nested repeat single generated spawn with same-body await_all` |
| `2026-05-17` | `ISF-REPEAT-BODY-CHILD-ACTIVATION.42` | `perl -Iperl -c perl/FSM/Scheduler/ISF/LoweringIR.pm`; `perl -Iperl -c t/1215-isf-spawn-parameter-binding.t`; `perl -Iperl -c t/1304-isf-repeat-body-doc-truth-audit.t`; `perl -Iperl -c t/1305-isf-book-feature-matrix-audit.t`; `perl -Iperl -c t/1307-isf-loop-body-doc-truth-audit.t`; `prove -l t/1215-isf-spawn-parameter-binding.t t/1304-isf-repeat-body-doc-truth-audit.t t/1305-isf-book-feature-matrix-audit.t t/1307-isf-loop-body-doc-truth-audit.t`; `prove -l t/1103-isf-switch-branch-exits.t t/1215-isf-spawn-parameter-binding.t t/1177-isf-do-child-done-pulse.t t/1184-isf-child-transaction-target-boundary.t t/1203-isf-await-sync-clause-boundary.t t/1204-isf-child-composition-clause-boundary.t t/1241-isf-transaction-port-bindings.t t/1242-isf-port-binding-conflict-semantics.t t/1243-isf-port-binding-schedule-report.t t/1247-isf-clock-domain-partition.t t/1304-isf-repeat-body-doc-truth-audit.t t/1305-isf-book-feature-matrix-audit.t t/1307-isf-loop-body-doc-truth-audit.t`; `mdbook build docs/book`; `./bin/ci-regression isf --no-book`; `git diff --check` | `syntax, touched repeat/spawn/doc checks (Files=4, Tests=333), focused activation/domain/doc suite (Files=13, Tests=375), book build, full ISF gate (Files=227, Tests=1146), and diff check passed` |
| `2026-05-17` | `ISF-REPEAT-BODY-CHILD-ACTIVATION.43` | `mdbook build docs/book`; `git diff --check` | `book and diff checks passed after selecting top-level switch-branch nested repeat single generated spawn with same-body await_all` |
| `2026-05-17` | `ISF-REPEAT-BODY-CHILD-ACTIVATION.44` | `perl -Iperl -c perl/FSM/Scheduler/ISF/LoweringIR.pm`; `perl -Iperl -c t/1215-isf-spawn-parameter-binding.t`; `perl -Iperl -c t/1304-isf-repeat-body-doc-truth-audit.t`; `perl -Iperl -c t/1305-isf-book-feature-matrix-audit.t`; `perl -Iperl -c t/1307-isf-loop-body-doc-truth-audit.t`; `prove -l t/1215-isf-spawn-parameter-binding.t t/1304-isf-repeat-body-doc-truth-audit.t t/1305-isf-book-feature-matrix-audit.t t/1307-isf-loop-body-doc-truth-audit.t`; `prove -l t/1103-isf-switch-branch-exits.t t/1215-isf-spawn-parameter-binding.t t/1177-isf-do-child-done-pulse.t t/1184-isf-child-transaction-target-boundary.t t/1203-isf-await-sync-clause-boundary.t t/1204-isf-child-composition-clause-boundary.t t/1241-isf-transaction-port-bindings.t t/1242-isf-port-binding-conflict-semantics.t t/1243-isf-port-binding-schedule-report.t t/1247-isf-clock-domain-partition.t t/1304-isf-repeat-body-doc-truth-audit.t t/1305-isf-book-feature-matrix-audit.t t/1307-isf-loop-body-doc-truth-audit.t`; `mdbook build docs/book`; `./bin/ci-regression isf --no-book`; `git diff --check` | `syntax, touched repeat/spawn/doc checks (Files=4, Tests=338), focused activation/domain/doc suite (Files=13, Tests=380), book build, full ISF gate (Files=227, Tests=1151), and diff check passed` |
| `2026-05-17` | `ISF-REPEAT-BODY-CHILD-ACTIVATION.45` | `mdbook build docs/book`; `git diff --check` | `book and diff checks passed after selecting top-level when-body nested repeat single generated spawn with same-body await_any` |
| `2026-05-17` | `ISF-REPEAT-BODY-CHILD-ACTIVATION.46` | `perl -Iperl -c perl/FSM/Scheduler/ISF/LoweringIR.pm`; `perl -Iperl -c t/1215-isf-spawn-parameter-binding.t`; `perl -Iperl -c t/1305-isf-book-feature-matrix-audit.t`; `perl -Iperl -c t/1307-isf-loop-body-doc-truth-audit.t`; `prove -l t/1215-isf-spawn-parameter-binding.t`; `prove -l t/1215-isf-spawn-parameter-binding.t t/1304-isf-repeat-body-doc-truth-audit.t t/1305-isf-book-feature-matrix-audit.t t/1307-isf-loop-body-doc-truth-audit.t`; `prove -l t/1103-isf-switch-branch-exits.t t/1215-isf-spawn-parameter-binding.t t/1177-isf-do-child-done-pulse.t t/1184-isf-child-transaction-target-boundary.t t/1203-isf-await-sync-clause-boundary.t t/1204-isf-child-composition-clause-boundary.t t/1241-isf-transaction-port-bindings.t t/1242-isf-port-binding-conflict-semantics.t t/1243-isf-port-binding-schedule-report.t t/1247-isf-clock-domain-partition.t t/1304-isf-repeat-body-doc-truth-audit.t t/1305-isf-book-feature-matrix-audit.t t/1307-isf-loop-body-doc-truth-audit.t`; `mdbook build docs/book`; `./bin/ci-regression isf --no-book`; `git diff --check` | `syntax, touched repeat/spawn test (Files=1, Tests=25), touched repeat/spawn/doc checks (Files=4, Tests=342), focused activation/domain/doc suite (Files=13, Tests=384), book build, full ISF gate (Files=227, Tests=1155), and diff check passed` |
| `2026-05-17` | `ISF-REPEAT-BODY-CHILD-ACTIVATION.47` | `mdbook build docs/book`; `git diff --check` | `book and diff checks passed after selecting top-level switch-branch nested repeat single generated spawn with same-body await_any` |
| `2026-05-17` | `ISF-REPEAT-BODY-CHILD-ACTIVATION.48` | `perl -Iperl -c perl/FSM/Scheduler/ISF/LoweringIR.pm`; `perl -Iperl -c t/1215-isf-spawn-parameter-binding.t`; `perl -Iperl -c t/1305-isf-book-feature-matrix-audit.t`; `perl -Iperl -c t/1307-isf-loop-body-doc-truth-audit.t`; `prove -l t/1215-isf-spawn-parameter-binding.t`; `prove -l t/1215-isf-spawn-parameter-binding.t t/1304-isf-repeat-body-doc-truth-audit.t t/1305-isf-book-feature-matrix-audit.t t/1307-isf-loop-body-doc-truth-audit.t`; `prove -l t/1103-isf-switch-branch-exits.t t/1215-isf-spawn-parameter-binding.t t/1177-isf-do-child-done-pulse.t t/1184-isf-child-transaction-target-boundary.t t/1203-isf-await-sync-clause-boundary.t t/1204-isf-child-composition-clause-boundary.t t/1241-isf-transaction-port-bindings.t t/1242-isf-port-binding-conflict-semantics.t t/1243-isf-port-binding-schedule-report.t t/1247-isf-clock-domain-partition.t t/1304-isf-repeat-body-doc-truth-audit.t t/1305-isf-book-feature-matrix-audit.t t/1307-isf-loop-body-doc-truth-audit.t`; `mdbook build docs/book`; `./bin/ci-regression isf --no-book`; `git diff --check` | `syntax, touched repeat/spawn test (Files=1, Tests=26), touched repeat/spawn/doc checks (Files=4, Tests=346), focused activation/domain/doc suite (Files=13, Tests=388), book build, full ISF gate (Files=227, Tests=1159), and diff check passed` |
| `2026-05-17` | `ISF-REPEAT-BODY-CHILD-ACTIVATION.49` | `mdbook build docs/book`; `git diff --check` | `book and diff checks passed after selecting top-level when-body nested repeat multiple generated spawns with mandatory same-body await_all` |
| `2026-05-17` | `ISF-REPEAT-BODY-CHILD-ACTIVATION.50` | `perl -Iperl -c perl/FSM/Scheduler/ISF/LoweringIR.pm`; `perl -Iperl -c t/1215-isf-spawn-parameter-binding.t`; `perl -Iperl -c t/1305-isf-book-feature-matrix-audit.t`; `perl -Iperl -c t/1307-isf-loop-body-doc-truth-audit.t`; `prove -l t/1215-isf-spawn-parameter-binding.t`; `prove -l t/1215-isf-spawn-parameter-binding.t t/1304-isf-repeat-body-doc-truth-audit.t t/1305-isf-book-feature-matrix-audit.t t/1307-isf-loop-body-doc-truth-audit.t`; `prove -l t/1103-isf-switch-branch-exits.t t/1215-isf-spawn-parameter-binding.t t/1177-isf-do-child-done-pulse.t t/1184-isf-child-transaction-target-boundary.t t/1203-isf-await-sync-clause-boundary.t t/1204-isf-child-composition-clause-boundary.t t/1241-isf-transaction-port-bindings.t t/1242-isf-port-binding-conflict-semantics.t t/1243-isf-port-binding-schedule-report.t t/1247-isf-clock-domain-partition.t t/1304-isf-repeat-body-doc-truth-audit.t t/1305-isf-book-feature-matrix-audit.t t/1307-isf-loop-body-doc-truth-audit.t`; `mdbook build docs/book`; `./bin/ci-regression isf --no-book`; `git diff --check` | `syntax, touched repeat/spawn test (Files=1, Tests=27), touched repeat/spawn/doc checks (Files=4, Tests=351), focused activation/domain/doc suite (Files=13, Tests=393), book build, full ISF gate (Files=227, Tests=1164), and diff check passed` |
| `2026-05-17` | `ISF-REPEAT-BODY-CHILD-ACTIVATION.51` | `mdbook build docs/book`; `git diff --check` | `book and diff checks passed after selecting top-level switch-branch nested repeat multiple generated spawns with mandatory same-body await_all` |
| `2026-05-17` | `ISF-REPEAT-BODY-CHILD-ACTIVATION.52` | `perl -Iperl -c perl/FSM/Scheduler/ISF/LoweringIR.pm`; `perl -Iperl -c t/1215-isf-spawn-parameter-binding.t`; `perl -Iperl -c t/1305-isf-book-feature-matrix-audit.t`; `perl -Iperl -c t/1307-isf-loop-body-doc-truth-audit.t`; `prove -l t/1215-isf-spawn-parameter-binding.t`; `prove -l t/1215-isf-spawn-parameter-binding.t t/1304-isf-repeat-body-doc-truth-audit.t t/1305-isf-book-feature-matrix-audit.t t/1307-isf-loop-body-doc-truth-audit.t`; `prove -l t/1103-isf-switch-branch-exits.t t/1215-isf-spawn-parameter-binding.t t/1177-isf-do-child-done-pulse.t t/1184-isf-child-transaction-target-boundary.t t/1203-isf-await-sync-clause-boundary.t t/1204-isf-child-composition-clause-boundary.t t/1241-isf-transaction-port-bindings.t t/1242-isf-port-binding-conflict-semantics.t t/1243-isf-port-binding-schedule-report.t t/1247-isf-clock-domain-partition.t t/1304-isf-repeat-body-doc-truth-audit.t t/1305-isf-book-feature-matrix-audit.t t/1307-isf-loop-body-doc-truth-audit.t`; `mdbook build docs/book`; `./bin/ci-regression isf --no-book`; `git diff --check` | `syntax, touched repeat/spawn test (Files=1, Tests=28), touched repeat/spawn/doc checks (Files=4, Tests=354), focused activation/domain/doc suite (Files=13, Tests=396), book build, full ISF gate (Files=227, Tests=1167), and diff check passed` |
| `2026-05-17` | `ISF-REPEAT-BODY-CHILD-ACTIVATION.53` | `mdbook build docs/book`; `git diff --check` | `book and diff checks passed after selecting top-level when-body nested repeat multi-pending await_any with mandatory same-body await_all drain` |
| `2026-05-17` | `ISF-REPEAT-BODY-CHILD-ACTIVATION.54` | `perl -Iperl -c perl/FSM/Scheduler/ISF/LoweringIR.pm`; `perl -Iperl -c t/1215-isf-spawn-parameter-binding.t`; `perl -Iperl -c t/1305-isf-book-feature-matrix-audit.t`; `perl -Iperl -c t/1307-isf-loop-body-doc-truth-audit.t`; `prove -l t/1215-isf-spawn-parameter-binding.t`; `prove -l t/1215-isf-spawn-parameter-binding.t t/1304-isf-repeat-body-doc-truth-audit.t t/1305-isf-book-feature-matrix-audit.t t/1307-isf-loop-body-doc-truth-audit.t`; `prove -l t/1103-isf-switch-branch-exits.t t/1215-isf-spawn-parameter-binding.t t/1177-isf-do-child-done-pulse.t t/1184-isf-child-transaction-target-boundary.t t/1203-isf-await-sync-clause-boundary.t t/1204-isf-child-composition-clause-boundary.t t/1241-isf-transaction-port-bindings.t t/1242-isf-port-binding-conflict-semantics.t t/1243-isf-port-binding-schedule-report.t t/1247-isf-clock-domain-partition.t t/1304-isf-repeat-body-doc-truth-audit.t t/1305-isf-book-feature-matrix-audit.t t/1307-isf-loop-body-doc-truth-audit.t`; `mdbook build docs/book`; `./bin/ci-regression isf --no-book`; `git diff --check` | `syntax, touched repeat/spawn test (Files=1, Tests=29), touched repeat/spawn/doc checks (Files=4, Tests=358), focused activation/domain/doc suite (Files=13, Tests=400), book build, full ISF gate (Files=227, Tests=1171), and diff check passed` |
| `2026-05-17` | `ISF-REPEAT-BODY-CHILD-ACTIVATION.55` | `mdbook build docs/book`; `git diff --check` | `book and diff checks passed after selecting top-level switch-branch nested repeat multi-pending await_any with mandatory same-body await_all drain` |
| `2026-05-17` | `ISF-REPEAT-BODY-CHILD-ACTIVATION.56` | `perl -Iperl -c perl/FSM/Scheduler/ISF/LoweringIR.pm`; `perl -Iperl -c t/1215-isf-spawn-parameter-binding.t`; `perl -Iperl -c t/1305-isf-book-feature-matrix-audit.t`; `perl -Iperl -c t/1307-isf-loop-body-doc-truth-audit.t`; `prove -l t/1215-isf-spawn-parameter-binding.t`; `prove -l t/1215-isf-spawn-parameter-binding.t t/1304-isf-repeat-body-doc-truth-audit.t t/1305-isf-book-feature-matrix-audit.t t/1307-isf-loop-body-doc-truth-audit.t`; `prove -l t/1103-isf-switch-branch-exits.t t/1215-isf-spawn-parameter-binding.t t/1177-isf-do-child-done-pulse.t t/1184-isf-child-transaction-target-boundary.t t/1203-isf-await-sync-clause-boundary.t t/1204-isf-child-composition-clause-boundary.t t/1241-isf-transaction-port-bindings.t t/1242-isf-port-binding-conflict-semantics.t t/1243-isf-port-binding-schedule-report.t t/1247-isf-clock-domain-partition.t t/1304-isf-repeat-body-doc-truth-audit.t t/1305-isf-book-feature-matrix-audit.t t/1307-isf-loop-body-doc-truth-audit.t`; `mdbook build docs/book`; `./bin/ci-regression isf --no-book`; `git diff --check` | `syntax, touched repeat/spawn test (Files=1, Tests=30), touched repeat/spawn/doc checks (Files=4, Tests=362), focused activation/domain/doc suite (Files=13, Tests=404), book build, full ISF gate (Files=227, Tests=1175), and diff check passed` |
| `2026-05-17` | `ISF-REPEAT-BODY-CHILD-ACTIVATION.57` | `mdbook build docs/book`; `git diff --check` | `book and diff checks passed after selecting top-level when-body nested repeat local do while generated nested spawn is pending` |
| `2026-05-17` | `ISF-REPEAT-BODY-CHILD-ACTIVATION.58` | `perl -Iperl -c perl/FSM/Scheduler/ISF/LoweringIR.pm`; `perl -Iperl -c t/1215-isf-spawn-parameter-binding.t`; `perl -Iperl -c t/1305-isf-book-feature-matrix-audit.t`; `perl -Iperl -c t/1307-isf-loop-body-doc-truth-audit.t`; `prove -l t/1215-isf-spawn-parameter-binding.t`; `prove -l t/1215-isf-spawn-parameter-binding.t t/1304-isf-repeat-body-doc-truth-audit.t t/1305-isf-book-feature-matrix-audit.t t/1307-isf-loop-body-doc-truth-audit.t`; `prove -l t/1103-isf-switch-branch-exits.t t/1215-isf-spawn-parameter-binding.t t/1177-isf-do-child-done-pulse.t t/1184-isf-child-transaction-target-boundary.t t/1203-isf-await-sync-clause-boundary.t t/1204-isf-child-composition-clause-boundary.t t/1241-isf-transaction-port-bindings.t t/1242-isf-port-binding-conflict-semantics.t t/1243-isf-port-binding-schedule-report.t t/1247-isf-clock-domain-partition.t t/1304-isf-repeat-body-doc-truth-audit.t t/1305-isf-book-feature-matrix-audit.t t/1307-isf-loop-body-doc-truth-audit.t`; `mdbook build docs/book`; `./bin/ci-regression isf --no-book`; `git diff --check` | `syntax, touched repeat/spawn test (Files=1, Tests=31), touched repeat/spawn/doc checks (Files=4, Tests=368), focused activation/domain/doc suite (Files=13, Tests=410), book build, full ISF gate (Files=227, Tests=1181), and diff check passed` |
| `2026-05-18` | `ISF-REPEAT-BODY-CHILD-ACTIVATION.59` | `mdbook build docs/book`; `git diff --check` | `book and diff checks passed after selecting top-level switch-branch nested repeat local do while generated nested spawn is pending` |
| `2026-05-18` | `ISF-REPEAT-BODY-CHILD-ACTIVATION.60` | `perl -Iperl -c perl/FSM/Scheduler/ISF/LoweringIR.pm`; `perl -Iperl -c t/1215-isf-spawn-parameter-binding.t`; `perl -Iperl -c t/1304-isf-repeat-body-doc-truth-audit.t`; `perl -Iperl -c t/1305-isf-book-feature-matrix-audit.t`; `perl -Iperl -c t/1307-isf-loop-body-doc-truth-audit.t`; `prove -l t/1215-isf-spawn-parameter-binding.t`; `prove -l t/1215-isf-spawn-parameter-binding.t t/1304-isf-repeat-body-doc-truth-audit.t t/1305-isf-book-feature-matrix-audit.t t/1307-isf-loop-body-doc-truth-audit.t`; `prove -l t/1103-isf-switch-branch-exits.t t/1215-isf-spawn-parameter-binding.t t/1177-isf-do-child-done-pulse.t t/1184-isf-child-transaction-target-boundary.t t/1203-isf-await-sync-clause-boundary.t t/1204-isf-child-composition-clause-boundary.t t/1241-isf-transaction-port-bindings.t t/1242-isf-port-binding-conflict-semantics.t t/1243-isf-port-binding-schedule-report.t t/1247-isf-clock-domain-partition.t t/1304-isf-repeat-body-doc-truth-audit.t t/1305-isf-book-feature-matrix-audit.t t/1307-isf-loop-body-doc-truth-audit.t`; `mdbook build docs/book`; `./bin/ci-regression isf --no-book`; `git diff --check` | `syntax, touched repeat/spawn test (Files=1, Tests=32), touched repeat/spawn/doc checks (Files=4, Tests=374), focused activation/domain/doc suite (Files=13, Tests=416), book build, full ISF gate (Files=227, Tests=1187), and diff check passed` |
| `2026-05-18` | `ISF-REPEAT-BODY-CHILD-ACTIVATION.61` | `mdbook build docs/book`; `git diff --check` | `book and diff checks passed after selecting top-level when-body nested repeat generated-child do while generated nested spawn is pending` |
| `2026-05-18` | `ISF-REPEAT-BODY-CHILD-ACTIVATION.62` | `perl -Iperl -c perl/FSM/Scheduler/ISF/LoweringIR.pm`; `perl -Iperl -c t/1215-isf-spawn-parameter-binding.t`; `perl -Iperl -c t/1305-isf-book-feature-matrix-audit.t`; `perl -Iperl -c t/1307-isf-loop-body-doc-truth-audit.t`; `prove -l t/1215-isf-spawn-parameter-binding.t`; `prove -l t/1215-isf-spawn-parameter-binding.t t/1304-isf-repeat-body-doc-truth-audit.t t/1305-isf-book-feature-matrix-audit.t t/1307-isf-loop-body-doc-truth-audit.t`; `prove -l t/1103-isf-switch-branch-exits.t t/1215-isf-spawn-parameter-binding.t t/1177-isf-do-child-done-pulse.t t/1184-isf-child-transaction-target-boundary.t t/1203-isf-await-sync-clause-boundary.t t/1204-isf-child-composition-clause-boundary.t t/1241-isf-transaction-port-bindings.t t/1242-isf-port-binding-conflict-semantics.t t/1243-isf-port-binding-schedule-report.t t/1247-isf-clock-domain-partition.t t/1304-isf-repeat-body-doc-truth-audit.t t/1305-isf-book-feature-matrix-audit.t t/1307-isf-loop-body-doc-truth-audit.t`; `mdbook build docs/book`; `./bin/ci-regression isf --no-book`; `git diff --check` | `syntax, touched repeat/spawn test (Files=1, Tests=33), touched repeat/spawn/doc checks (Files=4, Tests=380), focused activation/domain/doc suite (Files=13, Tests=422), book build, full ISF gate (Files=227, Tests=1193), and diff check passed` |
| `2026-05-18` | `ISF-REPEAT-BODY-CHILD-ACTIVATION.63` | `mdbook build docs/book`; `git diff --check` | `book and diff checks passed after selecting top-level switch-branch nested repeat generated-child do while generated nested spawn is pending` |
| `2026-05-18` | `ISF-REPEAT-BODY-CHILD-ACTIVATION.64` | `perl -Iperl -c perl/FSM/Scheduler/ISF/LoweringIR.pm`; `perl -Iperl -c t/1215-isf-spawn-parameter-binding.t`; `perl -Iperl -c t/1305-isf-book-feature-matrix-audit.t`; `perl -Iperl -c t/1307-isf-loop-body-doc-truth-audit.t`; `prove -l t/1215-isf-spawn-parameter-binding.t`; `prove -l t/1215-isf-spawn-parameter-binding.t t/1304-isf-repeat-body-doc-truth-audit.t t/1305-isf-book-feature-matrix-audit.t t/1307-isf-loop-body-doc-truth-audit.t`; `prove -l t/1103-isf-switch-branch-exits.t t/1215-isf-spawn-parameter-binding.t t/1177-isf-do-child-done-pulse.t t/1184-isf-child-transaction-target-boundary.t t/1203-isf-await-sync-clause-boundary.t t/1204-isf-child-composition-clause-boundary.t t/1241-isf-transaction-port-bindings.t t/1242-isf-port-binding-conflict-semantics.t t/1243-isf-port-binding-schedule-report.t t/1247-isf-clock-domain-partition.t t/1304-isf-repeat-body-doc-truth-audit.t t/1305-isf-book-feature-matrix-audit.t t/1307-isf-loop-body-doc-truth-audit.t`; `mdbook build docs/book`; `./bin/ci-regression isf --no-book`; `git diff --check` | `syntax, touched repeat/spawn test (Files=1, Tests=34), touched repeat/spawn/doc checks (Files=4, Tests=386), focused activation/domain/doc suite (Files=13, Tests=428), book build, full ISF gate (Files=227, Tests=1199), and diff check passed` |
| `2026-05-18` | `ISF-REPEAT-BODY-CHILD-ACTIVATION.65` | `mdbook build docs/book`; `git diff --check` | `book and diff checks passed after selecting top-level when-body nested repeat generated do with static parameter overrides while generated nested spawn is pending` |
| `2026-05-18` | `ISF-REPEAT-BODY-CHILD-ACTIVATION.66` | `perl -Iperl -c perl/FSM/Scheduler/ISF/LoweringIR.pm`; `perl -Iperl -c t/1215-isf-spawn-parameter-binding.t`; `perl -Iperl -c t/1305-isf-book-feature-matrix-audit.t`; `perl -Iperl -c t/1307-isf-loop-body-doc-truth-audit.t`; `prove -l t/1215-isf-spawn-parameter-binding.t`; `prove -l t/1215-isf-spawn-parameter-binding.t t/1304-isf-repeat-body-doc-truth-audit.t t/1305-isf-book-feature-matrix-audit.t t/1307-isf-loop-body-doc-truth-audit.t`; `prove -l t/1103-isf-switch-branch-exits.t t/1215-isf-spawn-parameter-binding.t t/1177-isf-do-child-done-pulse.t t/1184-isf-child-transaction-target-boundary.t t/1203-isf-await-sync-clause-boundary.t t/1204-isf-child-composition-clause-boundary.t t/1241-isf-transaction-port-bindings.t t/1242-isf-port-binding-conflict-semantics.t t/1243-isf-port-binding-schedule-report.t t/1247-isf-clock-domain-partition.t t/1304-isf-repeat-body-doc-truth-audit.t t/1305-isf-book-feature-matrix-audit.t t/1307-isf-loop-body-doc-truth-audit.t`; `mdbook build docs/book`; `./bin/ci-regression isf --no-book`; `git diff --check` | `syntax, touched repeat/spawn test (Files=1, Tests=35), touched repeat/spawn/doc checks (Files=4, Tests=392), focused activation/domain/doc suite (Files=13, Tests=434), book build, full ISF gate (Files=227, Tests=1205), and diff check passed` |
| `2026-05-18` | `ISF-REPEAT-BODY-CHILD-ACTIVATION.67` | `mdbook build docs/book`; `git diff --check` | `book and diff checks passed after selecting top-level switch-branch nested repeat generated do with static parameter overrides while generated nested spawn is pending` |
| `2026-05-18` | `ISF-REPEAT-BODY-CHILD-ACTIVATION.68` | `perl -Iperl -c perl/FSM/Scheduler/ISF/LoweringIR.pm`; `perl -Iperl -c t/1215-isf-spawn-parameter-binding.t`; `perl -Iperl -c t/1305-isf-book-feature-matrix-audit.t`; `perl -Iperl -c t/1307-isf-loop-body-doc-truth-audit.t`; `prove -l t/1215-isf-spawn-parameter-binding.t`; `prove -l t/1215-isf-spawn-parameter-binding.t t/1304-isf-repeat-body-doc-truth-audit.t t/1305-isf-book-feature-matrix-audit.t t/1307-isf-loop-body-doc-truth-audit.t`; `prove -l t/1103-isf-switch-branch-exits.t t/1215-isf-spawn-parameter-binding.t t/1177-isf-do-child-done-pulse.t t/1184-isf-child-transaction-target-boundary.t t/1203-isf-await-sync-clause-boundary.t t/1204-isf-child-composition-clause-boundary.t t/1241-isf-transaction-port-bindings.t t/1242-isf-port-binding-conflict-semantics.t t/1243-isf-port-binding-schedule-report.t t/1247-isf-clock-domain-partition.t t/1304-isf-repeat-body-doc-truth-audit.t t/1305-isf-book-feature-matrix-audit.t t/1307-isf-loop-body-doc-truth-audit.t`; `mdbook build docs/book`; `./bin/ci-regression isf --no-book`; `git diff --check` | `syntax, touched repeat/spawn test (Files=1, Tests=36), touched repeat/spawn/doc checks (Files=4, Tests=398), focused activation/domain/doc suite (Files=13, Tests=440), book build, full ISF gate (Files=227, Tests=1211), and diff check passed` |
| `2026-05-18` | `ISF-REPEAT-BODY-CHILD-ACTIVATION.69` | `mdbook build docs/book`; `git diff --check` | `book and diff checks passed after selecting top-level when-body nested repeat generated do with static parameter overrides and port bindings while generated nested spawn is pending` |
| `2026-05-18` | `ISF-REPEAT-BODY-CHILD-ACTIVATION.70` | `perl -Iperl -c perl/FSM/Scheduler/ISF/LoweringIR.pm`; `perl -Iperl -c t/1215-isf-spawn-parameter-binding.t`; `perl -Iperl -c t/1305-isf-book-feature-matrix-audit.t`; `perl -Iperl -c t/1307-isf-loop-body-doc-truth-audit.t`; `prove -l t/1215-isf-spawn-parameter-binding.t`; `prove -l t/1215-isf-spawn-parameter-binding.t t/1304-isf-repeat-body-doc-truth-audit.t t/1305-isf-book-feature-matrix-audit.t t/1307-isf-loop-body-doc-truth-audit.t`; `prove -l t/1103-isf-switch-branch-exits.t t/1215-isf-spawn-parameter-binding.t t/1177-isf-do-child-done-pulse.t t/1184-isf-child-transaction-target-boundary.t t/1203-isf-await-sync-clause-boundary.t t/1204-isf-child-composition-clause-boundary.t t/1241-isf-transaction-port-bindings.t t/1242-isf-port-binding-conflict-semantics.t t/1243-isf-port-binding-schedule-report.t t/1247-isf-clock-domain-partition.t t/1304-isf-repeat-body-doc-truth-audit.t t/1305-isf-book-feature-matrix-audit.t t/1307-isf-loop-body-doc-truth-audit.t`; `mdbook build docs/book`; `./bin/ci-regression isf --no-book`; `git diff --check` | `syntax, touched repeat/spawn test (Files=1, Tests=37), touched repeat/spawn/doc checks (Files=4, Tests=404), focused activation/domain/doc suite (Files=13, Tests=446), book build, full ISF gate (Files=227, Tests=1217), and diff check passed` |
| `2026-05-18` | `ISF-REPEAT-BODY-CHILD-ACTIVATION.71` | `mdbook build docs/book`; `git diff --check` | `book and diff checks passed after selecting top-level switch-branch nested repeat generated do with static parameter overrides and port bindings while generated nested spawn is pending` |
| `2026-05-18` | `ISF-REPEAT-BODY-CHILD-ACTIVATION.72` | `perl -Iperl -c perl/FSM/Scheduler/ISF/LoweringIR.pm`; `perl -Iperl -c t/1215-isf-spawn-parameter-binding.t`; `perl -Iperl -c t/1305-isf-book-feature-matrix-audit.t`; `perl -Iperl -c t/1307-isf-loop-body-doc-truth-audit.t`; `prove -l t/1215-isf-spawn-parameter-binding.t`; `prove -l t/1215-isf-spawn-parameter-binding.t t/1304-isf-repeat-body-doc-truth-audit.t t/1305-isf-book-feature-matrix-audit.t t/1307-isf-loop-body-doc-truth-audit.t`; `prove -l t/1103-isf-switch-branch-exits.t t/1215-isf-spawn-parameter-binding.t t/1177-isf-do-child-done-pulse.t t/1184-isf-child-transaction-target-boundary.t t/1203-isf-await-sync-clause-boundary.t t/1204-isf-child-composition-clause-boundary.t t/1241-isf-transaction-port-bindings.t t/1242-isf-port-binding-conflict-semantics.t t/1243-isf-port-binding-schedule-report.t t/1247-isf-clock-domain-partition.t t/1304-isf-repeat-body-doc-truth-audit.t t/1305-isf-book-feature-matrix-audit.t t/1307-isf-loop-body-doc-truth-audit.t`; `mdbook build docs/book`; `./bin/ci-regression isf --no-book`; `git diff --check` | `syntax, touched repeat/spawn test (Files=1, Tests=38), touched repeat/spawn/doc checks (Files=4, Tests=410), focused activation/domain/doc suite (Files=13, Tests=452), book build, full ISF gate (Files=227, Tests=1223), and diff check passed` |
| `2026-05-18` | `ISF-REPEAT-BODY-CHILD-ACTIVATION.73` | `mdbook build docs/book`; `git diff --check` | `book and diff checks passed after selecting top-level when-body nested repeat generated do same-domain metadata while generated nested spawn is pending` |
| `2026-05-18` | `ISF-REPEAT-BODY-CHILD-ACTIVATION.74` | `perl -Iperl -c perl/FSM/Scheduler/ISF/LoweringIR.pm`; `perl -Iperl -c t/1215-isf-spawn-parameter-binding.t`; `perl -Iperl -c t/1305-isf-book-feature-matrix-audit.t`; `perl -Iperl -c t/1307-isf-loop-body-doc-truth-audit.t`; `prove -l t/1215-isf-spawn-parameter-binding.t`; `prove -l t/1307-isf-loop-body-doc-truth-audit.t`; `prove -l t/1215-isf-spawn-parameter-binding.t t/1304-isf-repeat-body-doc-truth-audit.t t/1305-isf-book-feature-matrix-audit.t t/1307-isf-loop-body-doc-truth-audit.t`; `prove -l t/1103-isf-switch-branch-exits.t t/1215-isf-spawn-parameter-binding.t t/1177-isf-do-child-done-pulse.t t/1184-isf-child-transaction-target-boundary.t t/1203-isf-await-sync-clause-boundary.t t/1204-isf-child-composition-clause-boundary.t t/1241-isf-transaction-port-bindings.t t/1242-isf-port-binding-conflict-semantics.t t/1243-isf-port-binding-schedule-report.t t/1247-isf-clock-domain-partition.t t/1304-isf-repeat-body-doc-truth-audit.t t/1305-isf-book-feature-matrix-audit.t t/1307-isf-loop-body-doc-truth-audit.t`; `mdbook build docs/book`; `./bin/ci-regression isf --no-book`; `git diff --check` | `syntax, touched repeat/spawn test (Files=1, Tests=39), loop-body doc audit (Files=1, Tests=99), touched repeat/spawn/doc checks (Files=4, Tests=416), focused activation/domain/doc suite (Files=13, Tests=458), book build, full ISF gate (Files=227, Tests=1229), and diff check passed` |
| `2026-05-18` | `ISF-REPEAT-BODY-CHILD-ACTIVATION.75` | `mdbook build docs/book`; `git diff --check` | `book and diff checks passed after selecting top-level switch-branch nested repeat generated do same-domain metadata while generated nested spawn is pending` |
| `2026-05-18` | `ISF-REPEAT-BODY-CHILD-ACTIVATION.76` | `perl -Iperl -c perl/FSM/Scheduler/ISF/LoweringIR.pm`; `perl -Iperl -c t/1215-isf-spawn-parameter-binding.t`; `perl -Iperl -c t/1305-isf-book-feature-matrix-audit.t`; `perl -Iperl -c t/1307-isf-loop-body-doc-truth-audit.t`; `prove -l t/1215-isf-spawn-parameter-binding.t`; `prove -l t/1305-isf-book-feature-matrix-audit.t`; `prove -l t/1307-isf-loop-body-doc-truth-audit.t`; `prove -l t/1215-isf-spawn-parameter-binding.t t/1304-isf-repeat-body-doc-truth-audit.t t/1305-isf-book-feature-matrix-audit.t t/1307-isf-loop-body-doc-truth-audit.t`; `prove -l t/1103-isf-switch-branch-exits.t t/1215-isf-spawn-parameter-binding.t t/1177-isf-do-child-done-pulse.t t/1184-isf-child-transaction-target-boundary.t t/1203-isf-await-sync-clause-boundary.t t/1204-isf-child-composition-clause-boundary.t t/1241-isf-transaction-port-bindings.t t/1242-isf-port-binding-conflict-semantics.t t/1243-isf-port-binding-schedule-report.t t/1247-isf-clock-domain-partition.t t/1304-isf-repeat-body-doc-truth-audit.t t/1305-isf-book-feature-matrix-audit.t t/1307-isf-loop-body-doc-truth-audit.t`; `mdbook build docs/book`; `./bin/ci-regression isf --no-book`; `git diff --check` | `syntax, touched repeat/spawn test (Files=1, Tests=40), book feature audit (Files=1, Tests=140), loop-body doc audit (Files=1, Tests=102), touched repeat/spawn/doc checks (Files=4, Tests=422), focused activation/domain/doc suite (Files=13, Tests=464), book build, full ISF gate (Files=227, Tests=1235), and diff check passed` |

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
| `ISF-REPEAT-BODY-CHILD-ACTIVATION.31` | `ISF-REPEAT-BODY-CHILD-ACTIVATION.31: select switch repeat generated do params` | `selected switch-contained repeat generated do static params` |
| `ISF-REPEAT-BODY-CHILD-ACTIVATION.32` | `ISF-REPEAT-BODY-CHILD-ACTIVATION.32: implement switch repeat generated do params` | `switch-contained repeat generated do static params shipped` |
| `ISF-REPEAT-BODY-CHILD-ACTIVATION.33` | `ISF-REPEAT-BODY-CHILD-ACTIVATION.33: select when repeat generated do bindings` | `selected when-contained repeat generated do bindings` |
| `ISF-REPEAT-BODY-CHILD-ACTIVATION.34` | `ISF-REPEAT-BODY-CHILD-ACTIVATION.34: implement when repeat generated do bindings` | `when-contained repeat generated do bindings shipped` |
| `ISF-REPEAT-BODY-CHILD-ACTIVATION.35` | `ISF-REPEAT-BODY-CHILD-ACTIVATION.35: select switch repeat generated do bindings` | `selected switch-contained repeat generated do bindings` |
| `ISF-REPEAT-BODY-CHILD-ACTIVATION.36` | `ISF-REPEAT-BODY-CHILD-ACTIVATION.36: implement switch repeat generated do bindings` | `switch-contained repeat generated do bindings shipped` |
| `ISF-REPEAT-BODY-CHILD-ACTIVATION.37` | `ISF-REPEAT-BODY-CHILD-ACTIVATION.37: select when repeat generated do domains` | `selected when-contained repeat generated do same-domain metadata` |
| `ISF-REPEAT-BODY-CHILD-ACTIVATION.38` | `ISF-REPEAT-BODY-CHILD-ACTIVATION.38: implement when repeat generated do domains` | `when-contained repeat generated do same-domain metadata shipped` |
| `ISF-REPEAT-BODY-CHILD-ACTIVATION.39` | `ISF-REPEAT-BODY-CHILD-ACTIVATION.39: select switch repeat generated do domains` | `selected switch-contained repeat generated do same-domain metadata` |
| `ISF-REPEAT-BODY-CHILD-ACTIVATION.40` | `ISF-REPEAT-BODY-CHILD-ACTIVATION.40: implement switch repeat generated do domains` | `switch-contained repeat generated do same-domain metadata shipped` |
| `ISF-REPEAT-BODY-CHILD-ACTIVATION.41` | `ISF-REPEAT-BODY-CHILD-ACTIVATION.41: select when repeat spawn await_all` | `selected when-contained repeat single spawn with same-body await_all` |
| `ISF-REPEAT-BODY-CHILD-ACTIVATION.42` | `ISF-REPEAT-BODY-CHILD-ACTIVATION.42: implement when repeat spawn await_all` | `when-contained repeat single spawn with same-body await_all shipped` |
| `ISF-REPEAT-BODY-CHILD-ACTIVATION.43` | `ISF-REPEAT-BODY-CHILD-ACTIVATION.43: select switch repeat spawn await_all` | `selected switch-contained repeat single spawn with same-body await_all` |
| `ISF-REPEAT-BODY-CHILD-ACTIVATION.44` | `ISF-REPEAT-BODY-CHILD-ACTIVATION.44: implement switch repeat spawn await_all` | `switch-contained repeat single spawn with same-body await_all shipped` |
| `ISF-REPEAT-BODY-CHILD-ACTIVATION.45` | `ISF-REPEAT-BODY-CHILD-ACTIVATION.45: select when repeat spawn await_any` | `selected when-contained repeat single spawn with same-body await_any` |
| `ISF-REPEAT-BODY-CHILD-ACTIVATION.46` | `ISF-REPEAT-BODY-CHILD-ACTIVATION.46: implement when repeat spawn await_any` | `when-contained repeat single spawn with same-body await_any shipped` |
| `ISF-REPEAT-BODY-CHILD-ACTIVATION.47` | `ISF-REPEAT-BODY-CHILD-ACTIVATION.47: select switch repeat spawn await_any` | `selected switch-contained repeat single spawn with same-body await_any` |
| `ISF-REPEAT-BODY-CHILD-ACTIVATION.48` | `ISF-REPEAT-BODY-CHILD-ACTIVATION.48: implement switch repeat spawn await_any` | `switch-contained repeat single spawn with same-body await_any shipped` |
| `ISF-REPEAT-BODY-CHILD-ACTIVATION.49` | `ISF-REPEAT-BODY-CHILD-ACTIVATION.49: select when repeat multiple spawns` | `selected when-contained repeat multiple generated spawns with same-body await_all` |
| `ISF-REPEAT-BODY-CHILD-ACTIVATION.50` | `ISF-REPEAT-BODY-CHILD-ACTIVATION.50: implement when repeat multiple spawns` | `when-contained repeat multiple generated spawns with same-body await_all shipped` |
| `ISF-REPEAT-BODY-CHILD-ACTIVATION.51` | `ISF-REPEAT-BODY-CHILD-ACTIVATION.51: select switch repeat multiple spawns` | `selected switch-contained repeat multiple generated spawns with same-body await_all` |
| `ISF-REPEAT-BODY-CHILD-ACTIVATION.52` | `ISF-REPEAT-BODY-CHILD-ACTIVATION.52: implement switch repeat multiple spawns` | `switch-contained repeat multiple generated spawns with same-body await_all shipped` |
| `ISF-REPEAT-BODY-CHILD-ACTIVATION.53` | `ISF-REPEAT-BODY-CHILD-ACTIVATION.53: select when repeat await_any drain` | `selected when-contained repeat multi-pending await_any with mandatory same-body await_all drain` |
| `ISF-REPEAT-BODY-CHILD-ACTIVATION.54` | `ISF-REPEAT-BODY-CHILD-ACTIVATION.54: implement when repeat await_any drain` | `when-contained repeat multi-pending await_any with mandatory same-body await_all drain shipped` |
| `ISF-REPEAT-BODY-CHILD-ACTIVATION.55` | `ISF-REPEAT-BODY-CHILD-ACTIVATION.55: select switch repeat await_any drain` | `selected switch-contained repeat multi-pending await_any with mandatory same-body await_all drain` |
| `ISF-REPEAT-BODY-CHILD-ACTIVATION.56` | `ISF-REPEAT-BODY-CHILD-ACTIVATION.56: implement switch repeat await_any drain` | `switch-contained repeat multi-pending await_any with mandatory same-body await_all drain shipped` |
| `ISF-REPEAT-BODY-CHILD-ACTIVATION.57` | `ISF-REPEAT-BODY-CHILD-ACTIVATION.57: select when repeat do while spawn pending` | `selected when-contained local do while generated nested spawn is pending` |
| `ISF-REPEAT-BODY-CHILD-ACTIVATION.58` | `ISF-REPEAT-BODY-CHILD-ACTIVATION.58: implement when repeat do while spawn pending` | `when-contained local do while generated nested spawn is pending shipped` |
| `ISF-REPEAT-BODY-CHILD-ACTIVATION.59` | `ISF-REPEAT-BODY-CHILD-ACTIVATION.59: select switch repeat do while spawn pending` | `selected switch-contained local do while generated nested spawn is pending` |
| `ISF-REPEAT-BODY-CHILD-ACTIVATION.60` | `ISF-REPEAT-BODY-CHILD-ACTIVATION.60: implement switch repeat do while spawn pending` | `switch-contained local do while generated nested spawn is pending shipped` |
| `ISF-REPEAT-BODY-CHILD-ACTIVATION.61` | `ISF-REPEAT-BODY-CHILD-ACTIVATION.61: select when repeat generated do while spawn pending` | `selected when-contained generated-child do while generated nested spawn is pending` |
| `ISF-REPEAT-BODY-CHILD-ACTIVATION.62` | `ISF-REPEAT-BODY-CHILD-ACTIVATION.62: implement when repeat generated do while spawn pending` | `when-contained generated-child do while generated nested spawn is pending shipped` |
| `ISF-REPEAT-BODY-CHILD-ACTIVATION.63` | `ISF-REPEAT-BODY-CHILD-ACTIVATION.63: select switch repeat generated do while spawn pending` | `selected switch-contained generated-child do while generated nested spawn is pending` |
| `ISF-REPEAT-BODY-CHILD-ACTIVATION.64` | `ISF-REPEAT-BODY-CHILD-ACTIVATION.64: implement switch repeat generated do while spawn pending` | `switch-contained generated-child do while generated nested spawn is pending shipped` |
| `ISF-REPEAT-BODY-CHILD-ACTIVATION.65` | `ISF-REPEAT-BODY-CHILD-ACTIVATION.65: select when repeat parameterized do while spawn pending` | `selected when-contained generated static-parameter do while generated nested spawn is pending` |
| `ISF-REPEAT-BODY-CHILD-ACTIVATION.66` | `ISF-REPEAT-BODY-CHILD-ACTIVATION.66: implement when repeat parameterized do while spawn pending` | `when-contained generated static-parameter do while generated nested spawn is pending shipped` |
| `ISF-REPEAT-BODY-CHILD-ACTIVATION.67` | `ISF-REPEAT-BODY-CHILD-ACTIVATION.67: select switch repeat parameterized do while spawn pending` | `selected switch-contained generated static-parameter do while generated nested spawn is pending` |
| `ISF-REPEAT-BODY-CHILD-ACTIVATION.68` | `ISF-REPEAT-BODY-CHILD-ACTIVATION.68: implement switch repeat parameterized do while spawn pending` | `switch-contained generated static-parameter do while generated nested spawn is pending shipped` |
| `ISF-REPEAT-BODY-CHILD-ACTIVATION.69` | `ISF-REPEAT-BODY-CHILD-ACTIVATION.69: select when repeat bound do while spawn pending` | `selected when-contained generated bound do while generated nested spawn is pending` |
| `ISF-REPEAT-BODY-CHILD-ACTIVATION.70` | `ISF-REPEAT-BODY-CHILD-ACTIVATION.70: implement when repeat bound do while spawn pending` | `when-contained generated bound do while generated nested spawn is pending shipped` |
| `ISF-REPEAT-BODY-CHILD-ACTIVATION.71` | `ISF-REPEAT-BODY-CHILD-ACTIVATION.71: select switch repeat bound do while spawn pending` | `selected switch-contained generated bound do while generated nested spawn is pending` |
| `ISF-REPEAT-BODY-CHILD-ACTIVATION.72` | `ISF-REPEAT-BODY-CHILD-ACTIVATION.72: implement switch repeat bound do while spawn pending` | `switch-contained generated bound do while generated nested spawn is pending shipped` |
| `ISF-REPEAT-BODY-CHILD-ACTIVATION.73` | `ISF-REPEAT-BODY-CHILD-ACTIVATION.73: select when repeat domain do while spawn pending` | `selected when-contained generated same-domain do while generated nested spawn is pending` |
| `ISF-REPEAT-BODY-CHILD-ACTIVATION.74` | `ISF-REPEAT-BODY-CHILD-ACTIVATION.74: implement when repeat domain do while spawn pending` | `when-contained generated same-domain do while generated nested spawn is pending shipped` |
| `ISF-REPEAT-BODY-CHILD-ACTIVATION.75` | `ISF-REPEAT-BODY-CHILD-ACTIVATION.75: select switch repeat domain do while spawn pending` | `selected switch-contained generated same-domain do while generated nested spawn is pending` |
| `ISF-REPEAT-BODY-CHILD-ACTIVATION.76` | `ISF-REPEAT-BODY-CHILD-ACTIVATION.76: implement switch repeat domain do while spawn pending` | `switch-contained generated same-domain do while generated nested spawn is pending shipped` |

## Changelog

- `2026-05-18`: Shipped top-level switch-branch nested repeat generated
  blocking `(do child (params ...) [(bind ...)] (domain NAME))` with static
  parameter overrides, optional input/output port bindings, and declared
  same-domain metadata while generated nested spawns are pending before a
  later same-body `(await_all done)` drain. The generated do site preserves
  static generated-top parameter binding, optional generated-top binding
  handoffs, declared generated-composition and schedule-report clock-domain
  ownership metadata, and its own fresh done handoff while leaving the
  pending generated-spawn done set live for the later drain. `await_any`
  around the do, new spawn after the do before drain, cross-domain
  activation, deeper branch/loop nesting, and broader outstanding-child
  semantics remain fail-closed. Leaf `.77` is now the next selection
  frontier.
- `2026-05-18`: Selected top-level switch-branch nested repeat generated
  blocking `(do child (params ...) [(bind ...)] (domain NAME))` with static
  parameter overrides, optional input/output port bindings, and declared
  same-domain metadata while generated nested spawns are pending before a
  later same-body `(await_all done)` drain. The selected implementation must
  preserve static generated-top parameter binding, optional generated-top
  binding handoffs, generated-composition and clock-domain report ownership
  metadata, and the pending generated-spawn done set until the later drain.
  The domain annotation remains metadata only; `await_any` around the do, new
  spawn after the do before drain, cross-domain activation, deeper
  branch/loop nesting, and broader outstanding-child semantics remain
  deferred. Leaf `.76` is now the implementation frontier.
- `2026-05-18`: Shipped top-level when-body nested repeat generated
  blocking `(do child (params ...) [(bind ...)] (domain NAME))` with static
  parameter overrides, optional input/output port bindings, and declared
  same-domain metadata while generated nested spawns are pending before a
  later same-body `(await_all done)` drain. The generated do site preserves
  static generated-top parameter binding, optional generated-top binding
  handoffs, declared generated-composition and schedule-report clock-domain
  ownership metadata, and its own fresh done handoff while leaving the
  pending generated-spawn done set live for the later drain. The
  switch-contained domain analogue, `await_any` around the do, new spawn
  after the do before drain, cross-domain activation, deeper branch/loop
  nesting, and broader outstanding-child semantics remain fail-closed. Leaf
  `.75` is now the next selection frontier.
- `2026-05-18`: Selected top-level when-body nested repeat generated blocking
  `(do child (params ...) [(bind ...)] (domain NAME))` with static parameter
  overrides, optional input/output port bindings, and declared same-domain
  metadata while generated nested spawns are pending before a later same-body
  `(await_all done)` drain. The selected implementation must preserve static
  generated-top parameter binding, optional generated-top binding handoffs,
  generated-composition and clock-domain report ownership metadata, and the
  pending generated-spawn done set until the later drain. The switch-contained
  domain analogue, `await_any` around the do, new spawn after the do before
  drain, cross-domain activation, deeper branch/loop nesting, and broader
  outstanding-child semantics remain deferred. Leaf `.74` is now the
  implementation frontier.
- `2026-05-18`: Shipped top-level switch-branch nested repeat generated
  blocking `(do child (params ...) (bind ...))` with static parameter
  overrides and input/output port bindings while generated nested spawns are
  pending before a later same-body `(await_all done)` drain. The generated do
  site preserves static generated-top parameter binding, wires generated-top
  binding handoffs for that lexical do instance, waits for its deterministic
  generated do instance's fresh done handoff, and leaves the pending
  generated-spawn done set live for the later drain. Domain metadata on that
  do, `await_any` around the do, new spawn after the do before drain,
  cross-domain activation, deeper branch/loop nesting, and broader
  outstanding-child semantics remain fail-closed. Leaf `.73` is now the next
  selection frontier.
- `2026-05-18`: Selected top-level switch-branch nested repeat generated
  blocking `(do child (params ...) (bind ...))` with static parameter
  overrides and input/output port bindings while generated nested spawns are
  pending before a later same-body `(await_all done)` drain. The selected
  implementation must preserve static generated-top parameter binding and
  generated-top binding handoffs on the generated do instance while leaving
  the generated-spawn done set live for the later drain. Domain metadata on
  that do, `await_any` around the do, new spawn after the do before drain,
  cross-domain activation, deeper branch/loop nesting, and broader
  outstanding-child semantics remain deferred. Leaf `.72` is now the
  implementation frontier.
- `2026-05-18`: Shipped top-level when-body nested repeat generated blocking
  `(do child (params ...) (bind ...))` with static parameter overrides and
  input/output port bindings while generated nested spawns are pending before
  a later same-body `(await_all done)` drain. The generated do site preserves
  static generated-top parameter binding, wires generated-top binding
  handoffs for that lexical do instance, waits for its deterministic
  generated do instance's fresh done handoff, and leaves the pending
  generated-spawn done set live for the later drain. Domain metadata on that
  do, the switch-contained bound analogue, `await_any` around the do, new
  spawn after the do before drain, cross-domain activation, deeper branch/loop
  nesting, and broader outstanding-child semantics remain fail-closed. Leaf
  `.71` is now the next selection frontier.
- `2026-05-18`: Selected top-level when-body nested repeat generated blocking
  `(do child (params ...) (bind ...))` with static parameter overrides and
  input/output port bindings while generated nested spawns are pending before
  a later same-body `(await_all done)` drain. The selected implementation must
  preserve static generated-top parameter binding and generated-top binding
  handoffs on the generated do instance while leaving the generated-spawn done
  set live for the later drain. Domain metadata on that do, the
  switch-contained bound analogue, `await_any` around the do, new spawn after
  the do before drain, cross-domain activation, deeper branch/loop nesting,
  and broader outstanding-child semantics remain deferred. Leaf `.70` is now
  the implementation frontier.
- `2026-05-18`: Shipped top-level switch-branch nested repeat generated
  blocking `(do child (params ...))` with static parameter overrides while
  generated nested spawns are pending before a later same-body
  `(await_all done)` drain. The generated do site preserves static
  generated-top parameter binding, waits for its deterministic generated do
  instance's fresh done handoff, and leaves the pending generated-spawn done
  set live for the later drain. Bind/domain subclauses on that do,
  `await_any` around the do, new spawn after the do before drain,
  cross-domain activation, deeper branch/loop nesting, and broader
  outstanding-child semantics remain fail-closed. Leaf `.69` is now the next
  selection frontier.
- `2026-05-18`: Selected top-level switch-branch nested repeat generated
  blocking `(do child (params ...))` with static parameter overrides while
  generated nested spawns are pending before a later same-body
  `(await_all done)` drain, opened `.68` as the implementation frontier, and
  kept bind/domain subclauses on that do, `await_any` around the do, new spawn
  after the do before drain, cross-domain activation, deeper branch/loop
  nesting, and broader outstanding-child semantics deferred.
- `2026-05-18`: Shipped top-level when-body nested repeat generated blocking
  `(do child (params ...))` with static parameter overrides while generated
  nested spawns are pending before a mandatory later same-body
  `(await_all done)` drain, opened `.67` as the next selection-only frontier,
  and kept bind/domain subclauses on that do, the switch-contained analogue,
  `await_any` around the do, new nested spawn after the do before drain,
  cross-domain activation, deeper branch/loop nesting, and broader
  outstanding-child semantics fail-closed.
- `2026-05-18`: Selected top-level when-body nested repeat generated
  blocking `(do child (params ...))` with static parameter overrides while
  generated nested spawns are pending before a later same-body
  `(await_all done)` drain, opened `.66` as the implementation frontier, and
  kept bind/domain subclauses on that do, the switch-contained analogue,
  `await_any` around the do, new spawn after the do before drain, cross-domain
  activation, deeper branch/loop nesting, and broader outstanding-child
  semantics deferred.
- `2026-05-18`: Shipped top-level switch-branch nested repeat
  generated-child plain `do` while generated nested spawns are pending before
  a mandatory later same-body `(await_all done)` drain, opened `.65` as the
  next selection-only frontier, and kept parameterized/bound/domain-qualified
  generated do while pending, `await_any` around the do, new nested spawn
  after the do before the drain, cross-domain activation, deeper branch/loop
  nesting, and broader outstanding-child semantics fail-closed.
- `2026-05-18`: Selected top-level switch-branch nested repeat
  generated-child plain `do` while generated nested spawns are pending before
  a later same-body `(await_all done)` drain, opened `.64` as the
  implementation frontier, and kept parameterized/bound/domain-qualified
  generated do while pending, `await_any` around the do, new spawn after the
  do before drain, cross-domain activation, deeper branch/loop nesting, and
  broader outstanding-child semantics deferred.
- `2026-05-18`: Shipped top-level when-body nested repeat generated-child
  plain `do` while generated nested spawns are pending before a mandatory
  later same-body `(await_all done)` drain, opened `.63` as the next
  selection-only frontier, and kept parameterized/bound/domain-qualified
  generated do while pending, switch-contained generated-child do while
  pending, `await_any` around the do, new nested spawn after the do before the
  drain, cross-domain activation, deeper branch/loop nesting, and broader
  outstanding-child semantics fail-closed.
- `2026-05-18`: Shipped top-level switch-branch nested repeat local `do` while
  generated nested spawns are pending before a mandatory later same-body
  `(await_all done)` drain, opened `.61` as the next selection-only frontier,
  and kept generated do while pending, `await_any` around the local do, new
  nested spawn after the local do before drain, cross-domain activation,
  deeper branch/loop nesting, and broader outstanding-child semantics
  fail-closed.
- `2026-05-18`: Selected top-level when-body nested repeat generated-child
  plain `do` while generated nested spawns are pending before a later
  same-body `(await_all done)` drain, opened `.62` as the implementation
  frontier, and kept parameterized/bound/domain-qualified generated do while
  pending, switch-contained analogue, `await_any` around the do, new spawn
  after the do before drain, cross-domain activation, deeper branch/loop
  nesting, and broader outstanding-child semantics deferred.
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
- `2026-05-18`: Selected top-level switch-branch nested repeat local `do`
  while generated nested spawn is pending as the next bounded implementation
  subset.
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
- `2026-05-17`: Selected top-level switch-branch nested repeat generated
  `do` with static parameter overrides as the next bounded nested generated-do
  subset.
- `2026-05-17`: Shipped top-level switch-branch nested repeat generated `do`
  with static parameter overrides, while keeping bind/domain metadata, spawn
  nesting, deeper branch/loop nesting, cross-domain activation, and broader
  outstanding-child semantics fail-closed.
- `2026-05-17`: Selected top-level when-body nested repeat generated `do`
  with static parameter overrides and port bindings as the next bounded
  nested generated-do subset.
- `2026-05-17`: Shipped top-level when-body nested repeat generated `do`
  with static parameter overrides and port bindings, while keeping domain
  metadata, switch-contained bound nested `do`, spawn nesting, deeper
  branch/loop nesting, cross-domain activation, and broader outstanding-child
  semantics fail-closed.
- `2026-05-17`: Selected top-level switch-branch nested repeat generated `do`
  with static parameter overrides and port bindings as the next bounded
  nested generated-do subset.
- `2026-05-17`: Shipped top-level switch-branch nested repeat generated `do`
  with static parameter overrides and port bindings, while keeping domain
  metadata, spawn nesting, deeper branch/loop nesting, cross-domain
  activation, and broader outstanding-child semantics fail-closed.
- `2026-05-17`: Selected top-level when-body nested repeat generated `do`
  same-domain metadata as the next bounded nested generated-do subset.
- `2026-05-17`: Shipped top-level when-body nested repeat generated `do`
  same-domain metadata, while keeping switch-contained domain metadata, spawn
  nesting, deeper branch/loop nesting, cross-domain activation, and broader
  outstanding-child semantics fail-closed.
- `2026-05-17`: Selected top-level switch-branch nested repeat generated `do`
  same-domain metadata as the next bounded nested generated-do subset.
- `2026-05-17`: Shipped top-level switch-branch nested repeat generated `do`
  same-domain metadata, while keeping spawn nesting, deeper branch/loop
  nesting, cross-domain activation, and broader outstanding-child semantics
  fail-closed.
- `2026-05-17`: Selected top-level when-body nested repeat single generated
  spawn with same-body `await_all` as the next bounded spawn-nesting subset.
- `2026-05-17`: Shipped top-level when-body nested repeat single generated
  spawn with same-body `await_all`, while keeping `await_any`, multiple
  pending nested spawns, switch-contained spawn nesting, `do` while nested
  spawn is pending, cross-domain activation, deeper branch/loop nesting, and
  broader outstanding-child semantics fail-closed.
- `2026-05-17`: Selected top-level switch-branch nested repeat single
  generated spawn with same-body `await_all` as the next bounded
  spawn-nesting subset.
- `2026-05-17`: Shipped top-level switch-branch nested repeat single
  generated spawn with same-body `await_all`, while keeping `await_any`,
  multiple pending nested spawns, `do` while nested spawn is pending,
  cross-domain activation, deeper branch/loop nesting, and broader
  outstanding-child semantics fail-closed.
- `2026-05-17`: Selected top-level when-body nested repeat single generated
  spawn with same-body single-pending `await_any` as the next bounded
  spawn-nesting subset, while keeping multiple pending nested spawns,
  switch-contained `await_any`, `do` while nested spawn is pending,
  cross-domain activation, deeper branch/loop nesting, and broader
  outstanding-child semantics deferred.
- `2026-05-17`: Shipped top-level when-body nested repeat single generated
  spawn with same-body single-pending `await_any`, while keeping multiple
  pending nested spawns, switch-contained `await_any`, `do` while nested spawn
  is pending, cross-domain activation, deeper branch/loop nesting, and broader
  outstanding-child semantics fail-closed.
- `2026-05-17`: Selected top-level switch-branch nested repeat single
  generated spawn with same-body single-pending `await_any` as the next
  bounded spawn-nesting subset, while keeping multiple pending nested spawns,
  `do` while nested spawn is pending, cross-domain activation, deeper
  branch/loop nesting, and broader outstanding-child semantics deferred.
- `2026-05-17`: Shipped top-level switch-branch nested repeat single
  generated spawn with same-body single-pending `await_any`, while keeping
  multiple pending nested spawns, `do` while nested spawn is pending,
  cross-domain activation, deeper branch/loop nesting, and broader
  outstanding-child semantics fail-closed.
- `2026-05-17`: Selected top-level when-body nested repeat multiple generated
  spawns with mandatory same-body `await_all` as the next bounded
  spawn-nesting subset, while keeping nested `await_any` for multiple pending
  children, switch-contained multiple nested spawns, `do` while nested spawn
  is pending, cross-domain activation, deeper branch/loop nesting, and broader
  outstanding-child semantics deferred.
- `2026-05-17`: Shipped top-level when-body nested repeat multiple generated
  spawns with mandatory same-body `await_all`, while keeping nested
  `await_any` for multiple pending children, switch-contained multiple nested
  spawns, `do` while nested spawn is pending, cross-domain activation, deeper
  branch/loop nesting, and broader outstanding-child semantics fail-closed.
- `2026-05-17`: Selected top-level switch-branch nested repeat multiple
  generated spawns with mandatory same-body `await_all` as the next bounded
  spawn-nesting subset, while keeping nested `await_any` for multiple pending
  children, `do` while nested spawn is pending, cross-domain activation,
  deeper branch/loop nesting, and broader outstanding-child semantics
  deferred.
- `2026-05-17`: Shipped top-level switch-branch nested repeat multiple
  generated spawns with mandatory same-body `await_all`, while keeping nested
  `await_any` for multiple pending children, `do` while nested spawn is
  pending, cross-domain activation, deeper branch/loop nesting, and broader
  outstanding-child semantics fail-closed.
- `2026-05-17`: Opened leaf `.53` to select the next bounded repeat-body child
  activation subset before any further implementation.
- `2026-05-17`: Selected top-level when-body nested repeat multi-pending
  `await_any` with mandatory same-body `await_all` drain as the next bounded
  implementation subset, while keeping switch-contained multi-pending
  `await_any`, `do` while nested spawn is pending, cross-domain activation,
  deeper branch/loop nesting, and broader outstanding-child semantics
  deferred.
- `2026-05-17`: Shipped top-level when-body nested repeat multi-pending
  `await_any` with mandatory same-body `await_all` drain, while keeping
  switch-contained multi-pending `await_any`, `do` while nested spawn is
  pending, cross-domain activation, deeper branch/loop nesting, and broader
  outstanding-child semantics fail-closed.
- `2026-05-17`: Opened leaf `.55` to select the next bounded repeat-body child
  activation subset before any further implementation.
- `2026-05-17`: Selected top-level switch-branch nested repeat multi-pending
  `await_any` with mandatory same-body `await_all` drain as the next bounded
  implementation subset, while keeping `do` while nested spawn is pending,
  cross-domain activation, deeper branch/loop nesting, and broader
  outstanding-child semantics deferred.
- `2026-05-17`: Shipped top-level switch-branch nested repeat multi-pending
  `await_any` with mandatory same-body `await_all` drain, while keeping `do`
  while nested spawn is pending, cross-domain activation, deeper branch/loop
  nesting, and broader outstanding-child semantics fail-closed.
- `2026-05-17`: Opened leaf `.57` to select the next bounded repeat-body child
  activation subset before any further implementation.
- `2026-05-17`: Selected top-level when-body nested repeat local `do` while a
  generated nested spawn is pending as the next bounded implementation subset,
  while keeping generated `do` while spawn pending, the switch-contained
  analogue, `await_any` before the do, new spawn after the do before drain,
  cross-domain activation, deeper branch/loop nesting, and broader
  outstanding-child semantics deferred.
- `2026-05-17`: Shipped top-level when-body nested repeat local `do` while a
  generated nested spawn is pending, while keeping generated `do` while spawn
  pending, the switch-contained analogue, `await_any` before or after the do,
  new spawn after the do before drain, cross-domain activation, deeper
  branch/loop nesting, and broader outstanding-child semantics fail-closed.
