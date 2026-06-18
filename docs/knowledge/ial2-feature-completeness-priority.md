---
id: ial2-feature-completeness-priority
title: IAL2 is the current feature-completeness priority on the SV-backed path
answers:
  - "what is the current feature completeness priority?"
  - "should IAL2 be prioritized before VHDL?"
  - "what task owns IAL2 feature completeness?"
  - "what is the next IAL2 PNT frontier?"
  - "can IAL2 feature completion require new IAL1 features?"
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.136 select?"
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.137 clean?"
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.138 select?"
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.139 select?"
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.140 ship?"
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.141 select?"
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.142 select?"
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.143 ship?"
  - "what is the next IAL2 frontier after multi-group runtime validation?"
  - "what stale AXI manager support residue remains after .135?"
  - "what is the next IAL2 frontier after support residue cleanup?"
  - "what is the next IAL2 frontier after support-report residue cleanup?"
  - "what is the next IAL2 frontier after write multi-group readiness?"
  - "what is the next IAL2 frontier after write multi-group behavior?"
  - "what is the next IAL2 frontier after read single-beat multi-group readiness?"
  - "what is the next IAL2 frontier after read single-beat multi-group behavior?"
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.144 select?"
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.145 select?"
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.146 ship?"
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.147 select?"
  - "what is the next IAL2 frontier after read single-beat multi-group read-data?"
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.148 select?"
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.149 ship?"
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.150 select?"
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.151 select?"
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.152 select?"
  - "what is the next IAL2 frontier after read single-beat depth-3 queue-head response-demux?"
  - "what is the next IAL2 frontier after read single-beat depth-3 queue-head read-data?"
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.156 ship?"
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.157 select?"
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.158 select?"
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.159 ship?"
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.160 select?"
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.161 select?"
  - "what is the next IAL2 frontier after read burst-last depth-3 queue-head response-demux?"
  - "what is the next IAL2 frontier after read burst-last depth-3 read-data readiness?"
  - "what is the next IAL2 frontier after read burst-last depth-3 queue-head read-data?"
  - "what is the next IAL2 frontier after read burst-last depth-3 burst-length readiness?"
  - "what is the next IAL2 frontier after read burst-last depth-3 burst-length behavior?"
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.163 select?"
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.164 select?"
  - "what is the next IAL2 frontier after depth-3 runtime-validation readiness?"
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.165 ship?"
  - "what is the next IAL2 frontier after depth-3 runtime-validation behavior?"
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.166 select?"
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.167 select?"
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.168 ship?"
  - "what is the next IAL2 frontier after depth-3 multi-beat output-bank behavior?"
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.169 select?"
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.170?"
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.170 select?"
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.171?"
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.172 select?"
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.173?"
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.173 select?"
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.174?"
  - "what follows write depth-3 queue-head response-demux?"
  - "why is support-detail expectation alignment next after depth-3 queue-head response-demux?"
