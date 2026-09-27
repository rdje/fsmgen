#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use JSON::PP;
use Cwd qw(abs_path);
use lib 'perl', 't/lib';
use FSM::Test::ProjectDataLocality;
use FSM::Test::SourceQueryRunner;
use FSM::Support::ISFPublicInterfaceContract qw(build_isf_public_interface_contract);
use FSM::Support::SemanticIntrospectionMCPAdapter;

my $source = 't/data/isf_schedule_generated_role_families.isf';
my $root = abs_path('.');
my $json = JSON::PP->new->canonical;
my $capture = \&FSM::Test::SourceQueryRunner::_capture;
my $check = $capture->([$^X,'bin/fsmgen','--strict','--check','--json',$source], '');
is($check->{exit_code}, 0, 'generated report fixture strict-checks') or diag($check->{stdout}, $check->{stderr});
my $native = $capture->([$^X,'bin/fsmgen','--emit-schedule-json',$source], '');
is($native->{exit_code}, 0, 'generated storage/completion schedule succeeds') or diag($native->{stdout}, $native->{stderr});
BAIL_OUT('cannot inspect generated report') if $native->{exit_code};
my $report = FSM::Test::SourceQueryRunner::normalize_repository_paths($json->decode($native->{stdout}), $root);
my $contract = build_isf_public_interface_contract();

for my $family (
    ['inferred_storage','role','schedule_report_storage_role_values',
        [qw(child_completion_output_handoff child_completion_seen child_completion_view local_completion_pulse)]],
    ['dt_blocks','kind','schedule_report_dt_kind_values',
        [qw(actor_storage_read_handoff actor_storage_write_handoff child_completion child_completion_output)]],
) {
    my ($table,$field,$advertisement,$required) = @$family;
    my %observed = map {$_->{$field} => 1} grep {defined $_->{$field}} @{$report->{$table}};
    my %declared = map {$_ => 1} @{$contract->{$advertisement}};
    is_deeply([sort grep {!$declared{$_}} keys %observed], [], "$table has no unadvertised $field");
    for my $value (@$required) {
        ok($observed{$value}, "$table exercises $value through production lowering");
        my %omitted = %declared; delete $omitted{$value};
        is_deeply([sort grep {!$omitted{$_}} keys %observed], [$value], "omitting $value is detected by actual-report membership");
    }
}
my $adapter = FSM::Support::SemanticIntrospectionMCPAdapter->new(repo_root=>$root,workspace_root=>$root);
my $request = {jsonrpc=>'2.0',id=>1,method=>'tools/call',params=>{
    name=>'fsmgen_schedule_preview',arguments=>{source_id=>$source}}};
my $response = $adapter->handle_jsonrpc_request($request);
ok(!$response->{error} && !$response->{result}{isError}, 'API schedule succeeds');
is_deeply($response->{result}{structuredContent}{report}, $report, 'complete native/API generated report agrees');
my $wire = $capture->([$^X,'bin/fsmgen-mcp','--workspace-root','.'], $json->encode($request)."\n");
is($wire->{exit_code}, 0, 'newline schedule succeeds');
is_deeply($json->decode($wire->{stdout}), $response, 'complete newline/API generated response agrees');

done_testing();
