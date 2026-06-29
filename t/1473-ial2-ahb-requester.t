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

subtest 'adapter parses the selected AHB requester PPIF shape' => sub {
    ok(-f sample_ahb_ppif_path(), 'tracked runnable AHB requester PPIF sample exists');

    my $result = FSM::Adapter::IAL2::PPIF->new()->parse_file(sample_ahb_ppif_path());

    is($result->{layer}, 'IAL2', 'AHB requester adapter result stays IAL2');
    is($result->{kind}, 'protocol_intent.ahb_requester', 'adapter returns the AHB requester kind');
    is($result->{mode}, 'requester', 'AHB requester mode is explicit');
    is($result->{report}{schema}, 'fsmgen.ial2.protocol_intent.ahb_requester.v1', 'AHB requester report schema is selected');
    is($result->{report}{source_object}{id}, 'fsmgen-ahb-requester', 'AHB requester source object id is preserved');
    is($result->{report}{source_object}{intent_name}, 'ahb_requester', 'AHB requester source intent name is preserved');
    is($result->{report}{target_protocol}{profile}, 'ahb', 'AHB requester report carries the AHB profile');
    is($result->{report}{target_protocol}{object}, 'ahb-requester', 'AHB requester report carries the AHB requester object');
    is($result->{report}{target_protocol}{role}, 'requester', 'AHB requester report carries the requester role');

    my $isf = $result->{generated_ial1}{text};
    is($result->{generated_ial1}{name}, 'amba_requester.isf', 'AHB requester exposes generated IAL1 artifact');
    like($isf, qr/\A\(actor amba_requester\b/, 'generated AHB IAL1 is .isf text');
    like($isf, qr/\(input cmd_valid\)/, 'generated AHB IAL1 declares local command valid');
    like($isf, qr/\(input HGRANT\)/, 'generated AHB IAL1 declares HGRANT');
    like($isf, qr/\(input HREADY\)/, 'generated AHB IAL1 declares HREADY');
    like($isf, qr/\(input HRESP \(width 2\)\)/, 'generated AHB IAL1 declares HRESP');
    like($isf, qr/\(output HTRANS \(width 2\)\)/, 'generated AHB IAL1 declares HTRANS');
    like($isf, qr/\(storage\s+\(var ahb_request_done_q \(width 1\) \(reset 0\)\)\)/s, 'generated AHB IAL1 uses an internal completion bit');
    like($isf, qr/\(while beats_remaining_q/, 'generated AHB IAL1 loops over remaining beats');
    like($isf, qr/\(when HGRANT/, 'generated AHB IAL1 gates transfer activity on HGRANT');
    like($isf, qr/\(when HREADY/, 'generated AHB IAL1 advances response handling on HREADY');
    like($isf, qr/\(complete ahb_request_done_q\)/, 'generated AHB IAL1 completes on the internal bit');

    is_deeply(
        sorted([keys %{$result->{generated_ial0}{files}}]),
        ['amba_requester.fsm'],
        'AHB requester adapter exposes generated AHB IAL0 .fsm file map',
    );
    my $fsm = $result->{generated_ial0}{files}{'amba_requester.fsm'};
    like($fsm, qr/\(\?fsm:amba_requester\b/, 'generated AHB IAL0 names the requester FSM');
    like($fsm, qr/\bHGRANT\b/, 'generated AHB IAL0 carries HGRANT');
    like($fsm, qr/\bHREADY\b/, 'generated AHB IAL0 carries HREADY');
    like($fsm, qr/\bHRESP\b/, 'generated AHB IAL0 carries HRESP');
    like($fsm, qr/\bHTRANS\b/, 'generated AHB IAL0 carries HTRANS');
    like($fsm, qr/\bHBURST\b/, 'generated AHB IAL0 carries HBURST');

    is($result->{report}{bindings}{local_command}{address}{name}, 'cmd_addr', 'report captures local command address binding');
    is($result->{report}{bindings}{local_status}{beats_remaining}{width}, 5, 'report captures beats-remaining width');
    is($result->{report}{bindings}{bus}{response}{name}, 'HRESP', 'report captures bus response binding');
    is($result->{report}{burst}{wrap16}, "3'b110", 'report captures WRAP16 encoding');
    is($result->{report}{transfer}{first_beat}, 'nonseq', 'report captures first-beat transfer policy');
    is($result->{report}{response}{retry_action}, 're-request', 'report captures retry action');
    is($result->{report}{generated_artifacts}{hdl_entry}{entry_artifact}, 'amba_requester.fsm', 'report selects generated requester .fsm as HDL entry');
    is($result->{report}{layering}{direct_ial2_to_ial0}, 0, 'AHB requester lowering goes through generated IAL1 before IAL0');

    my %residue = map { $_->{id} => 1 } @{$result->{report}{unsupported_residue}};
    ok($residue{ahb_profile_alias_deferred}, 'report keeps .ahb profile alias residue explicit');
    ok($residue{ahb_completer_subordinate_deferred}, 'report keeps completer/subordinate residue explicit');
    ok($residue{ahb_interconnect_decode_deferred}, 'report keeps interconnect/decode residue explicit');
};

subtest 'malformed AHB requester PPIF sources fail closed' => sub {
    my @cases = (
        [
            'non-AHB profile',
            sub {
                my $source = sample_ahb_ppif();
                $source =~ s/\(profile ahb\)/(profile apb)/;
                return $source;
            },
            qr/profile 'apb' does not match \(ahb-requester \.\.\.\); expected ahb/,
        ],
        [
            'missing local-status block',
            sub {
                my $source = sample_ahb_ppif();
                $source =~ s/\n    \(local-status\n.*?\n    \(bus/\n    (bus/s;
                return $source;
            },
            qr/missing required \(local-status \.\.\.\) clause/,
        ],
        [
            'unsupported burst encoding',
            sub {
                my $source = sample_ahb_ppif();
                $source =~ s/\(incr16 3'b111\)/(incr16 3'b110)/;
                return $source;
            },
            qr/burst\.incr16 must be 3'b111/,
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

subtest 'CLI checks, semantic export, schedule report, and outdir all use the public AHB path' => sub {
    my $check = run_json_command('./bin/fsmgen', '--quiet', '--strict', '--check', '--json', sample_ahb_ppif_path());
    ok($check->{success}, 'strict check JSON succeeds for AHB requester PPIF');
    is($check->{result}{module_name}, 'amba_requester', 'check JSON reports generated module name');
    is($check->{support_accounting}{entry_id}, 'intent.ppif_ahb_requester', 'check JSON matches AHB requester support accounting');
    is($check->{support_accounting}{source_kind}, 'ppif', 'check JSON reports PPIF source kind');

    my $semantic = run_json_command('./bin/fsmgen', '--quiet', '--strict', '--emit-semantic-json', sample_ahb_ppif_path());
    ok($semantic->{success}, 'strict semantic JSON succeeds for AHB requester PPIF');
    is($semantic->{generation_result_snapshot}{summary}{module_name}, 'amba_requester', 'semantic JSON reports generated module name');
    is($semantic->{generation_result_snapshot}{summary}{source_root_kind}, 'fsm', 'semantic JSON reports generated FSM source root');
    is($semantic->{support_accounting}{entry_id}, 'intent.ppif_ahb_requester', 'semantic JSON matches AHB requester support accounting');

    my $schedule = run_json_command('./bin/fsmgen', '--quiet', '--emit-schedule-json', sample_ahb_ppif_path());
    is($schedule->{schema}, 'fsmgen.ial2.protocol_intent.ahb_requester.v1', 'schedule/report JSON exposes the AHB requester schema');
    is($schedule->{generated_artifacts}{ial1}{name}, 'amba_requester.isf', 'schedule/report JSON exposes generated IAL1 artifact');
    is_deeply($schedule->{generated_artifacts}{ial0}{files}, ['amba_requester.fsm'], 'schedule/report JSON exposes generated IAL0 artifact');

    my $tempdir = tempdir(CLEANUP => 1);
    my $outdir = File::Spec->catdir($tempdir, 'out');
    my $hdl = File::Spec->catfile($tempdir, 'amba_requester.sv');
    my ($success, undef, undef, undef, $stderr) = run(
        command => ['./bin/fsmgen', '--quiet', '--outdir', $outdir, '--output', $hdl, sample_ahb_ppif_path()],
    );
    ok($success, 'AHB requester PPIF emits HDL and review artifacts through --outdir');
    is(join('', @{$stderr || []}), '', 'outdir generation keeps stderr clean');
    ok(-f File::Spec->catfile($outdir, 'amba_requester.isf'), 'outdir contains generated AHB IAL1 artifact');
    ok(-f File::Spec->catfile($outdir, 'amba_requester.fsm'), 'outdir contains generated AHB IAL0 artifact');
    ok(-f $hdl, 'outdir command emits selected HDL output');
    like(slurp($hdl), qr/\bmodule\s+amba_requester\b/, 'generated HDL contains the AHB requester module');
};

subtest '.ahb remains an unsupported profile-alias suffix' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $ahb_path = File::Spec->catfile($tempdir, 'ahb_requester.ahb');
    write_file($ahb_path, sample_ahb_ppif());

    my ($success, undef, undef, $stdout, undef) = run(
        command => ['./bin/fsmgen', '--quiet', '--strict', '--check', '--json', $ahb_path],
    );
    ok(!$success, '.ahb check JSON fails closed');
    my $report = decode_json(join('', @{$stdout || []}));
    ok(!$report->{success}, '.ahb check JSON reports failure');
    like(
        $report->{diagnostics}[0]{message},
        qr/source suffix '\.ahb' is a known IAL2 alias candidate but is not supported in this slice/,
        '.ahb failure keeps the unsupported known-alias diagnostic',
    );
};

done_testing();

sub sample_ahb_ppif_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'ahb_requester.ppif');
}

sub sample_ahb_ppif {
    return slurp(sample_ahb_ppif_path());
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
