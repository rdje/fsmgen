# Knowledge Map

> **AUTO-GENERATED — DO NOT EDIT.** Regenerate with `knowledge-map/scripts/gen_knowledge_map.sh`.
> Source of truth = YAML front-matter in: `docs/knowledge docs/decisions`. Edit the fact files, never this map.
> A fact is any `.md` whose front-matter has a non-empty `answers:` list.
> **10** facts · **48** question keys.

## Questions → fact

- "Unsupported expression operator <point>_active" -> [isf-fsm-verification-boundary](docs/knowledge/isf-fsm-verification-boundary.md) · 2026-06-03 · reverify: `grep -n "_active" perl/FSM/Scheduler/ISF/LoweringIR.pm | head`
- "can I add a new key to the ISF schedule report?" -> [isf-schedule-report-additive-keys](docs/knowledge/isf-schedule-report-additive-keys.md) · 2026-06-03 · reverify: `prove -Iperl t/1116-isf-public-schedule-report-key-family-audit.t t/1227-isf-schedule-report-freeze-boundary.t`
- "can I compare aggregate +params with == or !=?" -> [aggregate-parameter-comparison](docs/knowledge/aggregate-parameter-comparison.md) · 2026-06-05 · reverify: `prove -Iperl t/30-language-contract-symbol-definitions.t t/51-language-contract-symbol-definition-boundary.t t/88-rtlif-typed-port-contract.t t/91-composition-multi-rtl-children.t t/292-composition-generated-child-parameter-overrides.t`
- "can ISF assertions reference current_state or state_active?" -> [isf-fsm-verification-boundary](docs/knowledge/isf-fsm-verification-boundary.md) · 2026-06-03 · reverify: `grep -n "_active" perl/FSM/Scheduler/ISF/LoweringIR.pm | head`
- "do aggregate parameters support equality or inequality?" -> [aggregate-parameter-comparison](docs/knowledge/aggregate-parameter-comparison.md) · 2026-06-05 · reverify: `prove -Iperl t/30-language-contract-symbol-definitions.t t/51-language-contract-symbol-definition-boundary.t t/88-rtlif-typed-port-contract.t t/91-composition-multi-rtl-children.t t/292-composition-generated-child-parameter-overrides.t`
- "does .rtlif support aggregate generic comparison defaults?" -> [aggregate-parameter-comparison](docs/knowledge/aggregate-parameter-comparison.md) · 2026-06-05 · reverify: `prove -Iperl t/30-language-contract-symbol-definitions.t t/51-language-contract-symbol-definition-boundary.t t/88-rtlif-typed-port-contract.t t/91-composition-multi-rtl-children.t t/292-composition-generated-child-parameter-overrides.t`
- "does ISF (within …) support a lower bound / a range / F[min,max]?" -> [isf-bounded-window-min](docs/knowledge/isf-bounded-window-min.md) · 2026-06-04 · reverify: `prove -Iperl t/1418-isf-property-window-range.t`
- "does ISF support $stable / $rose / $fell / $changed?" -> [isf-sampled-value-predicates](docs/knowledge/isf-sampled-value-predicates.md) · 2026-06-04 · reverify: `prove -Iperl t/1417-isf-property-sampled-value.t`
- "does ISF validate the assert condition or pass it through?" -> [isf-property-grammar-location](docs/knowledge/isf-property-grammar-location.md) · 2026-06-04 · reverify: `grep -n "sub parse_check_property" perl/FSM/Adapter/FSMGenFull/Parser.pm`
- "does adding a schedule-report key need a schema_version bump?" -> [isf-schedule-report-additive-keys](docs/knowledge/isf-schedule-report-additive-keys.md) · 2026-06-03 · reverify: `prove -Iperl t/1116-isf-public-schedule-report-key-family-audit.t t/1227-isf-schedule-report-freeze-boundary.t`
- "how do I add a property combinator or operator to ISF checks?" -> [isf-property-grammar-location](docs/knowledge/isf-property-grammar-location.md) · 2026-06-04 · reverify: `grep -n "sub parse_check_property" perl/FSM/Adapter/FSMGenFull/Parser.pm`
- "how do I anchor a position in ISF verification without touching the state variable?" -> [isf-fsm-verification-boundary](docs/knowledge/isf-fsm-verification-boundary.md) · 2026-06-03 · reverify: `grep -n "_active" perl/FSM/Scheduler/ISF/LoweringIR.pm | head`
- "how do I assert on a rising or falling edge in ISF?" -> [isf-sampled-value-predicates](docs/knowledge/isf-sampled-value-predicates.md) · 2026-06-04 · reverify: `prove -Iperl t/1417-isf-property-sampled-value.t`
- "how do I check a signal is stable or unchanged in an ISF assertion?" -> [isf-sampled-value-predicates](docs/knowledge/isf-sampled-value-predicates.md) · 2026-06-04 · reverify: `prove -Iperl t/1417-isf-property-sampled-value.t`
- "how do I express 'data stable while valid' in ISF?" -> [isf-sampled-value-predicates](docs/knowledge/isf-sampled-value-predicates.md) · 2026-06-04 · reverify: `prove -Iperl t/1417-isf-property-sampled-value.t`
- "how do I express a min>1 bounded window / lower bound in an ISF assertion?" -> [isf-bounded-window-min](docs/knowledge/isf-bounded-window-min.md) · 2026-06-04 · reverify: `prove -Iperl t/1418-isf-property-window-range.t`
- "how do I run the full test suite?" -> [full-test-suite-invocation](docs/knowledge/full-test-suite-invocation.md) · 2026-06-03 · reverify: `prove -j4 -Iperl t/`
- "how do I say 'ack between 2 and 5 cycles after req' in ISF?" -> [isf-bounded-window-min](docs/knowledge/isf-bounded-window-min.md) · 2026-06-04 · reverify: `prove -Iperl t/1418-isf-property-window-range.t`
- "how do I write a stability or edge property in an assert/assume/cover?" -> [isf-sampled-value-predicates](docs/knowledge/isf-sampled-value-predicates.md) · 2026-06-04 · reverify: `prove -Iperl t/1417-isf-property-sampled-value.t`
- "how do aggregate comparison parameters lower to HDL?" -> [aggregate-parameter-comparison](docs/knowledge/aggregate-parameter-comparison.md) · 2026-06-05 · reverify: `prove -Iperl t/30-language-contract-symbol-definitions.t t/51-language-contract-symbol-definition-boundary.t t/88-rtlif-typed-port-contract.t t/91-composition-multi-rtl-children.t t/292-composition-generated-child-parameter-overrides.t`
- "how do exit-when and continue-when differ in their target?" -> [loop-early-exit-target-hook](docs/knowledge/loop-early-exit-target-hook.md) · 2026-06-03 · reverify: `grep -n "loop_exit_target" perl/FSM/Scheduler/ISF/LoweringIR.pm`
- "how does (within B MIN MAX) lower / what does ##[MIN:MAX] come from?" -> [isf-bounded-window-min](docs/knowledge/isf-bounded-window-min.md) · 2026-06-04 · reverify: `prove -Iperl t/1418-isf-property-window-range.t`
- "how does ISF get compiled to SystemVerilog?" -> [isf-lowering-pipeline](docs/knowledge/isf-lowering-pipeline.md) · 2026-06-03 · reverify: `grep -rln "package FSM::Scheduler::ISF" perl/FSM/Scheduler/ISF*`
- "how does report() / the JSON schedule report get built?" -> [isf-lowering-pipeline](docs/knowledge/isf-lowering-pipeline.md) · 2026-06-03 · reverify: `grep -rln "package FSM::Scheduler::ISF" perl/FSM/Scheduler/ISF*`
- "how is the loop exit target for a mid-loop early exit computed?" -> [loop-early-exit-target-hook](docs/knowledge/loop-early-exit-target-hook.md) · 2026-06-03 · reverify: `grep -n "loop_exit_target" perl/FSM/Scheduler/ISF/LoweringIR.pm`
- "how long does the full suite take?" -> [full-test-suite-invocation](docs/knowledge/full-test-suite-invocation.md) · 2026-06-03 · reverify: `prove -j4 -Iperl t/`
- "how were transaction_loops / loop_early_exits added without bumping the version?" -> [isf-schedule-report-additive-keys](docs/knowledge/isf-schedule-report-additive-keys.md) · 2026-06-03 · reverify: `prove -Iperl t/1116-isf-public-schedule-report-key-family-audit.t t/1227-isf-schedule-report-freeze-boundary.t`
- "is the ISF schedule report schema frozen or can it grow?" -> [isf-schedule-report-additive-keys](docs/knowledge/isf-schedule-report-additive-keys.md) · 2026-06-03 · reverify: `prove -Iperl t/1116-isf-public-schedule-report-key-family-audit.t t/1227-isf-schedule-report-freeze-boundary.t`
- "the test suite got killed / SIGKILL during prove" -> [full-test-suite-invocation](docs/knowledge/full-test-suite-invocation.md) · 2026-06-03 · reverify: `prove -j4 -Iperl t/`
- "what does schema_version: 1 / evolves_with_isf_implementation mean for the report?" -> [isf-schedule-report-additive-keys](docs/knowledge/isf-schedule-report-additive-keys.md) · 2026-06-03 · reverify: `prove -Iperl t/1116-isf-public-schedule-report-key-family-audit.t t/1227-isf-schedule-report-freeze-boundary.t`
- "what is loop_exit_target in the ISF lowering?" -> [loop-early-exit-target-hook](docs/knowledge/loop-early-exit-target-hook.md) · 2026-06-03 · reverify: `grep -n "loop_exit_target" perl/FSM/Scheduler/ISF/LoweringIR.pm`
- "what is the ISF to FSM to HDL pipeline?" -> [isf-lowering-pipeline](docs/knowledge/isf-lowering-pipeline.md) · 2026-06-03 · reverify: `grep -rln "package FSM::Scheduler::ISF" perl/FSM/Scheduler/ISF*`
- "what is the ISF/FSM separation rule for verification?" -> [isf-fsm-verification-boundary](docs/knowledge/isf-fsm-verification-boundary.md) · 2026-06-03 · reverify: `grep -n "_active" perl/FSM/Scheduler/ISF/LoweringIR.pm | head`
- "what is the command to run all the Perl tests?" -> [full-test-suite-invocation](docs/knowledge/full-test-suite-invocation.md) · 2026-06-03 · reverify: `prove -j4 -Iperl t/`
- "where do I document a new ISF property construct / did the book get synced?" -> [isf-verification-book-map](docs/knowledge/isf-verification-book-map.md) · 2026-06-04 · reverify: `grep -rln "assert\|monitor\|=>\|sampled-value" docs/book/src/13d-control-flow.md docs/book/src/13k-isf-feature-support-matrix.md`
- "where does (=> A B) / next / within / after / sampled-value get parsed and rendered to SVA?" -> [isf-property-grammar-location](docs/knowledge/isf-property-grammar-location.md) · 2026-06-04 · reverify: `grep -n "sub parse_check_property" perl/FSM/Adapter/FSMGenFull/Parser.pm`
- "where does (exit-when) / (continue-when) jump to?" -> [loop-early-exit-target-hook](docs/knowledge/loop-early-exit-target-hook.md) · 2026-06-03 · reverify: `grep -n "loop_exit_target" perl/FSM/Scheduler/ISF/LoweringIR.pm`
- "where does ISF lowering happen?" -> [isf-lowering-pipeline](docs/knowledge/isf-lowering-pipeline.md) · 2026-06-03 · reverify: `grep -rln "package FSM::Scheduler::ISF" perl/FSM/Scheduler/ISF*`
- "where is the .fsm text produced from an ISF actor?" -> [isf-lowering-pipeline](docs/knowledge/isf-lowering-pipeline.md) · 2026-06-03 · reverify: `grep -rln "package FSM::Scheduler::ISF" perl/FSM/Scheduler/ISF*`
- "where is the ISF assert/assume/cover property grammar?" -> [isf-property-grammar-location](docs/knowledge/isf-property-grammar-location.md) · 2026-06-04 · reverify: `grep -n "sub parse_check_property" perl/FSM/Adapter/FSMGenFull/Parser.pm`
- "where is the ISF verification / assert / assume / cover surface documented?" -> [isf-verification-book-map](docs/knowledge/isf-verification-book-map.md) · 2026-06-04 · reverify: `grep -rln "assert\|monitor\|=>\|sampled-value" docs/book/src/13d-control-flow.md docs/book/src/13k-isf-feature-support-matrix.md`
- "where is the clean hook for ISF loop early-exit?" -> [loop-early-exit-target-hook](docs/knowledge/loop-early-exit-target-hook.md) · 2026-06-03 · reverify: `grep -n "loop_exit_target" perl/FSM/Scheduler/ISF/LoweringIR.pm`
- "where is the verilator-simulable vs formal-only (ifndef SYNTHESIS / ifdef FORMAL) split decided?" -> [isf-property-grammar-location](docs/knowledge/isf-property-grammar-location.md) · 2026-06-04 · reverify: `grep -n "sub parse_check_property" perl/FSM/Adapter/FSMGenFull/Parser.pm`
- "which book chapter covers ISF temporal properties, trigger anchors, monitors?" -> [isf-verification-book-map](docs/knowledge/isf-verification-book-map.md) · 2026-06-04 · reverify: `grep -rln "assert\|monitor\|=>\|sampled-value" docs/book/src/13d-control-flow.md docs/book/src/13k-isf-feature-support-matrix.md`
- "which mdBook chapters do I update when I add an ISF verification feature?" -> [isf-verification-book-map](docs/knowledge/isf-verification-book-map.md) · 2026-06-04 · reverify: `grep -rln "assert\|monitor\|=>\|sampled-value" docs/book/src/13d-control-flow.md docs/book/src/13k-isf-feature-support-matrix.md`
- "which module parses ISF / lowers ISF / emits the schedule report?" -> [isf-lowering-pipeline](docs/knowledge/isf-lowering-pipeline.md) · 2026-06-03 · reverify: `grep -rln "package FSM::Scheduler::ISF" perl/FSM/Scheduler/ISF*`
- "why did prove exit with code 137?" -> [full-test-suite-invocation](docs/knowledge/full-test-suite-invocation.md) · 2026-06-03 · reverify: `prove -j4 -Iperl t/`
- "why doesn't (at NAME) lower to current_state == STATE?" -> [isf-fsm-verification-boundary](docs/knowledge/isf-fsm-verification-boundary.md) · 2026-06-03 · reverify: `grep -n "_active" perl/FSM/Scheduler/ISF/LoweringIR.pm | head`

