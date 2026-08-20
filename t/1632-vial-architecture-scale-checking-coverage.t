#!/usr/bin/env perl

use strict;
use warnings;

use File::Spec;
use FindBin;
use JSON::PP ();
use Test::More;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::VIAL::ArchitectureScaleCheckingState;
use FSM::VIAL::Parser;

my $class = 'FSM::VIAL::ArchitectureScaleCheckingState';
my $repo_root = File::Spec->catdir($FindBin::Bin, '..');
my $json = JSON::PP->new->canonical(1)->utf8(1);
my $reference_hial = slurp_raw(repo_path('ppif/ahb_lite_subordinate.ppif'));
my %selected = (
    coverpoints => {
        gate_candidate_v1 => 256,
        qualification_candidate_v1 => 8_192,
        limit_v1 => 65_536,
        over_limit_v1 => 65_537,
    },
    bins_and_cross_tuples => {
        gate_candidate_v1 => 4_096,
        qualification_candidate_v1 => 262_144,
        limit_v1 => 1_000_000,
        over_limit_v1 => 1_000_001,
    },
);

sub construction {
    my ($axis, $level) = @_;
    return $class->construct({
        primary_axis => $axis,
        level => $level,
        reference_hial_text => $reference_hial,
    });
}

subtest 'coverage gates execute exact packed static-domain vectors' => sub {
    my %expected = (
        coverpoints => {
            source_bytes => 28_987,
            coverpoints => 256,
            bins => 256,
            crosses => 0,
            tuples => 0,
            vector_bytes => 32,
            vector_sha256 =>
                'af9613760f72635fbdb44a5a0a63c39f12af30f950a6ee5c971be188e89c4051',
            domain_sha256 =>
                '0df1181ec9f12f1a8c6ca8b8e1ebad9f74ac648a6054ebf25251bc024a1ff009',
            evaluation =>
                'checking-evaluation/d8e45c23dfbb98b9fce5803704d73576bb3fd047a7efe9ddafdcf41383c2ce98',
            rerun =>
                'rerun/038e9850ce6cb4d03a0275481bf592fe58d992be1a6d6cfb0d846a62bf4f08d5',
        },
        bins_and_cross_tuples => {
            source_bytes => 8_551,
            coverpoints => 3,
            bins => 127,
            crosses => 1,
            tuples => 3_969,
            vector_bytes => 512,
            vector_sha256 =>
                '9f56cda75fefeab90f6fa5d5ddc9601544b121732c5ecccab32e631060453a5d',
            domain_sha256 =>
                '713e354cf189200b45cac300f00ee225e6e14625fda7b2f9145d4b68253c5de5',
            evaluation =>
                'checking-evaluation/2da7cd278cf6227235f0cc56cd526ef42bb3c7ac20274d5837c07a889e760601',
            rerun =>
                'rerun/804db7df765dfdb126a6d4b281fc3fde6a1f39c312fc5447290c1947b752037b',
        },
    );

    for my $axis (sort keys %expected) {
        my $constructed = construction($axis, 'gate_candidate_v1');
        ok($constructed->{ok}, "$axis gate constructs ordinary VIAL source");
        my ($vial) = grep { $_->{role} eq 'vial_source' }
            @{$constructed->{inputs}};
        is(length($vial->{content}), $expected{$axis}{source_bytes},
            "$axis gate freezes its compact source size");
        my $evaluation = $class->evaluate({construction => $constructed});
        ok($evaluation->{ok}, "$axis gate passes the packed coverage oracle");
        diag($json->encode($evaluation->{diagnostics})) unless $evaluation->{ok};
        is($evaluation->{status}, 'accepted', "$axis gate is accepted");
        is($evaluation->{evaluation_identity}, $expected{$axis}{evaluation},
            "$axis gate evaluation identity is frozen");
        is($evaluation->{rerun_identity}, $expected{$axis}{rerun},
            "$axis independent-route identity is frozen");
        is($evaluation->{metrics}{$axis}, $selected{$axis}{gate_candidate_v1},
            "$axis gate reaches its selected metric");

        my $coverage = $evaluation->{oracle_evidence}{coverage};
        is($evaluation->{oracle_evidence}{oracle}, 'coverage',
            "$axis uses only the coverage oracle");
        is($coverage->{schema},
            'fsmgen.vial_architecture_scale_coverage_oracle_evidence.v1',
            "$axis uses the closed coverage-evidence schema");
        is($coverage->{program}, 'one_sample_packed_static_domain_vector_v1',
            "$axis executes the selected one-sample program");
        is($coverage->{coverpoints}, $expected{$axis}{coverpoints},
            "$axis preserves every authored coverpoint");
        is($coverage->{authored_bins}, $expected{$axis}{bins},
            "$axis preserves every authored bin");
        is($coverage->{authored_crosses}, $expected{$axis}{crosses},
            "$axis preserves only authored crosses");
        is($coverage->{static_cross_tuples}, $expected{$axis}{tuples},
            "$axis reconstructs the exact static tuple product");
        is($coverage->{static_domain_entries},
            $selected{$axis}{gate_candidate_v1},
            "$axis reconstructs the exact selected static domain");
        is($coverage->{hit_entries}, $coverage->{static_domain_entries},
            "$axis single sample hits every static entry");
        is($coverage->{packed_vector_bytes}, $expected{$axis}{vector_bytes},
            "$axis uses exactly one bit per static entry");
        is($coverage->{packed_vector_sha256},
            $expected{$axis}{vector_sha256},
            "$axis packed vector digest is frozen");
        is($coverage->{packed_vector_sha256},
            $coverage->{expected_vector_sha256},
            "$axis vector matches the independent expectation");
        is($coverage->{static_domain_sha256},
            $expected{$axis}{domain_sha256},
            "$axis ordered static-domain digest is frozen");
        is($coverage->{static_domain_sha256},
            $coverage->{expected_static_domain_sha256},
            "$axis authored order matches independent reconstruction");
        ok($coverage->{byte_equal_expected}
            && $coverage->{static_domain_order_preserved}
            && $coverage->{all_authored_bins_matched}
            && $coverage->{all_static_cross_tuples_hit}
            && $coverage->{illegal_match_rejected}
            && $coverage->{ignore_match_excluded}
            && $coverage->{mutation_rejected}
            && $coverage->{order_mutation_rejected}
            && $coverage->{no_undeclared_domain_entries},
            "$axis closes hit, order, classification, and mutation proofs");
        ok($evaluation->{claims}{axis_level_owned}
            && !$evaluation->{claims}{capability_claimed}
            && !$evaluation->{claims}{support_claimed}
            && !$evaluation->{claims}{performance_claimed}
            && !$evaluation->{claims}{capacity_claimed}
            && !$evaluation->{claims}{backend_authority}
            && !$evaluation->{claims}{runtime_authority},
            "$axis remains qualification-only without product claims");
        my $validated = $class->validate_evaluation({
            construction => $constructed,
            evaluation => $evaluation,
        });
        is($json->encode($validated), $json->encode($evaluation),
            "$axis canonical evaluation validates byte-for-byte");
    }
};

