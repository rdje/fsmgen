#!/usr/bin/env perl

use strict;
use warnings;

use File::Spec;
use FindBin;
use JSON::PP ();
use Test::More;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::HIAL::VIALBridge::Builder;
use FSM::VIAL::ArchitectureScaleBridgeFanout;
use FSM::VIAL::ArchitectureScaleWorkload;

my $class = 'FSM::VIAL::ArchitectureScaleBridgeFanout';
my $foundation = 'FSM::VIAL::ArchitectureScaleWorkload';
my $json = JSON::PP->new->canonical(1)->utf8(1);
my $repo_root = File::Spec->catdir($FindBin::Bin, '..');
my $reference_hial = slurp_raw(File::Spec->catfile(
    $repo_root, qw(ppif ahb_lite_subordinate.ppif),
));
my $reference_vial = slurp_raw(File::Spec->catfile(
    $repo_root, qw(vial ahb_subordinate_base_output_arbitration.vial),
));

my @axes = qw(
    selected_units selected_domains configurations types endpoints transactions
    events observations probes backend_bindings retained_residue_records
    source_map_records serialized_manifest_bytes
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
        reference_hial_text => $level eq 'reference_v1' ? $reference_hial : undef,
        reference_vial_text => $level eq 'reference_v1' ? $reference_vial : undef,
    });
}

sub check_evaluation {
    my ($axis, $level, $evaluation) = @_;
    ok($evaluation->{ok}, "$axis/$level passes its canonical bridge oracle");
    diag($json->encode($evaluation->{diagnostics})) unless $evaluation->{ok};
    is_deeply(
        [sort keys %$evaluation],
        [sort @{$class->evaluation_keys}],
        "$axis/$level evaluation is closed",
    );
    is($evaluation->{family}, 'bridge_fanout_v1',
        "$axis/$level retains the exact family");
    is($evaluation->{primary_axis}, $axis,
        "$axis/$level retains the exact primary axis");
    is($evaluation->{level}, $level, "$axis/$level retains the exact level");
    if ($evaluation->{status} eq 'accepted' && $level ne 'reference_v1') {
        my $requested = $evaluation->{requested_counts}{$axis};
        is($evaluation->{metrics}{$axis}, $requested,
            "$axis/$level reaches its requested bridge count");
        like($evaluation->{manifest_sha256}, qr/\A[0-9a-f]{64}\z/,
            "$axis/$level has one canonical manifest identity");
        is($evaluation->{report_sha256}, $evaluation->{manifest_sha256},
            "$axis/$level report and immutable manifest are byte-equal");
        is_deeply($evaluation->{review_layers}, [qw(IAL1 IAL0)],
            "$axis/$level uses only the reviewed direct-IAL1 route");
    }
    elsif ($evaluation->{status} eq 'expected_rejection') {
        like($evaluation->{diagnostics}[0]{code},
            qr/\AHIAL_VIAL_BRIDGE_(?:LIMIT|CAPABILITY)_ERROR\z/,
            "$axis/$level stops at one authoritative bridge boundary");
        is(scalar(@{$evaluation->{contract_discrepancies}}), 1,
            "$axis/$level records the exact earlier-cap interaction");
    }
}

subtest 'closed construction covers every bridge axis and level deterministically' => sub {
    my $catalog = $foundation->catalog->{families}{bridge_fanout_v1}{axes};
    is_deeply([sort keys %$catalog], [sort @axes],
        'test axis inventory equals the selected bridge catalog');
    my $count = 0;
    for my $axis (@axes) {
        is_deeply([sort keys %{$catalog->{$axis}{levels}}], [sort @levels],
            "$axis retains every selected level");
        for my $level (@levels) {
            my $first = construct($axis, $level);
            my $second = construct($axis, $level);
            ok($first->{ok}, "$axis/$level constructs through the shared foundation");
            diag($json->encode($first->{diagnostics})) unless $first->{ok};
            is($json->encode($second), $json->encode($first),
                "$axis/$level independently regenerates byte-equal inputs and identity");
            is($first->{specification}{family}, 'bridge_fanout_v1',
                "$axis/$level cannot escape the bridge family");
            is_deeply([map { $_->{role} } @{$first->{inputs}}],
                [qw(hial_source vial_source)],
                "$axis/$level contains exactly one HIAL and one VIAL source");
            $count++;
        }
    }
    is($count, 65, 'construction covers all thirteen axes at all five levels');

    my $bad_key = eval {
        $class->construct({
            primary_axis => 'events', level => 'gate_candidate_v1',
            reference_hial_text => undef, reference_vial_text => undef,
            unexpected => 1,
        });
        1;
    };
    ok(!$bad_key, 'unknown generator invocation keys fail closed');
    like($@, qr/unknown key 'unexpected'/,
        'unknown-key failure names the closed boundary');

    my $bad_anchor = eval {
        $class->construct({
            primary_axis => 'events', level => 'reference_v1',
            reference_hial_text => "$reference_hial\n",
            reference_vial_text => $reference_vial,
        });
        1;
    };
    ok(!$bad_anchor, 'reference construction rejects altered HIAL bytes');
    like($@, qr/does not match its checked anchor/,
        'altered reference failure explains its identity boundary');

    my $forged = $json->decode($json->encode(
        construct('events', 'gate_candidate_v1'),
    ));
    $forged->{inputs}[0]{content} .= ' ';
    my $forged_result = eval {
        $class->evaluate({construction => $forged});
        1;
    };
    ok(!$forged_result, 'evaluation rejects a construction mutated after identity');
    like($@, qr/construction is not canonical/,
        'forged-construction failure names the canonical identity boundary');
};