## Facts (by id)

### aggregate-parameter-comparison
_Semantic parameter and generic aggregate comparison support_

- **answers:** do aggregate parameters support equality or inequality? | can I compare aggregate +params with == or !=? | does .rtlif support aggregate generic comparison defaults? | how do aggregate comparison parameters lower to HDL?
- **date:** 2026-06-05 · **status:** current
- **evidence:** `docs/book/src/04-symbols-types-and-imports.md; docs/book/src/06-composition-advanced.md; perl/FSM/ParameterValueSupport.pm; t/30-language-contract-symbol-definitions.t; t/88-rtlif-typed-port-contract.t; t/91-composition-multi-rtl-children.t; t/292-composition-generated-child-parameter-overrides.t`
- **reverify:** `prove -Iperl t/30-language-contract-symbol-definitions.t t/51-language-contract-symbol-definition-boundary.t t/88-rtlif-typed-port-contract.t t/91-composition-multi-rtl-children.t t/292-composition-generated-child-parameter-overrides.t`
- **source:** [`docs/knowledge/aggregate-parameter-comparison.md`](docs/knowledge/aggregate-parameter-comparison.md)

### full-test-suite-invocation
_How to run the full Perl test suite (and why -j6 can get OOM-killed)_

- **answers:** how do I run the full test suite? | what is the command to run all the Perl tests? | why did prove exit with code 137? | the test suite got killed / SIGKILL during prove | how long does the full suite take?
- **date:** 2026-06-03 · **status:** current
- **evidence:** `t/ (~1400+ .t files); .github/workflows/regression.yml; bin/ci-regression`
- **reverify:** `prove -j4 -Iperl t/`
- **source:** [`docs/knowledge/full-test-suite-invocation.md`](docs/knowledge/full-test-suite-invocation.md)

