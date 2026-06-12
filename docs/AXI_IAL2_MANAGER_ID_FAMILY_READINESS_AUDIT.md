# AXI IAL2 Manager ID-Family Readiness Audit

Status: implementation boundary selected; no parser, generator, HDL, or CLI
behavior changed by this note.

Task tree:
[docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md](tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md).

Builds on:

- [docs/AXI_IAL2_MANAGER_ID_FAMILY_SUBSET_SELECTION.md](AXI_IAL2_MANAGER_ID_FAMILY_SUBSET_SELECTION.md)
- [docs/AXI_IAL2_MANAGER_CAPACITY_STATUS_PPIF_FIRST_SLICE.md](AXI_IAL2_MANAGER_CAPACITY_STATUS_PPIF_FIRST_SLICE.md)
- [docs/AXI_ID_ORDERING_RULE_EVIDENCE_PROBE.md](AXI_ID_ORDERING_RULE_EVIDENCE_PROBE.md)

## Purpose

This audit maps the selected AXI manager ID-family/static-validation subset to
current code, tests, public reports, and documentation before implementation
changes.

## Readiness Conclusion

The first implementation should be an additive extension to the existing
capacity/status object, not a new full manager object yet.

Rationale:

- the selected ID-family subset is static structure and report metadata, not
  dynamic transaction scheduling;
- the existing `manager-capacity-status` object is already the public
  capacity/status shell that future ID allocation and response matching will
  build on;
- adding optional ID-family metadata can be done without changing generated
  `.isf`, generated `.fsm`, or SystemVerilog behavior;
- introducing a broader `(axi-manager ...)` object before transaction verbs,
  allocation, ordering, and response matching are selected would create a
  name that appears more complete than the behavior.

No IAL1, IAL0, or SystemVerilog prerequisite is required first for the
static/report-only ID-family slice.

## Selected Implementation Boundary

The next implementation leaf should add an optional `(id-families ...)` clause
inside one public `(manager-capacity-status ...)` object:

```text
(manager-capacity-status axi0
  (clock clk)
  (reset (rst_n active_low async))
  (read-max-pending 4)
  (write-max-pending 2)
  (submit-policy try)
  (read-submit axi0_read_submit)
  (read-complete axi0_read_complete)
  (write-submit axi0_write_submit)
  (write-complete axi0_write_complete)
  (id-families
    (write (width 4) (request-id axi0_awid) (response-id axi0_bid))
    (read  (width 4) (request-id axi0_arid) (response-id axi0_rid)))
  (status
    ...))
```

Zero-width ID families should be written without request/response ID signals:

```text
(id-families
  (write (width 0))
  (read  (width 0)))
```

The in-process contract shape should be:

```perl
id_families => {
    write => {
        width              => 4,
        request_id_signal  => 'axi0_awid',
        response_id_signal => 'axi0_bid',
    },
    read => {
        width              => 4,
        request_id_signal  => 'axi0_arid',
        response_id_signal => 'axi0_rid',
    },
}
```

If `id_families` is absent, the current capacity/status sample remains valid
and behavior-compatible. The report should keep ID allocation, ordering, and
response matching in explicit residue.

## Code Owners

`perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm`:

- accept optional `id_families`,
- normalize read/write family entries,
- validate widths in `0..32`,
- require request/response ID signal names when width is positive,
- reject request/response ID signal names when width is zero,
- fold ID signal names into the existing collision check,
- add `id_families` to the IAL2 report when supplied,
- leave generated `.isf`, generated `.fsm`, and HDL unchanged.

`perl/FSM/Adapter/IAL2/PPIF.pm`:

- parse `(id-families ...)` under `(manager-capacity-status ...)`,
- map `(write ...)` and `(read ...)` family clauses to structured contract
  hashes,
- reject duplicate families, unsupported family names, unsupported fields,
  malformed widths, missing positive-width signal names, and zero-width signal
  names.

`perl/FSM/Support/RegressionCorpus.pm`:

- add a separate supported `.ppif` sample for the ID-family slice so the
  existing capacity/status sample remains a no-ID compatibility fixture.

`perl/FSM/Support/LanguageSurfaceSection.pm`:

- widen the `.ppif` boundary text to mention one-object capacity/status
  sources with optional static ID-family metadata.

## Public Samples

Keep the existing sample:

```text
ppif/axi_manager_capacity_status.ppif
```

Add a new sample:

```text
ppif/axi_manager_capacity_status_id_family.ppif
```

The new sample should be support-accounted separately, likely:

```text
intent.ppif_axi_manager_capacity_status_id_family
```

Both samples should continue through check JSON and normalized semantic JSON
with public `.ppif` source identity.

## Report Contract

Retain the current report schema string:

```text
fsmgen.ial2.protocol_intent.axi_manager_capacity_status.v1
```

Reason: this implementation is an additive optional key on a report that is not
declared as a frozen full schema. The implementation must not rename, remove,
or retype existing report keys.

When `id_families` is supplied, the report should include:

```text
id_families:
  write:
    width: 4
    present: true
    request_id_signal: axi0_awid
    response_id_signal: axi0_bid
    source_anchors: [...]
  read:
    width: 4
    present: true
    request_id_signal: axi0_arid
    response_id_signal: axi0_rid
    source_anchors: [...]
```

For width `0`, `present` is `false` and request/response ID signal fields are
absent.

The report should add static rule entries for ID-family width/presence and
signal-pair validation. `unsupported_residue` must continue to name ID
allocation, per-transaction ID validation, same-ID ordering, different-ID
interleaving, `BID`/`RID` response matching, bursts, queued/blocking policy,
profile aliases, full AXI manager behavior, and VHDL.

## Diagnostics

The implementation must fail closed on:

- non-integer, negative, or greater-than-32 widths;
- duplicate `read` or `write` family clauses;
- unsupported family names;
- missing `(width ...)`;
- supplied ID signal names when width is `0`;
- missing request/response ID signal names when width is positive;
- duplicate or colliding request/response ID signal names;
- unsupported clauses that attempt allocation, user ID validation, ordering,
  response matching, bursts, transaction classes, aliases, queued/blocking
  policy, or VHDL behavior.

## Validation Gates

Focused tests should extend:

- `t/1437-axi-ial2-manager-capacity-status-generator.t`
- `t/1436-ial2-ppif-parser-cli.t`

Broader gates should include:

- `perl -Iperl -c perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm`
- `perl -Iperl -c perl/FSM/Adapter/IAL2/PPIF.pm`
- `prove -Iperl t/1437-axi-ial2-manager-capacity-status-generator.t`
- `prove -Iperl t/1436-ial2-ppif-parser-cli.t`
- `prove -Iperl t/297-capability-manifest.t t/317-language-surface-contract.t`
- `prove -Iperl t/301-check-json-supported-corpus.t t/303-normalized-semantic-json-supported-corpus.t`
- `mdbook build docs/book`
- `prove -Iperl t/1414-docs-relative-paths-audit.t`
- `bash knowledge-map/scripts/check_knowledge_map.sh`
- `scripts/check_memory_architecture.sh`
- `git --no-pager diff --check`

## Selected Next Leaf

Proceed with `IAL2-FEATURE-COMPLETENESS-FRONTIER.9`: implement the additive
AXI manager ID-family/static-validation slice for the existing
capacity/status object, including public `.ppif` syntax, a separate sample,
support accounting, report coverage, diagnostics, mdBook, Knowledge Map, and
focused tests.
