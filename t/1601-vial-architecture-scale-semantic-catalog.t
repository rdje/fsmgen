#!/usr/bin/env perl

use strict;
use warnings;

use File::Spec;
use FindBin;
use JSON::PP ();
use Test::More;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::VIAL::ArchitectureScaleSemanticCatalog;
use FSM::VIAL::ArchitectureScaleWorkload;

my $class = 'FSM::VIAL::ArchitectureScaleSemanticCatalog';
my $foundation = 'FSM::VIAL::ArchitectureScaleWorkload';
my $json = JSON::PP->new->canonical(1)->utf8(1);
my $repo_root = File::Spec->catdir($FindBin::Bin, '..');
my $anchor_path = File::Spec->catfile(
    $repo_root, qw(vial ahb_subordinate_base_output_arbitration.vial),
);
open my $anchor_fh, '<:raw', $anchor_path or die "Cannot read checked VIAL anchor: $!";
local $/;
my $anchor_text = <$anchor_fh>;
close $anchor_fh or die "Cannot close checked VIAL anchor: $!";

my @axes = qw(
    imports declarations fixtures actions parallel_depth fibers_per_parallel
    scalar_or_list_length record_fields aggregate_depth scoreboard_capacity
    coverage_bins literal_repeat_count source_bytes_per_source
    source_bytes_combined
);
my @levels = qw(
    reference_v1 gate_candidate_v1 qualification_candidate_v1 limit_v1
    over_limit_v1
);

sub construct {
    my ($axis, $level) = @_;
    return $class->construct({
        primary_axis => $axis,
        level => $level,
        reference_text => $level eq 'reference_v1' ? $anchor_text : undef,
    });
}

sub check_evaluation {
    my ($axis, $level, $evaluation) = @_;
    ok($evaluation->{ok}, "$axis/$level passes its current canonical semantic oracle");
    diag($json->encode($evaluation->{diagnostics})) unless $evaluation->{ok};
    is_deeply(
        [sort keys %{$evaluation}],
        [sort @{$class->evaluation_keys}],
        "$axis/$level evaluation is closed",
    );
    is($evaluation->{family}, 'semantic_catalog_v1', "$axis/$level retains the exact family");
    is($evaluation->{primary_axis}, $axis, "$axis/$level retains the exact primary axis");
    is($evaluation->{level}, $level, "$axis/$level retains the exact level");
    if ($evaluation->{status} eq 'accepted' && $level ne 'reference_v1') {
        is(
            $evaluation->{metrics}{$axis},
            $evaluation->{requested_counts}{$axis},
            "$axis/$level reaches the requested semantic count",
        );
        like($evaluation->{semantic_projection_sha256}, qr/\A[0-9a-f]{64}\z/,
            "$axis/$level has one canonical semantic-projection identity");
        like($evaluation->{semantic_report_sha256}, qr/\A[0-9a-f]{64}\z/,
            "$axis/$level has one canonical report identity");
        ok(@{$evaluation->{format_identities}}, "$axis/$level formats every accepted source deterministically");
    }
    elsif ($evaluation->{status} eq 'expected_rejection') {
        is($evaluation->{diagnostics}[0]{code}, 'VIAL_LIMIT_ERROR',
            "$axis/$level rejects at one authoritative VIAL limit");
    }
}

subtest 'closed construction covers every selected semantic axis and level deterministically' => sub {
    my $catalog = $foundation->catalog->{families}{semantic_catalog_v1}{axes};
    is_deeply([sort keys %{$catalog}], [sort @axes], 'test axis inventory equals the selected catalog');
    my $count = 0;
    for my $axis (@axes) {
        is_deeply([sort keys %{$catalog->{$axis}{levels}}], [sort @levels], "$axis retains every selected level");
        for my $level (@levels) {
            my $first = construct($axis, $level);
            my $second = construct($axis, $level);
            ok($first->{ok}, "$axis/$level constructs through the shared foundation");
            diag($json->encode($first->{diagnostics})) unless $first->{ok};
            is($json->encode($second), $json->encode($first),
                "$axis/$level independently regenerates byte-equal source and identity");
            is($first->{specification}{family}, 'semantic_catalog_v1',
                "$axis/$level cannot escape the semantic family");
            is_deeply([map { $_->{role} } @{$first->{inputs}}],
                [('vial_source') x scalar(@{$first->{inputs}})],
                "$axis/$level contains only canonical VIAL source inputs");
            $count++;
        }
    }
    is($count, 70, 'construction covers all fourteen axes at all five selected levels');

    my $bad_key = eval {
        $class->construct({
            primary_axis => 'imports', level => 'gate_candidate_v1',
            reference_text => undef, unexpected => 1,
        });
        1;
    };
    ok(!$bad_key, 'unknown generator invocation keys fail closed');
    like($@, qr/unknown key 'unexpected'/, 'unknown-key failure names the closed boundary');
    my $bad_anchor = eval {
        $class->construct({
            primary_axis => 'imports', level => 'reference_v1',
            reference_text => "$anchor_text\n",
        });
        1;
    };
    ok(!$bad_anchor, 'reference construction rejects altered anchor bytes');
    like($@, qr/exact checked VIAL anchor/, 'altered anchor failure explains its identity boundary');
};

