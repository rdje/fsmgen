# 0112 — ISF reset provenance is separate from hardware policy

- Date: 2026-09-30
- Type: ISF source and public report contract
- Status: accepted; provenance implemented under .60.3.3.1
- Owner: SEMANTIC-INTROSPECTION-MCP-FRONTIER.60.3.2

## Context

SPECFORGE must distinguish a reset stated by an input specification from a
compiler-selected implementation default. The supplied unstated-reset packet
is retained with current public products in
`docs/audits/specforge-unstated-reset-20260930/`. Legacy reset omission and an
explicit asynchronous active-low `rst_n` produce identical hardware and reports
apart from source paths. A clock-only named domain instead selects hardware
without reset or a guaranteed initial state. These are different choices.

`explicit_system_contract` describes the emitted FSM carrier. It cannot serve
as evidence that the ISF author wrote a reset clause. Changing defaults or
inventing startup initialization would change existing source semantics and
would not answer the provenance question.

## Decision

Retain declaration provenance before parser defaults. Add `reset_provenance`
to schedule JSON and optional `source.reset_provenance` to successful native
check and semantic JSON for directly parsed ISF inputs. The same values must
reach the public adapter and actual newline MCP responses. Existing reset
policy fields, source acceptance, scheduled FSM and HDL stay unchanged.

The value is an array in authored domain order. Each entry has exactly
`domain` and `origin`. A legacy actor has one entry with `domain: null`.
Named-domain actors use the declared domain names. The origin values are:

| Origin | Meaning |
| --- | --- |
| `explicit` | A reset clause occurs in this ISF actor/domain. |
| `legacy_default` | The legacy actor omits reset and selects the documented default. |
| `domain_absent` | The named domain omits reset and selects hardware without it. |

`explicit` proves clause presence only; flat-name polarity inference and omitted
timing/polarity operands still follow existing rules. This metadata does not
prove a fact about an upstream specification that FSMGen has never read.
SPECFORGE must preserve its own grounding evidence.

Unknown provenance in a caller-constructed actor must remain unknown: schedule
JSON uses null rather than guessing from an effective reset object. Direct FSM
and other source formats do not gain ISF provenance. Parsing/check failure does
not manufacture successful source provenance. Advertise the optional shared
source field and schedule field/entry/value families in their capability
contracts, with complete discovery and public-query tests.

For the downstream question, an omitted legacy reset is the existing form for
an unstated ISF reset **with the documented implementation default selected**.
The new metadata makes that selection visible. Clock-only domains are suitable
only when deliberately selecting hardware without reset. No existing form
defers reset kind/polarity to instantiation; this answer does not claim one.
If SPECFORGE requires a deferred hardware decision rather than a visible
default, it must retain that unresolved source fact before executable ISF
generation. The director clarified that this ticket is a question. A configurable reset
feature is outside its scope; the inferred follow-on `.61` is superseded.
Absence must not be silently implemented as reset-free hardware.

## Delivery and qualification

Implement provenance retention, detached projection and shared report fields
in one bounded slice; generated products must match the retained baseline after
removing only the added metadata and generated date banner. Cover explicit and
omitted legacy forms, defaulted clock, single and mixed named domains, source
permutation, caller-constructed actors without evidence, and malformed source.
Qualify parser/scheduler, native check/semantic/schedule, API/newline and
capability discovery. Since hardware must be unchanged, this metadata slice
does not require a new native simulator run or waive its existing admission.

The final downstream response must disposition every supplied question and
expected outcome, include a runnable omission example and exact field meaning,
and keep the initialization and VHDL limits explicit. This provenance change
does not depend on independent transaction controllers, writer admission, or
the unresolved historical native `setpgid` cause.
