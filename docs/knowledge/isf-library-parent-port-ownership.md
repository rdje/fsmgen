---
id: isf-library-parent-port-ownership
title: ISF library-owned outputs feed explicit parent readback inputs
answers:
  - "why did the FIFO library top leave the parent data_in port unconnected?"
  - "how can importing actor logic read a library-owned output?"
  - "how do nondefault-domain library clock and reset bindings work?"
date: 2026-09-27
status: current
tags: [isf, libraries, interfaces, ownership, fifo, domains, mcp]
evidence: perl/FSM/Scheduler/ISF/LibraryPortOwnership.pm; perl/FSM/Scheduler/ISF/Emitter/CompositionTop.pm; t/1238-isf-fifo-library-hdl-generation.t; t/1914-isf-library-parent-interfaces.t; t/1912-isf-multi-domain-generated-children.t; t/1915-isf-library-domain-system-bindings.t; perl/FSM/Adapter/ISF/Parser.pm; docs/ISF_LIBRARY_CATALOG.md
reverify: FSMGEN_DARWIN_VERILATOR_TEST_RUNTIME=1 scripts/run_with_ram_guard.sh prove -Iperl t/1238-isf-fifo-library-hdl-generation.t t/1914-isf-library-parent-interfaces.t t/1915-isf-library-domain-system-bindings.t
---

Explicit interface preservation kept all importing-actor inputs and outputs in
the parent FSM. CompositionTop still omitted parent connections for library
inputs and suppressed parent library-output routes. Strict C2 admission then
rejected the retained unconnected data_in port. Keeping a phantom parent output
writer also conflicted with the library's actual ownership.

The top now supplies library-bound inputs to both consumers. LibraryPortOwnership
keeps actor-facing ports unchanged for schedule/top publication while turning
library-owned outputs into explicit_interface_ports inputs on the parent FSM.
Each library output directly fans out to its public endpoint and parent readback.
Width and type aliases survive; no readback register or reset copy is added.
Parent data writers, generated completion views, reset/default declarations and
duplicate library drivers are refused rather than silently arbitrated.

The unchanged FIFO HDL regression and T1914 independently qualify queue data,
full/empty/hold behavior, pointer-wrap stimulus, parent sampling, typed aliases,
reset and selected-domain isolation, exact public pins, scheduled replay and
complete native/API/newline reports. The FIFO fixture resets outputs low and
sets empty on the first idle clock after release; its parent samples the prior
cycle's output through ordinary sequential rule semantics.

Library resolution precedes domain-annotation materialization. The parser now
selects the use's explicit/default domain directly for system binding validation
and inference; the actor's compatibility clock/reset describes only its default
domain. Explicit multidomain bindings must use the selected domain's declared
clock/reset. Inferred resets require equal name, kind and polarity; explicit
remapping preserves the reusable actor's policy. No reset is borrowed from a
sibling domain, and ordinary input pins cannot replace declared domain signals.
Legacy actors without clock-domains keep their published explicit binding rules.
An unused domain emits no empty +size section, so its generated FSM remains
strict-admissible; authored legacy empty sections are still rejected.

T1914 applies its FIFO scoreboard, strict replay, exact interfaces and report
parity to default/nondefault, inferred and renamed library pins. T1915 checks
reset kind/polarity and absence with independent HDL observations, rejects
wrong-domain bindings and incompatible inference, and preserves explicit policy
remapping. No implicit domain crossing is introduced.

Owner: SEMANTIC-INTROSPECTION-MCP-FRONTIER.47 and .48.
