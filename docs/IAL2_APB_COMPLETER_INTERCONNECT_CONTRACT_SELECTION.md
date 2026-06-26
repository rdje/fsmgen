# IAL2 APB Completer/Interconnect Contract Selection

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.559`

Date: 2026-06-26

## Outcome

`IAL2-FEATURE-COMPLETENESS-FRONTIER.559` selects a split APB
completer/interconnect contract path.

The first public contract is APB completer generation under the generic
`.ppif` IAL2 container. APB interconnect/composition generation remains a
later contract after the completer path has a generated review-artifact chain.
The bounded `.apb` profile alias remains requester-transfer only until a later
alias owner explicitly widens it.

The next exact owner is `IAL2-FEATURE-COMPLETENESS-FRONTIER.560`, a
no-behavior APB completer generated-IAL1 substrate audit. `.560` must verify
whether the selected APB completer contract can lower through generated `.isf`
before `.fsm` without bypassing the reviewable IAL1 boundary. It must not
implement parser or generator behavior.

No parser behavior, generator behavior, samples, support-accounting catalog,
validation behavior, generated artifacts, tests, schedule/check/semantic JSON,
HDL/runtime behavior, suffix acceptance, direct backend lowering,
verification-output generation, backend-language variants, AXI behavior, APB
behavior, or VHDL behavior changed.

## Split Policy

The combined residue `apb_completer_and_interconnect_generation_deferred` is
split by contract sequence, not by runtime behavior in this slice:

1. APB completer generation is selected first because the repository already
   has a lower-layer `fsm/apb_completer.fsm` target and because an
   interconnect/composition top should compose generated endpoints rather than
   depend on only an authored completer fixture.
2. APB interconnect/composition generation remains deferred until the
   generated APB completer path is selected, verified, and shipped.
3. APB multi-peripheral decode remains separate. A later interconnect owner may
   select the first decode subset, but this completer contract is limited to
   the existing single implemented register address and unmapped-address error
   behavior.

## Selected Source Shape

The first APB completer source uses the generic `.ppif` container:

```text
ppif/apb_completer.ppif
```

The source uses explicit APB profile selection:

```text
(profile apb)
```

The selected first object is:

```text
(apb-completer apb_completer ...)
```

The selected source shape is:

```text
(protocol-platform-intent apb_completer
  (profile apb)
  (source
    (object fsmgen-apb-completer)
    (anchor
      (document FSMGEN-APB-REQUESTER-CAPTURE-WORKSHEET)
      (section completer-model)
      (page stage-1)))
  (apb-completer apb_completer
    (role completer)
    (clock clk)
    (reset (rst_n active_low async))
    (control
      (wait-cycles wait_cycles width 4))
    (bus
      (select PSEL)
      (enable PENABLE)
      (write PWRITE)
      (address PADDR width 32)
      (write-data PWDATA width 32)
      (ready PREADY)
      (read-data PRDATA width 32)
      (error PSLVERR))
    (storage
      (register reg0
        (address 0 width 32)
        (data reg_data_q width 32 reset 0)))
    (transfer apb_complete
      (setup-detect (select 1) (enable 0))
      (wait-cycles wait_cycles)
      (read register)
      (write register)
      (unmapped-address error))))
