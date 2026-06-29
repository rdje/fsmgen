# IAL2 AHB Source-Shape Readiness Audit

- Work unit: `IAL2-FEATURE-COMPLETENESS-FRONTIER.695`
- Date: `2026-06-29`
- Status: selected
- Scope: no-behavior readiness audit for first AHB IAL2 source shape

## Decision

`IAL2-FEATURE-COMPLETENESS-FRONTIER.695` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.696`, an AHB requester `.ppif` public
contract selection, as the next exact owner.

The next owner should select the first generic `.ppif` AHB requester contract,
not implementation. The `.ahb` profile alias must remain unsupported until a
later exact alias owner selects it.

## Evidence Read

This audit read:

- `.694` post-tri-mode selector and `.695` task-tree acceptance;
- the IAL2 new-protocol workflow in
  `docs/book/src/15a-ial2-new-protocol-support.md`;
- the current AHB boundary chapter and fact card;
- `fsm/amba_requester.fsm`;
- `bin/fsmgen` suffix handling for `.ppif`, `.axi`, `.apb`, and unsupported
  aliases such as `.ahb`;
- `FSM::Adapter::IAL2::PPIF`;
- current `FSM::IAL2::ProtocolIntent::*` entrypoints for Valid-Ready, AXI
  manager, and APB requester/completer/composition behavior;
- APB requester and AXI Valid-Ready public `.ppif` source examples;
- `FSM::Support::RegressionCorpus` and `FSM::Support::LanguageSurfaceSection`;
- decisions `0014`, `0015`, `0016`, `0017`, and `0018`;
- relevant Knowledge Map fact cards for AHB boundary, profile aliases,
  non-AXI taxonomy, and protocol-specific interconnect/decode separation.

## Live Probes

The direct AHB seed remains support-accounted:

```bash
./bin/fsmgen --quiet --strict --check --json fsm/amba_requester.fsm
```

The check JSON reports:

```text
success: true
entry_id: protocol.amba_requester
source_kind: fsm
coverage: direct_root_pipeline_cli
module_name: amba_requester
```

A temporary `.ahb` copy fails closed:

```bash
cp fsm/amba_requester.fsm /tmp/fsmgen-695-amba-requester.ahb
./bin/fsmgen --quiet --strict --check --json /tmp/fsmgen-695-amba-requester.ahb
```

The expected diagnostic remains:

```text
source suffix '.ahb' is a known IAL2 alias candidate but is not supported in this slice
```

## Readiness Findings

AHB has enough current evidence for public contract selection because the
direct seed already fixes a bounded requester/master model:

- one local command active at a time;
- arbitration through `HBUSREQ` and `HGRANT`;
- `SINGLE`, `INCR`, `INCR4`, `INCR8`, `INCR16`, `WRAP4`, `WRAP8`, and
  `WRAP16` burst families;
- `HTRANS=NONSEQ` for the first accepted beat and `HTRANS=SEQ` afterward;
- `HREADY` wait-state handling;
- `HRESP` handling for `OKAY`, `ERROR`, `RETRY`, and `SPLIT`;
- local command and status signals already documented in the mdBook.

Current IAL2 infrastructure is also ready for a contract-selection slice:

- `.ppif` is the first public generic IAL2 container by decision `0016`;
- profile aliases such as `.ahb` are optional future vocabulary aliases by
  decision `0015`, not prerequisites for generic `.ppif` support;
- the parser already routes by bounded top-level object family;
- current ProtocolIntent modules already follow the required pattern:
  normalize contract, emit generated IAL1 `.isf`, lower to generated IAL0
  `.fsm`, build a report, and expose generated review artifacts;
- support accounting and language-surface text already distinguish direct
  `.fsm` seeds from IAL2 `.ppif` examples.

## Selected Next Boundary

`.696` should select the exact public contract for a first AHB requester
source, likely a checked-in future source named by the contract selection such
as `ppif/ahb_requester.ppif`.

The selected contract must decide:

- required `(profile ahb)` spelling;
- exact top-level object form, expected to be a bounded requester object such
  as `(ahb-requester amba_requester ...)`;
- required clock/reset, local command, local response/status, bus request, bus
  response, burst, transfer, and response-policy clauses;
- generated IAL1 artifact name, expected to be an AHB requester `.isf`;
- generated IAL0 artifact name, expected to be an AHB requester `.fsm`;
- HDL entry module name;
- report schema name;
- support-accounting identity and source kind;
- missing/duplicate/unsupported diagnostics;
- `.ahb` alias deferral and rollback boundary;
- focused validation and mdBook/Knowledge Map gates.

`.696` must not implement parser or generator behavior. It must leave `.ahb`
unsupported and must not add public AHB source samples.

## Deferred Boundaries

This audit does not select:

- AHB parser behavior;
- AHB generator behavior;
- an AHB public `.ppif` sample;
- `.ahb` profile-alias acceptance;
- support-accounting catalog changes;
- generated AHB `.isf` or `.fsm` artifacts;
- AHB completer/subordinate behavior;
- AHB interconnect/decode or arbitration beyond requester bus arbitration;
- AHB scoreboards;
- full AHB manager behavior;
- direct IAL2-to-IAL0 or IAL2-to-HDL lowering;
- verification-output generation;
- backend-language variants;
- VHDL behavior.

## Validation

Closeout for this audit should include:

- fact-card reverify;
- Knowledge Map generation/check;
- mdBook build;
- docs relative-path audit;
- memory architecture check;
- whitespace diff check;
- doctrine driver.

## Rollback

Rollback removes this audit note, its Knowledge Map fact card, task-tree
updates for `.695`/`.696`, README/ROADMAP/MEMORY/Knowledge Map updates, and
generated Knowledge Map changes. No behavior changes are part of this audit.
