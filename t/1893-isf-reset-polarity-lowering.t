#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Cwd qw(abs_path);
use File::Spec;
use File::Temp qw(tempdir);
use JSON::PP ();
use lib 'perl', 't/lib';
use FSM::Test::ProjectDataLocality;
use FSM::Test::SourceQueryRunner;
use FSM::Adapter::ISF;
use FSM::Scheduler::ISF;
use FSM::Adapter::FSMGenFull;
use FSM::Support::SemanticIntrospectionMCPAdapter;
use Lispish;

my $root = abs_path('.');
my $work = tempdir(CLEANUP => 1);
my $json = JSON::PP->new->canonical->utf8;
my $capture = \&FSM::Test::SourceQueryRunner::_capture;
my $normalize = \&FSM::Test::SourceQueryRunner::normalize_repository_paths;
my $adapter = FSM::Support::SemanticIntrospectionMCPAdapter->new(repo_root => $root, workspace_root => $root);
my $serial = 0;

for my $kind (qw(sync async)) {
    for my $level (0, 1) {
        my $polarity = $level ? 'active_high' : 'active_low';
        subtest "$kind $polarity reaches native/API/MCP without policy loss" => sub {
            my $reset = '(reset (reset_pin ' . ($kind eq 'async' ? 'async ' : '') . "$polarity))";
            my ($path, $actor, $lowered) = lower_source($reset);
            is_deeply($actor->{reset}, {name => 'reset_pin', kind => $kind, polarity => $polarity},
                'public actor retains authored reset policy');
            assert_carrier($lowered, $kind, $level, 'reset_pin');
            my $relative = File::Spec->abs2rel($path, $root);
            for my $query (qw(check semantic schedule)) {
                my %flags = (check => [qw(--strict --check --json)],
                    semantic => [qw(--strict --emit-semantic-json)], schedule => ['--emit-schedule-json']);
                my %tool = (check => 'fsmgen_check', semantic => 'fsmgen_semantic_introspect',
                    schedule => 'fsmgen_schedule_preview');
                my $r = $capture->([$^X, 'bin/fsmgen', @{$flags{$query}}, $relative], '');
                is($r->{exit_code}, 0, "$query native query succeeds") or diag($r->{stdout}, $r->{stderr});
                is($r->{stderr}, '', 'native machine report has no stderr');
                my $report = $normalize->($json->decode($r->{stdout}), $root);
                if ($query eq 'semantic') {
                    for my $field (qw(system_contract explicit_system_contract)) {
                        is($report->{semantic}{$field}{reset_kind}, $kind, "$field retains timing");
                        is($report->{semantic}{$field}{reset_active_level}, $level, "$field retains active level");
                    }
                } elsif ($query eq 'schedule') {
                    is_deeply($report->{reset}, $actor->{reset}, 'schedule agrees with the public parsed actor');
                }
                my $request = {jsonrpc => '2.0', id => 1, method => 'tools/call', params => {
                    name => $tool{$query}, arguments => {source_id => $relative}}};
                my $api = $adapter->handle_jsonrpc_request($request);
                ok(!$api->{result}{isError}, "$query public API succeeds");
                is_deeply($api->{result}{structuredContent}{report}, $report, 'complete native/API equality');
                my $wire = $capture->([$^X, 'bin/fsmgen-mcp', '--workspace-root', '.'],
                    $json->encode($request)."\n");
                is($wire->{exit_code}, 0, 'actual newline MCP succeeds');
                is($wire->{stderr}, '', 'MCP has no stderr');
                is_deeply($json->decode($wire->{stdout}), $api, 'complete newline/API response equality');
            }
        };
    }
}

subtest 'flat-name inference and explicit policy never inherit FSM naming heuristics' => sub {
    for my $case (
        ['', 'async', 0, 'rst_n', '(areset rst_n)'],
        ['(reset reset)', 'sync', 1, 'reset', '(sreset reset)'],
        ['(reset rst_n)', 'sync', 0, 'rst_n', '(sreset rst_n active_low)'],
        ['(reset rst_b)', 'sync', 0, 'rst_b', '(sreset rst_b active_low)'],
        ['(reset resetn)', 'sync', 1, 'resetn', '(sreset resetn active_high)'],
        ['(reset reset_N)', 'sync', 1, 'reset_N', '(sreset reset_N active_high)'],
        ['(reset (rst_n async active_low))', 'async', 0, 'rst_n', '(areset rst_n)'],
        ['(reset (reset async active_low))', 'async', 0, 'reset', '(areset reset active_low)'],
        ['(reset (rst_n async active_high))', 'async', 1, 'rst_n', '(areset rst_n active_high)'],
        ['(reset (rst_n active_high))', 'sync', 1, 'rst_n', '(sreset rst_n active_high)'],
    ) {
        my ($path, $actor, $lowered) = lower_source($case->[0]);
        is_deeply($actor->{reset}, {kind => $case->[1], polarity => $case->[2] ? 'active_high' : 'active_low', name => $case->[3]},
            "$case->[0] retains the established ISF policy");
        my ($file) = values %{$lowered->{files}};
        like($file, qr/\Q$case->[4]\E/, 'faithful carrier preserves already strict-supported old spellings');
        assert_carrier($lowered, @$case[1..3]);
    }
};

done_testing();

sub lower_source {
    my ($reset) = @_;
    my $name = 'reset_lowering_' . ++$serial;
    my $path = "$work/$name.isf";
    write_file($path, "(actor $name\n (clock clk) $reset\n"
        ." (interface (input DATA (width 4)) (output Q (width 4) (reset 3)))\n"
        ." (rule capture 1 (set Q DATA)))\n");
    my $actor = FSM::Adapter::ISF->new->parse_file($path);
    return ($path, $actor, FSM::Scheduler::ISF->new->lower($actor));
}
sub assert_carrier {
    my ($lowered, $kind, $level, $name) = @_;
    is(scalar(keys %{$lowered->{files}}), 1, 'ordinary actor emits one scheduled module');
    for my $file (sort keys %{$lowered->{files}}) {
        my $path = "$work/$file";
        write_file($path, $lowered->{files}{$file});
        my $module = FSM::Adapter::FSMGenFull->new(debug => 0)->parse_fsm(Lispish::multi($path));
        my $contract = $module->effective_system_contract;
        is($contract->{reset}, $name, 'scheduled carrier keeps the authored pin');
        is($contract->{reset_kind}, $kind, 'scheduled carrier keeps reset timing');
        is($contract->{reset_active_level}, $level, 'scheduled carrier keeps active level');
        my $check = $capture->([$^X, 'bin/fsmgen', '--strict', '--check', '--json', $path], '');
        is($check->{exit_code}, 0, 'generated artifact independently strict-checks') or diag($check->{stdout});
        is($check->{stderr}, '', 'generated artifact check has no stderr');
    }
}
sub write_file {
    open my $fh, '>', $_[0] or die $!;
    print {$fh} $_[1] or die $!;
    close $fh or die $!;
}
