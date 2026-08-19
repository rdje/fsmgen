#!/usr/bin/env perl

use strict;
use warnings;

use bytes ();
use File::Spec;
use FindBin;
use JSON::PP ();
use Test::More;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::VIAL::ArchitectureScaleExecutionGraph;
use FSM::VIAL::ArchitectureScaleWorkload;

my $class = 'FSM::VIAL::ArchitectureScaleExecutionGraph';
my $json = JSON::PP->new->canonical(1)->utf8(1);
my $envelope = 1_114_112;
my $manifest_cap = 16_777_216;
my $repair_owner = 'HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.4';

# Decision 0072 requires three numbers per unreachable level: the declared cap,
# the earliest decider, and the measured route boundary.
my $declared_cap = 65_536;
my %boundary = (accepted => 2_054, rejected => 2_055, events_cap => 2_048);
my %level = (
    qualification_candidate_v1 => {bindings => 32_768, hial => 1_933_429, vial => 721_460},
    limit_v1 => {bindings => 65_536, hial => 3_866_741, vial => 1_442_356},
    over_limit_v1 => {bindings => 65_537, hial => 3_866_800, vial => 1_442_378},
);
my $envelope_diagnostic = {
    code => 'VIAL_SCALE_INPUT_ERROR',
    severity => 'error',
    message => 'input 0 exceeds the bounded construction envelope',
    path => '/inputs/0/content',
};

sub construction {
    my ($name) = @_;
    return $class->construct({primary_axis => 'bindings', level => $name});
}

