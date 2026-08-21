---
id: ial2-ahb-paired-subordinate-claim-evidence
title: AHB paired BUSY, phase-pipeline, and subordinate-shape claims retain distinct evidence
answers:
  - "how are paired AHB BUSY and subordinate claims verified?"
  - "which two-window AHB BUSY counts are current versus historical?"
  - "how is AHB completion-edge phase recapture verified?"
  - "how are fixed-wrap repairs separated from pre-repair AHB measurements?"
  - "how are AHB subordinate storage and width claims falsified?"
date: 2026-08-21
status: current
tags: [claim-verification, ial2, ahb, paired-busy, subordinate, pipeline, wrap, evidence]
evidence: >-
  doctrine/claim_verification/inventory.jsonl;
  doctrine/claim_verification/dispositions.jsonl;
  perl/FSM/IAL2/ProtocolIntent/AhbInterconnect.pm;
  perl/FSM/IAL2/ProtocolIntent/AhbRequester.pm;
  perl/FSM/IAL2/ProtocolIntent/AhbSubordinate.pm;
  fsm/amba_requester.fsm;
  ppif/ahb_lite_subordinate.ppif;
  ppif/ahb_requester.ppif;
  ppif/ahb_interconnect_requester_busy_insert_byte_lane_hburst_seq_busy_park.ppif;
  ppif/ahb_interconnect_requester_busy_insert_byte_lane_hburst_seq_busy_park.ahb;
  ppif/ahb_interconnect_requester_busy_insert_two_subordinate_byte_lane_hburst_seq_busy_park.ppif;
  ppif/ahb_interconnect_requester_busy_insert_two_subordinate_byte_lane_hburst_seq_busy_park.ahb;
  t/1475-ial2-ahb-subordinate.t;
  t/1492-ial2-ahb-interconnect-byte-lane-hburst-seq.t;
  t/1493-ial2-ahb-interconnect-byte-lane-hburst-seq-profile-alias.t;
  t/1496-ial2-ahb-interconnect-byte-lane-hburst-seq-busy-park.t;
  t/1497-ial2-ahb-interconnect-byte-lane-hburst-seq-busy-park-profile-alias.t;
  t/1513-ial2-ahb-paired-busy-composition.t;
  t/1514-ial2-ahb-paired-busy-composition-profile-alias.t;
  t/1515-ial2-ahb-two-subordinate-paired-busy-composition.t;
  t/1516-ial2-ahb-two-subordinate-paired-busy-composition-profile-alias.t;
  t/1517-ial2-ahb-requester-wrap-progression-audit.t;
  t/1518-ial2-ahb-mdbook-current-surface-truthfulness.t;
  t/1519-ial2-ahb-pipelined-active-transfer-audit.t;
  docs/tasks/CLAIM-VERIFICATION-ADOPTION.md
reverify: >-
  scripts/check_claim_verification_dispositions.pl --report &&
  scripts/run_with_ram_guard.sh --host-max-pct 100 --process-max-rss-mb 4096 --
  prove -Iperl t/1475-ial2-ahb-subordinate.t
  t/1492-ial2-ahb-interconnect-byte-lane-hburst-seq.t
  t/1493-ial2-ahb-interconnect-byte-lane-hburst-seq-profile-alias.t
  t/1496-ial2-ahb-interconnect-byte-lane-hburst-seq-busy-park.t
  t/1497-ial2-ahb-interconnect-byte-lane-hburst-seq-busy-park-profile-alias.t
  t/1513-ial2-ahb-paired-busy-composition.t
  t/1514-ial2-ahb-paired-busy-composition-profile-alias.t
  t/1515-ial2-ahb-two-subordinate-paired-busy-composition.t
  t/1516-ial2-ahb-two-subordinate-paired-busy-composition-profile-alias.t
  t/1517-ial2-ahb-requester-wrap-progression-audit.t
  t/1518-ial2-ahb-mdbook-current-surface-truthfulness.t
  t/1519-ial2-ahb-pipelined-active-transfer-audit.t &&
  prove -Iperl t/248-regression-corpus-accounting.t
  t/297-capability-manifest.t t/1638-claim-verification-dispositions.t
---

`CLAIM-VERIFICATION-ADOPTION.5.5.3` reviews the exact 34 inventory
candidates on `docs/book/src/16c-ial2-ahb.md` lines 1657 through 2037. Seven
current topology, runtime, WRAP, phase-pipeline, storage, and width statements
use derived gates. Twenty-seven test/task locators, readiness measurements,
contract inputs, shipment totals, and pre-repair failures use reviewed-
incidental dispositions.

The seven current gates remain deliberately separate:

- two-window paired report topology, windows, semantic root, and artifacts;
- two-window status/control BUSY runtime and independent storage;
- corrected generated/direct fixed-wrap address progression;
- atomic completion-edge active-phase recapture;
- exactly one subordinate register at address zero;
- 32-bit subordinate address/data/register fields; and
- two-bit `HTRANS`, three-bit `HSIZE`, four-bit `wait_cycles`, and one-bit
  `HRESP`.

The two-window source directly reports module `ahb_tb`, four children, 29
signals, semantic root `top`, status `[0,4)`, control `[4,8)`, four IAL1
artifacts, and five IAL0 artifacts. Its assertion-enabled runtime drives
status-base-zero and control-base-four byte `INCR4` commands. Each retains its
selected child's state/storage across one qualified BUSY presentation,
completes four data beats, leaves the unselected child unchanged, and produces
final status/control storage `32'h44332211` / `32'h88776655`; the control
window independently checks global-to-local address subtraction.

The phase gate is distinct from paired BUSY behavior. The subordinate banks
one accepted address/control phase, the requester separates address and data
ownership, and the interconnect retains a one-hot data-phase owner with same-
edge replacement. The phase oracle requires exactly two acceptances and two
completions for boundary-free `NONSEQ`-to-`SEQ`, and separates final-ERROR
active capture from `IDLE` cancellation. It does not claim a deeper
outstanding queue.

The fixed-wrap gate likewise describes only repaired current behavior. It
checks byte/halfword/word `WRAP4` and byte `WRAP8`/`WRAP16`, including byte
`WRAP4` start three as `3,0,1,2`. The earlier skipped-base bus sequence and
`32'h00000011` dropped-phase storage result remain historical measurements at
commits `ec9fa2ee3a8a25de863d1d6c22564fbd871b6d99` and
`5cbed61ccb6457d9cc2e3158b3624adf3c188d28`; they are not current defects.

Readiness and selection values at commits
`262c1ad1012f66c63cfbe7e7ae5cb7e463a5fe67`,
`77c3196817103f947f3a661fe41a9c83ecb5f6f3`, and
`fae20f5e377e72d39746569e5bf8499a8df32c45`, plus the 313/354 and 314/355
shipment checkpoints at `7e5b9f24876dc99818127a159381fcd8bbeb296d` and
`f5083339cd10abf22154828c22d891f639dea1be`, remain immutable chronology.
Current support accounting and the shipped runtime/topology gates are derived
independently.
