# AXI IAL2 Manager Dynamic Transaction-ID Metadata Behavior

Status: shipped by `IAL2-FEATURE-COMPLETENESS-FRONTIER.219` on 2026-06-22.

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.219`

## Summary

The AXI manager capacity/status `.ppif` surface now accepts the exact
transaction-local spelling `(id dynamic)` for read and write transactions when
the matching `id-families` direction declares a positive-width request-ID and
response-ID signal.

This slice is metadata-first. It records that the transaction ID is
user-supplied at the family request-ID signal and that generated dynamic ID
capture, response matching, same-ID ordering, read-data routing, queues,
scoreboards, and HDL behavior are not generated yet.

The public sample is:

```bash
./bin/fsmgen --emit-schedule-json ppif/axi_manager_capacity_status_dynamic_transaction_id.ppif
```

## PPIF Syntax

The accepted dynamic transaction-ID spelling is:

```lisp
(transactions
  (write w0
    (tag wr0)
    (request axi0_write_submit)
    (completion axi0_write_complete)
    (id dynamic))
  (read r0
    (tag rd0)
    (request axi0_read_submit)
    (completion axi0_read_complete)
    (id dynamic)))
```

Malformed or unsupported dynamic/user spellings remain rejected, including
`(id user)`, `(id (dynamic))`, `(id (signal ...))`, and dynamic ID records that
also carry a concrete value.

Dynamic IDs require matching ID-family metadata:

```lisp
(id-families
  (write (width 4) (request-id axi0_awid) (response-id axi0_bid))
  (read (width 4) (request-id axi0_arid) (response-id axi0_rid)))
```

The family width must be positive. Missing ID-family metadata or zero-width
families fail closed before report generation.

## Report Contract

Schedule JSON reports dynamic IDs as transaction ID metadata:

```json
{
  "policy": "dynamic",
  "family": "read",
  "family_width": 4,
  "request_id_source": "axi0_arid",
  "response_id_signal": "axi0_rid",
  "ownership": "user_supplied",
  "implementation_status": "selected_not_generated"
}
```

The same shape is emitted for write transactions with the write request and
response ID signals. The support detail also records that dynamic transaction
ID metadata is supported for `(id dynamic)` when matching ID-family metadata is
present.

The unsupported-residue report remains explicit:

```text
dynamic_transaction_id_behavior
```

That residue covers dynamic ID capture, response matching, same-ID ordering,
read-data routing, queues, scoreboards, and HDL behavior.

## Fail-Closed Boundaries

This slice rejects same-family dynamic transactions when a behavior clause
would require generated dynamic matching:

- `auto-id-lifecycle.<family>` with a dynamic transaction ID.
- `response-demux.<family>` with a dynamic transaction ID.
- `same-id-ordering-policy.<family>` with a dynamic transaction ID.
- `read-data.read` with a dynamic read transaction ID.

Those clauses remain future exact-owner work because they require runtime ID
capture and response matching semantics, not only metadata.

## Preservation

Existing `id auto`, concrete `(id (value N))`, concrete same-ID fail-closed
validation, generated auto-ID lifecycle behavior, generated response demux,
generated queue-head behavior, counted request accounting, generated
artifacts, and default HDL behavior remain unchanged.

The dynamic metadata sample is support-accounted for strict check JSON and
semantic JSON. Its default HDL output intentionally does not expose dynamic ID
ports or generated ID-matching behavior.

## Verification

Focused verification for this slice included:

```bash
env -u PERL5LIB perl -Iperl -c perl/FSM/Adapter/IAL2/PPIF.pm
env -u PERL5LIB perl -Iperl -c perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm
env -u PERL5LIB perl -Iperl -c perl/FSM/Support/RegressionCorpus.pm
env -u PERL5LIB perl -Iperl -c t/1436-ial2-ppif-parser-cli.t
env -u PERL5LIB perl -Iperl -c t/1437-axi-ial2-manager-capacity-status-generator.t
env -u PERL5LIB perl -Iperl -c t/248-regression-corpus-accounting.t
env -u PERL5LIB prove -Iperl t/1437-axi-ial2-manager-capacity-status-generator.t
env -u PERL5LIB prove -Iperl t/248-regression-corpus-accounting.t
env -u PERL5LIB ./bin/fsmgen --quiet --emit-schedule-json ppif/axi_manager_capacity_status_dynamic_transaction_id.ppif
env -u PERL5LIB ./bin/fsmgen --quiet --strict --check --json ppif/axi_manager_capacity_status_dynamic_transaction_id.ppif
env -u PERL5LIB ./bin/fsmgen --quiet --strict --emit-semantic-json ppif/axi_manager_capacity_status_dynamic_transaction_id.ppif
env -u PERL5LIB ./bin/fsmgen --quiet --output /tmp/fsmgen_axi_dynamic_transaction_id_after219.sv ppif/axi_manager_capacity_status_dynamic_transaction_id.ppif
```

The full `t/1436-ial2-ppif-parser-cli.t` suite was attempted under the RAM
guard and stopped when host memory crossed the configured cutoff; narrower
schedule/check/semantic/default-HDL probes covered the new public dynamic
sample.
