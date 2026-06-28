# IAL2 APB Sideband Back-To-Back Requester Behavior

- Work unit: `IAL2-FEATURE-COMPLETENESS-FRONTIER.612`
- Date: `2026-06-28`
- Status: shipped
- Scope: selected 32-bit APB sideband-aware requester timing-policy behavior

## Summary

`IAL2-FEATURE-COMPLETENESS-FRONTIER.612` implements the requester-first
sideband-aware APB back-to-back owner selected by `.611` for exactly two public
sources:

- `ppif/apb_requester_transfer_sideband_status_back_to_back.ppif`
- `ppif/apb_requester_transfer_sideband_status_back_to_back.apb`

The source lowers through generated `.isf` before generated `.fsm`, matching the
existing APB IAL2 review path. The selected family reuses the `.606` public
timing-policy vocabulary:

```text
(timing-policy
  (back-to-back queued)
  (queue-depth 1)
  (overflow reject))
```

and requires requester response fields `accepted`, `busy`, and `status width 2`.

## Selected Source Contract

The selected sideband requester remains intentionally narrow:

- 32-bit APB address, write-data, and read-data;
- request `(protection req_prot width 3)`;
- request `(write-strobe req_wstrb width 4)`;
- bus `(protection PPROT width 3)`;
- bus `(strobe PSTRB width 4)`;
- depth-1 queued requester admission with overflow reject.

The implementation rejects missing `accepted`/`busy`/`status`, unsupported queue
depth, unsupported overflow policy, missing sideband bundle fields, data16
timing-policy attempts, protection-policy timing-policy attempts, composition
timing-policy attempts, and unsupported topology shapes.

## Generated Behavior

The generated requester keeps the `.607` one-active-transfer plus one queued
next-transfer model. For the sideband-aware selected family, the queue state now
includes:

```text
queued_prot
queued_wstrb
```

When `start` is accepted into the queued slot, the generated FSM stores
`req_prot` and `req_wstrb` beside the queued address, write bit, and write data.
When the active transfer reaches its terminal state and a queued transfer is
present, the queued setup launches immediately with:

```lisp
(<- (PPROT> queued_prot))
(<- (PSTRB> (& queued_wstrb
              (concat queued_write queued_write queued_write queued_write))))
```

That preserves the no-idle-cycle back-to-back behavior while relaunching the
accepted sideband payload. The direct terminal-cycle acceptance path also drives
the current request sidebands immediately, with `PSTRB` masked by the current
`req_write` bit. Read transfers drive `PSTRB=0`; write transfers drive the
accepted strobe value.

## Reports And Support Accounting

Selected sideband requester reports carry the same requester timing-policy
metadata shape as `.607`:

```json
"timing_policy": {
  "back_to_back": "queued",
  "queue_depth": 1,
  "overflow": "reject",
  "accepted": "accepted"
}
```

The selected `.ppif` and `.apb` requester surfaces remove the broad
`apb_back_to_back_policy_deferred` residue and retain narrowed
`apb_additional_back_to_back_policies_deferred` for remaining APB timing-policy
work.

Support-accounting identities added in this slice:

- `intent.ppif_apb_requester_transfer_sideband_status_back_to_back`
- `intent.apb_profile_alias_requester_transfer_sideband_status_back_to_back`

## Deferred Work

Fixed composition, multi-peripheral composition, completer timing-policy
propagation, data16/protection back-to-back variants, queue depths greater than
1, overflow policies other than `reject`, accepted-less requester surfaces,
multiple active APB bus transfers, direct backend lowering,
verification-output generation, backend-language variants, AXI, AHB, and VHDL
remain deferred.

## Validation

Focused validation for this slice:

```bash
perl -Iperl -c perl/FSM/IAL2/ProtocolIntent/ApbRequesterTransfer.pm
perl -Iperl -c perl/FSM/Support/RegressionCorpus.pm
perl -Iperl -c perl/FSM/Support/LanguageSurfaceSection.pm
perl -Iperl -c t/1470-ial2-apb-profile-alias.t
perl -Iperl -c t/248-regression-corpus-accounting.t
perl -Iperl -c t/297-capability-manifest.t
prove -Iperl t/1470-ial2-apb-profile-alias.t
prove -Iperl t/248-regression-corpus-accounting.t
prove -Iperl t/297-capability-manifest.t
```

Direct schedule/check/semantic probes passed for both new requester sources.
Closeout also runs Knowledge Map generation/check, mdBook build, docs path,
memory, diff, and doctrine gates.

## Rollback

Rollback removes the two sideband requester back-to-back sample files, the
requester timing-policy guard widening, queued `PPROT/PSTRB` capture and
relaunch behavior, the two support-accounting entries, focused tests, this
behavior record, its Knowledge Map fact card, README, ROADMAP_V2, mdBook, task
tree, and Memory updates. Existing no-sideband back-to-back behavior and
existing sideband, data16, protection, completer, composition, AXI, AHB, and
VHDL behavior remain owned by earlier slices or future owners.
