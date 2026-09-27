#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Storable qw(dclone);
use File::Temp qw(tempdir);
use lib 'perl', 't/lib';
use FSM::Test::ProjectDataLocality;
use FSM::Test::SourceQueryRunner;
use FSM::Adapter::ISF;
use FSM::Scheduler::ISF;
use FSM::Scheduler::ISF::FormalIdentityPlan;
use FSM::Scheduler::ISF::FormalClauseResolver;
use JSON::PP;

my $planner = 'FSM::Scheduler::ISF::FormalIdentityPlan';
my $walker = 'FSM::Scheduler::ISF::FormalClauseResolver';
my $actor = {actor_name => 'roles', transactions => [
    {name => 'main', ports => {inputs => [map {{name => $_, width => 4}} qw(data ready valid ram)],
        outputs => [{name => 'result', width => 4}]}, clauses => []},
    {name => 'worker', ports => {inputs => [{name => 'data', width => 4}], outputs => [{name => 'result', width => 4}]}, clauses => []},
    {name => 'child', ports => {inputs => [{name => 'data', width => 4}], outputs => [{name => 'result', width => 4}]}, clauses => []},
]};
my $plan = $planner->build($actor, generated_children => {child => 1}, reserved_names => {});
my %context = (plan => $plan, locals => {scratch => 1}, static_symbols => {COUNT => 1}, named_drives => {data => 1});
my $p = sub {$plan->{formals}{$_[0]}{$_[1]}{physical_name}};
my ($data, $result, $ready, $valid) = map {$p->('main', $_)} qw(data result ready valid);
my @cases = (
    [[], []],
    [['set', 'result', ['+', 'data', 1]], ['set', $result, ['+', $data, 1]]],
    [['update', 'result', 'data'], ['update', $result, $data]],
    [['sample', 'data', 'as', 'result'], ['sample', $data, 'as', $result]],
    [['complete', 'result'], ['complete', $result]],
    [['wait', ['+', 'data', 'COUNT']], ['wait', ['+', $data, 'COUNT']]],
    [['wait', 'COUNT'], ['wait', 'COUNT']],
    [['on', 'data', 'as', 'result', ['sample', 'data', 'as', 'result']],
     ['on', $data, 'as', 'result', ['sample', $data, 'as', $result]]],
    [['await', 'data', ['watchdog', 'data']], ['await', $data, ['watchdog', 'data']]],
    [['when', 'data', ['set', 'result', 'data']], ['when', $data, ['set', $result, $data]]],
    [['while', ['!=', 'data', 0], ['when', 'ready', ['exit-when', 'valid']], ['continue-when', 'data']],
     ['while', ['!=', $data, 0], ['when', $ready, ['exit-when', $valid]], ['continue-when', $data]]],
    [['until', 'data', ['set', 'result', 'data']], ['until', $data, ['set', $result, $data]]],
    [['repeat', 'data', ['repeat', 'COUNT', ['set', 'result', 'data']]],
     ['repeat', $data, ['repeat', 'COUNT', ['set', $result, $data]]]],
    [['switch', 'data', ['data', ['set', 'result', 'data']], ['default', ['update', 'result', 'data']]],
     ['switch', $data, ['data', ['set', $result, $data]], ['default', ['update', $result, $data]]]],
    [['drive', 'data', ['+', 'data', 1]], ['drive', 'data', ['+', $data, 1]]],
    [['drive', ['result', 'data']], ['drive', [$result, $data]]],
    [['drive', 'result', ['result', 'data']], ['drive', 'result', [$result, $data]]],
    [['shift_left', 'result', 'data', ['width', 'data']], ['shift_left', $result, $data, ['width', 'data']]],
    [['shift_right', 'result', 'data'], ['shift_right', $result, $data]],
    [['assemble', 'data', 'ready', 'as', 'result', ['widths', 'data', 'ready']],
     ['assemble', $data, $ready, 'as', $result, ['widths', 'data', 'ready']]],
    [['extract', 'data', 'as', 'result', 'valid', ['widths', 'result', 'valid']],
     ['extract', $data, 'as', $result, $valid, ['widths', 'result', 'valid']]],
    [['store', 'ram', 'data', 'result'], ['store', 'ram', $data, $result]],
    [['load', 'ram', 'data', 'as', 'result'], ['load', 'ram', $data, 'as', $result]],
    [['await_all', 'result'], ['await_all', $result]],
    [['await_any'], ['await_any']],
    [['point', 'data'], ['point', 'data']],
    [['phase', 'data', ['outputs', 'result'], ['next', 'data']], ['phase', 'data', ['outputs', 'result'], ['next', 'data']]],
    [['phase', 'data'], ['phase', 'data']],
    [['stage', 'data', ['ready', 'ready'], ['valid', 'valid']], ['stage', 'data', ['ready', 'ready'], ['valid', 'valid']]],
    [['stage', 'data', ['output', 'valid'], ['input', 'ready']], ['stage', 'data', ['output', 'valid'], ['input', 'ready']]],
    [['atl_trigger', 'data'], ['atl_trigger', 'data']],
    [['atl_trigger_batch', 'data', 'result'], ['atl_trigger_batch', 'data', 'result']],
    [['local', 'scratch', ['width', 4], ['init', 0], ['reset', 1]], ['local', 'scratch', ['width', 4], ['init', 0], ['reset', 1]]],
    [['latency', ['min', 'data'], ['max', 'result']], ['latency', ['min', 'data'], ['max', 'result']]],
    [['params', ['data', ['result', 'ready']]], ['params', ['data', ['result', 'ready']]]],
    [['assert', ['=>', ['at', 'data'], ['within', ['next', 'result'], 1, 4]], 'data result'],
     ['assert', ['=>', ['at', 'data'], ['within', ['next', $result], 1, 4]], 'data result']],
    [['assume', ['after', 'data', ['within', 'result', 4]]],
     ['assume', ['after', $data, ['within', $result, 4]]]],
    [['cover', ['==', 'data', ['past', 'data', 2]]], ['cover', ['==', $data, ['past', $data, 2]]]],
    [['assert', ['monitor', ['within', 'ready', 'data']], 'data'], ['assert', ['monitor', ['within', 'ready', 'data']], 'data']],
);
for my $fn (qw(stable changed rose fell)) {
    push @cases, [['assert', [$fn, 'data']], ['assert', [$fn, $data]]];
}
for my $i (0 .. $#cases) {
    my $tx = {%{$actor->{transactions}[0]}, clauses => [$cases[$i][0]]};
    my $before = dclone($tx);
    my $out = $walker->transaction($tx, %context);
    is_deeply($out->{transaction}{clauses}, [$cases[$i][1]], "role case $i rewritten precisely");
    is_deeply($tx, $before, "role case $i input preserved");
    is($out->{transaction}{ports}{inputs}[0]{name}, $data, 'formal declaration renamed with operands');
    is($out->{transaction}{ports}{inputs}[0]{width}, 4, 'formal declaration width retained');
}

