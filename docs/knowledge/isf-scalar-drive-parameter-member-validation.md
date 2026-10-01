---
id: isf-scalar-drive-parameter-member-validation
title: Scalar drive parameters reject record members before public publication
answers:
  - "why did a scalar drive parameter masking a record accept member access?"
  - "how do public record-input refusals preserve their error contracts?"
  - "why did root classification reject the scalar parameter context map?"
date: 2026-10-01
status: current
tags: [isf, drive, record-ports, validation, public-reports]
evidence: docs/audits/record-output-source-admission-20261001/manifest.json; t/1989-isf-record-port-root-classification.t; perl/FSM/Support/ISFRecordPortScopes.pm; perl/FSM/Support/ISFRecordPortContexts.pm; t/1987-isf-record-port-declaration-scopes.t; t/1988-isf-record-port-context-gates.t; t/2014-isf-record-input-public-sources.t; t/2016-isf-record-input-public-refusals.t; docs/tasks/SEMANTIC-INTROSPECTION-MCP-FRONTIER.md
reverify: scripts/run_with_ram_guard.sh -- prove -Iperl t/1989-isf-record-port-root-classification.t t/1987-isf-record-port-declaration-scopes.t t/1988-isf-record-port-context-gates.t t/2014-isf-record-input-public-sources.t t/2016-isf-record-input-public-refusals.t
---

At predecessor 007b6425d162b804754da47c4964e295b73ebea9, an actor with a record
input `packet` could define `(drive (publish packet) (seen packet.payload.data))`
and call `(drive publish start)` using a one-bit scalar actual. Check, semantic
and schedule products all succeeded through native, API and newline routes.
The earlier wider actual failed check/semantic only for a width mismatch; that
was not proof of member validation.

`record_drive_scope` correctly masks the outer declaration with an unresolved
local binding. Its introduction is 5f843a3f59a1ab3fdaea9523c498afbbeb283388.
The value resolver deliberately delegates unknown types. Context validation
previously lost the separate grammar fact that drive parameters are scalar.
The context now keeps private scalar-parameter identities and refuses dotted
declaration paths, including members after scalar selectors, as `member_on_non_record` before unresolved type delegation.
Namespace classification still precedes that refusal. Bare values and slices
retain their width owner; raw value bindings keep their closed role/type shape,
with no fabricated width or borrowed outer record facts. Parser and module
admission activate this context gate for actors with record inputs; this slice
does not claim general scalar-only actor member validation.

T1988 independently rejects parameter member reads, writes and nested expression
uses, preserves enum/package namespaces, bare values, slices and complete actor
JSON. T2016 requires native/API/newline contextual refusals with exact source and
package preservation. Check/semantic keep complete failure reports with nullable
codes and no partial semantics/declaration snapshots. Schedule emits no JSON;
API/newline retain the generic message-only error rather than promising native
stderr context as structured error data. T2014 preserves accepted record sources
and strict carriers.

Re-derivation uses these actual producers and full typed transport comparisons.
Falsification is the pre-product public/context RED plus the independent member,
role, layout/type and successful namespace/shadow controls. Permanent tests,
source producers, this card and predecessor Git evidence provide durability.
Frontend closure is qualified under SEM .60.4.3.2.3.6.3.
Generated/domain/backend/native/consumer delivery retains separate owners. No HDL runtime or external consumer signoff is claimed.

SEM .60.4.3.3.4.3 finds the earlier T1989 exact projection-key assertion still
omitted scalar_parameter_roots. Git pickaxe traces producer and consumer to
ee81704239ca86545804eee4af357ffb3a838404; an exact baseline child reproduces
the stale map assertion independently of output admission. The maintained test
now expects the complete private map and independently checks empty outer masks
versus the explicit drive formal mask. Production scope/context helpers remain
unchanged. Saved baseline/current tests and full failure/repair receipts retain
this P3 repair. The first prove preload affected the harness only; its extra
current-source failure is preserved, and direct Perl child preloading supplies
the actual baseline proof. Mandatory contexts now include resolved output-only
actors under the separately qualified source-context and output-admission cards.
