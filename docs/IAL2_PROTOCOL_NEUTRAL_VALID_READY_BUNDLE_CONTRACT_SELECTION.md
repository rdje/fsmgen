# IAL2 Protocol-Neutral Valid-Ready Bundle Contract Selection

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.534`

Date: 2026-06-26

## Outcome

`IAL2-FEATURE-COMPLETENESS-FRONTIER.534` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.535`, direct bounded implementation of a
protocol-neutral/non-AXI Valid-Ready `.ppif` bundle under `(profile
valid-ready)`.

The implementation owner may reuse the existing aggregate Valid-Ready bundle
contract from decision `0017`. No new aggregate wrapper/top prerequisite is
required. The implementation must still keep `.ppif` generic: AXI remains the
first shipped IAL2 profile/example, not the definition of IAL2.

This contract-selection slice changes no parser behavior, generator behavior,
PPIF sample, support-accounting catalog, validation behavior, generated
artifact, test, schedule/check/semantic JSON behavior, HDL/runtime behavior,
backend behavior, verification-output generation, backend-language variant,
external converter dependency, scoreboard, AXI behavior, non-AXI behavior,
common construct promotion beyond this selected contract, profile-alias suffix
syntax, or VHDL behavior.

## Selected Source Shape

The first support-accounted neutral bundle sample is:

```text
ppif/valid_ready_dual_channel_bundle.ppif
```

Its exact public source shape is:

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

The explicit `(profile valid-ready)` selector remains required. No-profile
input remains unsupported. No `.axi`, `.chi`, `.ace`, `.ahb`, `.apb`, `.atb`,
`.smbus`, `.i2s`, or other suffix alias is introduced.

## Profile Vocabulary

For neutral bundles:

- `(valid-ready-channel NAME ...)` keeps the existing object-name role and
  drives generated artifact names.
- `(channel NAME)` is an authored logical channel identifier and must be an
  ISF/HDL identifier. It is not an AXI channel family.
- `producer-to-consumer` and `consumer-to-producer` are both allowed and may
  coexist in the same neutral bundle.
- `manager-to-subordinate` and `subordinate-to-manager` remain AXI-profile
  roles and are not accepted under `(profile valid-ready)`.
- `AW`, `W`, `B`, `AR`, and `R` remain AXI profile channel families and are
  not required or implied by the neutral profile.

The first implementation may accept any multi-channel `(profile valid-ready)`
bundle that follows the existing aggregate Valid-Ready bundle rules. The
support-accounted public sample is the two-channel shape above because it
proves both neutral roles, one channel-local source, and one inherited channel
source without claiming broader protocol semantics.

## Source Anchors

The top-level source object names the internal FSMGen neutral bundle profile
contract:

```text
(object fsmgen-valid-ready-dual-channel-bundle)
(anchor (document FSMGEN-IAL2-VALID-READY-PROFILE)
        (section bundle)
        (page contract))
```

The `data_downstream` channel refines that source with a channel-local monitor
anchor:

```text
(object fsmgen-valid-ready-data-downstream)
(anchor (document FSMGEN-IAL2-VALID-READY-PROFILE)
        (section monitor)
        (page producer-to-consumer))
```

The `status_upstream` channel intentionally omits a channel-local source. Its
report must mark source attribution as inherited from
`fsmgen-valid-ready-dual-channel-bundle`; it must not fabricate
channel-specific evidence.

## Report Contract

The aggregate report schema remains:

```text
fsmgen.ial2.protocol_intent.valid_ready_bundle.v1
```

For the selected sample, the implementation should report:

```text
bundle.protocol               = "valid-ready"
bundle.channel_count          = 2
bundle.channel_object_names   = ["data_downstream", "status_upstream"]
bundle.inherited_source_count = 1
```

The channel report entries should include:

```text
channels[0].target_channel.protocol = "valid-ready"
channels[0].target_channel.family   = "data_downstream"
channels[0].target_channel.role     = "producer-to-consumer"

channels[1].target_channel.protocol = "valid-ready"
channels[1].target_channel.family   = "status_upstream"
channels[1].target_channel.role     = "consumer-to-producer"
```

The neutral aggregate must not report AXI manager concurrency as bundle-level
residue. It should report generic monitor-profile residue:

```text
valid_ready_profile_bundle_behavior_outside_monitor
```

with wording that keeps producer/consumer drive policy, backpressure policy,
coordination, and protocol-specific ordering outside the monitor-only bundle.
The existing AXI AW/W bundle must continue to report its AXI-profile residue,
including `axi_manager_concurrency`.

## Generated Artifacts

The selected sample should generate these review artifacts:

