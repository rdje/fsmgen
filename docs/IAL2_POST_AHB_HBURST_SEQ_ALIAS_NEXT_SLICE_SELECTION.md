# IAL2 Post-AHB HBURST SEQ Alias Next Slice Selection

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.767`

Date: 2026-06-30

## Outcome

`IAL2-FEATURE-COMPLETENESS-FRONTIER.767` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.768`, a no-behavior readiness audit for
bounded aggregate AHB HBURST propagation after the endpoint HBURST-aware
byte-lane `SEQ` `.ppif` source and matching `.ahb` alias are both shipped.

This selector changes no parser behavior, generator behavior, public source
sample, support-accounting catalog, capability-manifest behavior, focused test
behavior, schedule/check/semantic JSON behavior, generated artifact,
HDL/runtime behavior, direct-backend behavior, verification-output generation,
backend-language variant, AXI/APB behavior, broader AHB behavior, or VHDL
behavior.

## Evidence Read

The selector read the `.766` HBURST-aware alias behavior, `.765` selector,
`.764` generic endpoint behavior, `.762` readiness audit, existing aggregate
byte-lane and aggregate byte-lane `SEQ` `.ppif/.ahb` behavior, aggregate
source samples, AHB requester/subordinate/interconnect code owners, support
accounting, language-surface and capability boundaries, focused AHB tests,
README, ROADMAP_V2, the AHB mdBook chapter, the feature backlog, the active
task tree, Memory, Knowledge Map, and relevant decisions.

Relevant decisions remain:

- `0014`, protocol/platform intent uses layered lowering;
- `0015`, protocol-specific extensions are profile aliases over IAL2;
- `0016`, `.ppif` is the first generic IAL2 container;
- `0018`, IAL contracts and the mdBook are backend-language-neutral; and
- `0003`, `0005`, `0006`, and `0007` for autonomous PNT, push gating,
  mdBook synchronization, and frozen legacy blobs.

## Current Aggregate Evidence

The shipped aggregate byte-lane `SEQ` sources still strict-check as-is:

```text
ppif/ahb_interconnect_byte_lane_seq.ppif
ppif/ahb_interconnect_two_subordinate_byte_lane_seq.ppif
```

Both sources expose requester/top-level HBURST as global AHB bus wiring, but
their embedded subordinates still use the pre-HBURST byte-lane `SEQ` endpoint
contracts:

```text
subordinate transfer = ahb_lite_byte_lane_seq_access
subordinate seq_policy.mode = in_word_progressive
subordinate bus burst binding = absent
```

The one-subordinate aggregate schedule/report JSON confirms that current
`composition.seq_policy_propagation.request_forwarding` includes address,
ready, size, transfer, write, and write-data forwarding, but no burst/HBURST
forwarding. The top-level wiring includes `HBURST`, and the requester child
includes `bindings.bus.burst`, but the subordinate child binding does not.

`AhbInterconnect` currently selects `composition.seq_policy_propagation` only
when all subordinates match the older `in_word_progressive` byte-lane policy.
It does not yet accept child `transfer.seq_policy.mode =
hburst_in_word_progressive`, does not report subordinate-local HBURST
forwarding, and its selected residue still says HBURST-driven length/wrap
semantics remain future work.

## Temporary Candidate Probes

Two temporary `/tmp` probes rewired the existing aggregate `SEQ` sources to
the already-shipped HBURST-aware endpoint shape without touching repository
files.

The one-subordinate candidate changed the child to:

```text
object = ahb_lite_subordinate_byte_lane_hburst_seq
transfer = ahb_lite_byte_lane_hburst_seq_access
subordinate bus = (burst HBURST_REGS width 3)
seq-policy = hburst-in-word-progressive
```

Schedule/report JSON lowered far enough to show the child
`bindings.bus.burst.name = HBURST_REGS` and
`transfer.seq_policy.mode = hburst_in_word_progressive`, but strict check
failed closed because the generated composition left `regs.HBURST_REGS`
unconnected.

The two-subordinate candidate changed the children to local
`HBURST_STATUS` and `HBURST_CONTROL` bindings. Its schedule/report JSON also
lowered far enough to show local child HBURST bindings, but strict check
failed closed because the generated composition left
`status.HBURST_STATUS` unconnected.

These probes make the next step a readiness audit rather than direct
implementation: the aggregate stack must first select the exact subordinate
HBURST forwarding contract, report movement, top-port policy, child-port
connection policy, and candidate source family before behavior changes.

## Selected `.768` Scope

`.768` owns a no-behavior readiness audit for bounded aggregate AHB HBURST
propagation. It must decide whether the next behavior-bearing owner can be a
direct implementation or whether a public contract selection or narrower
wiring/report prerequisite must come first.

The audit must cover:

- one-subordinate and two-subordinate aggregate byte-lane `SEQ` sources;
- candidate source names and whether aggregate HBURST propagation widens
  existing `*_byte_lane_seq` samples or adds new `*_byte_lane_hburst_seq`
  samples;
- subordinate-local HBURST signal naming and top-level connection policy;
- child endpoint object and transfer names;
- `composition.seq_policy_propagation` acceptance for
  `hburst_in_word_progressive`;
- report keys, generated artifact names, support identities, coverage keys,
  language-surface entries, capability-manifest expectations, focused tests,
  mdBook examples, and residue movement;
- strict fail-closed behavior for unsupported or partially wired aggregate
  HBURST shapes; and
- rollback and preservation boundaries for existing endpoint, requester, and
  aggregate `.ppif/.ahb` behavior.

## Explicit Non-Selections

`.768` must not implement aggregate HBURST forwarding, add public aggregate
HBURST sources, add matching aggregate `.ahb` aliases, change endpoint
HBURST behavior, change requester HBURST behavior, change existing aggregate
byte-lane `SEQ` behavior, add BUSY-in-burst parking, add halfword/word burst
`SEQ`, add wider or indefinite bursts, add multi-word/register-bank
progression, add optional/property-gated AHB signals, add legacy two-bit
subordinate `HRESP`, broaden interconnect/decode, add scoreboards, add
full-manager behavior, add direct backend behavior, add verification-output
generation, add backend-language variants, add AXI/APB behavior, add broader
AHB behavior, or add VHDL behavior.

## Validation

Closeout for `.767` is documentation-only plus targeted current-state probes:

The `/tmp` candidate files below were temporary probes created from the
tracked aggregate sources during the selector and removed after closeout; rerun
the candidate checks only after recreating those temporary sources from the
documented probe shapes.

```bash
./bin/fsmgen --quiet --strict --check --json ppif/ahb_interconnect_byte_lane_seq.ppif
./bin/fsmgen --quiet --strict --check --json ppif/ahb_interconnect_two_subordinate_byte_lane_seq.ppif
./bin/fsmgen --quiet --emit-schedule-json ppif/ahb_interconnect_byte_lane_seq.ppif
./bin/fsmgen --quiet --strict --check --json /tmp/fsmgen-ahb-interconnect-hburst-candidate.ppif
./bin/fsmgen --quiet --emit-schedule-json /tmp/fsmgen-ahb-interconnect-hburst-candidate.ppif
./bin/fsmgen --quiet --strict --check --json /tmp/fsmgen-ahb-interconnect-two-hburst-candidate.ppif
./bin/fsmgen --quiet --emit-schedule-json /tmp/fsmgen-ahb-interconnect-two-hburst-candidate.ppif
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

Rollback is documentation-only: remove this selector, its Knowledge Map fact
card, task-tree advancement, README/ROADMAP_V2/mdBook sync, Memory pointer
update, and regenerated Knowledge Map entries. No runtime behavior is affected.
