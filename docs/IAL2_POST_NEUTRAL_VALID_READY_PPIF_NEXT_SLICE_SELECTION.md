# IAL2 Post Neutral Valid-Ready PPIF Next Slice Selection

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.532`

Date: 2026-06-26

## Outcome

`IAL2-FEATURE-COMPLETENESS-FRONTIER.532` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.533`, readiness audit for
protocol-neutral/non-AXI Valid-Ready `.ppif` bundles.

This selector changes no parser behavior, generator behavior, PPIF sample,
support-accounting catalog, validation behavior, generated artifact, test,
schedule/check/semantic JSON behavior, HDL/runtime behavior, backend behavior,
verification-output generation, backend-language variant, external converter
dependency, scoreboard, AXI behavior, non-AXI behavior, common construct
promotion, profile-alias suffix syntax, or VHDL behavior.

## Selection Rationale

`.531` shipped the first protocol-neutral/non-AXI one-channel Valid-Ready
`.ppif` sample under:

```text
(profile valid-ready)
```

It also deliberately kept protocol-neutral multi-channel bundles unsupported:

```text
profile valid-ready supports exactly one (valid-ready-channel ...) object
```

That fail-closed boundary is now the smallest honest next question. The repo
already has a general aggregate Valid-Ready bundle contract in decision `0017`
and a shipped AXI AW/W bundle path, but those shipped examples exercise AXI
profiles, AXI channel families, AXI roles, and AXI-shaped report residue. A
neutral bundle must be audited before implementation because it needs exact
answers for:

- whether decision `0017` can apply unchanged to `(profile valid-ready)`;
- how aggregate wrapper/top naming should work for authored neutral channel
  identifiers;
- whether `producer-to-consumer` and `consumer-to-producer` may coexist in one
  first neutral bundle;
- how channel-local source anchors should cite the internal valid-ready
  profile contract without inventing external protocol evidence;
- whether aggregate residue must stay monitor-profile-only and avoid AXI
  manager concurrency residue;
- how duplicate public ports, reset compatibility, artifact collisions, and
  generated wrapper/top entry selection apply to neutral channel names;
- whether support accounting needs a new public sample or a metadata-only
  audit first; and
- which focused checks can cover the new path without relying on a full broad
  `t/1436` run that may hit the RAM guard.

## Alternatives Considered

Another one-channel neutral sample is lower value now that `.531` already
proves the profile vocabulary, support accounting, and report residue for the
generic valid-ready profile.

Profile suffix alias design remains valid future work, but `.531` deliberately
introduced no `.axi`, `.chi`, `.ace`, `.ahb`, `.apb`, `.atb`, `.smbus`, or
`.i2s` alias. A suffix-alias owner should wait until the generic `.ppif`
profile behavior has at least one more neutral compatibility point.

Common IAL2 construct promotion remains premature. One neutral one-channel
sample is not enough evidence to promote any queue, ordering, read-data, or
transaction construct into common IAL2.

Returning immediately to profile-local AXI implementation would be
roadmap-valid, but it would leave the newly exposed neutral bundle boundary
unaudited right after the user-facing correction that IAL2 is broader than
AXI.

## Selected `.533` Scope

`.533` should audit protocol-neutral Valid-Ready bundle readiness before any
behavior change. It should read:

- `.531` behavior;
- `.530` contract selection;
- `.529` readiness audit;
- decision `0017`;
- the shipped AXI AW/W bundle behavior and HDL entry records;
- `FSM::Adapter::IAL2::PPIF` bundle parsing/report paths;
- `FSM::IAL2::ProtocolIntent::ValidReadyChannel` profile normalization and
  residue reporting;
- focused parser/CLI/support-accounting test surfaces;
- public/downstream contracts, capability manifest, README, ROADMAP_V2,
  mdBook, task tree, Memory, and Knowledge Map.

The audit should decide whether the next owner can directly implement a
bounded neutral bundle, must first select a neutral bundle public contract,
must split an aggregate wrapper/top prerequisite, or should keep the boundary
deferred behind another protocol-neutral profile sample.

## Preservation Matrix

| Surface | Preservation rule |
| --- | --- |
| `.ppif` container | Remains the generic IAL2 container; no direct `.ppif -> .fsm` path. |
| Neutral one-channel sample | `ppif/valid_ready_handshake.ppif` remains supported and support-accounted. |
| AXI Valid-Ready | Existing one-channel and AW/W bundle behavior remains unchanged. |
| AXI manager capacity/status | Remains profile-local shipped coverage; no behavior changes here. |
| Profile aliases | Remain future exact-owner work; no suffix alias syntax is introduced. |
| Common IAL2 constructs | No construct is promoted merely because Valid-Ready uses it. |
| Reports and JSON | Existing schedule/check/semantic JSON schemas and fields remain unchanged in `.532`. |
| HDL/backends | No HDL/runtime/backend/VHDL behavior changes in `.532`. |

## Validation

`.532` is documentation-only and closes with:

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

Rollback is documentation-only: remove this selector, its Knowledge Map fact,
task-tree advancement, README/ROADMAP_V2/mdBook sync, and Memory pointer. No
parser, generator, sample, support-accounting, runtime, generated HDL, or
backend artifact rollback is required.
