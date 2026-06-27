# IAL2 APB Requester Status Field Behavior

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.577`

Date: 2026-06-27

## Outcome

FSMGen now ships additive APB requester-transfer and fixed-composition samples
that expose both requester `busy` and a named 2-bit requester `status` field:

```text
ppif/apb_requester_transfer_status.ppif
ppif/apb_requester_transfer_status.apb
ppif/apb_composition_status.ppif
ppif/apb_composition_status.apb
```

The existing no-busy and busy-only APB samples remain unchanged. The status
field is intentionally available only on the selected busy-capable APB
requester response shape.

## Source Shape

The selected status syntax is:

```lisp
(response
  (busy busy)
  (status status width 2)
  (done done)
  (read-data last_read_data width 32)
  (error last_error))
```

`(status NAME width 2)` is accepted only when the same response block also has
`(busy NAME)`. A status-only response block, missing width, malformed status
binding, or any width other than `2` fails closed.

The selected status encoding is:

```text
0 idle
1 busy
2 done_ok
3 done_error
```

## Generated Behavior

Status-capable requester-transfer sources generate the same review chain as
the earlier APB requester samples:

```text
IAL2 .ppif/.apb -> generated apb_requester.isf -> generated apb_requester.fsm -> HDL
```

The generated requester interface adds:

```lisp
(output busy)
(output status (width 2))
```

The generated requester drives `busy = 1` and `status = 1` during setup and
access. The generated requester clears both outputs in idle:

```lisp
(<- (busy> 0))
(<- (status> 0))
```

After `PREADY`, the requester samples `PRDATA` and `PSLVERR` before the done
drive. The done drive publishes `last_error = slverr` and computes the status
with the bounded concat expression:

```lisp
(status (concat 1'b1 slverr))
```

That yields `2'b10` when `PSLVERR` is low and `2'b11` when `PSLVERR` is high.
The generated HDL exposes `output reg [1:0] status`.

Status-capable fixed-composition sources propagate requester `busy` and
`status` to the generated `apb_tb.fsm` top. The generated top carries a public
`status<2` output and embeds the requester/completer child FSM text as before.

## Support Accounting

The new support-accounting identities are:

```text
intent.ppif_apb_requester_transfer_status
intent.apb_profile_alias_requester_transfer_status
intent.ppif_apb_composition_status
intent.apb_profile_alias_composition_status
```

Their coverage names are:

```text
ial2_ppif_apb_requester_transfer_status_pipeline_cli
ial2_apb_profile_alias_requester_transfer_status_pipeline_cli
ial2_ppif_apb_composition_status_pipeline_cli
ial2_apb_profile_alias_composition_status_pipeline_cli
```

The `.ppif` samples use `source_kind: ppif`; the `.apb` samples use
`source_kind: ial2_profile_alias`.

## Reports And Residue

Requester-transfer reports preserve the normalized response binding:

```json
"response": {
  "busy": "busy",
  "status": { "name": "status", "width": 2 },
  "done": "done",
  "read_data": { "name": "last_read_data", "width": 32 },
  "error": "last_error"
}
```

They also expose `response_status_field` metadata with the selected encoding.
Composition reports expose the same requester status metadata through
`requester_status_field`, child report metadata, and the top-port list.

Status-capable requester-transfer and fixed-composition reports omit both:

```text
apb_requester_status_field_deferred
apb_requester_busy_status_deferred
```

The broader APB residues remain explicit, including multi-peripheral decode,
sidebands/strobes, alternate widths, and back-to-back policy. Fixed composition
also keeps multi-register decode residue.

Existing no-busy APB samples still keep `apb_requester_busy_status_deferred`.
Existing busy-only samples still keep `apb_requester_status_field_deferred`.

## Diagnostics

The parser rejects:

- `(status NAME width 2)` without `(busy NAME)` in the same APB requester
  response block;
- malformed status syntax other than `(status NAME width 2)`;
- missing status width; and
- status widths other than `2`.

Unsupported APB decode, sideband, storage, width, and back-to-back behavior
remain fail-closed or explicitly deferred as before.

## Non-Goals

This slice does not add status-only samples, enum-like status declarations,
custom encodings, multiple status fields, sticky status registers, APB
multi-peripheral decode, APB multi-register decode, APB sidebands/strobes,
alternate APB widths, back-to-back transfer policy, direct IAL2-to-IAL0
lowering, direct backend lowering, verification-output generation,
backend-language variants, AXI follow-on behavior, or VHDL behavior.

## Validation

Focused validation includes:

```bash
prove -Iperl t/1470-ial2-apb-profile-alias.t \
  t/1472-ial2-apb-composition.t \
  t/248-regression-corpus-accounting.t \
  t/297-capability-manifest.t

./bin/fsmgen --emit-schedule-json ppif/apb_requester_transfer_status.ppif
./bin/fsmgen --strict --check --json ppif/apb_requester_transfer_status.ppif
./bin/fsmgen --strict --emit-semantic-json ppif/apb_requester_transfer_status.ppif
./bin/fsmgen --quiet --outdir /tmp/fsmgen-apb-requester-status \
  --output /tmp/fsmgen-apb-requester-status/apb_requester_status.sv \
  ppif/apb_requester_transfer_status.ppif
./bin/fsmgen --quiet --outdir /tmp/fsmgen-apb-requester-status-apb \
  --output /tmp/fsmgen-apb-requester-status-apb/apb_requester_status.sv \
  ppif/apb_requester_transfer_status.apb

./bin/fsmgen --emit-schedule-json ppif/apb_composition_status.ppif
./bin/fsmgen --strict --check --json ppif/apb_composition_status.ppif
./bin/fsmgen --strict --emit-semantic-json ppif/apb_composition_status.ppif
./bin/fsmgen --quiet --outdir /tmp/fsmgen-apb-composition-status \
  --output /tmp/fsmgen-apb-composition-status/apb_tb_status.sv \
  ppif/apb_composition_status.ppif
./bin/fsmgen --quiet --outdir /tmp/fsmgen-apb-composition-status-apb \
  --output /tmp/fsmgen-apb-composition-status-apb/apb_tb_status.sv \
  ppif/apb_composition_status.apb
```

The matching `.apb` profile-alias samples are covered by the same focused
tests and direct schedule/check/semantic/outdir probes.
