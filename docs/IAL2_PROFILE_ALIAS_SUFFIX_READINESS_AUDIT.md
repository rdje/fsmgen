# IAL2 Profile-Alias Suffix Readiness Audit

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.537`

Date: 2026-06-26

## Outcome

`IAL2-FEATURE-COMPLETENESS-FRONTIER.537` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.538`, public inventory synchronization for
future IAL2 profile-alias suffixes.

The audit does not implement `.axi` or any other suffix alias. IAL2 remains the
generic protocol/platform intent layer. AXI is the first shipped
profile/example, not the definition of IAL2.

## Evidence Read

Decision `0015` allows protocol-specific extensions such as `.axi`, `.chi`,
`.ace`, `.ahb`, `.apb`, `.atb`, `.smbus`, and `.i2s` as future
vocabulary/profile aliases over the same IAL2 model. It also requires those
aliases to preserve reports, source anchors, residue, reviewable generated
IAL1, and the mandatory lowering chain:

```text
IAL2 -> IAL1 / .isf -> IAL0 / .fsm -> HDL
```

Decision `0016` selects `.ppif` as the first public generic IAL2 container and
keeps `.pif`, `.ppi`, and protocol-profile aliases outside the first
implementation. Decision `0017` keeps multi-channel Valid-Ready bundles
reviewable through generated `.isf` and `.fsm` artifacts and an aggregate
report.

`.527` synchronized public contracts with the guardrail that `.ppif` is the
generic IAL2 container, AXI is only the first shipped profile/example, future
protocol-specific suffixes are profile aliases over IAL2, and every `.ppif`
path lowers through generated `.isf` before generated `.fsm`.

`.535` then shipped the neutral `valid-ready` dual-channel `.ppif` bundle, so
the current public surface now has both AXI-profile and protocol-neutral IAL2
examples before any profile-alias suffix work begins.

## Current Implementation Boundary

The current CLI and adapter are not ready to accept profile-alias suffixes:

- bare-name source resolution only treats `.fsm`, `.isf`, and `.ppif` as known
  source suffixes; a bare `foo.axi` is searched as `foo.axi.fsm`;
- path-based `foo.axi` inputs can resolve as files, but they do not enter the
  PPIF pipeline because the dispatch branch only matches `.ppif`;
- `FSM::Adapter::IAL2::PPIF->parse_file` currently requires a readable `.ppif`
  path;
- help text advertises only `.fsm`, `.isf`, and `.ppif` source forms;
- final direct-FSM basename stripping only removes `.fsm`, `.isf`, or `.ppif`;
- the capability manifest advertises shipped suffixes as `.fsm`, `.isf`, and
  `.ppif`; and
- the manifest prose names `.smbus` and `.i2s` as future aliases, while
  `unsupported_first_slice_aliases` currently lists only `.pif`, `.ppi`, `.axi`,
  `.chi`, `.ace`, `.ahb`, `.apb`, and `.atb`.

These are contract and routing boundaries, not generator limitations. Existing
`.ppif` behavior can already express AXI-profile and protocol-neutral
Valid-Ready shapes through explicit `(profile ...)` clauses.

## Readiness Findings

Future profile-alias suffixes can be accepted safely only after a contract owner
settles the file-surface rules. The first candidate profile-alias inventory is
`.axi`, `.chi`, `.ace`, `.ahb`, `.apb`, `.atb`, `.smbus`, and `.i2s`.
Generic `.pif` and `.ppi` remain generic-container candidates, not
protocol-profile aliases.

An alias implementation must preserve the equivalent `.ppif` behavior:

- reports and schemas remain IAL2 reports;
- authored source paths stay visible as the alias path instead of being hidden
  behind an internal `.ppif` rewrite;
- support accounting either reuses an explicitly selected existing entry or
  introduces a new support-accounted alias fixture under its own owner;
- generated review artifacts remain `.isf` before `.fsm`;
- direct IAL2-to-IAL0 lowering remains forbidden;
- check JSON, semantic JSON, `--outdir`, and default HDL paths keep the same
  lowering semantics as equivalent `.ppif` input; and
- diagnostics distinguish unknown suffix, unsupported-but-known alias, missing
  profile, and suffix/profile mismatch.

The explicit-profile rule needs a contract decision before implementation.
Decision `0015` says a future `.axi` file can be equivalent to a generic IAL2
file that declares an AXI vocabulary/profile inside the file. The safest first
alias contract is therefore to decide whether aliases require explicit
`(profile ...)`, imply a profile, or require both an implied suffix profile and
an explicit matching profile clause.

## Selected `.538` Scope

`.538` should synchronize the public unsupported-alias inventory before any
alias behavior changes. It should:

- make the capability-manifest `unsupported_first_slice_aliases` inventory match
  the public boundary prose for `.axi`, `.chi`, `.ace`, `.ahb`, `.apb`, `.atb`,
  `.smbus`, and `.i2s`, while keeping `.pif` and `.ppi` as unsupported generic
  container candidates;
- add focused manifest expectations for the synchronized inventory;
- update README, ROADMAP_V2, mdBook, task tree, Memory, and Knowledge Map; and
- select the next exact owner for the first profile-alias public contract.

`.538` must not accept `.axi`, `.chi`, `.ace`, `.ahb`, `.apb`, `.atb`,
`.smbus`, `.i2s`, `.pif`, or `.ppi` as source suffixes. It must not change
parser behavior, generator behavior, PPIF samples, support accounting,
schedule/check/semantic JSON behavior, generated artifacts, HDL/runtime
behavior, backend behavior, verification-output generation, backend-language
variants, common construct promotion, AXI behavior, non-AXI behavior, direct
backend lowering, or VHDL behavior.

## Validation

Closeout for this audit is documentation-only:

```bash
bash knowledge-map/scripts/gen_knowledge_map.sh
bash knowledge-map/scripts/check_knowledge_map.sh
mdbook build docs/book
scripts/check_docs_relative_paths.sh
scripts/check_memory_architecture.sh
git --no-pager diff --check
scripts/check_doctrines.sh
```

## Rollback

Rollback is documentation-only: remove this audit, its Knowledge Map fact,
task-tree advancement, README/ROADMAP_V2/mdBook sync, and Memory pointer. No
parser, manifest, generator, sample, support-accounting, generated HDL, runtime,
or backend artifact rollback is required.
