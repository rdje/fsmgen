#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Storable qw(dclone);
use JSON::PP;
use File::Temp qw(tempdir);
use lib 'perl', 't/lib';
use FSM::Test::ProjectDataLocality;
use FSM::Test::SourceQueryRunner;
use FSM::Adapter::ISF;
use FSM::Scheduler::ISF;
use FSM::Scheduler::ISF::WriterActivation;

my $collector = 'FSM::Scheduler::ISF::WriterActivation';
my $scheduler = FSM::Scheduler::ISF->new;
my $work = tempdir(CLEANUP => 1);
my $capture = \&FSM::Test::SourceQueryRunner::_capture;
my $json = JSON::PP->new;
my $source = <<'ISF';
(actor activation_predicates (clock clk) (reset rst_n)
 (interface (input req) (input allow) (input ack) (input data (width 8))
  (output done) (output observed (width 8)) (output disabled (width 8)))
 (transaction main (when (& req allow) (sample data as captured))
  (assert (monitor (within ack 3))) (repeat 3 (wait 1))
  (set observed captured) (complete done) (latency (min 2) (max 12)))
 (rule never (when 0) (set disabled 5)))
ISF
my $actor = FSM::Adapter::ISF->new->parse_source($source, 'activation_predicates.isf');
my $ir = $scheduler->{ir}->build_module($actor);
sub write_file {
    my ($name, $text) = @_;
    open my $fh, '>', "$work/$name" or die $!;
    print {$fh} $text;
    close $fh or die $!;
    return "$work/$name";
}
sub state {
    my ($guard, $op) = @_;
    return {name => 'entry', kind => 'entry', guard => {port => 'start'},
        transitions => [{target => 'entry'}],
        assignments => [{lhs => 'value', rhs => '7', op => $op // '<-', guard => $guard}]};
}

subtest 'actual state and DT predicates remain detached from transition context' => sub {
    my $before = dclone($ir);
    my @records;
    for my $kind (qw(state dt)) {
        for my $container (@{$ir->{$kind eq 'state' ? 'states' : 'dt_blocks'}}) {
            for my $index (0 .. $#{$container->{assignments}}) {
                push @records, $collector->resolve($kind, $container, $index);
            }
        }
    }
    my ($sample) = grep {$_->{target} eq 'captured'} @records;
    is_deeply($sample->{assignment_enable}, {
        raw => {expr => '(& req allow)', expr_ast => ['&', 'req', 'allow']},
        predicate => {kind => 'truthy', source_field => 'expr', expression => '(& req allow)'},
    }, 'actual inline sample retains expression text and independent structured AST');
    is_deeply($sample->{container_enable}, {kind => 'state_active', state => $sample->{container_name}},
        'state membership is an explicit container condition');
    my ($bookkeeping) = grep {$_->{target} eq 'can_accept'} @records;
    is($bookkeeping->{assignment_enable}{predicate}{kind}, 'always', 'entry bookkeeping is not guarded by the entry condition');
    is($bookkeeping->{state_transition_context}{guard}{predicate}{expression}, '(& req allow)',
        'entry condition remains separate context');
    my ($decrement) = grep {$_->{operator} eq '--'} @records;
    ok($decrement, 'actual repeat lowering produces a decrement');
    is($decrement->{assignment_guard_placement}, 'none', 'actual decrement has no emitted guard');
    my ($comparison) = grep {$_->{assignment_enable}{predicate}{kind} eq 'comparison'} @records;
    is_deeply($comparison->{assignment_enable}{predicate},
        {kind => 'comparison', signal => 'main_cc', operator => '<', value => 2},
        'latency error retains its actual comparison');
    my ($rule) = grep {$_->{target} eq 'disabled'} @records;
    is_deeply($rule->{container_enable}, {kind => 'dt_header', guard => {
        raw => {port => '0'}, predicate => {kind => 'truthy', source_field => 'port', expression => '0'}}},
        'literal false DT header controls the writer');
    is($rule->{assignment_enable}{predicate}{kind}, 'always', 'rule body does not duplicate its DT header condition');
    my @monitors = grep {$_->{container_name} =~ /monitor/} @records;
    ok(@monitors && (grep {$_->{assignment_enable}{predicate}{kind} eq 'truthy'} @monitors),
        'actual monitor DT assignments retain expression enables');
    is_deeply($ir, $before, 'collection never modifies the production IR');
    $sample->{assignment_enable}{raw}{expr_ast}[1] = 'mutated';
    $sample->{state_transition_context}{transitions}[0]{target} = 'mutated';
    is_deeply($ir, $before, 'returned predicates and transition records are deeply detached');
    my $fsm = $scheduler->{fsm_emitter}->emit($ir);
    like($fsm, qr/\(<= \(captured data\) <\(& req allow\)\)/, 'actual sample carrier has the expression suffix');
    like($fsm, qr/\(= \(can_accept 1\)\)/, 'actual bookkeeping carrier has no suffix');
    like($fsm, qr/\(-never < \(!= 0 0\)/, 'actual false rule enable is at the DT header');
    like($fsm, qr/\(= \(main_lerr 1\) <main_cc<2\)/, 'actual latency guard uses its comparison carrier');
    my $path = write_file('activation_predicates.fsm', $fsm);
    my $check = $capture->([$^X, 'bin/fsmgen', '--strict', '--check', '--json', $path], '');
    is($check->{exit_code}, 0, 'complete collected carrier strict-checks') or diag($check->{stdout}, $check->{stderr});
    my $native_path = write_file('activation_predicates.isf', $source);
    my @semantic;
    for my $input ($path, $native_path) {
        my $result = $capture->([$^X, 'bin/fsmgen', '--strict', '--emit-semantic-json', $input], '');
        is($result->{exit_code}, 0, 'actual native/carrier semantic query succeeds') or diag($result->{stderr});
        push @semantic, $json->decode($result->{stdout})->{semantic};
    }
    is_deeply($semantic[0], $semantic[1], 'complete semantic products agree after public carrier replay');
};

subtest 'guard shapes and operator placement follow emitted explicit assignments' => sub {
    my @forms = (
        [undef, 'always', ''], [{}, 'always', ''],
        [{port => '1'}, 'always', ''], [{port => '0'}, 'truthy', ' < (!= 0 0)'],
        [{port => 'allow'}, 'truthy', ' <allow'], [{expr => '0'}, 'truthy', ' < (!= 0 0)'],
        [{expr => '(! allow)'}, 'truthy', ' <(! allow)'],
        [{signal => 'counter', op => '<', value => 3}, 'comparison', ' <counter<3'],
    );
    for my $op ('=', '<-', '<=', '<1', '<2') {
        for my $form (@forms) {
            my ($guard, $kind, $suffix) = @$form;
            my $container = state($guard, $op);
            my $record = $collector->resolve('state', $container, 0);
            is($record->{assignment_enable}{predicate}{kind}, $kind, "$op predicate classification");
            is(join("\n", $scheduler->{fsm_emitter}->_emit_assignments($container)),
                "    ($op (value 7)$suffix)", "$op actual state placement");
            for my $dt_kind (qw(rule latency_counter)) {
                my $dt = {name => 'test_dt', kind => $dt_kind, assignments => $container->{assignments}};
                my $dt_record = $collector->resolve('dt', $dt, 0);
                is_deeply($dt_record->{assignment_enable}, $record->{assignment_enable}, 'DT and state retain the same effective predicate');
                my $grouped = $dt_kind eq 'rule' && defined($guard) && defined($guard->{port}) && $guard->{port} ne '1';
                is($dt_record->{assignment_guard_placement}, $grouped ? 'rule_group' : 'suffix', 'rule port groups have explicit placement');
                my @lines = $dt_kind eq 'rule' ? $scheduler->{fsm_emitter}->_emit_rule_dt_assignments($dt)
                                             : $scheduler->{fsm_emitter}->_emit_plain_dt_assignments($dt);
                my $expected = $grouped ? '    (' . substr($suffix, 1) . "\n      ($op (value 7))\n    )"
                                        : "    ($op (value 7)$suffix)";
                is(join("\n", @lines), $expected, 'actual DT carrier matches independently declared placement');
            }
        }
    }
};

subtest 'malformed evidence and invented operator contracts are refused' => sub {
    for my $guard ('allow', {unknown => 1}, {port => 'allow', expr => 'other'},
            {port => []}, {expr_ast => ['&', 'a', 'b']}, {port => 'allow', op => '<'},
            {signal => 'counter', op => '<'}, {signal => 'counter', op => 'bad', value => 1},
            {expr => '(& a b)', expr_ast => ['|', 'a', 'b']}) {
        eval {$collector->resolve('state', state($guard), 0)};
        like($@, qr/Writer activation/, 'malformed guard cannot silently become unconditional');
    }
    eval {$collector->resolve('state', state({port => 'allow'}, '--'), 0)};
    like($@, qr/guarded state decrement/, 'invented decrement guard is not promoted to effective evidence');
    eval {$collector->resolve('dt', {name => 'dt', kind => 'rule', assignments => state(undef, '--')->{assignments}}, 0)};
    like($@, qr/DT decrement/, 'DT fallback is not misrepresented as a decrement');
    eval {$collector->resolve('state', state(undef, 'unknown'), 0)};
    like($@, qr/supported explicit assignment/, 'unknown operator is not silently classified');
    for my $index (-1, 1, [], '01') {
        eval {$collector->resolve('state', state(undef), $index)};
        like($@, qr/state or DT assignment/, 'invalid index cannot select another writer');
    }
    my $original = state({port => 'allow'});
    my $removed = dclone($original); delete $removed->{assignments}[0]{guard};
    isnt($collector->resolve('state', $removed, 0)->{assignment_enable}{predicate}{kind},
        $collector->resolve('state', $original, 0)->{assignment_enable}{predicate}{kind},
        'independent guard omission changes effective evidence');
    isnt(join("\n", $scheduler->{fsm_emitter}->_emit_assignments($original)),
        join("\n", $scheduler->{fsm_emitter}->_emit_assignments($removed)),
        'the same omission independently changes the emitted carrier');
};

done_testing();
