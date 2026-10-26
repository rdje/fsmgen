use strict;
use warnings;
use lib 'perl';
use Test::More;
use Scalar::Util qw(weaken);
use JSON::PP;
use FSM::Adapter::FSMGenFull;
use FSM::Package::Symbols;

my $json = JSON::PP->new->canonical;
my %captures;
subtest 'completed and refused parameter graphs release their actual parser' => sub {
    for my $case (
        ['empty', [], 1],
        ['literal', [{name => 'W', value_ast => ['8']}], 1],
        ['alias', [{name => 'A', value_ast => ['W']}, {name => 'W', value_ast => ['8']}], 1],
        ['cycle', [{name => 'A', value_ast => ['B']}, {name => 'B', value_ast => ['A']}], 0],
        ['unknown', [{name => 'A', value_ast => ['UNKNOWN']}], 0],
    ) {
        my ($name, $entries, $expected) = @$case;
        my ($weak, $ok, $error);
        {
            my $adapter = FSM::Adapter::FSMGenFull->new(debug => 0);
            my $parser = $adapter->{parser};$weak = $parser;weaken($weak);
            $ok = eval {$parser->resolve_pending_direct_root_params('graph_lifetime', $entries); 1};$error = $@;
        }
        $captures{lifetime}{$name} = {ok => $ok ? 1 : 0, retained => defined($weak) ? 1 : 0, error => $error};
        is($ok ? 1 : 0, $expected, "$name preserves canonical admission/refusal");
        ok(!defined($weak), "$name releases the parser after caller references leave scope");
    }
};

subtest 'one neutral graph preserves source order, actual references and canonical values' => sub {
    my $loaded = eval {require FSM::ParameterDeclarationSupport; 1};
    ok($loaded, 'shared canonical declaration graph owner is available') or return;
    my $entries = [
        {name => 'FORWARD', value_ast => ['BASE']},
        {name => 'BASE', value_ast => ['16']},
        {name => 'STATIC', value_ast => ['FIXED']},
        {name => 'SUM', value_ast => [['+', ['BASE', '1']]]},
    ];
    my $before = $json->encode($entries);
    my $symbols = FSM::Package::Symbols->new(constants => {FIXED => {kind => 'scalar', payload => '8'}});
    my @registered;
    my $result = FSM::ParameterDeclarationSupport->resolve_declarations(
        entries => $entries, source_module => 'shared_graph',
        resolve_static_symbol_payload => sub {return $symbols->resolve_payload($_[0])},
        on_resolved => sub {
            my ($name, $value, $source) = @_;
            push @registered, $name;
            # Consumer mutation must not rewrite the cache, source or aliases.
            $value->{value_payload}{payload} = 'WRONG';$source->{expression}[0] = 'WRONG';
        },
    );
    is_deeply($result->{order}, [qw(FORWARD BASE STATIC SUM)], 'declaration order remains independent of recursive resolution');
    is_deeply(\@registered, $result->{order}, 'registration callbacks retain original declaration order');
    is_deeply({map {$_ => $result->{parameters}{$_}{value_text}} keys %{$result->{parameters}}},
        {FORWARD => '16', BASE => '16', STATIC => '8', SUM => '(16 + 1)'}, 'canonical value/path evaluator retains existing values and expression text');
    is_deeply($result->{default_sources}{FORWARD}, {parameter => 'FORWARD', source_module => 'shared_graph',
        expression => ['BASE'], references => [{parameter => 'BASE', token => 'BASE', suffix => ''}]}, 'successful parameter branch retains exact original/reference identity');
    is_deeply($result->{default_sources}{STATIC}, {parameter => 'STATIC', source_module => 'shared_graph',
        expression => ['FIXED'], references => []}, 'static fallback gains no invented parameter reference');
    is($json->encode($entries), $before, 'whole declaration caller stays unchanged despite callback mutations');
    $captures{shared_graph} = $json->decode($json->encode($result));
    $result->{default_sources}{FORWARD}{expression}[0] = 'WRONG';
    is($result->{default_sources}{SUM}{expression}[0][1][0], 'BASE', 'distinct source trees are detached');
};

if (my $path = $ENV{FSMGEN_PARAMETER_GRAPH_CAPTURE}) {
    open my $out, '>', $path or die $!;print {$out} $json->encode(\%captures), "\n" or die $!;close $out or die $!;
}
done_testing();
