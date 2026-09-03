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

sub mutate_portable_process_telemetry_derivatives($projection) {
    my %stage = map { $_ => 1 } qw(
        compile_analyze run trace_validate result_produce publish
    );
    my %artifact_path = map {
        ("outputs/$_/lifecycle-evidence.json" => 'evidence')
    } keys %stage;
    $artifact_path{"outputs/$_/lifecycle-handle.json"} = 'handle'
        for qw(compile_analyze run trace_validate result_produce);

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
    for my $index (grep { $_ != 7 && $_ != 9 } 0 .. $#$profiles) {
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
        'all nine non-telemetry-normalized profiles remain byte-exact');
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

subtest 'portable Verilator process telemetry drift admits only stable correctness' => sub {
    my $portable = $profiles->[7];
    is($portable->{ordinal}, 8, 'fixture selects exact ordinal 8');
    is(
        $portable->{selection_key},
        'portable_runtime|runtime_stream_v1|gate_candidate_v1|-|sv_portable_verilator',
        'fixture selects exact portable Verilator runtime profile',
    );
    my $portable_expected = clone($portable->{correctness_projection});
    is(
        'regression-promotion-correctness/'
            . sha256_hex(canonical($portable_expected)),
        $portable->{correctness_projection_identity},
        'portable projection has its immutable qualified identity',
    );

    my $portable_source_report = join '/', qw(
        vial qualification regression_promotion_gate evidence-v1 payload
        regression-promotion-corpus-v1 profiles
        08-f979ad45d5bda5b9f42d440578f99802e5b1e1457794fdf742bd9193da65fd2d
        measurement-report.json
    );
    open my $portable_fh, '<', $portable_source_report
        or die "cannot read tracked ordinal-8 source report: $!";
    local $/;
    my $portable_source = $json->decode(<$portable_fh>);
    close $portable_fh
        or die "cannot close tracked ordinal-8 source report: $!";
    is(
        canonical(
            FSM::VIAL::ArchitectureScaleRegressionPromotionGateProfile::current_correctness_projection_for_test({
                measurement_set => $portable_source->{report},
            }),
        ),
        canonical($portable_expected),
        'sealed seam reproduces the qualified portable source projection',
    );

    my $portable_current = clone($portable_expected);
    is(
        mutate_portable_process_telemetry_derivatives($portable_current),
        96,
        'fixture mutates the exact 24 portable telemetry derivatives per record',
    );
    isnt(canonical($portable_current), canonical($portable_expected),
        'raw portable current and qualified projections differ');
    my $stable_expected =
        FSM::VIAL::ArchitectureScaleRegressionPromotionGateProfile::_stable_correctness_projection(
            $portable_expected,
        );
    my $stable_current =
        FSM::VIAL::ArchitectureScaleRegressionPromotionGateProfile::_stable_correctness_projection(
            $portable_current,
        );
    is(canonical($stable_current), canonical($stable_expected),
        'only portable telemetry-derived lifecycle drift normalizes equal');
    isnt(canonical($portable_current), canonical($stable_current),
        'portable normalization returns a defensive projection');

    my $semantic = clone($portable_current);
    my ($run_measurement) = grep {
        ($_->{stage} // '') eq 'run'
    } @{$semantic->{record_projections}[0]{stage_measurements}};
    ++$run_measurement->{output_counts}{objects};
    isnt(
        canonical(
            FSM::VIAL::ArchitectureScaleRegressionPromotionGateProfile::_stable_correctness_projection(
                $semantic,
            ),
        ),
        canonical($stable_expected),
        'portable non-telemetry output-count drift remains visible',
    );

    my $missing = clone($portable_expected);
    @{$missing->{record_projections}[0]{artifact_records}} = grep {
        ($_->{relative_path} // '') ne
            'outputs/compile_analyze/lifecycle-evidence.json'
    } @{$missing->{record_projections}[0]{artifact_records}};
    like(captured_error(sub {
        FSM::VIAL::ArchitectureScaleRegressionPromotionGateProfile::_stable_correctness_projection(
            $missing,
        );
    }), qr/missing volatile lifecycle artifact.*compile_analyze/s,
        'missing portable volatile artifact coordinate rejects');

    my $extra = clone($portable_expected);
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
        'new portable volatile artifact coordinate rejects');

    my $duplicate_oracle = clone($portable_expected);
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
        'duplicate portable volatile oracle coordinate rejects');

    my $invalid_digest = clone($portable_expected);
    my ($compile_evidence) = grep {
        ($_->{relative_path} // '') eq
            'outputs/compile_analyze/lifecycle-evidence.json'
    } @{$invalid_digest->{record_projections}[0]{artifact_records}};
    $compile_evidence->{sha256} = undef;
    like(captured_error(sub {
        FSM::VIAL::ArchitectureScaleRegressionPromotionGateProfile::_stable_correctness_projection(
            $invalid_digest,
        );
    }), qr/volatile lifecycle artifact digest changed shape/s,
        'invalid portable lifecycle digest shape rejects');

    my $invalid_bytes = clone($portable_expected);
    my ($run_stage) = grep {
        ($_->{stage} // '') eq 'run'
    } @{$invalid_bytes->{record_projections}[0]{stage_measurements}};
    $run_stage->{output_counts}{bytes} = '1';
    like(captured_error(sub {
        FSM::VIAL::ArchitectureScaleRegressionPromotionGateProfile::_stable_correctness_projection(
            $invalid_bytes,
        );
    }), qr/volatile lifecycle stage output bytes.*not a safe nonnegative JSON integer/s,
        'non-numeric portable lifecycle byte shape rejects');

    my $reordered = clone($portable_current);
    @{$reordered->{record_projections}[0]{artifact_records}}[6, 7] =
        @{$reordered->{record_projections}[0]{artifact_records}}[7, 6];
    isnt(
        canonical(
            FSM::VIAL::ArchitectureScaleRegressionPromotionGateProfile::_stable_correctness_projection(
                $reordered,
            ),
        ),
        canonical($stable_expected),
        'portable lifecycle artifact order drift remains visible',
    );

    my $foreign = clone($portable_expected);
    $foreign->{report_contract}{backend_profile} = 'vhdl_portable_ghdl';
    my $foreign_raw = canonical($foreign);
    is(
        canonical(
            FSM::VIAL::ArchitectureScaleRegressionPromotionGateProfile::_stable_correctness_projection(
                $foreign,
            ),
        ),
        $foreign_raw,
        'portable schema with a foreign backend remains byte-exact',
    );
};

done_testing;