date: 2026-06-18
status: current
tags: [ial2, ial1, ial0, systemverilog, roadmap, task-tree, feature-completeness]
evidence: docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; docs/AXI_IAL2_MANAGER_MULTIPLE_MIXED_DEPTH3_QUEUE_HEAD_RESPONSE_DEMUX_READINESS_AUDIT.md; docs/AXI_IAL2_MANAGER_POST_WRITE_DEPTH3_QUEUE_HEAD_RESPONSE_DEMUX_NEXT_SLICE_SELECTION.md; docs/AXI_IAL2_MANAGER_WRITE_DEPTH3_QUEUE_HEAD_RESPONSE_DEMUX_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_WRITE_DEPTH3_QUEUE_HEAD_RESPONSE_DEMUX_READINESS_AUDIT.md; docs/AXI_IAL2_MANAGER_POST_READ_BURST_LAST_DEPTH3_QUEUE_HEAD_MULTI_BEAT_NEXT_SLICE_SELECTION.md; docs/AXI_IAL2_MANAGER_READ_BURST_LAST_DEPTH3_QUEUE_HEAD_MULTI_BEAT_READ_DATA_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_READ_BURST_LAST_DEPTH3_QUEUE_HEAD_MULTI_BEAT_READINESS_AUDIT.md; docs/AXI_IAL2_MANAGER_POST_READ_BURST_LAST_DEPTH3_QUEUE_HEAD_RUNTIME_VALIDATION_NEXT_SLICE_SELECTION.md; docs/AXI_IAL2_MANAGER_READ_BURST_LAST_DEPTH3_QUEUE_HEAD_RUNTIME_VALIDATION_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_READ_BURST_LAST_DEPTH3_QUEUE_HEAD_RUNTIME_VALIDATION_READINESS_AUDIT.md; docs/AXI_IAL2_MANAGER_POST_READ_BURST_LAST_DEPTH3_QUEUE_HEAD_BURST_LENGTH_NEXT_SLICE_SELECTION.md; docs/AXI_IAL2_MANAGER_READ_BURST_LAST_DEPTH3_QUEUE_HEAD_BURST_LENGTH_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_READ_BURST_LAST_DEPTH3_QUEUE_HEAD_BURST_LENGTH_READINESS_AUDIT.md; docs/AXI_IAL2_MANAGER_POST_READ_BURST_LAST_DEPTH3_QUEUE_HEAD_READ_DATA_NEXT_SLICE_SELECTION.md; docs/AXI_IAL2_MANAGER_READ_BURST_LAST_DEPTH3_QUEUE_HEAD_READ_DATA_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_READ_BURST_LAST_DEPTH3_QUEUE_HEAD_READ_DATA_READINESS_AUDIT.md; docs/AXI_IAL2_MANAGER_POST_READ_BURST_LAST_DEPTH3_QUEUE_HEAD_RESPONSE_DEMUX_NEXT_SLICE_SELECTION.md; docs/AXI_IAL2_MANAGER_READ_BURST_LAST_DEPTH3_QUEUE_HEAD_RESPONSE_DEMUX_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_READ_BURST_LAST_DEPTH3_QUEUE_HEAD_RESPONSE_DEMUX_READINESS_AUDIT.md; docs/AXI_IAL2_MANAGER_POST_READ_SINGLE_BEAT_DEPTH3_QUEUE_HEAD_READ_DATA_NEXT_SLICE_SELECTION.md; docs/AXI_IAL2_MANAGER_READ_SINGLE_BEAT_DEPTH3_QUEUE_HEAD_READ_DATA_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_READ_SINGLE_BEAT_DEPTH3_QUEUE_HEAD_READ_DATA_READINESS_AUDIT.md; docs/AXI_IAL2_MANAGER_POST_READ_SINGLE_BEAT_DEPTH3_QUEUE_HEAD_RESPONSE_DEMUX_NEXT_SLICE_SELECTION.md; docs/AXI_IAL2_MANAGER_READ_SINGLE_BEAT_DEPTH3_QUEUE_HEAD_RESPONSE_DEMUX_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_DEEPER_QUEUE_HEAD_GROUPS_READINESS_AUDIT.md; docs/AXI_IAL2_MANAGER_POST_READ_SINGLE_BEAT_MULTI_GROUP_QUEUE_HEAD_READ_DATA_NEXT_SLICE_SELECTION.md; docs/AXI_IAL2_MANAGER_READ_SINGLE_BEAT_MULTI_GROUP_QUEUE_HEAD_READ_DATA_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_READ_SINGLE_BEAT_MULTI_GROUP_QUEUE_HEAD_READ_DATA_READINESS_AUDIT.md; docs/AXI_IAL2_MANAGER_READ_SINGLE_BEAT_MULTI_GROUP_QUEUE_HEAD_RESPONSE_DEMUX_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_READ_SINGLE_BEAT_MULTI_GROUP_QUEUE_HEAD_RESPONSE_DEMUX_READINESS_AUDIT.md; docs/AXI_IAL2_MANAGER_POST_WRITE_MULTI_GROUP_QUEUE_HEAD_RESPONSE_DEMUX_NEXT_SLICE_SELECTION.md; docs/AXI_IAL2_MANAGER_WRITE_MULTI_GROUP_QUEUE_HEAD_RESPONSE_DEMUX_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_WRITE_MULTI_GROUP_QUEUE_HEAD_RESPONSE_DEMUX_READINESS_AUDIT.md; docs/AXI_IAL2_MANAGER_POST_SUPPORT_RESIDUE_CLEANUP_NEXT_SLICE_SELECTION.md; docs/AXI_IAL2_MANAGER_POST_MULTI_GROUP_QUEUE_HEAD_RUNTIME_VALIDATION_NEXT_SLICE_SELECTION.md; docs/AXI_IAL2_MANAGER_MULTI_GROUP_QUEUE_HEAD_RUNTIME_VALIDATION_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_MULTI_GROUP_QUEUE_HEAD_RUNTIME_VALIDATION_READINESS_AUDIT.md; docs/AXI_IAL2_MANAGER_POST_MULTI_GROUP_QUEUE_HEAD_BURST_LENGTH_NEXT_SLICE_SELECTION.md; docs/AXI_IAL2_MANAGER_MULTI_GROUP_QUEUE_HEAD_BURST_LENGTH_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_POST_MULTI_GROUP_QUEUE_HEAD_LAST_BEAT_READ_DATA_NEXT_SLICE_SELECTION.md; docs/AXI_IAL2_MANAGER_MULTI_GROUP_QUEUE_HEAD_LAST_BEAT_READ_DATA_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_MULTI_GROUP_QUEUE_HEAD_LAST_BEAT_READ_DATA_READINESS_AUDIT.md; docs/AXI_IAL2_MANAGER_POST_MULTI_GROUP_QUEUE_HEAD_READ_DATA_NEXT_SLICE_SELECTION.md; docs/AXI_IAL2_MANAGER_MULTI_GROUP_QUEUE_HEAD_READ_DATA_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_MULTI_GROUP_QUEUE_HEAD_READ_DATA_READINESS_AUDIT.md; docs/AXI_IAL2_MANAGER_POST_MULTI_GROUP_QUEUE_HEAD_DEMUX_NEXT_SLICE_SELECTION.md; docs/AXI_IAL2_MANAGER_MULTI_GROUP_QUEUE_HEAD_RESPONSE_DEMUX_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_MULTI_GROUP_QUEUE_HEAD_RESPONSE_DEMUX_READINESS_AUDIT.md; docs/AXI_IAL2_MANAGER_POST_QUEUE_HEAD_MULTI_BEAT_NEXT_SLICE_SELECTION.md; docs/AXI_IAL2_MANAGER_QUEUE_HEAD_MULTI_BEAT_READ_DATA_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_POST_QUEUE_HEAD_RUNTIME_VALIDATION_NEXT_SLICE_SELECTION.md; docs/AXI_IAL2_MANAGER_QUEUE_HEAD_RUNTIME_VALIDATION_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_MULTI_BEAT_READ_DATA_OUTPUT_BANK_BEHAVIOR_FIRST_SLICE.md; docs/AXI_IAL2_MANAGER_QUEUE_HEAD_BURST_LENGTH_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_BEAT_COUNT_RLAST_RUNTIME_VALIDATION_FIRST_SLICE.md; docs/AXI_IAL2_MANAGER_QUEUE_HEAD_LAST_BEAT_READ_DATA_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_ARLEN_CAPTURE_BEHAVIOR_FIRST_SLICE.md; docs/AXI_IAL2_MANAGER_BURST_READ_DATA_BEAT_COUNT_METADATA_FIRST_SLICE.md; docs/AXI_IAL2_MANAGER_QUEUE_HEAD_READ_DATA_BEHAVIOR_FIRST_SLICE.md; docs/AXI_IAL2_MANAGER_LAST_BEAT_READ_DATA_BEHAVIOR_FIRST_SLICE.md; docs/AXI_IAL2_MANAGER_READ_DATA_BEHAVIOR_FIRST_SLICE.md; docs/AXI_IAL2_MANAGER_WRITE_SAME_ID_QUEUE_HEAD_RESPONSE_DEMUX_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_SAME_ID_QUEUE_BEHAVIOR_FIRST_SLICE.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md; docs/tasks/R11-DIRECT-STRUCTURAL-VHDL-REROUTING.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.171|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.172|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.173|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.174|MULTIPLE_MIXED_DEPTH3_QUEUE_HEAD_RESPONSE_DEMUX_READINESS_AUDIT|multi_depth3_same_id_queue_head_response_demux|mixed_depth3_depth2_same_id_queue_head_response_demux|VHDL backend/reroute' docs/TASK_TREE.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/AXI_IAL2_MANAGER_MULTIPLE_MIXED_DEPTH3_QUEUE_HEAD_RESPONSE_DEMUX_READINESS_AUDIT.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md
---

