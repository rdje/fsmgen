#!/usr/bin/env perl

use strict;
use warnings;

use bytes ();
use Digest::SHA qw(sha256_hex);
use File::Spec;
use FindBin;
use JSON::PP ();
use Test::More;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::VIAL::ArchitectureScaleExecutionGraph;
use FSM::VIAL::Parser;

my $class = 'FSM::VIAL::ArchitectureScaleExecutionGraph';
my $json = JSON::PP->new->canonical(1)->utf8(1);
my $reference_hial = slurp_raw(repo_path('ppif/ahb_lite_subordinate.ppif'));
my $complete_reset = ' (reset b 1)';
my %expected = (
    cap_bytes => 16_777_216,
    minimum_bytes => 16_777_217,
    operations => 48_851,
    hial_bytes => 1_326,
    vial_bytes => 587_434,
    workload_identity =>
        'workload/4acdb54e29ae1d378a272bd6a0a07e164c4443dcad39bfc538a370751c5569a9',
    hial_sha256 =>
        '9a1d7a591d3ec9a3419b07f05bc83aefa2b213b2cae45f5332f9349ffa27056c',
    vial_sha256 =>
        '499cf6b0747d312a6593865fbc3fcde5211083c08fd659d504babefd83eae89a',
    semantic_sha256 =>
        '89ee52afc611520db4bbd48f31b76b8d042a2115038bfe43cbe3fb09a0e94ae1',
);
my $expected_diagnostic = {
    schema_version => 1,
    severity => 'error',
    code => 'VIAL_EXECUTION_LIMIT_ERROR',
    phase => 'limit',
    message => 'serialized_plan_bytes exceeds the limit 16777216',
    semantic_path => '/plan',
    source_location => undef,
    bridge_fact_paths => [],
    related => [],
};

sub construction {
    return $class->construct({
        primary_axis => 'serialized_plan_bytes',
        level => 'over_limit_v1',
        reference_hial_text => $reference_hial,
    });
}

sub limit_construction {
    return $class->construct({
        primary_axis => 'serialized_plan_bytes',
        level => 'limit_v1',
        reference_hial_text => $reference_hial,
    });
}

subtest 'over-limit construction appends exactly one complete reset' => sub {
    my $first = construction();
    my $second = construction();
    ok($first->{ok}, 'over-limit construction satisfies the workload contract');
    diag($json->encode($first->{diagnostics})) unless $first->{ok};
    is($json->encode($second), $json->encode($first),
        'independent over-limit construction is byte-identical');
    is_deeply(
        $first->{specification}{requested_counts},
        {
            minimum_bytes => $expected{minimum_bytes},
            declared_cap_bytes => $expected{cap_bytes},
            construction_rule => 'first_complete_valid_record_over_boundary',
        },
        'construction retains the exact first-complete-record contract',
    );
    is($first->{workload_identity}, $expected{workload_identity},
        'over-limit construction identity is exact');

    my %input = map { $_->{role} => $_ } @{$first->{inputs}};
    is_deeply([sort keys %input], [qw(hial_source vial_source)],
        'construction contains only checked HIAL and generated VIAL source');
    is(bytes::length($input{hial_source}{content}), $expected{hial_bytes},
        'checked-AHB source byte count is frozen');
    is(sha256_hex($input{hial_source}{content}), $expected{hial_sha256},
        'checked-AHB source identity is frozen');
    is($input{vial_source}{relative_path},
        'generated/vial-scale/execution_graph/p16m.vial',
        'over-limit source retains the exact limit route');
    is(bytes::length($input{vial_source}{content}), $expected{vial_bytes},
        'generated over-limit VIAL byte count is exact');
    is(sha256_hex($input{vial_source}{content}), $expected{vial_sha256},
        'generated over-limit VIAL identity is frozen');
    is(scalar(() = $input{vial_source}{content} =~ /\(reset b 1\)/g),
        $expected{operations}, 'source contains exactly 48,851 real resets');

    my ($limit_vial) = grep { $_->{role} eq 'vial_source' }
        @{limit_construction()->{inputs}};
    my $reduced = $input{vial_source}{content};
    my $last_reset = rindex($reduced, $complete_reset);
    ok($last_reset >= 0, 'over-limit source contains the appended reset record');
    substr($reduced, $last_reset, length($complete_reset), '');
    is($reduced, $limit_vial->{content},
        'removing the final complete reset reproduces the exact limit source');
    is(bytes::length($input{vial_source}{content})
            - bytes::length($limit_vial->{content}),
        bytes::length($complete_reset),
        'source growth is exactly one complete reset record');
    unlike($input{vial_source}{content}, qr/\n\n|\/\*|\*\/|;/,
        'source contains no blank-data or comment padding');
};

