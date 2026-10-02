---
id: isf-first-when-activation-body
title: Entry when accepts inline samples and refuses other actions before publication
answers:
  - "why did a first when drop its action?"
  - "which actions can an entry when contain?"
  - "does wait zero make a following when a branch?"
  - "what does a failed schedule preview return?"
  - "is a first select operation supported?"
date: 2026-10-02
status: current
tags: [isf, activation, entry, when, branch, macros]
evidence: >-
  perl/FSM/Scheduler/ISF/LoweringIR.pm;
  t/2040-isf-first-when-activation-body.t;
  docs/isf-spec/02-interface-transactions.md;
  docs/audits/first-when-activation-body-20261002/scope.txt;
  docs/audits/first-when-activation-body-20261002/manifest.json;
  docs/audits/first-when-activation-body-20261002/verify.py;
  docs/tasks/SEMANTIC-INTROSPECTION-MCP-FRONTIER.md
reverify: >-
  scripts/run_with_ram_guard.sh -- prove -Iperl -It/lib
  t/2040-isf-first-when-activation-body.t
---

At baseline `43dcfae199ca7d93a88fe047f886fdcc6522c2ec`, first scheduled
`when` takes `_ir_when_activation`, which collects only inline samples. Actual
source/private/native/API/newline products admit other actions while omitting
them. The selector and sample-only collection originate at
`2ca15577c3cc07f38ba49a15efc8955529f39d8b`.

SEM `.60.4.3.3.5.2.1.3` adds a precise source-body gate at that selected entry
path. Only `(sample port as name)` survives there. Place other actions after
the guard, or use `(on PORT)` followed by a branching `when`. Declarations and
zero waits create no preceding state. Initialized locals and positive waits
do create states, so a subsequent `when` branches. Supported entry guards,
samples, labels, parameterized zero waits, formals/domains and later branches
retain complete products. Caller/source/named-producer identities remain intact.

Check/semantic refusals retain complete failure JSON with normal status 1.
Native failed schedule has normalized stderr and status 255; the API/newline
surface retains its existing bounded RPC error -32000. It publishes no success
object or invented schedule failure schema. Check/semantic provide the primary
source diagnostic. The empty-list/unused-parameter/unspecialized-call drafts
were invalid controls and are retained, rather than relabeled as this defect.

The first-operation `select` source also desugars into this entry selector and
loses its true-path assignment. Complete actual observations qualify that
separate P2 defect under `.2.1.5`, scheduled next before literal/read integration.
The gate now refuses that unsupported first placement; source-intent repair
remains required. Existing later macro examples retain explicit activation.

Full literal products, genuine pre-gate RED and unchanged supported products
provide distinct re-derivation/falsification legs. Saved sources/code/recipes,
raw transports, immutable prior evidence and sealed member identities provide
durability. No macro/output execution, writer routing, public record widening,
timer/duration completion or spent native replay is established here.
