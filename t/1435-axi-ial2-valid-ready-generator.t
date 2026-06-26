#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Spec;
use File::Temp qw(tempdir);
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Adapter::FSMGenFull;
use FSM::Adapter::ISF;
use FSM::IAL2::ProtocolIntent::ValidReadyChannel;
use FSM::IR::IntentHIRBuilder;
use FSM::Pipeline::GeneratedModuleInfoBuilder;
use FSM::Scheduler::ISF;
use Lispish;

subtest 'AXI Valid-Ready generator emits reviewable IAL1 before IAL0' => sub {
    my $result = generate_sample();

    is($result->{layer}, 'IAL2', 'result identifies the source layer');
    is($result->{kind}, 'protocol_intent.valid_ready_channel', 'result identifies the generator kind');
    is($result->{mode}, 'monitor-only', 'first slice is explicitly monitor-only');

    my $isf = $result->{generated_ial1}{text};
    is($result->{generated_ial1}{name}, 'axi_aw_valid_ready_monitor.isf', 'IAL1 artifact is named');
    like($isf, qr/\A\(actor axi_aw_valid_ready_monitor\b/, 'generated IAL1 is reviewable .isf text');
    like($isf, qr/\(reset \(rst_n async active_low\)\)/, 'generated IAL1 carries reset binding');
    like($isf, qr/\(input awaddr \(width 32\)\)/, 'generated IAL1 carries payload width');
    like($isf, qr/\Q(assert (=> (& (past awvalid) (! (past awready))) awvalid)\E/, 'generated IAL1 asserts VALID hold from prior stalled cycle');
    like($isf, qr/\Q(assert (=> (& (past awvalid) (! (past awready))) (== awaddr (past awaddr)))\E/, 'generated IAL1 asserts payload stability from prior stalled cycle');
    like($isf, qr/\Q(cover (& awvalid awready))\E/, 'generated IAL1 records the fire condition cover');

    my $actor = FSM::Adapter::ISF->new()->parse_source($isf, $result->{generated_ial1}{name});
    my $lowered = FSM::Scheduler::ISF->new()->lower($actor);
    is_deeply(
        sorted([keys %{$result->{generated_ial0}{files}}]),
        ['axi_aw_valid_ready_monitor.fsm'],
        'generator exposes the generated IAL0 .fsm file map',
    );
    is(
        $result->{generated_ial0}{files}{'axi_aw_valid_ready_monitor.fsm'},
        $lowered->{files}{'axi_aw_valid_ready_monitor.fsm'},
        'generated IAL0 text is produced by the public IAL1 scheduler path',
    );
    like(
        $result->{generated_ial0}{files}{'axi_aw_valid_ready_monitor.fsm'},
        qr/\(\+assert[\s\S]*monitor_assert_0[\s\S]*monitor_cover_0/,
        'generated .fsm carries assertion and cover carriers',
    );
};

subtest 'protocol-neutral Valid-Ready profile emits reviewable IAL1 without AXI residue' => sub {
    my $result = generate_generic_sample();

    is($result->{layer}, 'IAL2', 'generic profile result identifies the source layer');
    is($result->{kind}, 'protocol_intent.valid_ready_channel', 'generic profile keeps the generator kind');
    is($result->{generated_ial1}{name}, 'data_link_valid_ready_monitor.isf', 'generic profile IAL1 artifact is named from the channel object');

    my $isf = $result->{generated_ial1}{text};
    like($isf, qr/\A\(actor data_link_valid_ready_monitor\b/, 'generic profile emits reviewable .isf text');
    like($isf, qr/\(input data \(width 8\)\)/, 'generic profile carries payload width');
    like($isf, qr/\Q(assert (=> (& (past valid) (! (past ready))) valid)\E/, 'generic profile asserts VALID hold');

    is_deeply(
        sorted([keys %{$result->{generated_ial0}{files}}]),
        ['data_link_valid_ready_monitor.fsm'],
        'generic profile exposes the generated IAL0 .fsm file map',
    );

    my $report = $result->{report};
    is($report->{source_object}{id}, 'fsmgen-valid-ready-profile', 'generic source object id is reported');
    is($report->{source_object}{intent_name}, 'valid_ready_handshake', 'generic intent name is reported');
    is_deeply(
        $report->{source_object}{anchors},
        [{ document => 'FSMGEN-IAL2-VALID-READY-PROFILE', section => 'monitor', page => 'contract' }],
        'generic profile source anchor is reported',
    );
    is($report->{target_channel}{protocol}, 'valid-ready', 'generic profile is reported as the target protocol/profile');
    is($report->{target_channel}{family}, 'data_link', 'generic profile reports authored channel identifier');
    is($report->{target_channel}{role}, 'producer-to-consumer', 'generic profile reports neutral role');
    is($report->{transfer_fire_condition}, 'valid && ready', 'generic profile reports the fire condition');

    my %residue = map { $_->{id} => 1 } @{$report->{unsupported_residue}};
    ok($residue{valid_ready_profile_behavior_outside_monitor}, 'generic profile reports generic monitor-only residue');
    ok(!$residue{axi_manager_concurrency}, 'generic profile does not report AXI manager residue');

    my $rules = join "\n", @{$report->{enforced_static_rules}};
    like($rules, qr/valid-ready profile channel must be an ISF identifier/, 'generic profile static rules describe authored channel identifiers');
    unlike($rules, qr/AXI profile channel must be one of AW/, 'generic profile static rules are not AXI-only');
};

subtest 'report publishes source anchors, artifacts, bindings, assertions, assumptions, and residue' => sub {
    my $report = generate_sample()->{report};

    is($report->{schema}, 'fsmgen.ial2.protocol_intent.valid_ready_channel.v1', 'report schema is versioned');
    is($report->{layering}{direct_ial2_to_ial0}, 0, 'report rejects direct IAL2-to-IAL0 lowering');
    is($report->{source_object}{id}, 'axi-valid-ready-aw', 'source object id is reported');
    is($report->{source_object}{intent_name}, 'axi_aw_valid_ready', 'source intent name is reported when supplied');
    is_deeply(
        $report->{source_object}{anchors},
        [{ document => 'IHI0022_L_2025-08', section => 'A3.2.1', page => 'A3-40' }],
        'source anchors are reported',
    );
    is($report->{generated_artifacts}{ial1}{name}, 'axi_aw_valid_ready_monitor.isf', 'IAL1 artifact is reported');
    is_deeply($report->{generated_artifacts}{ial0}{files}, ['axi_aw_valid_ready_monitor.fsm'], 'IAL0 artifacts are reported');
    is($report->{target_channel}{protocol}, 'axi4', 'protocol is normalized');
    is($report->{target_channel}{family}, 'AW', 'channel family is normalized');
    is($report->{target_channel}{role}, 'manager-to-subordinate', 'role is reported');
    is($report->{bindings}{valid}, 'awvalid', 'valid binding is reported');
    is($report->{bindings}{ready}, 'awready', 'ready binding is reported');
    is($report->{transfer_fire_condition}, 'awvalid && awready', 'fire condition is reported as VALID && READY');

    my @assertion_ids = map { $_->{id} } @{$report->{generated_runtime_assertions}};
    is_deeply(
        \@assertion_ids,
        [qw(valid_hold_while_stalled payload_awaddr_stable_while_stalled payload_awlen_stable_while_stalled)],
        'generated runtime assertions are reported in generation order',
    );

    my %residue = map { $_->{id} => 1 } @{$report->{unsupported_residue}};
    ok($residue{reset_low_valid_during_reset}, 'reset-during-reset obligation remains explicit residue');
    ok($residue{ready_independence}, 'ready-independence proof remains explicit residue');
    ok($residue{axi_manager_concurrency}, 'full AXI manager concurrency remains explicit residue');
};

subtest 'generated checks surface through the existing assertion-property backend path' => sub {
    my $result = generate_sample();
    my $info = module_info_for(
        'axi_aw_valid_ready_monitor.fsm',
        $result->{generated_ial0}{files}{'axi_aw_valid_ready_monitor.fsm'},
    );

    my %by_name = map { $_->{name} => $_ } @{$info->{immediate_assertions}};
    is_deeply(
        sorted([keys %by_name]),
        [qw(monitor_assert_0 monitor_assert_1 monitor_assert_2 monitor_cover_0)],
        'assert and cover carriers survive into module_info',
    );
    like($by_name{monitor_assert_0}{condition_sv}, qr/\|-> \(awvalid\)\z/, 'valid-hold check renders as overlapping implication');
    like($by_name{monitor_assert_1}{condition_sv}, qr/awaddr == \$past\(awaddr\)/, 'payload stability uses $past for awaddr');
    like($by_name{monitor_assert_2}{condition_sv}, qr/awlen == \$past\(awlen\)/, 'payload stability uses $past for awlen');
    is($by_name{monitor_cover_0}{kind}, 'cover', 'fire condition is carried as a cover');
    ok(!$by_name{$_}{formal_only}, "$_ remains simulable")
        for qw(monitor_assert_0 monitor_assert_1 monitor_assert_2 monitor_cover_0);
};

subtest 'malformed contract objects fail closed and no direct lower-to-fsm entrypoint is exposed' => sub {
    my $generator = FSM::IAL2::ProtocolIntent::ValidReadyChannel->new();
    ok(!$generator->can('lower_to_fsm'), 'generator exposes no direct IAL2-to-.fsm method');

    my @cases = (
        ['missing valid', sub { my $c = sample_contract(); delete $c->{valid}; $c }, qr/missing required scalar field 'valid'/],
        ['empty payload', sub { my $c = sample_contract(); $c->{payload} = []; $c }, qr/payload.*non-empty array/],
        ['bad width', sub { my $c = sample_contract(); $c->{payload}[0]{width} = 0; $c }, qr/payload\[0\]\.width.*positive integer/],
        ['duplicate endpoint', sub { my $c = sample_contract(); $c->{payload}[0]{name} = 'awvalid'; $c }, qr/duplicates interface signal 'awvalid'/],
        ['bad protocol', sub { my $c = sample_contract(); $c->{protocol} = 'chi'; $c }, qr/profile must be valid-ready, axi/],
        ['bad channel', sub { my $c = sample_contract(); $c->{channel} = 'XYZ'; $c }, qr/channel must be one of AW, W, B, AR, or R/],
        ['bad generic channel', sub { my $c = generic_contract(); $c->{channel} = 'data-link'; $c }, qr/field 'channel' must be an ISF identifier/],
        ['bad generic role', sub { my $c = generic_contract(); $c->{role} = 'manager-to-subordinate'; $c }, qr/valid-ready profile role must be producer-to-consumer or consumer-to-producer/],
        ['bad source anchors', sub { my $c = sample_contract(); $c->{source}{anchors} = {}; $c }, qr/source\.anchors must be an array reference/],
    );

    for my $case (@cases) {
        my ($label, $build, $pattern) = @$case;
        my $ok = eval { $generator->generate($build->()); 1 };
        ok(!$ok, "$label is rejected");
        like($@, $pattern, "$label diagnostic is targeted");
    }
};

done_testing();

sub generate_sample {
    return FSM::IAL2::ProtocolIntent::ValidReadyChannel->new()->generate(sample_contract());
}

sub generate_generic_sample {
    return FSM::IAL2::ProtocolIntent::ValidReadyChannel->new()->generate(generic_contract());
}

sub sample_contract {
    return {
        name     => 'axi_aw',
        intent_name => 'axi_aw_valid_ready',
        protocol => 'axi4',
        channel  => 'AW',
        role     => 'manager-to-subordinate',
        clock    => 'clk',
        reset    => { signal => 'rst_n', active_low => 1, async => 1 },
        valid    => 'awvalid',
        ready    => 'awready',
        payload  => [
            { name => 'awaddr', width => 32 },
            { name => 'awlen',  width => 8 },
        ],
        source => {
            object_id => 'axi-valid-ready-aw',
            anchors => [
                { document => 'IHI0022_L_2025-08', section => 'A3.2.1', page => 'A3-40' },
            ],
        },
    };
}

sub generic_contract {
    return {
        name     => 'data_link',
        intent_name => 'valid_ready_handshake',
        protocol => 'valid-ready',
        channel  => 'data_link',
        role     => 'producer-to-consumer',
        clock    => 'clk',
        reset    => { signal => 'rst_n', active_low => 1, async => 1 },
        valid    => 'valid',
        ready    => 'ready',
        payload  => [
            { name => 'data', width => 8 },
        ],
        source => {
            object_id => 'fsmgen-valid-ready-profile',
            anchors => [
                { document => 'FSMGEN-IAL2-VALID-READY-PROFILE', section => 'monitor', page => 'contract' },
            ],
        },
    };
}

sub module_info_for {
    my ($file_name, $fsm_text) = @_;
    my $tempdir = tempdir(CLEANUP => 1);
    my $path = File::Spec->catfile($tempdir, $file_name);
    open my $fh, '>', $path or die "write $path: $!";
    print {$fh} $fsm_text;
    close $fh or die "close $path: $!";

    my $module = FSM::Adapter::FSMGenFull->new(debug => 0)->parse_fsm(Lispish::multi($path));
    my $intent = FSM::IR::IntentHIRBuilder->build_from_fsm_module(fsm_module => $module);
    return FSM::Pipeline::GeneratedModuleInfoBuilder->build_from_fsm_module(
        fsm_module => $module,
        intent_hir => $intent,
    );
}

sub sorted {
    my ($values) = @_;
    return [sort @{$values || []}];
}