```text
data_downstream_valid_ready_monitor.isf
data_downstream_valid_ready_monitor.fsm
status_upstream_valid_ready_monitor.isf
status_upstream_valid_ready_monitor.fsm
valid_ready_dual_channel_bundle.fsm
```

Default HDL generation and `--verify-hdl` should use the aggregate wrapper/top
entry:

```text
generated_artifacts.hdl_entry.kind           = aggregate_wrapper_top
generated_artifacts.hdl_entry.entry_artifact = valid_ready_dual_channel_bundle.fsm
generated_artifacts.hdl_entry.module_name    = valid_ready_dual_channel_bundle
```

The mandatory lowering chain remains:

```text
.ppif / IAL2 -> generated .isf / IAL1 -> generated .fsm / IAL0 -> HDL
```

No direct `.ppif -> .fsm` shortcut is introduced.

## Support Accounting

The selected public support identity is:

```text
intent.ppif_valid_ready_dual_channel_bundle
```

The selected coverage key is:

```text
ial2_ppif_valid_ready_dual_channel_bundle_pipeline_cli
```

Check JSON and normalized semantic JSON should preserve the public source path
and report the same support-accounting entry for the selected sample.

## Selected `.535` Scope

`.535` should implement this contract directly:

- remove only the current fail-closed neutral-bundle guard that blocks
  `(profile valid-ready)` with multiple `valid-ready-channel` objects;
- keep all existing duplicate channel-name, duplicate artifact, shared
  clock/reset, duplicate wrapper-port, and reset-policy diagnostics;
- add `ppif/valid_ready_dual_channel_bundle.ppif`;
- add support-accounting and public corpus documentation for the selected
  sample;
- make aggregate residue conditional so valid-ready bundles report generic
  monitor residue while AXI bundles preserve AXI residue;
- update focused tests, README, ROADMAP_V2, mdBook, public/downstream contract
  wording, capability-manifest boundary wording if touched, task tree, Memory,
  and Knowledge Map; and
- preserve existing AXI one-channel, AXI AW/W bundle, AXI manager, neutral
  one-channel sample, unsupported suffix alias, direct backend,
  verification-output, backend-language variant, and VHDL boundaries.

Recommended focused test owner:

```text
t/1468-ial2-ppif-neutral-valid-ready-bundle.t
```

That focused test can cover the neutral bundle adapter shape, aggregate
schedule JSON, `--outdir`, default HDL, check JSON, semantic JSON, support
accounting, generic aggregate residue, preservation of AXI bundle residue, and
the already-selected fail-closed diagnostics without relying on a full broad
`t/1436` run as the only proof.

## Validation For `.535`

The implementation owner should run focused checks such as:

```bash
perl -Iperl -c perl/FSM/Adapter/IAL2/PPIF.pm
perl -Iperl -c perl/FSM/IAL2/ProtocolIntent/ValidReadyChannel.pm
perl -Iperl -c perl/FSM/Support/RegressionCorpus.pm
perl -Iperl -c t/1468-ial2-ppif-neutral-valid-ready-bundle.t
prove -Iperl t/1468-ial2-ppif-neutral-valid-ready-bundle.t
prove -Iperl t/1435-axi-ial2-valid-ready-generator.t
prove -Iperl t/248-regression-corpus-accounting.t
prove -Iperl t/297-capability-manifest.t
./bin/fsmgen --emit-schedule-json ppif/valid_ready_dual_channel_bundle.ppif
./bin/fsmgen --strict --check --json ppif/valid_ready_dual_channel_bundle.ppif
./bin/fsmgen --strict --emit-semantic-json ppif/valid_ready_dual_channel_bundle.ppif
bash knowledge-map/scripts/gen_knowledge_map.sh
bash knowledge-map/scripts/check_knowledge_map.sh
mdbook build docs/book
scripts/check_docs_relative_paths.sh
scripts/check_memory_architecture.sh
git --no-pager diff --check
scripts/check_doctrines.sh
```

Any broad `t/1436` rerun remains RAM-guarded. Do not bypass a RAM-guard
approval rejection with an unguarded broad run.

## Non-Goals

This contract does not select:

- no-profile `.ppif` input;
- profile-specific suffix aliases;
- full non-AXI protocol behavior;
- common IAL2 queue/order/read-data/transaction constructs;
- AXI manager behavior changes;
- cross-channel dependency rules;
- scoreboards;
- direct backend lowering;
- verification-output generation for IAL2 profiles;
- backend-language variants; or
- VHDL behavior.

## Rollback

Rollback is documentation-only: remove this contract selection, its Knowledge
Map fact, task-tree advancement, README/ROADMAP_V2/mdBook sync, and Memory
pointer. No parser, generator, sample, support-accounting, runtime, generated
HDL, or backend artifact rollback is required.
