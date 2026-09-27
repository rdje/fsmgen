---
id: isf-composed-domain-activation-handoffs
title: Composed domains retain explicit activation CDC handoffs
answers:
  - "why was core.remote_done unconnected when a domain also spawned a child?"
  - "can a composed domain retain activation crossing start done and ready routes?"
  - "how are private handoffs distinguished from explicit outer domain boundaries?"
date: 2026-09-27
status: current
tags: [isf, domains, composition, activation, cdc, handoffs, mcp]
evidence: perl/FSM/Scheduler/ISF/Emitter/CompositionTop.pm; perl/FSM/Scheduler/ISF.pm; t/1958-isf-composed-domain-activation-handoffs.t; t/1957-isf-formal-domain-reservation-integration.t
reverify: FSMGEN_DARWIN_VERILATOR_TEST_RUNTIME=1 scripts/run_with_ram_guard.sh prove -Iperl t/1958-isf-composed-domain-activation-handoffs.t t/1957-isf-formal-domain-reservation-integration.t
---

A generated child or library makes its owning domain use ordinary component
emission within the flat outer top. External activation start/done/ready ports
carry isf_handoff, so the component emitter formerly skipped them as private.
The outer emitter had already transferred their explicit CDC routes into its
sources/targets map and removed those routes from outer-only wiring. This
left the domain handshake unconnected even though public lowering succeeded.
A minimal public generated-child-plus-activation source failed strict admission
at core.remote_done; no formal rewrite was needed to reproduce the defect.

Component emission now retains a handoff when an explicit boundary entry exists
for its direction: sources for an input, targets for an output. Unmapped local
child handoffs remain internal. Existing endpoint remapping supplies the actual
CDC route and retains its multiple-driver checks; no public handshake pin,
register or control state is added.

T1958 checks exact routes and private top interfaces for a composed caller,
composed caller/callee and library-composed caller. All pass strict exported
replay and complete native/API/newline check, semantic and schedule reports.
Independent SystemVerilog and Verilog oracles stop the destination clock,
observe the local child, resume the crossing, and check reset, repeated
activation and exact public event counts without internal signal knowledge.
T1957 additionally qualifies the combined projected-domain reservation case
that exposed the defect. The complete ordinary scope/storage/completion/library
regression cohort passes; the owning task records its consumed results.

The existing child-await watchdog, plain local-call/controller and historical
process-containment issues remain separately owned; these observations do not
close them. See [domain source products](isf-formal-domain-source-products.md)
and [outer identities](isf-generated-domain-identities.md).
Owner: SEMANTIC-INTROSPECTION-MCP-FRONTIER.49.2.2.3.2.2.2.3.2.2.2.2.2.2.2.2.2.3.2.3.