The current feature-completeness priority is IAL2 on the
SystemVerilog-backed path.

`IAL2-FEATURE-COMPLETENESS-FRONTIER.108` shipped generated AXI same-ID write
queue-head behavior for one duplicate concrete write-ID group of two
transactions at computed depth 2 after `.106` shipped generated read
burst-last depth-2 queue state and queue-head demux for the public sample.
`IAL2-FEATURE-COMPLETENESS-FRONTIER.110` shipped generated AXI read
`single-beat` same-ID queue-head behavior for one duplicate concrete read-ID
group of two transactions at computed depth 2. `IAL2-FEATURE-COMPLETENESS-FRONTIER.111`
selected queue-head read-data readiness as `.112`, `.112` selected `.113`,
and `.113` shipped generated single-beat read-data capture for bounded read
single-beat concrete same-ID queue-head demux. `.114` selected `.115`, `.115`
shipped generated last-beat read-data capture for the bounded read burst-last
concrete same-ID queue-head demux shape, and `.116` selected `.117`,
generated raw-`ARLEN` burst-length capture for bounded queue-head last-beat
read-data. `.117` shipped that report-only raw-`ARLEN` capture behavior and
advanced the frontier to `IAL2-FEATURE-COMPLETENESS-FRONTIER.118`. `.118`
selected `IAL2-FEATURE-COMPLETENESS-FRONTIER.119`, generated queue-head
beat-count/`RLAST` runtime validation for the bounded queue-head last-beat
read-data shape. `.119` shipped that behavior and advanced the frontier to
`IAL2-FEATURE-COMPLETENESS-FRONTIER.120`, the next queue-head/read-data
expansion selector. `.120` selected
`IAL2-FEATURE-COMPLETENESS-FRONTIER.121`, generated multi-beat read-data
output-bank behavior for the bounded read burst-last concrete same-ID
queue-head demux shape. `.121` shipped that behavior for
`ppif/axi_manager_capacity_status_read_multi_beat_same_id_queue_head_read_data.ppif`.
Generated queue-head read-data capture now
supports the bounded read single-beat shape and the bounded read burst-last
last-beat shape, with completion-validity reports
`generated_queue_head_response_demux_completion_pulse` and
`generated_queue_head_response_demux_last_beat_completion_pulse`,
respectively. The bounded queue-head multi-beat path now reports
`per_beat_output_bank`, valid masks, length outputs, scalar `RRESP`
aggregation, `read_data.residue: []`, and `response_demux.residue: []`.
`.122` selected `.123`, readiness audit for multiple independent read
burst-last depth-2 concrete same-ID queue-head response-demux groups. `.123`
selected `.124`, generated read burst-last response-demux-only queue-head
behavior for two or more duplicate concrete read-ID groups, each exactly two
transactions at computed depth `2`. `.124` shipped that behavior for
`ppif/axi_manager_capacity_status_read_multi_group_same_id_queue_head_response_demux.ppif`.
`.125` selected `.126`, readiness audit for read-data coverage over multiple
generated read burst-last concrete same-ID queue-head groups. `.126` selected
`.127`, generated multi-group queue-head multi-beat read-data output-bank
behavior. `.127` shipped that behavior for
`ppif/axi_manager_capacity_status_read_multi_group_same_id_queue_head_read_data.ppif`.
`.128` selected `.129`, readiness audit for last-beat-only read-data over
multiple generated read burst-last concrete same-ID queue-head groups. `.129`
selected `.130`, generated multi-group queue-head last-beat read-data capture.
`.130` shipped that scalar no-`burst_length` behavior for
`ppif/axi_manager_capacity_status_read_multi_group_last_beat_same_id_queue_head_read_data.ppif`
and advanced the frontier to `IAL2-FEATURE-COMPLETENESS-FRONTIER.131`, the
next feature-completeness selector. `.131` selected
`IAL2-FEATURE-COMPLETENESS-FRONTIER.132`, generated report-only raw-`ARLEN`
burst-length capture for the multi-group queue-head scalar last-beat read-data
shape. `.132` shipped that behavior for
`ppif/axi_manager_capacity_status_read_multi_group_last_beat_same_id_queue_head_burst_length.ppif`
and advanced the frontier to `IAL2-FEATURE-COMPLETENESS-FRONTIER.133`, the
next feature-completeness selector. `.133` selected
`IAL2-FEATURE-COMPLETENESS-FRONTIER.134`, readiness audit for generated
runtime-validation multi-group queue-head scalar last-beat read-data. `.134`
selected `IAL2-FEATURE-COMPLETENESS-FRONTIER.135`, generated
runtime-validation multi-group queue-head scalar last-beat read-data, after
finding no new lower-layer prerequisite beyond the local queue-head read-data
coverage gate. `.135` shipped that runtime-validation sibling for
`ppif/axi_manager_capacity_status_read_multi_group_last_beat_same_id_queue_head_burst_length_runtime_assertion.ppif`
and advanced the frontier to `IAL2-FEATURE-COMPLETENESS-FRONTIER.136`, the
next feature-completeness selector. `.136` selected
`IAL2-FEATURE-COMPLETENESS-FRONTIER.137`, report/static residue cleanup,
because the live `.135` report supports runtime-validation multi-group
queue-head scalar last-beat read-data while the AXI ID/order support-detail
string and focused PPIF/parser assertion still preserve stale unsupported
wording for that exact behavior. `.137` cleaned that report/static residue:
the support detail now describes the shipped runtime-validation multi-group
scalar shape as supported, focused parser expectations reject the retired
unsupported wording, and `.135`, `.132`, `.130`, `.127`, `.124`, and `.119`
live reports remain preserved. `.138` selected `.139`, readiness audit for
generated write-family multi-group queue-head response-demux, because the
one-group write queue-head sample is generated, read burst-last multi-group
queue-head behavior is generated, and a temporary two-group write probe
reported two duplicate concrete write-ID groups while still remaining
metadata-only with `generated_same_id_queue_head_demux` residue. `.139`
selected `IAL2-FEATURE-COMPLETENESS-FRONTIER.140`, generated write-family
multi-group queue-head response-demux, after finding no new parser,
support-accounting, generated-artifact, lowerer, direct-backend, or VHDL
prerequisite. The local blocker is the narrow behavior-builder gate; once
behavior exists, the queue-state, transition, assertion, response-demux
state/rule, report, and residue helpers already iterate groups for write. The
`.140` implementation shipped generated write-family multi-group queue-head
response-demux for
`ppif/axi_manager_capacity_status_write_multi_group_same_id_queue_head_response_demux.ppif`.
The generated report lists `BID` `3` for `w0`/`w1` and `BID` `5` for
`w2`/`w3`, every generated group remains depth `2`, generated completion
signals cover `w0` through `w3`, and `generated_same_id_queue_head_demux`
residue is removed for the covered write family while the family-wide
admitted-request onehot boundary is preserved. `.141` selected
`IAL2-FEATURE-COMPLETENESS-FRONTIER.142`, readiness audit for generated read
single-beat multi-group queue-head response-demux, because a temporary
two-group single-beat read probe reports selected metadata with two duplicate
concrete read-ID groups but remains generated-false with
`generated_same_id_queue_head_demux` residue. `.142` selected
`IAL2-FEATURE-COMPLETENESS-FRONTIER.143`, generated read single-beat
multi-group queue-head response-demux, after finding no new parser,
support-accounting, generated-artifact, lowerer, direct-backend, or VHDL
prerequisite. The local blocker is the narrow behavior-builder gate; once
behavior exists, queue-head planning, storage, transition, assertion,
response-demux rule, report, and residue helpers already group-iterate for
read single-beat. `.143` shipped generated read single-beat multi-group
queue-head response-demux for
`ppif/axi_manager_capacity_status_read_single_beat_multi_group_same_id_queue_head_response_demux.ppif`.
The generated report lists `RID` `3` for `r0`/`r1` and `RID` `5` for
`r2`/`r3`, every generated group remains depth `2`, generated completion
signals cover `r0` through `r3`, no `RLAST` or `read_data` behavior is
introduced, and semantic JSON/check JSON match the support-accounting entry
for the sample. `.144` selected `.145`, readiness audit for generated
read-data over read single-beat multi-group queue-head response-demux. `.145`
selected `.146`, and `.146` shipped generated scalar single-beat `RDATA` and
`RRESP` capture over the two depth-2 read single-beat queue-head groups in
`ppif/axi_manager_capacity_status_read_single_beat_multi_group_same_id_queue_head_read_data.ppif`.
`.147` then selected `.148`, readiness audit for generated concrete same-ID
queue-head groups deeper than two slots. `.148` selected `.149`, generated
read single-beat depth-3 queue-head response-demux through generalized shared
queue-state helpers. `.149` shipped that behavior for
`ppif/axi_manager_capacity_status_read_single_beat_depth3_same_id_queue_head_response_demux.ppif`:
`r0`, `r1`, and `r2` share concrete `RID` `3`, generated queue depth is `3`,
queue storage spans `slot0` through `slot2`, and completion pulses are
generated for the active head transaction without `RLAST` or `read_data`.
`.150` selected `IAL2-FEATURE-COMPLETENESS-FRONTIER.151`, support-detail
expectation alignment, because focused PPIF validation still expected older
support-detail wording while the production report now explicitly names
independent `depth-2` queue-head groups. `.151` aligned that validation
surface without changing public behavior and selected `.152`, readiness audit
for read-data over generated read single-beat depth-3 queue-head response-demux.
`.152` selected `IAL2-FEATURE-COMPLETENESS-FRONTIER.153`, generated scalar
read-data over one read single-beat depth-3 queue-head response-demux group.
`.153` shipped that bounded read-data sibling for
`ppif/axi_manager_capacity_status_read_single_beat_depth3_same_id_queue_head_read_data.ppif`:
`r0`, `r1`, and `r2` share concrete `RID` `3`, read queue depth is `3`,
scalar `RDATA`/`RRESP` capture is generated for all three transactions, and
strict check/semantic JSON support-account the sample. `.154` selected
`.155`, readiness audit for generated read burst-last depth-3 queue-head
response-demux. `.155` selected `.156`, generated read burst-last depth-3
queue-head response-demux, after a temporary burst-last depth-3 probe passed
schedule/check/semantic parsing and remained selected-not-generated only at
the local builder gate. `.156` shipped that bounded response-demux-only
sibling for
`ppif/axi_manager_capacity_status_read_burst_last_depth3_same_id_queue_head_response_demux.ppif`:
`r0`, `r1`, and `r2` share concrete `RID` `3`, read queue depth is `3`,
generated completion pulses are guarded by raw read completion, `RID`,
`RLAST`, and queue-head identity, and strict check/semantic JSON
support-account the sample. `.157` selected `.158`, readiness audit for
generated read-data over read burst-last depth-3 queue-head response-demux,
after a temporary last-beat read-data-over-`.156` probe failed closed at the
depth-2-only burst-last queue-head read-data coverage gate. `.158` selected
`.159`, direct bounded implementation of scalar last-beat read-data over the
generated read burst-last depth-3 queue-head response-demux, after finding no
lower-layer prerequisite beyond the local read-data coverage gate and support
surface updates. `.159` shipped that bounded scalar last-beat read-data
sibling for
`ppif/axi_manager_capacity_status_read_burst_last_depth3_same_id_queue_head_read_data.ppif`:
`r0`, `r1`, and `r2` share concrete `RID` `3`, read queue depth is `3`,
scalar last-beat `RDATA`/`RRESP` capture is generated for all three
transactions, and strict check/semantic JSON support-account the sample.
`.160` selected `IAL2-FEATURE-COMPLETENESS-FRONTIER.161`, readiness audit for
generated report-only raw-`ARLEN` burst-length capture over the generated read
burst-last depth-3 queue-head read-data shape. Write depth-3,
runtime-validation or multi-beat over read burst-last depth-3, multiple or
mixed depth-3 groups, same-family mixed auto-ID, group-local enqueue widening,
packed burst-vector outputs, alternate payload assembly, direct backend
lowering, and VHDL remain deferred.
`.161` selected `IAL2-FEATURE-COMPLETENESS-FRONTIER.162`, direct bounded
implementation of generated report-only raw-`ARLEN` burst-length capture over
exactly one generated read burst-last depth-3 queue-head read-data group,
after finding the temporary candidate fails only at the local queue-head
read-data coverage predicate and the raw-`ARLEN` artifact/report helpers are
already transaction-list driven.
`.162` shipped that support-accounted report-only raw-`ARLEN` depth-3
behavior for
`ppif/axi_manager_capacity_status_read_burst_last_depth3_same_id_queue_head_burst_length.ppif`.
`.163` selected `IAL2-FEATURE-COMPLETENESS-FRONTIER.164`, readiness audit for
generated runtime beat-count/`RLAST` validation over the `.162` shape, after
live probes showed `.162` still has `generated_beat_count_validation` residue
and a temporary depth-3 `runtime-assertion` candidate fails closed only at the
local queue-head coverage diagnostic.
`.164` selected `IAL2-FEATURE-COMPLETENESS-FRONTIER.165`, direct bounded
implementation of generated runtime beat-count/`RLAST` validation over the
same depth-3 queue-head raw-`ARLEN` shape, after finding no prerequisite
beyond the local admission gate.
`.165` shipped that support-accounted runtime-validation sibling for
`ppif/axi_manager_capacity_status_read_burst_last_depth3_same_id_queue_head_burst_length_runtime_assertion.ppif`:
`r0`, `r1`, and `r2` share concrete `RID` `3`, read queue depth is `3`, raw
`ARLEN` storage, expected-beat storage, read-beat counters,
matched-read-beat increment rules, and four beat-count/`RLAST` assertions per
transaction are generated. The report records
`beat_count_match_source: response_demux_matched_read_beat`, removes
`generated_beat_count_validation` from `read_data.residue`, and keeps
multi-beat reassembly/output/aggregation deferred. `.166` selected
`IAL2-FEATURE-COMPLETENESS-FRONTIER.167`, readiness audit for generated
multi-beat output-bank behavior over the same read burst-last depth-3
queue-head runtime-validation group. `.167` found no prerequisite beyond the
local multi-beat depth-3 admission gate and selected
`IAL2-FEATURE-COMPLETENESS-FRONTIER.168`, direct bounded implementation over
the same `r0`/`r1`/`r2` runtime-validation group. `.168` shipped that
support-accounted multi-beat read-data output-bank behavior for
`ppif/axi_manager_capacity_status_read_burst_last_depth3_same_id_queue_head_multi_beat_read_data.ppif`:
generation emits 16 `RDATA` and 16 `RRESP` lanes per transaction, 48 total
lane capture rules, valid masks, read-length outputs, scalar worst-observed
`RRESP` aggregates, raw `ARLEN` capture, expected-beat/read-beat storage, and
runtime beat-count/`RLAST` assertions. The report records
`output_shape: per_beat_output_bank` and empty `read_data` and
`response_demux` residue for the covered sample. `.171` now ships direct
bounded implementation of generated write-family depth-3 concrete same-ID
queue-head response-demux for one `w0`/`w1`/`w2` concrete `BID` `3` group.
`.172` selected `IAL2-FEATURE-COMPLETENESS-FRONTIER.173`, readiness audit for
generated multiple or mixed depth-3 concrete same-ID queue-head response-demux
groups, because one-group depth-3 and multi-group depth-2 response-demux
behavior is now generated across the covered read/write response-demux-only
shapes, while temporary multi-depth-3 and mixed depth-3/depth-2 write probes
strict-check with no diagnostics and remain selected-not-generated only with
`generated_same_id_queue_head_demux` residue.
`.173` selected `IAL2-FEATURE-COMPLETENESS-FRONTIER.174`, direct bounded
implementation of generated multiple or mixed depth-3 concrete same-ID
queue-head response-demux for response-demux-only read single-beat, read
burst-last, and write families. Temporary two-depth-3 and mixed
depth-3/depth-2 probes across all three family scopes strict-check with no
diagnostics and remain selected-not-generated only with
`generated_same_id_queue_head_demux` residue, while existing one-group depth-3
and multi-group depth-2 public samples remain generated and
support-accounted.

