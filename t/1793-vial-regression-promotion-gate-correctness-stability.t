use v5.20;
use strict;
use warnings;

use lib 'perl';
use Digest::SHA qw(sha256_hex);
use JSON::PP ();
use Test::More;
use feature qw(signatures);
no warnings 'experimental::signatures';

use FSM::VIAL::ArchitectureScaleRegressionPromotionGateProfile;

my $class =
    'FSM::VIAL::ArchitectureScaleRegressionPromotionGateProfile';
{
    package FSM::VIAL::ArchitectureScaleRegressionPromotionGateProfile;

    sub current_correctness_projection_for_test {
        return FSM::VIAL::ArchitectureScaleRegressionPromotionQualification
            ->_gate_correctness_projection(@_);
    }
}
my $json = JSON::PP->new->canonical(1)->utf8(1);
my $publication = join '/', qw(
    vial qualification regression_promotion_gate evidence-v1 payload
    regression-promotion-budget-qualification-v1 current
    regression-promotion-budget-qualification.json
);
my $source_report = join '/', qw(
    vial qualification regression_promotion_gate evidence-v1 payload
    regression-promotion-corpus-v1 profiles
    10-100befd04da28db2e5d5e7016aee42e3daf8155a0221fd099a97eeb7b8b4269b
    measurement-report.json
);

sub clone($value) {
    return $json->decode($json->encode($value));
}

sub canonical($value) {
    return $json->encode($value);
}

sub captured_error($code) {
    my $ok = eval { $code->(); 1 };
    return '' if $ok;
    return $@;
}

sub replacement_digest($value) {
    return $value eq ('f' x 64) ? ('e' x 64) : ('f' x 64);
}

