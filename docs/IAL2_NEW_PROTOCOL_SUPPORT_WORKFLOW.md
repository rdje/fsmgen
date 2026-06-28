# IAL2 New Protocol Support Workflow

- Work unit: `IAL2-NEW-PROTOCOL-SUPPORT-WORKFLOW-CAPTURE.1`
- Date: `2026-06-28`
- Status: current
- Scope: reusable process for adding a new IAL2 protocol or protocol-profile
  surface

## Purpose

This document captures the process learned from the AXI and APB IAL2 work so
future protocol support can be added systematically. It is a workflow, not an
implementation claim. Every future protocol still needs exact task-tree leaves
for its selected readiness audits, contracts, behavior slices, docs, tests,
and commits.

The core rule is unchanged:

```text
IAL2 source -> generated IAL1 .isf -> generated IAL0 .fsm -> HDL
```

Direct IAL2-to-IAL0 lowering is forbidden. Generated `.isf` and `.fsm`
artifacts are review artifacts, not private implementation details.

## Non-Negotiable Entry Gate

Before any new protocol code, test, sample, source, generated artifact, or
config change:

- create or activate the owning task-tree leaf;
- record the exact acceptance criteria, validation scope, deferrals, and
  rollback boundary;
- read the relevant decisions, current task frontier, Memory, Knowledge Map,
  README, roadmap, and mdBook surfaces;
- keep the work to one selected slice;
- commit through `COMMIT.md` before continuing to the next slice.

Do not start with parser code. Do not start with a full protocol. Start with a
readiness or contract-selection leaf unless the exact public contract already
exists and is task-tree owned.

## Phase 1: Evidence And Candidate Selection

The first protocol step is evidence capture. A candidate protocol or profile
needs source anchors and a small semantic subset that genuinely belongs above
IAL1.

Capture:

- protocol family and profile names, such as `axi4`, `apb`, or a future
  `ahb`;
- source documents, pages, sections, design notes, or platform contracts;
- endpoint roles, channels, phases, transfer conditions, and hierarchy;
- state required by the protocol, such as outstanding IDs, queues, decode
  windows, access policies, or wait states;
- assertions, assumptions, static checks, and runtime checks;
- explicit unsupported residue.

The first subset should be the smallest object with real protocol semantics.
AXI started with one Valid-Ready channel rather than a full manager. APB grew
from requester and completer endpoints before fixed composition, multi-register
decode, sidebands, protection, widths, and timing policies.

Reject the candidate as IAL2 if it is only:

- a shorter spelling for existing `.isf`;
- a one-transaction macro;
- a reusable `.fsm` or `.isf` library with no higher protocol object;
- a prompt-only spec-to-code workflow with no source anchors and no residue
  report.

## Phase 2: Readiness Audit

A readiness audit changes no behavior. It answers whether the selected subset
can fit the current substrate or whether a smaller prerequisite is needed.

Read and record:

- existing IAL2 protocol-intent modules under
  `perl/FSM/IAL2/ProtocolIntent/`;
- `perl/FSM/Adapter/IAL2/PPIF.pm` parser and profile-alias behavior;
- existing generated IAL1 and IAL0 artifact shapes;
- `bin/fsmgen` CLI modes for check JSON, schedule JSON, semantic JSON,
  `--outdir`, HDL generation, and capability manifest;
- `perl/FSM/Support/RegressionCorpus.pm` support-accounting entries;
- `perl/FSM/Support/LanguageSurfaceSection.pm` manifest wording;
- focused parser/generator/CLI/support tests;
- README, ROADMAP_V2, mdBook, Knowledge Map, and Memory.

The audit output must select exactly one of:

- a public contract-selection leaf;
- a direct implementation leaf only when the public contract is already
  selected and the substrate is proven ready;
- a smaller IAL1/IAL0/SystemVerilog prerequisite;
- an explicit deferral.

## Phase 3: Public Contract Selection

Contract selection changes no behavior. It freezes the next implementation
boundary before source, parser, generator, sample, or report changes.

The contract must name:

- public source suffixes, usually `.ppif` first;
- any profile alias, such as `.apb` or `.axi`, and the fact that it is only a
  vocabulary/profile alias over IAL2;