### isf-bounded-window-min
_ISF bounded-window property supports a lower bound — (within B MIN MAX) -> ##[MIN:MAX]_

- **answers:** how do I express a min>1 bounded window / lower bound in an ISF assertion? | how do I say 'ack between 2 and 5 cycles after req' in ISF? | does ISF (within …) support a lower bound / a range / F[min,max]? | how does (within B MIN MAX) lower / what does ##[MIN:MAX] come from?
- **date:** 2026-06-04 · **status:** current
- **evidence:** `docs/book/src/13d-control-flow.md (Delayed consequents); t/1418-isf-property-window-range.t; docs/tasks/ISF-PROPERTY-WINDOW-RANGE.md`
- **reverify:** `prove -Iperl t/1418-isf-property-window-range.t`
- **source:** [`docs/knowledge/isf-bounded-window-min.md`](docs/knowledge/isf-bounded-window-min.md)

### isf-fsm-verification-boundary
_ISF-originated verification references signals, never the FSM state variable_

- **answers:** can ISF assertions reference current_state or state_active? | why doesn't (at NAME) lower to current_state == STATE? | how do I anchor a position in ISF verification without touching the state variable? | what is the ISF/FSM separation rule for verification? | Unsupported expression operator <point>_active
- **date:** 2026-06-03 · **status:** current
- **evidence:** `docs/decisions/0009; docs/decisions/0010; perl/FSM/Scheduler/ISF/LoweringIR.pm (_resolve_at_references generates a driven *_active signal)`
- **reverify:** `grep -n "_active" perl/FSM/Scheduler/ISF/LoweringIR.pm | head`
- **source:** [`docs/knowledge/isf-fsm-verification-boundary.md`](docs/knowledge/isf-fsm-verification-boundary.md)