subtest 'million-entry static domain is a bounded exact all-hit vector' => sub {
    my $constructed = construction('bins_and_cross_tuples', 'limit_v1');
    ok($constructed->{ok}, 'million-entry static-domain source constructs');
    my ($vial) = grep { $_->{role} eq 'vial_source' }
        @{$constructed->{inputs}};
    is(length($vial->{content}), 62_841,
        'million-entry authored static domain is exactly 62841 source bytes');
    my $evaluation = $class->evaluate({construction => $constructed});
    ok($evaluation->{ok}, 'million-entry packed coverage proof passes');
    diag($json->encode($evaluation->{diagnostics})) unless $evaluation->{ok};
    is($evaluation->{evaluation_identity},
        'checking-evaluation/1cce1e6ec2ffd064832aefae7a2f07635c263aeab98791b8b9b4b375cf7f5ace',
        'million-entry evaluation identity is frozen');
    is($evaluation->{rerun_identity},
        'rerun/cacd20ac0432262aa379e96ce951a6af4a45d10de49bae1cc2444e5cd24f12bf',
        'million-entry independent-route identity is frozen');
    my $coverage = $evaluation->{oracle_evidence}{coverage};
    is($coverage->{authored_bins}, 1_999,
        'two 999-bin points plus one independent bin are explicit');
    is($coverage->{static_cross_tuples}, 998_001,
        'the authored 999-by-999 cross has its exact static product');
    is($coverage->{static_domain_entries}, 1_000_000,
        'bins plus tuples total exactly one million');
    is($coverage->{hit_entries}, 1_000_000,
        'one sample hits every one-million-entry domain member');
    is($coverage->{packed_vector_bytes}, 125_000,
        'one million entries occupy exactly 125000 packed bytes');
    is($coverage->{packed_vector_sha256},
        'ae450c2064c76df34378b11784d1d24bde068c9b94dab52cc41fcea3be558582',
        'million-bit all-one vector digest is frozen');
    is($coverage->{static_domain_sha256},
        '696d5310f3fb4d16332ff8c72d178d4391b111b49c973b599084f08841562f23',
        'million-entry authored-order digest is frozen');
};