subtest 'checked reference and every gate candidate pass reusable semantic oracles' => sub {
    my $reference = construct('imports', 'reference_v1');
    my $reference_evaluation = $class->evaluate({construction => $reference});
    check_evaluation('imports', 'reference_v1', $reference_evaluation);
    is($reference_evaluation->{metrics}{sources}, 1, 'checked reference retains one exact source');
    is($reference_evaluation->{metrics}{fixtures}, 1, 'checked reference retains one exact fixture');
    is($reference_evaluation->{metrics}{semantic_ids}, 53,
        'checked reference retains fifty-three globally unambiguous named semantic IDs');
    is_deeply($reference_evaluation->{contract_discrepancies}, [],
        'checked reference has no selected-contract discrepancy');

    for my $axis (@axes) {
        my $evaluation = $class->evaluate({
            construction => construct($axis, 'gate_candidate_v1'),
        });
        check_evaluation($axis, 'gate_candidate_v1', $evaluation);
        is_deeply($evaluation->{contract_discrepancies}, [],
            "$axis gate candidate has no selected-contract discrepancy");
    }

    my $parsed = $class->parse({
        construction => construct('imports', 'gate_candidate_v1'),
    });
    isa_ok($parsed, 'FSM::VIAL::SemanticIR');
    is(scalar(@{$parsed->sources}), 9, 'canonical parse boundary retains root plus eight imported sources');
};

subtest 'exact qualification, boundary, and excess proof is explicit and RAM-guarded' => sub {
    plan skip_all => 'set FSMGEN_VIAL_SCALE_EXACT=1 under scripts/run_with_ram_guard.sh for exact scale proof'
        unless $ENV{FSMGEN_VIAL_SCALE_EXACT};

    for my $level (qw(qualification_candidate_v1 limit_v1 over_limit_v1)) {
        for my $axis (@axes) {
            my $evaluation = $class->evaluate({construction => construct($axis, $level)});
            check_evaluation($axis, $level, $evaluation);
            if ($axis eq 'literal_repeat_count'
                && ($level eq 'qualification_candidate_v1' || $level eq 'limit_v1')) {
                is($evaluation->{status}, 'expected_rejection',
                    "$axis/$level stops at the earlier expanded-action cap");
                is(scalar(@{$evaluation->{contract_discrepancies}}), 1,
                    "$axis/$level records the one selected limit interaction");
                is(
                    $evaluation->{contract_discrepancies}[0]{repair_owner},
                    'HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.4',
                    "$axis/$level routes limit-policy repair to the selected owner",
                );
            }
            else {
                is_deeply($evaluation->{contract_discrepancies}, [],
                    "$axis/$level has no selected-contract discrepancy");
            }
        }
    }
};

subtest 'generated inputs stage on the repository volume and clean success and failure exactly' => sub {
    my $construction = construct('imports', 'gate_candidate_v1');
    my ($success_stage, $materialized_count);
    my $success = $foundation->with_staging({
        repository_root => $repo_root,
        construction => $construction,
        consumer => sub {
            my ($context) = @_;
            $success_stage = $context->{staging_identity};
            $materialized_count = scalar(@{$context->{inputs}});
            ok(!(grep { !-f $_->{absolute_path} } @{$context->{inputs}}),
                'every generated source is materialized before canonical consumption');
            my $evaluation = $class->evaluate({construction => $construction});
            ok($evaluation->{ok}, 'canonical semantic evaluation succeeds while staging is owned');
        },
    });
    diag($json->encode($success->{diagnostics})) unless $success->{ok};
    ok($success->{ok}, 'successful semantic staging completes');
    ok($success->{same_volume}, 'successful semantic staging proves same-volume identity');
    ok($success->{removed}, 'successful semantic staging reports exact cleanup');
    is($materialized_count, 9, 'root plus eight imported sources were materialized');
    ok(!-e File::Spec->catdir($repo_root, split m{/}, $success_stage),
        'successful semantic staging leaves no operation-owned tree');

    my $failure_stage;
    my $failure = $foundation->with_staging({
        repository_root => $repo_root,
        construction => $construction,
        consumer => sub {
            my ($context) = @_;
            $failure_stage = $context->{staging_identity};
            die "forced semantic consumer failure\n";
        },
    });
    ok(!$failure->{ok}, 'consumer failure is reported without partial success');
    is($failure->{diagnostics}[0]{code}, 'VIAL_SCALE_CONSUMER_ERROR',
        'consumer failure retains the stable staging diagnostic family');
    ok(!$failure->{removed}, 'failed staging result does not misreport a successful workflow');
    ok(!-e File::Spec->catdir($repo_root, split m{/}, $failure_stage),
        'failed semantic staging leaves no operation-owned tree');
};

done_testing;
