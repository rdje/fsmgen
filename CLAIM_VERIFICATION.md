<!-- CLAIM-VERIFICATION-LOCAL-ADOPTION:BEGIN -->
## Local adoption note — FSMGen

- Authority: FSMGen maintainers; adopted 2026-08-20 under decision `0074`,
  deliberately revised 2026-09-23 under decision `0104`.
- Authoritative copy: repository-root `CLAIM_VERIFICATION.md`. Bootstrap and
  focused references point here; they do not independently define this policy.
- Original adoption: the neutral body was imported byte-for-byte with SHA-256
  `8f194574ec718749e90a402cf6e4dc6650e44f6185dd194853a54482eef68643`.
  The current body is a reviewed local revision, not that original byte copy.
- Reviewed update: the director-selected template, exact diff and dispositions
  are retained in `docs/audits/claim-template-review-20260923/` under
  `CLAIM-VERIFICATION-TEMPLATE-REVIEW`. Its deployment measurements and other
  project's assent are source history, not FSMGen measurements or authority.
  Original examples remain available in the retained `template.txt`.
- Independence: the originating template is not an upstream. Later changes
  require deliberate local review and task-tree ownership.
- Scope: decision `0074` distinguishes actionable quantitative claims from
  incidental dates, versions, identifiers, HDL literals, examples and transient
  command output. Those exclusions do not weaken exact semantic contracts.
- Enforcement: `scripts/check_claim_verification.pl` validates bounded records,
  exact source markers, named distinct legs or owned gaps, and tracked local
  paths. `scripts/check_doctrines.sh` runs the registered doctrine. Structural
  checks do not prove semantic truth, statistical adequacy or oracle independence.
- Registry contract: decision `0094` makes the finite manifest-addressed set
  the default, with aggregate, shard and global-identity bounds. Explicit
  `--registry` retains bounded portable single-file fixture compatibility.
- Original-constant membership: the baseline names an exact adoption commit
  and derives its identity set from that versioned source. Current files retain
  every original identity without rediscovering the frozen cohort; later nested
  fields may remain legitimate current-only constants.
<!-- CLAIM-VERIFICATION-LOCAL-ADOPTION:END -->

---
# Claim Verification — re-derive, falsify, and make durable

This project- and harness-neutral standard applies when a measurement becomes
an actionable quantitative claim. It complements task ownership, durable memory,
knowledge retrieval and doctrine enforcement: those locate and enforce records;
this standard asks whether the evidence earns the claim.

## 0. How to use this file

1. Use the distinct evidence legs in §3 as the definition of checked.
2. Publish their evidence and any missing leg under §4.
3. Mechanize decidable invariants under §5 and apply the review checklist in §7.

State each rule in domain-free terms before any labeled illustration. The rule
must be complete without machinery specific to an example. If an example is
carrying an unstated assumption, clarify the rule before applying it elsewhere.

## 1. Why repeating a check is insufficient

A repeated pass can reproduce the same blind spot. Matching totals cannot prove
correct allocation between categories; agreement between instruments cannot
validate a classifier they share; a correct copied value can become stale when
its inputs change. Ask which defect the evidence could actually expose.

*Illustration:* a suite-level success attribute does not establish a property of
each individual test. Repeating the suite query answers the same group question.
An item-level claim needs item-level evidence or a proven mapping to that item.
This is an illustration, not a measurement of this project's test results.

## 2. Check limits

| Check | What it can detect | What it leaves open |
| --- | --- | --- |
| Sum of parts equals total | Omission, duplication or arithmetic errors affecting the sum | Misallocation that preserves the sum |
| Row count equals expectation | A population-size mismatch | Wrong values within the rows |
| Input identity hash | Changed declared inputs | Logic errors and undeclared inputs |
| Implementation and tests from the same interpretation | Some transcription errors | A shared misunderstanding of the contract |
| Checklist completed | A declared step is present | Whether the step was done correctly |
| Group-level attribute | Properties of that group | Different properties of its members |
| Independent per-category comparison | Disagreement in allocation | Defects shared by the sources or outside the compared scope |

Independence concerns the possible defect, not the number of tools. Identify
shared assumptions and classifiers; two commands using the same wrong predicate
are not independent evidence about that predicate.

## 3. The three legs

### Leg 1 — RE-DERIVE: does the source reproduce the claim?

Run the derivation and retain its output, source revision, relevant environment
and input identity. Consistency among copied numbers is not re-derivation.

- State the quantity, observation unit, population and predicate before running
  the command. Match evidence granularity to the claim: container evidence
  cannot establish each member's property without a demonstrated mapping.
- Re-derive numbers quoted from the project's own documentation as well as new
  measurements. Prefer one authoritative derivation over synchronized copies.
- Attribute a changed result with a controlled before/after comparison or an
  isolated reconstruction when safe and meaningful. Keep inputs and conditions
  comparable and preserve the first failure and unrelated user work. A reversal
  in a controlled comparison is stronger attribution evidence than reading alone.
  Never replay a spent capture, bypass an admission prerequisite, or discard
  evidence just to perform this check. If the comparison cannot be obtained,
  publish the attribution gap and its owner; do not invent a timing guarantee.

### Leg 2 — FALSIFY: what separates the claim from a competing hypothesis?

Name the competing hypothesis and seek evidence that would distinguish it.
More observations predicted equally by both explanations do not separate them.

