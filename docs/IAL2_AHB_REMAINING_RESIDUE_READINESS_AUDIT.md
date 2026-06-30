# IAL2 AHB Remaining Residue Readiness Audit

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.734`

Date: 2026-06-30

## Outcome

`IAL2-FEATURE-COMPLETENESS-FRONTIER.734` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.735`, a no-behavior readiness audit for
the first bounded AHB byte-lane and narrow-transfer behavior.

The audit changes no parser behavior, generator behavior, public source sample,
support-accounting catalog, capability manifest, focused test behavior,
schedule/check/semantic JSON behavior, generated artifact, HDL/runtime
behavior, direct backend behavior, verification-output generation,
backend-language variant, AXI behavior, APB behavior, broader AHB behavior, or
VHDL behavior.

## Current Shipped Surface

The shipped AHB IAL2 surface now has eight public bounded entrypoints:

```text
ppif/ahb_requester.ppif
ppif/ahb_lite_subordinate.ppif
ppif/ahb_interconnect.ppif
ppif/ahb_interconnect_two_subordinate.ppif
ppif/ahb_requester.ahb
ppif/ahb_lite_subordinate.ahb
ppif/ahb_interconnect.ahb
ppif/ahb_interconnect_two_subordinate.ahb
```

The direct lower-layer AHB seeds remain separate `.fsm` coverage:

```text
fsm/amba_requester.fsm
fsm/ahb_lite_subordinate.fsm
```

Current subordinate behavior accepts selected `NONSEQ` word transfers, ignores
`IDLE` and `BUSY`, and returns two-cycle ERROR for unsupported `SEQ`,
unsupported sizes, and unmapped addresses. Current interconnect behavior
forwards `HSIZE`, localizes addresses, decodes one or two static windows, and
maps one-bit subordinate `HRESP` to requester two-bit `HRESP`.

## Residue Triage

The remaining AHB residue is not one implementation family. It separates into
several independent axes:

- AHB completer behavior;
- broader interconnect/decode beyond selected one-subordinate and
  two-subordinate static-window aggregates;
- optional/property-gated AHB signals such as `HBURST`, `HPROT`,
  `HMASTLOCK`, and AHB5 additions;
- burst `SEQ` continuation behavior;
- byte-lane and narrow-transfer behavior;
- legacy two-bit subordinate `HRESP` compatibility;
- AHB scoreboards;
- full AHB manager behavior beyond the bounded requester;
- direct backend behavior;
- verification-output generation;
- backend-language variants; and
- VHDL.

The next exact owner should be a focused readiness audit, not direct behavior.

## Why Byte-Lane/Narrow-Transfer Readiness Comes Next

Byte-lane/narrow-transfer behavior is the narrowest source-backed candidate
that can advance the shipped subordinate/interconnect path without introducing
new topology, optional signal policy, burst progression, scoreboards, backend
targets, or legacy compatibility.

The source fact inventory already records that narrower transfers only require
active byte lanes to be valid and that read data is required only for transfers
that complete with OKAY. The current public subordinate and aggregate sources
already carry the relevant bounded inputs:

```text
HADDR
HSIZE
HWRITE
HWDATA
HRDATA
```

The existing subordinate generator already rejects unsupported sizes, so a
future contract can define one explicit widening point: selected byte and
halfword transfer acceptance for the existing 32-bit single-register storage
shape.

## Deferred Axes

This audit does not select optional/property-gated AHB signals next because
`HBURST`, `HPROT`, `HMASTLOCK`, AHB5 optional signals, security, exclusive,
user, parity, and protection-policy effects need their own policy boundaries.

It does not select burst `SEQ` continuation next because that requires burst
address progression, wrapping/incrementing semantics, and manager/subordinate
coordination beyond the current single-transfer subordinate shape.

It does not select broader interconnect/decode next because the one- and
two-subordinate aggregate surfaces just shipped and the next cardinality step
would mainly repeat topology widening before closing endpoint transfer
semantics.

It does not select legacy two-bit subordinate `HRESP` compatibility next
because the current imported source-backed common AHB/AHB-Lite facts and
current public sources are built around one-bit subordinate OKAY/ERROR `HRESP`
with interconnect widening to requester two-bit `HRESP`.

It does not select full manager, scoreboards, direct backend,
verification-output generation, backend-language variants, or VHDL because
those are cross-cutting workstreams that need a narrower behavior contract
first.

## Selected `.735` Contract

`.735` must audit first bounded AHB byte-lane/narrow-transfer readiness and
select the next exact owner or prerequisite. It should answer:

- whether the first public contract should target the direct subordinate seed,
  `ppif/ahb_lite_subordinate.ppif`, `ppif/ahb_lite_subordinate.ahb`, aggregate
  interconnect sources, or a staged subset;
- which `HSIZE` encodings are accepted first;
- how `HADDR` low bits select byte and halfword lanes in the existing 32-bit
  storage word;
- how narrow writes update only selected lanes;
- how narrow reads project returned `HRDATA`;
- whether unaligned or crossing accesses fail closed as ERROR;
- how wait states and two-cycle ERROR behavior interact with narrow transfers;
- what report fields, residue movement, diagnostics, and support-accounting
  identities are needed;
- which focused parser/generator/CLI tests and direct probes are mandatory;
  and
- whether any lower-layer generated-IAL1/IAL0 substrate work is required
  before behavior.

## Validation

`.734` validates current state only. Useful current probes are:

```text
./bin/fsmgen --quiet --strict --check --json ppif/ahb_lite_subordinate.ppif
./bin/fsmgen --quiet --strict --check --json ppif/ahb_lite_subordinate.ahb
./bin/fsmgen --quiet --strict --check --json ppif/ahb_interconnect_two_subordinate.ahb
```

Closeout must run Knowledge Map generation/check, mdBook build, docs path
audit, memory architecture check, diff check, and the doctrine driver. Broad or
potentially heavyweight Perl/`prove`/`fsmgen` commands must remain RAM-guarded.

## Non-Goals

`.734` and `.735` must not add parser/generator/source
sample/support-accounting/manifest/test behavior. They must not implement byte
lanes, narrow transfers, optional signals, burst `SEQ` support, legacy two-bit
`HRESP`, broader interconnect cardinality, multiple requesters, arbitration,
bus matrices, scoreboards, full-manager behavior, direct backend behavior,
verification-output generation, backend-language variants, AXI, APB, broader
AHB behavior, or VHDL behavior.