subtest 'ordinary semantic parsing reaches the plan boundary' => sub {
    my $construction = construction();
    my ($vial) = grep { $_->{role} eq 'vial_source' }
        @{$construction->{inputs}};
    my $semantic_ir = FSM::VIAL::Parser->parse_source({
        text => $vial->{content},
        source_name => $vial->{relative_path},
        source_catalog => {},
    });
    my $semantic = $semantic_ir->as_hashref;
    is(sha256_hex($json->encode($semantic)), $expected{semantic_sha256},
        'ordinary parser produces the exact over-limit SemanticIR identity');
    my $fixture = $semantic->{packages}[0]{fixtures}[0];
    is($fixture->{name}, 'limit_plan',
        'over-limit source retains the referenced limit fixture');
    is(scalar(@{$fixture->{scenarios}[0]{actions}}), $expected{operations},
        'SemanticIR contains every complete reset action');
    is($fixture->{scenarios}[0]{timeout_cycles}, 48_851,
        'the accepted boundary timeout stays fixed while one reset is appended');
};

subtest 'public builder rejects the first complete excess deterministically' => sub {
    my $first = $class->build({construction => construction()});
    my $second = $class->build({construction => construction()});
    ok(!$first->{ok}, 'first complete excess is rejected');
    is($json->encode($second), $json->encode($first),
        'independent rejection is byte-identical');
    is($first->{execution_ir}, undef,
        'rejection exposes no partial execution IR');
    is($first->{plan}, undef, 'rejection exposes no partial plan');
    is_deeply($first->{diagnostics}, [$expected_diagnostic],
        'rejection returns the one exact authoritative plan-cap diagnostic');
};

subtest 'evaluation recognizes the selected rejection and rejects mutation' => sub {
    my $evaluation = $class->evaluate({construction => construction()});
    ok($evaluation->{ok}, 'over-limit evaluation satisfies every closed oracle');
    diag($json->encode($evaluation->{diagnostics})) unless $evaluation->{ok};
    is($evaluation->{status}, 'expected_rejection',
        'evaluation classifies the plan-cap rejection as expected');
    is($evaluation->{observed_outcome}, 'rejected',
        'evaluation records the rejected outcome');
    is_deeply($evaluation->{diagnostics}, [$expected_diagnostic],
        'evaluation preserves the exact builder diagnostic');
    is_deeply($evaluation->{metrics}, {},
        'rejection reports no measurements from a partial plan');
    is_deeply($evaluation->{contract_discrepancies}, [],
        'selected plan cap has no earlier-stage contract discrepancy');

    my $forged = clone_json(construction());
    my ($vial) = grep { $_->{role} eq 'vial_source' } @{$forged->{inputs}};
    $vial->{content} .= ' ';
    my $accepted = eval { $class->build({construction => $forged}); 1 };
    ok(!$accepted, 'post-identity over-limit padding fails closed');
    like($@, qr/construction is not canonical/,
        'mutation rejection names canonical regeneration');

    my $missing = eval {
        $class->construct({
            primary_axis => 'serialized_plan_bytes',
            level => 'over_limit_v1',
        });
        1;
    };
    ok(!$missing, 'over-limit construction requires frozen checked-AHB source');
    like($@, qr/checked-AHB reference text is required/,
        'missing-source rejection names checked-AHB authority');
};

done_testing();

sub repo_path {
    my ($relative) = @_;
    return File::Spec->catfile($FindBin::Bin, '..', split m{/}, $relative);
}

sub slurp_raw {
    my ($path) = @_;
    open my $fh, '<:raw', $path or die "Cannot read $path: $!";
    local $/;
    my $text = <$fh>;
    close $fh or die "Cannot close $path: $!";
    return $text;
}

sub clone_json {
    my ($value) = @_;
    return $json->decode($json->encode($value));
}
