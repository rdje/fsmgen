# IAL2 Protocol-Neutral Valid-Ready PPIF Behavior

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.531`

Date: 2026-06-26

## Outcome

FSMGen now ships a first protocol-neutral/non-AXI Valid-Ready `.ppif` sample:

```text
ppif/valid_ready_handshake.ppif
```

The sample uses the generic `.ppif` IAL2 container and the explicit profile:

```text
(profile valid-ready)
```

It lowers through the required reviewable chain:

```text
.ppif / IAL2 -> generated .isf / IAL1 -> generated .fsm / IAL0 -> HDL
```

No direct `.ppif -> .fsm` shortcut is introduced.

## Source Shape

The shipped sample is:

```text
(protocol-platform-intent valid_ready_handshake
  (profile valid-ready)
  (source
    (object fsmgen-valid-ready-profile)
    (anchor (document FSMGEN-IAL2-VALID-READY-PROFILE) (section monitor) (page contract)))
  (valid-ready-channel data_link
    (channel data_link)
    (role producer-to-consumer)
    (clock clk)
    (reset (rst_n active_low async))
    (valid valid)
    (ready ready)
    (payload
      (data width 8))))
```

`(channel data_link)` is an authored logical channel identifier for the
`valid-ready` profile. It is not an AXI channel family. The neutral role is
`producer-to-consumer`. AXI roles and channel families remain AXI-profile-local
for the existing AXI samples.

The source anchor deliberately names the internal FSMGen valid-ready profile
contract. It does not cite an AXI specification section.

## CLI Examples

Emit the IAL2 source-anchor/residue report without writing HDL:

```bash
./bin/fsmgen --emit-schedule-json ppif/valid_ready_handshake.ppif
```

Materialize generated review artifacts and HDL:

```bash
./bin/fsmgen --outdir generated ppif/valid_ready_handshake.ppif
```

Run check mode with machine-readable diagnostics:

```bash
./bin/fsmgen --strict --check --json ppif/valid_ready_handshake.ppif
```

Emit normalized semantic JSON:

```bash
./bin/fsmgen --strict --emit-semantic-json ppif/valid_ready_handshake.ppif
```

## Report Surface

The generated report keeps the existing schema:

```text
fsmgen.ial2.protocol_intent.valid_ready_channel.v1
```

The neutral sample reports:

```text
target_channel.protocol = "valid-ready"
target_channel.family   = "data_link"
target_channel.role     = "producer-to-consumer"
transfer_fire_condition = "valid && ready"
```

The generated monitor module is:

```text
data_link_valid_ready_monitor
```

The report residue is monitor-profile residue. It does not report AXI manager
concurrency as residue for the neutral profile.

## Support Accounting

The neutral sample is support-accounted as:

```text
intent.ppif_valid_ready_handshake
```

Coverage key:

```text
ial2_ppif_valid_ready_handshake_pipeline_cli
```

The check JSON and normalized semantic JSON support-accounting reports name
that entry and keep the public source path on
`ppif/valid_ready_handshake.ppif`.

## Boundaries

This behavior does not add:

- a no-profile `.ppif` form;
- `.axi`, `.chi`, `.ace`, `.ahb`, `.apb`, `.atb`, `.smbus`, `.i2s`, or other
  profile-specific suffix aliases;
- protocol-neutral multi-channel bundles;
- full non-AXI protocol behavior;
- common IAL2 queue/order/read-data constructs;
- AXI manager behavior changes;
- direct backend lowering;
- verification-output generation for IAL2 profiles;
- backend-language variants; or
- VHDL behavior.

Existing AXI one-channel Valid-Ready, AXI AW/W Valid-Ready bundle, and AXI
manager capacity/status `.ppif` behavior remain unchanged.

## Validation

The implementation is covered by focused generator, parser/CLI,
support-accounting, capability-manifest, and docs/doctrine gates for
`IAL2-FEATURE-COMPLETENESS-FRONTIER.531`.
