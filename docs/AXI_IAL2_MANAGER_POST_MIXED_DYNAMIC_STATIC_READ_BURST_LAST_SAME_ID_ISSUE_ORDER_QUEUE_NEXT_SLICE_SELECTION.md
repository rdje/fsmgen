# AXI IAL2 Manager Post Mixed Dynamic/Static Read Burst-Last Same-ID Issue-Order Queue Next Slice Selection

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.510`

Date: 2026-06-26

## Decision

`IAL2-FEATURE-COMPLETENESS-FRONTIER.510` selects `.511`, public `.ppif`
downstream-contract, capability-manifest, and mdBook surface synchronization
after the generated mixed dynamic/static same-ID issue-order queue behavior
shipped through `.503`, `.506`, and `.509`.

This selector changes no parser, generator, PPIF sample, support-accounting
catalog, generated artifact, schedule/check/semantic JSON, HDL/runtime,
backend, external converter, verification-output, or VHDL behavior.

## Why This Is Next

`.509` shipped generated mixed dynamic/static read burst-last `RID && RLAST`
same-ID `issue-order-queue` behavior for exactly one dynamic read transaction
and one concrete static read transaction. The behavior-specific surfaces are
current: the support-accounted sample exists, the regression corpus includes
it, focused parser/generator/dynamic-ID tests cover it, README/ROADMAP/book
feature-backlog summaries mention it, and the behavior fact card records the
generated queue/report contract.

The required downstream-consumer lockstep audit found a narrower public-surface
gap before the next behavior slice:

- `docs/ISF_DOWNSTREAM_INTEGRATION_SPEC.md` and
  `docs/ISF_PUBLIC_INTERFACE_CONTRACT.md` still summarize `.ppif` coverage
  without naming generated mixed dynamic/static same-ID issue-order queue
  behavior.
- `docs/book/src/11-extensions-and-embedding.md` still stops the IAL2
  manifest-boundary narrative around the older mixed response-demux selector
  era and does not advertise the `.503`/`.506`/`.509` generated mixed
  dynamic/static queue chain.
- `perl/FSM/Support/LanguageSurfaceSection.pm` still advertises a
  `language_surface.file_surfaces` `.ppif` `current_boundary` string that
  omits the generated mixed dynamic/static same-ID issue-order queue chain.
- `docs/knowledge/downstream-consumer-contract-lockstep.md` records that
  downstream handoff docs, public contracts, manifest metadata,
  support-accounting, tests, README, roadmap, Memory, Knowledge Map, task
  tree, and mdBook must stay lockstep for downstream-visible `.isf`/`.ppif`
  facts.

Because the gap includes the capability manifest, repairing it belongs in its
own owner before mixed queue read-data, raw `ARLEN`, runtime validation,
multi-beat output banks, broader mixed cardinality, scoreboards, backend
behavior, backend-language variants, verification-code generation, external
converter audits such as `sv2v`, or VHDL.

## Selected `.511` Scope

`.511` owns synchronization of public summary surfaces to the behavior already
shipped by `.503`, `.506`, and `.509`:

- Update `.ppif` coverage text in `docs/ISF_DOWNSTREAM_INTEGRATION_SPEC.md`.
- Update the matching `.ppif` coverage text in
  `docs/ISF_PUBLIC_INTERFACE_CONTRACT.md`.
- Update `docs/book/src/11-extensions-and-embedding.md`; the included
  `docs/book/src/13i-downstream-integration.md` then follows the downstream
  handoff file automatically.
- Update the `.ppif` `current_boundary` string in
  `perl/FSM/Support/LanguageSurfaceSection.pm` so
  `./bin/fsmgen --capability-manifest` reports the same bounded public
  coverage.
- Add or adjust exact manifest/contract tests only if required to keep public
  manifest discovery synchronized.
- Keep README, ROADMAP_V2, the task tree, Memory, mdBook, and Knowledge Map
  synchronized with the public-surface repair.

The expected public wording must name the generated one-dynamic plus
one-concrete-static mixed dynamic/static same-ID issue-order queue coverage for:

- write `BID`;
- read single-beat `RID`;
- read burst-last `RID && RLAST`.

It must also keep explicit deferrals visible: mixed read-data over these
issue-order queues, raw `ARLEN` over them, runtime validation over them,
multi-beat output banks over them, multi-static/two-dynamic mixed queues,
scoreboards, arbitrary cardinality, same-cycle widening beyond the shipped
boundaries, backend behavior, backend-language variants, verification-code
generation, external converter dependencies such as `sv2v`, and VHDL remain
future exact-owner work.

## Validation Gates For `.511`

Focused checks:

- `perl -c perl/FSM/Support/LanguageSurfaceSection.pm` if that source file
  changes.
- A capability-manifest probe, for example
  `./bin/fsmgen --capability-manifest | rg 'mixed dynamic/static same-ID issue-order queue|read burst-last'`.
- Any existing language-surface/capability-manifest tests that cover the
  changed contract shape.

Closeout gates:

- `knowledge-map/scripts/gen_knowledge_map.sh`
- `knowledge-map/scripts/check_knowledge_map.sh`
- `mdbook build docs/book`
- `scripts/check_docs_relative_paths.sh`
- `scripts/check_memory_architecture.sh`
- `git --no-pager diff --check`
- `scripts/check_doctrines.sh`

## Rollback

Revert the `.511` documentation/manifest-boundary synchronization and any
focused contract-test expectation changes. Since `.511` must not change
parser/generator behavior or samples, rollback must not affect generated
hardware behavior.

## Non-Goals

- Do not add mixed read-data over the generated mixed dynamic/static
  issue-order queues.
- Do not add raw `ARLEN`, runtime validation, or multi-beat output banks over
  those mixed issue-order queues.
- Do not widen mixed queue cardinality.
- Do not add scoreboards, arbitrary cardinality, or backend behavior.
- Do not add backend-language variants, verification-code generation, external
  converter dependencies such as `sv2v`, or VHDL.
