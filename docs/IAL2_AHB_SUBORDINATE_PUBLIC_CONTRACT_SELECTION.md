# IAL2 AHB Subordinate Public Contract Selection

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.711`

Date: 2026-06-29

## Outcome

`IAL2-FEATURE-COMPLETENESS-FRONTIER.711` selects the first public IAL2 AHB
subordinate contract, but does not implement it.

The selected future source is the generic `.ppif` container:

```text
ppif/ahb_lite_subordinate.ppif
```

The selected public object is:

```text
(ahb-subordinate ahb_lite_subordinate ...)
```

The generated review artifacts must be:

```text
ahb_lite_subordinate.isf
ahb_lite_subordinate.fsm
```

The selected report schema and support identity are:

```text
fsmgen.ial2.protocol_intent.ahb_subordinate.v1
intent.ppif_ahb_lite_subordinate
```

The next exact owner is `IAL2-FEATURE-COMPLETENESS-FRONTIER.712`, a
no-behavior generated-IAL1/IAL0/SV substrate audit for this selected contract.
`.712` must verify that the public source can lower through generated `.isf`
before generated `.fsm` without bypassing the review boundary. It must not
implement parser or generator behavior.

No parser behavior, generator behavior, public source sample,
support-accounting catalog behavior, capability-manifest behavior, test
behavior, schedule/check/semantic JSON behavior, generated artifact,
HDL/runtime behavior, seed behavior, direct backend behavior,
verification-output generation, backend-language variant, AXI, APB, or VHDL
behavior changed in this selector.

## Naming Policy

The public AHB object name is `ahb-subordinate`.

The backlog and task-tree lane may still use the umbrella phrase
AHB completer/subordinate, but the public AHB profile should use the Arm AHB
term already used by the imported source-reference facts and direct seed:
subordinate. This keeps AHB requester/subordinate naming explicit and avoids
borrowing the APB-specific `apb-completer` object name for AHB source syntax.

The first contract is `.ppif` only. A `.ahb` subordinate profile alias remains
deferred until a later task-tree owner widens the shipped `.ahb` alias beyond
the bounded requester surface.

## Selected Source Shape

The selected future source shape is:

```text
(protocol-platform-intent ahb_lite_subordinate
  (profile ahb)
  (source
    (object fsmgen-ahb-lite-subordinate)
    (anchor
      (document ARM-AMBA-AHB-IHI0033-C-2021-09)
      (section bounded-ahb-lite-subordinate)
      (page first-public-contract)))
  (ahb-subordinate ahb_lite_subordinate
    (role subordinate)
    (clock clk)
    (reset (rst_n active_low async))
    (control
      (wait-cycles wait_cycles width 4))
    (bus
      (select HSEL)
      (ready-in HREADY)
      (address HADDR width 32)
      (transfer HTRANS width 2)
      (write HWRITE)
      (size HSIZE width 3)
      (write-data HWDATA width 32)
      (ready-out HREADYOUT)
      (response HRESP width 1)
      (read-data HRDATA width 32))
    (storage
      (register reg0
        (address 0 width 32)
        (data reg_data_q width 32 reset 0)))
    (transfer ahb_lite_access
      (accept-when (select 1) (ready-in 1))
      (idle 2'b00)
      (busy 2'b01)
      (nonseq 2'b10)
      (seq 2'b11)
      (supported-transfer nonseq)
      (ignored-transfer idle)
      (ignored-transfer busy)
      (wait-cycles wait_cycles)
      (read register)
      (write register)
      (unmapped-address error)
      (unsupported-size error)
      (unsupported-transfer error)
      (response okay 1'b0 error 1'b1)
      (error-completion two-cycle))))
```

The first source shape intentionally mirrors the direct
`fsm/ahb_lite_subordinate.fsm` fixture shipped in `.709`:

- one AHB-Lite/common-AHB subordinate endpoint;
- selected address/control acceptance only when `HSEL=1` and `HREADY=1`;
- `IDLE` and `BUSY` ignored with zero-wait OKAY;
- selected `NONSEQ` word reads/writes only;
- 32-bit `HADDR`, `HWDATA`, and `HRDATA`;
- one 4-bit `wait_cycles` input controlling data-phase wait states;
- one implemented 32-bit register at address `0`;
- one-bit AHB-Lite/common-AHB `HRESP`;
- two-cycle ERROR for unsupported `SEQ`, unsupported sizes, and unmapped
  addresses; and
- generated HDL module `ahb_lite_subordinate`.

## Generated Artifact Contract

The future implementation must lower through:

```text
ppif/ahb_lite_subordinate.ppif -> ahb_lite_subordinate.isf -> ahb_lite_subordinate.fsm -> HDL module ahb_lite_subordinate
```

The generated report must keep:

```text
layering.source_layer = IAL2
layering.generated_ial1_format = isf
layering.generated_ial0_format = fsm
layering.direct_ial2_to_ial0 = 0
```

Direct `.ppif -> .fsm` lowering is not allowed. Directly copying or wrapping
the authored `fsm/ahb_lite_subordinate.fsm` seed is also not the selected
public contract; the generated `.isf` artifact must be reviewable before the
generated `.fsm` artifact is used.

## Report And Support Contract

The selected future report schema is:

```text
fsmgen.ial2.protocol_intent.ahb_subordinate.v1
```

The future report should include:

- `source_object.id = "fsmgen-ahb-lite-subordinate"`;
- `source_object.intent_name = "ahb_lite_subordinate"`;
- `target_protocol.profile = "ahb"`;
- `target_protocol.object = "ahb-subordinate"`;
- `target_protocol.role = "subordinate"`;
- bus, control, storage, transfer, response, and residue summaries;
- generated IAL1 and IAL0 artifact names;
- enforced static rules; and
- explicit unsupported residue.

The selected future support-accounting identity is:

```text
entry_id: intent.ppif_ahb_lite_subordinate
coverage: ial2_ppif_ahb_lite_subordinate_pipeline_cli
source_kind: ppif
```

The selected focused future implementation test file is:

```text
t/1475-ial2-ahb-subordinate.t
```

## Diagnostics And Residue

Before implementation, `(ahb-subordinate ...)` remains unsupported in both
`.ppif` and `.ahb` sources. Diagnostics should stay explicit:

- `.ppif` with `(profile ahb)` and `(ahb-subordinate ...)` should fail as an
  unsupported AHB object until the implementation owner ships;
- `.ahb` with `(ahb-subordinate ...)` should fail as outside the bounded `.ahb`
  requester alias surface until a later alias owner widens it;
- mixed requester/subordinate objects should fail closed until an aggregate
  interconnect/composition contract is selected;
- any object name other than `ahb_lite_subordinate` is out of the first public
  contract;
- any register set beyond the single selected word register is deferred;
- `HBURST`, burst `SEQ` support, wrapping/incrementing burst progression,
  `HPROT`, `HMASTLOCK`, AHB5 optional property/user/parity/check signals,
  exclusive access, multi-manager identity, byte-lane/narrow-transfer policy,
  and legacy two-bit `HRESP` compatibility are deferred; and
- direct backend behavior, verification-output generation, backend-language
  variants, AXI, APB, and VHDL remain deferred.

The selected residue key family should distinguish subordinate endpoint work
from interconnect/decode work, for example:

```text
ahb_subordinate_profile_alias_deferred
ahb_interconnect_generation_deferred
ahb_subordinate_optional_signal_residue
```

The implementation or immediate follow-on owner may refine these keys when
the report surface exists, but the first public subordinate behavior must not
reuse requester-only residue wording that implies no subordinate contract has
been selected.

## Selected `.712` Scope

`.712` should audit the generated-IAL1/IAL0/SV substrate for the selected AHB
subordinate contract before behavior implementation.

It should verify, without changing tracked behavior, whether generated `.isf`
can faithfully express:

- address/control acceptance gated by `HSEL && HREADY`;
- `IDLE`/`BUSY` ignore behavior with zero-wait OKAY;
- selected `NONSEQ` word transfer support;
- unsupported `SEQ` routing to two-cycle ERROR;
- dynamic `wait_cycles` delay using the shipped runtime wait surface;
- storage reset and updates for the implemented register at address `0`;
- read-data return on reads;
- write-data capture on successful mapped writes only;
- unsupported-size and unmapped-address two-cycle ERROR; and
- a generated `.fsm` review artifact equivalent to the bounded lower-layer
  fixture shape.

`.712` must decide whether the next owner can implement directly or must first
repair a smaller substrate gap.

## Validation

Closeout for this selector is documentation-only plus direct AHB behavior
reverification:

```bash
./bin/fsmgen --quiet --strict --check --json fsm/ahb_lite_subordinate.fsm
rg -n 'ahb_lite_subordinate|protocol\.ahb_lite_subordinate' \
  docs/IAL2_AHB_SUBORDINATE_SEED_BEHAVIOR.md \
  perl/FSM/Support/RegressionCorpus.pm t/248-regression-corpus-accounting.t
rg -n 'ppif/ahb_lite_subordinate\.ppif|ahb-subordinate|ahb_subordinate\.v1|intent\.ppif_ahb_lite_subordinate|IAL2-FEATURE-COMPLETENESS-FRONTIER\.712' \
  docs/IAL2_AHB_SUBORDINATE_PUBLIC_CONTRACT_SELECTION.md \
  docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md README.md ROADMAP_V2.md \
  docs/book/src/16c-ial2-ahb.md docs/book/src/14-feature-backlog.md MEMORY.md
knowledge-map/scripts/gen_knowledge_map.sh
knowledge-map/scripts/check_knowledge_map.sh
mdbook build docs/book
scripts/check_memory_architecture.sh
git --no-pager diff --check
scripts/check_doctrines.sh
```

## Rollback

Rollback removes this contract-selection document, its Knowledge Map fact
card, task-tree advancement, README/ROADMAP/mdBook sync, Memory pointer
update, and regenerated Knowledge Map entries. No runtime behavior is
affected.
