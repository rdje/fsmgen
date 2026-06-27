---
id: ial2-apb-multi-register-decode-readiness-audit
title: APB multi-register decode needs public contract selection first
answers:
  - "is APB multi-register decode ready to implement?"
  - "what does IAL2-FEATURE-COMPLETENESS-FRONTIER.579 select?"
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.580?"
  - "why does APB multi-register decode need a contract first?"
  - "does .579 change APB behavior?"
date: 2026-06-27
status: current
tags: [ial2, apb, completer, composition, multi-register, contract, task-tree]
evidence: docs/IAL2_APB_MULTI_REGISTER_DECODE_READINESS_AUDIT.md; docs/IAL2_POST_APB_STATUS_FIELD_NEXT_SLICE_SELECTION.md; docs/IAL2_APB_PPIF_COMPLETER_BEHAVIOR.md; docs/IAL2_APB_PPIF_COMPOSITION_BEHAVIOR.md; ppif/apb_completer.ppif; ppif/apb_composition_status.ppif; fsm/apb_completer.fsm; perl/FSM/Adapter/IAL2/PPIF.pm; perl/FSM/IAL2/ProtocolIntent/ApbCompleter.pm; perl/FSM/IAL2/ProtocolIntent/ApbComposition.pm; t/1471-ial2-apb-completer.t; t/1472-ial2-apb-composition.t; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; MEMORY.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: ./bin/fsmgen --quiet --emit-schedule-json ppif/apb_completer.ppif && ./bin/fsmgen --quiet --emit-schedule-json ppif/apb_composition_status.ppif && perl -Iperl -MFSM::Adapter::IAL2::PPIF -0777 -ne 's/\(register reg0\n        \(address 0 width 32\)\n        \(data reg_data_q width 32 reset 0\)\)/$&\n      (register reg1\n        (address 4 width 32)\n        (data reg1_data_q width 32 reset 0))/ or die "substitution failed\n"; my $ok = eval { FSM::Adapter::IAL2::PPIF->new()->parse_source($_, "multi-register-probe.ppif"); 1 }; die "unexpected success\n" if $ok; die $@ unless $@ =~ /supports exactly one \(register/; print "multi-register probe rejected with selected diagnostic\n";' ppif/apb_completer.ppif
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.579` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.580`, public APB multi-register completer
decode contract selection.

The audit found that the PPIF parser already scans repeated `(register ...)`
clauses and parses each register clause, but it still deliberately rejects
anything except exactly one register. The generator, report schema, focused
tests, public samples, and lower-layer fixture are also singular: one
address-0 register named `reg0`, one storage signal `reg_data_q`, singular
`bindings.storage.register`, and singular `transfer.register`.

Direct implementation is therefore not the next safe owner. `.580` must select
the public source syntax, deterministic register ordering, address uniqueness
and diagnostics, report schema migration, generated storage naming, sample and
support-accounting scope, and deferred boundaries before any parser or
generator behavior changes.

`.579` changes no source syntax, parser acceptance, diagnostics, generator
logic, samples, support-accounting, validation behavior, generated artifacts,
JSON schemas, HDL/runtime behavior, direct backend lowering,
verification-output generation, backend-language variants, AXI behavior, APB
behavior, or VHDL behavior.