*Illustration:* one emitted definition could mean several units were merged or
that all but one were eliminated. A definition count alone cannot distinguish
those explanations; evidence of where each actual call resolves may do so.

- Prefer an independently established oracle. Explain which shared defect it
  can expose, rather than calling it independent merely because it has another name.
- A set claim carries a scoped enumeration and its command. Define the searched
  population and exclusions before claiming absence, uniqueness or completeness.
  A search result is a candidate population: classify its members before
  publishing a defect count. Search hits and absence of hits both need scrutiny.
- Consult prior project adjudications for the same case. Explain any material
  difference in revision, scope, contract or evidence before contradicting them.
  If no difference is established, the conflicting finding is unproved. History
  increases the burden of proof; it cannot make a demonstrated old error correct.
- Observe controls fail on a known-bad input when permitted. A control seen only
  green has not demonstrated its ability to reject the relevant defect. If the
  necessary control is unavailable, name the missing falsification evidence.
- Derive membership and classification evidence from the authorized producer
  contract or emitted data, not merely the prose used to implement the classifier.
  Respect dependency black-box boundaries; source access alone is not authority
  to inspect an implementation.

### Leg 3 — DURABILITY: can a reader reproduce it and detect staleness?

Track the producer, relevant inputs and evidence, or name an explicit durability
gap. Ignored scratch data cannot be the sole source of a reproducible claim.

A current derived value needs a watcher that fails when the value or any relevant
input changes. Correcting an unwatched constant without fixing its update path
leaves the same failure mechanism. Derive inexpensive values at use; otherwise
bind the complete artifact to its inputs and require remeasurement on change.
Historical observations must identify their capture boundary and retention
contract; they must not silently become claims about the current state.

## 4. Publishing contract

State the claim's scope, conditions and evidence legs. Name each missing leg and
its repair owner rather than presenting absence as success.

*Illustration:* "Re-derived and falsified for the recorded input revision;
durability remains unproved because the producing instrument is untracked."

Use intervals and an explicit sampling method for stochastic measurements.
Do not infer agreement or precision from a single run when within-condition
variation has not been assessed. When a new derivation contradicts an existing
claim, investigate both instruments: being newer does not make it authoritative.

### 4.1 Reviewing a challenged claim

Stand behind the recorded scope, revision, evidence and named gaps. Rechecking
when evidence or conditions change is legitimate; an immediate unconditional
answer is not a verification method. Correct an error with its cause and owned
repair, without silently rewriting the original claim's scope.

| Axis | Review obligation |
| --- | --- |
| Prose | Assess the statement under its original scope and conditions; explain changed context separately. |
| Quantity | Compare the same population, predicate, instrument and conditions; justify any tolerance before evaluating agreement. |
| Named instance | Verify that exact identity and its asserted property; aggregate evidence does not license a substitute. |

A fixed-input deterministic census should reproduce exactly. A changed population,
predicate, instrument or relevant environment may answer a different question and
must be identified. A command can also measure stochastic behavior: runtime and
resource samples still require the measurement treatment above.

Contract values and named identities are exact; a nearby value does not satisfy
the contract. A judgment estimate may use a stated, justified tolerance when the
underlying decision allows it. Do not choose the tolerance after seeing the
result or use an aggregate tolerance to excuse a wrong named instance. Incidental
numerals remain subject to their semantic contracts even when no claim record
is required for them.

## 5. Mechanizing the contract

Mechanize what can be decided honestly; expose the remaining review obligations.
A provenance tag or structured record names the derivation, falsification and
durability evidence or their gaps. Presence and format alone cannot prove truth.

A repository-derived constant is derived or gated. If a cheaper identity check
stands in for remeasurement, it must cover every input affecting the complete
artifact, including the producing instrument, and fail on identity drift.

*Illustration:* binding source inputs and a consuming binary is insufficient
when changing the reporting instrument changes the stored artifact. Include
that instrument even if the headline metric appears unchanged.

## 6. Anti-patterns

- Counting repeated passes as independent evidence.
- A control never observed rejecting the relevant defect.
- Shared interpretation presented as an independent specification oracle.
- A conservation check presented as proof of correct allocation.
- An actionable measurement whose producer is untracked or whose inputs are lost.
- Fixing a copied value without a derivation or watcher for its update path.
- Treating a comment instructing remeasurement as an executable gate.
- A point estimate presented as adequate evidence for a stochastic quantity.
- An absence or uniqueness claim without a scoped enumeration.
- Raw search hits published as a classified defect count.
- A member-level claim supported only by its container's attribute.
- Confidence, a newer instrument or an old adjudication treated as proof by itself.

## 7. Adoption and review checklist

1. Define the actionable-claim scope and its explicit exclusions.
2. Require distinct evidence legs and visible owned gaps in review records.
3. Inventory published derived constants; derive or gate them from their source.
4. Find ignored or untracked producers and inputs behind published claims, and
   repair their durability or disclose the gap.
5. Exercise controls against known-bad inputs when permitted; fix ineffective
   controls or disclose the missing evidence without bypassing prerequisites.
6. Review the evidence's unit, population, enumerations and prior adjudications.
7. Restate each rule without its illustration before adopting it. Keep local
   paths, authority, measurements and adaptations in a separate adoption note.
8. Document what mechanical gates establish and what remains semantic review.
