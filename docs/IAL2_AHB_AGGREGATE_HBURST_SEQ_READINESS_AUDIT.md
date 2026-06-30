# IAL2 AHB Aggregate HBURST SEQ Readiness Audit

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.768`

Date: 2026-06-30

## Outcome

`IAL2-FEATURE-COMPLETENESS-FRONTIER.768` audits bounded aggregate AHB
HBURST-aware byte-lane `SEQ` propagation readiness and selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.769`, a no-behavior public contract
selection for a combined bounded generic `.ppif` aggregate HBURST propagation
family.

Direct implementation is not selected in this slice. The endpoint
HBURST-aware subordinate source and matching `.ahb` alias are shipped, and the
aggregate top already carries requester/global `HBURST`, but the aggregate
source family, child-local HBURST names, support identities, report contract,
residue movement, validation matrix, and later `.ahb` alias sequence are not
yet selected.

This audit changes no parser behavior, generator behavior, public source
sample, support-accounting catalog, capability-manifest behavior, focused test
behavior, schedule/check/semantic JSON behavior, generated artifact,
HDL/runtime behavior, direct-backend behavior, verification-output generation,
backend-language variant, AXI/APB behavior, broader AHB behavior, or VHDL
behavior.

## Evidence Read

The audit read:

- `.767`, the selector after endpoint HBURST `.ahb` alias shipment;
- `.766`, matching endpoint HBURST `.ahb` alias behavior;
- `.764`, generic endpoint HBURST-aware byte-lane `SEQ` behavior;
- `.762`, HBURST length/wrap readiness audit;
- aggregate byte-lane `SEQ` `.ppif/.ahb` behavior records;
- `ppif/ahb_interconnect_byte_lane_seq.ppif`;
- `ppif/ahb_interconnect_two_subordinate_byte_lane_seq.ppif`;
- `perl/FSM/Adapter/IAL2/PPIF.pm`;
- `perl/FSM/IAL2/ProtocolIntent/AhbInterconnect.pm`;
- `perl/FSM/IAL2/ProtocolIntent/AhbSubordinate.pm`;
- `perl/FSM/IAL2/ProtocolIntent/AhbRequester.pm`;
- support-accounting, language-surface, and capability boundaries;
- focused AHB tests;
- README, ROADMAP_V2, mdBook backlog/AHB chapter, task tree, Memory,
  Knowledge Map, and decisions `0014`, `0015`, `0016`, and `0018`.

## Current Boundary

The endpoint HBURST-aware byte-lane `SEQ` subordinate is shipped through both
selected public source surfaces:

```text
ppif/ahb_lite_subordinate_byte_lane_hburst_seq.ppif
ppif/ahb_lite_subordinate_byte_lane_hburst_seq.ahb
```

The selected aggregate byte-lane `SEQ` sources are still pre-HBURST at their
embedded subordinate endpoints:

```text
ppif/ahb_interconnect_byte_lane_seq.ppif
ppif/ahb_interconnect_two_subordinate_byte_lane_seq.ppif
ppif/ahb_interconnect_byte_lane_seq.ahb
ppif/ahb_interconnect_two_subordinate_byte_lane_seq.ahb
```

Those aggregate sources instantiate `ahb_lite_byte_lane_seq_access`, not
`ahb_lite_byte_lane_hburst_seq_access`, and their embedded subordinate bus
contracts have no `(burst ...)` binding. Their requester/top-level AHB bus
wiring does include `HBURST`.

## Current Implementation Boundary

The current aggregate top already wires requester `HBURST` to the generated
interconnect/fabric child. It also wires requester `HTRANS`, `HWRITE`,
`HSIZE`, and `HWDATA` directly to each subordinate child, while the generated
fabric drives selected-subordinate `HSEL_*` and local `HADDR_*`.

There is no corresponding subordinate-local HBURST child wiring today. A
temporary one-subordinate aggregate HBURST candidate lowered far enough to
show child `bindings.bus.burst.name = HBURST_REGS` and
`transfer.seq_policy.mode = hburst_in_word_progressive`, then failed strict
check because `regs.HBURST_REGS` was left unconnected.

A temporary two-subordinate aggregate HBURST candidate lowered far enough to
show local child HBURST bindings for `HBURST_STATUS` and `HBURST_CONTROL`,
then failed strict check because `status.HBURST_STATUS` was left unconnected.

The generated composition-wiring gap is specific and bounded: an eventual
implementation can wire requester/global `HBURST` to each subordinate-local
HBURST child input in the same fanout style already used for `HTRANS`,
`HWRITE`, `HSIZE`, and `HWDATA`.

## Report Gap

`AhbInterconnect` currently selects `composition.seq_policy_propagation` only
when every subordinate has the older byte-lane `in_word_progressive` policy:

```text
transfer.name = ahb_lite_byte_lane_seq_access
transfer.seq_policy.mode = in_word_progressive
supported_seq_size = [byte, halfword]
```

It does not yet recognize:

```text
transfer.name = ahb_lite_byte_lane_hburst_seq_access
transfer.seq_policy.mode = hburst_in_word_progressive
supported_hburst_modes = [WRAP4, INCR4]
supported_seq_size = [byte]
```

Current aggregate `composition.seq_policy_propagation.request_forwarding`
also omits `burst`, and the selected aggregate residue still says
HBURST-driven length/wrap semantics remain future work.

## Readiness Decision

No endpoint generator substrate repair is required before contract selection:
the HBURST-aware endpoint source already parses, reports, emits generated
review artifacts, and lowers through HDL on its own.

No broad composition rewrite is required before contract selection: the
failure mode is the missing subordinate-local HBURST child connection, while
the existing aggregate top already handles selected-subordinate address,
select, ready/response/data muxing, and direct requester-to-subordinate
control/data fanout.

