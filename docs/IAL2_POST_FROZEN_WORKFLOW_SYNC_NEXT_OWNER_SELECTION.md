# IAL2 Post Frozen-Workflow-Sync Next-Owner Selection

## Selection

`IAL2-FEATURE-COMPLETENESS-FRONTIER.835` selects proposed no-behavior
`BIN-FSMGEN-IMPORT-TREE-JUL29-REFRESH.1` as the next exact owner.

The selected leaf must remeasure the live project-owned dependency closure
reachable from `bin/fsmgen`, synchronize the maintained architecture note and
its canonical fact, refresh stale selected line counts and reachability prose,
and change no runtime behavior. This selector does not activate or modify the
selected child before its own commit is clean.

## Reconciled Boundary

Clean workflow commit `771d2918c` completes the decision-`0007` memory-layer
repair without modifying any frozen blob or product behavior. The mdBook VHDL
boundary and grouped assertion repair remain aligned; AHB requester literal
`2..16` and support accounting remain at `332` protocol / `373` supported / `56`
AHB paths split `28` `.ppif` / `28` `.ahb`.

The maintained import-tree note is now the last exact startup-alignment owner.
Its saved baseline is dated `2026-06-28` and claims `213` project files, `212`
packages, and `IAL2: 5`.

## Live Import Evidence

The activation-time `Module::ScanDeps` probe from repository root reports:

- `228` project-owned files total: `bin/fsmgen` plus `227` reachable
  `FSM::...` packages;
- family counts `Support 70`, `Composition 36`, `HDL 33`, `IAL2 19`,
  `Package 14`, `Synthesis 10`, `Adapter 9`, `IR 7`, `Scheduler 7`,
  `Pipeline 5`, `Backend 4`, `Extension 3`, `VerificationOutput 2`, and
  `AST 1`;
- all `19` shipped IAL2 protocol-intent owners are reachable, including the
  current AHB, APB, AXI requester/acceptor/composition, and Valid-Ready
  families.

The proposed child originally recorded a startup measurement of `227` / `226`.
The additional reachable file is explained, not anomalous: same-volume policy
implementation commit `017153eac` added reachable singleton
`perl/FSM/ProjectDataLocality.pm`. The child acceptance already requires the
newly measured values if the graph changes before activation.

## Candidate Comparison

| Candidate | Selection result | Evidence |
| --- | --- | --- |
| `bin/fsmgen` import-tree refresh | **selected** | The canonical maintainer architecture note and fact are measurably stale; the exact read-only probe, bounded documentation surface, and no-behavior correction are known. |
| Public-sync test drift | remains proposed | Three independently owned pre-existing test/document mismatches remain, but they are behavior/test-contract repairs rather than the last startup architecture snapshot correction. |
| HIAL/VIAL verification architecture | remains proposed | Director-endorsed and foundational, but substantially broader than synchronizing one demonstrably stale live architecture note. |
| End-to-end large-design scalability | remains proposed | Required product direction, but workload and capacity methodology are broader than the exact no-behavior refresh. |
| mdBook rustdoc fence repair and other documentation work | remains proposed | Independently bounded; none supersedes the canonical import-map mismatch selected here. |
| RAM-guard refinement and t1436 failures | retain explicit gates | Guard behavior still requires separate director authorization; t1436 still requires explicit prioritization. |
| Decision `0020` transaction architecture | ineligible | It remains a thinking-aloud North Star explicitly marked no-pivot and not PNT-eligible without director activation. |
| Other protocol/backend work | deferred | No evidence makes it a prerequisite for the import-note truth repair. |

## Selected Leaf Contract

The selected leaf must:

- rerun `Module::ScanDeps` from repository root and record the exact total,
  package, family, and IAL2-owner closure;
- update `docs/BIN_FSMGEN_IMPORT_TREE.md` from source evidence, including the
  review date, baseline prose, measured table, current IAL2/AHB/AXI/APB
  reachability, singleton owners, and selected line counts;
- update `docs/knowledge/bin-fsmgen-import-tree-current-baseline.md` and
  regenerate the Knowledge Map;
- preserve runtime code, parser/generator behavior, public sources, support
  accounting, artifacts, APIs, HDL, simulation, backend behavior, and every
  broader roadmap owner;
- render the mdBook and run focused path/status, Knowledge Map, memory, diff,
  and doctrine gates; and
- use repository-local storage, the authorized host100/process4096 profile,
  and canonical Stats-compatible RAM plus separate kernel-pressure reporting.

## Validation And Rollback

Validation reruns the exact closure/family/IAL2 listing; verifies the note and
fact against that output; checks selected source line counts; runs book/status/
path audits, Knowledge Map generation/checking, repository-local mdBook build,
diff hygiene, and all doctrine gates. No simulator or product regression is
needed because the selected child changes documentation only.

Rollback removes this selector record/fact and restores `.835` to active. The
stale import note, the selected child, and every product behavior remain
unchanged until a clean selector commit separately activates the child.

## Closeout Evidence

- The exact live import probe reports `228` project files / `227` packages /
  `19` IAL2 owners and the same-volume singleton addition is traced to clean
  commit `017153eac`.
- Book/status/path truth passes 5 files/329 tests. Knowledge Map generation and
  checking passes at 1,064 facts/5,477 question keys.
- The mdBook renders exactly 72 files/16,544,855 bytes; its repository-local
  output is removed, and `.artifacts/tmp/tests` is empty.
- `MEMORY.md` is 47 lines, `README.md` is 2,353 lines, diff hygiene passes, and
  all six doctrine gates pass, including project-data locality.
- Final canonical Stats-compatible capacity is
  18,000,412,672/25,769,803,776 bytes = 16.764/24.000 GiB = 69.85%, with
  separate macOS kernel pressure level 1 and `memory_pressure` 74% free. Guard
  occupancy is excluded from capacity truth. No background job remains.

Clean selector commit `23a987e06` activates only the selected import-tree
child through continuity changes. The stale note/fact and every product
behavior remain unchanged during activation.
