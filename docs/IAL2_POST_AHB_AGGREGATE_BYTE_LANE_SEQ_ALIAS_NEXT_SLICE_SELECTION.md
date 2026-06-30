# Post AHB Aggregate Byte-Lane In-Word SEQ Alias Next Slice Selection

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.761`

Date: 2026-06-30

## Outcome

`IAL2-FEATURE-COMPLETENESS-FRONTIER.761` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.762`, a no-behavior readiness audit for
bounded AHB HBURST-driven length/wrap `SEQ` semantics after the aggregate
byte-lane in-word `SEQ` `.ahb` alias shipment.

This selector changes no parser behavior, generator behavior, public source
sample, support-accounting catalog, capability manifest, focused test
behavior, schedule/check/semantic JSON behavior, generated artifact,
HDL/runtime behavior, direct backend behavior, verification-output generation,
backend-language variant, AXI/APB behavior, broader AHB behavior, or VHDL
behavior.

## Evidence Read

The selector reads the shipped AHB `SEQ` surfaces and remaining residue:

- `docs/IAL2_AHB_AGGREGATE_BYTE_LANE_SEQ_PROFILE_ALIAS_BEHAVIOR.md`;
- `docs/IAL2_AHB_AGGREGATE_BYTE_LANE_SEQ_BEHAVIOR.md`;
- `docs/IAL2_AHB_BYTE_LANE_SEQ_PROFILE_ALIAS_BEHAVIOR.md`;
- `docs/IAL2_AHB_BYTE_LANE_SEQ_BEHAVIOR.md`;
- `docs/IAL2_AHB_BURST_SEQ_CONTRACT_SELECTION.md`;
- `ppif/ahb_lite_subordinate_byte_lane_seq.ahb`;
- `ppif/ahb_interconnect_byte_lane_seq.ahb`;
- `ppif/ahb_interconnect_two_subordinate_byte_lane_seq.ahb`;
- `README.md`, `ROADMAP_V2.md`, and `docs/book/src/16c-ial2-ahb.md`;
- `docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md` and `docs/TASK_TREE.md`;
  and
- `MEMORY.md` and `KNOWLEDGE_MAP.md`.

Current parser/report probes show the same shared `ahb_burst_seq_support_deferred`
truth across the shipped endpoint and aggregate `SEQ` alias surfaces:

```text
HBURST-driven length/wrap semantics
BUSY-in-burst handling or continuation
multi-word/register-bank SEQ progression
wrapping/incrementing burst address progression beyond requester generation
```

The aggregate aliases have now removed the previous source-surface alias
residue, so the remaining `SEQ` residue is no longer blocked by profile-alias
exposure work.

## Selection Rationale

HBURST length/wrap readiness is the next AHB follow-on because it is the
front-most shared `SEQ` residue now visible on:

- the bounded endpoint byte-lane in-word `SEQ` source and `.ahb` alias; and
- the selected one-subordinate and two-subordinate aggregate byte-lane in-word
  `SEQ` `.ppif` sources and `.ahb` aliases.

It is narrower than optional/property-gated AHB signals, broader
interconnect/decode, scoreboards, full-manager behavior, direct backend
behavior, verification-output generation, backend-language variants, AXI/APB
behavior, and VHDL. It must still be audited before implementation because the
current subordinate bus shape does not yet include HBURST, current aggregate
forwarding deliberately omitted HBURST-to-subordinate behavior, and the
existing first `SEQ` implementation is intentionally limited to byte/halfword
in-word progression.

## Selected `.762` Readiness Audit Scope

`.762` must audit whether the first HBURST length/wrap step should:

- extend the byte-lane `SEQ` subordinate bus contract with `HBURST`;
- introduce a new generic `.ppif` source family or update an existing selected
  source family;
- begin with endpoint-only behavior or include aggregate propagation in the
  same first implementation plan;
- define exact bounded burst kinds, length sources, wrap windows, and
  fail-closed diagnostics;
- decide whether BUSY-in-burst and multi-word/register-bank behavior remain
  separate later owners or are prerequisites for any useful first length/wrap
  subset;
- identify generated `.isf`, `.fsm`, and HDL review-artifact impacts;
- define report keys, residue movement, and preservation expectations; and
- record focused tests, mdBook updates, rollback, and explicit deferrals before
  behavior changes.

## Explicit Deferrals

`.761` does not select implementation. `.762` must not implement behavior. The
following remain deferred until a later exact owner selects them:

- HBURST length/wrap behavior implementation;
- BUSY-in-burst parking/continuation behavior;
- multi-word/register-bank `SEQ` progression;
- optional/property-gated AHB signals;
- broader AHB interconnect/decode cardinality;
- legacy two-bit subordinate `HRESP` compatibility;
- scoreboards and full-manager behavior;
- direct backend behavior;
- verification-output generation;
- backend-language variants;
- AXI/APB behavior; and
- VHDL.

## Validation

Selector validation:

```bash
perl -Iperl -MFSM::Adapter::IAL2::PPIF -e 'for my $p (qw(ppif/ahb_lite_subordinate_byte_lane_seq.ahb ppif/ahb_interconnect_byte_lane_seq.ahb ppif/ahb_interconnect_two_subordinate_byte_lane_seq.ahb)){ my $r=FSM::Adapter::IAL2::PPIF->new->parse_file($p); print "$p\n"; for my $u (@{$r->{report}{unsupported_residue}||[]}){ print "  $u->{id}: $u->{detail}\n" if $u->{id} eq "ahb_burst_seq_support_deferred"; } }'
knowledge-map/scripts/gen_knowledge_map.sh
knowledge-map/scripts/check_knowledge_map.sh
mdbook build docs/book
scripts/check_docs_relative_paths.sh
git --no-pager diff --check
scripts/check_doctrines.sh
```
