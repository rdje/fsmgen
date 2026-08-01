# IAL2 APB Data16 PPROT Effects Readiness Audit

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.601`

Date: 2026-06-27

## Summary

`.601` audits readiness for sideband data16 APB `PPROT` policy effects and
selects `IAL2-FEATURE-COMPLETENESS-FRONTIER.602`, public contract selection
for that bounded surface.

The audit changes no parser behavior, generator behavior, source samples,
support-accounting catalog entries, validation behavior, generated artifacts,
report schemas, schedule/check JSON, semantic JSON, HDL/runtime behavior,
suffix acceptance, direct backend lowering, verification-output generation,
backend-language variants, APB behavior, AXI behavior, AHB behavior, or VHDL
behavior.

## Current Boundary

Sideband data16 APB completer and composition aliases already lower through the
same sideband machinery as the 32-bit APB policy family:

- `PPROT` is declared at width 3 and sampled during APB setup;
- `PSTRB` is declared at width 2 and drives two byte lanes;
- 16-bit `PWDATA`, `PRDATA`, and register data are already carried through
  generated IAL1/IAL0;
- multi-register data16 completers use two-byte register alignment; and
- data16 reports use `apb_remaining_widths_deferred`.

The current fail-closed policy boundary is explicit in
`FSM::IAL2::ProtocolIntent::ApbCompleter`:

```text
APB completer IAL2 contract access-policy requires selected 32-bit APB data width in this slice
```

A temporary `/tmp` candidate that inserted register-local `(access-policy ...)`
clauses into `ppif/apb_completer_multi_register_sideband_data16.ppif` failed at
that exact guard and did not expose parser, IAL1, IAL0, report-schema,
composition, direct-backend, or VHDL prerequisites.

## Readiness Finding

The parser already accepts and preserves register-local access-policy clauses
before the APB completer validator rejects the data16 shape. The generated
completer policy helpers are data-width aware: allowed writes use the existing
byte-lane write generator, denied writes bypass storage updates, denied reads
drive the normal error completion path, and policy expressions use sampled
`prot_q` independently of data width.

The report helpers are also mostly width-neutral. `protection_policy` metadata
does not depend on the data width, and the residue switch already chooses
`apb_additional_protection_policies_deferred` when a storage register has an
access policy. The data16 width policy can continue to report 16-bit data,
2-bit strobes, two byte lanes, and remaining-width residue.

Composition readiness is similarly local. Fixed and multi-peripheral
composition already detect access policies in child completers, propagate
`PPROT/PSTRB`, and report policy ownership as completer/peripheral-owned.
Interconnect-owned enforcement remains out of scope.

## Selection

`.602` shall select the public data16 PPROT policy contract before behavior
changes. It must settle:

- source sample names and whether the combined surface is spelled
  `sideband_data16_protection` or another exact suffix;
- whether the first data16 policy syntax reuses the `.597` register-local
  `allow` / `require (privileged 0|1)` vocabulary unchanged;
- whether the first behavior is limited to sideband-aware data16 multi-register
  completers and matching fixed/multi-peripheral composition shapes;
- exact denied read/write behavior for 16-bit `PRDATA` and two-lane `PSTRB`;
- report and residue migration for data16 policy samples;
- diagnostics for unsupported single-register, no-sideband, non-data16, or
  broader policy shapes;
- support-accounting, docs, mdBook, and Knowledge Map updates;
- validation and rollback; and
- direct-backend, verification-output, backend-language, and VHDL deferral.

## Non-Goals

`.601` and `.602` do not implement data16 policy behavior. Additional PPROT
predicates, global/window/peripheral policies, interconnect-owned enforcement,
back-to-back transfer policy, additional APB topology behavior, AXI/AHB return,
direct backend lowering, verification-output generation, backend-language
variants, and VHDL remain deferred unless a later exact owner selects them.

## Validation

The audit validation was:

```bash
perl -MFile::Path=make_path,remove_tree -MFile::Temp=tempfile -we '
my $artifact_dir = q{.artifacts/ial2-apb-data16-probe};
make_path($artifact_dir);
END { remove_tree($artifact_dir) if -d $artifact_dir; }
local $/;
open my $input, q{<}, q{ppif/apb_completer_multi_register_sideband_data16.ppif}
    or die $!;
my $source = <$input>;
close $input;
$source =~ s/\(data reg0_data_q width 16 reset 0\)/(data reg0_data_q width 16 reset 0)\n        (access-policy\n          (read require (privileged 1))\n          (write allow))/ or die q{reg0 substitution failed\n};
$source =~ s/\(data reg1_data_q width 16 reset 0\)/(data reg1_data_q width 16 reset 0)\n        (access-policy\n          (read allow)\n          (write require (privileged 0)))/ or die q{reg1 substitution failed\n};
my ($fixture, $path) = tempfile(
    q{fsmgen-data16-policy-XXXX},
    SUFFIX => q{.ppif},
    DIR => $artifact_dir,
    UNLINK => 1,
);
print {$fixture} $source;
close $fixture;
my $output = qx(./bin/fsmgen --quiet --emit-schedule-json $path 2>&1);
my $status = $? >> 8;
print "candidate_status=$status\n";
print $output;
'
bash knowledge-map/scripts/gen_knowledge_map.sh
bash knowledge-map/scripts/check_knowledge_map.sh
mdbook build docs/book
git --no-pager diff --check
scripts/check_doctrines.sh
```

## Rollback

Rollback is doc-only: revert this audit, its fact card, task-tree frontier
updates, README, ROADMAP_V2, mdBook, Memory, and generated Knowledge Map
changes. The `.597` 32-bit policy behavior, `.599` public profile sync, and
`.600` selector remain unchanged.