subtest 'frozen AHB reference and every gate candidate pass reusable bridge oracles' => sub {
    my $reference = $class->evaluate({
        construction => construct('selected_units', 'reference_v1'),
    });
    check_evaluation('selected_units', 'reference_v1', $reference);
    is($reference->{report_sha256},
        'a4565d40507f369799adaf199b57a6695b12022d068ff9902cec1bdec1a71aca',
        'checked AHB IAL2-via-IAL1 report identity remains frozen');
    is_deeply($reference->{review_layers}, [qw(IAL2 IAL1 IAL0)],
        'checked AHB reference retains all three review layers');
    is_deeply($reference->{contract_discrepancies}, [],
        'checked AHB reference has no selected-contract discrepancy');

    for my $axis (@axes) {
        my $evaluation = $class->evaluate({
            construction => construct($axis, 'gate_candidate_v1'),
        });
        check_evaluation($axis, 'gate_candidate_v1', $evaluation);
        is_deeply($evaluation->{contract_discrepancies}, [],
            "$axis gate candidate has no selected-contract discrepancy");
    }

    my $parsed = $class->parse({
        construction => construct('events', 'gate_candidate_v1'),
    });
    is($parsed->{actor_name}, 'vial_architecture_scale',
        'canonical parse boundary returns the ordinary generated IAL1 actor');
    is(scalar(@{$parsed->{verification_bridge}{transaction}{events}}), 256,
        'canonical parser retains every gate-scale bridge event');
};

subtest 'qualification profile is private, exact, and cannot bypass IAL1 review' => sub {
    my $construction = construct('selected_units', 'gate_candidate_v1');
    my $route = FSM::VIAL::ArchitectureScaleBridgeFanout::_route($construction);
    my $built = $route->{method}->($route->{class}, $route->{arguments});
    ok($built->{ok}, 'ordinary direct-IAL1 qualification bridge succeeds');
    is_deeply($built->{report}{required_capabilities}, [qw(
        hial_vial.bridge_manifest.v1
        hial_vial.bridge_probe.equivalent_adapter_required
        hial_vial.bridge_profile.core_single_unit_v1
        hial_vial.bridge_qualification.architecture_scale_v1
        hial_vial.bridge_source.ial1
    )], 'qualification report exposes only the selected private capability set');
    is($built->{report}{protocols}[0]{facts}[0]{name}, 'scale_evidence_only',
        'qualification annotation carries the exact evidence-only fact');
    is($built->{report}{protocols}[0]{facts}[0]{value}, 'true',
        'qualification annotation keeps the evidence-only fact true');

    my $bad_profile_args = $json->decode($json->encode($route->{arguments}));
    $bad_profile_args->{actor}{verification_bridge}{protocol}{profile} = 'ahb';
    $bad_profile_args->{schedule_report}{verification_bridge}{protocol}{profile}
        = 'ahb';
    my $bad_profile = FSM::HIAL::VIALBridge::Builder->build_ial1(
        $bad_profile_args,
    );
    ok(!$bad_profile->{ok}, 'altered qualification metadata fails closed');
    is($bad_profile->{diagnostics}[0]{code},
        'HIAL_VIAL_BRIDGE_ANNOTATION_ERROR',
        'altered qualification metadata uses the stable annotation diagnostic');

    my $bad_event_args = $json->decode($json->encode($route->{arguments}));
    $bad_event_args->{actor}{verification_bridge}{transaction}{events}[0]{name}
        = 'bridge_event_00000001';
    $bad_event_args->{schedule_report}{verification_bridge}{transaction}{events}[0]{name}
        = 'bridge_event_00000001';
    my $bad_event = FSM::HIAL::VIALBridge::Builder->build_ial1($bad_event_args);
    ok(!$bad_event->{ok}, 'non-ordinal scale event family fails closed');
    is($bad_event->{diagnostics}[0]{code},
        'HIAL_VIAL_BRIDGE_ANNOTATION_ERROR',
        'non-ordinal scale event uses the stable annotation diagnostic');

    my %generated_source = %{$route->{arguments}{authored_source}};
    $generated_source{repository_path} = undef;
    $generated_source{artifact_name} = 'vial_architecture_scale.isf';
    my $bypass = FSM::HIAL::VIALBridge::Builder->build_ial2_via_ial1({
        profile => $route->{arguments}{profile},
        authored_source => $route->{arguments}{authored_source},
        generated_ial1 => {
            source => \%generated_source,
            actor => $route->{arguments}{actor},
            schedule_report => $route->{arguments}{schedule_report},
        },
        generated_ial0 => $route->{arguments}{generated_ial0},
        backend_names => $route->{arguments}{backend_names},
    });
    ok(!$bypass->{ok}, 'architecture-scale profile cannot masquerade as IAL2');
    is($bypass->{diagnostics}[0]{code}, 'HIAL_VIAL_BRIDGE_ANNOTATION_ERROR',
        'IAL2 bypass rejection uses the stable annotation diagnostic');
};

