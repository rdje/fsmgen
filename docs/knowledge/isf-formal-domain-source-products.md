---
id: isf-formal-domain-source-products
title: Formal preparation retains actual independent domain source products
answers:
  - "does formal preparation reserve external activation ready and request declarations?"
  - "what does domain_source_products retain?"
  - "why does monolithic preparation miss domain activation helpers?"
date: 2026-09-27
status: current
tags: [isf, formals, reservations, domains, activation, ownership]
evidence: perl/FSM/Scheduler/ISF/DomainSource.pm; perl/FSM/Scheduler/ISF/LoweringIR.pm; perl/FSM/Scheduler/ISF.pm; t/1955-isf-formal-domain-source-products.t; t/1387-isf-cross-domain-activation-handshake-lowering.t
reverify: scripts/run_with_ram_guard.sh prove -Iperl t/1955-isf-formal-domain-source-products.t t/1247-isf-clock-domain-partition.t t/1387-isf-cross-domain-activation-handshake-lowering.t
---

Monolithic source preparation does not inject the external activation contracts
used by independently emitted domains. Actual caller ready/request states and
ready ports, plus callee idle/ready/request declarations, were absent from that
inventory even when public activation-crossing lowering succeeded. Ordinary
event-crossing controls did not exhibit that omission.

DomainSource now owns the same detached source constructor consumed by scheduler
realization and formal preparation. It selects authored domain interfaces,
storage, transactions, rules and library uses, filters resource users and
priorities, and injects event endpoints and caller/callee activation contracts.
Existing scheduler helper symbols remain import aliases for current consumers;
no second constructor or synthetic executable parent is introduced.

prepare_formal_source retains domain_source_products keyed by logical domain.
Each entry has an actor_domain identity, a detached partition entry and complete
local preparation. The constructor clears clock_domains, so recursive preparation
terminates at the independent module scope. Local transaction order, generated
and reusable children, handoffs, completion products and activation rewrites come
from the same existing producers used for that actual source. Ordinary actors
retain an empty domain product map. These products remain private and do not
enable automatic formal rewriting or independent controllers.

T1955 observes actual source construction and build_module calls from public
lowering, compares complete domain sources/local preparation, and checks actual
declarations against local reservations. Activation/event/no-reset/case-domain,
generated storage/completion, library/empty-domain and portable formal-helper
alias controls pass strict exported composition checks. Preparation is tested
with build_module forbidden; source, monolithic products and sibling domains
remain detached. Unused crossings still fail canonical admission. The retained
activation probe has no missing declarations after repair, and its native
schedule is byte-identical. The complete partition/activation/shadow/wiring/child
regression cohort passes, including independent T1912 domain runtime and public
reports. The historical watchdog and local-call limits remain separately owned.

Outer module/file/flat-instance/wiring/CDC identities occupy separate scopes;
[outer namespace qualification](isf-generated-domain-identities.md) observes
unchanged local IR across their realization. Complete reservation integration
remains a separate gate. Related execution contract:
[isf-multi-domain-generated-children](isf-multi-domain-generated-children.md).
Owner: SEMANTIC-INTROSPECTION-MCP-FRONTIER.49.2.2.3.2.2.2.3.2.2.2.2.2.2.2.2.2.3.2.1.

T1957 joins raw prepared reservations with allocated private formal identities
against real projected domain lowering. Different-width same-spelled formals,
actor-storage shadows, transaction/domain/rule declaration permutations,
portable candidate conflicts and filtered domain resource users/priorities
retain complete tested declaration coverage. Generated reads and sole writes,
shared named completion and control-only activation crossings compose; potential
write products do not admit competing parent writers. No parent merge occurs
during preparation. This is domain integration qualification, not the future
global completeness contract or automatic production rewriting. Its combined
crossing case exposed an emitter defect repaired and independently qualified in
[composed domain handoffs](isf-composed-domain-activation-handoffs.md).
