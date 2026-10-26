use strict;
use warnings;
use lib 'perl';
use Test::More;
use JSON::PP;
use Lispish;
use FSM::Composition::Parser;
use FSM::Composition::PackageImportResolver;
use FSM::SourcePathResolver;

my $renderer = 'FSM::Backend::VerilogFamily::CompositionBindingEmitter';
require_ok($renderer) or BAIL_OUT('canonical scalar renderer is not installed');
my $json = JSON::PP->new->canonical;
sub copy { $json->decode($json->encode($_[0])) }
sub parsed {
    my ($path) = @_;
    my $spec = FSM::Composition::Parser->new->parse_source(scalar Lispish::multi($path));
    FSM::Composition::PackageImportResolver->resolve_imports(
        composition_spec => $spec, fsm_file => $path,
        source_path_resolver => FSM::SourcePathResolver->new);
    return $spec->top;
}
my $top = parsed('t/data/composition-top-default-bindings.fsm');
my $environment = $top->parameter_environment;
my $bindings = $environment->{default_bindings};
my $before = $json->encode($environment);
sub lower {
    my ($node, $env, $language) = @_;
    return $renderer->lower_expression(binding => $node,
        environment => $env // $environment, target_language => $language // 'systemverilog');
}
sub refusal {
    my ($name, $node, $pattern, $env, $language) = @_;
    my $ok = eval { lower($node, $env, $language); 1 };
    my $error = $@;
    ok(!$ok, "$name refuses");
    like($error, $pattern, "$name explains its boundary");
}

subtest 'actual source retains selected names, static values and operator structure' => sub {
    my %expected = (
        FORWARD => ['ALIAS', ['ALIAS']], ALIAS => ['BASE', ['BASE']],
        OTHER => ['SAME', ['SAME']], LITERAL => ['16', []],
        SUM => ['(BASE + 16)', ['BASE']], STATIC_COPY => ['16', []], MODE => ['16', []],
    );
    for my $language (qw(systemverilog sv verilog v)) {
        for my $name (sort keys %expected) {
            is_deeply(lower($bindings->{$name}, undef, $language),
                {text => $expected{$name}[0], parameter_references => $expected{$name}[1]},
                "$language $name uses its canonical source binding");
        }
    }
    my $changed = copy($environment);
    $changed->{parameters}{BASE}{value_text} = '999';
    $changed->{parameters}{BASE}{value_payload}{payload} = '999';
    is(lower($bindings->{ALIAS}, $changed)->{text}, 'BASE', 'changed validation cache cannot replace a symbolic alias');
    my $result = lower($bindings->{SUM});
    $result->{parameter_references}[0] = 'caller_mutation';
    is_deeply(lower($bindings->{SUM})->{parameter_references}, ['BASE'], 'returned dependency list is isolated');
    is($json->encode($environment), $before, 'rendering leaves the complete captured source environment unchanged');
};

subtest 'actual child actuals preserve distinct equal-default parameter identities' => sub {
    my $child_top = parsed('t/data/composition-top-child-bindings.fsm');
    my $env = $child_top->parameter_environment;
    my $instance = $child_top->instances->[0];
    my %overrides = map { $_->{name} => $_ } @{$instance->parameter_overrides};
    is_deeply(lower($overrides{WIDTH}{binding_expression}, $env),
        {text => 'W', parameter_references => ['W']}, 'actual WIDTH selects W');
    is_deeply(lower($overrides{EQUAL}{binding_expression}, $env),
        {text => 'SAME', parameter_references => ['SAME']}, 'actual EQUAL selects SAME');
    refusal('aggregate child actual', $overrides{DATA}{binding_expression}, qr/scalar parameter/, $env);
};

subtest 'operator aliases, nested precedence, literals and repeated dependencies' => sub {
    my $ref = $bindings->{ALIAS};
    my $literal = sub { +{kind => 'literal', token => $_[0]} };
    my $op = sub { my ($operator, $source, @operands) = @_; +{
        kind => 'operator', operator => $operator, source_operator => $source, operands => \@operands} };
    my $expression = $op->('-', 'sub', $ref,
        $op->('*', 'mul', $literal->('2'), $literal->('3')), $ref);
    is_deeply(lower($expression), {text => '(BASE - (2 * 3) - BASE)', parameter_references => ['BASE', 'BASE']},
        'nested and ordered n-ary operands retain their actual dependencies');
    is(lower($op->('~', 'not', $ref))->{text}, '(~BASE)', 'unary inversion preserves its canonical operator');
    is(lower($literal->('0xA5'))->{text}, "'hA5", 'literal normalization shares the canonical language helper');
    is(lower({kind => 'payload', value => {kind => 'scalar', payload => "8'hA5"}})->{text}, "8'hA5", 'semantic scalar literals render without invented source');
    refusal('operator alias mismatch', $op->('+', 'sub', $ref, $literal->('2')), qr/canonical operator/);
    refusal('binary operator arity', $op->('+', '+', $ref), qr/operand/);
    refusal('unary operator arity', $op->('~', '~', $ref, $ref), qr/operand/);
    refusal('unknown operator', $op->('&&', '&&', $ref, $ref), qr/canonical operator/);
    refusal('literal injection', $literal->('16); endmodule'), qr/scalar integer literals/);
    refusal('aggregate disguised as literal token', $literal->(["8'hA5", "8'h3C"]), qr/literal source token/);
    refusal('payload disguised as literal token', $literal->({kind => 'scalar', payload => '16'}), qr/literal source token/);
};

subtest 'malformed, foreign, aggregate and raw-text bindings fail closed' => sub {
    my $bad = copy($bindings->{ALIAS}); $bad->{scope}{owner} = 'other_top';
    refusal('foreign scope', $bad, qr/scope/);
    $bad = copy($bindings->{ALIAS}); $bad->{parameter} = 'MISSING'; $bad->{token} = 'MISSING';
    refusal('undeclared parameter', $bad, qr/declared parameter/);
    $bad = copy($bindings->{ALIAS}); $bad->{token} = 'SAME';
    refusal('inconsistent selected name', $bad, qr/token/);
    my $reserved = copy($environment);
    $reserved->{parameters}{wire} = delete $reserved->{parameters}{BASE};
    $_ = 'wire' for grep { $_ eq 'BASE' } @{$reserved->{declaration_order}};
    $bad = copy($bindings->{ALIAS}); $bad->{parameter} = 'wire'; $bad->{token} = 'wire';
    refusal('reserved parameter name', $bad, qr/reserved in SystemVerilog/, $reserved);
    refusal('aggregate parameter path', $bindings->{LANE}, qr/aggregate selection/);
    refusal('aggregate tree', $bindings->{LANES}, qr/unsupported.*list/);
    refusal('raw expression payload', {kind => 'payload', value => {kind => 'scalar_expr', payload => '(BASE + 1)'}}, qr/scalar literal/);
    $bad = copy($bindings->{STATIC_COPY}); $bad->{value_payload} = {kind => 'scalar_expr', payload => '(BASE + 1)'};
    refusal('raw static expression', $bad, qr/scalar literal/);
    $bad = copy($bindings->{STATIC_COPY}); $bad->{scope}{owner} = 'other_top';
    refusal('foreign static scope', $bad, qr/scope/);
    refusal('unsupported target', $bindings->{ALIAS}, qr/Verilog-family/, undef, 'vhdl');
    refusal('missing environment', $bindings->{ALIAS}, qr/environment/, {});
    my $env = copy($environment); pop @{$env->{declaration_order}};
    refusal('incomplete declaration order', $bindings->{ALIAS}, qr/declaration order/, $env);
    $env = copy($environment); push @{$env->{declaration_order}}, 'BASE';
    refusal('duplicate declaration order', $bindings->{ALIAS}, qr/declaration order/, $env);
    my $cycle = {kind => 'operator', operator => '~', source_operator => '~'};
    $cycle->{operands} = [$cycle];
    refusal('recursive caller tree', $cycle, qr/cyclic/);
    $cycle->{operands} = [];
};

done_testing;
