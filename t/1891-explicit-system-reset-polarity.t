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
use Lispish;
use FSM::Adapter::FSMGenFull;
use FSM::Support::CapabilityManifest qw(build_capability_manifest);
use FSM::Support::SemanticIntrospectionMCPAdapter;

my $root = abs_path('.');
my $work = tempdir(CLEANUP => 1);
my $json = JSON::PP->new->canonical->utf8;
my $capture = \&FSM::Test::SourceQueryRunner::_capture;
my $normalize = \&FSM::Test::SourceQueryRunner::normalize_repository_paths;
my $adapter = FSM::Support::SemanticIntrospectionMCPAdapter->new(repo_root => $root, workspace_root => $root);
my $serial = 0;

for my $kind (qw(sync async)) {
    for my $level (0, 1) {
        my $keyword = $kind eq 'sync' ? 'sreset' : 'areset';
        my $polarity = $level ? 'active_high' : 'active_low';
        # Intentionally oppose the old name heuristic: the modifier owns intent.
        my $name = $level ? 'reset_n' : 'reset_pin';
        my $path = source("($keyword $name $polarity)");
        subtest "$kind $polarity survives public semantics and source transports" => sub {
            my $module = FSM::Adapter::FSMGenFull->new(debug => 0)->parse_fsm(Lispish::multi($path));
            for my $contract ($module->effective_system_contract, $module->explicit_system_contract) {
                is($contract->{reset}, $name, 'authored name is retained');
                is($contract->{reset_keyword}, $keyword, 'reset keyword is retained');
                is($contract->{reset_kind}, $kind, 'reset kind is retained');
                is($contract->{reset_active_level}, $level, 'explicit level is not overwritten by a keyword default');
            }
            my $relative = File::Spec->abs2rel($path, $root);
            for my $query (qw(check semantic)) {
                my @flags = $query eq 'check' ? ('--check', '--json') : ('--emit-semantic-json');
                my $r = $capture->([$^X, 'bin/fsmgen', '--strict', @flags, $relative], '');
                is($r->{exit_code}, 0, "$query strict native query succeeds") or diag($r->{stdout},$r->{stderr});
                is($r->{stderr}, '', 'machine report has no stderr');
                my $report = $normalize->($json->decode($r->{stdout}), $root);
                ok($report->{success}, 'report declares success');
                if ($query eq 'semantic') {
                    for my $field (qw(system_contract explicit_system_contract)) {
                        is($report->{semantic}{$field}{reset_kind}, $kind, "$field exposes authored kind");
                        is($report->{semantic}{$field}{reset_active_level}, $level, "$field exposes authored active level");
                        is_deeply([sort keys %{$report->{semantic}{$field}}],
                            [sort qw(clock reset reset_keyword reset_kind reset_active_level),
                             ($field eq 'system_contract' ? qw(declare_ports implicit) : ())],
                            "$field adds no result fields");
                    }
                }
                my $request = {jsonrpc => '2.0', id => 1, method => 'tools/call', params => {
                    name => $query eq 'check' ? 'fsmgen_check' : 'fsmgen_semantic_introspect',
                    arguments => {source_id => $relative}}};
                my $api = $adapter->handle_jsonrpc_request($request);
                ok(!$api->{result}{isError}, 'public adapter reports success');
                is_deeply($api->{result}{structuredContent}{report}, $report, 'complete native/API report equality');
                my $wire = $capture->([$^X, 'bin/fsmgen-mcp', '--workspace-root', '.'], $json->encode($request)."\n");
                is($wire->{exit_code}, 0, 'actual newline MCP succeeds');
                is($wire->{stderr}, '', 'newline transport has no stderr');
                is_deeply($json->decode($wire->{stdout}), $api, 'complete actual newline/API response equality');
            }
        };
    }
}

subtest 'malformed and unsupported extended reset declarations fail closed' => sub {
    for my $case (
        ['(sreset reset active_middle)', 'FSMGEN_LANGUAGE_SYSTEM_RESET_POLARITY'],
        ['(sreset reset 0)', 'FSMGEN_LANGUAGE_SYSTEM_RESET_POLARITY'],
        ['(sreset reset (active_low))', 'FSMGEN_LANGUAGE_SYSTEM_RESET_POLARITY'],
        ['(sreset reset (+ 0 1))', 'FSMGEN_LANGUAGE_SYSTEM_RESET_POLARITY'],
        ['(areset reset_n active_middle)', 'FSMGEN_LANGUAGE_SYSTEM_RESET_POLARITY'],
        ['(sreset reset active_low extra)'], ['(sreset)'], ['(sreset (reset active_low))'],
        ['(clock spare active_low)'], ['(asreset rst_n active_low)'],
        ['(sreset reset active_high) (areset rst_n active_low)'],
        ['(sreset bad-name active_low)'],
    ) {
        my $path = source($case->[0]);
        for my $strict (0, 1) {
            my $r = $capture->([$^X, 'bin/fsmgen', ($strict ? '--strict' : ()), '--check', '--json', $path], '');
            is($r->{exit_code}, 1, "$case->[0] rejected in " . ($strict ? 'strict' : 'default') . ' mode');
            my $report = $json->decode($r->{stdout});
            ok(!$report->{success}, 'failure is explicit');
            is($report->{diagnostics}[0]{source_file}, $path, 'failure retains authored source');
            is($report->{diagnostics}[0]{code}, $case->[1], 'invalid literal polarity has stable code') if $case->[1];
        }
    }
};

