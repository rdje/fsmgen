# IAL2 Post APB Data16 Protection Back-To-Back Next Slice Selection

- Work unit: `IAL2-FEATURE-COMPLETENESS-FRONTIER.632`
- Date: `2026-06-28`
- Status: selected
- Scope: no-behavior next-owner selection after selected APB sideband-aware
  data16-protection fixed back-to-back behavior shipped

## Decision

`IAL2-FEATURE-COMPLETENESS-FRONTIER.632` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.633`, public contract selection for a
bounded APB sideband-aware multi-peripheral data16-protection back-to-back
timing-policy family.

No parser behavior, generator behavior, public sample, support-accounting,
schedule/check/semantic JSON, generated artifact, HDL/runtime behavior, suffix
acceptance, direct backend lowering, verification-output generation,
backend-language variant, APB behavior, AXI behavior, AHB behavior, or VHDL
behavior changes in this selector slice.

## Evidence Read

The selector reviewed the active roadmap and continuity surfaces:

- `README.md`, `ROADMAP_V2.md`, `MEMORY.md`, `docs/TASK_TREE.md`, and
  `docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md`
- the mdBook APB IAL2 backlog chapter and the protocol-support workflow
  chapter
- Knowledge Map cards for `.631`, `.630`, `.629`, `.620`, and APB
  multi-peripheral timing readiness
- relevant decision records from `docs/decisions/INDEX.md`

The selector also reviewed the APB timing chain:

- `.631` data16-protection back-to-back behavior
- `.630` data16-protection back-to-back contract selection
- `.629` post-protection timing owner selection
- `.628` protection timing behavior
- `.625` data16 timing behavior
- `.622` and `.621` sideband multi-register timing records
- `.620` data16/protection timing readiness audit
- `.618` and `.609` multi-peripheral timing behavior records
- `.612` sideband requester timing behavior

Code and public-surface review covered `ApbComposition`,
`ApbRequesterTransfer`, `ApbCompleter`, `RegressionCorpus`,
`LanguageSurfaceSection`, APB profile-alias tests, APB completer/composition
tests, support-accounting tests, and capability-manifest coverage.

Live parser/report probes after `.631` confirmed that
`ppif/apb_composition_multi_peripheral_sideband_data16_protection.ppif` and
its `.apb` alias already carry the selected multi-peripheral protected
data16 topology, but still report no aggregate `back_to_back_policy` and keep
broad `apb_back_to_back_policy_deferred`. Existing fixed
data16-protection timing reports aggregate `back_to_back_policy`, and existing
sideband multi-peripheral status timing reports aggregate
`back_to_back_policy`, so the remaining residue is the composition of those
two shipped capabilities.

## Why Multi-Peripheral Data16-Protection Next

Multi-peripheral data16-protection timing is the narrowest remaining APB
timing residue after `.631`.

The prerequisite behaviors are already present:

- fixed data16-protection adjacent setup and fixed-composition timing from
  `.631`
- sideband-aware multi-peripheral status timing propagation through
  `apb_interconnect` from `.618`
- no-sideband multi-peripheral timing propagation from `.609`
- sideband multi-register and data16/protection endpoint timing prerequisites
  from `.622`, `.625`, `.628`, and `.631`

Selecting `.633` keeps the next slice bounded to the existing static
two-peripheral data16-protection topology and avoids pulling in broader
multi-peripheral multi-register timing, deeper queues, alternate overflow,
accepted-less requesters, multiple active APB transfers, broader protection
policies, direct backend lowering, verification-output generation,
backend-language variants, AXI, AHB, or VHDL.

## `.633` Contract-Selection Boundary

`.633` must settle, before implementation:

- exact `.ppif` and `.apb` public source names
- whether the first selected family is limited to the existing
  `apb_composition_multi_peripheral_sideband_data16_protection` shape plus a
  back-to-back suffix
- requester endpoint requirements, including accepted/busy/status depth-1
  queued timing, 16-bit data, `PPROT width 3`, and `PSTRB width 2`
- peripheral completer requirements, including the protected data16
  two-register shape, adjacent setup admission, `reg0` byte address `0`, and
  `reg1` byte address `2`
- interconnect propagation requirements for queued setup decode, `PPROT`,
  `PSTRB`, write data, address selection, and response muxing
- report and residue movement for top, requester, interconnect, and each
  peripheral
- support-accounting identities and language-surface/capability-manifest
  wording
- diagnostics for unsupported topology, width, protection, timing, and
  interconnect combinations
- focused validation and rollback boundaries

## Deferred Work

`.632` keeps the following work explicitly deferred:

- broader multi-peripheral multi-register timing propagation beyond the exact
  selected data16-protection topology
- queue depths other than 1
- overflow policies other than reject
- accepted-less requesters
- multiple active APB transfers
- broader protection policies
- direct backend lowering
- verification-output generation
- backend-language variants
- AXI
- AHB
- VHDL

## Validation

This selector is documentation, task-tree, mdBook, memory, and Knowledge Map
only. Closeout validation is the doctrine/doc gate set:

- `knowledge-map/scripts/gen_knowledge_map.sh`
- `knowledge-map/scripts/check_knowledge_map.sh`
- `mdbook build docs/book`
- `scripts/check_doctrines.sh`
- `git diff --check`

No runtime behavior tests are required because no behavior-bearing files are
changed.

## Rollback

Rollback is the single `.632` documentation/continuity commit. Reverting it
restores `.632` as the active selector and removes `.633` ownership before any
behavior-bearing implementation begins.
