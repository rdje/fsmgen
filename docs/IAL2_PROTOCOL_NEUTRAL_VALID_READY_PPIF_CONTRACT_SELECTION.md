# IAL2 Protocol-Neutral Valid-Ready PPIF Contract Selection

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.530`

Date: 2026-06-26

## Outcome

`IAL2-FEATURE-COMPLETENESS-FRONTIER.530` selects the public contract for the
first protocol-neutral/non-AXI Valid-Ready `.ppif` example and selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.531`, direct bounded implementation of
that contract.

The contract keeps `.ppif` as the generic Protocol/Platform Intent Format IAL2
container. It does not introduce `.axi`, `.chi`, `.ace`, `.ahb`, `.apb`,
`.atb`, `.smbus`, `.i2s`, or any other profile-specific suffix alias. AXI
remains the first shipped IAL2 profile/example, not the definition of IAL2.

## Selected Source Shape

The first protocol-neutral Valid-Ready example uses a required profile clause:

```text
(profile valid-ready)
```

No-profile `.ppif` input remains unsupported. Keeping the explicit profile
selector preserves source identity, makes diagnostics unambiguous, and avoids
quietly promoting one sample into the whole IAL2 common core.

The selected one-channel source shape is:

```text
(protocol-platform-intent valid_ready_handshake
  (profile valid-ready)
  (source
    (object fsmgen-valid-ready-profile)
    (anchor (document FSMGEN-IAL2-VALID-READY-PROFILE)
            (section monitor)
            (page contract)))
  (valid-ready-channel data_link
    (channel data_link)
    (role producer-to-consumer)
    (clock clk)
    (reset (rst_n active_low async))
    (valid valid)
    (ready ready)
    (payload
      (data width 8))))
```

The selected sample path is:

```text
ppif/valid_ready_handshake.ppif
```

The selected support-accounting identity is:

```text
intent.ppif_valid_ready_handshake
```

The expected generated channel monitor module name follows the existing
Valid-Ready naming rule:

```text
data_link_valid_ready_monitor
```

## Profile Vocabulary

For `(profile valid-ready)`:

- `(valid-ready-channel NAME ...)` keeps the existing object-name role; `NAME`
  remains an ISF identifier and drives generated artifact names.
- `(channel NAME)` is an authored logical channel identifier, not an AXI
  channel family. It must use the same identifier grammar as generated ISF
  signal/object names.
- `(role producer-to-consumer)` is the selected neutral direction for the
  first sample.
- `(role consumer-to-producer)` is reserved as the opposite neutral direction
  for later exact owners; it does not need to be exercised by the first sample.
- `manager-to-subordinate` and `subordinate-to-manager` remain accepted AXI
  profile roles and must not be removed or reinterpreted.
- `AW`, `W`, `B`, `AR`, and `R` remain AXI profile channel families and must
  not be required or implied for `(profile valid-ready)`.

This contract does not claim that every Valid-Ready-like protocol uses the
same semantics. It selects a bounded generic handshake monitor profile whose
behavior is limited to observing `VALID && READY` transfer fire plus payload
binding visibility.

## Source Anchors

The first neutral sample uses an internal FSMGen profile source anchor rather
than citing an external protocol standard. The selected anchor names the
contractual profile source:

```text
(anchor (document FSMGEN-IAL2-VALID-READY-PROFILE)
        (section monitor)
        (page contract))
```

This is intentionally explicit. It avoids pretending that a non-AXI sample is
backed by an AXI specification section, while still satisfying the current
source-anchor requirement and keeping generated source/residue reports
reviewable.

## Report Contract

The first implementation should keep the existing report schema names:

```text
fsmgen.ial2.protocol_intent.valid_ready_channel.v1
fsmgen.ial2.protocol_intent.valid_ready_bundle.v1
```

The schema names can remain stable because `target_channel.protocol`,
`target_channel.family`, and `target_channel.role` are already profile and
channel metadata rather than AXI-only field names. For `(profile
valid-ready)`, the first one-channel report should use:

```text
target_channel.protocol = "valid-ready"
target_channel.family   = "data_link"
target_channel.role     = "producer-to-consumer"
```

The implementation owner must update generator diagnostics and
`enforced_static_rules` so generic Valid-Ready failures are not phrased as
"AXI Valid-Ready" errors. AXI-specific residue, such as AXI manager
concurrency, must remain AXI-profile-local; the neutral profile should report
only monitor-profile residue that applies to the generic handshake monitor.

If the first implementation needs additive report detail for profile kind or
source-attribution clarity, it may add optional fields without changing the
schema name. It must not remove or rename existing AXI report fields.

## Bundle Boundary

Decision `0017` remains the bundle contract. A future
`(profile valid-ready)` bundle can reuse the aggregate bundle shape if every
channel follows the selected neutral vocabulary. The first implementation owner
is not required to add a neutral bundle sample. It must preserve the existing
AXI AW/W bundle behavior and should fail closed for any neutral bundle shape it
does not explicitly support.

## Selected `.531` Scope

`.531` should implement the one-channel `ppif/valid_ready_handshake.ppif`
contract. It should update the parser/generator normalization, diagnostics,
report residue/static-rule text, support accounting, focused parser/generator
tests, README, ROADMAP_V2, mdBook, task tree, Memory, and Knowledge Map.

`.531` must preserve:

- existing AXI one-channel Valid-Ready behavior;
- existing AXI AW/W bundle behavior;
- existing AXI manager capacity/status behavior;
- the required `IAL2 -> generated .isf -> generated .fsm -> HDL` lowering
  chain;
- unsupported `.pif`, `.ppi`, `.axi`, `.chi`, `.ace`, `.ahb`, `.apb`, `.atb`,
  `.smbus`, and `.i2s` suffix behavior;
- support-accounting identities for existing AXI samples; and
- all backend/VHDL boundaries.

## Non-Goals

This contract does not select:

- a no-profile `.ppif` form;
- profile-specific suffix aliases;
- a neutral multi-channel bundle implementation;
- full non-AXI protocol behavior;
- common IAL2 queue/order/read-data constructs;
- AXI manager behavior changes;
- direct backend lowering;
- verification-output generation for IAL2 profiles;
- backend-language variants; or
- VHDL behavior.

## Validation

`.530` is documentation-only and closes with:

```bash
bash knowledge-map/scripts/gen_knowledge_map.sh
bash knowledge-map/scripts/check_knowledge_map.sh
mdbook build docs/book
scripts/check_docs_relative_paths.sh
scripts/check_memory_architecture.sh
git --no-pager diff --check
scripts/check_doctrines.sh
```

## Rollback

Rollback is documentation-only: remove this contract selection, its Knowledge
Map fact, task-tree advancement, README/ROADMAP_V2/mdBook sync, and Memory
pointer. No parser, generator, sample, support-accounting, runtime, generated
HDL, or backend artifact rollback is required.
