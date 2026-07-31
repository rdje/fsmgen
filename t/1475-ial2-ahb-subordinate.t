#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Digest::SHA qw(sha256_hex);
use File::Spec;
use File::Temp qw(tempdir);
use FindBin;
use IPC::Cmd qw(run);
use JSON::PP qw(decode_json);

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Adapter::IAL2::PPIF;
use FSM::Support::ISFPublicInterfaceContract qw(
    isf_public_interface_schedule_report_verification_bridge_event_keys
    isf_public_interface_schedule_report_verification_bridge_keys
    isf_public_interface_schedule_report_verification_bridge_protocol_keys
    isf_public_interface_schedule_report_verification_bridge_transaction_keys
);

subtest 'adapter parses the selected AHB subordinate PPIF shape' => sub {
    ok(-f sample_ahb_subordinate_ppif_path(), 'tracked runnable AHB subordinate PPIF sample exists');

    my $result = FSM::Adapter::IAL2::PPIF->new()->parse_file(sample_ahb_subordinate_ppif_path());

    is($result->{layer}, 'IAL2', 'AHB subordinate adapter result stays IAL2');
    is($result->{kind}, 'protocol_intent.ahb_subordinate', 'adapter returns the AHB subordinate kind');
    is($result->{mode}, 'subordinate', 'AHB subordinate mode is explicit');
    is($result->{report}{schema}, 'fsmgen.ial2.protocol_intent.ahb_subordinate.v1', 'AHB subordinate report schema is selected');
    is($result->{report}{source_object}{id}, 'fsmgen-ahb-lite-subordinate', 'AHB subordinate source object id is preserved');
    is($result->{report}{source_object}{intent_name}, 'ahb_lite_subordinate', 'AHB subordinate source intent name is preserved');
    is($result->{report}{target_protocol}{profile}, 'ahb', 'AHB subordinate report carries the AHB profile');
    is($result->{report}{target_protocol}{object}, 'ahb-subordinate', 'AHB subordinate report carries the AHB subordinate object');
    is($result->{report}{target_protocol}{role}, 'subordinate', 'AHB subordinate report carries the subordinate role');
    is($result->{report}{target_protocol}{transfer}, 'ahb_lite_access', 'AHB subordinate report names the selected transfer');
    is($result->{report}{layering}{direct_ial2_to_ial0}, 0, 'AHB subordinate lowering goes through generated IAL1 before IAL0');

    my $isf = $result->{generated_ial1}{text};
    is($result->{generated_ial1}{name}, 'ahb_lite_subordinate.isf', 'AHB subordinate exposes generated IAL1 artifact');
    like($isf, qr/\A\(actor ahb_lite_subordinate\b/, 'generated AHB subordinate IAL1 is .isf text');
    like($isf, qr/\(verification-bridge\b/, 'generated AHB subordinate IAL1 carries additive verification bridge metadata');
    like($isf, qr/\(input HSEL\)/, 'generated AHB subordinate IAL1 declares HSEL');
    like($isf, qr/\(input HREADY\)/, 'generated AHB subordinate IAL1 declares HREADY');
    like($isf, qr/\(input HADDR \(width 32\)\)/, 'generated AHB subordinate IAL1 declares HADDR');
    like($isf, qr/\(input HTRANS \(width 2\)\)/, 'generated AHB subordinate IAL1 declares HTRANS');
    like($isf, qr/\(output HREADYOUT \(reset 1\) \(default 1\)\)/, 'generated AHB subordinate IAL1 records HREADYOUT reset/default');
    like($isf, qr/\(output HRESP \(reset 0\) \(default 0\)\)/, 'generated AHB subordinate IAL1 records HRESP reset/default');
    like($isf, qr/\(output HRDATA \(width 32\) \(reset 0\) \(default 0\)\)/, 'generated AHB subordinate IAL1 records HRDATA reset/default');
    like($isf, qr/\(var ahb_phase_pending_q \(width 1\) \(reset 0\)\)/, 'generated AHB subordinate IAL1 stores one accepted next phase valid bit');
    like($isf, qr/\(var next_addr_q \(width 32\) \(reset 0\)\).*?\(var next_trans_q \(width 2\) \(reset 0\)\).*?\(var next_wait_n \(width 4\) \(reset 0\)\)/s, 'generated AHB subordinate IAL1 stores one accepted next address/control bank');
    like($isf, qr/\(priority ahb_phase_capture over ahb_phase_hold\).*?\(priority ahb_phase_hold over ahb_lite_access\)/s, 'generated AHB subordinate IAL1 gives phase capture and hold priority over the transaction tail');
    like($isf, qr/\(rule ahb_phase_capture \(& \(! ahb_phase_pending_q\) HSEL HREADY \(\| \(== HTRANS 2'b10\) \(== HTRANS 2'b11\)\)\).*?\(set next_wait_n wait_cycles\)\s+\(set HREADYOUT 0\)\)/s, 'generated AHB subordinate IAL1 capture owns phase storage and not-ready only');
    like($isf, qr/\(rule ahb_phase_hold ahb_phase_pending_q\s+\(set HREADYOUT 0\)\)/s, 'generated AHB subordinate IAL1 hold owns not-ready only');
    like($isf, qr/\(rule ahb_error_retire \(& HREADYOUT \(== HRESP 1'b1\)\)\s+\(set HREADYOUT 1\)\s+\(set HRESP 1'b0\)\)/s, 'generated AHB subordinate IAL1 retirement owns ready and OKAY without redundant data');
    like($isf, qr/\(when ahb_phase_pending_q\s+\(sample next_addr_q as addr_q\).*?\(sample next_trans_q as trans_q\).*?\(set ahb_phase_pending_q 0\)/s, 'generated AHB subordinate IAL1 relaunches the captured phase once');
    unlike($isf, qr/\(sample HWDATA\b/, 'generated AHB subordinate IAL1 keeps HWDATA as live data-phase state');
    like($isf, qr/\(repeat wait_n\s+\(wait 1\)\)/s, 'generated AHB subordinate IAL1 repeats one-cycle waits from the sampled runtime count');
    like($isf, qr/\(when \(== trans_q 2'b11\)\s+\(drive error_first\)\s+\(drive error_complete\)\)/s, 'generated AHB subordinate IAL1 routes SEQ to two-cycle ERROR');
    like($isf, qr/\(set reg_data_q HWDATA\)/, 'generated AHB subordinate IAL1 writes the selected register from HWDATA');
    like($isf, qr/\(drive read_hit\)/, 'generated AHB subordinate IAL1 has a read-hit drive');

    is_deeply(
        sorted([keys %{$result->{generated_ial0}{files}}]),
        ['ahb_lite_subordinate.fsm'],
        'AHB subordinate adapter exposes generated AHB IAL0 .fsm file map',
    );
    my $fsm = $result->{generated_ial0}{files}{'ahb_lite_subordinate.fsm'};
    is(sha256_hex($fsm), '3d8fa7ac7c3a7f2c9ca063aca2cf707106b511219243d8b277ac3e2e8cf47bcf', 'additive generated IAL1 metadata leaves generated IAL0 bytes unchanged');
    like($fsm, qr/\(\?fsm:ahb_lite_subordinate\b/, 'generated AHB subordinate IAL0 names the subordinate FSM');
    like($fsm, qr/\(HREADYOUT 1 \(reset 1\)\)/, 'generated AHB subordinate IAL0 carries HREADYOUT reset metadata');
    like($fsm, qr/\(HRESP 1 \(reset 0\)\)/, 'generated AHB subordinate IAL0 carries HRESP reset metadata');
    like($fsm, qr/\(HRDATA 32 \(reset 0\)\)/, 'generated AHB subordinate IAL0 carries HRDATA reset metadata');
    like($fsm, qr/\(ahb_lite_access_idle_0\s+\(<- \(HRDATA> 0\)\)\s+\(<- \(HREADYOUT> 1\) <\(& \(! \(& \(! ahb_phase_pending_q\).*?\)\) \(! ahb_phase_pending_q\)\)\)\s+\(<- \(HRESP> 0\)/s,
        'generated AHB subordinate IAL0 keeps the ready default suppressed during phase capture and hold');
    like($fsm, qr/\(<- \(reg_data_q HWDATA\)\)/, 'generated AHB subordinate IAL0 writes storage on mapped writes');
    like($fsm, qr/\(<- \(HRDATA> reg_data_q\) <read_hit_start\)/, 'generated AHB subordinate IAL0 drives read data on mapped reads');
    like($fsm, qr/\Q(<- (HRESP> 1'b1) <(& error_first_start (! (& HREADYOUT (== HRESP 1'b1)))))\E/, 'generated AHB subordinate IAL0 drives first ERROR response');
    like($fsm, qr/\Q(<- (HREADYOUT> 1) <(& error_complete_start (! (& (! ahb_phase_pending_q) HSEL HREADY (| (== HTRANS 2'b10) (== HTRANS 2'b11)))) (! ahb_phase_pending_q)))\E/, 'generated AHB subordinate IAL0 completes the second ERROR cycle');

    is($result->{report}{bindings}{bus}{response}{name}, 'HRESP', 'report captures AHB response binding');
    is($result->{report}{bindings}{bus}{response}{width}, 1, 'report captures one-bit AHB-Lite response width');
    is($result->{report}{bindings}{storage}{register}{data}{name}, 'reg_data_q', 'report captures selected register storage');
    is($result->{report}{transfer}{supported_transfer}, 'nonseq', 'report captures selected NONSEQ support');
    is($result->{report}{transfer}{ignored_transfer}[0], 'idle', 'report captures IDLE as ignored');
    is($result->{report}{transfer}{ignored_transfer}[1], 'busy', 'report captures BUSY as ignored');
    is($result->{report}{transfer}{error_completion}, 'two-cycle', 'report captures selected two-cycle ERROR policy');
    is($result->{report}{output_defaults}{HREADYOUT}{reset}, 1, 'report captures HREADYOUT reset high');
    is($result->{report}{output_defaults}{HREADYOUT}{default}, 1, 'report captures HREADYOUT idle default high');
    is($result->{report}{output_defaults}{HRESP}{reset}, 0, 'report captures HRESP reset OKAY');
    is($result->{report}{output_defaults}{HRDATA}{default}, 0, 'report captures HRDATA idle default zero');
    is($result->{report}{phase_pipeline}{mode}, 'one_accepted_next_address_control', 'report exposes the one-next-phase pipeline mode');
    is($result->{report}{phase_pipeline}{accepted_next_capacity}, 1, 'report bounds accepted next phase capacity to one');
    is_deeply($result->{report}{phase_pipeline}{captured_address_control}, [qw(HADDR HTRANS HWRITE HSIZE wait_cycles)], 'report exposes the non-HBURST captured address/control bank');
    is($result->{report}{phase_pipeline}{write_data}{policy}, 'live_data_phase_held_while_stalled', 'report keeps HWDATA live in the data phase');
    is($result->{report}{phase_pipeline}{overflow}, 'stall_before_another_acceptance', 'report exposes phase-bank backpressure');
    is($result->{report}{generated_artifacts}{hdl_entry}{entry_artifact}, 'ahb_lite_subordinate.fsm', 'report selects generated subordinate .fsm as HDL entry');

    my $bridge = $result->{generated_ial1_schedule_report}{verification_bridge};
    is_deeply(sorted([keys %$bridge]), sorted(isf_public_interface_schedule_report_verification_bridge_keys()), 'reparsed schedule report publishes the exact bridge key family');
    is_deeply(sorted([keys %{$bridge->{protocol}}]), sorted(isf_public_interface_schedule_report_verification_bridge_protocol_keys()), 'reparsed schedule report publishes the exact bridge protocol key family');
    is_deeply(sorted([keys %{$bridge->{transaction}}]), sorted(isf_public_interface_schedule_report_verification_bridge_transaction_keys()), 'reparsed schedule report publishes the exact bridge transaction key family');
    is_deeply(sorted([keys %{$bridge->{transaction}{events}[0]}]), sorted(isf_public_interface_schedule_report_verification_bridge_event_keys()), 'reparsed schedule report publishes the exact bridge event key family');
    is($bridge->{probes}[0]{name}, 'reg_data_q', 'reparsed bridge annotation retains the declared verification probe');

    my %residue = map { $_->{id} => 1 } @{$result->{report}{unsupported_residue}};
    ok($residue{ahb_subordinate_profile_alias_deferred}, 'report keeps .ahb subordinate alias residue explicit');
    ok($residue{ahb_interconnect_generation_deferred}, 'report keeps interconnect/decode residue explicit');
    ok($residue{ahb_subordinate_optional_signal_residue}, 'report keeps optional-signal residue explicit');
    ok($residue{ahb_burst_seq_support_deferred}, 'report keeps burst SEQ residue explicit');
};

subtest 'malformed AHB subordinate PPIF sources fail closed' => sub {
    my @cases = (
        [
            'non-AHB profile',
            sub {
                my $source = sample_ahb_subordinate_ppif();
                $source =~ s/\(profile ahb\)/(profile apb)/;
                return $source;
            },
            qr/profile 'apb' does not match \(ahb-subordinate \.\.\.\); expected ahb/,
        ],
        [
            'two-bit response',
            sub {
                my $source = sample_ahb_subordinate_ppif();
                $source =~ s/\(response HRESP width 1\)/(response HRESP width 2)/;
                return $source;
            },
            qr/bus\.response\.width must be 1/,
        ],
        [
            'missing BUSY ignored transfer',
            sub {
                my $source = sample_ahb_subordinate_ppif();
                $source =~ s/\n      \(ignored-transfer busy\)//;
                return $source;
            },
            qr/transfer must either ignore \{idle, busy\} or ignore \{idle\} and park \{busy\}/,
        ],
        [
            'unsupported selected transfer',
            sub {
                my $source = sample_ahb_subordinate_ppif();
                $source =~ s/\(supported-transfer nonseq\)/(supported-transfer seq)/;
                return $source;
            },
            qr/transfer\.supported_transfer must be nonseq/,
        ],
        [
            'duplicate accept ready-in',
            sub {
                my $source = sample_ahb_subordinate_ppif();
                $source =~ s/\(accept-when \(select 1\) \(ready-in 1\)\)/(accept-when (select 1) (ready-in 1) (ready-in 1))/;
                return $source;
            },
            qr/has duplicate \(ready-in \.\.\.\) clause/,
        ],
    );

    for my $case (@cases) {
        my ($label, $build_source, $pattern, $source_label) = @$case;
        $source_label //= "$label.ppif";
        my $ok = eval {
            FSM::Adapter::IAL2::PPIF->new()->parse_source($build_source->(), $source_label);
            1;
        };
        ok(!$ok, "$label is rejected");
        like($@, $pattern, "$label diagnostic is targeted");
    }
};

subtest 'CLI checks, semantic export, schedule report, and outdir all use the public AHB subordinate path' => sub {
    my $check = run_json_command('./bin/fsmgen', '--quiet', '--strict', '--check', '--json', sample_ahb_subordinate_ppif_path());
    ok($check->{success}, 'strict check JSON succeeds for AHB subordinate PPIF');
    is($check->{result}{module_name}, 'ahb_lite_subordinate', 'check JSON reports generated subordinate module name');
    is($check->{support_accounting}{entry_id}, 'intent.ppif_ahb_lite_subordinate', 'check JSON matches AHB subordinate support accounting');
    is($check->{support_accounting}{source_kind}, 'ppif', 'check JSON reports PPIF source kind');
    is($check->{support_accounting}{coverage}, 'ial2_ppif_ahb_lite_subordinate_pipeline_cli', 'check JSON reports selected coverage key');

    my $semantic = run_json_command('./bin/fsmgen', '--quiet', '--strict', '--emit-semantic-json', sample_ahb_subordinate_ppif_path());
    ok($semantic->{success}, 'strict semantic JSON succeeds for AHB subordinate PPIF');
    is($semantic->{generation_result_snapshot}{summary}{module_name}, 'ahb_lite_subordinate', 'semantic JSON reports generated subordinate module name');
    is($semantic->{generation_result_snapshot}{summary}{source_root_kind}, 'fsm', 'semantic JSON reports generated FSM source root');
    is($semantic->{support_accounting}{entry_id}, 'intent.ppif_ahb_lite_subordinate', 'semantic JSON matches AHB subordinate support accounting');

    my $schedule = run_json_command('./bin/fsmgen', '--quiet', '--emit-schedule-json', sample_ahb_subordinate_ppif_path());
    is($schedule->{schema}, 'fsmgen.ial2.protocol_intent.ahb_subordinate.v1', 'schedule/report JSON exposes the AHB subordinate schema');
    is($schedule->{target_protocol}{object}, 'ahb-subordinate', 'schedule/report JSON exposes the AHB subordinate object');
    is($schedule->{generated_artifacts}{ial1}{name}, 'ahb_lite_subordinate.isf', 'schedule/report JSON exposes generated IAL1 artifact');
    is_deeply($schedule->{generated_artifacts}{ial0}{files}, ['ahb_lite_subordinate.fsm'], 'schedule/report JSON exposes generated IAL0 artifact');
    is($schedule->{output_defaults}{HREADYOUT}{default}, 1, 'schedule/report JSON exposes HREADYOUT default high');
    is($schedule->{output_defaults}{HRESP}{reset}, 0, 'schedule/report JSON exposes HRESP reset OKAY');
    is($schedule->{phase_pipeline}{mode}, 'one_accepted_next_address_control', 'schedule/report JSON exposes the selected phase pipeline');
    is($schedule->{phase_pipeline}{accepted_next_capacity}, 1, 'schedule/report JSON exposes the one-phase capacity');
    my %schedule_residue = map { $_->{id} => 1 } @{$schedule->{unsupported_residue}};
    ok($schedule_residue{ahb_subordinate_profile_alias_deferred}, 'schedule/report JSON keeps .ahb subordinate alias residue explicit');

    my $tempdir = tempdir(CLEANUP => 1);
    my $outdir = File::Spec->catdir($tempdir, 'out');
    my $hdl = File::Spec->catfile($tempdir, 'ahb_lite_subordinate.sv');
    my ($success, undef, undef, undef, $stderr) = run(
        command => ['./bin/fsmgen', '--quiet', '--outdir', $outdir, '--output', $hdl, sample_ahb_subordinate_ppif_path()],
    );
    ok($success, 'AHB subordinate PPIF emits HDL and review artifacts through --outdir');
    is(join('', @{$stderr || []}), '', 'outdir generation keeps stderr clean');
    ok(-f File::Spec->catfile($outdir, 'ahb_lite_subordinate.isf'), 'outdir contains generated AHB subordinate IAL1 artifact');
    ok(-f File::Spec->catfile($outdir, 'ahb_lite_subordinate.fsm'), 'outdir contains generated AHB subordinate IAL0 artifact');
    ok(-f $hdl, 'outdir command emits selected AHB subordinate HDL output');
    my $generated_isf = slurp(File::Spec->catfile($outdir, 'ahb_lite_subordinate.isf'));
    my $generated_fsm = slurp(File::Spec->catfile($outdir, 'ahb_lite_subordinate.fsm'));
    my $generated_hdl = slurp($hdl);
    like($generated_isf, qr/\(output HREADYOUT \(reset 1\) \(default 1\)\)/, 'outdir generated .isf keeps HREADYOUT reset/default metadata');
    like($generated_fsm, qr/\(HREADYOUT 1 \(reset 1\)\)/, 'outdir generated .fsm keeps HREADYOUT reset metadata');
    like($generated_hdl, qr/\bmodule\s+ahb_lite_subordinate\b/, 'generated HDL contains the AHB subordinate module');
    like($generated_hdl, qr/HREADYOUT\s*<=\s*1;/, 'generated HDL resets HREADYOUT high');
    like($generated_hdl, qr/assign\s+\w*error_complete\w*hresp__1_b1_en\b.*HRESP <- 1'b1/, 'generated HDL contains ERROR response drive');
};

done_testing();

sub sample_ahb_subordinate_ppif_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'ahb_lite_subordinate.ppif');
}

sub sample_ahb_subordinate_ppif {
    return slurp(sample_ahb_subordinate_ppif_path());
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
