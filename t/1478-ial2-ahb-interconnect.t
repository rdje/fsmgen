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

subtest 'adapter parses the selected AHB interconnect PPIF shape' => sub {
    ok(-f sample_ahb_interconnect_ppif_path(), 'tracked runnable AHB interconnect PPIF sample exists');

    my $result = FSM::Adapter::IAL2::PPIF->new()->parse_file(sample_ahb_interconnect_ppif_path());

    is($result->{layer}, 'IAL2', 'AHB interconnect adapter result stays IAL2');
    is($result->{kind}, 'protocol_intent.ahb_interconnect', 'adapter returns the AHB interconnect kind');
    is($result->{mode}, 'requester-subordinate-interconnect', 'AHB interconnect mode is explicit');
    is($result->{report}{schema}, 'fsmgen.ial2.protocol_intent.ahb_interconnect.v1', 'AHB interconnect report schema is selected');
    is($result->{report}{source_object}{id}, 'fsmgen-ahb-interconnect', 'AHB interconnect source object id is preserved');
    is($result->{report}{source_object}{intent_name}, 'ahb_interconnect', 'AHB interconnect source intent name is preserved');
    is($result->{report}{target_protocol}{profile}, 'ahb', 'AHB interconnect report carries the AHB profile');
    is($result->{report}{target_protocol}{object}, 'ahb-interconnect', 'AHB interconnect report carries the AHB interconnect object');
    is($result->{report}{target_protocol}{role}, 'interconnect', 'AHB interconnect report carries the interconnect role');
    is($result->{report}{layering}{direct_ial2_to_ial0}, 0, 'AHB interconnect lowering goes through generated IAL1 before IAL0');

    is_deeply(
        [map { $_->{name} } @{$result->{generated_ial1}{items}}],
        [qw(amba_requester.isf ahb_lite_subordinate.isf ahb_interconnect.isf)],
        'AHB interconnect exposes requester, subordinate, and fabric IAL1 artifacts',
    );
    is_deeply(
        sorted([keys %{$result->{generated_ial0}{files}}]),
        [qw(ahb_interconnect.fsm ahb_lite_subordinate.fsm ahb_tb.fsm amba_requester.fsm)],
        'AHB interconnect exposes requester, subordinate, fabric, and top IAL0 artifacts',
    );

    my ($interconnect_isf_item) = grep { $_->{name} eq 'ahb_interconnect.isf' } @{$result->{generated_ial1}{items}};
    my $interconnect_isf = $interconnect_isf_item->{text};
    like($interconnect_isf, qr/\A\(actor ahb_interconnect\b/, 'generated interconnect IAL1 is .isf text');
    like($interconnect_isf, qr/\(output HGRANT \(reset 1\) \(default 1\)\)/, 'generated interconnect IAL1 records fixed HGRANT');
    like($interconnect_isf, qr/\(output HREADY \(reset 1\) \(default 1\)\)/, 'generated interconnect IAL1 records global HREADY default high');
    like($interconnect_isf, qr/\(output HRESP \(width 2\) \(reset 0\) \(default 0\)\)/, 'generated interconnect IAL1 records requester HRESP as two bits');
    like($interconnect_isf, qr/\(input HRESP_REGS\)/, 'generated interconnect IAL1 accepts one-bit subordinate HRESP');
    like($interconnect_isf, qr/\(output HSEL_REGS \(reset 0\) \(default 0\)\)/, 'generated interconnect IAL1 drives subordinate select');
    like($interconnect_isf, qr/\(output HADDR_REGS \(width 32\) \(reset 0\) \(default 0\)\)/, 'generated interconnect IAL1 drives local subordinate address');
    like($interconnect_isf, qr/\(address-map ahb_decode/, 'generated interconnect IAL1 records address-map name');
    like($interconnect_isf, qr/\(window regs\s+\(base REG_BASE width 32 default 0\)\s+\(size REG_SIZE width 32 default 4\)\)/s, 'generated interconnect IAL1 records the selected static window');
    like($interconnect_isf, qr/\(unmapped-address-error two-cycle\)/, 'generated interconnect IAL1 records two-cycle unmapped ERROR policy');

    my $interconnect_fsm = $result->{generated_ial0}{files}{'ahb_interconnect.fsm'};
    like($interconnect_fsm, qr/\(\?fsm:ahb_interconnect\b/, 'generated interconnect IAL0 names the fabric FSM');
    like($interconnect_fsm, qr/\(HGRANT 1 \(reset 1\)\)/, 'generated interconnect IAL0 carries HGRANT reset metadata');
    like($interconnect_fsm, qr/\(HREADY 1 \(reset 1\)\)/, 'generated interconnect IAL0 carries HREADY reset metadata');
    like($interconnect_fsm, qr/\(<\(& \(! \(== HTRANS 2'b00\)\) \(< HADDR 4\)\)/, 'generated interconnect IAL0 omits the tautological lower-bound comparison for a zero-base static window');
    like($interconnect_fsm, qr/\(= \(HSEL_REGS> 1\)\)/, 'generated interconnect IAL0 asserts subordinate select on hits');
    like($interconnect_fsm, qr/\(= \(HADDR_REGS> HADDR\)\)/, 'generated interconnect IAL0 emits local address for the zero-base window');
    like($interconnect_fsm, qr/\(<HRESP_REGS\s+\(= \(HRESP> 2'b01\)\)/s, 'generated interconnect IAL0 maps one-bit subordinate ERROR to two-bit requester ERROR');
    like($interconnect_fsm, qr/\(<!HRESP_REGS\s+\(= \(HRESP> 2'b00\)\)/s, 'generated interconnect IAL0 maps one-bit subordinate OKAY to two-bit requester OKAY');
    like($interconnect_fsm, qr/\(unmapped_error_complete\s+\(= \(HGRANT> 1\)\)\s+\(= \(HREADY> 1\)\)\s+\(= \(HRESP> 2'b01\)\)/s, 'generated interconnect IAL0 completes unmapped ERROR on the second cycle');

    my $top = $result->{generated_ial0}{files}{'ahb_tb.fsm'};
    like($top, qr/\A\(\?top:ahb_tb\b/, 'generated top starts with the AHB composition root');
    like($top, qr/\(\?fsmc:requester amba_requester\)/, 'generated top instantiates the requester child');
    like($top, qr/\(\?fsmc:fabric ahb_interconnect\)/, 'generated top instantiates the interconnect child with a legal HDL instance name');
    like($top, qr/\(\?fsmc:regs ahb_lite_subordinate\)/, 'generated top instantiates the subordinate child');
    like($top, qr/\(requester\.HADDR fabric\.HADDR\)/, 'generated top wires requester address into interconnect');
    like($top, qr/\(fabric\.HGRANT requester\.HGRANT\)/, 'generated top wires fixed grant back to requester');
    like($top, qr/\(fabric\.HREADY requester\.HREADY\)/, 'generated top wires global ready to requester');
    like($top, qr/\(fabric\.HREADY regs\.HREADY\)/, 'generated top wires global ready to subordinate');
    like($top, qr/\(fabric\.HSEL_REGS regs\.HSEL_REGS\)/, 'generated top wires decoded select to subordinate');
    like($top, qr/\(fabric\.HADDR_REGS regs\.HADDR_REGS\)/, 'generated top wires local address to subordinate');
    like($top, qr/\(requester\.HTRANS regs\.HTRANS\)/, 'generated top passes HTRANS to subordinate');
    like($top, qr/\(regs\.HRESP_REGS fabric\.HRESP_REGS\)/, 'generated top wires subordinate response into interconnect');

    is($result->{report}{composition}{name}, 'ahb_tb', 'report captures top name');
    is($result->{report}{composition}{topology}, 'one_requester_one_subordinate_static_window_interconnect', 'report captures selected topology');
    is($result->{report}{composition}{child_instance_count}, 3, 'report captures requester/interconnect/subordinate child count');
    is($result->{report}{composition}{address_map}{windows}[0]{name}, 'regs', 'report captures subordinate address window');
    is($result->{report}{composition}{address_map}{windows}[0]{limit}, 4, 'report captures static window limit');
    is($result->{report}{composition}{response_mux}{unmapped_policy}{cycles}, 2, 'report captures two-cycle unmapped response');
    is($result->{report}{composition}{response_mux}{hresp_mapping}{error}{requester}, "2'b01", 'report captures requester ERROR mapping');
    is($result->{report}{composition}{generated_interconnect}{ial0_artifact}, 'ahb_interconnect.fsm', 'report captures generated interconnect artifact');
    is($result->{report}{children}[0]{role}, 'requester', 'report carries requester child first');
    is($result->{report}{children}[1]{role}, 'interconnect', 'report carries interconnect child second');
    is($result->{report}{children}[1]{instance_name}, 'fabric', 'report gives the interconnect child a legal generated HDL instance name');
    is($result->{report}{children}[2]{role}, 'subordinate', 'report carries subordinate child third');
    is($result->{report}{generated_artifacts}{hdl_entry}{entry_artifact}, 'ahb_tb.fsm', 'report selects generated AHB top as HDL entry');
    is_deeply(
        $result->{report}{generated_artifacts}{hdl_entry}{child_artifacts},
        [qw(amba_requester.fsm ahb_interconnect.fsm ahb_lite_subordinate.fsm)],
        'report lists child artifacts under the selected HDL entry',
    );

    my %residue = map { $_->{id} => 1 } @{$result->{report}{unsupported_residue}};
    ok($residue{ahb_aggregate_profile_alias_deferred}, 'report keeps aggregate .ahb alias residue explicit');
    ok($residue{ahb_multi_subordinate_decode_deferred}, 'report keeps multi-subordinate residue explicit');
    ok($residue{ahb_optional_signal_residue}, 'report keeps optional-signal residue explicit');
    ok($residue{ahb_burst_seq_support_deferred}, 'report keeps burst SEQ residue explicit');
    ok(!$residue{ahb_interconnect_decode_deferred}, 'report does not keep the selected interconnect/decode residue at aggregate level');
};

subtest 'malformed AHB interconnect PPIF sources fail closed' => sub {
    my @cases = (
        [
            'non-AHB profile',
            sub {
                my $source = sample_ahb_interconnect_ppif();
                $source =~ s/\(profile ahb\)/(profile apb)/;
                return $source;
            },
            qr/profile 'apb' does not match \(ahb-interconnect \.\.\.\); expected ahb/,
        ],
        [
            'missing subordinate child',
            sub {
                my $source = sample_ahb_interconnect_ppif();
                $source =~ s/\n      \(subordinate regs ahb_lite_subordinate\)//;
                return $source;
            },
            qr/is missing required \(subordinate \.\.\.\) clause/,
        ],
        [
            'wrong window name',
            sub {
                my $source = sample_ahb_interconnect_ppif();
                $source =~ s/\(window regs/(window other/;
                return $source;
            },
            qr/address-map window 'other' must match subordinate child instance 'regs'/,
        ],
        [
            'two-bit subordinate response',
            sub {
                my $source = sample_ahb_interconnect_ppif();
                $source =~ s/\(response HRESP_REGS width 1\)/(response HRESP_REGS width 2)/;
                $source =~ s/\(subordinate-response HRESP_REGS width 1\)/(subordinate-response HRESP_REGS width 2)/;
                return $source;
            },
            qr/bus\.response\.width must be 1/,
        ],
    );

    for my $case (@cases) {
        my ($label, $build_source, $pattern) = @$case;
        my $ok = eval {
            FSM::Adapter::IAL2::PPIF->new()->parse_source($build_source->(), "$label.ppif");
            1;
        };
        ok(!$ok, "$label is rejected");
        like($@, $pattern, "$label diagnostic is targeted");
    }

};

subtest 'CLI checks, semantic export, schedule report, and outdir all use the public AHB interconnect path' => sub {
    my $check = run_json_command('./bin/fsmgen', '--quiet', '--strict', '--check', '--json', sample_ahb_interconnect_ppif_path());
    ok($check->{success}, 'strict check JSON succeeds for AHB interconnect PPIF');
    is($check->{result}{module_name}, 'ahb_tb', 'check JSON reports generated aggregate module name');
    is($check->{result}{composition_child_count}, 3, 'check JSON reports requester/interconnect/subordinate children');
    is($check->{support_accounting}{entry_id}, 'intent.ppif_ahb_interconnect', 'check JSON matches AHB interconnect support accounting');
    is($check->{support_accounting}{source_kind}, 'ppif', 'check JSON reports PPIF source kind');
    is($check->{support_accounting}{coverage}, 'ial2_ppif_ahb_interconnect_pipeline_cli', 'check JSON reports selected coverage key');

    my $semantic = run_json_command('./bin/fsmgen', '--quiet', '--strict', '--emit-semantic-json', sample_ahb_interconnect_ppif_path());
    ok($semantic->{success}, 'strict semantic JSON succeeds for AHB interconnect PPIF');
    is($semantic->{generation_result_snapshot}{summary}{module_name}, 'ahb_tb', 'semantic JSON reports generated aggregate module name');
    is($semantic->{generation_result_snapshot}{summary}{source_root_kind}, 'top', 'semantic JSON reports generated composition top source root');
    is($semantic->{support_accounting}{entry_id}, 'intent.ppif_ahb_interconnect', 'semantic JSON matches AHB interconnect support accounting');

    my $schedule = run_json_command('./bin/fsmgen', '--quiet', '--emit-schedule-json', sample_ahb_interconnect_ppif_path());
    is($schedule->{schema}, 'fsmgen.ial2.protocol_intent.ahb_interconnect.v1', 'schedule/report JSON exposes the AHB interconnect schema');
    is($schedule->{target_protocol}{object}, 'ahb-interconnect', 'schedule/report JSON exposes the AHB interconnect object');
    is($schedule->{composition}{name}, 'ahb_tb', 'schedule/report JSON exposes aggregate top');
    is($schedule->{composition}{generated_interconnect}{ial1_artifact}, 'ahb_interconnect.isf', 'schedule/report JSON exposes generated interconnect IAL1 artifact');
    is($schedule->{composition}{response_mux}{unmapped_policy}{cycles}, 2, 'schedule/report JSON exposes two-cycle unmapped ERROR');
    is_deeply(
        $schedule->{generated_artifacts}{hdl_entry}{child_artifacts},
        [qw(amba_requester.fsm ahb_interconnect.fsm ahb_lite_subordinate.fsm)],
        'schedule/report JSON exposes child artifacts under selected HDL entry',
    );
    my %schedule_residue = map { $_->{id} => 1 } @{$schedule->{unsupported_residue}};
    ok($schedule_residue{ahb_aggregate_profile_alias_deferred}, 'schedule/report JSON keeps aggregate .ahb alias residue explicit');

    my $tempdir = tempdir(CLEANUP => 1);
    my $outdir = File::Spec->catdir($tempdir, 'out');
    my $hdl = File::Spec->catfile($tempdir, 'ahb_tb.sv');
    my ($success, undef, undef, undef, $stderr) = run(
        command => ['./bin/fsmgen', '--quiet', '--outdir', $outdir, '--output', $hdl, sample_ahb_interconnect_ppif_path()],
    );
    ok($success, 'AHB interconnect PPIF emits HDL and review artifacts through --outdir');
    is(join('', @{$stderr || []}), '', 'outdir generation keeps stderr clean');
    ok(-f File::Spec->catfile($outdir, 'amba_requester.isf'), 'outdir contains generated AHB requester IAL1 artifact');
    ok(-f File::Spec->catfile($outdir, 'ahb_lite_subordinate.isf'), 'outdir contains generated AHB subordinate IAL1 artifact');
    ok(-f File::Spec->catfile($outdir, 'ahb_interconnect.isf'), 'outdir contains generated AHB interconnect IAL1 artifact');
    ok(-f File::Spec->catfile($outdir, 'amba_requester.fsm'), 'outdir contains generated AHB requester IAL0 artifact');
    ok(-f File::Spec->catfile($outdir, 'ahb_lite_subordinate.fsm'), 'outdir contains generated AHB subordinate IAL0 artifact');
    ok(-f File::Spec->catfile($outdir, 'ahb_interconnect.fsm'), 'outdir contains generated AHB interconnect IAL0 artifact');
    ok(-f File::Spec->catfile($outdir, 'ahb_tb.fsm'), 'outdir contains generated AHB top IAL0 artifact');
    ok(-f $hdl, 'outdir command emits selected aggregate HDL output');
    like(slurp($hdl), qr/\bmodule\s+ahb_tb\b/, 'generated HDL contains the AHB aggregate module');
    like(slurp(File::Spec->catfile($outdir, 'ahb_interconnect.fsm')), qr/unmapped_error_complete/, 'outdir generated interconnect FSM keeps unmapped ERROR state');
};

done_testing();

sub sample_ahb_interconnect_ppif_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'ahb_interconnect.ppif');
}

sub sample_ahb_interconnect_ppif {
    return slurp(sample_ahb_interconnect_ppif_path());
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

sub write_file {
    my ($path, $content) = @_;
    open my $fh, '>', $path or die "Cannot write $path: $!";
    print {$fh} $content;
    close $fh or die "Cannot close $path: $!";
}

sub sorted {
    my ($values) = @_;
    return [sort @$values];
}