subtest 'activation paths retain source projections and every static identity' => sub {
    my $tx = {%{$actor->{transactions}[0]}, clauses => [
        ['when', 'data', ['do', 'worker', ['bind', ['input', 'data', 'data'], ['output', 'result', 'result']], ['domain', 'data']]],
        ['spawn', 'child', 'as', 'data', ['params', ['data', ['data', 'result']]],
            ['bind', ['input', 'data', ['+', 'data', 1], ['timing', 'live']], ['output', 'result', 'result']]],
    ]};
    my $out = $walker->transaction($tx, %context);
    is_deeply($out->{transaction}{clauses}, [
        ['when', $data, ['do', 'worker', ['bind', ['input', $p->('worker','data'), $data], ['output', $p->('worker','result'), $result]], ['domain', 'data']]],
        ['spawn', 'child', 'as', 'data', ['params', ['data', ['data', 'result']]],
            ['bind', ['input', 'data', ['+', $data, 1], ['timing', 'live']], ['output', 'result', $result]]],
    ], 'callee names, instance labels, static params/domains and timing preserved');
    is_deeply($out->{bindings}[0]{path}, ['clauses', 0, 2, 2, 1], 'nested source binding has structural location');
    is_deeply($out->{bindings}[0]{source}, ['input', 'data', 'data'], 'source entry retained independently');
    is($out->{bindings}[2]{formal}{placement}, 'generated_child_interface', 'generated endpoint placement retained');
    $out->{transaction}{clauses}[1][4][1][1][0] = 'changed';
    is($tx->{clauses}[1][4][1][1][0], 'data', 'nested static structures are detached');
};

