# IAL2 Protocol-Neutral Valid-Ready Bundle Behavior

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.535`

Date: 2026-06-26

## Outcome

FSMGen now ships a support-accounted protocol-neutral/non-AXI Valid-Ready
`.ppif` bundle sample:

```text
ppif/valid_ready_dual_channel_bundle.ppif
```

The sample keeps the generic `.ppif` IAL2 container and the explicit profile:

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
(protocol-platform-intent valid_ready_dual_channel_bundle
  (profile valid-ready)
  (source
    (object fsmgen-valid-ready-dual-channel-bundle)
    (anchor (document FSMGEN-IAL2-VALID-READY-PROFILE) (section bundle) (page contract)))
  (valid-ready-channel data_downstream
    (source
      (object fsmgen-valid-ready-data-downstream)
      (anchor (document FSMGEN-IAL2-VALID-READY-PROFILE) (section monitor) (page producer-to-consumer)))
    (channel data_downstream)
    (role producer-to-consumer)
    (clock clk)
    (reset (rst_n active_low async))
    (valid data_valid)
    (ready data_ready)
    (payload
      (data width 8)))
  (valid-ready-channel status_upstream
    (channel status_upstream)
    (role consumer-to-producer)
    (clock clk)
    (reset (rst_n active_low async))
    (valid status_valid)
    (ready status_ready)
    (payload
      (status width 4))))
```

`(channel data_downstream)` and `(channel status_upstream)` are authored
logical channel identifiers for the `valid-ready` profile. They are not AXI
channel families. The bundle exercises both neutral roles:
`producer-to-consumer` and `consumer-to-producer`.

The `data_downstream` channel has a channel-local source anchor. The
`status_upstream` channel inherits the aggregate source object
`fsmgen-valid-ready-dual-channel-bundle`.

## CLI Examples

Emit the IAL2 source-anchor/residue report without writing HDL:

```bash
./bin/fsmgen --emit-schedule-json ppif/valid_ready_dual_channel_bundle.ppif
```

Materialize generated review artifacts and aggregate HDL:

```bash
./bin/fsmgen --outdir generated --output valid_ready_dual_channel_bundle.sv ppif/valid_ready_dual_channel_bundle.ppif
```

Run check mode with machine-readable diagnostics:

```bash
./bin/fsmgen --strict --check --json ppif/valid_ready_dual_channel_bundle.ppif
```

Emit normalized semantic JSON:

```bash
./bin/fsmgen --strict --emit-semantic-json ppif/valid_ready_dual_channel_bundle.ppif
```

## Report Surface

The aggregate report keeps the existing schema:

```text
fsmgen.ial2.protocol_intent.valid_ready_bundle.v1
```

The neutral bundle reports:

```text
bundle.protocol               = "valid-ready"
bundle.channel_count          = 2
bundle.channel_object_names   = ["data_downstream", "status_upstream"]
bundle.inherited_source_count = 1
```

The channel reports include:

```text
channels[0].target_channel.protocol = "valid-ready"
channels[0].target_channel.family   = "data_downstream"
channels[0].target_channel.role     = "producer-to-consumer"

channels[1].target_channel.protocol = "valid-ready"
channels[1].target_channel.family   = "status_upstream"
channels[1].target_channel.role     = "consumer-to-producer"
```

The neutral bundle reports generic aggregate residue:

```text
valid_ready_profile_bundle_behavior_outside_monitor
```

It does not report the AXI-profile aggregate residue
`axi_manager_concurrency`. The existing AXI AW/W bundle continues to report
that AXI residue.

## Generated Artifacts

The sample generates these review artifacts:

```text
data_downstream_valid_ready_monitor.isf
data_downstream_valid_ready_monitor.fsm
status_upstream_valid_ready_monitor.isf
status_upstream_valid_ready_monitor.fsm
valid_ready_dual_channel_bundle.fsm
```

Default HDL generation uses the aggregate wrapper/top entry:

```text
generated_artifacts.hdl_entry.kind           = aggregate_wrapper_top
generated_artifacts.hdl_entry.entry_artifact = valid_ready_dual_channel_bundle.fsm
generated_artifacts.hdl_entry.module_name    = valid_ready_dual_channel_bundle
```

The generated HDL contains the `valid_ready_dual_channel_bundle` wrapper
module and instantiates the two generated channel monitors.

## Support Accounting

The neutral bundle is support-accounted as:

```text
intent.ppif_valid_ready_dual_channel_bundle
```

Coverage key:

```text
ial2_ppif_valid_ready_dual_channel_bundle_pipeline_cli
```

The check JSON and normalized semantic JSON support-accounting reports name
that entry and keep the public source path on
`ppif/valid_ready_dual_channel_bundle.ppif`.

## Boundaries

This behavior does not add:

- no-profile `.ppif` input;
- `.axi`, `.chi`, `.ace`, `.ahb`, `.apb`, `.atb`, `.smbus`, `.i2s`, or other
  profile-specific suffix aliases;
- full non-AXI protocol behavior;
- common IAL2 queue/order/read-data/transaction constructs;
- AXI manager behavior changes;
- cross-channel dependency rules;
- scoreboards;
- direct backend lowering;
- verification-output generation for IAL2 profiles;
- backend-language variants; or
- VHDL behavior.

Existing AXI one-channel Valid-Ready, AXI AW/W Valid-Ready bundle, AXI manager
capacity/status, and protocol-neutral one-channel Valid-Ready `.ppif`
behavior remain unchanged.

## Validation

The implementation is covered by focused parser/generator/support-accounting,
capability-manifest, direct schedule/check/semantic CLI, direct output
materialization, mdBook, Knowledge Map, memory, docs-path, diff, and doctrine
gates for `IAL2-FEATURE-COMPLETENESS-FRONTIER.535`.
