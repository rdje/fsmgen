# IAL2 AHB Subordinate Generated-IAL1 Substrate Audit

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.712`

Date: 2026-06-29

## Outcome

`IAL2-FEATURE-COMPLETENESS-FRONTIER.712` audits the generated-IAL1,
generated-IAL0, and SystemVerilog substrate for the public AHB subordinate
contract selected in `.711`.

The generated path can represent the core transaction flow: `HSEL && HREADY`
acceptance, `IDLE`/`BUSY` ignore behavior by not entering the transaction,
selected `NONSEQ` word access, unsupported `SEQ` and other errors,
runtime `wait_cycles`, storage reset/update, mapped read/write behavior, and
two sequential ERROR cycles.

The direct public implementation is still not ready. The selected AHB
subordinate contract requires reset and idle output behavior, especially
`HREADYOUT=1`, `HRESP=0`, and `HRDATA=0`. The current generated-IAL1
interface surface carries output width/type/domain metadata but no output
reset/default metadata, and the generated IAL0 review artifact only shows
scheduled output drives in transaction states. Shipping the AHB subordinate
generator now would either violate the selected idle/reset contract or tempt
the implementation to bypass the required generated `.isf` review boundary.

The next exact owner is `IAL2-FEATURE-COMPLETENESS-FRONTIER.713`, a
no-behavior contract-selection slice for generated-IAL1 output default/reset
semantics. `.713` must select the exact IAL1 source surface, generated `.fsm`
review-artifact expectation, SystemVerilog reset/idle expectation, diagnostics,
tests, documentation, and follow-on implementation owner before any substrate
code changes.

Later status: `.713` selected additive `(reset VALUE)` and
`(default VALUE)` options on generated-IAL1 actor interface outputs and routed
implementation to `.714`. AHB subordinate parser/generator/source behavior
remains deferred until that substrate is implemented and proven.

No parser behavior, generator behavior, public source sample,
support-accounting catalog behavior, capability-manifest behavior, test
behavior, schedule/check/semantic JSON behavior, generated tracked artifact,
HDL/runtime behavior, seed behavior, direct backend behavior,
verification-output generation, backend-language variant, AXI, APB, or VHDL
behavior changed in this audit.

## Evidence Read

The audit read the `.711` public contract selection, `.710` readiness audit,
`.709` direct seed behavior, `fsm/ahb_lite_subordinate.fsm`, `.708` seed
contract selection, `.707` source-fact inventory, imported Arm AHB reference
metadata, shipped AHB requester `.ppif`/`.ahb` behavior, the APB completer
generated-IAL1 precedent, PPIF parser/generator/report surfaces,
`FSM::Adapter::ISF` parser behavior, `FSM::Scheduler::ISF` generated-IAL0
emission behavior, README, ROADMAP_V2, mdBook, task tree, Memory, and the
Knowledge Map.

The selected contract from `.711` still stands:

```text
ppif/ahb_lite_subordinate.ppif
(ahb-subordinate ahb_lite_subordinate ...)
ahb_lite_subordinate.isf
ahb_lite_subordinate.fsm
fsmgen.ial2.protocol_intent.ahb_subordinate.v1
intent.ppif_ahb_lite_subordinate
```

## Positive Substrate Findings

An in-memory generated-IAL1 probe with an AHB-like actor lowered through
`FSM::Adapter::ISF` and `FSM::Scheduler::ISF` to a generated `.fsm` without
tracked artifact changes. The probe used the selected bus shape:
`HSEL`, `HREADY`, `HADDR`, `HTRANS`, `HWRITE`, `HSIZE`, `HWDATA`,
`wait_cycles`, `HREADYOUT`, `HRESP`, `HRDATA`, storage `reg_data_q`, and an
internal completion bit.

The probe confirmed that generated IAL1 can express:

- combined entry activation for `HSEL && HREADY` plus transfer-type tests;
- sampled address/control/data fields;
- runtime wait counts through `(wait wait_n)`;
- storage reset on `reg_data_q`;
- mapped write update of `reg_data_q`;
- mapped read drive of `HRDATA`;
- unsupported-size and unmapped-address branches;
- unsupported `SEQ` routing; and
- two sequential ERROR response drives.

The probe also confirmed that the APB-era expression entry-guard problem is
not present here: no `ARRAY(...)` text leaked into the generated `.fsm`.

The current PPIF adapter also fails closed for an inline
`(ahb-subordinate ahb_lite_subordinate ...)` object. That is the correct
pre-implementation behavior: `.712` is an audit, not public source support.

## Blocking Finding

The selected AHB subordinate contract requires reset and idle outputs:

```text
HREADYOUT = 1
HRESP     = 0
HRDATA    = 0
```

The shipped direct seed expresses this with explicit `.fsm` state behavior.
Generated IAL1 does not currently provide an equivalent output
default/reset contract.

The current ISF interface parser supports output metadata such as width,
type, and domain. Storage variables support reset metadata. Output ports do
not have an audited reset/default metadata surface, and the generated module
emitter declares outputs without a reset/default contract. In the generated
probe, `HREADYOUT` is driven low or high in scheduled transaction states, but
there is no reviewable reset/default statement proving that idle and reset
start at `HREADYOUT=1`.

The APB completer precedent does not close this gap. The APB audit warned
that idle/default output timing had to be reviewed, and the later APB tests
proved transaction behavior and generated artifacts without establishing a
general output reset/default substrate for generated IAL1.

Therefore direct AHB subordinate implementation remains blocked until output
default/reset semantics are selected and then implemented by a task-tree-owned
slice.

## Selected `.713` Scope

`.713` should select generated-IAL1 output default/reset semantics before any
AHB subordinate implementation.

Acceptance for `.713` should include:

- read this audit, `.711` public contract selection, `.709` direct seed
  behavior, the APB completer generated-substrate precedent, ISF interface
  parser and generated-IAL0 emitter paths, README, ROADMAP_V2, mdBook, task
  tree, Memory, and Knowledge Map;
- decide the exact source surface for output defaults and reset values;
- decide how generated `.fsm` review artifacts must prove output defaults and
  reset values;
- decide how SystemVerilog reset/idle behavior must be validated;
- select diagnostics and residue for unsupported or malformed output
  default/reset clauses;
- select focused tests and documentation updates for the follow-on
  implementation owner; and
- keep parser/generator/test/source/sample/support-accounting/runtime behavior
  unchanged in `.713`.

## Validation

Closeout for this no-behavior audit is documentation-only plus direct seed and
substrate probes:

```bash
./bin/fsmgen --quiet --strict --check --json fsm/ahb_lite_subordinate.fsm
knowledge-map/scripts/gen_knowledge_map.sh
knowledge-map/scripts/check_knowledge_map.sh
mdbook build docs/book
scripts/check_memory_architecture.sh
git --no-pager diff --check
scripts/check_doctrines.sh
```

The in-memory substrate probe and current PPIF fail-closed probe are not
tracked artifacts. They are evidence for this audit only.

## Rollback

Rollback is documentation-only: remove this audit, its Knowledge Map fact,
task-tree advancement, README/ROADMAP_V2/mdBook sync, Memory pointer update,
and regenerated Knowledge Map entries. No runtime behavior is affected.
