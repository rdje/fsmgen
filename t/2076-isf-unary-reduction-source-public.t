use strict;
use warnings;
use lib 'perl', 't/lib';
use Test::More;
use JSON::PP;
use Cwd qw(abs_path);
use File::Temp qw(tempdir);
use Digest::SHA qw(sha256_hex);
use FSM::Test::ProjectDataLocality;
use FSM::Test::SourceQueryRunner qw(normalize_repository_paths);
use FSM::Support::SemanticIntrospectionMCPAdapter;
use FSM::Support::CapabilityManifest qw(build_capability_manifest);
use FSM::Adapter::ISF;
use FSM::Scheduler::ISF;

my $root = abs_path('.');
my $work = tempdir(CLEANUP => 1);
my $json = JSON::PP->new->canonical->utf8;
my $api = FSM::Support::SemanticIntrospectionMCPAdapter->new(repo_root => $root, workspace_root => $root);
my %flags = (check => [qw(--strict --check --json)], semantic => [qw(--strict --emit-semantic-json)],
    schedule => ['--emit-schedule-json']);
my %tools = (check => 'fsmgen_check', semantic => 'fsmgen_semantic_introspect', schedule => 'fsmgen_schedule_preview');
my @expected;
for my $case (
    [xor_check => '^','data',8], [all_check => '&','data',8], [any_check => '|','data',8],
    [odd_check => '^','data',8], [slice_check => '^','data[7:4]',4], [bit_check => '&','data[3]',1],
) {
    push @expected, {owner_kind=>'rule',owner=>$case->[0],context=>"rule '$case->[0]' action[0] RHS",
        kind=>'unary',operator=>$case->[1],operand=>$case->[2],operand_width=>$case->[3],result_width=>1};
}
sub record_rows { $_[1] eq 'schedule' ? $_[0]{reductions} : $_[0]{source}{reductions} }
sub same { is($json->encode($_[0]), $json->encode($_[1]), $_[2]); }
sub capture { FSM::Test::SourceQueryRunner::_capture($_[0], $_[1] // '') }
sub source {
    my ($name, $body, $extra) = @_;
    return "(actor $name (clock clk) (reset (rst_n sync active_low)) "
        . '(interface (input start) (input bus (width 8)) (output out) (output done)) '
        . ($extra // '') . ' ' . $body . ')';
}
sub file {
    my ($name, $text) = @_;
    my $path = "$work/$name.isf";
    open my $fh, '>', $path or die $!; print {$fh} $text; close $fh or die $!;
    return $path;
}
sub native {
    my ($path, $kind) = @_;
    return capture([$^X,'bin/fsmgen',@{$flags{$kind}},$path]);
}

subtest 'complete native API and actual newline products carry independently expected source records' => sub {
    for my $kind (qw(check semantic schedule)) {
        my $path = 'isf/unary_reductions.isf';
        my $native = native($path, $kind);
        is($native->{exit_code}, 0, "$kind source admits natively");
        is($native->{stderr}, '', "$kind machine stderr clean");
        my $report = normalize_repository_paths($json->decode($native->{stdout}), $root);
        same(record_rows($report,$kind), \@expected, "$kind literal owner/operator/operand/width inventory");
        my $request = {jsonrpc=>'2.0',id=>1,method=>'tools/call',params=>{
            name=>$tools{$kind},arguments=>{source_id=>$path}}};
        my $response = $api->handle_jsonrpc_request($request);
        ok(!$response->{error} && !$response->{result}{isError}, "$kind API succeeds");
        same($response->{result}{structuredContent}{report}, $report, "$kind complete native/API typed equality");
        same($json->decode($response->{result}{content}[0]{text}), $response->{result}{structuredContent},
            "$kind complete text/structured equality");
        my $wire = capture([$^X,'bin/fsmgen-mcp','--workspace-root','.'], $json->encode($request)."\n");
        is($wire->{exit_code}, 0, "$kind actual MCP process settles successfully");
        is($wire->{stderr}, '', "$kind MCP stderr clean");
        like($wire->{stdout}, qr/\A[^\n]+\n\z/, "$kind emits one compact newline record");
        same($json->decode($wire->{stdout}), $response, "$kind complete API/newline equality");
    }
};

subtest 'source consumers agree with actual generated IAL0 and preserve caller actor kinds' => sub {
    my $parser = FSM::Adapter::ISF->new;
    my $scheduler = FSM::Scheduler::ISF->new;
    my $actor = $parser->parse_file('isf/unary_reductions.isf');
    my $before = $json->encode($actor);
    my $lowered = $scheduler->lower($actor);
    is($json->encode($actor), $before, 'lowering keeps complete caller data and JSON kinds');
    for my $name (sort keys %{$lowered->{files}}) {
        my $path = "$work/$name";
        open my $fh, '>', $path or die $!; print {$fh} $lowered->{files}{$name}; close $fh or die $!;
        my $result = capture([$^X,'bin/fsmgen','--strict','--check','--json',$path]);
        is($result->{exit_code}, 0, "$name strictly replays through the public frontend");
        my $report = $json->decode($result->{stdout});
        ok($report->{success}, "$name actual native success");
        ok(!exists($report->{source}{reductions}), 'IAL0 carrier does not invent ISF source ownership');
    }
    same($json->decode($scheduler->report($actor))->{reductions}, \@expected, 'schedule uses the same literal source inventory');
};

subtest 'transaction sample local condition and used-drive contexts retain exact scalar results' => sub {
    my @cases = (
        ['local_sample', source('local_sample', '(transaction main (on start) (local tmp (width 8)) '
            . '(sample bus as snap) (set tmp bus) (when (^ snap) (set out (& tmp))) (complete done))'),
            [['^','snap',8],['&','tmp',8]]],
        ['drive', source('drive_case','(transaction main (on start) (drive tap) (complete done))',
            '(drive tap (out (| bus)))'), [['|','bus',8]]],
        ['wait', source('wait_case','(transaction main (on start) (wait (^ bus)) (complete done))'), [['^','bus',8]]],
    );
    for my $case (@cases) {
        my $path = file($case->[0],$case->[1]);
        for my $kind (qw(check schedule)) {
            my $result = native($path,$kind);
            is($result->{exit_code},0,"$case->[0] $kind admits") or diag($result->{stdout},$result->{stderr});
            next if $result->{exit_code};
            my $rows = record_rows($json->decode($result->{stdout}),$kind);
            same([map {[$_->{operator},$_->{operand},$_->{operand_width}]} @$rows], $case->[2],
                "$case->[0] $kind independently expected context operands");
            is_deeply([map {$_->{result_width}} @$rows], [(1)x@{$case->[2]}], "$case->[0] $kind scalar widths");
        }
    }
};

subtest 'unknown nonvector paths and static-value collisions refuse without declaration inventions' => sub {
    my @cases = (
        ['unknown', source('unknown','(rule r start (out (^ missing)))')],
        ['constant', source('constant_case','(rule r start (out (^ P)))','(params (P 8))')],
        ['literal', source('literal_case',q{(rule r start (out (^ 8'hAA)))})],
        ['path', source('path_case','(rule r start (out (^ bus[8])))')],
        ['expression', source('expression_case','(rule r start (out (^ (+ bus bus))))')],
        ['collision','(actor collision (params (P 8)) (interface (input P (width 8)) (output out)) (rule r 1 (out (^ P))))'],
    );
    for my $case (@cases) {
        my $path = file($case->[0],$case->[1]);
        for my $kind (qw(check semantic schedule)) {
            my $result = native($path,$kind);
            isnt($result->{exit_code},0,"$case->[0] $kind refuses");
            like($result->{stdout}.$result->{stderr},qr/(?:reduction|operand|path|scalar)/i,"$case->[0] $kind contextual cause");
            if ($kind ne 'schedule') {
                my $report = $json->decode($result->{stdout});
                ok(!$report->{success}, "$case->[0] $kind reports actual failure");
                ok(!exists($report->{source}{reductions}), "$case->[0] $kind has no invented source inventory");
            }
        }
    }
};

subtest 'shared capability discovery describes the same detached unary contract' => sub {
    my $manifest = build_capability_manifest();
    my $native = capture([$^X,'bin/fsmgen','--capability-manifest']);
    is($native->{exit_code},0,'native manifest succeeds');
    same($json->decode($native->{stdout}),$manifest,'complete native/in-process manifest equality');
    my $contract = $manifest->{semantic_exports}{normalized_semantic_json}{source_optional_fields}{reductions};
    same($manifest->{embedding}{isf_public_interface}{schedule_report_reductions}, $contract,
        'native shared discovery advertises the same schedule and semantic record contract');
    same($contract->{operator_values}, ['^','&','|'],'canonical operators advertised');
    same($contract->{source_forms}, ['(^ X)','(& X)','(| X)'],'authored unary forms advertised');
};

done_testing();
