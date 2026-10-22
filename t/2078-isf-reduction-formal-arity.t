use strict;
use warnings;
use lib 'perl', 't/lib';
use Test::More;
use JSON::PP;
use Cwd qw(abs_path);
use File::Temp qw(tempdir);
use FSM::Test::ProjectDataLocality;
use FSM::Test::SourceQueryRunner qw(normalize_repository_paths);
use FSM::Adapter::ISF;
use FSM::Scheduler::ISF;
use FSM::Scheduler::ISF::FormalIdentityPlan;
use FSM::Scheduler::ISF::FormalOperandResolver;
use FSM::Scheduler::ISF::FormalLowering;
use FSM::Support::SemanticIntrospectionMCPAdapter;

my $root = abs_path('.');
my $work = tempdir(CLEANUP => 1);
my $json = JSON::PP->new->canonical;
my @forms = ('^', '&', '|', 'xor', 'and', 'or');
my @operators = ('^', '&', '|', '^', '&', '|', '^');
my $source = '(actor formal_reductions (clock clk) (reset (rst_n sync active_low)) '
    . '(interface (input start) (input bus (width 8)) '
    . join(' ', map {"(output p$_)"} 0..6) . ' (output done)) '
    . '(transaction main (ports (input bus (width 3))) (on start) (set bus 3\'d5) '
    . join(' ', map {"(set p$_ ($forms[$_] bus))"} 0..5)
    . ' (set p6 (! (^ bus[2:1]))) (complete done)))';
