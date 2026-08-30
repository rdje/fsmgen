# OSVVM Runtime Execution Plan

The exact OSVVM runtime path separates structural planning from external tool
execution. Child `.17.3.7.1` first materializes the authored portable-VHDL
reference, gate, and qualification sources through the qualified OSVVM
wrapper. Child `.17.3.7.2` then binds those graphs to the exact provider,
tool, source order, commands, reports, and resource controls needed by the
qualified GHDL route. Neither step starts GHDL.

<!-- CLAIM-VERIFICATION:BEGIN vial-osvvm-runtime-execution-plan-v1 -->
- Claim: The exact OSVVM/GHDL execution-plan authority closes three in-memory plans over 61 provider-analysis inputs and commands, seven generated sources plus one checked probe, separate fixture/probe elaboration and run commands, and four supplementary reports; reference, gate, and qualification have the listed exact plan identities, while the existing 74,976-byte qualifier report remains a byte-exact executable oracle.
- Re-derive: Run prove -Iperl t/1677-vial-architecture-scale-osvvm-runtime-execution-plan.t and prove -Iperl t/1599-vial-vhdl-osvvm-ghdl-qualification.t; independently reconstruct all three plans and compare the live qualifier with its checked report.
- Falsify: Mutate a command or report, request a preflight-dominated level, add an invocation key, call a private qualifier seam directly, use a subclass invocant, or change any source/tool/oracle identity. Every control must fail before staging or tool execution.
- Durability: Retain the caller-sealed plan module, qualifier consumer, t1677 and t1599, task .17.3.7.2, this chapter, Knowledge Map card, bounded claim record, checked qualifier, doctrine watcher, and work-unit Git chain.
<!-- CLAIM-VERIFICATION:END vial-osvvm-runtime-execution-plan-v1 -->

## Closed authority

`ArchitectureScaleOSVVMRuntimeExecutionPlan` owns only the materialized
reference, gate, and qualification roles. Each evaluation binds canonical
materialization and workload identities to the pinned OSVVM commit, tree, and
manifest; the qualified GHDL archive, binary, and version; every provider and
generated source; generated settings; libraries; commands; reports; timeouts;
capture ceilings; and a repository-relative same-volume staging identity.
Evaluation is purely structural: it creates no stage and starts no process.

| Role | Plan identity | Generated/probe source identity |
| --- | --- | --- |
| reference | `osvvm-ghdl-execution-plan/3639c39639ca5dbbdc5a715dd919617137beebdec13c37ee28011628c6981483` | `source/d479aeca91f41ee74d2572d1324e771aa922911b37b0ae4389ed215eac57ec53` |
| gate | `osvvm-ghdl-execution-plan/3adc10d1d81888b4d6c920413411f3e554bceaab2e6ce8cb0f10efbbed3f075e` | `source/5eba85abfc7ea62f3a959bef724f8b11dc5bb94b42845b8a9d4c3c633ee13463` |
| qualification | `osvvm-ghdl-execution-plan/7e35cfc36d528327535648026d382455148cc55ca370d3e540f53b8a576f6307` | `source/d4450e0b195c095f1927891bf6ee8a0aebeffc3c102e0d0bb40850392a44aa69` |

Every plan contains 61 ordered provider analyses, one ordered analysis over
the seven emitted VHDL sources plus the checked provider probe, separate
fixture/probe elaboration and run commands, and four OSVVM supplementary
reports. The qualifier consumes that same private authority rather than
maintaining a competing command, source, or resource list. A live rerun still
matches the checked 74,976-byte report and qualification identity byte-for-
byte. Limit and over-limit cannot acquire a plan and fail before provider or
tool access.

## Reproduction and use

t1677 independently reconstructs and validates all three exact plans. Its
hostile controls cover command mutation, preflight admission, unknown input,
direct private-seam access, and subclass widening:

```bash
prove -Iperl \
  t/1677-vial-architecture-scale-osvvm-runtime-execution-plan.t
```

Internal orchestration can inspect a gate plan without creating its
content-addressed stage or starting GHDL:

```perl
use FSM::VIAL::ArchitectureScaleOSVVMRuntimeExecutionPlan;

my $plan =
    FSM::VIAL::ArchitectureScaleOSVVMRuntimeExecutionPlan->evaluate({
        repository_root => '.',
        level => 'gate_candidate_v1',
    });

die "unexpected execution"
    if $plan->{claims}{staging_created}
        || $plan->{claims}{external_tool_executed};
```

No shared-lifecycle admission, new GHDL execution, measurement sample, matrix
publication, support, performance, capacity, provider-generality,
mixed-language, or public-API claim follows. The next clean child,
`.17.3.7.3`, separately owns shared-lifecycle role admission and qualifier
refactoring.

See [HIAL/VIAL Verification Architecture](16d-hial-vial-verification-architecture.md)
for the parent architecture and [Portable VHDL Runtime Measurement](16dd-vial-portable-vhdl-runtime-measurement.md)
for the shared source and GHDL lifecycle foundation.
