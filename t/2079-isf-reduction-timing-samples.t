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
use FSM::Support::SemanticIntrospectionMCPAdapter;
use FSM::Support::ISFRecordPortScopes qw(record_timing_scope);

my $root=abs_path('.');
my $work=tempdir(CLEANUP=>1);
my $json=JSON::PP->new->canonical;
my @cases=([clock=>'clk','^','q'],[reset=>'rst_n','&','q'],
    [input=>'start','|','q'],[chain=>'clk','^','again']);
my (%paths,%expected);
my $ready=1;
sub capture { FSM::Test::SourceQueryRunner::_capture($_[0],$_[1] // '') }
sub same { is($json->encode($_[0]),$json->encode($_[1]),$_[2]); }
sub write_file {
    my ($name,$text)=@_;my $path="$work/$name";
    open my $fh,'>',$path or die $!;print {$fh} $text;close $fh or die $!;
    $path =~ s/\A\Q$root\E\///;return $path;
}
sub header {
    return '(actor timing_samples (clock clk) (reset (rst_n sync active_low)) '
        . '(interface (input start) (output out) (output done)) ';
}
for my $case (@cases) {
    my ($label,$signal,$op,$operand)=@$case;
    my $extra=$label eq 'chain'?'(sample q as again) ':'';
    for my $variant (qw(baseline reduction)) {
        my $rhs=$variant eq 'baseline'?$operand:"($op $operand)";
        $paths{$label}{$variant}=write_file("$label-$variant.isf",header()
            . "(transaction main (on start) (sample $signal as q) $extra(set out $rhs) (complete done)))");
    }
    my $index=$label eq 'chain'?3:2;
    $expected{$label}=[{owner_kind=>'transaction',owner=>'main',
        context=>"transaction 'main' clause[$index] set RHS",kind=>'unary',operator=>$op,
        operand=>$operand,operand_width=>1,result_width=>1}];
}

subtest 'shared timing facts preserve named declarations nearest masks and caller kinds' => sub {
    my $actor=FSM::Adapter::ISF->new->parse_file($paths{clock}{reduction});
    my $actor_before=$json->encode($actor);
    my $bit={role=>'input',type_spec=>{kind=>'bits',width=>1,signed=>0}};
    is_deeply(record_timing_scope(actor=>$actor,scope=>{}),{clk=>$bit,rst_n=>$bit},
        'actual declared clock/reset roots have intrinsic scalar widths');
    my $nearest={clk=>{role=>'local',type_spec=>undef},
        rst_n=>{role=>'local',type_spec=>{kind=>'bits',width=>'3',signed=>'1'}}};
    my $nearest_before=$json->encode($nearest);
    my $projected=record_timing_scope(actor=>$actor,scope=>$nearest);
    is_deeply($projected,$nearest,'nearer unknown and scalar declarations mask timing roots');
    $projected->{rst_n}{type_spec}{width}=9;
    is($json->encode($nearest),$nearest_before,'projection mutation preserves complete nearest caller kinds');
    is($json->encode($actor),$actor_before,'projection preserves complete actual source actor');
    my $named=FSM::Adapter::ISF->new->parse_source(
        '(actor named_timing (clock-domains (domain core (clock core_clk) :default) '
        . '(domain aux (clock aux_clk) (reset (aux_rst sync active_high)))) '
        . '(interface (input start) (output done)) '
        . '(transaction main (on start) (complete done)))','named-timing.isf');
    my $named_before=$json->encode($named);
    is_deeply(record_timing_scope(actor=>$named,scope=>{}),
        {core_clk=>$bit,aux_clk=>$bit,aux_rst=>$bit},
        'actual named domains add only declared timing pins; clock-only default gains no reset');
    is($json->encode($named),$named_before,'named-domain projection preserves complete source kinds');
};

for my $case (@cases) {
    my ($label,$signal,$op,$operand)=@$case;
    subtest "$label samples retain declared scalar width through actual source and carrier" => sub {
        my $baseline=capture([$^X,'bin/fsmgen','--strict','--check','--json',$paths{$label}{baseline}]);
        my $base_ok=is($baseline->{exit_code},0,'exact otherwise-identical non-reduction baseline strict-checks');
        diag($baseline->{stdout},$baseline->{stderr}) unless $base_ok;
        $ready &&= $base_ok;
        my $actor=eval {FSM::Adapter::ISF->new->parse_file($paths{$label}{reduction})};
        my $error=$@;
        my $parsed=ok($actor,'reduction uses the known declared sample source width');
        $ready &&= $parsed;diag($error) unless $parsed;return unless $parsed;
        my $before=$json->encode($actor);
        my $scheduler=FSM::Scheduler::ISF->new;
        my $lowered=$scheduler->lower($actor);
        my $report=$json->decode($scheduler->report($actor));
        is($json->encode($actor),$before,'complete source caller data/kinds stay unchanged');
        same($report->{reductions},$expected{$label},'independent source owner/operator/operand and one-bit widths');
        my %storage=map {$_->{name}=>$_} @{$report->{inferred_storage}};
        ok(!exists($storage{clk}) && !exists($storage{rst_n}),
            'known timing widths do not invent private clock/reset storage');
        my $carrier=$lowered->{files}{'timing_samples.fsm'};
        for my $alias ($label eq 'chain'?qw(q again):'q') {
            my $typed=like($carrier,qr/\(\Q$alias\E 1\)/,"$alias has explicit known carrier width instead of a default guess");
            $ready &&= $typed;
            is_deeply($storage{$alias},{name=>$alias,kind=>'register',role=>'sample_alias',width=>1},
                "$alias actual schedule retains independently known scalar storage width and role");
        }
        my $path=write_file("$label.fsm",$carrier);
        my $native=capture([$^X,'bin/fsmgen','--strict','--check','--json',$path]);
        my $success=is($native->{exit_code},0,'actual emitted carrier strictly replays');
        $ready &&= $success;diag($native->{stdout},$native->{stderr}) unless $success;
    };
}

subtest 'unknown static and namespace sample sources do not gain declarations' => sub {
    for my $case (
        [unknown=>'', 'missing'],
        [parameter=>'(params (P 1)) ', 'P'],
        [namespace=>'(enums (mode (BUSY 1))) ', 'mode.BUSY'],
    ) {
        my ($name,$extra,$source)=@$case;
        my $path=write_file("bad-$name.isf",header().$extra
            . "(transaction main (on start) (sample $source as q) (set out (^ q)) (complete done)))");
        my $native=capture([$^X,'bin/fsmgen','--strict','--check','--json',$path]);
        isnt($native->{exit_code},0,"$name refuses");
        my $report=$json->decode($native->{stdout});
        ok(!$report->{success},"$name reports actual failure");
        ok(!exists($report->{source}{reductions}),"$name failure invents no source inventory");
        my @causes=map {$_->{message}} @{$report->{diagnostics}};
        my $cause="Invalid ISF reductions: transaction 'main' clause[2] set RHS reduction '^' operand 'q' is not a declared packed scalar signal";
        if ($name eq 'namespace') {
            # Enum member sampling is refused by its existing source-context
            # owner before reduction capture; preserve that complete cause.
            $cause="Error: transaction 'main' references enum member 'mode.BUSY'; "
                . 'this ISF surface accepts enum member references only as actor constants, '
                . 'actor scalar parameter defaults or aggregate/list parameter default leaves, '
                . 'transaction scalar parameter defaults or aggregate/list parameter default leaves, '
                . 'activation scalar parameter overrides or aggregate/list override leaves, '
                . 'reusable-library use-site parameter override values or leaves, '
                . 'transaction condition scalar values or expression operands, '
                . 'transaction set RHS scalar values or operands, transaction switch selector or branch values, '
                . 'rule guard scalar values or expression operands, rule assignment RHS scalar values or operands, '
                . 'drive body RHS scalar values or operands, inline drive assignment RHS scalar values or operands, '
                . 'and drive-call actual scalar values or operands';
        }
        is_deeply(\@causes,[$cause],"$name retains its complete intended first cause");
    }
};

subtest 'complete native API and actual newline products expose known timing sample facts' => sub {
    plan skip_all=>'source/carrier prerequisite is red' unless $ready;
    my $api=FSM::Support::SemanticIntrospectionMCPAdapter->new(repo_root=>$root,workspace_root=>$root);
    for my $case ([check=>[qw(--strict --check --json)],'fsmgen_check'],
        [semantic=>[qw(--strict --emit-semantic-json)],'fsmgen_semantic_introspect'],
        [schedule=>['--emit-schedule-json'],'fsmgen_schedule_preview']) {
        my ($kind,$flags,$tool)=@$case;
        my $native=capture([$^X,'bin/fsmgen',@$flags,$paths{clock}{reduction}]);
        my $success=is($native->{exit_code},0,"$kind native succeeds");
        diag($native->{stdout},$native->{stderr}) unless $success;next unless $success;
        is($native->{stderr},'',"$kind native stderr clean");
        my $report=normalize_repository_paths($json->decode($native->{stdout}),$root);
        same($kind eq 'schedule'?$report->{reductions}:$report->{source}{reductions},$expected{clock},
            "$kind independently expected timing source records");
        my $request={jsonrpc=>'2.0',id=>1,method=>'tools/call',params=>{name=>$tool,
            arguments=>{source_id=>$paths{clock}{reduction}}}};
        my $response=$api->handle_jsonrpc_request($request);
        my $ok=ok(!$response->{error} && ref($response->{result}) eq 'HASH'
            && !$response->{result}{isError} && ref($response->{result}{structuredContent}) eq 'HASH'
            && ref($response->{result}{structuredContent}{report}) eq 'HASH',"$kind API success");
        diag($json->encode($response)) unless $ok;next unless $ok;
        same($response->{result}{structuredContent}{report},$report,"$kind complete native/API equality");
        same($json->decode($response->{result}{content}[0]{text}),$response->{result}{structuredContent},"$kind text/structured equality");
        my $wire=capture([$^X,'bin/fsmgen-mcp','--workspace-root','.'],$json->encode($request)."\n");
        is($wire->{exit_code},0,"$kind newline success");is($wire->{stderr},'',"$kind newline stderr clean");
        like($wire->{stdout},qr/\A[^\n]+\n\z/,"$kind one compact newline response");
        same($json->decode($wire->{stdout}),$response,"$kind complete API/newline equality");
    }
};

done_testing();
