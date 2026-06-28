# IAL2 Post APB Generalized Multi-Peripheral Multi-Register Six-Register Next Slice Selection

- Work unit: `IAL2-FEATURE-COMPLETENESS-FRONTIER.686`
- Date: `2026-06-28`
- Status: selected
- Scope: next-slice selection after APB 32-bit no-policy six-register
  generalized register-set timing behavior shipped

## Decision

`IAL2-FEATURE-COMPLETENESS-FRONTIER.686` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.687`, public contract selection for the
bounded APB sideband-aware data16 no-policy six-register generalized
`reg0..regN` register-set multi-peripheral back-to-back timing family.

This selector changes no parser behavior, generator behavior, public source
file, support-accounting catalog entry, validation behavior, generated
artifact, schedule/check/semantic JSON behavior, HDL/runtime behavior, suffix
acceptance, direct backend lowering, verification-output generation,
backend-language variant, APB transaction behavior, AXI behavior, AHB
behavior, or VHDL behavior.

## Evidence Read

This selector read the `.685` 32-bit no-policy six-register behavior, `.684`
six-register contract, `.683` broader-cardinality audit, `.681` data16
protected five-register behavior, `.678` 32-bit protected five-register
behavior, `.675` data16 no-policy five-register behavior, `.672` 32-bit
no-policy five-register behavior, current `ApbCompleter` and `ApbComposition`
generalized cardinality predicates and residue, `RegressionCorpus`,
`LanguageSurfaceSection`, focused APB/profile-alias/support/capability tests,
README, ROADMAP_V2, mdBook, Memory, Knowledge Map, and relevant decisions.

The live guards now admit the selected 32-bit no-policy family up to six
registers while the data16 no-policy representative remains five-register.
A temporary `/tmp` data16 six-register probe based on the shipped data16
five-register public source fails strict check JSON at the selected data16
generalized storage-shape diagnostic and has no support-accounting match.

The next selected owner is data16 no-policy because it is the nearest
unprotected cardinality sibling to `.685`: it keeps register-local protection
policy out of scope, reuses the shipped sideband data16 no-policy timing
shape, and settles the 2-byte stride / 2-bit `PSTRB` six-register public
contract before any behavior change. Protected six-register families,
more-than-six registers, and more-than-two peripheral completers remain
separate broader owners.

## Selected Next Owner

`.687` must select the exact public contract for a data16 no-policy
six-register representative before implementation. It must settle:

- exact `.ppif` and `.apb` public source names;
- protocol-platform-intent name, source object id, and source anchor;
- one requester and exactly two peripheral completers;
- 32-bit APB addresses and 16-bit APB/register data;
- `PPROT width 3` and `PSTRB width 2`;
- status/control windows with the shipped data16 bases `0` and `258`;
- representative `reg0/reg1/reg2/reg3/reg4/reg5` local addresses
  `0/2/4/6/8/10`;
- no register-local `access-policy` clauses;
- queue-depth `1`, overflow `reject`, adjacent setup on both completers, and
  propagation-only interconnect decode;
- whether the selected data16 no-policy generalized family widens from
  `maximum_count = 5` to `maximum_count = 6`;
- support-accounting identities, coverage buckets, report fields,
  diagnostics, validation probes, rollback, docs, Knowledge Map, and next
  owner.

## Deferred Boundaries

This selector does not select implementation for:

- any data16 six-register public source;
- protected six-register generalized register sets;
- more than six registers;
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

This selector closeout uses documentation/continuity validation plus the
temporary fail-closed probe:

- `./bin/fsmgen --quiet --strict --check --json /tmp/fsmgen-apb-data16-six-register-selector-686.ppif`
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