subtest 'actor rule source roles remain actor-owned while bindings address callee ports' => sub {
    my $rule = {name => 'data', domain => 'result', when => ['when', ['!=', 'data', 0]], actions => [
        ['trigger', 'worker', ['bind', ['input', 'data', 'data']]],
        ['trigger', 'child', ['params', ['data', 'result']], ['bind', ['input', 'data', 'data'], ['output', 'result', 'result']]],
        ['priority', 'over', 'data'], ['pulse', 'result'], ['set', 'result', 'data'], ['result', ['+', 'data', 1]],
        ['store', 'ram', 'data', 'result'], ['load', 'ram', 'data', 'as', 'result'], ['atl_trigger', 'data'],
    ]};
    my $before = dclone($rule);
    my $out = $walker->rule($rule, %context, locals => {});
    my $expected = dclone($rule);
    $expected->{actions}[0][2][1][1] = $p->('worker','data');
    is_deeply($out->{rule}, $expected, 'only direct callee endpoint changes in actor rule');
    is_deeply($out->{bindings}[0]{path}, ['actions', 0, 2, 1], 'rule binding has source action path');
    is_deeply($rule, $before, 'rule source stays unchanged');
};

for my $bad (
    ['unknown', 'data'], ['sample','data','to','result'], ['on','data',['set','result',0]],
    ['on','data','as','data','as','result'], ['await','data',['mystery',4]],
    ['drive','missing'], ['drive',['result','data',1]], ['shift_left','result','data',['bits',4]],
    ['assemble','data','result'], ['extract','data','as','result',['widths',['data']]],
    ['store','ram','data'], ['load','ram','data','to','result'], ['await_all','data','result'],
    ['assert','data',['message','data']], ['assert',['monitor',['within',['+','data',1],4]]],
    ['stage','data',['ready','ready'],['input','data']], ['local','unknown',['width',4]],
    ['local','scratch',['type','data']], ['latency',['mystery',4]],
    ['do','worker',['typo','data']], ['spawn','child','as'],
    ['do','worker',['bind',['input','data','data'],['input','data','data']]],
    ['do','worker',['params',['data',1]],['params',['data',2]]],
    ['wait',['~','data']], ['wait',['&&','data','data']], ['wait',['concat','data']],
) {
    my $tx = {%{$actor->{transactions}[0]}, clauses => [$bad]};
    my $before = dclone($tx);
    eval {$walker->transaction($tx, %context)};
    like($@, qr/Formal (?:clause|operand)/, 'malformed role fails closed: ' . JSON::PP->new->encode($bad));
    is_deeply($tx, $before, 'failed rewrite leaves source intact');
}
eval {$walker->transaction($actor->{transactions}[0], %context, locals => {data => 1})};
like($@, qr/duplicates a transaction formal/, 'physical rename cannot legalize an existing source local/formal collision');
eval {$walker->transaction($actor->{transactions}[0], %context, transaction => 'child')};
like($@, qr/owner is selected by the source record/, 'caller cannot override transaction record owner');

