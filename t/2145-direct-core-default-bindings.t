use strict;
use warnings;
use lib 'perl';
use Test::More;
use JSON::PP;
use Scalar::Util qw(weaken);
use Lispish;
use FSM::Adapter::FSMGenFull;
use FSM::CoreAST;
use FSM::IR::IntentHIRBuilder;
use FSM::Pipeline::HDLGenerator;

ok(FSM::CoreAST::FSMModule->can('parameter_default_bindings'), 'Core exposes detached canonical default bindings') or do {
    done_testing(); exit;
};

my $json = JSON::PP->new->canonical;
my %capture;
my $scope = {kind => 'direct_module', owner => 'parameter_default_sources'};
sub copy {return $json->decode($json->encode($_[0]))}
sub literal {return {kind => 'literal', token => $_[0]}}
sub parameter {
    my ($name, $suffix) = @_; $suffix //= '';
    return {kind => 'parameter', scope => copy($scope), parameter => $name, token => $name.$suffix, suffix => $suffix};
}
sub static {
    return {kind => 'static_symbol', scope => copy($scope), token => $_[0],
        value_payload => {kind => 'scalar', payload => $_[1]}};
}
my $expected = {
    W => literal('16'), FORWARD => parameter('W'), CHAIN => parameter('FORWARD'),
    STATIC => static('FIXED', 16), MODE => static('mode.EIGHT', 8),
    ITEMS => {kind => 'list', items => [literal("8'hA5"), literal("8'h3C")]},
    CONFIG => {kind => 'map', member_order => [qw(flag lanes)], members => {
        flag => parameter('W'), lanes => parameter('ITEMS')}},
    LEAF => parameter('CONFIG', '.flag'), LANE => parameter('CONFIG', '.lanes[1]'),
    SUM => {kind => 'operator', operator => '+', source_operator => '+', operands => [parameter('W'), literal('1')]},
    REPEATED => {kind => 'operator', operator => '+', source_operator => '+', operands => [parameter('W'), parameter('W')]},
    COPY => parameter('CONFIG'),
};
my $raw = Lispish::multi('t/data/ial0-parameter-default-sources.fsm');
my $raw_before = $json->encode($raw);
my $adapter = FSM::Adapter::FSMGenFull->new(debug => 0);
my $module = $adapter->parse_fsm($raw);
my $old = $json->encode([$module->parameters, $module->parameter_default_sources]);

subtest 'actual resolution captures canonical bindings beside unchanged normalized/source views' => sub {
    is($json->encode($module->parameter_default_bindings), $json->encode($expected), 'complete actual source bindings retain lexical scope, immediate roots and structure');
    is($module->parameters->{W}{value_text}, '16', 'declared parameter still takes precedence over same-named constant eight');
    is($module->parameters->{FORWARD}{value_text}, '16', 'forward default retains existing selected semantics');
    is($module->parameters->{STATIC}{value_text}, '16', 'equal static default remains independently selected');
    is($json->encode($raw), $raw_before, 'whole frontend caller stays unchanged');
    my $view = $module->parameter_default_bindings;
    $view->{CONFIG}{members}{flag}{scope}{owner} = 'WRONG';
    $view->{STATIC}{value_payload}{payload} = 'WRONG';
    is($json->encode($module->parameter_default_bindings), $json->encode($expected), 'nested getter results are detached');
    is($json->encode([$module->parameters, $module->parameter_default_sources]), $old, 'binding inspection does not rewrite normalized/source views');
    $capture{bindings} = $module->parameter_default_bindings;
    $adapter->{signal_manager}->store_constant('FIXED',
        $adapter->{parser}{expression_builder}->parse_scalar_expression('32'));
    is_deeply($adapter->{signal_manager}->resolve_parameter_value_symbol_payload('FIXED'),
        {kind => 'scalar', payload => '32'}, 'the live lookup actually selects the intervened static value');
    is($json->encode($module->parameter_default_bindings), $json->encode($expected), 'later live static-cache edits cannot rewrite the selected snapshot');
    my $intent = FSM::IR::IntentHIRBuilder->build_from_fsm_module(fsm_module => $module)->as_hashref;
    unlike($json->encode($intent), qr/"_?parameter_default_bindings"\s*:/, 'private Core bindings do not extend IntentHIR schema');
};

subtest 'constructor, bulk update and declaration replacement own their records' => sub {
    my $input = copy($expected);
    my $clone = FSM::CoreAST::FSMModule->new(name => 'physical_copy', parameters => $module->parameters,
        _parameter_default_sources => $module->parameter_default_sources, _parameter_default_bindings => $input);
    $input->{FORWARD}{scope}{owner} = 'WRONG';
    is($clone->parameter_default_bindings->{FORWARD}{scope}{owner}, $scope->{owner}, 'physical copy preserves original lexical owner and clones constructor input');
    my $replacement = copy($expected);
    my $returned = $clone->set_parameter_default_bindings($replacement);
    $replacement->{STATIC}{value_payload}{payload} = 'WRONG';
    $returned->{MODE}{value_payload}{payload} = 'WRONG';
    is($json->encode($clone->parameter_default_bindings), $json->encode($expected), 'bulk setter input and result are detached');
    $clone->set_parameter('W', $module->parameters->{W}, $module->parameter_default_sources->{W});
    is_deeply($clone->parameter_default_bindings, {}, 'declaration replacement clears the entire derived binding snapshot');
    is($json->encode($module->parameter_default_bindings), $json->encode($expected), 'sibling replacement cannot change original bindings');
    my $plain = FSM::CoreAST::FSMModule->new(name => 'plain', parameters => {W => {value_text => '16'}});
    is_deeply($plain->parameter_default_bindings, {}, 'legacy programmatic declarations gain no invented capture');
};