subtest 'coverpoint nominal limits report the envelope and real parser boundary' => sub {
    my $envelope_diagnostic = {
        code => 'VIAL_SCALE_INPUT_ERROR',
        severity => 'error',
        message => 'input 1 exceeds the bounded construction envelope',
        path => '/inputs/1/content',
    };
    for my $level (qw(limit_v1 over_limit_v1)) {
        my $constructed = construction('coverpoints', $level);
        ok(!$constructed->{ok}, "$level is not admitted past the envelope");
        is_deeply($constructed->{diagnostics}, [$envelope_diagnostic],
            "$level returns the exact construction diagnostic");
        is_deeply($constructed->{inputs}, [],
            "$level retains no oversized source");
        is($constructed->{workload_identity}, undef,
            "$level claims no identity for unadmitted source");
        is($constructed->{specification}{requested_counts}{coverpoints},
            $selected{coverpoints}{$level},
            "$level retains its declared selected count");
        my $evaluation = $class->evaluate({construction => $constructed});
        ok($evaluation->{ok}, "$level satisfies the selected envelope result");
        is($evaluation->{status}, 'envelope_unconstructible',
            "$level is explicitly unconstructible");
        is($evaluation->{observed_outcome}, 'not_constructed',
            "$level claims no product outcome");
        is_deeply($evaluation->{diagnostics}, [$envelope_diagnostic],
            "$level preserves the exact fixture diagnostic");
        is_deeply([values %{$evaluation->{stage_identities}}],
            [(undef) x 4], "$level claims no product-stage identity");
        is_deeply([map { $_->{code} }
                @{$evaluation->{contract_discrepancies}}],
            [qw(VIAL_SCALE_LIMIT_INTERACTION VIAL_SCALE_ROUTE_BOUNDARY)],
            "$level records both decision-0072 facts");
        like($evaluation->{contract_discrepancies}[0]{message},
            qr/fixture bound and not a product limit/,
            "$level distinguishes the fixture envelope from a product cap");
        like($evaluation->{contract_discrepancies}[1]{message},
            qr/accepts 9524 in 1048467 source bytes and rejects 9525 in 1048577/,
            "$level records the exact parser-route boundary");
        is_deeply([map { $_->{repair_owner} }
                @{$evaluation->{contract_discrepancies}}],
            [('HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.4') x 2],
            "$level routes both cap records to the resource-cap owner");
        my $built = eval { $class->build({construction => $constructed}); 1 };
        ok(!$built, "$level cannot be built without admitted source");
        like($@, qr/no admitted source to build/,
            "$level build refusal names the absent source");
    }
};

