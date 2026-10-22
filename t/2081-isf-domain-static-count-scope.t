use strict;
use warnings;
use lib 'perl', 't/lib';
use Test::More;
use JSON::PP;
use Storable qw(dclone);
use Cwd qw(abs_path);
use File::Temp qw(tempdir);
use FSM::Test::ProjectDataLocality;
use FSM::Test::SourceQueryRunner qw(normalize_repository_paths);
use FSM::Adapter::ISF;
use FSM::Scheduler::ISF;
use FSM::Support::SemanticIntrospectionMCPAdapter;

my $root=abs_path('.');
my $work=tempdir(CLEANUP=>1);
my $json=JSON::PP->new->canonical;
my %paths;
my $ready=1;
sub capture { FSM::Test::SourceQueryRunner::_capture($_[0],$_[1] // '') }
sub same { is($json->encode($_[0]),$json->encode($_[1]),$_[2]); }
sub write_file {
    my ($name,$text)=@_;my $path="$work/$name";
    open my $fh,'>',$path or die $!;print {$fh} $text;close $fh or die $!;
    $path =~ s/\A\Q$root\E\///;return $path;
}
sub source {
    my ($count_kind,$reduction)=@_;
    my $body=$reduction?'(^ count)':'count[0]';
    my $core=$count_kind eq 'wait'?'(wait count)':"(repeat count (set out $body))";
    my $aux=$count_kind eq 'wait'?'(wait count)':"(repeat count (set aux_out $body))";
    my $core_set=$count_kind eq 'wait'?"(set out $body)":'';
    my $aux_set=$count_kind eq 'wait'?"(set aux_out $body)":'';
    return <<ISF;
(actor domain_count_scopes
 (clock-domains (domain core (clock clk) (reset rst_n) :default)
  (domain aux (clock aux_clk) (reset aux_rst_n)))
 (interface (input start) (input count (width 8)) (output out) (output done)
  (input aux_start (domain aux)) (output aux_out (domain aux)) (output aux_done (domain aux)))
 (transaction main (ports (input count (width 4))) (params (count 2))
  (on start) (set count 4'd5) $core $core_set (complete done))
 (transaction aux_main (domain aux) (ports (input count (width 3))) (params (count 3))
  (on aux_start) (set count 3'd5) $aux $aux_set (complete aux_done)))
ISF
}
sub local_reports {
    my ($scheduler,$actor)=@_;
    my %reports;
    my $producer=\&FSM::Scheduler::ISF::Emitter::JSON::report_hash;
    {
        no warnings 'redefine';
        local *FSM::Scheduler::ISF::Emitter::JSON::report_hash=sub {
            my $report=$producer->(@_);
            $reports{$_[1]->{actor_name}}=dclone($report);
            return $report;
        };
        $scheduler->report($actor);
    }
    return \%reports;
}

for my $kind (qw(wait repeat)) {
    subtest "$kind static count does not read a same-named foreign wire" => sub {
        for my $reduction (0,1) {
            my $label=$reduction?'reduction':'baseline';
            my $text=source($kind,$reduction);
            $paths{$kind}{$label}=write_file("$kind-$label.isf",$text);
            my $actor=FSM::Adapter::ISF->new->parse_file($paths{$kind}{$label});
            my $before=$json->encode($actor);
            my $scheduler=FSM::Scheduler::ISF->new;
            my %modules;
            my $build=\&FSM::Scheduler::ISF::LoweringIR::build_module;
            my $lowered=eval {
                no warnings 'redefine';
                local *FSM::Scheduler::ISF::LoweringIR::build_module=sub {
                    my $ir=$build->(@_);
                    $modules{$_[1]->{actor_name}}=dclone($ir) if $_[1]->{_scheduled_domain_name};
                    return $ir;
                };
                $scheduler->lower($actor);
            };
            my $error=$@;
            my $ok=ok($lowered,"$label actual domain source lowers");
            $ready &&= $ok;diag($error) unless $ok;next unless $ok;
            my $reports=local_reports($scheduler,$actor);
            my $domains=$reports->{domain_count_scopes}{clock_domains};
            is(scalar @$domains,2,'both logical domains retain actual artifact identities');
            for my $case ([core=>'main',4,2],[aux=>'aux_main',3,3]) {
                my ($domain,$owner,$width,$count)=@$case;
                my ($metadata)=grep {$_->{name} eq $domain} @$domains;
                ok($metadata,"$domain logical domain has an allocated artifact");
                (my $module=$metadata->{scheduled_fsm}) =~ s/\.fsm\z//;
                my $report=$reports->{$module};
                ok($report,"$domain actual report producer observed");
                if ($kind eq 'wait') {
                    is_deeply([map {{kind=>$_->{count_kind},cycles=>$_->{cycles},source=>$_->{count_source}}}
                        @{$report->{transaction_waits}}],[{kind=>'static',cycles=>$count,source=>'count'}],
                        "$domain keeps independently expected static wait");
                } else {
                    my $ir=$modules{$module};
                    is_deeply([map {{source=>$_->{repeat_count_source},kind=>$_->{repeat_count_kind},
                        load=>$_->{assignments}[0]{rhs}}}
                        grep {($_->{kind} // '') eq 'repeat_init'} @{$ir->{states}}],
                        [{source=>'count',kind=>'static_or_unclassified',load=>$count}],
                        "$domain actual repeat state loads the independently expected static count");
                }
                if ($reduction) {
                    my $context="transaction '$owner' clause[".($kind eq 'wait'?4:3)."] ";
                    $context.=$kind eq 'wait'?'set RHS':"repeat clause[0] set RHS";
                    is_deeply($report->{reductions},[{owner_kind=>'transaction',owner=>$owner,context=>$context,
                        kind=>'unary',operator=>'^',operand=>'count',operand_width=>$width,result_width=>1}],
                        "$domain runtime read retains nearest formal width");
                } else {ok(!exists $report->{reductions},"$domain ordinary source invents no reduction inventory");}
            }
            mkdir "$work/$kind-$label" or die $!;
            my %carriers=map {$_=>write_file("$kind-$label/$_",$lowered->{files}{$_})}
                keys %{$lowered->{files}};
            for my $name (sort keys %carriers) {
                my $path=$carriers{$name};
                my $check=capture([$^X,'bin/fsmgen',qw(--strict --check --json),$path]);
                my $replayed=is($check->{exit_code},0,"$label $name actual carrier strictly replays");
                $ready &&= $replayed;diag($check->{stdout},$check->{stderr}) unless $replayed;
            }
            is($json->encode($actor),$before,"$label domain lowering/report preserves complete caller data/kinds");
        }
    };
}

subtest 'count names do not exempt actual runtime crossings' => sub {
    my $header=<<'ISF';
(actor actual_crossing
 (clock-domains (domain core (clock clk) :default) (domain aux (clock aux_clk)))
 (interface (input count (width 8)) (input aux_start (domain aux)) (output aux_out (domain aux)))
 (transaction aux_main (domain aux) (params (count 3)) (on aux_start) (wait count)
ISF
    for my $case (
        [expression=>"(wait (+ count 8'd1))",'wait clause'],
        [body=>'(repeat count (set aux_out count[0]))','set clause'],
        [guard=>'(when count (set aux_out 1))','when condition'],
    ) {
        my ($label,$body,$context)=@$case;
        my $actor=FSM::Adapter::ISF->new->parse_source($header.$body.'))',"$label.isf");
        my $ok=eval {FSM::Scheduler::ISF->new->lower($actor);1};
        my ($cause)=split /\n/,$@;
        ok(!$ok,"$label actual runtime read refuses");
        my $operand=$label eq 'body'?'count[0]':'count';
        is($cause,"ISF clock-domain violation: transaction 'aux_main' $context read signal '$operand' owned by domain 'core' from domain 'aux' without a crossing primitive",
            "$label retains its complete actual crossing cause");
    }
};

subtest 'native API and actual newline products retain the repaired domain source' => sub {
    plan skip_all=>'source/carrier prerequisite is red' unless $ready;
    my $api=FSM::Support::SemanticIntrospectionMCPAdapter->new(repo_root=>$root,workspace_root=>$root);
    my @rows=map {{owner_kind=>'transaction',owner=>$_->[0],context=>"transaction '$_->[0]' clause[4] set RHS",
        kind=>'unary',operator=>'^',operand=>'count',operand_width=>$_->[1],result_width=>1}}
        ['main',4],['aux_main',3];
    for my $case ([check=>[qw(--strict --check --json)],'fsmgen_check'],
        [semantic=>[qw(--strict --emit-semantic-json)],'fsmgen_semantic_introspect'],
        [schedule=>['--emit-schedule-json'],'fsmgen_schedule_preview']) {
        my ($kind,$flags,$tool)=@$case;
        my $native=capture([$^X,'bin/fsmgen',@$flags,$paths{wait}{reduction}]);
        my $success=is($native->{exit_code},0,"$kind native succeeds");
        diag($native->{stdout},$native->{stderr}) unless $success;next unless $success;
        is($native->{stderr},'',"$kind native stderr clean");
        my $report=normalize_repository_paths($json->decode($native->{stdout}),$root);
        same($kind eq 'schedule'?$report->{reductions}:$report->{source}{reductions},\@rows,
            "$kind independent source scopes remain authored");
        my $request={jsonrpc=>'2.0',id=>1,method=>'tools/call',params=>{name=>$tool,
            arguments=>{source_id=>$paths{wait}{reduction}}}};
        my $response=$api->handle_jsonrpc_request($request);
        my $ok=ok(!$response->{error} && ref($response->{result}) eq 'HASH'
            && !$response->{result}{isError} && ref($response->{result}{structuredContent}) eq 'HASH'
            && ref($response->{result}{structuredContent}{report}) eq 'HASH',"$kind API success");
        diag($json->encode($response)) unless $ok;next unless $ok;
        same($response->{result}{structuredContent}{report},$report,"$kind complete native/API equality");
        same($json->decode($response->{result}{content}[0]{text}),$response->{result}{structuredContent},"$kind text/structured equality");
        my $wire=capture([$^X,'bin/fsmgen-mcp','--workspace-root','.'],$json->encode($request)."\n");
        is($wire->{exit_code},0,"$kind newline succeeds");is($wire->{stderr},'',"$kind newline stderr clean");
        like($wire->{stdout},qr/\A[^\n]+\n\z/,"$kind one compact newline response");
        same($json->decode($wire->{stdout}),$response,"$kind complete API/newline equality");
    }
};
done_testing;