subtest 'old forms retain their defaults and strict compatibility boundary' => sub {
    for my $case (
        ['(sreset reset)', 'sync', 1, 1], ['(areset rst_n)', 'async', 0, 1],
        ['(sreset rst_n)', 'sync', 1, 0], ['(areset reset)', 'async', 0, 0],
        ['(asreset rstn)', 'async', 0, 0],
    ) {
        my $path = source($case->[0]);
        my $module = FSM::Adapter::FSMGenFull->new(debug => 0)->parse_fsm(Lispish::multi($path));
        is($module->effective_system_contract->{reset_kind}, $case->[1], 'unmodified legacy kind');
        is($module->effective_system_contract->{reset_active_level}, $case->[2], 'unmodified legacy level');
        my $r = $capture->([$^X, 'bin/fsmgen', '--strict', '--check', '--json', $path], '');
        is($r->{exit_code}, $case->[3] ? 0 : 1, 'strict naming/alias admission is unchanged');
    }
    my $path = source('');
    my $r = $capture->([$^X, 'bin/fsmgen', '--strict', '--emit-semantic-json', $path], '');
    is($r->{exit_code}, 0, 'explicit clock-only source still passes');
    ok(!defined $json->decode($r->{stdout})->{semantic}{system_contract}{reset}, 'clock-only source gains no reset');
};

subtest 'invalid polarity preserves the full native failure through API and MCP' => sub {
    my $path = 't/corpus/system_reset_polarity.fsm';
    for my $query (qw(check semantic)) {
        my @flags = $query eq 'check' ? ('--check', '--json') : ('--emit-semantic-json');
        my $native = $capture->([$^X, 'bin/fsmgen', '--strict', @flags, $path], '');
        is($native->{exit_code}, 1, "$query rejects the invalid literal");
        is($native->{stderr}, '', 'machine failure has no stderr');
        my $report = $normalize->($json->decode($native->{stdout}), $root);
        is($report->{diagnostics}[0]{code}, 'FSMGEN_LANGUAGE_SYSTEM_RESET_POLARITY',
            'stable failure classification');
        my $request = {jsonrpc => '2.0', id => 1, method => 'tools/call', params => {
            name => $query eq 'check' ? 'fsmgen_check' : 'fsmgen_semantic_introspect',
            arguments => {source_id => $path}}};
        my $api = $adapter->handle_jsonrpc_request($request);
        ok($api->{result}{isError}, 'public adapter reports a tool failure');
        is_deeply($api->{result}{structuredContent}{report}, $report,
            'complete native/API failure equality');
        my $wire = $capture->([$^X, 'bin/fsmgen-mcp', '--workspace-root', '.'],
            $json->encode($request)."\n");
        is($wire->{exit_code}, 0, 'newline server transports the tool failure normally');
        is($wire->{stderr}, '', 'newline failure has no stderr');
        is_deeply($json->decode($wire->{stdout}), $api, 'complete newline/API failure equality');
    }
};

subtest 'capability discovery advertises every explicit form through API and MCP' => sub {
    my $expected = [map {my $k=$_; map {"($k NAME $_)"} qw(active_high active_low)} qw(sreset areset)];
    my $surface = build_capability_manifest()->{language_surface};
    is_deeply($surface->{system_contracts}{explicit_reset_polarity_forms}, $expected, 'public manifest advertises exact forms');
    my $request = {jsonrpc => '2.0', id => 1, method => 'tools/call', params => {
        name => 'fsmgen_capability_query', arguments => {section => 'language_surface'}}};
    my $api = $adapter->handle_jsonrpc_request($request);
    is_deeply($api->{result}{structuredContent}{payload}, $surface, 'API exposes the complete public language surface');
    my $wire = $capture->([$^X, 'bin/fsmgen-mcp', '--workspace-root', '.'], $json->encode($request)."\n");
    is($wire->{exit_code}, 0, 'newline capability query succeeds');
    is_deeply($json->decode($wire->{stdout}), $api, 'actual newline/API capability equality');
};

done_testing();
sub source {
    my ($reset) = @_;
    my $path = "$work/reset-" . ++$serial . '.fsm';
    open my $fh, '>', $path or die $!;
    print {$fh} "(?fsm:reset_carrier_$serial\n  (+system (clock clk) $reset)\n  (+size (Q 4 (reset 3)) (DATA 4))\n  (idle (<- (Q> DATA))))\n" or die $!;
    close $fh or die $!;
    return $path;
}
