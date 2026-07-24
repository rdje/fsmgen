# IAL2 AHB Requester BUSY-Insertion `.ahb` Profile Alias Behavior

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.790`

Date: 2026-07-24

## Outcome

FSMGen ships the bounded requester BUSY-insertion source through both the
generic IAL2 container and matching AHB vocabulary alias:

```text
ppif/ahb_requester_busy_insert.ppif
ppif/ahb_requester_busy_insert.ahb
```

The files are byte-identical. Both declare `(profile ahb)`, lower through the
same generated IAL1 and IAL0 artifacts, and generate the same HDL module. The
`.ahb` suffix is a profile alias over IAL2, not a separate language or a direct
lowering route.

## Preserved Behavior

The alias preserves the generic source's bounded transfer contract:

```text
(busy 2'b01)
(busy-before-beat 2)
```

For an `INCR4`, generated behavior presents
`NONSEQ(0) -> SEQ(1) -> BUSY(2 held) -> SEQ(2 resumed) -> SEQ(3)`. The BUSY
episode holds the pending address/control/write-data and counters, skips
response advancement, and does not consume a data beat. Exactly four data
beats are accepted.

Current cardinality: the alias is byte-identical to the generic source and now
retires exactly one `HGRANT && HREADY && HTRANS == BUSY` event per command.
The pending BUSY remains stable through ready or grant stalls and resumes the
same `SEQ` transfer. `beats=single` is therefore exact for both suffixes;
multiple-BUSY behavior remains deferred.

The alias preserves:

- report schema `fsmgen.ial2.protocol_intent.ahb_requester.v1`;
- `busy_insertion.generated_behavior = true`;
- `busy_insertion.htrans_busy_encoding = 2'b01`;
- `busy_insertion.before_beat = 2` and `beats = single`;
- generated `amba_requester_busy_insert.isf` then
  `amba_requester_busy_insert.fsm`;
- HDL module `amba_requester_busy_insert`; and
- `ahb_requester_busy_insert_support`, which records the shipped bounded subset
  and broader BUSY deferrals.

Existing suffix-keyed handling removes only `ahb_profile_alias_deferred` from
the `.ahb` report. The generic `.ppif` report keeps that source-surface residue.
No parser or generator code changed for the alias.

## Support Accounting

```text
support id:      intent.ahb_profile_alias_requester_busy_insert
coverage:        ial2_ahb_profile_alias_requester_busy_insert_pipeline_cli
source kind:     ial2_profile_alias
classification:  supported_smoke
strict:          supported
semantic root:   fsm
HDL module:      amba_requester_busy_insert
```

The support corpus moves from 309 to 310 protocol fixtures and from 350 to 351
supported-smoke/strict entries.

## Run It

```bash
./bin/fsmgen --quiet --strict --check --json ppif/ahb_requester_busy_insert.ahb
./bin/fsmgen --quiet --emit-schedule-json ppif/ahb_requester_busy_insert.ahb
./bin/fsmgen --quiet --strict --emit-semantic-json ppif/ahb_requester_busy_insert.ahb
./bin/fsmgen --quiet --outdir generated/ial2-ahb-requester-busy-insert-alias ppif/ahb_requester_busy_insert.ahb
./bin/fsmgen --quiet --strict --verify-hdl ppif/ahb_requester_busy_insert.ahb
```

Focused t/1512 proves byte parity, parse/check/schedule/semantic/outdir/HDL
surfaces, support identity, generated-artifact/report parity, alias-only residue
removal, and preservation of the base requester alias. Generated-HDL t/1498
continues to prove the shared held-BUSY/resumed-SEQ runtime behavior.

## Explicit Deferrals

Paired requester/subordinate composition, multi-beat or policy-driven BUSY
throttling, runtime-selected insertion points, a distinct
`local-status.bus_busy`, halfword/word burst `SEQ`, wider/indefinite bursts,
multi-word/register-bank progression, optional AHB signals, legacy subordinate
two-bit `HRESP`, broader AHB manager/interconnect behavior, scoreboards, direct
backend, verification output, backend-language variants, AXI/APB changes, and
VHDL remain deferred.
