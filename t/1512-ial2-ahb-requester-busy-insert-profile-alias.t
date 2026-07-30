#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;
use IPC::Cmd qw(run);
use JSON::PP qw(decode_json);

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Adapter::IAL2::PPIF;
use FSM::ProjectDataLocality qw(configure_project_temp_environment create_project_tempdir);

configure_project_temp_environment(purpose => 'tests');

subtest 'requester BUSY-insertion .ahb alias mirrors the generic source and lowering' => sub {
    ok(-f alias_path(), 'tracked requester BUSY-insertion .ahb alias exists');
    is(slurp(alias_path()), slurp(ppif_path()), '.ahb source is byte-identical to the generic .ppif source');

    my $alias = FSM::Adapter::IAL2::PPIF->new()->parse_file(alias_path());
    my $ppif = FSM::Adapter::IAL2::PPIF->new()->parse_file(ppif_path());

    is($alias->{layer}, 'IAL2', 'alias remains an IAL2 source');
    is($alias->{kind}, 'protocol_intent.ahb_requester', 'alias keeps the AHB requester kind');
    is($alias->{mode}, 'requester', 'alias keeps requester mode');
    is($alias->{generated_ial1}{name}, 'amba_requester_busy_insert.isf', 'alias exposes the selected IAL1 artifact');
    is($alias->{generated_ial1}{text}, $ppif->{generated_ial1}{text}, 'alias and generic source generate identical IAL1');
    is_deeply($alias->{generated_ial0}{files}, $ppif->{generated_ial0}{files}, 'alias and generic source generate identical IAL0 files');
    is_deeply($alias->{generated_ial0}{files}, {'amba_requester_busy_insert.fsm' => $ppif->{generated_ial0}{files}{'amba_requester_busy_insert.fsm'}}, 'alias keeps the selected IAL0 artifact text');

    is($alias->{report}{schema}, 'fsmgen.ial2.protocol_intent.ahb_requester.v1', 'alias keeps requester report schema');
    is($alias->{report}{source_object}{id}, 'fsmgen-ahb-requester-busy-insert', 'alias preserves source object');
    is($alias->{report}{source_object}{intent_name}, 'ahb_requester_busy_insert', 'alias preserves intent name');
    is($alias->{report}{target_protocol}{profile}, 'ahb', 'alias preserves explicit AHB profile');
    is($alias->{report}{target_protocol}{object}, 'ahb-requester', 'alias preserves requester object');
    is($alias->{report}{transfer}{busy}, "2'b01", 'alias preserves HTRANS BUSY encoding');
    is($alias->{report}{transfer}{busy_before_beat}, 2, 'alias preserves insertion index');
    is($alias->{report}{busy_insertion}{generated_behavior}, 1, 'alias preserves generated BUSY behavior marker');
    is($alias->{report}{busy_insertion}{htrans_busy_encoding}, "2'b01", 'alias exposes BUSY encoding');
    is($alias->{report}{busy_insertion}{before_beat}, 2, 'alias exposes before-beat index');
    is($alias->{report}{busy_insertion}{beats}, 'single', 'alias keeps single-presentation bound');
    is($alias->{report}{layering}{direct_ial2_to_ial0}, 0, 'alias still lowers through IAL1');

    my %alias_residue = map { $_->{id} => $_->{detail} } @{$alias->{report}{unsupported_residue}};
    ok(!exists $alias_residue{ahb_profile_alias_deferred}, 'alias removes source-surface profile-alias residue');
    like($alias_residue{ahb_requester_busy_insert_support}, qr/exactly 1 qualified requester HTRANS BUSY event/, 'alias keeps numeric exact-one BUSY residue');

    my %ppif_residue = map { $_->{id} => $_->{detail} } @{$ppif->{report}{unsupported_residue}};
    ok($ppif_residue{ahb_profile_alias_deferred}, 'generic source keeps its alias-deferred residue');
    is($alias_residue{ahb_requester_busy_insert_support}, $ppif_residue{ahb_requester_busy_insert_support}, 'alias and generic source keep identical BUSY support residue');
};

