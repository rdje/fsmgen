# IAL2 AHB Completer/Subordinate Post-Seed Readiness Audit

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.710`

Date: 2026-06-29

## Outcome

`IAL2-FEATURE-COMPLETENESS-FRONTIER.710` finds AHB
completer/subordinate work ready for a public IAL2 contract-selection leaf,
not for immediate parser/generator implementation.

The lower-layer prerequisite is now present:

```text
fsm/ahb_lite_subordinate.fsm
protocol.ahb_lite_subordinate
```

The next exact owner is `IAL2-FEATURE-COMPLETENESS-FRONTIER.711`, a
no-behavior public contract-selection slice for the first IAL2 AHB
subordinate/completer source. `.711` must choose the exact public source
shape, object naming, generated `.isf`/`.fsm` review-artifact names, report
schema, support-accounting identity, diagnostics, validation, residue, and
next implementation or substrate-audit owner before any IAL2 behavior changes.

No parser behavior, generator behavior, public source sample,
support-accounting catalog behavior, capability manifest behavior, test
behavior, schedule/check/semantic JSON behavior, generated artifact,
HDL/runtime behavior, seed behavior, direct backend behavior,
verification-output generation, backend-language variant, AXI, APB, or VHDL
behavior changed in this audit.

## Evidence Read

The audit read:

- `.709`, the shipped direct AHB-Lite/common-AHB subordinate seed behavior;
- `fsm/ahb_lite_subordinate.fsm`;
- `.708`, the lower-layer seed contract selection;
- `.707`, the source-backed AHB/AHB-Lite subordinate fact inventory;
- the imported Arm AMBA AHB Protocol Specification PDF under
  `docs/vendor/arm/amba/ahb/`;
- shipped AHB requester `.ppif`/`.ahb` behavior and direct requester seed;
- APB completer generated-IAL1 substrate precedent;
- PPIF parser/generator/report/support-accounting patterns;
- README, ROADMAP_V2, mdBook, task tree, Memory, Knowledge Map, and relevant
  decisions.

## Readiness Findings

The direct seed closes the lower-layer endpoint evidence gap identified in
`.702` through `.708`. It establishes a source-backed bounded subordinate
oracle for:

- `HSEL && HREADY` address/control acceptance;
- `IDLE` and `BUSY` zero-wait OKAY ignore behavior;
- selected `NONSEQ` word transfer support;
- bounded `wait_cycles` data-phase wait states through `HREADYOUT`;
- one 32-bit register at `32'h00000000`;
- successful read/write data behavior;
- unsupported `SEQ`, unsupported size, and unmapped-address two-cycle ERROR;
- reset/idle defaults `HREADYOUT=1`, `HRESP=0`, `HRDATA=0`; and
- one-bit AHB-Lite/common-AHB `HRESP` OKAY/ERROR response.

APB completer precedent shows the IAL2 implementation workflow to follow:

- select public source contract before behavior;
- generate reviewable `.isf` before generated `.fsm`;
- report generated-artifact names and residue;
- support-account the public `.ppif` source independently from the direct
  `.fsm` fixture; and
- keep profile-alias widening as a later owner.

The existing IAL1/generated-IAL0 substrate likely has enough shape for a
bounded AHB subordinate implementation because it already supports expression
entry guards after the APB prerequisite, actor-owned storage, runtime waits,
address-dependent read/write updates, and generated `.fsm` review artifacts.
However, AHB-specific source syntax, report shape, generated artifact naming,
diagnostics, and support-accounting identity are not selected yet. Selecting
those public contracts must happen before implementation.

## Selected `.711` Scope

`.711` should select the first public IAL2 AHB subordinate/completer contract.

The selector must decide:

- whether the public object is named `ahb-subordinate`, `ahb-completer`, or a
  narrower first-slice name;
- the exact source path and object name, such as a future
  `ppif/ahb_lite_subordinate.ppif` shape;
- whether the first `.ppif` source targets only the lower-layer direct seed
  behavior from `.709`;
- generated `.isf` and `.fsm` review-artifact names;
- report schema/version and residue keys;
- support-accounting identity and focused test names;
- required diagnostics for unsupported optional signals, bursts, aliases,
  interconnect/decode, byte-lane behavior, legacy two-bit `HRESP`, direct
  backend behavior, verification-output generation, backend-language variants,
  AXI, APB, and VHDL;
- validation gates and generated-HDL inspection;
- rollback; and
- whether the next owner is direct implementation or a smaller
  generated-IAL1/IAL0 substrate audit.

`.711` must not add parser/generator/source/sample/support-accounting/test
behavior. It is a contract-selection leaf only.

## Rejected Alternatives

Immediate IAL2 implementation is rejected because the public source contract,
report schema, support-accounting identity, generated artifact names, and
diagnostics are not selected.

AHB interconnect/decode is rejected because it needs a public subordinate
endpoint source contract first.

Profile-alias `.ahb` subordinate exposure is rejected for the first post-seed
step. The project should follow the APB/AHB requester pattern: generic
`.ppif` contract and behavior first, profile alias later.

Extending the direct `.fsm` seed instead of selecting IAL2 source is rejected
because the lower-layer seed now satisfies the prerequisite; the next missing
surface is the public IAL2 contract.

## Validation

This audit is documentation-only:

```bash
./bin/fsmgen --quiet --strict --check --json fsm/ahb_lite_subordinate.fsm
rg -n 'protocol\.ahb_lite_subordinate|ahb_lite_subordinate' \
  perl/FSM/Support/RegressionCorpus.pm t/248-regression-corpus-accounting.t
rg -n 'generated \\.isf|generated \\.fsm|apb_completer|guard prerequisite' \
  docs/IAL2_APB_COMPLETER_GENERATED_IAL1_SUBSTRATE_AUDIT.md
knowledge-map/scripts/gen_knowledge_map.sh
knowledge-map/scripts/check_knowledge_map.sh
mdbook build docs/book
scripts/check_memory_architecture.sh
git --no-pager diff --check
scripts/check_doctrines.sh
```

## Rollback

Rollback removes this audit, its Knowledge Map fact card, task-tree
advancement, README/ROADMAP/mdBook sync, Memory pointer update, and regenerated
Knowledge Map entries. No runtime behavior is affected.
