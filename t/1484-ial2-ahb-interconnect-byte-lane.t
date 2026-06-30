#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Spec;
use File::Temp qw(tempdir);
use FindBin;
use IPC::Cmd qw(run);
use JSON::PP qw(decode_json);

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Adapter::IAL2::PPIF;

subtest 'adapter parses selected one-subordinate AHB aggregate byte-lane PPIF shape' => sub {
    ok(-f one_subordinate_byte_lane_ppif_path(), 'tracked runnable one-subordinate AHB aggregate byte-lane PPIF sample exists');

    my $result = FSM::Adapter::IAL2::PPIF->new()->parse_file(one_subordinate_byte_lane_ppif_path());

    is($result->{layer}, 'IAL2', 'AHB aggregate byte-lane adapter result stays IAL2');
    is($result->{kind}, 'protocol_intent.ahb_interconnect', 'adapter returns the AHB interconnect kind');
    is($result->{mode}, 'requester-subordinate-interconnect', 'AHB aggregate byte-lane mode is explicit');
    is($result->{report}{schema}, 'fsmgen.ial2.protocol_intent.ahb_interconnect.v1', 'report schema stays the AHB interconnect schema');
    is($result->{report}{source_object}{id}, 'fsmgen-ahb-interconnect-byte-lane', 'source object id is preserved');
    is($result->{report}{source_object}{intent_name}, 'ahb_interconnect_byte_lane', 'source intent name is preserved');
    is($result->{report}{composition}{topology}, 'one_requester_one_subordinate_static_window_interconnect', 'report keeps the selected one-subordinate topology');
    is($result->{report}{composition}{child_instance_count}, 3, 'report captures requester/interconnect/subordinate child count');

    is_deeply(
        [map { $_->{name} } @{$result->{generated_ial1}{items}}],
        [qw(amba_requester.isf ahb_lite_subordinate_byte_lane.isf ahb_interconnect.isf)],
        'one-subordinate aggregate byte-lane source exposes requester, byte-lane subordinate, and fabric IAL1 artifacts',
    );
    is_deeply(
        sorted([keys %{$result->{generated_ial0}{files}}]),
        [qw(ahb_interconnect.fsm ahb_lite_subordinate_byte_lane.fsm ahb_tb.fsm amba_requester.fsm)],
        'one-subordinate aggregate byte-lane source exposes requester, byte-lane subordinate, fabric, and top IAL0 artifacts',
    );

    my $top = $result->{generated_ial0}{files}{'ahb_tb.fsm'};
    like($top, qr/\(\?fsmc:regs ahb_lite_subordinate_byte_lane\)/, 'generated top instantiates the byte-lane subordinate child');
    like($top, qr/\(interconnect\.HADDR_REGS regs\.HADDR_REGS\)/, 'generated top wires local address into byte-lane subordinate');
    like($top, qr/\(requester\.HSIZE regs\.HSIZE\)/, 'generated top forwards HSIZE into byte-lane subordinate');
    like($top, qr/\(requester\.HWRITE regs\.HWRITE\)/, 'generated top forwards HWRITE into byte-lane subordinate');
    like($top, qr/\(requester\.HWDATA regs\.HWDATA\)/, 'generated top forwards HWDATA into byte-lane subordinate');
    like($top, qr/\(regs\.HRESP_REGS interconnect\.HRESP_REGS\)/, 'generated top wires subordinate-owned response into interconnect');

    my $interconnect_fsm = $result->{generated_ial0}{files}{'ahb_interconnect.fsm'};
    like($interconnect_fsm, qr/\(= \(HADDR_REGS> HADDR\)\)/, 'generated interconnect keeps zero-base local address for byte-lane subordinate');
    like($interconnect_fsm, qr/\(<HRESP_REGS\s+\(= \(HRESP> 2'b01\)\)/s, 'generated interconnect maps subordinate ERROR to requester ERROR on mapped hits');
    like($interconnect_fsm, qr/\(unmapped_error_complete\s+\(= \(HGRANT> 1\)\)\s+\(= \(HREADY> 1\)\)\s+\(= \(HRESP> 2'b01\)\)/s, 'generated interconnect keeps interconnect-owned unmapped ERROR completion');

    my $subordinate_fsm = $result->{generated_ial0}{files}{'ahb_lite_subordinate_byte_lane.fsm'};
    like($subordinate_fsm, qr/read_byte_lane3_hit_start/, 'embedded byte-lane subordinate keeps byte-lane read path');
    like($subordinate_fsm, qr/read_halfword_lane1_hit_start/, 'embedded byte-lane subordinate keeps halfword read path');

    my $propagation = $result->{report}{composition}{byte_lane_propagation};
    ok($propagation->{selected}, 'report selects aggregate byte-lane propagation');
    is($propagation->{mode}, 'subordinate_owned_narrow_transfer_policy', 'report records subordinate-owned narrow-transfer policy');
    is($propagation->{local_address_policy}, 'subtract_window_base_before_subordinate_lane_policy', 'report records local-address policy before byte-lane selection');
    is($propagation->{mapped_hit_owner}, 'selected_subordinate', 'report records selected subordinate ownership for mapped-hit errors');
    is($propagation->{unmapped_error_owner}, 'interconnect', 'report records interconnect ownership for unmapped errors');
    is(scalar(@{$propagation->{subordinates}}), 1, 'report carries one propagated byte-lane subordinate');
    is($propagation->{subordinates}[0]{object_name}, 'ahb_lite_subordinate_byte_lane', 'report identifies propagated byte-lane subordinate object');
    is($propagation->{subordinates}[0]{local_address_signal}{name}, 'HADDR_REGS', 'report identifies propagated local address signal');
    is_deeply($propagation->{subordinates}[0]{supported_size}, [qw(byte halfword word)], 'report carries supported byte-lane sizes');
    is($propagation->{subordinates}[0]{narrow_transfer_policy}{narrow_write}{policy}, 'preserve-inactive-lanes', 'report carries child narrow-write policy');
    is($result->{report}{children}[2]{narrow_transfer_policy}{narrow_read}{policy}, 'zero-fill-inactive-lanes', 'child report propagates child narrow-read policy');

    my %residue = map { $_->{id} => $_->{detail} } @{$result->{report}{unsupported_residue}};
    ok($residue{ahb_aggregate_profile_alias_deferred}, 'generic aggregate byte-lane PPIF keeps aggregate .ahb alias residue explicit');
    ok($residue{ahb_multi_subordinate_decode_deferred}, 'one-subordinate aggregate byte-lane PPIF keeps multi-subordinate residue explicit');
    unlike($residue{ahb_optional_signal_residue}, qr/byte lanes/, 'one-subordinate aggregate byte-lane residue no longer claims byte lanes are deferred');
};

subtest 'adapter parses selected two-subordinate AHB aggregate byte-lane PPIF shape' => sub {
    ok(-f two_subordinate_byte_lane_ppif_path(), 'tracked runnable two-subordinate AHB aggregate byte-lane PPIF sample exists');

    my $result = FSM::Adapter::IAL2::PPIF->new()->parse_file(two_subordinate_byte_lane_ppif_path());

    is($result->{layer}, 'IAL2', 'AHB two-subordinate aggregate byte-lane adapter result stays IAL2');
    is($result->{kind}, 'protocol_intent.ahb_interconnect', 'adapter returns the AHB interconnect kind');
    is($result->{report}{source_object}{id}, 'fsmgen-ahb-interconnect-two-subordinate-byte-lane', 'source object id is preserved');
    is($result->{report}{source_object}{intent_name}, 'ahb_interconnect_two_subordinate_byte_lane', 'source intent name is preserved');
    is($result->{report}{composition}{topology}, 'one_requester_two_subordinate_static_window_interconnect', 'report keeps the selected two-subordinate topology');
    is($result->{report}{composition}{child_instance_count}, 4, 'report captures requester/interconnect/two-subordinate child count');

    is_deeply(
        [map { $_->{name} } @{$result->{generated_ial1}{items}}],
        [qw(amba_requester.isf ahb_status_subordinate_byte_lane.isf ahb_control_subordinate_byte_lane.isf ahb_interconnect.isf)],
        'two-subordinate aggregate byte-lane source exposes requester, both byte-lane subordinates, and fabric IAL1 artifacts',
    );
    is_deeply(
        sorted([keys %{$result->{generated_ial0}{files}}]),
        [qw(ahb_control_subordinate_byte_lane.fsm ahb_interconnect.fsm ahb_status_subordinate_byte_lane.fsm ahb_tb.fsm amba_requester.fsm)],
        'two-subordinate aggregate byte-lane source exposes all generated IAL0 files',
    );

    my $top = $result->{generated_ial0}{files}{'ahb_tb.fsm'};
    like($top, qr/\(\?fsmc:status ahb_status_subordinate_byte_lane\)/, 'generated top instantiates status byte-lane subordinate');
    like($top, qr/\(\?fsmc:control ahb_control_subordinate_byte_lane\)/, 'generated top instantiates control byte-lane subordinate');
    like($top, qr/\(requester\.HSIZE status\.HSIZE\)/, 'generated top forwards HSIZE into status subordinate');
    like($top, qr/\(requester\.HSIZE control\.HSIZE\)/, 'generated top forwards HSIZE into control subordinate');
    like($top, qr/\(status\.HRESP_STATUS interconnect\.HRESP_STATUS\)/, 'generated top wires status subordinate response into interconnect');
    like($top, qr/\(control\.HRESP_CONTROL interconnect\.HRESP_CONTROL\)/, 'generated top wires control subordinate response into interconnect');

    my $interconnect_fsm = $result->{generated_ial0}{files}{'ahb_interconnect.fsm'};
    like($interconnect_fsm, qr/\(= \(HADDR_STATUS> HADDR\)\)/, 'generated interconnect emits zero-base status local address');
    like($interconnect_fsm, qr/\(= \(HADDR_CONTROL> \(- HADDR 4\)\)\)/, 'generated interconnect subtracts control base before byte-lane policy');
    like($interconnect_fsm, qr/<HRESP_STATUS\s+\(= \(HRESP> 2'b01\)\)/s, 'generated interconnect maps status ERROR to requester ERROR');
    like($interconnect_fsm, qr/<HRESP_CONTROL\s+\(= \(HRESP> 2'b01\)\)/s, 'generated interconnect maps control ERROR to requester ERROR');

    my $propagation = $result->{report}{composition}{byte_lane_propagation};
    ok($propagation->{selected}, 'report selects two-subordinate aggregate byte-lane propagation');
    is($propagation->{mode}, 'subordinate_owned_narrow_transfer_policy', 'report records subordinate-owned policy');
    is(scalar(@{$propagation->{subordinates}}), 2, 'report carries both propagated byte-lane subordinates');
    is_deeply(
        [map { $_->{object_name} } @{$propagation->{subordinates}}],
        [qw(ahb_status_subordinate_byte_lane ahb_control_subordinate_byte_lane)],
        'report preserves byte-lane subordinate order',
    );
    is_deeply(
        [map { $_->{local_address_signal}{name} } @{$propagation->{subordinates}}],
        [qw(HADDR_STATUS HADDR_CONTROL)],
        'report identifies both local address signals',
    );
    is($result->{report}{children}[2]{narrow_transfer_policy}{narrow_write}{policy}, 'preserve-inactive-lanes', 'status child report propagates narrow-write policy');
    is($result->{report}{children}[3]{narrow_transfer_policy}{narrow_read}{policy}, 'zero-fill-inactive-lanes', 'control child report propagates narrow-read policy');

    my %residue = map { $_->{id} => $_->{detail} } @{$result->{report}{unsupported_residue}};
    ok($residue{ahb_broader_interconnect_decode_deferred}, 'two-subordinate aggregate byte-lane PPIF keeps broader interconnect residue explicit');
    unlike($residue{ahb_broader_interconnect_decode_deferred}, qr/byte lanes/, 'two-subordinate broader interconnect residue no longer claims byte lanes are deferred');
    unlike($residue{ahb_optional_signal_residue}, qr/byte lanes/, 'two-subordinate optional-signal residue no longer claims byte lanes are deferred');
};

subtest 'CLI checks, semantic export, schedule report, and outdir use the aggregate byte-lane public paths' => sub {
    my @cases = (
        {
            path => one_subordinate_byte_lane_ppif_path(),
            id => 'intent.ppif_ahb_interconnect_byte_lane',
            coverage => 'ial2_ppif_ahb_interconnect_byte_lane_pipeline_cli',
            child_count => 3,
            schedule_source_id => 'fsmgen-ahb-interconnect-byte-lane',
            generated_isf => [qw(amba_requester.isf ahb_lite_subordinate_byte_lane.isf ahb_interconnect.isf)],
            generated_fsm => [qw(amba_requester.fsm ahb_lite_subordinate_byte_lane.fsm ahb_interconnect.fsm ahb_tb.fsm)],
            byte_lane_fsm => 'ahb_lite_subordinate_byte_lane.fsm',
        },
        {
            path => two_subordinate_byte_lane_ppif_path(),
            id => 'intent.ppif_ahb_interconnect_two_subordinate_byte_lane',
            coverage => 'ial2_ppif_ahb_interconnect_two_subordinate_byte_lane_pipeline_cli',
            child_count => 4,
            schedule_source_id => 'fsmgen-ahb-interconnect-two-subordinate-byte-lane',
            generated_isf => [qw(amba_requester.isf ahb_status_subordinate_byte_lane.isf ahb_control_subordinate_byte_lane.isf ahb_interconnect.isf)],
            generated_fsm => [qw(amba_requester.fsm ahb_status_subordinate_byte_lane.fsm ahb_control_subordinate_byte_lane.fsm ahb_interconnect.fsm ahb_tb.fsm)],
            byte_lane_fsm => 'ahb_control_subordinate_byte_lane.fsm',
        },
    );

    for my $case (@cases) {
        my $check = run_json_command('./bin/fsmgen', '--quiet', '--strict', '--check', '--json', $case->{path});
        ok($check->{success}, "strict check JSON succeeds for $case->{id}");
        is($check->{result}{module_name}, 'ahb_tb', "check JSON reports aggregate module for $case->{id}");
        is($check->{result}{composition_child_count}, $case->{child_count}, "check JSON reports expected child count for $case->{id}");
        is($check->{support_accounting}{entry_id}, $case->{id}, "check JSON matches support accounting for $case->{id}");
        is($check->{support_accounting}{source_kind}, 'ppif', "check JSON reports PPIF source kind for $case->{id}");
        is($check->{support_accounting}{coverage}, $case->{coverage}, "check JSON reports coverage key for $case->{id}");

        my $semantic = run_json_command('./bin/fsmgen', '--quiet', '--strict', '--emit-semantic-json', $case->{path});
        ok($semantic->{success}, "strict semantic JSON succeeds for $case->{id}");
        is($semantic->{generation_result_snapshot}{summary}{module_name}, 'ahb_tb', "semantic JSON reports aggregate module for $case->{id}");
        is($semantic->{generation_result_snapshot}{summary}{source_root_kind}, 'top', "semantic JSON reports generated composition top for $case->{id}");
        is($semantic->{support_accounting}{entry_id}, $case->{id}, "semantic JSON matches support accounting for $case->{id}");

        my $schedule = run_json_command('./bin/fsmgen', '--quiet', '--emit-schedule-json', $case->{path});
        is($schedule->{schema}, 'fsmgen.ial2.protocol_intent.ahb_interconnect.v1', "schedule/report JSON exposes AHB interconnect schema for $case->{id}");
        is($schedule->{source_object}{id}, $case->{schedule_source_id}, "schedule/report JSON preserves source id for $case->{id}");
        is($schedule->{composition}{child_instance_count}, $case->{child_count}, "schedule/report JSON exposes child count for $case->{id}");
        ok($schedule->{composition}{byte_lane_propagation}{selected}, "schedule/report JSON exposes aggregate byte-lane propagation for $case->{id}");

        my $tempdir = tempdir(CLEANUP => 1);
        my $outdir = File::Spec->catdir($tempdir, 'out');
        my $hdl = File::Spec->catfile($tempdir, 'ahb_tb.sv');
        my ($success, undef, undef, undef, $stderr) = run(
            command => ['./bin/fsmgen', '--quiet', '--outdir', $outdir, '--output', $hdl, $case->{path}],
        );
        ok($success, "aggregate byte-lane PPIF emits HDL and review artifacts through --outdir for $case->{id}");
        is(join('', @{$stderr || []}), '', "outdir generation keeps stderr clean for $case->{id}");
        for my $artifact (@{$case->{generated_isf}}, @{$case->{generated_fsm}}) {
            ok(-f File::Spec->catfile($outdir, $artifact), "outdir contains generated $artifact for $case->{id}");
        }
        ok(-f $hdl, "outdir command emits selected aggregate HDL output for $case->{id}");
        like(slurp($hdl), qr/\bmodule\s+ahb_tb\b/, "generated HDL contains the AHB aggregate module for $case->{id}");
        like(slurp(File::Spec->catfile($outdir, $case->{byte_lane_fsm})), qr/read_halfword_lane1_hit_start/, "outdir generated byte-lane subordinate FSM keeps halfword lane path for $case->{id}");
    }
};

subtest 'existing AHB aggregate and endpoint byte-lane boundaries stay unchanged' => sub {
    my $word_only_ppif = FSM::Adapter::IAL2::PPIF->new()->parse_file(word_only_interconnect_ppif_path());
    ok(!exists $word_only_ppif->{report}{composition}{byte_lane_propagation}, 'word-only aggregate PPIF does not gain aggregate byte-lane report');
    my %word_only_residue = map { $_->{id} => $_->{detail} } @{$word_only_ppif->{report}{unsupported_residue}};
    like($word_only_residue{ahb_optional_signal_residue}, qr/byte lanes/, 'word-only aggregate PPIF keeps byte-lane residue');

    my $word_only_alias = run_json_command('./bin/fsmgen', '--quiet', '--emit-schedule-json', word_only_interconnect_alias_path());
    ok(!exists $word_only_alias->{composition}{byte_lane_propagation}, 'existing word-only aggregate .ahb alias does not gain aggregate byte-lane report');

    my $endpoint_byte_lane = FSM::Adapter::IAL2::PPIF->new()->parse_file(endpoint_byte_lane_ppif_path());
    is($endpoint_byte_lane->{report}{narrow_transfer_policy}{narrow_read}{policy}, 'zero-fill-inactive-lanes', 'endpoint byte-lane PPIF keeps narrow-transfer report');

    my $one_alias = run_json_command('./bin/fsmgen', '--quiet', '--emit-schedule-json', one_subordinate_byte_lane_alias_path());
    ok($one_alias->{composition}{byte_lane_propagation}{selected}, 'matching one-subordinate aggregate byte-lane .ahb alias keeps byte-lane propagation');
    ok(!exists $one_alias->{composition}{seq_policy_propagation}, 'matching one-subordinate aggregate byte-lane .ahb alias does not gain aggregate SEQ propagation');

    my $two_alias = run_json_command('./bin/fsmgen', '--quiet', '--emit-schedule-json', two_subordinate_byte_lane_alias_path());
    ok($two_alias->{composition}{byte_lane_propagation}{selected}, 'matching two-subordinate aggregate byte-lane .ahb alias keeps byte-lane propagation');
    ok(!exists $two_alias->{composition}{seq_policy_propagation}, 'matching two-subordinate aggregate byte-lane .ahb alias does not gain aggregate SEQ propagation');
};

done_testing();

sub one_subordinate_byte_lane_ppif_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'ahb_interconnect_byte_lane.ppif');
}

sub two_subordinate_byte_lane_ppif_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'ahb_interconnect_two_subordinate_byte_lane.ppif');
}

sub word_only_interconnect_ppif_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'ahb_interconnect.ppif');
}

sub word_only_interconnect_alias_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'ahb_interconnect.ahb');
}

sub endpoint_byte_lane_ppif_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'ahb_lite_subordinate_byte_lane.ppif');
}

sub one_subordinate_byte_lane_alias_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'ahb_interconnect_byte_lane.ahb');
}

sub two_subordinate_byte_lane_alias_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'ahb_interconnect_two_subordinate_byte_lane.ahb');
}

sub run_json_command {
    my @command = @_;
    my ($success, undef, undef, $stdout, $stderr) = run(command => \@command);
    my $json = join('', @{$stdout || []});
    my $decoded = eval { decode_json($json) };
    ok($decoded, join(' ', @command) . ' emits decodable JSON')
        or do {
            diag($json);
            diag(join('', @{$stderr || []}));
            diag('command failed') unless $success;
            return {};
        };
    return $decoded;
}

sub slurp {
    my ($path) = @_;
    open my $fh, '<', $path or die "Cannot read $path: $!";
    local $/;
    return <$fh>;
}

sub sorted {
    my ($values) = @_;
    return [sort @$values];
}
