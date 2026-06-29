# IAL2 AHB Subordinate Source Reference Seed Evidence Audit

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.704`

Date: 2026-06-29

## Outcome

`IAL2-FEATURE-COMPLETENESS-FRONTIER.704` does not establish the
source-backed AHB subordinate seed evidence yet. The repository still has no
local AHB/AHB-Lite source reference artifact and no curated AHB subordinate
source-evidence inventory.

The next exact owner is `IAL2-FEATURE-COMPLETENESS-FRONTIER.705`, an
AHB/AHB-Lite local source-reference import prerequisite. `.705` must establish
a repo-local, reviewable source artifact under the documentation/evidence
tree, or record the precise blocker if no acceptable source artifact is
available. Source-fact extraction and lower-layer seed contract selection stay
behind that import prerequisite.

No source reference, parser behavior, generator behavior, source sample,
support accounting, capability manifest, test behavior, schedule/check/semantic
JSON, generated artifact, HDL/runtime behavior, suffix behavior, direct
backend behavior, verification-output generation, backend-language variant,
AXI, APB, or VHDL behavior changed in this audit.

## Evidence Read

The audit read:

- `.703`, the AHB subordinate seed prerequisite selector;
- `.702`, the AHB completer/subordinate readiness audit;
- `.700`, bounded AHB `.ahb` profile-alias behavior;
- `.697`, bounded AHB requester `.ppif` behavior;
- current AHB mdBook boundary coverage;
- direct requester seed `fsm/amba_requester.fsm`;
- `docs/vendor/` inventory;
- AXI and Accellera local reference import task-tree precedent;
- AXI source-evidence inventory notes that were built from the tracked AXI
  PDF reference;
- README, ROADMAP_V2, task tree, Memory, and Knowledge Map.

Current tracked vendor references are:

```text
docs/vendor/arm/amba/axi/IHI0022_L_2025-08_AMBA_AXI_Protocol_Specification.pdf
docs/vendor/accellera/pss/Portable_Test_Stimulus_Standard_v3.0.pdf
docs/vendor/accellera/uvm/uvm_users_guide_1.2.pdf
docs/vendor/accellera/uvm/UVM_Class_Reference_Manual_1.2.pdf
docs/vendor/accellera/systemrdl/SystemRDL_2.0_Jan2018.pdf
```

No tracked path under `docs/vendor/` contains AHB or AHB-Lite reference
material.

## Finding

The project has useful AHB requester implementation evidence, but not source
evidence for subordinate behavior.

The current AHB sources:

```text
fsm/amba_requester.fsm
ppif/ahb_requester.ppif
ppif/ahb_requester.ahb
```

establish requester-side behavior and public IAL2 requester review artifacts.
They do not establish subordinate-side transfer qualification, select/default
behavior, ready/response timing, data phase behavior, read/write storage
policy, or unsupported-transfer response policy.

The existing AXI precedent separates three things:

- import the source artifact under `docs/vendor/...`;
- write curated source-evidence notes from that local artifact; and
- only then select implementation contracts from source-backed facts and
  explicitly labeled inferences.

AHB should follow the same structure. APB completer precedent is useful for
workflow shape, but APB cannot define AHB protocol behavior.

## Selected `.705` Scope

`.705` should establish the repo-local AHB/AHB-Lite reference prerequisite.

The next owner should:

- search only repo-local approved/provided inputs first;
- import an acceptable AHB/AHB-Lite source reference under a repo-relative
  `docs/vendor/arm/amba/ahb/` path if an approved artifact is available;
- keep the artifact import separate from rule extraction and behavior changes;
- record SHA-256 and git-ignore status for any copied artifact;
- update README, ROADMAP_V2, mdBook/backlog, task tree, Memory, and Knowledge
  Map;
- if no acceptable artifact is available, record the exact blocker instead of
  inferring protocol facts from requester code or non-authoritative summaries;
  and
- leave source-fact extraction, direct `.fsm` seed contract selection, seed
  implementation, IAL2 completer/subordinate source vocabulary, interconnect,
  scoreboards, full-manager behavior, direct backend, verification-output,
  backend-language variants, AXI, APB, and VHDL to later exact owners.

## Rejected Alternatives

Selecting the subordinate seed contract in `.704` is rejected because the
source facts are still unavailable locally.

Writing a curated subordinate source-evidence note in `.704` is rejected
because there is no local AHB/AHB-Lite source artifact to cite.

Importing or fetching a source artifact inside `.704` is rejected because the
leaf is an audit/selection leaf. The import needs its own owner, provenance,
SHA-256, docs updates, and verification.

Using requester code as the source of subordinate truth is rejected because it
would make the first subordinate endpoint an inferred mirror of requester
behavior rather than a source-backed protocol endpoint.

Using APB completer behavior as the source of AHB truth is rejected because APB
does not define AHB transfer, ready/response, burst, or data-phase semantics.

## Validation

The audit validation is documentation-only:

```bash
rg --files docs/vendor
perl -we 'for my $f (qx(rg --files docs/vendor)) { die $f if $f =~ /(?:ahb|ahb-lite|ihi00(?:11|33))/i } print "no local AHB vendor reference\n";'
perl -we 'for my $f (qx(rg --files fsm ppif perl/FSM/IAL2/ProtocolIntent t)) { die $f if $f =~ /ahb.*(?:completer|subordinate|slave)|(?:completer|subordinate|slave).*ahb/ } print "no AHB completer/subordinate fixture\n";'
rg -n 'AXI-SPEC-LOCAL-REFERENCE-IMPORT|ACCELLERA-STANDARDS-LOCAL-REFERENCE-IMPORT|docs/vendor/arm/amba/axi|source/copy SHA-256 match' \
  docs/tasks/AXI-SPEC-LOCAL-REFERENCE-IMPORT.md \
  docs/tasks/ACCELLERA-STANDARDS-LOCAL-REFERENCE-IMPORT.md \
  docs/AXI_VALID_READY_INTENT_PROBE.md \
  docs/AXI_ID_ORDERING_RULE_EVIDENCE_PROBE.md
rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\.704|IAL2-FEATURE-COMPLETENESS-FRONTIER\.705|source-reference import|docs/vendor/arm/amba/ahb' \
  docs/IAL2_AHB_SUBORDINATE_SOURCE_REFERENCE_SEED_EVIDENCE_AUDIT.md \
  docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md \
  README.md ROADMAP_V2.md MEMORY.md
```

Closeout reruns Knowledge Map, mdBook, memory, docs path, diff, and doctrine
gates.

## Rollback

Rollback of `.704` removes this audit, its Knowledge Map fact card, and the
README/ROADMAP/mdBook/task-tree/Memory updates. No runtime behavior, source
sample, parser rule, generator, support-accounting entry, test, generated
artifact, public suffix behavior, direct backend behavior, source reference, or
backend-language behavior is changed by this audit.
