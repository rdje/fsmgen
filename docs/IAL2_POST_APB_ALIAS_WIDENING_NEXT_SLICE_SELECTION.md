# IAL2 Post APB Alias Widening Next Slice Selection

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.570`

Date: 2026-06-27

## Outcome

`IAL2-FEATURE-COMPLETENESS-FRONTIER.570` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.571`, APB requester busy/status public
contract selection after requester-transfer, completer, fixed composition, and
bounded `.apb` alias coverage all shipped.

This selector changes no parser, generator, sample, support-accounting,
manifest, test, schedule/check/semantic JSON, HDL/runtime, direct backend,
verification-output, backend-language variant, AXI, APB, or VHDL behavior.

## Evidence Read

The selector read the current shipped APB surfaces:

- APB requester-transfer `.ppif` behavior from `.550`;
- APB requester-transfer `.apb` profile alias from `.554`;
- APB completer `.ppif` behavior from `.562`;
- fixed APB requester/completer composition `.ppif` behavior from `.566`;
- APB completer and fixed composition `.apb` aliases from `.569`;
- current APB report residue in requester, completer, and composition
  reports;
- `RegressionCorpus` APB `.ppif` and `.apb` support entries;
- `LanguageSurfaceSection` `.ppif` and `.apb` boundaries;
- focused APB tests; and
- README, ROADMAP_V2, mdBook, task tree, Memory, and Knowledge Map.

Exact probes captured the current public `.apb` report boundary:

```bash
./bin/fsmgen --quiet --emit-schedule-json ppif/apb_requester_transfer.apb
./bin/fsmgen --quiet --emit-schedule-json ppif/apb_completer.apb
./bin/fsmgen --quiet --emit-schedule-json ppif/apb_composition.apb
```

The requester and composition reports still carry
`apb_requester_busy_status_deferred`. The requester report exposes response
keys `done`, `last_error`, and `last_read_data`, and says requester busy/status
output remains future contract widening. The fixed composition report exposes
top ports `done`, `last_error`, and `last_read_data`, repeats the same
busy/status residue, and leaves multi-peripheral decode, multi-register decode,
sidebands/strobes, alternate widths, and back-to-back policy as separate
future owners.

Lower-layer hand-authored APB fixtures already prove the intended public
direction is plausible: `fsm/apb_requester.fsm` includes a public `busy`
output, and `fsm/apb_tb.fsm` exposes top-level `busy` alongside `done`,
`last_error`, and `last_read_data`. The generated IAL2 requester/composition
surface has not yet selected how to expose that status.

## Selection

The next owner is a public contract selection, not immediate implementation:

```text
IAL2-FEATURE-COMPLETENESS-FRONTIER.571
```

`.571` must decide the exact APB requester busy/status contract before any
behavior changes, including:

- whether the first widening exposes only `busy`, or also a named status field;
- source syntax for requester and fixed composition response/status bindings;
- generated requester `.isf`/`.fsm` review-artifact expectations;
- fixed composition top-port propagation;
- `.ppif` and `.apb` sample/support-accounting identity policy;
- report schema/residue updates;
- check JSON and semantic JSON source identity expectations;
- diagnostics for malformed or unsupported status clauses;
- validation coverage; and
- rollback.

The selector favors requester busy/status because it is the narrowest remaining
APB user-visible interface gap shared by requester-transfer and fixed
composition. It is smaller than multi-peripheral interconnect/decode,
multi-register decode, sidebands/strobes, alternate widths, or back-to-back
transfer policy, and it can be contracted against existing lower-layer APB
fixture evidence before generated behavior changes.

## Rejected Alternatives

Immediate busy/status implementation is rejected here because the public source
syntax, generated top-port propagation, report/residue updates, and diagnostics
need an exact contract first.

Multi-peripheral APB interconnect/decode is rejected as the next owner because
it requires address maps, peripheral selection, decode-error policy, and top
port shape beyond the current fixed one-requester/one-completer composition.

Multi-register decode is rejected as the next owner because it changes the
completer storage/register map contract, while requester busy/status only
widens observation of an already generated requester transfer.

Sidebands/strobes and alternate widths are rejected as the next owner because
they widen protocol signal shape across requester, completer, composition, and
fixtures. Back-to-back transfer policy is rejected because it changes
admission/queueing behavior rather than exposing a simple status output.

APB report/residue cleanup alone is rejected because the current residues
accurately point at real future owners. Another IAL2 protocol surface, direct
backend, verification-output, backend-language variant, AXI follow-on, and
VHDL are rejected because the APB requester/composition public interface still
has a small local gap with clear evidence.

## Validation

The selector is validated with:

```bash
./bin/fsmgen --quiet --emit-schedule-json ppif/apb_requester_transfer.apb
./bin/fsmgen --quiet --emit-schedule-json ppif/apb_completer.apb
./bin/fsmgen --quiet --emit-schedule-json ppif/apb_composition.apb
rg -n 'apb_requester_busy_status_deferred|busy' \
  docs/IAL2_APB_PPIF_REQUESTER_TRANSFER_BEHAVIOR.md \
  docs/IAL2_APB_PPIF_COMPOSITION_BEHAVIOR.md \
  fsm/apb_requester.fsm fsm/apb_tb.fsm
```

The final `.570` closeout reruns Knowledge Map, mdBook, memory, docs path,
diff, and doctrine gates.

## Rollback

Rollback of `.570` removes this selector record, its Knowledge Map fact card,
and the README/ROADMAP/mdBook/task-tree/memory updates. No runtime behavior,
source sample, parser rule, generator, support-accounting entry, test,
generated artifact, or public suffix behavior is changed by this selector.
