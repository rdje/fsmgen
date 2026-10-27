use strict;
use warnings;
use lib 'perl';
use Test::More;
use JSON::PP;
use Scalar::Util qw(weaken);
use FSM::WidthExpressionSupport;

ok(FSM::WidthExpressionSupport->can('capture_positive_width_expression'), 'canonical width capture is available')
    or do { done_testing(); exit };
my $json = JSON::PP->new->canonical;
sub copy { return $json->decode($json->encode($_[0])) }
sub literal { return {kind => 'literal', token => $_[0]} }
sub operator { return {kind => 'operator', operator => $_[0], operands => [@_[1 .. $#_]]} }
sub reference { return {kind => 'reference', observation_index => $_[0], value_expression => $_[1]} }
my %symbols = (
    W => {kind => 'static_symbol', token => 'W', value_payload => {kind => 'scalar', payload => '4'}},
    P => {kind => 'parameter', token => 'P', parameter => 'P', suffix => '', value_payload => {kind => 'scalar', payload => '8'}},
    LEAF => {kind => 'static_symbol', token => 'LEAF', value_payload => {kind => 'scalar_expr', payload => 'W+2*3'}},
    GROUP => {kind => 'static_symbol', token => 'GROUP', value_payload => {kind => 'list', items => []}},
    CYCLE => {kind => 'static_symbol', token => 'CYCLE', value_payload => {kind => 'scalar_expr', payload => 'CYCLE+1'}},
);
my %parameters = (W => {kind => 'scalar', payload => '16'});
my @calls;
my $kernel = FSM::WidthExpressionSupport->new(
    resolve_symbol_payload => sub {push @calls, ['payload', $_[0]]; return $symbols{$_[0]}{value_payload}},
    resolve_symbol_observation => sub {push @calls, ['observation', $_[0]]; return $symbols{$_[0]}},
    resolve_parameter_payload => sub {push @calls, ['parameter', $_[0]]; return $parameters{$_[0]}},
);
my @original_keys = sort keys %$kernel;
my %capture;

subtest 'literal and prefix capture retains structure, source aliases and kinds' => sub {
    my $empty = FSM::WidthExpressionSupport->new;
    is($json->encode($empty->capture_positive_width_expression('0x10', 'literal')),
        $json->encode({width => 16, binding => literal('0x10'), observations => []}), 'literal capture needs no resolver and retains its token');
    my $source = ['add', [3, ['*', [2, 4]]]];
    my $before = $json->encode($source);
    my $actual = $empty->capture_positive_width_expression($source, 'prefix');
    is($json->encode($actual), $json->encode({width => 11,
        binding => operator('add', literal(3), operator('*', literal(2), literal(4))), observations => []}),
        'independent complete nested tree preserves alias, operand order and numeric token kinds');
    is($json->encode($source), $before, 'whole authored caller is unchanged');
    $capture{prefix} = $actual;
};

subtest 'one actual walk captures selectors and nested infix lookup precedence' => sub {
    @calls = ();
    my $source = ['add', [['param', ['W']], 'LEAF']];
    my $before = $json->encode([$source, \%symbols, \%parameters]);
    my $actual = $kernel->capture_positive_width_expression($source, 'mixed');
    my $expected = {width => 26, binding => operator('add', reference(0, literal('16')),
        reference(1, operator('+', reference(2, literal('4')), operator('*', literal('2'), literal('3'))))),
        observations => [
            {lookup => 'parameter', kind => 'parameter', token => 'W', parameter => 'W', suffix => '', value_payload => {kind => 'scalar', payload => '16'}},
            {lookup => 'symbol', %{$symbols{LEAF}}},
            {lookup => 'symbol', %{$symbols{W}}},
        ]};
    is($json->encode($actual), $json->encode($expected), 'independent full bound tree retains nested static payload references and infix precedence');
    is_deeply(\@calls, [['parameter', 'W'], ['observation', 'LEAF'], ['observation', 'W']],
        'capture resolves every selected value exactly once without replaying the payload hook');
    is($json->encode([$source, \%symbols, \%parameters]), $before, 'all source and callback payload JSON kinds survive');
    $actual->{observations}[1]{value_payload}{payload} = 'WRONG';
    $actual->{binding}{operands}[0]{value_expression}{token} = 'WRONG';
    is($json->encode($kernel->capture_positive_width_expression($source, 'mixed')),
        $json->encode($expected), 'nested result mutation cannot change later captures');
    $capture{mixed} = $expected;
};

subtest 'immediate parameter identity and repeats are never deduplicated or guessed' => sub {
    @calls = ();
    my $actual = $kernel->capture_positive_width_expression(['+', ['P', 'P']], 'repeats');
    is($json->encode($actual), $json->encode({width => 16,
        binding => operator('+', reference(0, literal('8')), reference(1, literal('8'))),
        observations => [{lookup => 'symbol', %{$symbols{P}}}, {lookup => 'symbol', %{$symbols{P}}}]}),
        'same root appears twice with distinct actual observation positions');
    is_deeply(\@calls, [['observation', 'P'], ['observation', 'P']], 'repeated operands cause their actual lookups');
    my $plain = $kernel->resolve_positive_width_expression('W', 'ordinary');
    is($plain, 4, 'ordinary API retains its original payload callback');
    is_deeply($calls[-1], ['payload', 'W'], 'ordinary evaluation does not activate observations');
    $capture{repeats} = $actual;
};

subtest 'capture refuses invalid inputs atomically and leaves ordinary evaluation intact' => sub {
    for my $case (
        [0, qr/positive integer/], [['-', [2, 3]], qr/negative width-expression/],
        [['/', [4, 0]], qr/divides by zero/], [['%', [4, 0]], qr/modulo by zero/],
        [['+', [1]], qr/at least two operands/], [['param', ['W', 'EXTRA']], qr/exactly one/],
        [['param', ['UNKNOWN']], qr/unknown declared parameter/], ['UNKNOWN', qr/unknown or non-scalar constant/],
        ['GROUP', qr/aggregate payload kind 'list'/],
        ['CYCLE', qr/cyclic.*lookup|cyclic.*reference/],
    ) {
        my $actual = eval {$kernel->capture_positive_width_expression($case->[0], 'control')};
        my $error = $@;
        ok(!defined($actual), 'invalid capture returns no partial record'); like($error, $case->[1], 'precise refusal meaning');
        is_deeply([sort keys %$kernel], \@original_keys, 'no transient capture state survives refusal');
        $capture{refusals}{scalar keys %{$capture{refusals} // {}}} = $error;
    }
    my $no_hook = FSM::WidthExpressionSupport->new(resolve_symbol_payload => sub {return {kind => 'scalar', payload => '8'}});
    my $actual = eval {$no_hook->capture_positive_width_expression('P', 'no observation')};
    ok(!defined($actual), 'a payload-only resolver cannot guess a selected namespace');
    like($@, qr/observation.*resolver|observation.*callback/, 'actual selection authority is required');
    is($no_hook->resolve_positive_width_expression('P', 'ordinary'), 8, 'old payload-only interface stays usable');
    is($kernel->capture_positive_width_expression(['param', ['W']], 'retry')->{width}, 16, 'fresh capture succeeds after failures');
    is_deeply([sort keys %$kernel], \@original_keys, 'success leaves no capture state');
};

subtest 'resolver work is isolated from the captured expression stack' => sub {
    my $weak;
    my $local = FSM::WidthExpressionSupport->new(resolve_symbol_observation => sub {
        my $value = $weak->resolve_positive_width_expression(['+', [1, 2]], 'resolver work');
        return {kind => 'static_symbol', token => $_[0], value_payload => {kind => 'scalar', payload => $value}};
    });
    $weak = $local; weaken($weak);
    is($json->encode($local->capture_positive_width_expression('CALCULATED', 'outer')),
        $json->encode({width => 3, binding => reference(0, literal(3)), observations => [
            {lookup => 'symbol', kind => 'static_symbol', token => 'CALCULATED', value_payload => {kind => 'scalar', payload => 3}}]}),
        'callback arithmetic does not invent outer source operands or operators');
    my $ok = eval {FSM::WidthExpressionSupport->new(resolve_symbol_observation => {}); 1};
    ok(!$ok, 'new observation hook requires a callback'); like($@, qr/resolve_symbol_observation.*callback/, 'hook is named');
};

subtest 'malformed observations, cyclic records and held results retain no callers' => sub {
    my $before = copy($symbols{P});
    for my $change (
        sub {$_[0]{kind} = 'foreign'}, sub {$_[0]{token} = 'OTHER'},
        sub {$_[0]{parameter} = 'OTHER'}, sub {$_[0]{extra} = 'unknown'},
    ) {
        $symbols{P} = copy($before); $change->($symbols{P});
        my $actual = eval {$kernel->capture_positive_width_expression('P', 'bad observation')};
        ok(!defined($actual), 'a malformed selection cannot publish a capture');
        like($@, qr/observation|selected.*token|parameter.*identity/, 'selection contract is named');
    }
    $symbols{P} = copy($before);
    $symbols{P}{value_payload}{cycle} = $symbols{P}{value_payload};
    my $bad_record = eval {$kernel->capture_positive_width_expression('P', 'cyclic observation')};
    ok(!defined($bad_record), 'cyclic callback records refuse without publication');
    like($@, qr/JSON|circular|nesting|depth|cyclic/i, 'callback structural refusal is explicit');
    delete $symbols{P}{value_payload}{cycle};
    $symbols{P} = $before;
    my $cyclic = []; push @$cyclic, $cyclic;
    my $actual = eval {$kernel->capture_positive_width_expression($cyclic, 'cyclic source')};
    ok(!defined($actual), 'cyclic authored structure refuses before evaluation');
    like($@, qr/JSON|circular|nesting|depth|cyclic/i, 'bounded structural refusal is explicit');
    pop @$cyclic;
    my ($weak, $weak_owner, $held);
    {
        my $owner = {value => 8};
        $weak_owner = $owner; weaken($weak_owner);
        my $local = FSM::WidthExpressionSupport->new(resolve_symbol_observation => sub {
            return {kind => 'static_symbol', token => $_[0], value_payload => {kind => 'scalar', payload => $owner->{value}}};
        });
        $weak = $local; weaken($weak);
        $held = $local->capture_positive_width_expression('HELD', 'held');
    }
    ok(!defined($weak), 'held plain capture does not retain its evaluator');
    ok(!defined($weak_owner), 'held result does not retain the released evaluator callback owner');
    is($held->{width}, 8, 'detached capture remains usable');
};

if (my $path = $ENV{FSMGEN_WIDTH_CAPTURE_RESULTS}) {
    open my $out, '>', $path or die $!;
    print {$out} $json->encode(\%capture), "\n" or die $!; close $out or die $!;
}
done_testing();
