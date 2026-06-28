# IAL2 Post APB Protection Generalized Multi-Peripheral Multi-Register Cardinality Next Slice Selection

- Work unit: `IAL2-FEATURE-COMPLETENESS-FRONTIER.679`
- Date: `2026-06-28`
- Status: selected
- Scope: no-behavior next-owner selection after bounded APB 32-bit protected
  five-register generalized timing shipped

## Decision

`IAL2-FEATURE-COMPLETENESS-FRONTIER.679` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.680`, public contract selection for the
bounded APB sideband-aware data16 protected five-register generalized
`reg0..regN` register-set multi-peripheral back-to-back timing family.

The next slice is a contract-selection slice, not an implementation slice.
It must settle exact source names, object id, anchor, selected policy matrix,
report/support identities, validation, rollback, and the implementation owner
before any parser, generator, sample, test, generated-artifact, HDL/runtime,
or APB transaction behavior changes.

This selector changes no parser behavior, generator behavior, public source
file, support-accounting catalog entry, report behavior, validation behavior,
generated artifact, schedule/check/semantic JSON behavior, HDL/runtime
behavior, suffix acceptance, direct backend lowering, verification-output
generation, backend-language variant, APB transaction behavior, AXI behavior,
AHB behavior, or VHDL behavior.

## Evidence Read

This selector read `.678` 32-bit protected five-register behavior, `.677`
contract, `.676` selector, `.675` data16 no-policy five-register behavior,
`.674` contract, `.672` 32-bit no-policy five-register behavior, `.668`
data16 protected generalized behavior, `.665` 32-bit protected generalized
behavior, current `ApbCompleter` and `ApbComposition` protected generalized
cardinality predicates and residue, `RegressionCorpus`,
`LanguageSurfaceSection`, focused APB/profile-alias/support/capability tests,
README, ROADMAP_V2, mdBook, Memory, Knowledge Map, and relevant decisions.

The shipped state is now:

- 32-bit no-policy generalized timing supports two, three, four, or five
  registers per peripheral;
- data16 no-policy generalized timing supports two, three, four, or five
  registers per peripheral;
- 32-bit protected generalized timing supports two, three, four, or five
  registers per peripheral;
- data16 protected generalized timing still supports two, three, or four
  registers per peripheral;
- all selected generalized timing families remain bounded to exactly two
  peripheral completers.

## Why Data16 Protected Next

The data16 protected five-register family is the nearest remaining APB
cardinality sibling after `.678`.

Selecting it next completes the protected five-register pair while keeping the
work bounded to the already-shipped data16 protected policy model. The
existing data16 protected generalized family already defines the selected
access-policy matrix, protected peripheral enforcement owner, 2-byte register
spacing, 2-bit `PSTRB`, status/control windows at `0` and `258`, and
propagation-only interconnect behavior. What remains is a public
five-register contract for widening the data16 protected generalized
cardinality bound from `maximum_count = 4` to `maximum_count = 5`.

## Selected Contract Owner

`.680` shall choose the exact public contract for the bounded APB
sideband-aware data16 protected five-register generalized register-set
multi-peripheral family.

The expected public source family is:

- `ppif/apb_composition_multi_peripheral_multi_register_sideband_data16_protection_generalized_five_register_status_back_to_back.ppif`
- `ppif/apb_composition_multi_peripheral_multi_register_sideband_data16_protection_generalized_five_register_status_back_to_back.apb`

The selected contract must explicitly decide or confirm:

- protocol-platform-intent name;
- source object id and anchor section;
- one requester and exactly two peripheral completers;
- 32-bit APB address width with 16-bit request, response, bus, and register
  data;
- `PPROT width 3` and `PSTRB width 2`;
- status/control windows at bases `0` and `258`;
- queue-depth `1`, overflow `reject`, and adjacent setup admission;
- propagation-only interconnect decode with no interconnect-owned protection
  predicate;
- five-register representative `reg0/reg1/reg2/reg3/reg4` at local byte
  addresses `0/2/4/6/8`;
- admitted data16 protected generalized family bound `maximum_count = 5`;
- selected policy matrix: `reg0` read allow, `reg0` write privileged
  `PPROT[0] == 1`, and every `reg1..regN` read/write privileged
  `PPROT[0] == 1`;
- support-accounting identities, capability buckets, diagnostics,
  report/residue expectations, validation probes, rollback, docs, Knowledge
  Map, and implementation owner.

## Deferred Boundaries

`.679` does not select implementation. It keeps 32-bit protected behavior,
data16 protected behavior, more-than-five registers, more-than-two peripheral
completers, deeper queues, overflow policies other than `reject`,
accepted-less requesters, multiple active APB transfers, alternate access
policies, interconnect-owned protection policy, bus matrices, scoreboards,
direct backend lowering, verification-output generation, backend-language
variants, AXI, AHB, and VHDL unchanged.

## Validation

No behavior changed. Closeout validation is documentation/doctrine focused:

- `knowledge-map/scripts/gen_knowledge_map.sh`
- `knowledge-map/scripts/check_knowledge_map.sh`
- `mdbook build docs/book`
- `scripts/check_docs_relative_paths.sh`
- `scripts/check_memory_architecture.sh`
- `git diff --check`
- `scripts/check_doctrines.sh`

## Rollback

Rollback removes this selector doc and fact card, restores the task-tree and
Memory pointers to the post-`.678` state, regenerates the Knowledge Map, and
leaves all parser/generator/source/test/HDL/runtime behavior unchanged.