### isf-lowering-pipeline
_How an ISF actor becomes SystemVerilog — the lowering pipeline stages and where each lives_

- **answers:** how does ISF get compiled to SystemVerilog? | where does ISF lowering happen? | what is the ISF to FSM to HDL pipeline? | which module parses ISF / lowers ISF / emits the schedule report? | where is the .fsm text produced from an ISF actor? | how does report() / the JSON schedule report get built?
- **date:** 2026-06-03 · **status:** current
- **evidence:** `perl/FSM/Adapter/ISF.pm; perl/FSM/Scheduler/ISF.pm; perl/FSM/Scheduler/ISF/LoweringIR.pm; perl/FSM/Scheduler/ISF/Emitter/JSON.pm; perl/FSM/Backend/GeneratedModuleEmitter.pm; docs/book/src/13-intent-scheduling.md`
- **reverify:** `grep -rln "package FSM::Scheduler::ISF" perl/FSM/Scheduler/ISF*`
- **source:** [`docs/knowledge/isf-lowering-pipeline.md`](docs/knowledge/isf-lowering-pipeline.md)

### isf-property-grammar-location
_Where the ISF verification property grammar lives (parse + render to SVA)_

- **answers:** where is the ISF assert/assume/cover property grammar? | how do I add a property combinator or operator to ISF checks? | where does (=> A B) / next / within / after / sampled-value get parsed and rendered to SVA? | does ISF validate the assert condition or pass it through? | where is the verilator-simulable vs formal-only (ifndef SYNTHESIS / ifdef FORMAL) split decided?
- **date:** 2026-06-04 · **status:** current
- **evidence:** `perl/FSM/Adapter/FSMGenFull/Parser.pm (parse_check_property); perl/FSM/Pipeline/GeneratedModuleInfoBuilder.pm (_render_check_condition_sv, _property_is_formal_only); perl/FSM/Adapter/FSMGenFull/SignalAnalyzer.pm (_analyze_check_condition_references)`
- **reverify:** `grep -n "sub parse_check_property" perl/FSM/Adapter/FSMGenFull/Parser.pm`
- **source:** [`docs/knowledge/isf-property-grammar-location.md`](docs/knowledge/isf-property-grammar-location.md)

