# 0060 — VIAL bridge scale uses a qualification-only direct-IAL1 profile

- Date: 2026-08-10
- Type: verification architecture/scalability
- Status: selected by `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.2.3.1`
- Refines: [0035](0035-hial-vial-bridge-is-produced-from-reviewable-hial-routes.md), [0055](0055-vial-scale-proof-uses-orthogonal-workloads-and-stage-local-oracles.md)
- Implementation owner: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.2.3.2`

## Context

Decision `0035` intentionally shipped the first bridge producer with one exact
AHB annotation profile. Its validator accepts one transaction, six events, one
probe, and five residue records. When an actor has that annotation, the builder
projects its fixed transaction and does not also project ordinary IAL1
transactions. Commit `51434a2ae` introduced this correct bounded behavior.

Decision `0055` later selected orthogonal bridge-fanout candidates from the
manifest's broader defensive array limits: 256 transactions, 2,048 events,
256 probes, and 4,096 residue records. Commit `0516f2c66` selected those
candidates but did not select a canonical profile capable of reaching them.
Treating the nominal limits as exercised through the fixed AHB fixture would
therefore create false scale evidence.

A real frontend probe proves that a closed synthetic annotation can traverse
the ordinary direct-IAL1 route: authored `.isf` parses, its exact annotation
appears in the scheduler report, and normal lowering produces the generated
`.fsm`. No parser object, manifest, or bridge record needs to be forged.

## Decision

1. Preserve the exact `ahb/ARM-AMBA-AHB-IHI0033-C-2021-09/subordinate`
   annotation validator, manifest bytes, capability set, generated IAL1, and
   all checked AHB identities. Scale infrastructure must not relax that
   product profile.
2. Add one closed direct-IAL1 annotation profile solely for architecture-scale
   qualification:

   ```text
   protocol name: architecture_scale_probe
   profile:       qualification_only
   revision:      1
   role:          verification
   exact fact:    scale_evidence_only = true
   ```

   Its manifest advertises
   `hial_vial.bridge_qualification.architecture_scale_v1`, not a protocol,
   runtime, support, or capacity capability.
3. Generate ordinary `.isf` text and require the shipped parser, scheduler
   report, lowering path, and `Builder->build_ial1` in that order. The scale
   generator may accept no actor, schedule report, generated IAL0, manifest,
   or report supplied by its caller.
4. The annotation contains one minimal bridge transaction. The qualification
   profile additionally projects ordinary parsed actor transactions/events;
   generated actor parameters, scalar widths, endpoints, observations,
   storage-backed probes, and retained residues supply the other axes. All
   names and payloads remain deterministic under seed `1701`.
5. The qualification validator is closed: it requires the exact metadata
   above, scalar single-unit/single-domain meaning, resolved field/event/probe
   references, storage-backed read-only probes, and generated scale residue
   IDs. Unknown metadata or use through the IAL2 route fails closed.
6. Every workload targets the normalized post-builder manifest count. If the
   source-map or serialized-manifest limit necessarily precedes a requested
   structural count, the oracle records that exact earlier
   `HIAL_VIAL_BRIDGE_LIMIT_ERROR`; it never claims the later count was reached.
   `.17.4` alone owns any later limit-policy repair.
7. Manifest-byte workloads use real parsed semantic records and deterministic
   identifiers. Comments, blank text, opaque padding, caller-forged records,
   and path-length inflation are forbidden.

## Consequences

- `.17.2.3.2` can measure the selected bridge families through production
  authorities without broadening the AHB product profile.
- The qualification profile is private test infrastructure. It does not make
  a public embedding API, accepted protocol, execution/backend path, support
  classification, performance budget, or capacity claim.
- Direct IAL2 remains constrained to its generated and reparsed AHB IAL1 route;
  direct PPIF/AST/report consumption remains a hard failure.
- The previously hidden reachability gap is durable and queryable instead of
  being normalized away as test setup.

## Containment

This decision is one bounded rationale record under the existing rationale
collection limits; it changes no live-document ceiling.
