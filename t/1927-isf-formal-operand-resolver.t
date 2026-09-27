#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Storable qw(dclone);
use lib 'perl', 't/lib';
use FSM::Test::ProjectDataLocality;
use FSM::Adapter::ISF;
use FSM::Scheduler::ISF;
use FSM::Scheduler::ISF::FormalIdentityPlan;
use FSM::Scheduler::ISF::FormalOperandResolver;

my $planner = 'FSM::Scheduler::ISF::FormalIdentityPlan';
my $resolver = 'FSM::Scheduler::ISF::FormalOperandResolver';
my $actor = FSM::Adapter::ISF->new->parse_source(<<'ISF', 'scoped_operands.isf');
(actor scoped_operands
 (clock clk) (reset (rst_n async active_low))
 (interface (input start) (output done))
 (storage (var data (width 8) (reset 19)))
 (transaction caller
  (ports (input data (width 4)) (output result (width 4)))
  (on start) (set result (+ data 1)) (complete done))
 (transaction callee
  (ports (input data (width 4)) (output result (width 4)))
  (on start) (set result data) (complete done))
 (transaction child
  (ports (input data (width 4)) (output result (width 4)))
  (on start) (set result data) (complete done))
 (transaction empty (on start) (complete done)))
ISF
my $bits = {kind => 'bits', width => 4};
my $record = {kind => 'record', width => 8, member_order => ['data', 'result'],
    members => {data => dclone($bits), result => dclone($bits)}};
push @{$actor->{transactions}[0]{ports}{inputs}},
    {name => 'packet', width => 8, type_spec => $record},
    {name => 'items', width => 16, type_spec => {kind => 'list', width => 16,
        items => [dclone($record), dclone($record)]}};
my $original = dclone($actor);
my $plan = $planner->build($actor, generated_children => {child => 1}, reserved_names => {});
my %context = (plan => $plan, transaction => 'caller', locals => {},
    static_symbols => {'data.MODE' => 1, 'pkg.values[0]' => 1, COUNT => 1});
my $r = $resolver->new(%context);
my $p = sub {$plan->{formals}{$_[0]}{$_[1]}{physical_name}};
my $data = $p->('caller', 'data');
my $result = $p->('caller', 'result');

is($r->expression('data'), $data, 'runtime read uses caller formal');
is($r->target('result'), $result, 'write uses caller formal');
is($r->expression('done'), 'done', 'actor signal is unchanged');
is($r->expression('data.MODE'), 'data.MODE', 'resolved qualified constant wins over matching formal root');
is($r->expression('pkg.values[0]'), 'pkg.values[0]', 'resolved aggregate constant leaf is unchanged');
is($r->expression('COUNT'), 'COUNT', 'static parameter value remains source-owned');
for my $value ('0', '19', '-3', '0x1f', "8'hff", "4'd3", "4'7", 'const_8b0', 'const_4bxz01') {
    is($r->expression($value), $value, "literal spelling retained: $value");
}
for my $suffix ('[0]', '[3:1]', '[1:3]', "'4", "[3:0]'4>") {
    is($r->expression('data' . $suffix), $data . $suffix, "scalar suffix preserved: $suffix");
}
is($r->expression('!data[1]'), "!$data\[1]", 'compact negation rewrites only reference');
is($r->expression('data>=COUNT'), "$data>=COUNT", 'inline comparison distinguishes runtime and static operands');
is($r->expression('data=result'), "$data=$result", 'inline comparison rewrites both runtime roots');
is($r->expression('packet.data[2:1]'), $p->('caller', 'packet') . '.data[2:1]', 'aggregate member sharing a formal name is preserved');
is($r->target('items[1].result'), $p->('caller', 'items') . '[1].result', 'list item and member suffix retained');

my $expr = ['&', ['!=', 'data', 'COUNT'], ['state_active', 'data'], ['at', 'result']];
my $before = dclone($expr);
is_deeply($r->expression($expr), ['&', ['!=', $data, 'COUNT'], ['state_active', 'data'], ['at', 'result']],
    'state/point roles remain source identities inside nested runtime expressions');
