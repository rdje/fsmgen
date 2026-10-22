use strict;
use warnings;
use lib 'perl', 't/lib';
use Test::More;
use JSON::PP;
use Cwd qw(abs_path);
use File::Temp qw(tempdir);
use FSM::Test::ProjectDataLocality;
use FSM::Test::SourceQueryRunner qw(normalize_repository_paths);
use FSM::Support::SemanticIntrospectionMCPAdapter;
use FSM::Adapter::ISF;
use FSM::Scheduler::ISF;

my $root = abs_path('.');
my $work = tempdir(CLEANUP => 1);
my $json = JSON::PP->new->canonical;
my $template = <<'ISF';
(actor delegated_sampling
 (clock clk) (reset (rst_n sync active_low))
 (types (type frame (record
   (payload (four_state (signed (bits 3)))) (ready (two_state bit)))))
 (interface (input start) (input bus (width 8)) (output out) (output done))
 (storage (var packet (type frame) (reset 0)))
 (transaction main (on start) (sample packet as q)
   (set out RHS) (complete done)))
ISF
my %paths;
for my $case ([baseline=>'bus[0]'], [reduced=>'(^ bus)'],
    [chain_baseline=>'bus[0]'], [chain_reduced=>'(^ bus)']) {
    my $source = $template;
    $source =~ s/RHS/$case->[1]/;
    $source =~ s/\Q(sample packet as q)\E/(sample packet as q) (sample q as again)/
        if $case->[0] =~ /\Achain_/;
    my $path = "$work/$case->[0].isf";
    open my $fh, '>', $path or die $!;
    print {$fh} $source; close $fh or die $!;
    $path =~ s/\A\Q$root\E\///;
    $paths{$case->[0]} = $path;
}
my $ready;
my $expected = [{owner_kind=>'transaction',owner=>'main',
    context=>"transaction 'main' clause[2] set RHS",kind=>'unary',operator=>'^',
    operand=>'bus',operand_width=>8,result_width=>1}];
sub capture { FSM::Test::SourceQueryRunner::_capture($_[0], $_[1] // '') }
sub same { is($json->encode($_[0]), $json->encode($_[1]), $_[2]); }

for my $prefix ('', 'chain_') {
subtest "${prefix}unrelated reduction preserves the actual delegated storage sample carrier" => sub {
    my $baseline = FSM::Adapter::ISF->new->parse_file($paths{"${prefix}baseline"});
    my $legacy = FSM::Scheduler::ISF->new->lower($baseline);
    my $reduced = eval { FSM::Adapter::ISF->new->parse_file($paths{"${prefix}reduced"}) };
    ok($reduced, 'otherwise identical reduced source admits delegated whole-storage sample')
        or diag($@);
    return unless $reduced;
    my $before = $json->encode($reduced);
    my $current = FSM::Scheduler::ISF->new->lower($reduced);
    is($json->encode($reduced), $before, 'lowering preserves complete caller data and kinds');
    same([sort keys %{$current->{files}}], [sort keys %{$legacy->{files}}],
        'actual module family remains unchanged');
    $ready = 1 if $prefix eq '';
    for my $name (sort keys %{$legacy->{files}}) {
        my $expected_carrier = $legacy->{files}{$name};
        my $replacements = $expected_carrier =~ s/\Q(<- (out> bus[0]))\E/(<- (out> (^ bus)))/g;
        is($replacements, 1, 'the retained baseline has exactly the authored RHS change');
        my $equal = is($current->{files}{$name}, $expected_carrier,
            'unrelated sample declarations, types, capture and states retain their carrier bytes');
        $ready &&= $equal if $prefix eq '';
        my $path = "$work/$name";
        open my $fh, '>', $path or die $!;
        print {$fh} $current->{files}{$name}; close $fh or die $!;
        my $replay = capture([$^X,'bin/fsmgen','--strict','--check','--json',$path]);
        my $success = is($replay->{exit_code},0,'actual reduced carrier strictly replays');
        diag($replay->{stdout},$replay->{stderr}) unless $success;
        $ready &&= $success if $prefix eq '';
    }
};
}

subtest 'native API and newline products retain the delegated source and independent inventory' => sub {
    plan skip_all => 'carrier prerequisite is red' unless $ready;
    my $api = FSM::Support::SemanticIntrospectionMCPAdapter->new(repo_root=>$root,workspace_root=>$root);
    for my $case (
        [check=>[qw(--strict --check --json)],'fsmgen_check'],
        [semantic=>[qw(--strict --emit-semantic-json)],'fsmgen_semantic_introspect'],
        [schedule=>['--emit-schedule-json'],'fsmgen_schedule_preview'],
    ) {
        my ($kind,$flags,$tool) = @$case;
        my $native = capture([$^X,'bin/fsmgen',@$flags,$paths{reduced}]);
        my $success = is($native->{exit_code},0,"$kind native success");
        diag($native->{stdout},$native->{stderr}) unless $success;
        next unless $success;
        is($native->{stderr},'',"$kind clean machine stderr");
        my $report = normalize_repository_paths($json->decode($native->{stdout}),$root);
        same($kind eq 'schedule' ? $report->{reductions} : $report->{source}{reductions},
            $expected,"$kind independently expected source owner and widths");
        my $request={jsonrpc=>'2.0',id=>1,method=>'tools/call',params=>{
            name=>$tool,arguments=>{source_id=>$paths{reduced}}}};
        my $response=$api->handle_jsonrpc_request($request);
        my $api_success = ok(!$response->{error} && ref($response->{result}) eq 'HASH'
            && !$response->{result}{isError} && ref($response->{result}{structuredContent}) eq 'HASH'
            && ref($response->{result}{structuredContent}{report}) eq 'HASH',"$kind API success");
        diag($json->encode($response)) unless $api_success;
        next unless $api_success;
        same($response->{result}{structuredContent}{report},$report,"$kind complete native/API equality");
        same($json->decode($response->{result}{content}[0]{text}),$response->{result}{structuredContent},
            "$kind complete text/structured equality");
        my $wire=capture([$^X,'bin/fsmgen-mcp','--workspace-root','.'],$json->encode($request)."\n");
        is($wire->{exit_code},0,"$kind newline process success");
        is($wire->{stderr},'',"$kind newline stderr clean");
        like($wire->{stdout},qr/\A[^\n]+\n\z/,"$kind one compact response");
        same($json->decode($wire->{stdout}),$response,"$kind complete API/newline equality");
    }
};

done_testing();