### isf-sampled-value-predicates
_ISF verification properties support the SV sampled-value functions (stable/changed/rose/fell)_

- **answers:** how do I check a signal is stable or unchanged in an ISF assertion? | does ISF support $stable / $rose / $fell / $changed? | how do I assert on a rising or falling edge in ISF? | how do I express 'data stable while valid' in ISF? | how do I write a stability or edge property in an assert/assume/cover?
- **date:** 2026-06-04 · **status:** current
- **evidence:** `docs/book/src/13d-control-flow.md (Sampled-value predicates subsection); t/1417-isf-property-sampled-value.t; docs/tasks/ISF-PROPERTY-SAMPLED-VALUE.md`
- **reverify:** `prove -Iperl t/1417-isf-property-sampled-value.t`
- **source:** [`docs/knowledge/isf-sampled-value-predicates.md`](docs/knowledge/isf-sampled-value-predicates.md)

### isf-schedule-report-additive-keys
_The ISF schedule report allows additive new top-level keys without a schema_version bump_

- **answers:** can I add a new key to the ISF schedule report? | does adding a schedule-report key need a schema_version bump? | is the ISF schedule report schema frozen or can it grow? | how were transaction_loops / loop_early_exits added without bumping the version? | what does schema_version: 1 / evolves_with_isf_implementation mean for the report?
- **date:** 2026-06-03 · **status:** current
- **evidence:** `perl/FSM/Support/ISFPublicInterfaceContract.pm (schedule_report_top_level_keys + the *_full_schema_stable / evolves_with_isf_implementation flags); docs/ISF_SPEC.md schedule-report section`
- **reverify:** `prove -Iperl t/1116-isf-public-schedule-report-key-family-audit.t t/1227-isf-schedule-report-freeze-boundary.t`
- **source:** [`docs/knowledge/isf-schedule-report-additive-keys.md`](docs/knowledge/isf-schedule-report-additive-keys.md)