is_deeply($expr, $before, 'nested expression input remains detached');
for my $op (qw(! not)) {
    is_deeply($r->expression([$op, 'data']), [$op, $data], "unary $op role preserved");
}
for my $op (qw(!& !| !^ == != < <= > >= & | ^ + - * / % << >> <<< >>> concat
    and nand or nor xor xnor add sub mul div mod eq ne lt le gt ge cat shl shr sal sar)) {
    is_deeply($r->expression([$op, 'data', 'result']), [$op, $data, $result], "operator $op spelling and operand roles preserved");
}
is_deeply($r->expression(['<', 'data', 'result', 'COUNT']), ['<', $data, $result, 'COUNT'], 'chained comparisons preserve all operands');
is_deeply($r->expression(['past', 'data[1]', 2], property => 1), ['past', "$data\[1]", 2], 'sampled value rewrites signal, not depth');
is_deeply($r->expression(['!', ['past', 'data']], property => 1), ['!', ['past', $data]], 'property context propagates into nested expression');

my $input = ['input', 'data', ['+', 'data', 'COUNT'], ['timing', 'snapshot']];
my $binding = $r->binding('callee', $input);
is_deeply($binding->{physical}, ['input', $p->('callee', 'data'), ['+', $data, 'COUNT'], ['timing', 'snapshot']],
    'input binding separates callee formal, caller expression and static timing');
is_deeply($binding->{source}, $input, 'authored binding retained for source reports');
is_deeply($binding->{formal}{identity}, ['transaction_port', 'scoped_operands', 'callee', 'data'], 'binding carries explicit callee identity');
is_deeply($r->binding('callee', ['output', 'result', 'result'])->{physical},
    ['output', $p->('callee', 'result'), $result], 'output separates callee read and caller write');
is_deeply($r->binding('child', ['input', 'data', 'data', ['timing', 'live']])->{physical},
    ['input', 'data', $data, ['timing', 'live']], 'generated public input survives caller rewrite');
is_deeply($r->binding('child', ['output', 'result', 'result'])->{physical},
    ['output', 'result', $result], 'generated public output survives caller rewrite');

my $rule = $resolver->new(%context, transaction => undef);
is_deeply($rule->binding('callee', ['input', 'data', 'data'])->{physical},
    ['input', $p->('callee', 'data'), 'data'], 'rule caller reads actor data while addressing callee formal');
is_deeply($rule->binding('callee', ['output', 'result', 'result'])->{physical},
    ['output', $p->('callee', 'result'), 'result'], 'rule caller writes actor result');
my $child = $resolver->new(%context, transaction => 'child');
is($child->expression('data'), 'data', 'generated child body retains public formal identity');
my $empty = $resolver->new(%context, transaction => 'empty');
is($empty->expression('data'), 'data', 'empty scope never borrows sibling formal');
my $local = $resolver->new(%context, locals => {data => 1});
is($local->expression('data'), 'data', 'explicit local shields same-name formal');
is($local->target('data[1]'), 'data[1]', 'local shield includes static suffix');
my $static = $resolver->new(%context, static_symbols => {data => 1});
is($static->expression('data'), 'data', 'resolved named symbol has expression precedence');

$binding->{source}[2][1] = 'changed';
$binding->{formal}{declaration}{width} = 99;
is_deeply($input, ['input', 'data', ['+', 'data', 'COUNT'], ['timing', 'snapshot']], 'binding result cannot mutate input');
is($r->binding('callee', $input)->{formal}{declaration}{width}, 4, 'returned endpoint cannot mutate retained plan');
$plan->{formals}{caller}{data}{physical_name} = 'changed';
$context{locals}{data} = 1;
$context{static_symbols}{data} = 1;
is($r->expression('data'), $data, 'resolver snapshots plan and scope sets');
is_deeply($actor, $original, 'all resolver operations preserve parsed source declarations');

