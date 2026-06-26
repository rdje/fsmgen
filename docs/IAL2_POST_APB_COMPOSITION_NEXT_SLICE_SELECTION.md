# IAL2 Post APB Composition Next Slice Selection

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.567`

Date: 2026-06-26

## Outcome

`IAL2-FEATURE-COMPLETENESS-FRONTIER.567` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.568`, APB `.apb` profile-alias public
contract selection for the now-shipped APB completer and fixed APB
requester/completer composition shapes.

This selector changes no parser, generator, support-accounting, sample,
schedule/check/semantic JSON, HDL/runtime, direct backend, verification-output,
backend-language variant, AXI, APB, or VHDL behavior.

## Evidence Read

The selector read the shipped APB surfaces:

- APB requester-transfer `.ppif` behavior from `.550`;
- APB requester-transfer `.apb` profile alias from `.554`;
- APB completer `.ppif` behavior from `.562`;
- APB fixed requester/completer composition `.ppif` behavior from `.566`;
- current APB report residue in the requester, completer, and composition
  generators;
- current `LanguageSurfaceSection` boundaries;
- `RegressionCorpus` support-accounting entries; and
- README, ROADMAP_V2, mdBook, task tree, Memory, and Knowledge Map.

Exact probes confirmed the current boundary:

```bash
./bin/fsmgen --quiet --emit-schedule-json ppif/apb_requester_transfer.apb
./bin/fsmgen --quiet --emit-schedule-json ppif/apb_completer.ppif
./bin/fsmgen --quiet --emit-schedule-json ppif/apb_composition.ppif
./bin/fsmgen --quiet --strict --check --json /tmp/fsmgen-pnt567-apb-completer.apb
./bin/fsmgen --quiet --strict --check --json /tmp/fsmgen-pnt567-apb-composition.apb
```

The first three probes pass. The temporary `.apb` copies of the APB completer
and APB composition sources fail closed with the current alias diagnostic:
`.apb` supports only the APB requester-transfer object in this slice.

## Selection

The next owner is a public contract selection, not immediate implementation:

```text
IAL2-FEATURE-COMPLETENESS-FRONTIER.568
```

`.568` must decide the exact `.apb` alias contract before behavior changes,
including:

- whether the alias widening ships both APB completer and APB composition in
  one behavior slice or splits them;
- future sample paths, expected to be considered as `ppif/apb_completer.apb`
  and `ppif/apb_composition.apb`;
- support-accounting identities and coverage names;
- source kind, expected to remain `ial2_profile_alias`;
- public source-path preservation in check JSON and semantic JSON;
- generated `.isf` and `.fsm` review-artifact preservation;
- diagnostics for non-APB profile mismatch and unsupported APB shapes; and
- rollback and validation gates.

The selector favors `.apb` alias contract selection because all underlying APB
generic `.ppif` behavior needed for aliasing now exists. Alias widening is a
source-surface contract problem, not a new APB protocol behavior. It is also a
smaller and safer next step than multi-peripheral interconnect/decode,
multi-register decode, sidebands/strobes, alternate widths, or back-to-back
requester policy.

## Rejected Alternatives

Immediate `.apb` implementation is rejected here because the public contract
still needs exact sample paths, support identities, diagnostics, and validation
scope recorded before any behavior changes.

Requester `busy`/status exposure is rejected as the next owner because it
would widen the requester endpoint and composition top interfaces. That is a
real protocol-contract change, while `.apb` alias widening can mirror shipped
generic `.ppif` behavior.

Multi-peripheral APB interconnect/decode is rejected as the next owner because
the shipped composition is fixed one-requester/one-completer wiring. Decode
policy needs a separate contract for address maps, peripheral selection, error
routing, and top-level port shape.

Multi-register decode, sidebands/strobes, alternate widths, and back-to-back
policy remain deferred because they change endpoint behavior rather than
exposing the shipped behavior through the existing profile-alias mechanism.

## Validation

The selector was validated with:

```bash
./bin/fsmgen --quiet --emit-schedule-json ppif/apb_requester_transfer.apb
./bin/fsmgen --quiet --emit-schedule-json ppif/apb_completer.ppif
./bin/fsmgen --quiet --emit-schedule-json ppif/apb_composition.ppif
./bin/fsmgen --quiet --strict --check --json /tmp/fsmgen-pnt567-apb-completer.apb
./bin/fsmgen --quiet --strict --check --json /tmp/fsmgen-pnt567-apb-composition.apb
```

The final `.567` closeout reruns Knowledge Map, mdBook, memory, docs path,
diff, and doctrine gates.

## Rollback

Rollback of `.567` removes this selector record, its Knowledge Map fact card,
and the README/ROADMAP/mdBook/task-tree/memory updates. No runtime behavior or
source sample is changed by this selector.