subtest 'one further static entry returns only the execution coverage diagnostic' => sub {
    my $constructed = construction('bins_and_cross_tuples', 'over_limit_v1');
    ok($constructed->{ok}, 'one-over static-domain source is admitted');
    my ($vial) = grep { $_->{role} eq 'vial_source' }
        @{$constructed->{inputs}};
    is(length($vial->{content}), 62_870,
        'one extra authored bin adds exactly 29 source bytes');
    my $evaluation = $class->evaluate({construction => $constructed});
    ok($evaluation->{ok}, 'one-over outcome is the selected rejection');
    is($evaluation->{status}, 'expected_rejection',
        'one-over static domain has expected-rejection status');
    is_deeply($evaluation->{diagnostics}, [{
        bridge_fact_paths => [],
        code => 'VIAL_EXECUTION_LIMIT_ERROR',
        message => 'coverage_bins_and_cross_tuples exceeds the limit 1000000',
        phase => 'limit',
        related => [],
        schema_version => 1,
        semantic_path => '/coverage',
        severity => 'error',
        source_location => undef,
    }], 'one-over static domain freezes its complete /coverage diagnostic');
    is($evaluation->{metrics}{bins_and_cross_tuples}, 1_000_001,
        'semantic stage contains exactly one further static entry');
    ok(defined($evaluation->{stage_identities}{semantic_ir_sha256})
        && defined($evaluation->{stage_identities}{bridge_manifest_sha256})
        && !defined($evaluation->{stage_identities}{execution_ir_sha256})
        && !defined($evaluation->{stage_identities}{plan_sha256}),
        'rejection exposes only SemanticIR and bridge identities');
    is($evaluation->{oracle_evidence}{oracle}, 'none',
        'rejected static domain cannot claim the vector oracle ran');
};

subtest 'hostile coverage structure and report mutation fail closed' => sub {
    my $constructed = construction(
        'bins_and_cross_tuples', 'gate_candidate_v1',
    );
    my $built = $class->build({construction => $constructed});
    ok($built->{ok}, 'canonical gate reaches ExecutionIR for hostile-state proof');
    my $execution = $built->{execution_ir}->as_hashref;
    $execution->{coverage}{coverpoints}[0]{bins}[0]{classification} = 'illegal';
    my ($evidence, $diagnostics) = $class->_test_coverage_oracle(
        $constructed->{specification}, $execution,
    );
    ok(@$diagnostics, 'illegal-bin mutation fails the provider-free oracle');
    is($diagnostics->[0]{code}, 'VIAL_SCALE_CHECKING_COVERAGE_ERROR',
        'hostile mutation uses the stable coverage diagnostic');
    like($diagnostics->[0]{message}, qr/exact authored static domain/,
        'hostile rejection names the authored domain');
    ok(!$evidence->{byte_equal_expected}
        && !$evidence->{static_domain_order_preserved}
        && !$evidence->{all_authored_bins_matched}
        && !$evidence->{no_undeclared_domain_entries},
        'hostile evidence cannot claim any positive domain proof');

    my $evaluation = $class->evaluate({construction => $constructed});
    my $mutated = clone_json($evaluation);
    ++$mutated->{oracle_evidence}{coverage}{hit_entries};
    my $accepted = eval {
        $class->validate_evaluation({
            construction => $constructed,
            evaluation => $mutated,
        });
        1;
    };
    ok(!$accepted, 'post-identity hit-vector mutation fails closed');
    like($@, qr/evaluation is not canonical/,
        'report mutation rejection names canonical regeneration');
};

subtest 'coverage construction and staging remain sealed and residue-free' => sub {
    my $constructed = construction('coverpoints', 'gate_candidate_v1');
    my $forged = clone_json($constructed);
    my ($vial) = grep { $_->{role} eq 'vial_source' } @{$forged->{inputs}};
    $vial->{content} .= ' ';
    my $accepted_forgery = eval { $class->evaluate({construction => $forged}); 1 };
    ok(!$accepted_forgery, 'post-identity generated source mutation fails closed');
    like($@, qr/construction is not canonical/,
        'generated-source mutation rejection names canonical regeneration');

    my $stage_abs = repo_path($constructed->{staging_identity});
    ok(!-e $stage_abs && !-l $stage_abs, 'coverage stage begins absent');
    my $success = $class->with_staging({
        repository_root => $repo_root,
        construction => $constructed,
        consumer => sub {
            my ($context) = @_;
            ok(-d $context->{staging_root},
                'consumer sees the repository-volume coverage stage');
        },
    });
    ok($success->{ok} && $success->{same_volume} && $success->{removed},
        'successful coverage staging proves same-volume cleanup');
    ok(!-e $stage_abs && !-l $stage_abs,
        'successful coverage staging leaves no residue');
    my $failed = $class->with_staging({
        repository_root => $repo_root,
        construction => $constructed,
        consumer => sub { die "intentional coverage consumer failure\n" },
    });
    ok(!$failed->{ok}, 'consumer failure is reported');
    is($failed->{diagnostics}[0]{code}, 'VIAL_SCALE_CONSUMER_ERROR',
        'consumer failure keeps the stable diagnostic family');
    ok(!-e $stage_abs && !-l $stage_abs,
        'failed coverage staging also leaves no residue');

    my $unconstructible = construction('coverpoints', 'limit_v1');
    my $staged = eval {
        $class->with_staging({
            repository_root => $repo_root,
            construction => $unconstructible,
            consumer => sub { die "must not run\n" },
        });
        1;
    };
    ok(!$staged, 'unconstructible source cannot enter staging');
    like($@, qr/no admitted source to stage/,
        'staging refusal names the absent source');
};

