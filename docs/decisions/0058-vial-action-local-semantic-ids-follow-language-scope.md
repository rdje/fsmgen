# 0058 — VIAL action-local semantic IDs follow language scope

- Date: 2026-08-10
- Type: verification language/semantic identity
- Status: accepted by `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.2.2`
- Refines: [0033](0033-vial-v1-uses-spanned-s-expressions-and-typed-semantic-records.md)

## Context

The semantic-scale oracle requires every named `VIALSemanticIR` entity ID to
identify exactly one authored entity. The checked AHB source exposed that the
original builder did not satisfy this invariant: `accepted_once` and
`read_zero` are valid expectation names in both scenarios, but both pairs used
fixture-scoped IDs. Handles are also unique per scenario, and fiber names are
unique only inside their containing parallel action. Fixture-only IDs therefore
collapsed distinct legal declarations.

Git blame identifies frontend implementation commit `be9c741630` as the
origin. Downstream execution, trace, and result layers use these IDs as keys,
so treating the collision as report-only would preserve semantic ambiguity.

## Decision

1. Scenario-local handle and expectation IDs extend the named scenario
   semantic ID before their kind and authored local name.
2. Fiber IDs extend the named scenario ID with their canonical semantic path
   before the authored fiber name. A path component is necessary because the
   VIAL v1 parallel form has no authored parallel name and permits the same
   fiber name in distinct parallel actions.
3. Package, declaration, fixture, scenario, and other already-correct named
   IDs retain their existing readable package/kind/name form.
4. The semantic oracle proves that every named entity or handle ID maps to one
   authored semantic path. Reused local names in cloned scenarios and
   distinct parallel scopes are positive regression inputs.

## Consequences

- The checked AHB semantic graph contains 53 globally unambiguous named IDs;
  its two `accepted_once` expectations now differ by `scenario::success` and
  `scenario::unsupported_size` scope.
- `VIALSemanticIR` is private, so this correction does not version a public
  file schema. Downstream plans, artifacts, traces, and results receive the
  corrected IDs through their existing canonical producers.
- The change does not add syntax, capabilities, backend support, runtime
  qualification, or a scale-capacity claim.
