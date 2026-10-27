use strict;
use warnings;
use lib 'perl';
use Test::More;
use JSON::PP;
use Scalar::Util qw(weaken);
use Lispish;
use FSM::Adapter::FSMGenFull;
use FSM::Adapter::FSMGenFull::SignalManager;
use FSM::Package::IntegerLiteralSupport;
use FSM::Package::ScalarWidthSupport;
use FSM::CoreAST;

my $class = 'FSM::Adapter::FSMGenFull::SignalManager';
ok($class->can('resolve_positive_integer_scalar_observation'), 'constant-only positive width observation is available')
    or do { done_testing(); exit };
my $json = JSON::PP->new->canonical;
sub expected {
    my ($token, $width, $decimal) = @_;
    return {width => $width, observation => {kind => 'static_symbol', token => $token,
        value_payload => {kind => 'scalar', payload => $decimal}}};
}
my %capture;

subtest 'actual constant-only source selection retains exact decimal value' => sub {
    my $adapter = FSM::Adapter::FSMGenFull->new(debug => 0);
    my $module = $adapter->parse_fsm(Lispish::multi('t/corpus/direct_size_parameter_selection.fsm'));
    my $manager = $adapter->{signal_manager};
    my $before = $json->encode([$module->parameters, $module->parameter_default_sources,
        $module->parameter_default_bindings]);
    is($json->encode($manager->resolve_positive_integer_scalar_observation('W')),
        $json->encode(expected('W', 8, '8')), 'fast path selects constant8 beside type4 and parameter16');
    is($manager->resolve_positive_integer_scalar('W'), 8, 'old accessor keeps its numeric result');
    is($adapter->{signal_manager}->get_signal('BARE')->width, 4, 'actual parser named-type precedence stays unchanged');
    is($json->encode([$module->parameters, $module->parameter_default_sources,
        $module->parameter_default_bindings]), $before, 'all source/default getters retain original kinds');
    $capture{source} = $manager->resolve_positive_integer_scalar_observation('W');
};

subtest 'literal-like width semantics do not borrow target formatting or other namespaces' => sub {
    my $manager = $class->new;
    $manager->store_param('W', {value_payload => {kind => 'scalar', payload => '16'}});
    $manager->store_type('W', {kind => 'bits', width => 4});
    $manager->store_aggregate_symbol('W', {kind => 'scalar', payload => '32'});
    is($manager->resolve_positive_integer_scalar_observation('W'), undef, 'no constant means no fast-path selection');
    $manager->store_constant('W', '0x10');
    is($json->encode($manager->resolve_positive_integer_scalar_observation('W')),
        $json->encode(expected('W', 16, '16')), 'actual constant wins without ordinary aggregate/type/parameter lookup');
    $manager->store_constant('W', FSM::CoreAST::Literal->new('1000', width => 2, radix => 'binary'));
    is($json->encode($manager->resolve_positive_integer_scalar_observation('W')),
        $json->encode(expected('W', 8, '8')), 'raw legacy Literal retains the intrinsic integer used by the existing width fast path');
    my $target_literal = eval {$manager->resolve_symbol('W')->to_systemverilog};
    ok(!defined($target_literal), 'target formatting separately refuses an out-of-range raw legacy Literal');
    like($@, qr/does not fit in 2 bit/, 'intrinsic width selection must not replay target formatting');
    for my $value (0, -1, 'not_an_integer') {
        $manager->store_constant('W', $value);
        is($manager->resolve_positive_integer_scalar_observation('W'), undef, 'non-positive or invalid constants produce no observation');
        is($manager->resolve_positive_integer_scalar('W'), undef, 'old numeric refusal remains unchanged');
    }
    $capture{literal_like} = expected('W', 8, '8');
};

subtest 'canonical optional decimal output comes from the same parsed positive integer' => sub {
    for my $helper ('FSM::Package::IntegerLiteralSupport', 'FSM::Package::ScalarWidthSupport') {
        my $decimal = 'STALE';
        is($helper->positive_integer_from_literal_like('0x10', \$decimal), 16, 'old numeric return is preserved with capture');
        is($json->encode($decimal), '"16"', 'new decimal output has an explicit string kind');
        my $large = '1267650600228229401496703205376';
        my $width = $helper->positive_integer_from_literal_like($large, \$decimal);
        ok(defined($width), 'existing native numeric width remains available');
        is($decimal, $large, 'exact decimal digits survive native numeric conversion');
        $decimal = 'STALE';
        is($helper->positive_integer_from_literal_like(0, \$decimal), undef, 'zero keeps the canonical refusal');
        is($decimal, undef, 'refused capture clears previous output');
        my $ok = eval {$helper->positive_integer_from_literal_like(8, {}); 1};
        ok(!$ok, 'optional output requires a scalar reference'); like($@, qr/scalar reference/, 'output contract is named');
    }
};

subtest 'observations remain detached and retain no manager' => sub {
    my $manager = $class->new;
    $manager->store_constant('W', FSM::CoreAST::Literal->new(8));
    my $actual = $manager->resolve_positive_integer_scalar_observation('W');
    $actual->{observation}{value_payload}{payload} = 'WRONG';
    is($json->encode($manager->resolve_positive_integer_scalar_observation('W')),
        $json->encode(expected('W', 8, '8')), 'result mutation cannot rewrite the selected constant');
    is($manager->resolve_positive_integer_scalar('W'), 8, 'old numeric path is unaffected by result mutation');
    is($manager->resolve_positive_integer_scalar_observation('UNKNOWN'), undef, 'missing constant produces no record');
    my ($weak, $held);
    {
        my $local = $class->new; $local->store_constant('WIDTH', '8');
        $weak = $local; weaken($weak);
        $held = $local->resolve_positive_integer_scalar_observation('WIDTH');
    }
    ok(!defined($weak), 'held plain record does not retain its manager');
    is($json->encode($held), $json->encode(expected('WIDTH', 8, '8')), 'held observation remains usable');
};

if (my $path = $ENV{FSMGEN_POSITIVE_WIDTH_CAPTURE}) {
    open my $out, '>', $path or die $!;
    print {$out} $json->encode(\%capture), "\n" or die $!; close $out or die $!;
}
done_testing();