subtest 'parsed normalized helpers and strict public carrier replay' => sub {
    my $source = <<'ISF';
(actor scoped_replay
 (clock clk) (reset (rst_n async active_low))
 (interface (input start) (output done))
 (storage (var data (width 8) (reset 19)))
 (transaction main (ports (input data (width 4)) (output result (width 4)))
  (on start as result)
  (set result data)
  (clear-bit result 1)
  (when-bit data 0 (incr result))
  (assert (=> (at result) (next (== result (past data)))) "data result")
  (complete done)))
ISF
    my $parsed = FSM::Adapter::ISF->new->parse_source($source, 'scoped_replay.isf');
    my $before = dclone($parsed);
    my $p = $planner->build($parsed, generated_children => {}, reserved_names => {});
    my $out = $walker->transaction($parsed->{transactions}[0], plan => $p,
        locals => {}, static_symbols => {}, named_drives => {});
    my $physical = dclone($parsed);
    $physical->{transactions}[0] = $out->{transaction};
    my $lowered = FSM::Scheduler::ISF->new->lower($physical);
    my $fsm = $lowered->{files}{'scoped_replay.fsm'};
    like($fsm, qr/\(data 8 \(reset 19\)\)/, 'actor declaration/reset remains separate');
    my $private = $p->{formals}{main}{data}{physical_name};
    like($fsm, qr/\(\Q$private\E 4\)/, 'physical formal keeps its own width');
    like($fsm, qr/"data result"/, 'authored check message remains intact');
    my $work = tempdir(CLEANUP => 1);
    my $file = "$work/scoped_replay.fsm";
    open my $fh, '>', $file or die $!;print $fh $fsm;close $fh;
    my $check = FSM::Test::SourceQueryRunner::_capture([$^X, 'bin/fsmgen', '--strict', '--check', '--json', $file], '');
    is($check->{exit_code}, 0, 'transformed carrier passes independent strict public replay') or diag($check->{stdout},$check->{stderr});
    is_deeply($parsed, $before, 'source actor, bit-helper expansion and report input remain intact');
    eval {FSM::Scheduler::ISF->new->lower($parsed)};
    like($@, qr/signal width for 'data' conflicts/, 'ordinary production route still has the owned integration boundary');
};

subtest 'parsed controller cohort keeps source records and strict carrier validity' => sub {
    my @sources = sort glob('t/data/logical-controller-shadow/*.isf');
    ok(@sources, 'tracked controller cohort is present');
    for my $file (@sources) {
        open my $fh, '<', $file or die $!;
        my $source = do { local $/; <$fh> };close $fh;
        my $a = FSM::Adapter::ISF->new->parse_source($source, $file);
        my $before = dclone($a);
        my $generated = $file =~ /binding_generated_live/ ? {worker => 1} : {};
        my $p = $planner->build($a, generated_children => $generated, reserved_names => {});
        my $physical = dclone($a);
        for my $i (0 .. $#{$a->{transactions}}) {
            my %static;
            for my $cl (@{$a->{transactions}[$i]{clauses}}) {
                next unless ref($cl) eq 'ARRAY' && ($cl->[0] // '') eq 'params';
                $static{$_->[0]} = 1 for @$cl[1 .. $#$cl];
            }
            $physical->{transactions}[$i] = $walker->transaction($a->{transactions}[$i],
                plan => $p, locals => {}, static_symbols => \%static, named_drives => {})->{transaction};
        }
        $physical->{rules} = [map {$walker->rule($_, plan => $p, locals => {},
            static_symbols => {}, named_drives => {})->{rule}} @{$a->{rules} || []}];
        my $lowered = FSM::Scheduler::ISF->new->lower($physical);
        my $work = tempdir(CLEANUP => 1);
        my @carriers = grep {/\.fsm\z/} sort keys %{$lowered->{files}};
        ok(@carriers, "$file emits carrier artifacts");
        for my $name (@carriers) {
            my $path = "$work/$name";
            open my $out, '>', $path or die $!;print $out $lowered->{files}{$name};close $out;
            my $check = FSM::Test::SourceQueryRunner::_capture([$^X, 'bin/fsmgen', '--strict', '--check', '--json', $path], '');
            is($check->{exit_code}, 0, "$file / $name strict replay") or diag($check->{stdout},$check->{stderr});
        }
        is_deeply($a, $before, "$file source/report input preserved");
    }
};
done_testing;
