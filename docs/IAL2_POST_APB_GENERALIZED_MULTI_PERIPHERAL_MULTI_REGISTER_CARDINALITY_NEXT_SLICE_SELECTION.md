# IAL2 Post APB Generalized Multi-Peripheral Multi-Register Cardinality Next Slice Selection

- Work unit: `IAL2-FEATURE-COMPLETENESS-FRONTIER.673`
- Date: `2026-06-28`
- Status: selected
- Scope: next-slice selection after the first APB 32-bit no-policy
  five-register generalized register-set timing behavior shipped

## Decision

`IAL2-FEATURE-COMPLETENESS-FRONTIER.673` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.674`, public contract selection for the
bounded APB sideband-aware data16 no-policy five-register generalized
`reg0..regN` register-set multi-peripheral back-to-back timing family.

This selector changes no parser behavior, generator behavior, public source
file, support-accounting catalog entry, validation behavior, generated
artifact, schedule/check/semantic JSON behavior, HDL/runtime behavior, suffix
acceptance, direct backend lowering, verification-output generation,
backend-language variant, APB transaction behavior, AXI behavior, AHB
behavior, or VHDL behavior.

## Evidence Read

This selector read the `.672` 32-bit no-policy five-register behavior, `.671`
contract, `.670` cardinality readiness audit, `.668` data16 protected
generalized behavior, `.665` 32-bit protected generalized behavior, `.662`
data16 no-policy generalized behavior, `.660` 32-bit no-policy generalized
behavior, current `ApbCompleter` and `ApbComposition` generalized cardinality
predicates and residue, `RegressionCorpus`, `LanguageSurfaceSection`, focused
APB/profile-alias/support/capability tests, README, ROADMAP_V2, mdBook,
Memory, Knowledge Map, and relevant decisions.

The next selected owner is data16 no-policy because it is the nearest
cardinality sibling to `.672`: it keeps register-local protection policy out
of scope, reuses the shipped sideband data16 no-policy timing shape, and
settles the 2-byte stride / 2-bit `PSTRB` five-register public contract before
any behavior change.

## Selected Next Owner

`.674` must select the exact public contract for a data16 no-policy
five-register representative before implementation. It must settle:

- exact `.ppif` and `.apb` public source names;
- protocol-platform-intent name, source object id, and source anchor;
- one requester and exactly two peripheral completers;
- 32-bit APB addresses and 16-bit APB/register data;
- `PPROT width 3` and `PSTRB width 2`;
- status/control windows with the shipped data16 bases `0` and `258`;
- representative `reg0/reg1/reg2/reg3/reg4` local addresses
  `0/2/4/6/8`;
- no register-local `access-policy` clauses;
- queue-depth `1`, overflow `reject`, adjacent setup on both completers, and
  propagation-only interconnect decode;
- whether the selected data16 no-policy generalized family widens from
  `maximum_count = 4` to `maximum_count = 5`;
- support-accounting identities, coverage buckets, report fields,
  diagnostics, validation probes, rollback, docs, Knowledge Map, and next
  owner.

## Deferred Boundaries

This selector does not select implementation for:

- any data16 five-register public source;
- protected five-register generalized register sets;
- more than five registers;
- more than two peripheral completers;
- queue depths other than `1`;
- overflow policies other than `reject`;
- accepted-less requester timing;
- multiple active APB transfers;
- alternate protection-policy matrices;
- bus matrices or scoreboards;
- direct backend lowering;
- verification-output generation;
- backend-language variants, AXI, AHB, or VHDL behavior.

## Validation

This selector closeout uses documentation/continuity validation only:

- Knowledge Map generation/check;
- mdBook build;
- docs path audit;
- memory architecture check;
- whitespace diff check;
- fact-card reverify search;
- `scripts/check_doctrines.sh`.

No parser, generator, public source, support-accounting, generated-artifact,
HDL/runtime, APB transaction, AXI, AHB, or VHDL behavior is changed by this
selector.

## Rollback

Rollback removes this selector document, its Knowledge Map fact card, README,
ROADMAP_V2, mdBook, task-tree, Memory, and generated Knowledge Map updates.
No parser, generator, public source, support-accounting, generated-artifact,
HDL/runtime, APB transaction, AXI, AHB, or VHDL behavior changes are part of
this selector.
