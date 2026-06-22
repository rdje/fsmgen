# AXI IAL2 Manager Dynamic Focused-Suite Cleanup

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.236`

Date: 2026-06-22

## Outcome

`IAL2-FEATURE-COMPLETENESS-FRONTIER.236` adds the bounded focused target
`t/1438-axi-ial2-manager-dynamic-transaction-id-focused.t` for the shipped
dynamic transaction-ID family from `.219` through `.234`.

The target covers the public PPIF samples for:

- metadata-only transaction-local `(id dynamic)`;
- generated single-active dynamic write `BID` response-demux;
- generated single-active dynamic read single-beat `RID` response-demux;
- generated single-active dynamic read burst-last `RID`/`RLAST`
  response-demux;
- scalar single-beat dynamic read-data capture; and
- scalar last-beat dynamic read-data capture.

## Validation Surface

The new focused test validates the shipped dynamic family without relying on
full `t/1436-ial2-ppif-parser-cli.t` or
`t/1437-axi-ial2-manager-capacity-status-generator.t` as routine closeout
surfaces. Those broad suites remain intact for broader sweeps.

For each dynamic public PPIF sample the focused target checks:

- PPIF adapter parsing and source identity;
- generated IAL1 and scheduled IAL0 dynamic storage/rule/capture invariants;
- report fields for dynamic ownership, generated completion source,
  generated rules, generated assertions, completion-validity vocabulary, and
  explicit residue;
- in-process SystemVerilog lowering for the generated dynamic guards and
  dynamic read-data capture enables; and
- strict CLI `--check --json` plus strict `--emit-semantic-json`
  support-accounting identity.

This keeps the assertion intent from the older monoliths while bounding the
routine dynamic-family proof to a predictable target. The first guarded run of
the new target passed in about 38 seconds:

```sh
scripts/run_with_ram_guard.sh -- env -u PERL5LIB prove -Iperl t/1438-axi-ial2-manager-dynamic-transaction-id-focused.t
```

## Non-Changes

This slice does not change parser behavior, generator behavior, PPIF public
syntax, support-accounting catalog semantics, generated artifacts, HDL
behavior, or dynamic feature scope. It adds only behavior-neutral validation.

Dynamic burst-length capture, runtime validation, multi-beat output banks,
multiple or mixed dynamic response-demux, same-cycle recapture, dynamic same-ID
ordering, queues, scoreboards, direct backend behavior, and VHDL remain future
feature work.

## Next Owner

The next owner is `IAL2-FEATURE-COMPLETENESS-FRONTIER.237`, readiness audit for
dynamic burst-length capture over the generated single-active dynamic read
last-beat response-demux and scalar dynamic read-data path.