Direct implementation is still not selected. The next slice must first select
the public aggregate source paths, child object names, subordinate-local
HBURST signal names, support identities, coverage keys, report schema,
residue movement, fail-closed behavior, validation matrix, and later aggregate
`.ahb` alias sequencing.

## Selected `.769` Contract Selector

`.769` must select the public contract for a combined bounded generic `.ppif`
aggregate HBURST-aware byte-lane `SEQ` propagation family.

Likely source names are:

```text
ppif/ahb_interconnect_byte_lane_hburst_seq.ppif
ppif/ahb_interconnect_two_subordinate_byte_lane_hburst_seq.ppif
```

Likely one-subordinate identity:

```text
intent_name: ahb_interconnect_byte_lane_hburst_seq
source object: fsmgen-ahb-interconnect-byte-lane-hburst-seq
subordinate object: ahb_lite_subordinate_byte_lane_hburst_seq
child binding: (subordinate regs ahb_lite_subordinate_byte_lane_hburst_seq)
subordinate burst binding: (burst HBURST_REGS width 3)
generated IAL1: amba_requester.isf, ahb_lite_subordinate_byte_lane_hburst_seq.isf, ahb_interconnect.isf
generated IAL0: amba_requester.fsm, ahb_lite_subordinate_byte_lane_hburst_seq.fsm, ahb_interconnect.fsm, ahb_tb.fsm
HDL entry: ahb_tb
```

Likely two-subordinate identity:

```text
intent_name: ahb_interconnect_two_subordinate_byte_lane_hburst_seq
source object: fsmgen-ahb-interconnect-two-subordinate-byte-lane-hburst-seq
subordinate objects: ahb_status_subordinate_byte_lane_hburst_seq, ahb_control_subordinate_byte_lane_hburst_seq
child bindings: (subordinate status ahb_status_subordinate_byte_lane_hburst_seq), (subordinate control ahb_control_subordinate_byte_lane_hburst_seq)
subordinate burst bindings: (burst HBURST_STATUS width 3), (burst HBURST_CONTROL width 3)
generated IAL1: amba_requester.isf, ahb_status_subordinate_byte_lane_hburst_seq.isf, ahb_control_subordinate_byte_lane_hburst_seq.isf, ahb_interconnect.isf
generated IAL0: amba_requester.fsm, ahb_status_subordinate_byte_lane_hburst_seq.fsm, ahb_control_subordinate_byte_lane_hburst_seq.fsm, ahb_interconnect.fsm, ahb_tb.fsm
HDL entry: ahb_tb
```

`.769` may adjust those names only if it records a stronger exact contract
before selecting implementation.

## Contract Questions For `.769`

The contract selector must settle:

- exact source paths, intent names, source-object anchors, support identities,
  coverage keys, and source kind;
- whether one-subordinate and two-subordinate aggregate HBURST sources ship in
  one implementation slice;
- subordinate-local HBURST signal naming and duplicate-local-signal rules;
- whether child HBURST fanout is from requester/global `HBURST` directly or
  through the generated interconnect/fabric child;
- generated child artifact names for selected `*_byte_lane_hburst_seq`
  subordinates;
- whether aggregate reports reuse `composition.seq_policy_propagation` with a
  new mode or add a separate named aggregate HBURST propagation block;
- whether request-forwarding reports include `burst`;
- which top-level and child `ahb_burst_seq_support_deferred` wording is
  removed for the selected aggregate HBURST sources while retaining true
  BUSY-in-burst, halfword/word burst `SEQ`, wider/indefinite burst,
  multi-word/register-bank, optional-signal, broader AHB, direct-backend,
  verification-output, backend-variant, AXI/APB, and VHDL residue;
- strict diagnostics for partially wired or unsupported aggregate HBURST
  shapes;
- focused tests, preservation matrix, docs/mdBook updates, Knowledge Map, and
  rollback; and
- later matching aggregate `.ahb` alias sequencing.

## Explicit Deferrals

Aggregate HBURST implementation, matching aggregate `.ahb` aliases,
BUSY-in-burst parking, halfword/word burst `SEQ`, wider or indefinite bursts,
multi-word/register-bank progression, optional/property-gated AHB signals,
legacy two-bit subordinate `HRESP`, broader interconnect/decode, scoreboards,
full-manager behavior, direct backend behavior, verification-output
generation, backend-language variants, AXI/APB behavior, broader AHB behavior,
and VHDL remain deferred.

## Validation

Closeout for `.768` is documentation-only plus targeted current-state probes
from `.767` and code-read audit:

```bash
./bin/fsmgen --quiet --strict --check --json ppif/ahb_interconnect_byte_lane_seq.ppif
./bin/fsmgen --quiet --strict --check --json ppif/ahb_interconnect_two_subordinate_byte_lane_seq.ppif
./bin/fsmgen --quiet --emit-schedule-json ppif/ahb_interconnect_byte_lane_seq.ppif
./bin/fsmgen --quiet --emit-schedule-json ppif/ahb_interconnect_two_subordinate_byte_lane_seq.ppif
knowledge-map/scripts/gen_knowledge_map.sh
knowledge-map/scripts/check_knowledge_map.sh
mdbook build docs/book
scripts/check_docs_relative_paths.sh
git --no-pager diff --check
scripts/check_doctrines.sh
```

Broad or potentially heavyweight Perl, `prove`, or `fsmgen` commands remain
behind `scripts/run_with_ram_guard.sh` or equivalent monitoring.

## Rollback

Rollback is documentation-only: remove this audit, its Knowledge Map fact
card, task-tree advancement, README/ROADMAP_V2/mdBook sync, Memory pointer
update, and regenerated Knowledge Map entries. No runtime behavior is affected.
