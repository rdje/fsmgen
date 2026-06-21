# AXI IAL2 Manager Post Mixed Auto-ID Queue-Head Runtime Validation Next Slice Selection

Work unit: `IAL2-FEATURE-COMPLETENESS-FRONTIER.203`

Date: 2026-06-21

## Decision

Select `IAL2-FEATURE-COMPLETENESS-FRONTIER.204`, AXI manager
report/static support and public-contract residue cleanup after generated
runtime beat-count/`RLAST` validation over the same-family mixed auto-ID plus
concrete same-ID queue-head read burst-last scalar last-beat read-data shape.

This selector changes no parser, generator, PPIF sample, support-accounting
catalog, validation, generated-artifact, test, or HDL behavior. It records the
next owned IAL2 feature-completeness leaf after `.202` shipped the runtime
validation sibling of the `.200` mixed report-only raw-`ARLEN` burst-length
sample.

## Evidence Read

- `.202` shipped behavior:
  `docs/AXI_IAL2_MANAGER_MIXED_AUTO_ID_QUEUE_HEAD_RUNTIME_VALIDATION_BEHAVIOR.md`.
- `.201` readiness audit:
  `docs/AXI_IAL2_MANAGER_MIXED_AUTO_ID_QUEUE_HEAD_RUNTIME_VALIDATION_READINESS_AUDIT.md`.
- `.200` report-only raw-`ARLEN` burst-length behavior:
  `docs/AXI_IAL2_MANAGER_MIXED_AUTO_ID_QUEUE_HEAD_BURST_LENGTH_BEHAVIOR.md`.
- `.197` mixed scalar read-data behavior and `.194` mixed response-demux
  behavior.
- Adjacent multiple/mixed depth-3 runtime-validation and multi-beat
  precedents, especially `.187` selecting `.188` support/residue cleanup
  before `.189` selected multi-beat output-bank readiness.
- Current implementation/support surfaces:
  `perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm`,
  `perl/FSM/Support/LanguageSurfaceSection.pm`,
  `perl/FSM/Support/RegressionCorpus.pm`,
  `t/1437-axi-ial2-manager-capacity-status-generator.t`, and
  `t/1436-ial2-ppif-parser-cli.t`.
- Public documentation surfaces: README, ROADMAP_V2, mdBook feature backlog,
  extensions/embedding chapter, downstream integration spec, public interface
  contract, task tree, Memory, and Knowledge Map.
- Startup architecture surfaces: `bin/fsmgen` and
  `docs/BIN_FSMGEN_IMPORT_TREE.md`. The live `bin/fsmgen` import closure still
  matches the saved `206` total / `205` `.pm` baseline, so no import-tree
  refresh is selected here.

## Live Support State

The generator support detail already classifies the `.202` runtime-validation
shape as supported. It says selected same-family mixed auto-ID plus depth-2
concrete queue-head read burst-last report-only raw-`ARLEN` burst-length and
runtime beat-count/`RLAST` validation shapes are covered, while mixed
multi-beat read-data remains outside the capacity/status shell.

The task tree, README, and mdBook feature backlog also know `.202` shipped.
However, a few public-facing/static surfaces still preserve stale deferred
wording:

- `docs/ISF_DOWNSTREAM_INTEGRATION_SPEC.md` still lists mixed runtime
  validation as deferred.
- `docs/ISF_PUBLIC_INTERFACE_CONTRACT.md` still lists mixed runtime
  validation as deferred.
- `perl/FSM/Support/LanguageSurfaceSection.pm` still says broader
  burst-length/runtime validation over mixed families remains deferred, even
  though the selected same-family mixed runtime-validation shape is now
  shipped.

This is support/static contract drift, not behavior drift.

## Selection Rationale

Mixed multi-beat output-bank behavior is the obvious next behavior-family
candidate after `.202`, because the analogous multiple/mixed depth-3 path moved
from runtime validation to a cleanup slice and then to multi-beat readiness.
But `.203` should not skip the cleanup step: the public handoff and manifest
boundary must be truthful before the next behavior expansion.

The closest precedent is
`docs/AXI_IAL2_MANAGER_POST_MULTIPLE_MIXED_DEPTH3_QUEUE_HEAD_RUNTIME_VALIDATION_NEXT_SLICE_SELECTION.md`.
After `.186` shipped multiple/mixed depth-3 runtime validation, `.187`
selected `.188` to clean stale support/residue wording before `.189` selected
multi-beat readiness. The same shape exists after `.202`: live behavior is
generated and support-accounted, while some static/public wording still
classifies part of that behavior as deferred.

## Selected `.204` Boundary

`.204` should update only support/report/public-contract wording and focused
expectations so generated runtime beat-count/`RLAST` validation over the
selected same-family mixed auto-ID plus depth-2 concrete same-ID queue-head
read burst-last scalar last-beat shape is described as supported, not
deferred.

The implementation boundary is:

- update `perl/FSM/Support/LanguageSurfaceSection.pm` so `.ppif` boundary text
  keeps selected mixed runtime validation as shipped while leaving mixed
  multi-beat read-data and broader mixed-family behavior deferred;
- update `docs/ISF_DOWNSTREAM_INTEGRATION_SPEC.md` and
  `docs/ISF_PUBLIC_INTERFACE_CONTRACT.md` to remove stale mixed-runtime
  deferred wording and preserve mixed multi-beat as deferred;
- add or adjust focused static expectations/scans if needed so the stale
  wording does not return;
- preserve live behavior for `.202`, `.200`, `.197`, `.194`, adjacent concrete
  queue-head samples, support-accounting identity, generated artifacts, strict
  check/semantic JSON, and HDL generation;
- do not broaden parser syntax, queue-head admission, generated read-data
  rules, generated assertions, PPIF corpus membership, support-accounting
  counts, or generated HDL behavior.

## Deferred Work

The following remain future exact-owner work:

- mixed multi-beat output-bank behavior;
- broader concrete same-ID queues beyond selected covered groups;
- group-local simultaneous enqueue widening;
- packed burst-vector outputs;
- alternate full burst payload assembly;
- verification-output generation;
- direct backend lowering;
- VHDL/backend-language variants.

## Validation Gates For `.204`

The selected cleanup should run:

- syntax checks for touched Perl and test files;
- a compact manifest/source-boundary probe or focused language-surface test;
- stale/positive wording scans that prove mixed runtime validation is no longer
  listed as deferred while mixed multi-beat remains deferred;
- compact schedule/check probes for the `.202` runtime sample and `.200`
  report-only sibling if needed;
- mdBook, README, downstream spec/public contract, task tree, Memory, and
  Knowledge Map sync; and
- standard continuity gates before commit.

## Rollback Boundary

This selector is documentation/task-tree state only. Rolling it back removes
this note, the `.203` task-tree/log updates, live-doc references, Memory, and
Knowledge Map card. It does not change parser, generator, PPIF sample,
support-accounting catalog, validation, generated artifact, test, or HDL
behavior.
