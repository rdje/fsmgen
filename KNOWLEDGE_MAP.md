# Knowledge Map

> **AUTO-GENERATED — DO NOT EDIT.** Regenerate with `knowledge-map/scripts/gen_knowledge_map.sh`.
> Source of truth = YAML front-matter in: `docs/knowledge docs/decisions`. Edit the fact files, never this map.
> A fact is any `.md` whose front-matter has a non-empty `answers:` list.
> **5** facts · **26** question keys.

## Questions → fact

- "Unsupported expression operator <point>_active" -> [isf-fsm-verification-boundary](docs/knowledge/isf-fsm-verification-boundary.md) · 2026-06-03 · reverify: `grep -n "_active" perl/FSM/Scheduler/ISF/LoweringIR.pm | head`
- "can I add a new key to the ISF schedule report?" -> [isf-schedule-report-additive-keys](docs/knowledge/isf-schedule-report-additive-keys.md) · 2026-06-03 · reverify: `prove -Iperl t/1116-isf-public-schedule-report-key-family-audit.t t/1227-isf-schedule-report-freeze-boundary.t`
- "can ISF assertions reference current_state or state_active?" -> [isf-fsm-verification-boundary](docs/knowledge/isf-fsm-verification-boundary.md) · 2026-06-03 · reverify: `grep -n "_active" perl/FSM/Scheduler/ISF/LoweringIR.pm | head`
- "does adding a schedule-report key need a schema_version bump?" -> [isf-schedule-report-additive-keys](docs/knowledge/isf-schedule-report-additive-keys.md) · 2026-06-03 · reverify: `prove -Iperl t/1116-isf-public-schedule-report-key-family-audit.t t/1227-isf-schedule-report-freeze-boundary.t`
- "how do I anchor a position in ISF verification without touching the state variable?" -> [isf-fsm-verification-boundary](docs/knowledge/isf-fsm-verification-boundary.md) · 2026-06-03 · reverify: `grep -n "_active" perl/FSM/Scheduler/ISF/LoweringIR.pm | head`
- "how do I run the full test suite?" -> [full-test-suite-invocation](docs/knowledge/full-test-suite-invocation.md) · 2026-06-03 · reverify: `prove -j4 -Iperl t/`
- "how do exit-when and continue-when differ in their target?" -> [loop-early-exit-target-hook](docs/knowledge/loop-early-exit-target-hook.md) · 2026-06-03 · reverify: `grep -n "loop_exit_target" perl/FSM/Scheduler/ISF/LoweringIR.pm`
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
- "where does (exit-when) / (continue-when) jump to?" -> [loop-early-exit-target-hook](docs/knowledge/loop-early-exit-target-hook.md) · 2026-06-03 · reverify: `grep -n "loop_exit_target" perl/FSM/Scheduler/ISF/LoweringIR.pm`
- "where does ISF lowering happen?" -> [isf-lowering-pipeline](docs/knowledge/isf-lowering-pipeline.md) · 2026-06-03 · reverify: `grep -rln "package FSM::Scheduler::ISF" perl/FSM/Scheduler/ISF*`
- "where is the .fsm text produced from an ISF actor?" -> [isf-lowering-pipeline](docs/knowledge/isf-lowering-pipeline.md) · 2026-06-03 · reverify: `grep -rln "package FSM::Scheduler::ISF" perl/FSM/Scheduler/ISF*`
- "where is the clean hook for ISF loop early-exit?" -> [loop-early-exit-target-hook](docs/knowledge/loop-early-exit-target-hook.md) · 2026-06-03 · reverify: `grep -n "loop_exit_target" perl/FSM/Scheduler/ISF/LoweringIR.pm`
- "which module parses ISF / lowers ISF / emits the schedule report?" -> [isf-lowering-pipeline](docs/knowledge/isf-lowering-pipeline.md) · 2026-06-03 · reverify: `grep -rln "package FSM::Scheduler::ISF" perl/FSM/Scheduler/ISF*`
- "why did prove exit with code 137?" -> [full-test-suite-invocation](docs/knowledge/full-test-suite-invocation.md) · 2026-06-03 · reverify: `prove -j4 -Iperl t/`
- "why doesn't (at NAME) lower to current_state == STATE?" -> [isf-fsm-verification-boundary](docs/knowledge/isf-fsm-verification-boundary.md) · 2026-06-03 · reverify: `grep -n "_active" perl/FSM/Scheduler/ISF/LoweringIR.pm | head`

## Facts (by id)

### full-test-suite-invocation
_How to run the full Perl test suite (and why -j6 can get OOM-killed)_

- **answers:** how do I run the full test suite? | what is the command to run all the Perl tests? | why did prove exit with code 137? | the test suite got killed / SIGKILL during prove | how long does the full suite take?
- **date:** 2026-06-03 · **status:** current
- **evidence:** `t/ (~1400+ .t files); .github/workflows/regression.yml; bin/ci-regression`
- **reverify:** `prove -j4 -Iperl t/`
- **source:** [`docs/knowledge/full-test-suite-invocation.md`](docs/knowledge/full-test-suite-invocation.md)

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

### isf-schedule-report-additive-keys
_The ISF schedule report allows additive new top-level keys without a schema_version bump_

- **answers:** can I add a new key to the ISF schedule report? | does adding a schedule-report key need a schema_version bump? | is the ISF schedule report schema frozen or can it grow? | how were transaction_loops / loop_early_exits added without bumping the version? | what does schema_version: 1 / evolves_with_isf_implementation mean for the report?
- **date:** 2026-06-03 · **status:** current
- **evidence:** `perl/FSM/Support/ISFPublicInterfaceContract.pm (schedule_report_top_level_keys + the *_full_schema_stable / evolves_with_isf_implementation flags); docs/ISF_SPEC.md schedule-report section`
- **reverify:** `prove -Iperl t/1116-isf-public-schedule-report-key-family-audit.t t/1227-isf-schedule-report-freeze-boundary.t`
- **source:** [`docs/knowledge/isf-schedule-report-additive-keys.md`](docs/knowledge/isf-schedule-report-additive-keys.md)

### loop-early-exit-target-hook
_Mid-loop exit/continue targets come from loop_exit_target computed in _link_states_

- **answers:** where does (exit-when) / (continue-when) jump to? | how is the loop exit target for a mid-loop early exit computed? | what is loop_exit_target in the ISF lowering? | how do exit-when and continue-when differ in their target? | where is the clean hook for ISF loop early-exit?
- **date:** 2026-06-03 · **status:** current
- **evidence:** `perl/FSM/Scheduler/ISF/LoweringIR.pm (_link_states per-loop pass stamps loop_exit_target; _link_loop_state wires the edges); docs/tasks/ISF-LOOP-EARLY-EXIT.md`
- **reverify:** `grep -n "loop_exit_target" perl/FSM/Scheduler/ISF/LoweringIR.pm`
- **source:** [`docs/knowledge/loop-early-exit-target-hook.md`](docs/knowledge/loop-early-exit-target-hook.md)
