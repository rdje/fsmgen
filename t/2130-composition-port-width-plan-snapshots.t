use strict;
use warnings;
use lib 'perl';
use Test::More;
use JSON::PP;
use Lispish;
use FSM::Composition::Parser;
use FSM::Composition::PackageImportResolver;
use FSM::Composition::Plan;
use FSM::SourcePathResolver;
use FSM::Support::SerializableCompositionPlanSnapshot qw(build_serializable_composition_plan_snapshot);

my $json = JSON::PP->new->canonical;
my $path = 't/data/composition-top-port-width-expressions.fsm';
sub parsed { FSM::Composition::Parser->new->parse_source(scalar Lispish::multi($path)) }
sub resolve {
    FSM::Composition::PackageImportResolver->resolve_imports(composition_spec => $_[0],
        fsm_file => $path, source_path_resolver => FSM::SourcePathResolver->new);
}
sub captured_plan {
    my ($spec) = @_;
    FSM::Composition::Plan->new(top_name => $spec->top->name, raw_spec => $spec,
        ports => $spec->top->ports_blocks->[0]->ports);
}
sub port { my ($owner, $name) = @_; return (grep {$_->name eq $name} @{$owner->ports})[0] }

subtest 'captured parameter defaults and port widths stay in the same epoch' => sub {
    my $spec = parsed(); resolve($spec);
    my $plan = captured_plan($spec);
    my $environment = $json->encode($plan->parameter_environment);
    my $contract = $json->encode(port($plan, 'data')->width_contract);
    my $snapshot = $json->encode(build_serializable_composition_plan_snapshot(composition_plan => $plan));
    $spec->top->top_symbols->store_constant('BASE', {kind => 'scalar', payload => '20'});
    resolve($spec);
    my $new_plan = captured_plan($spec);
    is(port($new_plan, 'data')->width, 22, 'new plan captures the new resolved default plus static two');
    is(port($plan, 'data')->width, 18, 'prior plan keeps original 16 plus static two');
    is(port($plan, 'result')->width, 24, 'prior plan also keeps dependent arithmetic width');
    is($json->encode($plan->parameter_environment), $environment, 'original default environment stays captured');
    is($json->encode(port($plan, 'data')->width_contract), $contract, 'complete original source/scope/lookups stay captured');
    is($json->encode(build_serializable_composition_plan_snapshot(composition_plan => $plan)), $snapshot,
        'complete original public plan snapshot stays stable across source retry');
    $spec->top->top_symbols->store_constant('BASE', {kind => 'list', items => []});
    my $ok = eval {resolve($spec);1};
    ok(!$ok, 'new invalid source epoch refuses');
    is(port($plan, 'data')->width, 18, 'refused retry cannot erase an earlier captured plan width');
};
subtest 'expression port getters return complete detached Port objects' => sub {
    my $spec = parsed(); resolve($spec);
    my $plan = captured_plan($spec);
    my $p = port($plan, 'data');
    my @attributes = qw(name direction width width_token signed state_model declared_type_name declared_type_spec type binding_mode raw_token origin_kind width_contract);
    my $expected = {map {$_ => $p->$_()} @attributes};
    my $again = port($plan, 'data');
    isnt($again, $p, 'separate getter objects');
    $p->set_width(99); $p->set_signed(1); $p->set_state_model('two_state');
    $p->set_declared_type_name('WRONG'); $p->set_declared_type_spec({kind => 'bits', width => 99});
    $p->set_width_contract({scope => {kind => 'composition_top', owner => 'WRONG'}});
    is_deeply({map {$_ => $again->$_()} @attributes}, $expected, 'complete sibling Port snapshot conserves attributes');
    my $current = port($plan, 'data');
    is_deeply({map {$_ => $current->$_()} @attributes}, $expected, 'later getter conserves attributes');
    is(($spec->top->ports_blocks->[0]->ports->[4])->width, 18, 'getter mutations cannot reach source owner');
    is(port($plan, 'clock')->type, 'clock', 'ordinary clock role unchanged');
    is(port($plan, 'reset')->type, 'reset', 'ordinary reset role unchanged');
    is(port($plan, 'typed')->declared_type_name, 'TYPE', 'ordinary named-type identity unchanged');
    is(port($plan, 'static')->width_contract, undef, 'ordinary static optional shape unchanged');
};
subtest 'incomplete expression caches refuse capture' => sub {
    my $spec = parsed(); $spec->top->resolve_parameter_defaults;
    my $ok = eval {captured_plan($spec);1};
    ok(!$ok, 'resolved defaults without resolved expression widths cannot make a coherent plan');
    like($@, qr/Port 'data'.*resolved width.*contract/s, 'refusal identifies actual port and missing contract');
};
done_testing;