```

The first source shape intentionally mirrors the existing
`fsm/apb_completer.fsm` fixture:

- one APB completer/target endpoint;
- APB setup detection from `PSEL=1` and `PENABLE=0`;
- 32-bit `PADDR`, `PWDATA`, and `PRDATA`;
- one 4-bit `wait_cycles` input controlling wait-state insertion;
- one implemented register at address `0`;
- `PSLVERR=1` for unmapped addresses; and
- generated HDL module `apb_completer`.

## Generated Artifacts

The selected future generated review artifacts are:

```text
apb_completer.isf
apb_completer.fsm
```

The selected future report must keep:

```text
layering.source_layer = IAL2
layering.generated_ial1_format = isf
layering.generated_ial0_format = fsm
layering.direct_ial2_to_ial0 = 0
```

Direct `.ppif -> .fsm` lowering is not allowed. Directly copying or wrapping
the existing authored `fsm/apb_completer.fsm` is also not the selected public
contract; the generated `.isf` artifact must be reviewable before the
generated `.fsm` artifact is used.

## Report And Support Contract

The selected future report schema is:

```text
fsmgen.ial2.protocol_intent.apb_completer.v1
```

The future report should include:

- `source_object.id = "fsmgen-apb-completer"`;
- `source_object.intent_name = "apb_completer"`;
- `target_protocol.profile = "apb"`;
- `target_protocol.object = "apb-completer"`;
- `target_protocol.role = "completer"`;
- bus, control, storage, and transfer summaries;
- generated IAL1 and IAL0 artifact names;
- enforced static rules; and
- explicit unsupported residue.

The selected future support-accounting identity is:

```text
entry_id: intent.ppif_apb_completer
coverage: ial2_ppif_apb_completer_pipeline_cli
source_kind: ppif
```

When APB completer behavior eventually ships, the requester-transfer residue
should no longer imply that completer generation itself is unselected. The
implementation or immediate follow-on owner should move current public residue
wording toward an interconnect-specific residue such as:

```text
apb_interconnect_generation_deferred
```

That residue movement is behavior/report-surface work and is not performed in
`.559`.

## Profile-Alias Policy

The first APB completer implementation should be `.ppif` only.

The bounded `.apb` profile alias remains limited to:

```text
ppif/apb_requester_transfer.apb
```

and exactly one:

```text
(apb-requester apb_requester ...)
```

object until a later APB profile-alias contract selects `.apb` completer
exposure. This preserves the established sequence used by the requester path:
generic `.ppif` behavior first, then profile-alias widening after a separate
readiness/contract step.

## Diagnostics

Before implementation, `(apb-completer ...)` remains unsupported in both
`.ppif` and `.apb` sources. Diagnostics should stay explicit:

- `.ppif` with `(profile apb)` and `(apb-completer ...)` should fail as an
  unsupported APB object until the implementation owner ships;
- `.apb` with `(apb-completer ...)` should fail as outside the bounded `.apb`
  requester-transfer alias surface until an alias owner widens it;
- mixed requester/completer objects should fail closed until an aggregate
  interconnect/composition contract is selected; and
- APB sidebands, alternate widths, multi-peripheral decode, back-to-back
  policy, direct backend, verification-output generation, backend-language
  variants, and VHDL should remain deferred diagnostics or residue.

## Selected `.560` Scope

`.560` should audit the generated-IAL1 substrate for the selected APB completer
contract before behavior implementation.

It should verify, without changing tracked behavior, whether generated `.isf`
can faithfully express:

- setup detection from `PSEL` and `!PENABLE`;
- dynamic `wait_cycles` delay using the shipped runtime wait surface;
- storage reset and updates for the implemented register at address `0`;
- read-data return on reads;
- write-data capture on writes;
- unmapped-address `PSLVERR`; and
- a generated `.fsm` review artifact equivalent to the bounded lower-layer
  fixture shape.

If `.560` proves the generated-IAL1 substrate is ready, it may select direct
bounded APB `.ppif` completer implementation. If it finds a gap, it should
select the smallest lower-layer or IAL1 prerequisite instead.

## Deferred Alternatives

APB interconnect/composition generation, APB `.apb` completer alias exposure,
multi-peripheral decode, APB sidebands, alternate widths, back-to-back
transfer policy, direct IAL2-to-IAL0 lowering, direct backend lowering,
verification-output generation, backend-language variants, and VHDL remain
future exact-owner work.

## Validation

Closeout for this selector is documentation-only:

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

Rollback is documentation-only: remove this selector, its Knowledge Map fact,
task-tree advancement, README/ROADMAP_V2/mdBook sync, Memory pointer update,
and regenerated Knowledge Map entries. No runtime behavior is affected.
