---
id: isf-schedule-report-additive-keys
title: The ISF schedule report allows additive new top-level keys without a schema_version bump
answers:
  - "can I add a new key to the ISF schedule report?"
  - "does adding a schedule-report key need a schema_version bump?"
  - "is the ISF schedule report schema frozen or can it grow?"
  - "how were transaction_loops / loop_early_exits added without bumping the version?"
  - "what does schema_version: 1 / evolves_with_isf_implementation mean for the report?"
date: 2026-06-03
status: current
tags: [isf, schedule-report, schema, public-interface]
evidence: perl/FSM/Support/ISFPublicInterfaceContract.pm (schedule_report_top_level_keys + the *_full_schema_stable / evolves_with_isf_implementation flags); docs/ISF_SPEC.md schedule-report section
reverify: prove -Iperl t/1116-isf-public-schedule-report-key-family-audit.t t/1227-isf-schedule-report-freeze-boundary.t
---

The schedule report (`FSM::Scheduler::ISF->report`) is declared **both**
`schedule_report_full_schema_stable` **and** `evolves_with_isf_implementation`.
The combination means **adding** a new top-level key is allowed and does **not**
bump `schema_version` (stays `1`) — only renaming/removing/retyping an existing
key is a breaking change. This is how `transaction_loops`, `transaction_stages`,
and `loop_early_exits` were added.

To add a key: emit it from `FSM::Scheduler::ISF::Emitter::JSON`, register it in
`ISFPublicInterfaceContract::schedule_report_top_level_keys()`, mirror it in the
schema docs (downstream spec + public-interface contract + `ISF_SPEC.md`), and
the freeze-boundary audit (t/1227) + key-family audit (t/1116) keep it honest.

See [[isf-lowering-pipeline]] for where the report sits in the flow.