subtest 'admitted semantic payloads remain opaque canonical nodes' => sub {
    my $tree = [['?fsm:bound_payload', [['+params', [['VALUE', {kind => 'scalar', payload => '16'}]]]]]];
    my $before = $json->encode($tree);
    my $m = FSM::Adapter::FSMGenFull->new(debug => 0)->parse_fsm($tree);
    is($json->encode($m->parameter_default_bindings->{VALUE}),
        '{"kind":"payload","value":{"kind":"scalar","payload":"16"}}',
        'existing semantic input does not acquire an invented authored symbol or operator tree');
    is($json->encode($tree), $before, 'semantic caller payload and JSON kinds stay unchanged');
};

subtest 'real imported constants, enum members and aggregate paths stay immutable static selections' => sub {
    my $result = FSM::Pipeline::HDLGenerator->new(quiet => 1, debug_level => 0,
        target_language => 'systemverilog')->generate_hdl_from_file('t/data/ial0-imported-default-bindings.fsm');
    my $imported = $result->{fsm_module}; my $bindings = $imported->parameter_default_bindings;
    for my $case (['PACKAGE', 'shared_defaults.FIXED', 16], ['MODE', 'shared_defaults.mode.BIG', 16],
        ['ITEM', 'shared_defaults.FRAME.data[1]', "8'h3C"]) {
        my ($name, $token, $payload) = @$case;
        is($json->encode($bindings->{$name}), $json->encode({kind => 'static_symbol',
            scope => {kind => 'direct_module', owner => 'imported_default_bindings'},
            token => $token, value_payload => {kind => 'scalar', payload => $payload}}),
            'qualified static selection keeps token, scope, canonical payload and JSON kind');
    }
    is($bindings->{ALIAS}{parameter}, 'PACKAGE', 'a local reference to a package-valued declaration remains an actual parameter');
    is($bindings->{SUM}{operands}[0]{parameter}, 'PACKAGE', 'operator does not replace a package-valued parameter by its selected number');
    $capture{imported} = {bindings => $bindings, parameters => $imported->parameters, sources => $imported->parameter_default_sources};
};

subtest 'refused retries cannot expose a stale completed binding graph' => sub {
    for my $entries (
        [{name => 'BAD', value_ast => ['UNKNOWN']}],
        [{name => 'FIRST', value_ast => ['1']}, {name => 'BAD', value_ast => ['UNKNOWN']}],
    ) {
        my $a = FSM::Adapter::FSMGenFull->new(debug => 0);
        my $text = '(?fsm:retry_bindings (+params (ALIAS W) (W 8)))';
        my $m = $a->parse_fsm(Lispish::multi(\$text));
        ok(keys(%{$m->parameter_default_bindings}), 'successful actual source starts with captured bindings');
        my $ok = eval {$a->{parser}->resolve_pending_direct_root_params('retry_bindings', $entries); 1};
        ok(!$ok, 'unknown retry refuses through the existing canonical evaluator');
        like($@, qr/UNKNOWN/, 'retry keeps the canonical reason');
        is_deeply($m->parameter_default_bindings, {}, 'refusal before/after registration exposes no stale or partially published binding map');
    }
};

subtest 'missing actual observations cannot fall through to the parameter-valued compatibility cache' => sub {
    my $a = FSM::Adapter::FSMGenFull->new(debug => 0);
    my $text = '(?fsm:missing_observation (+params (ALIAS W) (W 8)))';
    my $m = $a->parse_fsm(Lispish::multi(\$text));
    my $resolve = FSM::ParameterDeclarationSupport->can('resolve_declarations');
    my ($ok, $error);
    {
        no warnings 'redefine';
        local *FSM::ParameterDeclarationSupport::resolve_declarations = sub {
            my $result = $resolve->(@_);
            $result->{default_sources}{ALIAS}{references} = [];
            return $result;
        };
        $ok = eval {$a->{parser}->resolve_pending_direct_root_params('missing_observation', [
            {name => 'ALIAS', value_ast => ['W']}, {name => 'W', value_ast => ['8']}]); 1};
        $error = $@;
    }
    ok(!$ok, 'a discarded actual parameter observation refuses binding');
    like($error, qr/unbound canonical symbol 'W'/, 'declared root cannot be frozen as a static compatibility value');
    is_deeply($m->parameter_default_bindings, {}, 'failed binding publishes no partial snapshot');
};

subtest 'returned literal and alias bindings retain no parser ownership edge' => sub {
    for my $params ('(W 8)', '(ALIAS W) (W 8)') {
        my ($weak, $retained);
        {
            my $a = FSM::Adapter::FSMGenFull->new(debug => 0);
            $weak = $a->{parser}; weaken($weak);
            my $text = "(?fsm:binding_lifetime (+params $params))";
            $retained = $a->parse_fsm(Lispish::multi(\$text));
        }
        ok(!defined($weak), 'actual parser releases while returned Core bindings remain live');
        ok(keys(%{$retained->parameter_default_bindings}), 'returned binding data remains usable');
    }
};

if (my $path = $ENV{FSMGEN_DIRECT_CORE_BINDING_CAPTURE}) {
    open my $out, '>', $path or die $!;
    print {$out} $json->encode(\%capture), "\n" or die $!; close $out or die $!;
}
done_testing();
