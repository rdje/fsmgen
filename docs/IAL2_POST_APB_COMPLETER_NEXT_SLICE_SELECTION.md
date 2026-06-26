# IAL2 Post-APB Completer Next Slice Selection

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.563`

Date: 2026-06-26

## Outcome

`IAL2-FEATURE-COMPLETENESS-FRONTIER.563` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.564`, a no-behavior readiness audit for
APB interconnect/composition generation after the generated APB `.ppif`
completer behavior shipped.

The selected next owner must not implement APB interconnect/composition. It
must decide whether the now-shipped generated requester and completer endpoint
paths plus the existing lower-layer APB composition fixture are enough for a
public interconnect/composition contract selection, whether a smaller generated
aggregate-top/report prerequisite is needed, or whether the residue should
remain deferred.

No parser behavior, generator behavior, samples, support-accounting catalog,
validation behavior, generated artifacts, tests, schedule/check/semantic JSON,
HDL/runtime behavior, suffix acceptance, direct backend lowering,
verification-output generation, backend-language variants, AXI behavior, APB
behavior, or VHDL behavior changed.

Later status: `.566` shipped the fixed one-requester/one-completer APB
composition through `.ppif`, and `.569` later exposed the APB completer and
fixed composition through `.apb`. This selector remains the historical
post-completer owner.

## Evidence Read

The selector read the shipped APB `.ppif` completer behavior, the IAL1
expression entry-guard repair, the APB completer generated-IAL1 substrate
audit, the APB completer/interconnect split contract, the APB
completer/interconnect readiness audit, the APB `.apb` requester-transfer
behavior, the APB `.ppif` requester-transfer behavior, the APB `.ppif`
requester-transfer source contract, APB requester/completer samples and
reports, `fsm/apb_tb.fsm`, `RegressionCorpus`, `LanguageSurfaceSection`,
README, ROADMAP_V2, mdBook, task tree, Memory, and the Knowledge Map.

At `.563` selection time, APB IAL2 behavior had two generated `.ppif`
endpoint paths:

```text
ppif/apb_requester_transfer.ppif
ppif/apb_completer.ppif
```

At `.563` selection time, the bounded `.apb` profile alias remained
requester-transfer only:

```text
ppif/apb_requester_transfer.apb
```

At `.563` selection time, the APB completer report kept these residues
explicit:

```text
apb_interconnect_generation_deferred
apb_profile_alias_completer_deferred
apb_multi_register_decode_deferred
apb_protection_and_strobes_deferred
apb_alternate_widths_deferred
apb_back_to_back_policy_deferred
```

## Live Evidence

The selector reverified these APB surfaces:

```bash
./bin/fsmgen --quiet --emit-schedule-json ppif/apb_completer.ppif
./bin/fsmgen --quiet --strict --check --json ppif/apb_completer.ppif
./bin/fsmgen --quiet --strict --emit-semantic-json ppif/apb_completer.ppif
./bin/fsmgen --quiet --emit-schedule-json ppif/apb_requester_transfer.ppif
./bin/fsmgen --quiet --strict --check --json ppif/apb_requester_transfer.ppif
./bin/fsmgen --quiet --emit-schedule-json ppif/apb_requester_transfer.apb
./bin/fsmgen --quiet --strict --check --json ppif/apb_requester_transfer.apb
./bin/fsmgen --quiet --strict --check --json fsm/apb_completer.fsm
./bin/fsmgen --quiet --strict --check --json fsm/apb_tb.fsm
```

The generated APB completer path reports schema
`fsmgen.ial2.protocol_intent.apb_completer.v1`, generated artifacts
`apb_completer.isf` and `apb_completer.fsm`, support-accounting entry
`intent.ppif_apb_completer`, and the residue
`apb_interconnect_generation_deferred`.

The APB requester-transfer `.ppif` and `.apb` probes still pass with their
existing support identities. The lower-layer APB composition top still passes
strict check and wires `apb_requester` to `apb_completer` through the APB bus.

## Why `.564`

APB interconnect/composition readiness is the next narrow prerequisite because
the split selected in `.559` deliberately put generated APB completer behavior
before interconnect/composition. `.562` completed that prerequisite: both APB
endpoint roles now have generated IAL2-to-IAL1-to-IAL0 paths, and the
lower-layer `fsm/apb_tb.fsm` fixture already demonstrates the requester-to-
completer wiring target.

Direct interconnect/composition implementation is not selected yet. The public
contract is still unsettled:

- whether the source vocabulary is an aggregate `(apb-interconnect ...)`,
  `(apb-composition ...)`, a requester-plus-completer bundle, or another
  shape;
- whether the first generated top owns only fixed requester/completer wiring or
  also the first decode subset;
- which generated review artifacts should exist before HDL, such as a generated
  aggregate `.isf`, generated top `.fsm`, or generated composition wrapper;
- report schema, source identity, generated-child metadata, support-accounting
  identity, expected child modules, and diagnostics; and
- how `.ppif` composition relates to the later `.apb` completer alias and
  future APB multi-register/multi-peripheral decode.

A readiness audit is the smallest signoff-level owner that can settle whether
the next slice should be contract selection, a substrate/report prerequisite,
or continued deferral.

## Rejected Next Owners

APB completer `.apb` alias exposure is not selected next. The current `.apb`
surface is intentionally requester-transfer only, and widening the alias before
selecting the `.ppif` interconnect/composition contract would expose another
endpoint surface while the composition boundary remains unsettled.

That rejection was resolved later by sequencing: `.566` first shipped the
fixed `.ppif` composition contract, then `.569` widened `.apb` for the already
shipped completer and fixed composition shapes.

APB multi-register decode, sidebands/strobes, alternate widths, and
back-to-back policy remain deferred. Those expand endpoint behavior and APB
protocol breadth. They should not be mixed into the first post-completer
question, which is whether generated requester and completer endpoints can be
composed behind a public interconnect/composition contract.

APB report/static residue cleanup is not selected as a standalone next owner.
The current report already names the remaining APB residues explicitly enough
to drive `.564`; any report/support-accounting changes for composition should
be selected by the readiness audit or the contract it chooses.

AXI, direct backend lowering, verification-output generation,
backend-language variants, and VHDL remain future candidates but are not
selected before the APB composition boundary is audited.

## Selected `.564` Scope

`.564` should audit APB interconnect/composition readiness after generated APB
requester and completer endpoints.

The audit should read `.563`, `.562`, `.561`, `.560`, `.559`, `.558`, `.554`,
`.550`, `ppif/apb_completer.ppif`, `ppif/apb_requester_transfer.ppif`,
`ppif/apb_requester_transfer.apb`, `fsm/apb_tb.fsm`, `fsm/apb_completer.fsm`,
`RegressionCorpus`, `LanguageSurfaceSection`, generated schedule/check/
semantic behavior, README, ROADMAP_V2, mdBook, task tree, Memory, and
Knowledge Map.

It should decide the next exact owner from:

- APB interconnect/composition public contract selection;
- a generated aggregate-top or composition substrate prerequisite;
- report/support-accounting prerequisite over generated child modules and
  expected composition children;
- explicit deferral with evidence; or
- a narrower APB residue only if it blocks composition contract selection.

`.564` must not change parser behavior, generator behavior, samples,
support-accounting catalog, validation behavior, generated artifacts, tests,
schedule/check/semantic JSON, HDL/runtime behavior, suffix acceptance, direct
backend lowering, verification-output generation, backend-language variants,
AXI behavior, APB behavior, or VHDL behavior.

## Validation Plan For `.564`

Closeout for the selected readiness audit should include exact APB rechecks and
the standard documentation/doctrine gates:

```bash
./bin/fsmgen --quiet --emit-schedule-json ppif/apb_completer.ppif
./bin/fsmgen --quiet --strict --check --json ppif/apb_completer.ppif
./bin/fsmgen --quiet --emit-schedule-json ppif/apb_requester_transfer.ppif
./bin/fsmgen --quiet --strict --check --json ppif/apb_requester_transfer.ppif
./bin/fsmgen --quiet --emit-schedule-json ppif/apb_requester_transfer.apb
./bin/fsmgen --quiet --strict --check --json ppif/apb_requester_transfer.apb
./bin/fsmgen --quiet --strict --check --json fsm/apb_tb.fsm
knowledge-map/scripts/gen_knowledge_map.sh
knowledge-map/scripts/check_knowledge_map.sh
mdbook build docs/book
scripts/check_docs_relative_paths.sh
scripts/check_memory_architecture.sh
git --no-pager diff --check
scripts/check_doctrines.sh
```

## Rollback

Rollback is documentation-only: remove this selector, its Knowledge Map fact,
task-tree advancement, README/ROADMAP_V2/mdBook sync, Memory pointer update,
and regenerated Knowledge Map entries. No runtime behavior is affected.