subtest 'check and semantic JSON expose profile-alias source and support identity' => sub {
    my $check = run_json_command('./bin/fsmgen', '--quiet', '--strict', '--check', '--json', alias_path());
    ok($check->{success}, 'strict alias check succeeds');
    is($check->{source}{resolved_path}, File::Spec->rel2abs(alias_path()), 'check JSON reports alias source path');
    is($check->{result}{module_name}, 'amba_requester_busy_insert', 'check JSON reports selected module');
    is($check->{support_accounting}{entry_id}, 'intent.ahb_profile_alias_requester_busy_insert', 'check JSON reports selected alias support identity');
    is($check->{support_accounting}{coverage}, 'ial2_ahb_profile_alias_requester_busy_insert_pipeline_cli', 'check JSON reports selected alias coverage');
    is($check->{support_accounting}{source_kind}, 'ial2_profile_alias', 'check JSON records profile-alias source kind');

    my $semantic = run_json_command('./bin/fsmgen', '--quiet', '--strict', '--emit-semantic-json', alias_path());
    ok($semantic->{success}, 'semantic JSON succeeds for alias');
    is($semantic->{source}{resolved_path}, File::Spec->rel2abs(alias_path()), 'semantic JSON reports alias source path');
    is($semantic->{generation_result_snapshot}{summary}{module_name}, 'amba_requester_busy_insert', 'semantic JSON reports selected module');
    is($semantic->{semantic}{module}{source_root_kind}, 'fsm', 'semantic JSON reports generated FSM root');
    is($semantic->{support_accounting}{entry_id}, 'intent.ahb_profile_alias_requester_busy_insert', 'semantic JSON reports alias support identity');
};

subtest 'schedule JSON and outdir preserve BUSY report and review artifacts' => sub {
    my $schedule = run_json_command('./bin/fsmgen', '--quiet', '--emit-schedule-json', alias_path());
    is($schedule->{schema}, 'fsmgen.ial2.protocol_intent.ahb_requester.v1', 'schedule JSON keeps requester schema');
    is($schedule->{busy_insertion}{htrans_busy_encoding}, "2'b01", 'schedule JSON keeps BUSY encoding');
    is($schedule->{busy_insertion}{before_beat}, 2, 'schedule JSON keeps insertion index');
    is($schedule->{busy_insertion}{beats}, 'single', 'schedule JSON keeps single-presentation bound');
    is($schedule->{generated_artifacts}{ial1}{name}, 'amba_requester_busy_insert.isf', 'schedule JSON names IAL1 artifact');
    is_deeply($schedule->{generated_artifacts}{ial0}{files}, ['amba_requester_busy_insert.fsm'], 'schedule JSON names IAL0 artifact');
    my %residue = map { $_->{id} => $_->{detail} } @{$schedule->{unsupported_residue}};
    ok(!exists $residue{ahb_profile_alias_deferred}, 'schedule JSON removes alias-deferred residue');
    ok($residue{ahb_requester_busy_insert_support}, 'schedule JSON keeps BUSY support residue');

    my $tempdir = create_project_tempdir(purpose => 'tests');
    my $outdir = File::Spec->catdir($tempdir, 'out');
    my $hdl = File::Spec->catfile($tempdir, 'amba_requester_busy_insert.sv');
    my ($success, undef, undef, $stdout, $stderr) = run(
        command => ['./bin/fsmgen', '--quiet', '--strict', '--outdir', $outdir, '--output', $hdl, alias_path()],
    );
    ok($success, 'alias emits HDL and review artifacts')
        or diag(join('', @{$stdout || []}), join('', @{$stderr || []}));
    is(join('', @{$stderr || []}), '', 'alias outdir generation keeps stderr clean');
    ok(-f File::Spec->catfile($outdir, 'amba_requester_busy_insert.isf'), 'outdir contains IAL1 artifact');
    ok(-f File::Spec->catfile($outdir, 'amba_requester_busy_insert.fsm'), 'outdir contains IAL0 artifact');
    ok(-f $hdl, 'outdir command emits HDL');
    like(slurp(File::Spec->catfile($outdir, 'amba_requester_busy_insert.isf')), qr/\(drive transfer_busy\b/, 'generated IAL1 keeps BUSY drive');
    like(slurp(File::Spec->catfile($outdir, 'amba_requester_busy_insert.fsm')), qr/busy_inserted_q/, 'generated IAL0 keeps one-shot state');
    like(slurp($hdl), qr/\bmodule\s+amba_requester_busy_insert\b/, 'generated HDL keeps selected module');
};

subtest 'base requester alias and generic BUSY source remain distinct and unchanged' => sub {
    my $base = FSM::Adapter::IAL2::PPIF->new()->parse_file(base_alias_path());
    ok(!exists($base->{report}{busy_insertion}), 'base requester alias remains BUSY-insertion free');
    unlike($base->{generated_ial1}{text}, qr/transfer_busy|busy_inserted_q/, 'base requester alias has no BUSY-insertion machinery');

    my $generic = run_json_command('./bin/fsmgen', '--quiet', '--strict', '--check', '--json', ppif_path());
    is($generic->{support_accounting}{entry_id}, 'intent.ppif_ahb_requester_busy_insert', 'generic source keeps PPIF support identity');
    is($generic->{support_accounting}{source_kind}, 'ppif', 'generic source keeps PPIF source kind');
};

done_testing();

sub ppif_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'ahb_requester_busy_insert.ppif');
}

sub alias_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'ahb_requester_busy_insert.ahb');
}

sub base_alias_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'ahb_requester.ahb');
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