- top-level object form and required clauses;
- object cardinality for the first slice;
- generated review artifact names and entry artifact selection;
- report schema, report keys, source identity, generated artifacts, residue,
  and support details;
- support-accounting entry IDs, coverage names, source kinds, expected top
  names, and expected children where applicable;
- diagnostics for missing, malformed, mixed, duplicate, or unsupported forms;
- focused validation commands;
- docs and mdBook update requirements;
- rollback plan;
- explicit residue and next likely selectors.

The contract should deliberately exclude broader protocol behavior. APB timing
policy, for example, did not start with every width, protection policy, queue
depth, overflow behavior, and multi-peripheral form at once. Each family was
selected, implemented, documented, and committed separately.

## Phase 4: Implementation Shape

Each implementation slice should mirror the existing IAL2 structure.

Parser and public-source layer:

- extend `FSM::Adapter::IAL2::PPIF` only for the selected source form;
- fail closed on malformed or unsupported clauses;
- keep `.ppif` protocol/platform-generic;
- make profile aliases enforce their profile, for example `.apb` requires
  `(profile apb)`;
- reject profile/suffix mismatches;
- keep unsupported aliases out until an exact owner selects them.

Protocol-intent layer:

- implement or extend one `FSM::IAL2::ProtocolIntent::*` module;
- normalize the contract into deterministic in-memory data;
- validate names, widths, roles, cardinality, and selected-policy shape;
- generate reviewable IAL1 `.isf` text;
- run the existing IAL1 parser/scheduler path to produce `.fsm`;
- emit an IAL2 report with schema, layering, source object, generated
  artifacts, bindings, static rules, generated behavior, and residue;
- keep generated names stable and collision-checked.

Lowering and artifact layer:

- generated `.isf` must be inspectable;
- generated `.fsm` must be inspectable;
- the selected HDL entry must be deterministic;
- composition sources must report child artifacts, generated tops, instance
  names, wiring, and selected child modules;
- no hidden direct shortcut may bypass IAL1.

## Phase 5: Samples And Support Accounting

Every public protocol feature needs checked-in runnable samples and
support-accounting entries.

Add or update:

- positive `.ppif` sample under `ppif/`;
- matching profile alias sample only if selected;
- `RegressionCorpus` entry with stable `id`, `relpath`, `classification`,
  `coverage`, `source_kind`, and expected shape;
- support-accounting tests, including strict-supported classification when
  appropriate;
- capability-manifest text in `LanguageSurfaceSection`;
- parser/generator/CLI tests that prove source identity and matched support
  accounting.

Good support IDs are specific enough to survive future expansion, for example:

```text
intent.ppif_apb_completer_multi_register_sideband_data16_protection_back_to_back
intent.apb_profile_alias_composition_multi_register_sideband_data16_protection_status_back_to_back
```

Do not reuse support identities for a widened behavior. Add a new identity or
explicitly document why the old identity remains exact.

## Phase 6: Diagnostics And Residue

New protocol support must make unsupported behavior visible. It must not
pretend the whole protocol is supported because one bounded family works.

Diagnostics should fail closed for:

- unsupported profile/suffix combinations;
- missing required clauses;
- duplicate clauses or names;
- invalid widths, addresses, roles, policies, or cardinality;
- mixed object families outside selected composition forms;
- selected policy values outside the current slice.

Reports should keep residue machine-readable and honest:

- unsupported protocol families;
- broader widths or address forms;
- broader timing, queue, ordering, protection, or decode policies;
- direct backend and verification-output deferrals;
- backend-language variants and VHDL deferrals;
- profile aliases not selected in this slice.

Move residue only when behavior is actually implemented and validated. If a
slice only adds parser/report metadata, `generated_behavior` must remain
false or equivalent until generated artifacts and HDL behavior ship.

## Phase 7: Validation Gates

Choose validation based on blast radius. For a new protocol slice, focused
checks usually include:

```bash
perl -Iperl -c perl/FSM/Adapter/IAL2/PPIF.pm
perl -Iperl -c perl/FSM/IAL2/ProtocolIntent/<ProtocolModule>.pm
perl -Iperl -c perl/FSM/Support/RegressionCorpus.pm
perl -Iperl -c perl/FSM/Support/LanguageSurfaceSection.pm
perl -Iperl -c t/<focused-parser-or-generator-test>.t
perl -Iperl -c t/248-regression-corpus-accounting.t
perl -Iperl -c t/297-capability-manifest.t
prove -Iperl t/<focused-parser-or-generator-test>.t
prove -Iperl t/248-regression-corpus-accounting.t
prove -Iperl t/297-capability-manifest.t
```

