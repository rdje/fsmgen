# AXI IAL2 Manager Post Dynamic Read-Data Next Slice Selection

Status: selector for `IAL2-FEATURE-COMPLETENESS-FRONTIER.235` on
2026-06-22.

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.235`

## Decision

Select `IAL2-FEATURE-COMPLETENESS-FRONTIER.236`, AXI manager focused-suite
cost cleanup before further dynamic behavior expansion.

Do not select dynamic burst-length, runtime validation, multi-beat output
banks, multiple/mixed dynamic demux, same-cycle recapture, dynamic same-ID
ordering, queues, scoreboards, direct backend behavior, or VHDL as the
immediate next behavior owner. Those remain valid feature-completeness
frontiers, but `.234` exposed a validation prerequisite: the primary AXI
manager parser/generator focused suites are now too costly to rely on as
routine closeout gates.

## Evidence Read

The selector read or used:

- `.234` dynamic read-data behavior and its public samples.
- `.233` dynamic read-data readiness audit.
- `.231` dynamic read burst-last/`RID && RLAST` behavior.
- `.227` dynamic read single-beat `RID` behavior.
- `.223` dynamic write `BID` behavior.
- `.219` dynamic transaction-ID metadata behavior.
- Current dynamic read-data support accounting and report/residue prose.
- Parser/generator tests `t/1436-ial2-ppif-parser-cli.t` and
  `t/1437-axi-ial2-manager-capacity-status-generator.t`.
- `docs/knowledge/fsmgen-perl-test-env-path-isolation.md`.
- README, `ROADMAP_V2.md`, mdBook, task tree, Memory, and Knowledge Map.

The closeout evidence for `.234` is enough for the shipped behavior, but it
also shows the validation surface is no longer signoff-shaped:

- full `t/1437-axi-ial2-manager-capacity-status-generator.t` attempts became
  CPU-bound in pre-existing regex-heavy assertion code and produced no useful
  TAP diagnostics;
- a guarded full `t/1436-ial2-ppif-parser-cli.t` rerun after a stale
  diagnostic expectation fix reached the host-memory cutoff at 90.5%;
- direct parser/generator, schedule/check/semantic JSON, HDL, support
  accounting, mdBook, Knowledge Map, memory, and doctrine probes still covered
  the new `.234` behavior;
- earlier task-tree rows already show repeated multi-minute or multi-thousand
  second focused-suite runs for these AXI manager monoliths.

## Why The Next Owner Is Test-Cost Cleanup

The next natural behavior family after scalar dynamic read-data would be
dynamic raw-`ARLEN` burst-length capture over the last-beat dynamic read-data
shape, followed by runtime beat-count/`RLAST` validation and dynamic
multi-beat output banks. Those features would add more assertions, PPIF
samples, support-accounting rows, report prose, and generated HDL checks to
the same oversized test files.

Adding more behavior before bounding the validation surface would increase the
project's dependence on direct ad hoc probes and make future signoff weaker.
The safer prerequisite is to make the dynamic AXI manager focused coverage
fast, isolated, and routinely runnable under the RAM guard.

## Scope For `.236`

`.236` is test-infrastructure cleanup. It should:

- inspect the current AXI manager parser/generator focused suites and identify
  the cost hotspots that block routine closeout;
- create or factor bounded focused validation for the shipped dynamic
  transaction-ID family from `.219` through `.234`, including metadata-only
  dynamic IDs, dynamic write demux, dynamic read single-beat demux, dynamic
  read burst-last demux, and scalar dynamic read-data;
- preserve the existing assertions' intent while moving new or dynamic-family
  coverage to a smaller runnable surface, or add an explicit supported filter
  that lets the dynamic-family subset run predictably;
- keep product behavior, PPIF public syntax, support accounting semantics,
  generated artifacts, and HDL behavior unchanged;
- document the resulting validation command(s), closeout expectations, and
  any residual broad-suite caveat in the task tree, Memory, and Knowledge Map.

The owner may edit tests, test helpers, and test documentation. It should not
change parser/generator behavior except for strictly necessary test harness
plumbing that is behavior-neutral and validated as such.

## Non-Goals

`.235` changes no parser, generator, PPIF sample, support-accounting catalog,
validation, generated artifact, test, or HDL behavior.

`.236` must not implement dynamic burst-length capture, runtime validation,
multi-beat output banks, multiple dynamic read/write transactions, mixed
dynamic/static demux, same-cycle release-and-recapture, dynamic same-ID
ordering, queues, scoreboards, direct backend behavior, or VHDL behavior.

`.236` must not delete coverage to make the suite faster. Any removed
assertion must either be redundant with a retained assertion, moved to a
bounded focused test, or explicitly justified in the task tree as obsolete.

## Validation

Selector closeout validation for `.235`:

```sh
bash knowledge-map/scripts/gen_knowledge_map.sh
mdbook build docs/book
scripts/check_doctrines.sh
bash knowledge-map/scripts/check_knowledge_map.sh
scripts/check_memory_architecture.sh
git --no-pager diff --check
```

The `.236` cleanup owner must define and run the new bounded dynamic-family
validation target(s), plus syntax, docs, Knowledge Map, memory, and doctrine
gates. Where a full monolithic suite remains oversized, `.236` must record the
exact caveat and the replacement focused coverage.

## Rollback

Rollback for `.235` is limited to this selector record, task-tree frontier
movement, README, `ROADMAP_V2.md`, mdBook, Memory, and Knowledge Map updates.
No behavior-bearing file is part of this selector.

Rollback for `.236` must remove only the test-harness factoring or bounded
focused tests introduced by that cleanup while preserving the shipped dynamic
behavior and public PPIF samples.