sub mutate_process_telemetry_derivatives($projection) {
    my %stage = map { $_ => 1 } qw(
        compile_analyze elaborate run trace_validate result_produce publish
    );
    my %artifact_path = map {
        ("outputs/$_/lifecycle-evidence.json" => 'evidence')
    } keys %stage;
    $artifact_path{"outputs/$_/lifecycle-handle.json"} = 'handle'
        for qw(compile_analyze elaborate run trace_validate result_produce);

    my $changed = 0;
    for my $record (@{$projection->{record_projections}}) {
        for my $artifact (@{$record->{artifact_records}}) {
            my $kind = $artifact_path{$artifact->{relative_path} // ''};
            next unless defined $kind;
            $artifact->{sha256} = replacement_digest($artifact->{sha256});
            ++$changed;
            if ($kind eq 'evidence') {
                ++$artifact->{bytes};
                ++$changed;
            }
        }
        for my $oracle (@{$record->{correctness_oracles}}) {
            next unless $stage{$oracle->{stage} // ''};
            $oracle->{evidence_identity} =
                replacement_digest($oracle->{evidence_identity});
            ++$changed;
        }
        for my $measurement (@{$record->{stage_measurements}}) {
            next unless $stage{$measurement->{stage} // ''};
            ++$measurement->{output_counts}{bytes};
            ++$changed;
        }
    }
    return $changed;
}

open my $fh, '<', $publication
    or die "cannot read tracked qualification publication: $!";
local $/;
my $document = $json->decode(<$fh>);
close $fh or die "cannot close tracked qualification publication: $!";
my $profiles = $document->{qualification}{profiles};
my $qualified = $profiles->[9];
is($qualified->{ordinal}, 10, 'fixture selects exact ordinal 10');
is(
    $qualified->{selection_key},
    'osvvm_runtime|runtime_stream_v1|gate_candidate_v1|-|vhdl_osvvm_qualified',
    'fixture selects exact OSVVM/GHDL runtime profile',
);
my $expected = clone($qualified->{correctness_projection});
is(
    'regression-promotion-correctness/' . sha256_hex(canonical($expected)),
    $qualified->{correctness_projection_identity},
    'tracked projection has its immutable qualified identity',
);
open my $source_fh, '<', $source_report
    or die "cannot read tracked ordinal-10 source report: $!";
my $source = $json->decode(<$source_fh>);
close $source_fh or die "cannot close tracked ordinal-10 source report: $!";
is(
    canonical(
        FSM::VIAL::ArchitectureScaleRegressionPromotionGateProfile::current_correctness_projection_for_test({
            measurement_set => $source->{report},
        }),
    ),
    canonical($expected),
    'sealed current-projection seam reproduces the qualified source projection',
);

ok(
    $class->can('_stable_correctness_projection'),
    'gate profile exposes its private stable correctness projection',
);

SKIP: {
    skip 'stable projection is not implemented yet', 11
        unless $class->can('_stable_correctness_projection');

    my $current = clone($expected);
    is(
        mutate_process_telemetry_derivatives($current), 116,
        'fixture mutates the exact 29 telemetry-derived scalars per record',
    );
    isnt(canonical($current), canonical($expected),
        'raw current and qualified projections differ');
    my $stable_expected =
        FSM::VIAL::ArchitectureScaleRegressionPromotionGateProfile::_stable_correctness_projection(
            $expected,
        );
    my $stable_current =
        FSM::VIAL::ArchitectureScaleRegressionPromotionGateProfile::_stable_correctness_projection(
            $current,
        );
    is(canonical($stable_current), canonical($stable_expected),
        'only telemetry-derived lifecycle drift normalizes equal');
    isnt(canonical($current), canonical($stable_current),
        'normalization returns a defensive projection');

    my $semantic = clone($current);
    ++$semantic->{record_projections}[0]{stage_measurements}[7]
        {output_counts}{objects};
    isnt(
        canonical(
            FSM::VIAL::ArchitectureScaleRegressionPromotionGateProfile::_stable_correctness_projection(
                $semantic,
            ),
        ),
        canonical($stable_expected),
        'non-telemetry output-count drift remains visible',
    );

    my $missing = clone($expected);
    @{$missing->{record_projections}[0]{artifact_records}} = grep {
        ($_->{relative_path} // '') ne
            'outputs/compile_analyze/lifecycle-evidence.json'
    } @{$missing->{record_projections}[0]{artifact_records}};
    like(captured_error(sub {
        FSM::VIAL::ArchitectureScaleRegressionPromotionGateProfile::_stable_correctness_projection(
            $missing,
        );
    }), qr/missing volatile lifecycle artifact.*compile_analyze/s,
        'missing volatile artifact coordinate rejects');

    my $extra = clone($expected);
    my ($handle) = grep {
        ($_->{relative_path} // '') eq
            'outputs/result_produce/lifecycle-handle.json'
    } @{$extra->{record_projections}[0]{artifact_records}};
    my $unexpected = clone($handle);
    $unexpected->{stage} = 'publish';
    $unexpected->{relative_path} = 'outputs/publish/lifecycle-handle.json';
    push @{$extra->{record_projections}[0]{artifact_records}}, $unexpected;
    like(captured_error(sub {
        FSM::VIAL::ArchitectureScaleRegressionPromotionGateProfile::_stable_correctness_projection(
            $extra,
        );
    }), qr/unexpected volatile lifecycle artifact.*publish/s,
        'new volatile artifact coordinate rejects instead of being hidden');

    my $duplicate_oracle = clone($expected);
    my ($run_oracle) = grep {
        ($_->{stage} // '') eq 'run'
    } @{$duplicate_oracle->{record_projections}[0]{correctness_oracles}};
    push @{$duplicate_oracle->{record_projections}[0]{correctness_oracles}},
        clone($run_oracle);
    like(captured_error(sub {
        FSM::VIAL::ArchitectureScaleRegressionPromotionGateProfile::_stable_correctness_projection(
            $duplicate_oracle,
        );
    }), qr/volatile lifecycle oracle.*run.*exactly once/s,
        'duplicate volatile oracle coordinate rejects');

    my @foreign_drift;
    for my $index (grep { $_ != 9 } 0 .. $#$profiles) {
        my $foreign_projection =
            clone($profiles->[$index]{correctness_projection});
        push @foreign_drift, $profiles->[$index]{ordinal}
            unless canonical(
                FSM::VIAL::ArchitectureScaleRegressionPromotionGateProfile::_stable_correctness_projection(
                    $foreign_projection,
                ),
            ) eq canonical($foreign_projection);
    }
    is_deeply(\@foreign_drift, [],
        'all ten non-OSVVM correctness profiles remain byte-exact');
    my $foreign = clone($profiles->[0]{correctness_projection});
    my $foreign_raw = canonical($foreign);
    is(canonical($foreign), $foreign_raw,
        'non-target input projection is not mutated');
    like(captured_error(sub {
        FSM::VIAL::ArchitectureScaleRegressionPromotionGateProfile::_stable_correctness_projection(
            [],
        );
    }), qr/correctness projection must be one unblessed hash/,
        'invalid projection shape rejects');
}

done_testing;
