# 0037 — VIAL semantic types bind to HIAL carriers through directional proof relations

- Date: 2026-07-31
- Type: verification language and HIAL/VIAL binding architecture
- Status: accepted by `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.7.2`
- Preserves: `0018`, `0032`, `0033`, `0034`, `0035`, `0036`

## Context

Implementation audit `.7.1` proved that decision `0036`'s exact cross-boundary
type-identity wording cannot bind the checked AHB transaction. VIAL correctly
retains `htrans_t` as an enum, `write` as a two-state Boolean, and
`wait_cycles` as a two-state unsigned value. The HIAL bridge correctly retains
the corresponding hardware carriers as four-state logic. Address, size, data,
sampled public outputs, and the declared probe already agree.

The two type systems describe different semantic layers. VIAL types govern
authored verification operations, value validity, arithmetic, comparison, and
diagnostics. HIAL bridge types govern the observable hardware representation.
Forcing VIAL authors to spell every drive value as hardware logic would leak
backend representation upward and weaken the “SV+UVM/VHDL are backend
assembly languages” rule selected by decision `0034`.

Silently treating equal widths as compatible would be equally wrong. It could
collapse X/Z, reinterpret signedness, discard enum identity, or inherit a
target-language cast. The binder needs a closed semantic proof rather than
either type identity or implicit coercion.

## Decision

Select closed, proof-carrying, **directional representation relations** between
a VIAL semantic type and a HIAL hardware carrier type. The semantic type is
not replaced, widened, or reinterpreted. The relation exists only at a bound
drive/sample seam and is recorded in `VIALExecutionIR` and its sanitized plan.

Version 1 admits exactly three relation kinds:

1. `bit_domain_identity_v1` — scalar state domain, signedness, and width are
   equal. VIAL aliases and scalar family labels remain semantic metadata; the
   carrier has the same normalized bit domain. This relation may be used for
   drive or sample.
2. `known_value_injection_v1` — a two-state VIAL scalar drives a four-state
   HIAL logic carrier with equal signedness and width. Value bits are
   unchanged, every in-range carrier bit is known, and every Z bit is zero.
   This relation is drive-only.
3. `enum_encoding_injection_v1` — a VIAL enum drives a HIAL logic carrier
   through its exact declared base-bit encoding. Base width and signedness are
   equal; the base state-domain relation is identity or known-value injection;
   every member encoding is normalized, unique, representable, and preserved.
   This relation is drive-only.

Every relation record contains its stable ID, kind, direction, semantic and
carrier type IDs, both state domains, exact width/signedness, ordered enum
encoding (empty for non-enums), and closed proof IDs. The binder constructs
the record; callers and backends cannot assert a relation by name.

Sampling remains strict. A four-state carrier cannot bind to a two-state VIAL
sample, Boolean, integer, or enum merely because the observed bits happen to
be known in one run. Such a use requires a future explicit checked-decode or
unknown-policy semantic family. Inout bindings must prove both directions
independently.

No relation admits width change, truncation, extension, signedness change,
wrap, saturation, implicit enum decoding, invalid enum encodings, X/Z collapse,
aggregate flattening, expression-level coercion, target-language casts, or
backend-selected conversion policy. Failure to prove one of the closed kinds
is `VIAL_BIND_TYPE_ERROR` before plan construction.

The checked AHB transaction therefore binds as follows:

| Field | Relation |
| --- | --- |
| `address` | `bit_domain_identity_v1` |
| `transfer` | `enum_encoding_injection_v1` |
| `write` | `known_value_injection_v1` |
| `size` | `bit_domain_identity_v1` |
| `data` | `bit_domain_identity_v1` |
| `wait_cycles` | `known_value_injection_v1` |

The sampled `HREADYOUT`, `HRESP`, `HRDATA`, and `reg_data_q` bindings use
`bit_domain_identity_v1`. The compiler still rejects a probe without its
required backend adapter; representation proof does not satisfy a separate
access capability.

## Consequences

- VIAL authors retain Boolean, numeric, enum, and future domain-specific value
  intent rather than authoring hardware-carrier syntax.
- HIAL remains honest about four-state hardware observability and does not
  acquire VIAL-only arithmetic or enum meaning.
- Execution values remain typed VIAL values. Backends apply the recorded
  carrier representation and may not rerandomize or reinterpret them.
- Result/parity records compare semantic values. A backend may additionally
  validate driven carrier bits, but target spelling and casts never enter the
  parity oracle.
- The execution profile gains
  `vial.binding.directional_representation.v1`; this is a satisfied compiler
  capability, not a claim that any target backend has shipped.
- The VIAL source schema and HIAL bridge schema remain unchanged. `.7.3` owns
  the private binder implementation after a separate clean activation.

## Rejected Alternative

Requiring exact authored/carrier type identity would either replace VIAL
Boolean/numeric/enum intent with four-state logic or require HIAL to publish a
second VIAL-shaped semantic overlay. The former leaks representation upward;
the latter duplicates ownership and still needs a hardware-carrier mapping.
Both obscure the actual invariant: a directional value representation must be
proved at the seam.

## Canonical Detail

The exact record keys, proof IDs, direction rules, AHB oracle, diagnostics,
negative boundaries, and no-backend claims are canonical in
`docs/VIAL_EXECUTION_IR_V1_CONTRACT.md`. The discovery evidence remains in
`docs/VIAL_HIAL_TYPE_BINDING_MISMATCH_AUDIT.md`.

