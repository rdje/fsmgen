# IAL2 Post APB Data16 Protection Generalized Multi-Peripheral Multi-Register Cardinality Next Slice Selection

- Work unit: `IAL2-FEATURE-COMPLETENESS-FRONTIER.682`
- Date: `2026-06-28`
- Status: selected
- Scope: no-behavior next-owner selection after all four bounded APB
  five-register generalized timing siblings shipped

## Decision

`IAL2-FEATURE-COMPLETENESS-FRONTIER.682` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.683`, a readiness audit for broader APB
generalized register-set cardinality beyond the selected five-register,
two-peripheral timing families.

The next slice is an audit slice, not a contract or implementation slice. It
must re-baseline the current guards, report residue, source/test surfaces, and
public documentation after the 32-bit no-policy, data16 no-policy, 32-bit
protected, and data16 protected five-register siblings all shipped. It must
then decide whether the next exact owner should be a more-than-five-register
contract, a more-than-two-peripheral contract, a smaller prerequisite in
reports/static diagnostics/address-map/public fixtures, or explicit deferral.

This selector changes no parser behavior, generator behavior, public source
file, support-accounting catalog entry, report behavior, validation behavior,
generated artifact, schedule/check/semantic JSON behavior, HDL/runtime
behavior, suffix acceptance, direct backend lowering, verification-output
generation, backend-language variant, APB transaction behavior, AXI behavior,
AHB behavior, or VHDL behavior.

## Evidence Read

This selector read `.681` data16 protected five-register behavior, `.680`
contract, `.679` selector, `.678` 32-bit protected five-register behavior,
`.675` data16 no-policy five-register behavior, `.672` 32-bit no-policy
five-register behavior, `.668` data16 protected generalized behavior, `.670`
cardinality audit, current `ApbCompleter` and `ApbComposition` guards and
residue, `RegressionCorpus`, `LanguageSurfaceSection`, focused
APB/profile-alias/support/capability tests, README, ROADMAP_V2, mdBook,
Memory, Knowledge Map, and relevant decisions.

The shipped state is now:

- 32-bit no-policy generalized timing supports two, three, four, or five
  registers per peripheral;
- data16 no-policy generalized timing supports two, three, four, or five
  registers per peripheral;
- 32-bit protected generalized timing supports two, three, four, or five
  registers per peripheral;
- data16 protected generalized timing supports two, three, four, or five
  registers per peripheral;
- all selected generalized timing families remain bounded to exactly two
  peripheral completers;
- current guards still reject register counts above five and peripheral counts
  above two for these selected multi-peripheral back-to-back shapes.

## Why A Readiness Audit Next

The post-`.670` five-register plan is now complete. A direct implementation
slice would be premature because the next broader cardinality axis is no
longer a single obvious sibling. More-than-five registers and more-than-two
peripheral completers both cross an existing hard boundary, and either may
need smaller report, static diagnostic, address-map, public-fixture, or
support-accounting work before a behavior contract can be selected cleanly.

The current code also expresses the remaining boundary as broad timing and
cardinality residue rather than a single dedicated public contract. `.683`
therefore owns the next audit before any parser/generator/sample/test/HDL
behavior changes.

## Selected Audit Owner

`.683` shall audit broader APB generalized register-set cardinality after the
four five-register siblings.

The audit must explicitly cover:

- whether the next contract should start with more than five registers in the
  existing exactly-two-peripheral shape;
- whether the next contract should start with more than two peripheral
  completers for the existing two-to-five-register shape;
- whether one axis depends on smaller prerequisites in report metadata,
  static diagnostics, address-map description, public fixture naming, support
  accounting, or capability-manifest wording;
- whether protected and data16 variants should follow the same sibling ladder
  as the five-register work or be deferred behind a no-policy 32-bit pilot;
- how status/control windows, register stride, data width, `PSTRB`, `PPROT`,
  queue-depth `1`, overflow `reject`, adjacent setup, and propagation-only
  interconnect constraints affect the next public contract;
- expected source names, report surfaces, diagnostics, validation probes,
  rollback, docs, Knowledge Map, and implementation owner for the next
  selected slice.

## Deferred Boundaries

`.682` does not select implementation. It keeps more-than-five registers,
more-than-two peripheral completers, deeper queues, overflow policies other
than `reject`, accepted-less requesters, multiple active APB transfers,
alternate access policies, interconnect-owned protection policy, bus
matrices, scoreboards, direct backend lowering, verification-output
generation, backend-language variants, AXI, AHB, and VHDL unchanged.

## Validation

No behavior changed. Closeout validation is documentation/continuity focused:

- `knowledge-map/scripts/gen_knowledge_map.sh`
- `knowledge-map/scripts/check_knowledge_map.sh`
- `mdbook build docs/book`
- `scripts/check_docs_relative_paths.sh`
- `scripts/check_memory_architecture.sh`
- `git diff --check`
- `scripts/check_doctrines.sh`

## Rollback

Rollback removes this selector document and fact card, restores the task-tree
and Memory pointers to the post-`.681` state, regenerates the Knowledge Map,
and leaves all parser/generator/source/test/HDL/runtime behavior unchanged.
