# IAL2 Protocol-Neutral Valid-Ready Bundle Readiness Audit

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.533`

Date: 2026-06-26

## Outcome

`IAL2-FEATURE-COMPLETENESS-FRONTIER.533` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.534`, public contract selection for a
bounded protocol-neutral/non-AXI Valid-Ready `.ppif` bundle.

The audit does not select direct behavior implementation yet. Existing
aggregate bundle mechanics are close enough that no new wrapper/top
prerequisite is exposed, but the neutral bundle public contract still needs an
exact owner before parser, generator, sample, support-accounting, report, or
HDL behavior changes.

This audit changes no parser behavior, generator behavior, PPIF sample,
support-accounting catalog, validation behavior, generated artifact, test,
schedule/check/semantic JSON behavior, HDL/runtime behavior, backend behavior,
verification-output generation, backend-language variant, external converter
dependency, scoreboard, AXI behavior, non-AXI behavior, common construct
promotion, profile-alias suffix syntax, or VHDL behavior.

## Evidence Read

The controlling public rule remains unchanged:

- `.ppif` is the generic Protocol/Platform Intent Format IAL2 container;
- AXI is the first shipped IAL2 profile/example, not the definition of IAL2;
- future protocol-specific suffixes are profile aliases over IAL2; and
- common IAL2 constructs stay small until compatible reuse is proven across
  multiple profiles.

`.531` shipped `ppif/valid_ready_handshake.ppif` under explicit
`(profile valid-ready)`. It proves one neutral Valid-Ready channel with
authored channel `data_link`, role `producer-to-consumer`, internal
`FSMGEN-IAL2-VALID-READY-PROFILE` source anchors, generic target-channel
reporting, and support identity `intent.ppif_valid_ready_handshake`.

Decision `0017` and the shipped AXI AW/W bundle path prove the aggregate
bundle contract:

- per-channel generated `.isf` review artifacts;
- per-channel generated `.fsm` artifacts;
- one aggregate wrapper/top `.fsm`;
- aggregate `valid_ready_bundle.v1` schedule and semantic report roots;
- selected aggregate wrapper/top HDL entry; and
- fail-closed duplicate artifact, duplicate wrapper port, shared clock, and
  reset-policy checks.

The current PPIF adapter still blocks neutral bundles before that aggregate
path can run:

```text
profile valid-ready supports exactly one (valid-ready-channel ...) object
```

The no-write audit probe confirmed that a two-channel `(profile valid-ready)`
source fails on that guard. Separate no-write CLI probes confirmed that the
existing AXI AW/W bundle and the one-channel neutral sample still emit
schedule JSON successfully.

The existing aggregate report is still AXI-shaped in one important place: its
top-level bundle residue unconditionally reports `axi_manager_concurrency`.
That is correct for the AXI AW/W sample, but a neutral `valid-ready` bundle
needs generic monitor-profile residue instead.

## Readiness Finding

The next owner should be a public contract selection, not direct
implementation.

Direct implementation would be a small code delta, but it would force several
public choices into the implementation patch:

- sample path and support-accounting identity;
- whether the first neutral bundle should exercise one neutral role or both;
- top-level and channel-local source-anchor policy when no external protocol
  specification is cited;
- inherited-source reporting for omitted channel-local source metadata;
- whether the aggregate `valid_ready_bundle.v1` schema remains stable;
- the neutral aggregate residue id and wording;
- expected generated monitor and wrapper/top artifact names;
- focused validation that avoids relying on a full broad `t/1436` run when the
  RAM guard may stop it; and
- public README/ROADMAP/mdBook wording that does not imply all IAL2 is AXI or
  that one neutral Valid-Ready bundle promotes common queue/order/read-data
  constructs.

No separate aggregate wrapper/top prerequisite is needed. The current wrapper
generation already derives the top module from the PPIF intent name, shares
identical system ports once, exposes the union of channel public ports, rejects
non-system duplicate wrapper ports, rejects incompatible resets, and preserves
the mandatory `IAL2 -> IAL1 -> IAL0 -> HDL` chain.