subtest 'qualification and parser boundary are exact and RAM-guarded' => sub {
    plan skip_all => 'set FSMGEN_VIAL_SCALE_EXACT=1 under'
        . ' scripts/run_with_ram_guard.sh for complete coverage route proof'
        unless $ENV{FSMGEN_VIAL_SCALE_EXACT};

    for my $shape (
        [coverpoints => 'qualification_candidate_v1'],
        [bins_and_cross_tuples => 'qualification_candidate_v1'],
    ) {
        my ($axis, $level) = @$shape;
        my $constructed = construction($axis, $level);
        ok($constructed->{ok}, "$axis/$level constructs");
        my $evaluation = $class->evaluate({construction => $constructed});
        ok($evaluation->{ok}, "$axis/$level passes its exact packed oracle");
        diag($json->encode($evaluation->{diagnostics})) unless $evaluation->{ok};
        is($evaluation->{metrics}{$axis}, $selected{$axis}{$level},
            "$axis/$level reaches its selected count");
        is($evaluation->{oracle_evidence}{coverage}{hit_entries},
            $evaluation->{oracle_evidence}{coverage}{static_domain_entries},
            "$axis/$level hits its complete static domain");
    }

    my %boundary = (
        9_524 => {bytes => 1_048_467, ok => 1},
        9_525 => {bytes => 1_048_577, ok => 0},
    );
    for my $count (sort { $a <=> $b } keys %boundary) {
        my $source = $class->_test_render_coverage_source(
            'coverpoints', 'gate_candidate_v1', $count,
        );
        is(length($source), $boundary{$count}{bytes},
            "$count-coverpoint source has its exact measured byte count");
        my $result = FSM::VIAL::Parser->check_source({
            text => $source,
            source_name =>
                'generated/vial-scale/checking_state/checking_state.vial',
            source_catalog => {},
        });
        is($result->{ok} ? 1 : 0, $boundary{$count}{ok},
            "$count-coverpoint parser outcome is exact");
        if (!$boundary{$count}{ok}) {
            is_deeply($result->{diagnostics}, [{
                code => 'VIAL_LIMIT_ERROR',
                message => 'source exceeds the 1048576-byte limit',
                notes => [],
                phase => 'limit',
                schema_version => 1,
                semantic_path => '/',
                severity => 'error',
                source_location => {
                    source_name =>
                        'generated/vial-scale/checking_state/checking_state.vial',
                    start_byte => 0,
                    end_byte_exclusive => 0,
                    start_line => 1,
                    end_line => 1,
                    start_column => 1,
                    end_column => 1,
                },
            }], 'one-over parser boundary returns its exact diagnostic');
        }
    }
};

done_testing();

sub repo_path {
    my ($relative) = @_;
    return File::Spec->catfile($repo_root, split m{/}, $relative);
}

sub slurp_raw {
    my ($path) = @_;
    open my $fh, '<:raw', $path or die "cannot read $path: $!";
    local $/;
    my $text = <$fh>;
    close $fh or die "cannot close $path: $!";
    return $text;
}

sub clone_json {
    my ($value) = @_;
    return $json->decode($json->encode($value));
}

package FSM::VIAL::ArchitectureScaleCheckingState;

sub _test_coverage_oracle {
    my ($class, $specification, $execution_ir) = @_;
    return _evaluate_coverage_state($specification, $execution_ir);
}

sub _test_render_coverage_source {
    my ($class, $axis, $level, $count) = @_;
    return _render_coverage_source($axis, $level, $count);
}