subtest 'no binding level above the gate fits the bounded construction envelope' => sub {
    for my $name (sort keys %level) {
        my $case = $level{$name};
        my ($hial, $vial) = $class->_test_render_binding_sources($case->{bindings});
        is(bytes::length($hial), $case->{hial},
            "$name generates its exact direct-IAL1 byte count");
        is(bytes::length($vial), $case->{vial},
            "$name generates its exact VIAL byte count");
        cmp_ok(bytes::length($hial), '>', $envelope,
            "$name direct-IAL1 source exceeds the bounded construction envelope");
        is(scalar(() = $hial =~ /\(event bridge_event_[0-9]{8} /g),
            $case->{bindings} - 6,
            "$name authors one genuine event record per binding above the fixed six");
    }

    # One record per unit is the only authoring shape here: unlike fibers and
    # operations, an event is a declaration and neither public grammar has a
    # declaration-repetition form, so the source cannot be compacted.
    my ($small) = $class->_test_render_binding_sources(2_048);
    my ($large) = $class->_test_render_binding_sources(4_096);
    cmp_ok(bytes::length($large) - bytes::length($small), '>', 100_000,
        'the direct-IAL1 source grows linearly with bindings, with no compact form');
};

subtest 'each level reports its construction-stage rejection exactly' => sub {
    for my $name (sort keys %level) {
        my $first = construction($name);
        my $second = construction($name);
        ok(!$first->{ok}, "$name construction is rejected");
        is($json->encode($second), $json->encode($first),
            "$name construction rejects identically on an independent run");
        is_deeply($first->{diagnostics}, [$envelope_diagnostic],
            "$name returns the one exact bounded-envelope diagnostic");
        is($first->{specification}{primary_axis}, 'bindings',
            "$name retains the axis the caller asked for");
        is($first->{specification}{requested_counts}{bindings}, $level{$name}{bindings},
            "$name retains its exact requested count");
        is($first->{workload_identity}, undef,
            "$name claims no workload identity for a source that was never admitted");
        is_deeply($first->{inputs}, [],
            "$name retains no oversized source in its returned record");
    }
};

subtest 'evaluation reports envelope_unconstructible with both required records' => sub {
    for my $name (sort keys %level) {
        my $evaluation = $class->evaluate({construction => construction($name)});
        ok($evaluation->{ok}, "$name evaluation satisfies every closed oracle");
        diag($json->encode($evaluation->{diagnostics})) unless $evaluation->{ok};
        is($evaluation->{status}, 'envelope_unconstructible',
            "$name is reported as unconstructible, not as a product rejection");
        is($evaluation->{observed_outcome}, 'not_constructed',
            "$name never claims an observed product outcome");
        is_deeply($evaluation->{metrics}, {},
            "$name reports no measurement");
        is_deeply(
            [$evaluation->{semantic_ir_sha256}, $evaluation->{bridge_manifest_sha256},
                $evaluation->{plan_sha256}, $evaluation->{workload_identity}],
            [undef, undef, undef, undef],
            "$name claims no stage identity");
        is_deeply($evaluation->{diagnostics}, [$envelope_diagnostic],
            "$name preserves the exact construction diagnostic");

        my @codes = map { $_->{code} } @{$evaluation->{contract_discrepancies}};
        is_deeply(\@codes,
            ['VIAL_SCALE_LIMIT_INTERACTION', 'VIAL_SCALE_ROUTE_BOUNDARY'],
            "$name records both the fixture decider and the measured boundary");
        is_deeply([map { $_->{path} } @{$evaluation->{contract_discrepancies}}],
            [('/requested_counts/bindings') x 2], "$name names its own axis twice");
        is_deeply([map { $_->{repair_owner} } @{$evaluation->{contract_discrepancies}}],
            [($repair_owner) x 2], "$name routes both records to .17.4");
        like($evaluation->{contract_discrepancies}[0]{message}, qr/\b$envelope\b/,
            "$name names the envelope byte count that decides");
        like($evaluation->{contract_discrepancies}[0]{message},
            qr/fixture bound and not a product limit/,
            "$name says outright that its decider is not a product limit");
        like($evaluation->{contract_discrepancies}[1]{message},
            qr/accepts $boundary{accepted} and rejects $boundary{rejected}/,
            "$name names the measured route boundary");
        like($evaluation->{contract_discrepancies}[1]{message},
            qr/declared $declared_cap execution cap/,
            "$name names the declared cap it was selected from");
    }
};

subtest 'the binding ladder fails closed on building, mutation, and unowned shapes' => sub {
    my $built = eval { $class->build({construction => construction('limit_v1')}); 1 };
    ok(!$built, 'the raw builder refuses a level with no admitted source');
    like($@, qr/unconstructible level has no admitted source to build/,
        'the refusal names the absent source, not a resource failure');

    my $forged = clone_json(construction('limit_v1'));
    $forged->{specification}{requested_counts}{bindings} = 2_048;
    my $accepted = eval { $class->evaluate({construction => $forged}); 1 };
    ok(!$accepted, 'a forged requested count fails closed');
    like($@, qr/construction is not canonical/,
        'mutation rejection names canonical regeneration');

    my $injected = eval {
        $class->construct({
            primary_axis => 'bindings',
            level => 'limit_v1',
            reference_hial_text => 'x',
        });
        1;
    };
    ok(!$injected, 'the direct-IAL1 route still refuses a caller-supplied source');
    like($@, qr/accepted only for checked-AHB execution gates/,
        'the refusal names the checked-AHB boundary');

    # The owned frontier is published by the generator, so this proves the
    # boundary by deriving it from the catalog instead of restating a list that
    # goes stale the moment the next level lands.
    my %owned;
    $owned{"$_->{primary_axis}/$_->{level}"} = 1
        for @{$class->owned_shapes};
    my $axes = FSM::VIAL::ArchitectureScaleWorkload->catalog
        ->{families}{execution_graph_v1}{axes};
    my @unowned;
    for my $axis (sort keys %{$axes}) {
        for my $level_name (sort keys %{$axes->{$axis}{levels}}) {
            push @unowned, [$axis, $level_name] unless $owned{"$axis/$level_name"};
        }
    }
    cmp_ok(scalar(@unowned), '>', 0,
        'the caller-sealed generator still has an unowned frontier');

    my (@accepted, %reason);
    for my $shape (@unowned) {
        my ($axis, $level_name) = @{$shape};
        if (eval { $class->construct({primary_axis => $axis, level => $level_name}); 1 }) {
            push @accepted, "$axis/$level_name";
            next;
        }
        $reason{"$axis/$level_name"} = $@;
    }
    is_deeply(\@accepted, [],
        'every catalog shape outside the published owned frontier fails closed');
    is_deeply(
        [grep { $reason{$_} !~ /does not own the requested shape/ } sort keys %reason],
        [],
        'each unowned rejection names the caller-sealed generator boundary');
};

subtest 'exact route-boundary proof is explicit and RAM-guarded' => sub {
    plan skip_all => 'set FSMGEN_VIAL_SCALE_EXACT=1 under'
        . ' scripts/run_with_ram_guard.sh for exact binding boundary proof'
        unless $ENV{FSMGEN_VIAL_SCALE_EXACT};

    my $accepted = $class->_test_binding_bridge($boundary{accepted});
    ok($accepted->{ok},
        "the canonical route accepts exactly $boundary{accepted} bindings");
    diag($json->encode($accepted->{diagnostics})) unless $accepted->{ok};
    my $manifest = $accepted->{manifest}->as_hashref;
    is(scalar(@{$manifest->{events}}), $boundary{events_cap},
        'the accepted manifest carries exactly the bridge event cap');
    cmp_ok(bytes::length($json->encode($manifest)), '<=', $manifest_cap,
        'the accepted manifest is inside the serialized bridge cap');

    my $rejected = $class->_test_binding_bridge($boundary{rejected});
    ok(!$rejected->{ok}, 'one further binding crosses the bridge event cap');
    is($rejected->{diagnostics}[0]{code}, 'HIAL_VIAL_BRIDGE_LIMIT_ERROR',
        'the boundary rejection uses the stable bridge limit code');
    is($rejected->{diagnostics}[0]{message},
        'events count ' . ($boundary{rejected} - 6) . ' exceeds limit '
            . $boundary{events_cap},
        'the event cap is the route boundary for this axis');
    is($rejected->{diagnostics}[0]{path}, '/events',
        'the boundary diagnostic names the event family');

    cmp_ok($declared_cap / $boundary{accepted}, '>', 30,
        'the declared execution cap is more than thirty times the reachable boundary');
};

done_testing();

sub clone_json {
    my ($value) = @_;
    return $json->decode($json->encode($value));
}

package FSM::VIAL::ArchitectureScaleExecutionGraph;

sub _test_render_binding_sources {
    my ($class, $bindings) = @_;
    return (_render_hial($bindings - 6), _render_vial($bindings - 6));
}

# The route boundary lies between two catalog levels, so it is proved through
# the same renderer and canonical bridge the owned gate uses.
sub _test_binding_bridge {
    my ($class, $bindings) = @_;
    my $hial = _render_hial($bindings - 6);
    my $actor = FSM::Adapter::ISF->new()->parse_source(
        $hial, 'vial_architecture_scale.isf');
    my $scheduler = FSM::Scheduler::ISF->new();
    my $schedule_report = JSON::PP->new->decode($scheduler->report($actor));
    my $lowered = $scheduler->lower($actor);
    my $artifact_name = $actor->{actor_name} . '.fsm';
    $artifact_name = $actor->{actor_name} . '_top.fsm'
        unless exists $lowered->{files}{$artifact_name};
    return FSM::HIAL::VIALBridge::Builder->build_ial1({
        profile => 'core_single_unit_v1',
        authored_source => _source_record(
            $hial,
            'generated/vial-scale/execution_graph/vial_architecture_scale.isf'),
        actor => $actor,
        schedule_report => $schedule_report,
        generated_ial0 => _source_record(
            $lowered->{files}{$artifact_name}, undef, $artifact_name),
        backend_names => _backend_names($actor),
    });
}
