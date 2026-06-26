# IAL2 APB Completer/Interconnect Readiness Audit

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.558`

Date: 2026-06-26

## Outcome

`IAL2-FEATURE-COMPLETENESS-FRONTIER.558` finds APB
completer/interconnect generation ready for public contract selection, not
ready for direct implementation in this slice.

The audit selects `IAL2-FEATURE-COMPLETENESS-FRONTIER.559`, APB
completer/interconnect public contract selection. The selected owner must
decide the source vocabulary, profile policy, generated artifact chain,
report/support-accounting surface, diagnostics, validation, and split policy
before any parser, generator, sample, support-accounting, or behavior change.

No parser behavior, generator behavior, samples, support-accounting catalog,
validation behavior, generated artifacts, tests, schedule/check/semantic JSON
behavior beyond read-only probes, HDL/runtime behavior, suffix acceptance,
direct backend lowering, verification-output generation, backend-language
variants, AXI behavior, APB behavior, or VHDL behavior changed.

## Evidence Read

The audit read the `.557` selector, the post-APB public-surface sync, the
shipped APB `.apb` profile-alias behavior, the APB `.ppif`
requester-transfer behavior, the APB `.ppif` source-shape contract, the
earlier APB source-shape readiness audit, the APB lower-layer fixtures,
support-accounting entries, `LanguageSurfaceSection` manifest boundaries,
README, ROADMAP_V2, mdBook, task tree, Memory, and the Knowledge Map.

The current IAL2 APB behavior remains bounded to one requester-transfer
object under explicit `(profile apb)` in either `.ppif` or bounded `.apb`
profile-alias sources:

```text
(apb-requester apb_requester ...)
```

The current APB report still carries this explicit residue:

```text
apb_completer_and_interconnect_generation_deferred
```

## Lower-Layer Evidence

The repository already has concrete APB lower-layer evidence:

- `fsm/apb_completer.fsm` is a strict-supported APB target/completer model. It
  detects setup from `PSEL=1` and `PENABLE=0`, accepts `wait_cycles`, implements
  address `32'h00000000`, returns `PSLVERR=1` for other addresses, and drives
  `PREADY`, `PRDATA`, and `PSLVERR`.
- `fsm/apb_tb.fsm` is a strict-supported APB composition top. It instantiates
  `apb_requester` and `apb_completer`, wires `PSEL`, `PENABLE`, `PWRITE`,
  `PADDR`, `PWDATA`, `PREADY`, `PRDATA`, and `PSLVERR`, and exposes requester
  stimulus plus completer wait-state control.
- `RegressionCorpus` support-accounts `protocol.apb_completer` and
  `protocol.apb_tb` as supported-smoke entries. The composition entry expects
  two child modules: `apb_requester` and `apb_completer`.

That evidence proves a usable IAL0/composition target exists. It does not by
itself select an IAL2 public source contract.

## Readiness Finding

APB completer/interconnect is ready for contract selection because the shipped
requester-transfer IAL2 path already proves the APB profile, explicit
source-anchor model, generated review artifact reporting, authored `.ppif` and
`.apb` source identity, support-accounting pattern, and public residue shape.
The lower-layer APB completer and composition top provide concrete behavioral
targets for a bounded contract.

Direct implementation is not selected because several public decisions remain
unowned:

- the IAL2 source vocabulary for completer/target behavior, such as whether the
  first object is `(apb-completer ...)`, `(apb-target ...)`, an aggregate
  requester/completer object, or a separate composition/interconnect object;
- whether the first public contract keeps completer and interconnect together
  or splits them into a completer prerequisite followed by a composition owner;
- whether `.ppif`, bounded `.apb`, or both public surfaces expose the new
  object in the first implementation;
- how the mandatory `IAL2 -> IAL1/.isf -> IAL0/.fsm -> HDL` chain is preserved
  for the completer, because the existing completer evidence is an authored
  `.fsm` fixture rather than a generated `.isf` contract;
- whether the composition/interconnect output should be a generated aggregate
  top review artifact, a generated composition `.fsm`, or a lower-layer
  prerequisite;
- report schema identity, residue movement, support-accounting identities,
  semantic/check JSON source identities, and diagnostics for mixed requester,
  completer, and interconnect objects.

Those are contract questions, not implementation details. Selecting behavior
before answering them would risk a public surface that bypasses the
reviewable IAL1 boundary or conflates APB endpoint generation with APB
composition policy.

## Selected `.559` Scope

`.559` should select the public APB completer/interconnect contract before any
behavior change.

The selector should decide:

- source vocabulary and object cardinality for APB completer and APB
  interconnect/composition intent;
- whether the first implementation should be completer-only,
  requester-plus-completer aggregate, interconnect/composition-only, or a
  split sequence with a lower-layer prerequisite first;
- explicit `(profile apb)` policy under `.ppif` and bounded `.apb`, with no
  suffix-driven profile inference;
- generated `.isf` and `.fsm` review artifact names and whether a generated
  aggregate top is required;
- report schema and residue movement for `apb_completer_and_interconnect_generation_deferred`;
- support-accounting entry IDs, source kinds, expected child modules, and
  check/semantic JSON source identities;
- diagnostics for unsupported APB completer, target, interconnect, bundle, and
  mixed-object shapes before the implementation owner ships;
- focused validation commands for APB `.ppif`, APB `.apb`, lower-layer
  completer/composition preservation, support accounting, manifest wording,
  mdBook, Knowledge Map, and doctrine gates; and
- rollback boundaries and VHDL/direct-backend deferral.

`.559` must not change parser behavior, generator behavior, samples,
support-accounting catalog, validation behavior, generated artifacts, tests,
schedule/check/semantic JSON, HDL/runtime behavior, suffix acceptance, direct
backend lowering, verification-output generation, backend-language variants,
AXI behavior, APB behavior, or VHDL behavior.

## Deferred Alternatives

APB sidebands, APB4/APB5 protection and strobes, alternate widths,
multi-peripheral decode beyond the first bounded selection, back-to-back
transfer policy, direct IAL2-to-IAL0 lowering, direct backend lowering,
verification-output generation, backend-language variants, and VHDL remain
future exact-owner work.

APB multi-peripheral decode may become part of a later interconnect owner, but
`.559` should select that boundary explicitly rather than folding decode into
completer generation by implication.

## Validation

The audit reverified the lower-layer and current IAL2 APB surfaces with:

```bash
./bin/fsmgen --quiet --strict --check --json fsm/apb_completer.fsm
./bin/fsmgen --quiet --strict --check --json fsm/apb_tb.fsm
./bin/fsmgen --quiet --emit-schedule-json ppif/apb_requester_transfer.apb
./bin/fsmgen --quiet --strict --check --json ppif/apb_requester_transfer.apb
```

Closeout validation for this documentation-only slice is:

```bash
knowledge-map/scripts/gen_knowledge_map.sh
knowledge-map/scripts/check_knowledge_map.sh
mdbook build docs/book
scripts/check_docs_relative_paths.sh
scripts/check_memory_architecture.sh
git --no-pager diff --check
scripts/check_doctrines.sh
```

## Rollback

Rollback is documentation-only: remove this audit, its Knowledge Map fact,
task-tree advancement, README/ROADMAP_V2/mdBook sync, Memory pointer update,
and regenerated Knowledge Map entries. No runtime behavior is affected.