Direct public-source probes should cover each new sample:

```bash
./bin/fsmgen --quiet --emit-schedule-json ppif/<sample>.ppif
./bin/fsmgen --quiet --strict --check --json ppif/<sample>.ppif
./bin/fsmgen --quiet --strict --emit-semantic-json ppif/<sample>.ppif
./bin/fsmgen --quiet --outdir /tmp/<slice> ppif/<sample>.ppif
```

Use `--verify-hdl` when the slice claims HDL reachability and required tools
are available or the test has the selected external-tool skip behavior.
Heavy broad Perl, `prove`, or `fsmgen` runs must use the repository RAM guard.

Closeout gates always include:

```bash
knowledge-map/scripts/gen_knowledge_map.sh
knowledge-map/scripts/check_knowledge_map.sh
mdbook build docs/book
git diff --check
scripts/check_memory_architecture.sh
scripts/check_doctrines.sh
```

## Phase 8: Documentation And Memory

Every protocol slice updates the user-facing and continuity surfaces in the
same commit:

- canonical behavior, readiness, or contract doc under `docs/`;
- mdBook page or feature-backlog section that tells users what is supported;
- README and ROADMAP_V2 alignment where public behavior or status changed;
- Knowledge Map fact card under `docs/knowledge/`;
- regenerated `KNOWLEDGE_MAP.md`;
- owning task tree status, decisions, verification log, commit log, and
  changelog;
- bounded `MEMORY.md` pointer with latest commit, active work unit, recently
  done, and next action.

Do not append to frozen legacy blobs:

- `CHANGES.md`
- `DEVELOPMENT_NOTES.md`
- `ROADMAP_STATUS.md`
- `LIVE_ACHIEVEMENT_STATUS.md`

Git history is the durable change log for those legacy surfaces.

## Phase 9: Iteration Order

The proven order is:

1. Evidence capture.
2. Readiness audit.
3. Public contract selection.
4. Parser/report metadata if the syntax is not yet stable.
5. Generated behavior through `.isf` and `.fsm`.
6. Public samples and support accounting.
7. Profile alias exposure only after the generic `.ppif` behavior is stable.
8. Composition/interconnect only after endpoint roles are stable.
9. Width, sideband, protection, timing, queue, and policy families as separate
   bounded slices.
10. Direct backend, verification output, backend-language variants, and VHDL
    only after the SV-backed IAL2/IAL1/IAL0 path is feature-complete enough
    for the selected surface.

The next slice should usually be a selector after behavior ships. The selector
chooses the next exact residue owner instead of letting implementation drift.

## Stop Conditions

Stop before implementation when:

- no task-tree leaf owns the exact change;
- the public syntax or support-accounting identity is ambiguous;
- a source family would need unselected IAL1/IAL0/SystemVerilog substrate;
- generated artifacts would not be reviewable;
- residue movement would overclaim support;
- the mdBook cannot accurately explain the behavior;
- focused tests cannot isolate the change;
- the slice is expanding into full-protocol scope.

Stop during validation when:

- focused tests fail and cannot be resolved cleanly;
- RAM guard stops a heavy run;
- doctrine, Knowledge Map, mdBook, or memory gates fail;
- unrelated user changes conflict with the task-scoped commit.

Record the blocker in the owning task tree and Memory.

## Minimal New Protocol Checklist

Before a protocol is advertised as supported, the current slice must answer:

- What exact protocol object is supported?
- Which suffixes accept it?
- What generated `.isf` and `.fsm` artifacts appear?
- Which HDL entry is selected?
- Which report schema and keys are stable?
- Which support-accounting entries match check/semantic JSON?
- Which diagnostics prove unsupported forms fail closed?
- Which examples can users run?
- Which tests prove behavior, reports, artifacts, and docs?
- Which residue remains, and which task-tree leaf owns the next decision?

If any answer is missing, the slice is not signoff-ready.
