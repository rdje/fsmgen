# IAL2 Post-APB Data16 PPROT Next Slice Selection

Date: 2026-06-27

Owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.604`

## Decision

`.604` selects `IAL2-FEATURE-COMPLETENESS-FRONTIER.605`, an APB
back-to-back transfer policy readiness audit, as the next APB/IAL2
feature-completeness owner after the shipped sideband data16 `PPROT` policy
behavior.

This is a no-behavior selector. It does not change APB source acceptance,
parser behavior, generator behavior, sample files, support-accounting catalog
entries, validation behavior, generated artifacts, schedule/check/semantic JSON
behavior, HDL/runtime behavior, suffix acceptance, direct backend lowering,
verification-output generation, backend-language variants, AXI behavior, AHB
behavior, or VHDL behavior.

## Evidence Read

The selector read the `.603` shipped behavior, `.602` public contract, `.601`
readiness audit, `.600` selector, `.599` public sync, `.598` selector, `.597`
32-bit APB `PPROT` behavior, `.594` data16 behavior, and `.589` APB sideband
behavior. It also rechecked the APB behavior/profile docs, current live APB
unsupported-residue reports, PPIF parser and APB generator paths, regression
corpus support accounting, the language-surface section, focused APB test
ownership, README, ROADMAP_V2, mdBook, task tree, Memory, Knowledge Map, and
the relevant IAL2/backend/VHDL decisions.

Live report probes kept the shipped and deferred APB surfaces separated:

- `ppif/apb_completer_multi_register_sideband_data16_protection.ppif` reports
  `sideband_data16` and keeps
  `apb_interconnect_multi_peripheral_decode_deferred`,
  `apb_additional_protection_policies_deferred`,
  `apb_remaining_widths_deferred`, and
  `apb_back_to_back_policy_deferred`.
- `ppif/apb_composition_multi_peripheral_sideband_data16_protection.ppif`
  reports requester multi-peripheral composition and keeps
  `apb_additional_protection_policies_deferred`,
  `apb_remaining_widths_deferred`, and
  `apb_back_to_back_policy_deferred`.
- `ppif/apb_requester_transfer_status.ppif` reports requester-transfer status
  support and still keeps topology, protection/strobe, alternate-width, and
  back-to-back residues appropriate to that shape.

The generated APB paths still model one transfer at a time. Requester transfer
logic waits for `PREADY` completion before leaving the transfer, completer
logic admits setup through `PSEL && !PENABLE`, and composition propagates the
selected requester/completer behavior without a public queued-admission policy.

## Why Back-To-Back Next

The public APB surface is now aligned through the sideband, data16, 32-bit
`PPROT`, profile-alias, and data16 `PPROT` work. The remaining selected APB
data16 protection reports preserve three explicit future-work families:
additional protection policies, remaining widths, and back-to-back transfer
policy.

Back-to-back is the narrowest next owner because it is the remaining APB
timing/protocol residue that cuts across multiple shipped APB layers:

- requester transfer admission and possible queued request handling,
- completer setup admission across adjacent transfers,
- fixed and multi-peripheral composition propagation and response selection,
- report/support-accounting movement for selected APB shapes.

Additional `PPROT` policy families and remaining APB widths are important, but
they extend behavior families that already have shipped bounded contracts.
Back-to-back instead decides whether a new timing policy is needed before more
APB feature completeness can be claimed.

## `.605` Readiness Questions

`.605` must decide whether APB back-to-back behavior can proceed to a public
contract-selection slice, needs report/static/public-surface prerequisites,
should be split by requester/completer/composition, or should be explicitly
deferred.

The audit must record:

- source vocabulary candidates, if any, without selecting syntax prematurely,
- the public boundary between implicit APB handshake behavior and explicit
  queued/back-to-back policy behavior,
- requester queued transfer admission expectations,
- completer setup admission expectations,
- fixed and multi-peripheral composition propagation expectations,
- report, unsupported-residue, and support-accounting movement expectations,
- diagnostics and validation coverage,
- rollback boundaries,
- direct-backend, verification-output, backend-language, and VHDL deferral.

## Deferred Work

The selector does not select additional `PPROT` predicates, global/window
policies, peripheral/interconnect-owned enforcement, runtime-programmable
policies, remaining APB widths, additional topology/composition work, AXI/AHB
return, direct backend lowering, verification-output generation,
backend-language variants, or VHDL behavior.