for my $case (
    [sub {$r->expression(['mystery', 'data'])}, qr/unsupported operator 'mystery'/],
    [sub {$r->expression([])}, qr/non-empty normalized list/],
    [sub {$r->expression({value => 'data'})}, qr/non-empty normalized list/],
    [sub {$r->expression(undef)}, qr/defined scalar/],
    [sub {$r->expression(['!', 'data', 'result'])}, qr/invalid arity/],
    [sub {$r->expression(['<<', 'data', 1, 2])}, qr/invalid arity/],
    [sub {$r->expression(['+', 'data'])}, qr/invalid arity/],
    [sub {$r->expression(['at', ['+', 'data', 1]])}, qr/one source identity/],
    [sub {$r->expression(['state_active', 'data[0]'])}, qr/one source identity/],
    [sub {$r->expression(['past', 'data'])}, qr/requires property context/],
    [sub {$r->expression(['past', 'data', 'COUNT'], property => 1)}, qr/requires property context/],
    [sub {$r->expression(['past', 'data', 0], property => 1)}, qr/requires property context/],
    [sub {$r->expression(['past', ['+', 'data', 1]], property => 1)}, qr/unsupported signal reference/],
    [sub {$r->expression('data', properties => 1)}, qr/unknown option/],
    [sub {$r->expression('data[4]')}, qr/out-of-range scalar/],
    [sub {$r->expression('data.result')}, qr/requires a declared aggregate/],
    [sub {$r->expression('packet.missing')}, qr/unknown_member/],
    [sub {$r->expression('items[2].data')}, qr/list_index_out_of_range/],
    [sub {$r->expression('items[0].data[4]')}, qr/scalar_index_out_of_range/],
    [sub {$r->expression('data[COUNT]')}, qr/unsupported signal reference/],
    [sub {$r->expression('(add data 1)')}, qr/unsupported signal reference/],
    [sub {$r->expression('"data text"')}, qr/unsupported signal reference/],
    [sub {$r->target(['+', 'data', 1])}, qr/unsupported signal reference/],
    [sub {$r->target('data.MODE')}, qr/cannot be a static symbol/],
    [sub {$static->target('data')}, qr/cannot be a static symbol/],
    [sub {$r->binding('callee', ['output', 'data', 'result'])}, qr/no output formal/],
    [sub {$r->binding('callee', ['input', 'missing', 'data'])}, qr/no input formal/],
    [sub {$r->binding('unknown', ['input', 'data', 'data'])}, qr/unknown transaction/],
    [sub {$r->binding('callee', ['output', 'result', 'result[0]'])}, qr/scalar caller target/],
    [sub {$r->binding('callee', ['input', 'data', 'data', ['timing', 'queue']])}, qr/timing requires/],
    [sub {$r->binding('callee', ['output', 'result', 'result', ['timing', 'live']])}, qr/timing requires/],
    [sub {$r->binding('callee', ['input', 'data', 'data', undef])}, qr/timing requires/],
) {
    eval {$case->[0]->()};
    like($@, $case->[1], 'unsupported role/grammar fails precisely');
}
for my $case (
    [{transaction => 'unknown'}, qr/unknown transaction/],
    [{plan => {}}, qr/requires a formal identity plan/],
    [{locals => []}, qr/explicit locals hash/],
    [{locals => {'a.b' => 1}}, qr/invalid local name/],
    [{static_symbols => {'(data)' => 1}}, qr/invalid static symbol/],
    [{surprise => 1}, qr/unknown option/],
) {
    eval {$resolver->new(%context, %{$case->[0]})};
    like($@, $case->[1], 'invalid lexical context rejected');
}
my %missing = %context;
delete $missing{transaction};
eval {$resolver->new(%missing)};
like($@, qr/explicit transaction context/, 'omission cannot silently select actor scope');

# Production now applies the qualified planner/resolver before merging storage.
my $production = FSM::Scheduler::ISF->new->lower($actor);
my ($carrier) = values %{$production->{files}};
like($carrier, qr/\(isf_port_\w+_data\w* 4(?:\s|\))/, 'production emits a distinct private formal');
done_testing;