## Candidate Source Shape

`.534` should select or revise this exact candidate before implementation:

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

The candidate intentionally exercises both neutral roles. It also exercises
one channel-local source anchor and one inherited channel source, so the
existing bundle source-attribution machinery can be proven outside AXI.

Candidate public names:

| Item | Candidate |
| --- | --- |
| Sample path | `ppif/valid_ready_dual_channel_bundle.ppif` |
| Support-accounting id | `intent.ppif_valid_ready_dual_channel_bundle` |
| Coverage key | `ial2_ppif_valid_ready_dual_channel_bundle_pipeline_cli` |
| Wrapper/top artifact | `valid_ready_dual_channel_bundle.fsm` |
| Wrapper/top module | `valid_ready_dual_channel_bundle` |
| Channel artifacts | `data_downstream_valid_ready_monitor.isf/.fsm`; `status_upstream_valid_ready_monitor.isf/.fsm` |
| Aggregate schema | `fsmgen.ial2.protocol_intent.valid_ready_bundle.v1` |

## Contract Questions For `.534`

`.534` should select:

- whether the candidate source shape above is the first public neutral bundle;
- whether both `producer-to-consumer` and `consumer-to-producer` are required
  in the first sample, or whether one role should remain deferred;
- the exact source-anchor wording for the internal bundle profile contract;
- the aggregate residue id, likely a generic monitor-profile residue such as
  `valid_ready_profile_bundle_behavior_outside_monitor`;
- preservation of `axi_manager_concurrency` residue for AXI-profile bundles;
- public docs and manifest wording that says current shipped multi-channel
  bundle behavior is AXI AW/W until the neutral bundle implementation ships;
- focused tests and direct CLI probes for schedule JSON, `--outdir`, default
  HDL, check JSON, semantic JSON, and support accounting; and
- RAM-guard policy for any broad parser/CLI rerun.

## Preservation Matrix

| Surface | Preservation rule |
| --- | --- |
| `.ppif` container | Remains the generic IAL2 container; no direct `.ppif -> .fsm` path. |
| Neutral one-channel sample | `ppif/valid_ready_handshake.ppif` remains supported and support-accounted. |
| Neutral bundle | Remains fail-closed until a future implementation owner changes behavior. |
| AXI Valid-Ready bundle | `ppif/axi_aw_w_valid_ready_bundle.ppif` remains supported with AXI roles, AXI channel families, and AXI residue. |
| AXI manager capacity/status | Remains profile-local shipped coverage; no behavior changes here. |
| Profile aliases | Remain future exact-owner work; no suffix alias syntax is introduced. |
| Common IAL2 constructs | No queue, ordering, read-data, transaction, or scoreboard construct is promoted by this audit. |
| Reports and JSON | Existing schedule/check/semantic JSON schemas and fields remain unchanged in `.533`. |
| HDL/backends | No HDL/runtime/backend/VHDL behavior changes in `.533`. |

## Validation

The audit used these no-write evidence probes:

```bash
perl -Iperl -MFSM::Adapter::IAL2::PPIF -e '...'
./bin/fsmgen --emit-schedule-json ppif/axi_aw_w_valid_ready_bundle.ppif
./bin/fsmgen --emit-schedule-json ppif/valid_ready_handshake.ppif
```

The closeout gates for `.533` are documentation-only:

```bash
bash knowledge-map/scripts/gen_knowledge_map.sh
bash knowledge-map/scripts/check_knowledge_map.sh
mdbook build docs/book
scripts/check_docs_relative_paths.sh
scripts/check_memory_architecture.sh
git --no-pager diff --check
scripts/check_doctrines.sh
```

## Rollback

Rollback is documentation-only: remove this audit, its Knowledge Map fact,
task-tree advancement, README/ROADMAP_V2/mdBook sync, and Memory pointer. No
parser, generator, sample, support-accounting, runtime, generated HDL, or
backend artifact rollback is required.