### isf-verification-book-map
_Where the ISF verification/property surface is documented in the book_

- **answers:** where is the ISF verification / assert / assume / cover surface documented? | which book chapter covers ISF temporal properties, trigger anchors, monitors? | where do I document a new ISF property construct / did the book get synced? | which mdBook chapters do I update when I add an ISF verification feature?
- **date:** 2026-06-04 · **status:** current
- **evidence:** `docs/book/src/13d-control-flow.md; docs/book/src/13k-isf-feature-support-matrix.md; t/1376-isf-book-example-lowering-audit.t; t/1305-isf-book-feature-matrix-audit.t`
- **reverify:** `grep -rln "assert\|monitor\|=>\|sampled-value" docs/book/src/13d-control-flow.md docs/book/src/13k-isf-feature-support-matrix.md`
- **source:** [`docs/knowledge/isf-verification-book-map.md`](docs/knowledge/isf-verification-book-map.md)

### loop-early-exit-target-hook
_Mid-loop exit/continue targets come from loop_exit_target computed in _link_states_

- **answers:** where does (exit-when) / (continue-when) jump to? | how is the loop exit target for a mid-loop early exit computed? | what is loop_exit_target in the ISF lowering? | how do exit-when and continue-when differ in their target? | where is the clean hook for ISF loop early-exit?
- **date:** 2026-06-03 · **status:** current
- **evidence:** `perl/FSM/Scheduler/ISF/LoweringIR.pm (_link_states per-loop pass stamps loop_exit_target; _link_loop_state wires the edges); docs/tasks/ISF-LOOP-EARLY-EXIT.md`
- **reverify:** `grep -n "loop_exit_target" perl/FSM/Scheduler/ISF/LoweringIR.pm`
- **source:** [`docs/knowledge/loop-early-exit-target-hook.md`](docs/knowledge/loop-early-exit-target-hook.md)