my %paths;
for my $variant (qw(ordinary record_readonly)) {
    my $text = $source;
    if ($variant eq 'record_readonly') {
        $text =~ s/\Q(input start)\E/(input start) (input packet (type frame))/;
        $text =~ s/\Q(interface\E/(types (type frame (record (data (bits 4))))) (interface/;
        $text =~ s/\Q(set bus 3'd5)\E//;
    }
    my $path = "$work/$variant.isf";
    open my $fh, '>', $path or die $!; print {$fh} $text; close $fh or die $!;
    $path =~ s/\A\Q$root\E\///;
    $paths{$variant} = $path;
}
my $actor = FSM::Adapter::ISF->new->parse_file($paths{ordinary});
my $ready = 1;
sub capture { FSM::Test::SourceQueryRunner::_capture($_[0], $_[1] // '') }
sub same { is($json->encode($_[0]), $json->encode($_[1]), $_[2]); }
my @expected = map {{owner_kind=>'transaction',owner=>'main',
    context=>"transaction 'main' clause[".($_+2)."] set RHS",kind=>'unary',operator=>$operators[$_],
    operand=>$_==6?'bus[2:1]':'bus',operand_width=>$_==6?2:3,result_width=>1}} 0..6;

subtest 'detached rewriting preserves unary operators and nearest formal identity' => sub {
    my $before = $json->encode($actor);
    my $plan = FSM::Scheduler::ISF::FormalIdentityPlan->build($actor,
        generated_children=>{},reserved_names=>{});
    my $physical = $plan->{formals}{main}{bus}{physical_name};
    isnt($physical,'bus','formal receives a distinct physical identity');
    my $resolver = FSM::Scheduler::ISF::FormalOperandResolver->new(plan=>$plan,
        transaction=>'main',locals=>{},static_symbols=>{});
    for my $op (@forms) {
        my $input = [$op,'bus'];
        my $original = $json->encode($input);
        my $got = eval {$resolver->expression($input)};
        my $error = $@;
        same($got,[$op,$physical],"$op preserves authored operator and rewrites only the formal")
            or diag($error);
        is($json->encode($input),$original,"$op preserves complete input data/kinds");
    }
    my $nested = eval {$resolver->expression(['!', ['^','bus[2:1]']])};
    my $nested_error = $@;
    same($nested,['!', ['^',"$physical\[2:1]"]], 'nested unary keeps logical and slice roles') or diag($nested_error);
    for my $op (@forms) {
        same($resolver->expression([$op,'bus','start']),[$op,$physical,'start'],"$op existing binary roles unchanged");
    }
    for my $input (['^'],['+', 'bus'],['!', 'bus','start'],['!^','bus'],['concat','bus']) {
        my $ok = eval {$resolver->expression($input);1};
        my ($cause) = split /\n/,$@;
        ok(!$ok,'unrelated invalid arity refuses');
        like($cause // '',qr/\AFormal operand expression has invalid arity for /,'first-line arity cause retained');
    }
    is($json->encode($actor),$before,'planning and rewriting preserve complete source actor');
};

subtest 'actual formal lowering preserves physical widths and authored source inventory' => sub {
    for my $variant (qw(ordinary record_readonly)) {
        my $source_actor = FSM::Adapter::ISF->new->parse_file($paths{$variant});
        my $before = $json->encode($source_actor);
        my $scheduler = FSM::Scheduler::ISF->new;
        my $lowered = eval {$scheduler->lower($source_actor)};
        my $error = $@;
        my $success = ok($lowered,"$variant actual source lowers through formal rewriting");
        $ready &&= $success;
        diag($error) unless $success;
        next unless $success;
        is($json->encode($source_actor),$before,"$variant preserves complete caller data/kinds");
        my $context = FSM::Scheduler::ISF::FormalLowering->prepare($scheduler->{ir},$source_actor);
        my $physical = $context->{plan}{formals}{main}{bus}{physical_name};
        my $carrier = $lowered->{files}{'formal_reductions.fsm'};
        like($carrier,qr/\(bus 8\)/,"$variant actor input retains eight-bit width");
        like($carrier,qr/\(\Q$physical\E 3\)/,"$variant distinct formal retains three-bit width");
        like($carrier,qr/\Q(<- (p0> (^ $physical)))\E/,"$variant reduction reads actual private formal");
        my $path = "$work/$variant.fsm";
        open my $fh,'>',$path or die $!;print {$fh} $carrier;close $fh or die $!;
        my $replay = capture([$^X,'bin/fsmgen','--strict','--check','--json',$path]);
        my $ok = is($replay->{exit_code},0,"$variant actual carrier strictly replays");
        $ready &&= $ok;diag($replay->{stdout},$replay->{stderr}) unless $ok;
        my $expected = $json->decode($json->encode(\@expected));
        if ($variant eq 'record_readonly') {
            $_->{context} =~ s/clause\[(\d+)\]/'clause['.($1-1).']'/e for @$expected;
        }
        same($json->decode($scheduler->report($source_actor))->{reductions},$expected,
            "$variant authored source operands and independent widths survive physical renaming");
    }
};

subtest 'complete native API and actual newline products keep authored formal reductions' => sub {
    plan skip_all => 'actual carrier prerequisite is red' unless $ready;
    my $api=FSM::Support::SemanticIntrospectionMCPAdapter->new(repo_root=>$root,workspace_root=>$root);
    for my $case ([check=>[qw(--strict --check --json)],'fsmgen_check'],
        [semantic=>[qw(--strict --emit-semantic-json)],'fsmgen_semantic_introspect'],
        [schedule=>['--emit-schedule-json'],'fsmgen_schedule_preview']) {
        my ($kind,$flags,$tool)=@$case;
        my $native=capture([$^X,'bin/fsmgen',@$flags,$paths{ordinary}]);
        my $ok=is($native->{exit_code},0,"$kind native success");
        diag($native->{stdout},$native->{stderr}) unless $ok;next unless $ok;
        is($native->{stderr},'',"$kind native stderr clean");
        my $report=normalize_repository_paths($json->decode($native->{stdout}),$root);
        same($kind eq 'schedule'?$report->{reductions}:$report->{source}{reductions},\@expected,
            "$kind independent authored inventory uses formal width rather than outer input width");
        my $request={jsonrpc=>'2.0',id=>1,method=>'tools/call',params=>{name=>$tool,
            arguments=>{source_id=>$paths{ordinary}}}};
        my $response=$api->handle_jsonrpc_request($request);
        my $success=ok(!$response->{error} && ref($response->{result}) eq 'HASH'
            && !$response->{result}{isError} && ref($response->{result}{structuredContent}) eq 'HASH'
            && ref($response->{result}{structuredContent}{report}) eq 'HASH',"$kind API success");
        diag($json->encode($response)) unless $success;next unless $success;
        same($response->{result}{structuredContent}{report},$report,"$kind complete native/API equality");
        same($json->decode($response->{result}{content}[0]{text}),$response->{result}{structuredContent},"$kind text/structured equality");
        my $wire=capture([$^X,'bin/fsmgen-mcp','--workspace-root','.'],$json->encode($request)."\n");
        is($wire->{exit_code},0,"$kind newline success");is($wire->{stderr},'',"$kind newline stderr clean");
        like($wire->{stdout},qr/\A[^\n]+\n\z/,"$kind one compact newline response");
        same($json->decode($wire->{stdout}),$response,"$kind complete API/newline equality");
    }
};

done_testing();
