# IAL2 Post-AHB Aggregate Alias Residue Cleanup Next Slice Selection

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.749`

Date: 2026-06-30

## Outcome

`IAL2-FEATURE-COMPLETENESS-FRONTIER.749` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.750`, a no-behavior readiness audit for
bounded AHB burst `SEQ` continuation.

This selector changes no parser behavior, generator behavior, public source
sample, support-accounting catalog, capability manifest, focused test
behavior, schedule/check/semantic JSON behavior, generated artifact,
HDL/runtime behavior, direct backend behavior, verification-output generation,
backend-language variant, AXI behavior, APB behavior, broader AHB behavior, or
VHDL behavior.

## Current Boundary

The shipped AHB public surface now includes requester, word-only subordinate,
byte-lane subordinate, one-subordinate aggregate interconnect, two-subordinate
aggregate interconnect, aggregate byte-lane propagation, and matching `.ahb`
profile aliases for those selected bounded sources.

`IAL2-FEATURE-COMPLETENESS-FRONTIER.748` cleaned stale nested endpoint
profile-alias residue from aggregate `.ahb` reports. Current aggregate `.ahb`
reports now expose only true remaining AHB backlog, including:

```text
ahb_multi_subordinate_decode_deferred
ahb_broader_interconnect_decode_deferred
ahb_completer_subordinate_deferred
ahb_interconnect_decode_deferred
ahb_full_manager_deferred
ahb_interconnect_generation_deferred
ahb_optional_signal_residue
ahb_subordinate_optional_signal_residue
ahb_burst_seq_support_deferred
ahb_direct_backend_deferred
ahb_verification_output_deferred
```

## Current Probe Evidence

Focused in-process adapter probes confirmed:

- endpoint `.ahb` requester reports still defer completer/subordinate,
  interconnect/decode, full-manager, and verification-output behavior;
- endpoint `.ahb` subordinate reports still defer interconnect generation,
  optional subordinate signals, burst `SEQ`, and verification-output behavior;
- aggregate `.ahb` reports no longer carry aggregate or endpoint profile-alias
  residue;
- aggregate `.ahb` reports still carry topology, optional-signal, burst,
  direct-backend, and verification-output residue;
- generic aggregate `.ppif` reports intentionally keep profile-alias
  source-surface residue; and
- byte-lane aggregate `.ppif/.ahb` behavior is shipped and no longer the
  narrowest missing AHB transfer feature.

## Why Burst SEQ Readiness Comes Next

Burst `SEQ` continuation is now the narrowest protocol-behavior candidate that
is shared by endpoint subordinate and aggregate reports after byte-lane and
alias cleanup shipped. It is more focused than optional/property-gated signal
policy, broader interconnect/decode cardinality, full-manager behavior,
scoreboards, direct backend behavior, verification-output generation,
backend-language variants, or VHDL.

It still requires a readiness audit before any implementation because current
behavior explicitly treats `SEQ` as unsupported burst continuation and returns
ERROR. The next audit must determine whether the first bounded burst owner is:

- subordinate-only `SEQ` acceptance for local same-word or next-word transfer
  progression;
- requester-side burst generation;
- aggregate propagation of selected burst policy;
- report/static-validation cleanup before behavior; or
- a smaller generated-IAL1/IAL0 substrate prerequisite.

## Explicit Non-Selections

`.749` does not select direct implementation of burst behavior. It also does
not select optional/property-gated AHB signals because `HBURST`, `HPROT`,
`HMASTLOCK`, AHB5 optional signals, security, exclusive, user, parity, and
protection-policy effects require separate policy boundaries.

It does not select broader interconnect/decode next because one- and
two-subordinate aggregate families, including byte-lane variants, are already
shipped, while burst `SEQ` remains visible in both endpoint and aggregate
residue.

It does not select legacy two-bit subordinate `HRESP`, scoreboards,
full-manager behavior, direct backend behavior, verification-output
generation, backend-language variants, AXI/APB behavior, or VHDL behavior.

## Selected `.750` Audit

`.750` must audit bounded AHB burst `SEQ` continuation readiness and select the
next exact owner or prerequisite before behavior changes. It must read:

- shipped AHB requester/subordinate/interconnect `.ppif/.ahb` behavior;
- byte-lane/narrow-transfer subordinate and aggregate behavior;
- current `ahb_burst_seq_support_deferred` report details;
- generated `.isf` and `.fsm` substrate for subordinate and aggregate paths;
- focused AHB tests;
- README, ROADMAP_V2, mdBook, task tree, Memory, Knowledge Map; and
- relevant decisions.

The audit must decide:

- whether the first bounded burst owner is subordinate, requester, aggregate,
  report-only, or substrate-only;
- whether `SEQ` acceptance can be bounded without full manager behavior;
- whether address progression uses current local address signals and selected
  byte-lane policy;
- how unsupported burst shapes remain fail-closed;
- what report/residue movement is selected;
- which focused tests/probes are required;
- rollback boundaries; and
- explicit deferrals.

## Validation

`.749` validates current state only. Closeout must run Knowledge Map
generation/check, mdBook build, docs path audit, memory architecture check,
diff check, and the doctrine driver. Broad or potentially heavyweight
Perl/`prove`/`fsmgen` commands must remain RAM-guarded.