Completed `.47` shipped generated single-beat `RDATA`/`RRESP` capture
behavior. Completed `.48` selected `.49` because the current public read-data
surface is still single-beat and multi-beat read-data reassembly needs a
selected last-beat/completion contract before implementation.
Completed `.49` selected `.50` because no new IAL1/IAL0/SystemVerilog
substrate prerequisite is evident, but direct parser/report metadata or HDL
behavior would be premature without the public burst/`RLAST` contract.
Completed `.50` selected additive read `response-demux` syntax for
`response-scope burst-last`; it keeps transaction completion as the generated
last-beat pulse, publishes no per-transaction beat-valid output, uses `RLAST`
rather than `ARLEN`/beat-count metadata for this first boundary, and leaves
read-data reassembly deferred. Completed `.51` shipped parser/report metadata
and static validation for that contract while keeping generated `.isf`,
`.fsm`, and HDL behavior unchanged. Completed `.52` found no new
IAL1/IAL0/SystemVerilog prerequisite and selected direct generated behavior:
add the generated `RLAST` input, reuse generated `RID` matching, pulse
transaction completions only on matched last beats, and keep read-data
reassembly plus beat-count validation deferred. Completed `.53` shipped that
generated behavior and moved the frontier to a post-`RLAST` selector.
Completed `.54` found stale generated report prose that still calls
burst-last `RLAST` report-only and still says generated burst/last-beat
tracking remains outside the shell; it selected `.55` as the narrow
report/static-text alignment prerequisite before larger AXI feature work.
Completed `.55` aligned that report prose with shipped generated behavior and
advanced the frontier to `.56`, the next public read-data/burst owner
selector. Completed `.56` selected `.57`, public AXI burst read-data contract
selection, because direct behavior still needs an explicit public choice for
capture scope, output binding, beat-count/depth, `RRESP` aggregation,
interleaving policy, diagnostics, and report residue movement. Completed
`.57` selected explicit last-beat read-data capture as the first bounded
burst-side contract and advanced the frontier to `.58`, parser/report
metadata and static validation for that contract. Completed `.58` shipped
that parser/report metadata, added a strict support-accounted last-beat sample,
kept generated behavior false, and advanced the frontier to `.59`, generated
last-beat read-data capture readiness. Completed `.59` found no new
IAL1/IAL0/SystemVerilog prerequisite and selected `.60`, direct generated
last-beat `RDATA`/`RRESP` capture behavior. Completed `.60` shipped that
generated capture behavior, removed `generated_last_beat_read_data_capture`
from read-data residue, and advanced the frontier to `.61`, the next AXI
manager feature-completeness selector. Completed `.61` selected `.62`,
public AXI burst read-data beat-count/depth contract selection, because full
multi-beat reassembly, per-beat outputs, `RRESP` aggregation, missing/extra
beat validation, and per-ID reassembly all need an explicit
expected-count/depth contract first. Completed `.62` selected an additive
ARLEN-based `burst-length` contract and advanced the frontier to `.63`,
parser/report metadata and static validation for that contract. Completed
`.63` shipped that parser/report metadata, added a support-accounted
burst-length sample, kept generated artifacts unchanged, and advanced the
frontier to `.64`, the next exact-owner selector. Completed `.64` selected
`.65`, generated ARLEN burst-length capture readiness, because generated
capture is the next prerequisite before validation or reassembly but adds a
new HDL input/storage/request-event path that must be audited before behavior
changes. Completed `.65` found no new IAL1/IAL0/SystemVerilog substrate
prerequisite and selected `.66`, generated raw-ARLEN capture behavior.
Completed `.66` shipped generated raw-ARLEN capture with a width-8
`axi0_arlen` input, per-transaction raw-ARLEN storage, request-event guarded
capture rules, `.fsm`/SystemVerilog lowering, generated burst-length
input/storage/rule report fields, and no `generated_burst_length_capture`
residue. It selected `.67`, beat-count/RLAST validation readiness, before
expected-beat arithmetic, validation counters, payload storage/reassembly,
per-beat outputs, `RRESP` aggregation, direct backend lowering, or VHDL work.
Completed `.67` found the IAL1/IAL0/SystemVerilog substrate ready for future
generated validation after a public validation mode exists, but did not select
direct behavior because the current public syntax says `validation
report-only`. It selected `.68`, public beat-count/RLAST runtime-validation
contract selection. Completed `.68` selected `(validation
runtime-assertion)` / `runtime_assertion`, preserved `validation
report-only` / `report_only`, and selected `.69` as the behavior-bearing
implementation slice because the new runtime-validation spelling must not be
accepted as metadata-only behavior. Completed `.69` shipped that generated
beat-count/RLAST runtime-validation behavior and advanced the frontier to
`.70`, the next exact-owner selector. Completed `.70` selected `.71`, public
AXI multi-beat read-data reassembly/output contract selection, before parser,
generator, HDL, sample, support-accounting, check JSON, semantic JSON, or
validation behavior changes. Completed `.71` selected the per-beat output-bank
contract and advanced the frontier to `.72`, parser/report metadata and
static validation for that syntax. Completed `.72` shipped that parser/report
metadata, added the support-accounted
`ppif/axi_manager_capacity_status_read_data_multi_beat.ppif` sample, reports
per-transaction lane names, valid-mask widths, length-output widths, and
`multi_beat_reassembly_generated_behavior: false`, and advanced the frontier
to `.73`, generated multi-beat read-data reassembly/output readiness.
Completed `.73` found no lower-layer prerequisite for the first generated
output-bank behavior when it uses scalar generated lane outputs, public output
registers as beat storage, lane-specific guarded capture rules, constant
prefix valid-mask values, and the existing matched-read-beat plus
`!request_event` boundary. It advanced the frontier to `.74`, generated
multi-beat read-data output-bank behavior. Completed `.74` shipped generated
`RDATA`/`RRESP` inputs, per-transaction data/status lane outputs, valid-mask
outputs, length outputs, request-time output-bank clearing, and lane capture
rules. Schedule JSON now reports
`multi_beat_reassembly_generated_behavior: true` and read-data residue is
reduced to `rresp_aggregation`. It advanced the frontier to `.75`, the next
AXI manager feature-completeness selector. Completed `.75` selected `.76`,
public scalar `RRESP` aggregation contract selection, before parser/report
metadata or generated behavior changes. Completed `.76` selected additive
`(status-aggregation (policy worst-observed))` source syntax,
transaction-local `(status-aggregate-output NAME)` bindings, normalized
report spelling `worst_observed`, and `.77` as parser/report metadata plus
static validation before generated scalar behavior.
Completed `.77` shipped scalar `RRESP` aggregation parser/report metadata and
advanced to `.78`, generated scalar aggregation readiness. Completed `.78`
selected direct width-2 `worst_observed` behavior, and `.79` shipped scalar
aggregate outputs, request-time `2'd0` initialization, matched-beat max
updates, and empty `read_data.residue` for the public multi-beat sample.
Completed `.80` selected read-data interleaving/queue readiness. Completed
`.81` found the covered generated auto-ID multi-beat-by-RID output-bank
subset already has enough shipped behavior for read-data interleaving residue
movement. Completed `.82` removed broad `read_data_interleaving` residue from
`response_demux` and `same_id_ordering` for that covered subset. Completed
`.83` selected burst payload/output readiness. Completed `.84` selected
report/static `bursts` residue alignment because the per-beat output bank is
already the bounded burst payload/output shape for the covered subset.
Completed `.85` removed broad `bursts` residue from `response_demux` and
`same_id_ordering` for that covered subset and advanced the frontier to `.86`.
Completed `.86` selected AXI concrete-ID same-ID ordering readiness as `.87`
and kept the IAL2 factoring stance evidence-driven: common constructs should
be promoted only after compatible reuse is proven across multiple profiles.
Completed `.87` selected `.88`, conservative fail-closed static validation for
multiple concrete-ID transactions in the same response family sharing one
concrete ID value, before any per-ID queue, scoreboard, public same-ID policy,
or full same-ID ordering behavior. Completed `.88` shipped that fail-closed
static validation. Completed `.89` selected `.90`, AXI per-ID issue-order queue
readiness, because direct queue behavior remains gated by public same-ID reuse
policy, queue/scoreboard substrate, concrete response-demux prerequisites,
report/static residue refinement, and any smaller IAL1/IAL0/SystemVerilog
prerequisites. Completed `.90` found no smaller lower-layer prerequisite and
selected `.91`, public same-ID reuse policy contract selection, because the
public source still must define reject, queue, stall/block, or scoreboard
semantics before generated queue behavior. Completed `.91` selected optional
AXI-profile-local `(same-id-ordering (read|write (concrete-id-reuse reject)))`
syntax and advanced to `.92`, parser/report metadata plus static validation
for explicit reject policy. Completed `.92` shipped that parser/report/static
validation, preserved generated `.isf`/`.fsm`/SystemVerilog behavior for valid
sources, reported `generated_queue_behavior: false`, and advanced to `.93`,
the next AXI manager selector. Completed `.93` selected `.94`, AXI same-ID
issue-order queue policy contract selection, because accepted same-ID reuse
must first define public `issue-order-queue` syntax, family scope, queue depth
bounds, enqueue/dequeue semantics, queue-head response-demux expectations,
diagnostics, report vocabulary, validation gates, and rollback boundary.
Completed `.94` selected family-local `(concrete-id-reuse
issue-order-queue)` under the existing `same-id-ordering` clause, with queue
depth bounded by family `max-pending` and concrete transaction inventory. It
selected `.95`, AXI same-ID issue-order queue behavior readiness, because
current response-demux behavior is auto-ID-oriented and accepted same-ID reuse
requires queue-head transaction identity rather than ID-only matching.
Completed `.95` found generated queue-head behavior too broad for the next
slice and selected `.96`, metadata-first parser/report support for
`issue-order-queue`, with duplicated concrete same-ID reuse still fail-closed
until generated queue-head behavior ships. Completed `.96` shipped that
selected-not-generated parser/report metadata and support-accounted sample,
while advancing to `.97`, admitted per-transaction enqueue boundary
readiness before queue-state or queue-head response-demux behavior changes.
Completed `.97` selected admitted per-transaction request pulses as `.98`,
guarded by transaction request event, current capacity storage, family
`max-pending`, and same-cycle completion fan-in rather than generated
`can_accept`. Completed `.98` shipped those admitted request pulses while
keeping accepted same-ID reuse and generated queue behavior false. Completed
`.99` selected `.100`, AXI same-ID issue-order queue state and queue-head
demux readiness audit, before queue-state or queue-head response-demux
behavior changes. Completed `.100` found current response demux remains
auto-ID busy/selected-ID matching and selected `.101`, bounded same-ID
issue-order queue state representation selection, before duplicate same-ID
acceptance or generated queue behavior changes. Completed `.101` selected
`compact_onehot_transaction_slots` and advanced to `.102`, concrete same-ID
queue-head response-demux contract selection, because current response demux
is still auto-ID-lifecycle oriented. Completed `.102` reused the existing
`response-demux` family arms for concrete same-ID queue-head demux and
advanced to `.103`, metadata/static validation with generated behavior still
selected-not-generated. Completed `.103` shipped selected-not-generated
queue-head demux metadata/static validation and the public same-ID queue-head
PPIF sample, while keeping accepted same-ID reuse and generated queue behavior
false. Completed `.104` found no obvious new lower-layer substrate
prerequisite for the first bounded generated behavior slice, but direct broad
implementation is too large because queue state needs a queue-head-demux
dequeue event and queue-head demux needs queue-head transaction identity from
queue state. It advanced to `.105`, first generated AXI same-ID queue state
and queue-head behavior slice selection. Completed `.105` selected `.106`,
generated AXI same-ID read burst-last queue state and queue-head demux
behavior for one duplicate concrete-ID group, two transactions, and computed
depth 2.

Selected IAL2 work may include required IAL1 or IAL0/SV support, but only when
those prerequisites are explicit, task-tree owned, documented, and
regression-backed. VHDL backend/reroute work remains deferred until the
SV-backed IAL0/IAL1/IAL2 path is feature complete.
