# 0106 — Reset polarity is an explicit system carrier

- Date: 2026-09-24
- Status: accepted
- Type: source language and semantic contract
- Owner: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.32.1.3.2.1`

## Context

ISF admits synchronous/asynchronous resets of either polarity. The public FSM
carrier currently encodes only synchronous active-high `sreset` and
asynchronous active-low `areset`. ISF emission therefore loses synchronous
active-low and asynchronous active-high intent. In the event-crossing fixture,
the domain FSM and CDC primitive interpret the same reset net oppositely.
The baseline and exact owning repairs are retained in
`docs/audits/specforge-rule-admission-20260924/multiclock-strict-wiring.json`.

## Decision

Extend the canonical forms with one optional literal polarity:

```text
(sreset NAME [active_high|active_low])
(areset NAME [active_high|active_low])
```

Brackets denote optional syntax, not source tokens. Omission preserves the
existing keyword defaults and strict naming checks. With a modifier, the
keyword selects synchronous/asynchronous timing and the explicit polarity
selects the active level independently of the identifier spelling. This makes
authored intent authoritative without synthesizing combinational reset glue.
Only the two literal polarity tokens are admitted: no expressions, parameters,
nested forms or extra operands. The compatibility alias `asreset` gains no
extended form and remains rejected in strict mode.

Preserve the existing explicit/effective semantic contract field families.
`reset_kind` and `reset_active_level` carry the resolved policy; effective
contracts must not overwrite a parsed level with a keyword default. Advertise
the additive syntax through language-surface capabilities and retain complete
native/API/MCP report equality and independent reset-behavior checks.

## Consequences

Existing source keeps its meaning and diagnostics. Callers can represent every
kind/polarity combination through the public grammar. A later owned ISF slice
uses the modifier where the old keyword default cannot preserve intent; that
repair is not claimed by carrier selection alone. No runtime maturity, source
line mapping, reset-domain synchronization or combinational reset-tree feature
is implied by this extension.
