# Decision 0082: Portable SystemVerilog parallel children are single-await leaves

- **Status:** Accepted
- **Date:** 2026-08-24
- **Owner:** `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.3.5.1.3`

## Context

The target-neutral VIAL execution IR represents operations recursively. A
parallel operation therefore may identify child fibers whose programs contain
any recognized operation kind and successor chain.

Portable SystemVerilog backend revision 1 does not contain a general fiber
interpreter. Its parallel scheduler polls one property associated with each
direct child root. It neither invokes an arbitrary child operation task nor
advances a per-fiber program counter. The already qualified portable profile
therefore consists of a root parallel operation whose direct child fibers each
contain exactly one `await` operation.

A preserved executable counterexample replaced one such child `await` with a
`reset`. Planning accepted the target-neutral program and the backend emitted a
complete artifact set, but the generated scheduler never executed the reset.
A child containing an `await` followed by another operation had the same
structural problem: only the root property was observed and the successor was
not executed. This was silent semantic loss, not an emitter crash.

Supporting arbitrary parallel-child programs would require an explicit,
selected architecture for per-fiber program counters, operation phases,
blocking and resumption, nested `all`/`any` cancellation, shared-resource
conflict policy, and deterministic trace ordering. Inferring those semantics
inside this defect repair would create an undocumented second execution model.

## Decision

Portable SystemVerilog backend revision 1 admits a parallel operation only
when all of the following are structurally true:

1. It has one `activate_fibers` effect naming at least two unique child roots.
2. Every child root belongs to a distinct direct child fiber of the parent
   operation's fiber, in the same scenario.
3. Each child fiber contains exactly one operation, and that operation is its
   named root.
4. Every child operation is a terminal `await` with the expected property,
   evaluation effect, and deadline-phase shape.
5. Every non-root fiber is owned by exactly one parallel operation.

Negotiation rejects every other topology before creating artifacts. Rejection
diagnostics identify the parent and child operation and the precise violated
constraint. This includes non-`await` child kinds, multi-operation child
fibers, nested parallel children, duplicate roots, malformed awaits, and
unowned or multiply owned fibers.

This is a backend admission boundary, not a restriction on the target-neutral
execution IR. The IR and planner remain capable of representing general child
programs so another backend or a future portable-SystemVerilog revision may
select and implement a broader contract.

The rule governs the public portable-SystemVerilog revision-1 runtime profile.
It does not redefine decision `0077`'s caller-sealed balanced revision-2
qualification-only structural renderer, which deliberately claims no compile,
runtime, trace, or result semantics and has its own complete exact-shape gate.
The public revision-1 entrypoint continues to reject that private profile by
its two dedicated capability requirements, before artifact construction; it
does not reinterpret the revision-2 operation graph as a runtime candidate.

The machine-readable support contract publishes
`general_parallel_child_sequences` as an explicit nonclaim. Human-readable
backend manifests publish the single-`await` limitation as well.

## Rationale

The boundary preserves the behavior that has executable runtime qualification:
portable `all`/`any` composition over terminal property waits. It makes every
unimplemented shape fail atomically at negotiation, eliminating complete but
semantically false artifact sets.

The shape is derived from the actual scheduler contract rather than from a
source-level syntax whitelist. Checking fiber identity, ownership, program
cardinality, operation kind, and terminal-await structure makes the admission
rule robust against ordinary source programs and hostile or future IR
producers.

## Alternatives rejected

- **Invoke each generated operation task sequentially.** This would serialize
  the children and violate parallel timing and `any` cancellation semantics.
- **Emit an unqualified SystemVerilog `fork`.** Tool portability, deterministic
  tie resolution, cancellation, shared-resource behavior, and trace order
  would remain unspecified.
- **Accept any child root carrying a property.** A property does not prove that
  successor operations, side effects, or nested fibers have been executed.
- **Reject all portable parallel composition.** The single-`await` profile is
  already qualified by executable `all`/`any` runtime evidence and is useful.
- **Build a general fiber interpreter in this repair.** That is a separately
  selectable, versioned execution architecture with broader semantics and
  verification obligations; silently choosing it here would exceed the defect
  slice.

## Compatibility and evolution

Existing qualified portable programs are unchanged. Programs that the backend
previously emitted without executing all child semantics now receive
`VIAL_BACKEND_UNSUPPORTED` and no artifacts.

The balanced revision-2 structural-qualification artifact graph and its exact
public-bypass diagnostic remain byte-compatible because they belong to the
separately sealed non-runtime profile selected by decision `0077`.

A future revision may broaden the portable profile only through an explicit
decision and capability revision, with end-to-end runtime qualification for
each selected child-program semantic. Removing this gate without that evidence
would reintroduce the defect.

## Claim verification

- **Re-derivation:** inspect the generated portable scheduler and reconstruct
  its child behavior independently from the target-neutral execution IR.
- **Falsification:** run ordinary-source and hostile-IR cases for every other
  recognized operation kind, multi-operation fibers, duplicate roots, and
  malformed ownership; each must fail before artifact creation. Run the
  qualified single-`await` `all`/`any` integration cases to disprove accidental
  over-rejection.
- **Durability:** retain the admission tests, executable runtime tests, support
  contract nonclaim, backend manifest limitation, contract documentation, and
  this decision record under the owning task-tree leaf.
