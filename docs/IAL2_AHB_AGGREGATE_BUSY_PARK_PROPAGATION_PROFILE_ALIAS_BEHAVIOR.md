# IAL2 AHB Aggregate BUSY-Park Propagation Profile Alias Behavior

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.784`

Date: 2026-07-12

## Outcome

`IAL2-FEATURE-COMPLETENESS-FRONTIER.784` ships the matching bounded public AHB
aggregate BUSY-park HBURST-aware byte-lane `SEQ` `.ahb` profile aliases:

```text
ppif/ahb_interconnect_byte_lane_hburst_seq_busy_park.ahb
ppif/ahb_interconnect_two_subordinate_byte_lane_hburst_seq_busy_park.ahb
```

Each is a byte-identical mirror of the shipped generic BUSY-park `.ppif` source
from `.782`. They support-account as:

```text
entry_id: intent.ahb_profile_alias_interconnect_byte_lane_hburst_seq_busy_park
source_kind: ial2_profile_alias
coverage: ial2_ahb_profile_alias_interconnect_byte_lane_hburst_seq_busy_park_pipeline_cli
module_name: ahb_tb
composition_child_count: 3

entry_id: intent.ahb_profile_alias_interconnect_two_subordinate_byte_lane_hburst_seq_busy_park
source_kind: ial2_profile_alias
coverage: ial2_ahb_profile_alias_interconnect_two_subordinate_byte_lane_hburst_seq_busy_park_pipeline_cli
module_name: ahb_tb
composition_child_count: 4
```

## Alias Behavior

The aliases are pure profile-alias exposure: the same
`protocol-platform-intent` source text carried under the `.ahb` suffix. Because
they are byte-identical mirrors of the generic sources, they produce identical
generated review artifacts (`amba_requester.isf`/`.fsm`, the HBURST SEQ
subordinate `.isf`/`.fsm` or the status/control pair, `ahb_interconnect.isf`/
`.fsm`, aggregate `ahb_tb.fsm`), the same HDL entry module `ahb_tb`, and the
same `composition.byte_lane_propagation` / `composition.seq_policy_propagation`
reports — including each child `seq_policy.parks_on = [busy]` and BUSY-free
`clears_on`.

The only report difference is alias-only residue cleanup. Through the existing
suffix-keyed suppression (no adapter change), the alias reports remove:

- `ahb_aggregate_profile_alias_deferred` (top-level report);
- `ahb_subordinate_profile_alias_deferred` (each embedded child report); and
- the child `.ahb alias exposure` residue wording.

The generic `.ppif` reports keep all three. The narrowed aggregate
`ahb_burst_seq_support_deferred` residue (shipped BUSY-in-burst parking) carries
through unchanged on both surfaces.

After `.799`, the two-subordinate alias and generic surfaces also agree in
`ahb_broader_interconnect_decode_deferred`: parked sources record byte-only
`WRAP4`/`INCR4` in-word `SEQ` propagation with BUSY-in-burst parking as shipped
and do not defer BUSY continuation. The corresponding non-parking `.ahb` and
`.ppif` sources still defer BUSY continuation. Alias cleanup remains limited to
alias-specific residue; it does not rewrite this topology detail.

## Preservation

`.784` preserves the shipped aggregate BUSY-park `.ppif` sources and their
`t/1496` assertions, the non-parking aggregate HBURST `.ahb` aliases and
`t/1493` (they keep `BUSY-in-burst handling` deferred and gain no `parks_on`),
the endpoint BUSY-park `.ahb` alias and `t/1495`, and all shipped AHB behavior.

`.799` adds paired generic/alias wording checks in `t/1496`/`t/1497` and
non-parking preservation checks in `t/1492`/`t/1493`; it changes no source,
artifact, support identity/count, or HDL behavior.

## Focused Test And Accounting

- Add `t/1497-ial2-ahb-interconnect-byte-lane-hburst-seq-busy-park-profile-alias.t`
  (byte-identical mirror check, both aliases, generic parity, preserved
  `parks_on`/`clears_on`, alias-only residue cleanup, malformed fail-closed, CLI
  check/schedule/outdir).
- `t/248` moves 295 → 297 protocol / 336 → 338 total supported-smoke entries.
- `t/297` capability-manifest `.ahb` boundary/fixtures assertions extend for the
  two new aliases.

## Explicit Non-Selections

`.784` adds no requester-side BUSY insertion, halfword/word burst `SEQ`, wider
or indefinite bursts, multi-word/register-bank progression, optional AHB
signals, broader interconnect/decode, direct backend behavior,
verification-output generation, backend-language variants, AXI/APB behavior, or
VHDL behavior.

## Validation

```bash
perl -Iperl -c perl/FSM/Support/RegressionCorpus.pm
perl -Iperl -c perl/FSM/Support/LanguageSurfaceSection.pm
prove -Iperl t/1497-ial2-ahb-interconnect-byte-lane-hburst-seq-busy-park-profile-alias.t
prove -Iperl t/1493-ial2-ahb-interconnect-byte-lane-hburst-seq-profile-alias.t t/1495-ial2-ahb-subordinate-byte-lane-hburst-seq-busy-park-profile-alias.t t/1496-ial2-ahb-interconnect-byte-lane-hburst-seq-busy-park.t t/248-regression-corpus-accounting.t t/297-capability-manifest.t
```

The two-subordinate `--check` is slow (~63s); run heavy `prove`/`fsmgen` under
`scripts/run_with_ram_guard.sh` or equivalent monitoring.
