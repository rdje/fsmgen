# IAL2 AHB Completer/Subordinate Readiness Audit

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.702`

Date: 2026-06-29

## Outcome

`IAL2-FEATURE-COMPLETENESS-FRONTIER.702` finds AHB
completer/subordinate IAL2 work not ready for public IAL2 contract selection
yet.

The next exact owner is `IAL2-FEATURE-COMPLETENESS-FRONTIER.703`, a
no-behavior lower-layer AHB subordinate seed contract selection. `.703` must
select the first direct `.fsm` subordinate seed contract or select a smaller
prerequisite if the seed cannot be specified safely.

No parser behavior, generator behavior, public source sample, support
accounting, capability manifest, test behavior, schedule/check/semantic JSON,
generated artifact, HDL/runtime behavior, suffix behavior, direct backend
lowering, verification-output generation, backend-language variant, AXI, APB,
or VHDL behavior changed in this audit.

## Evidence Read

The audit read:

- `.701`, the post-`.ahb` selector;
- `.700`, bounded AHB `.ahb` profile-alias behavior;
- `.697`, bounded AHB requester `.ppif` behavior;
- the current AHB mdBook chapter and current-boundary fact card;
- direct seed `fsm/amba_requester.fsm`;
- `FSM::Adapter::IAL2::PPIF` AHB requester parsing and suffix validation;
- `FSM::IAL2::ProtocolIntent::AhbRequester` report/residue behavior;
- APB completer/interconnect readiness and contract precedent from `.558`
  through `.560`;
- `RegressionCorpus` and `LanguageSurfaceSection` AHB entries;
- focused AHB tests; and
- README, ROADMAP_V2, task tree, Memory, and Knowledge Map.

The shipped public AHB IAL2 surface is requester-only:

```text
ppif/ahb_requester.ppif
ppif/ahb_requester.ahb
```

The older direct seed is also requester-only:

```text
fsm/amba_requester.fsm
```

It passes strict check as `protocol.amba_requester` and support-accounts as a
direct-root protocol fixture.

## Lower-Layer Evidence Gap

APB completer work was able to move toward IAL2 public contract selection only
after lower-layer APB endpoint evidence already existed:

```text
fsm/apb_completer.fsm
fsm/apb_tb.fsm
```

AHB does not have an equivalent subordinate target today. A repository scan
over `fsm/`, `ppif/`, `perl/FSM/IAL2/ProtocolIntent/`, and `t/` finds no
shipped AHB completer, subordinate, or slave fixture/generator beyond the
current requester behavior.

That gap matters because a bounded AHB subordinate is not just an inverted
requester. The first seed must select, at minimum, the subordinate-side signal
families, ready/response timing, read/write storage behavior, transfer
qualification, reset/default outputs, and error/unsupported-transfer policy.
Those choices should be reviewable in a lower-layer `.fsm` artifact before an
IAL2 source vocabulary promises to generate them.

## Readiness Finding

AHB completer/subordinate work is ready for a lower-layer seed contract
selection, not for an IAL2 public contract selection.

The current requester path provides useful surrounding evidence:

- explicit `(profile ahb)` policy;
- generated `.isf` before generated `.fsm` review artifacts for requester
  IAL2 paths;
- report schema and support-accounting precedent;
- `.ppif` first, then `.ahb` alias widening;
- fail-closed diagnostics for unsupported AHB object breadth; and
- explicit `ahb_completer_subordinate_deferred` and
  `ahb_interconnect_decode_deferred` residue.

However, no existing lower-layer AHB subordinate seed establishes the endpoint
behavior an IAL2 contract should target. Selecting IAL2 source syntax first
would risk guessing protocol-local behavior and generated artifacts without a
cycle-level oracle.

## Selected `.703` Scope

`.703` should select the first lower-layer AHB subordinate seed contract
before any behavior changes.

The selector should decide:

- direct seed path and module name, such as whether the seed is
  `fsm/amba_subordinate.fsm`, `fsm/ahb_subordinate.fsm`, or another exact
  name;
- whether project vocabulary should prefer `subordinate`, `completer`, or both
  terms in docs and later IAL2 source shapes;
- the bounded signal set for the first subordinate endpoint;
- selected reset/default output behavior;
- transfer qualification and wait-state policy;
- read/write storage behavior for the smallest useful register target;
- response/error behavior for unsupported or unmapped transfers;
- support-accounting identity for the direct seed;
- direct strict-check and HDL validation probes;
- what IAL2 public contract questions remain after the seed ships; and
- rollback.

`.703` must not add the seed itself. If `.703` cannot select the seed safely,
it should select the smallest prerequisite needed before any AHB subordinate
behavior change.

## Rejected Alternatives

Immediate AHB IAL2 completer/subordinate public contract selection is rejected
because the lower-layer endpoint contract is missing.

Immediate AHB completer/subordinate implementation is rejected because neither
the lower-layer seed nor the IAL2 source vocabulary, report schema,
support-accounting identity, diagnostics, or generated artifact contract is
selected.

AHB interconnect/decode is rejected because it needs at least one selected
subordinate endpoint before topology, address decode, arbitration, bus-matrix,
or aggregate top behavior can be selected.

Full AHB manager behavior and scoreboards are rejected because they are broader
than the first missing endpoint.

Reusing APB completer behavior is rejected because APB evidence establishes an
APB target, not AHB subordinate ready/response and transfer semantics.

Profile-alias cleanup and residue-only cleanup are rejected because the current
AHB residue accurately points at real future owners.

## Validation

The audit validation is documentation-only:

```bash
./bin/fsmgen --quiet --strict --check --json fsm/amba_requester.fsm
./bin/fsmgen --quiet --emit-schedule-json ppif/ahb_requester.ppif
./bin/fsmgen --quiet --emit-schedule-json ppif/ahb_requester.ahb
perl -we 'for my $f (qx(rg --files fsm ppif perl/FSM/IAL2/ProtocolIntent t)) { die $f if $f =~ /ahb.*(?:completer|subordinate|slave)|(?:completer|subordinate|slave).*ahb/ } print "no AHB completer/subordinate fixture\n";'
rg -n 'ahb_completer_subordinate_deferred|ahb_interconnect_decode_deferred|AHB completer/subordinate generation|AHB interconnect/decode generation' \
  docs/IAL2_POST_AHB_PROFILE_ALIAS_NEXT_SLICE_SELECTION.md \
  docs/IAL2_AHB_REQUESTER_PPIF_BEHAVIOR.md \
  docs/IAL2_AHB_PROFILE_ALIAS_BEHAVIOR.md \
  docs/book/src/16c-ial2-ahb.md
```

Closeout reruns Knowledge Map, mdBook, memory, docs path, diff, and doctrine
gates.

## Rollback

Rollback of `.702` removes this audit, its Knowledge Map fact card, and the
README/ROADMAP/mdBook/task-tree/Memory updates. No runtime behavior, source
sample, parser rule, generator, support-accounting entry, test, generated
artifact, public suffix behavior, direct backend behavior, or backend-language
behavior is changed by this audit.
