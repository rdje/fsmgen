# VIAL/HIAL Transaction Type-Binding Mismatch Audit

Date: 2026-07-31

Owner: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.7.1`

Status: confirmed implementation blocker; semantic choice owned by blocked
`.7.2`

## Outcome

The checked AHB fixture cannot bind under the exact type-equivalence rule
selected by decision `0036`. Three of its six VIAL transaction fields have a
different semantic type or state domain from the authoritative HIAL bridge
field type:

| Field | VIALSemanticIR type | HIAL bridge type | Current rule |
| --- | --- | --- | --- |
| `address` | four-state unsigned `logic(32)` alias | four-state unsigned `logic(32)` | exact match |
| `transfer` | four-state `htrans_t` enum over `logic(2)` | four-state unsigned `logic(2)` | enum/logic mismatch |
| `write` | two-state `bool` | four-state unsigned `logic(1)` | state-domain/family mismatch |
| `size` | four-state unsigned `logic(3)` | four-state unsigned `logic(3)` | exact match |
| `data` | four-state unsigned `logic(32)` alias | four-state unsigned `logic(32)` | exact match |
| `wait_cycles` | two-state unsigned `u(4)` | four-state unsigned `logic(4)` | state-domain/family mismatch |

The fixture's sampled `HREADYOUT`, `HRESP`, `HRDATA`, and `reg_data_q` probe
do match: VIAL deliberately declares them as four-state logic. The blocker is
therefore confined to the authored transaction-to-hardware drive boundary,
not general endpoint/probe resolution.

No binder or ExecutionIR implementation was written. Silently weakening the
validator would violate the frozen contract and erase a semantically important
two-state/four-state distinction.

## Direct Evidence

The VIAL source declares:

```text
transfer     (type htrans_t)
write        bool
wait_cycles  (u 4)
```

The VIAL source contract defines `bool`, `u`, and `s` as two-state, `logic`
and `slogic` as four-state, and preserves enum identity. The SemanticIR dump
confirms the exact records: `transfer` is an enum whose base is four-state
logic width 2, `write` is two-state Boolean width 1, and `wait_cycles` is
two-state unsigned width 4.

The bridge producer constructs every HIAL scalar port through
`_ensure_logic_type`, which sets `state_domain => 'four_state'`, and each AHB
transaction field takes its authoritative type ID directly from its hardware
endpoint. A direct IAL2-via-generated/reparsed-IAL1 manifest build confirms
that all six bridge field types are four-state `logic_uN` records.

The execution contract currently says transaction fields must be
structurally equivalent, including state domain and enum member identity, and
explicitly rejects width-only coercion, two-/four-state collapse, or target-
language casts. Applying that rule honestly rejects the three fields above.

The prior `.5` bridge regression proved the VIAL unit/domain/endpoint/probe/
transaction bridge references and endpoint type/access facts. It checked the
transaction ID and field order, but did not compare each VIAL transaction
field type to its bridge field type. The `.5` claim that the AHB manifest
resolved every checked VIAL type was therefore too broad; this audit narrows
that historical claim without changing the shipped bridge data.

## Root Cause

The two independently valid type systems describe different sides of the
abstraction boundary:

- VIAL uses `bool`, unsigned arithmetic values, and enums to preserve authored
  verification meaning and rule out accidental X/Z arithmetic.
- HIAL exposes hardware ports as four-state logic so X/Z remains observable
  and backend-neutral.

Decision `0036` incorrectly required type identity across that boundary. It
did not select a representation relation for a VIAL semantic value that is
driven into a HIAL hardware carrier. The checked fixture makes that missing
relation unavoidable.

## Decision Required

Blocked `.7.2` must select one of two coherent rules before implementation:

1. **Exact identity.** Change the VIAL fixture/types or enrich the bridge type
   model until every field is identical. This preserves the current contract
   literally, but spelling `write` and `wait_cycles` as four-state logic and
   discarding the `transfer` enum would weaken VIAL's abstraction unless the
   bridge gains an equally expressive semantic overlay.
2. **Closed directional representation adapters.** Keep expressive VIAL types
   and permit only proof-carrying, lossless drive relations. A two-state scalar
   may inject into same-width/signed four-state logic with every bit known and
   no Z; an enum may inject through its exact declared base encoding when every
   member value fits and is preserved. The binding record names the relation
   and proof. No inverse four-state-to-two-state sample conversion, implicit
   expression coercion, width/sign change, truncation, extension, wrap, or
   backend cast is admitted.

The second rule is recommended. It preserves the user's abstraction: VIAL
authors write Boolean, numeric, and enum intent, while the compiler proves how
that value is represented on the HIAL hardware carrier. SV/UVM/VHDL remain
backend “assembly languages”; target representation does not leak into VIAL.
It also keeps X/Z handling strict because the relation is directional: a known
VIAL value can be driven into four-state hardware, but an unknown hardware
value cannot silently become a two-state VIAL value.

## Unblock Condition

The director selects the semantic rule. `.7.2` then synchronizes decision
`0036`, the source/bridge/execution contracts, the AHB oracle, mdBook examples,
and negative boundaries in one documentation commit. Only after that clean
commit may `.7.3` implement binding and ExecutionIR.

## Reverification

```bash
rg -n 'transfer \(type htrans_t\)|write bool|wait_cycles \(u 4\)' vial/ahb_subordinate_base_output_arbitration.vial
rg -n "state_domain => 'four_state'" perl/FSM/HIAL/VIALBridge/Builder.pm
rg -n 'type_id => \$endpoint->\{type_id\}' perl/FSM/HIAL/VIALBridge/Builder.pm
rg -n 'structurally equivalent|two-/four-state collapse|enum member order/value' docs/VIAL_EXECUTION_IR_V1_CONTRACT.md
prove -Iperl t/1550-vial-semantic-ir.t t/1551-hial-vial-bridge-manifest.t
```