subtest 'exact qualification, boundary, and excess proof is explicit and RAM-guarded' => sub {
    plan skip_all => 'set FSMGEN_VIAL_SCALE_EXACT=1 under scripts/run_with_ram_guard.sh for exact scale proof'
        unless $ENV{FSMGEN_VIAL_SCALE_EXACT};

    for my $level (qw(qualification_candidate_v1 limit_v1 over_limit_v1)) {
        for my $axis (@axes) {
            my $evaluation = $class->evaluate({construction => construct($axis, $level)});
            check_evaluation($axis, $level, $evaluation);
        }
    }
};

subtest 'generated bridge inputs stage on-repository and clean success and failure exactly' => sub {
    my $construction = construct('events', 'gate_candidate_v1');
    my ($success_stage, $materialized_count);
    my $success = $foundation->with_staging({
        repository_root => $repo_root,
        construction => $construction,
        consumer => sub {
            my ($context) = @_;
            $success_stage = $context->{staging_identity};
            $materialized_count = scalar(@{$context->{inputs}});
            ok(!(grep { !-f $_->{absolute_path} } @{$context->{inputs}}),
                'both canonical inputs exist before bridge consumption');
            my $evaluation = $class->evaluate({construction => $construction});
            ok($evaluation->{ok}, 'bridge evaluation succeeds while staging is owned');
        },
    });
    diag($json->encode($success->{diagnostics})) unless $success->{ok};
    ok($success->{ok}, 'successful bridge staging completes');
    ok($success->{same_volume}, 'successful staging proves same-volume identity');
    ok($success->{removed}, 'successful staging reports exact cleanup');
    is($materialized_count, 2, 'one HIAL and one VIAL source were materialized');
    ok(!-e File::Spec->catdir($repo_root, split m{/}, $success_stage),
        'successful bridge staging leaves no operation-owned tree');

    my $failure_stage;
    my $failure = $foundation->with_staging({
        repository_root => $repo_root,
        construction => $construction,
        consumer => sub {
            my ($context) = @_;
            $failure_stage = $context->{staging_identity};
            die "forced bridge consumer failure\n";
        },
    });
    ok(!$failure->{ok}, 'consumer failure is reported without partial success');
    is($failure->{diagnostics}[0]{code}, 'VIAL_SCALE_CONSUMER_ERROR',
        'consumer failure retains the stable staging diagnostic family');
    ok(!$failure->{removed}, 'failed workflow does not misreport success');
    ok(!-e File::Spec->catdir($repo_root, split m{/}, $failure_stage),
        'failed bridge staging leaves no operation-owned tree');
};

done_testing();

sub slurp_raw {
    my ($path) = @_;
    open my $fh, '<:raw', $path or die "Cannot read '$path': $!";
    local $/;
    my $text = <$fh>;
    close $fh or die "Cannot close '$path': $!";
    return $text;
}
