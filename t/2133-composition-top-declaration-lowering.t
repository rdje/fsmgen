use strict;
use warnings;
use lib 'perl';
use Test::More;
use JSON::PP;
use Lispish;
use FSM::Composition::Parser;
use FSM::Composition::PackageImportResolver;
use FSM::Composition::Plan;
use FSM::IR::StructuralRTLIRBuilder;
use FSM::Backend::VerilogFamily::TypeDeclarationSupport;
use FSM::Backend::VerilogFamily::StructuralRTLIREmitter;
use FSM::SourcePathResolver;

my $lowerer = 'FSM::Backend::VerilogFamily::CompositionParameterEmitter';
require_ok($lowerer) or BAIL_OUT('canonical top declaration lowerer is not installed');
my $json = JSON::PP->new->canonical;
sub copy { $json->decode($json->encode($_[0])) }
my $path = 't/data/composition-top-scalar-declarations.fsm';
my $spec = FSM::Composition::Parser->new->parse_source(scalar Lispish::multi($path));
FSM::Composition::PackageImportResolver->resolve_imports(composition_spec => $spec,
    fsm_file => $path, source_path_resolver => FSM::SourcePathResolver->new);
my $top = $spec->top;
my $plan = FSM::Composition::Plan->new(top_name => $top->name, raw_spec => $spec,
    ports => $top->ports_blocks->[0]->ports);
my $structural = FSM::IR::StructuralRTLIRBuilder->build_from_composition_plan($plan)->as_hashref;
my (undef, $typedefs) = FSM::Backend::VerilogFamily::TypeDeclarationSupport->collect_declared_aggregate_typedefs(
    $structural->{ports}, FSM::Backend::VerilogFamily::TypeDeclarationSupport->typedef_state(module_name => $top->name));
sub lower {
    my ($input, $lookup) = @_;
    $lowerer->lower_declarations(structural => $input // $structural,
        aggregate_typedef_lookup => $lookup // $typedefs);
}
sub refuses {
    my ($name, $change, $reason) = @_;
    my $input = copy($structural);
    $change->($input);
    my $before = $json->encode($input);
    my $ok = eval {lower($input);1}; my $error = $@;
    ok(!$ok, "$name refuses");
    like($error, $reason, "$name explains its boundary");
    is($json->encode($input), $before, "$name leaves the caller unchanged");
}
my @expected = (
    {name => 'BASE', default_text => '16', parameter_references => []},
    {name => 'SAME', default_text => '16', parameter_references => []},
    {name => 'ALIAS', default_text => 'BASE', parameter_references => ['BASE']},
    {name => 'FORWARD', default_text => 'ALIAS', parameter_references => ['ALIAS']},
    {name => 'OTHER', default_text => 'SAME', parameter_references => ['SAME']},
    {name => 'SUM', default_text => '(BASE + 2)', parameter_references => ['BASE']},
    {name => 'STATIC_COPY', default_text => '2', parameter_references => []},
    {name => 'HEX', default_text => "8'hA5", parameter_references => []},
    {name => 'NEG', default_text => '-8', parameter_references => []},
);
subtest 'actual source and captured IR preserve symbolic defaults in dependency order' => sub {
    my $before = $json->encode($structural);
    for my $language (qw(systemverilog sv verilog v)) {
        my $input = copy($structural); $input->{target_language} = $language;
        is_deeply(lower($input), \@expected, "$language preserves literal widths, aliases and authored ready-node order");
    }
    is_deeply($structural->{parameter_environment}{declaration_order},
        [qw(FORWARD BASE SAME ALIAS OTHER SUM STATIC_COPY HEX NEG)], 'source declaration order stays separate');
    my $changed = copy($structural);
    $changed->{parameter_environment}{parameters}{BASE}{value_text} = '999';
    $changed->{parameter_environment}{parameters}{BASE}{value_payload}{payload} = '999';
    $changed->{parameter_environment}{parameters}{BASE}{value_width} = 100;
    is_deeply(lower($changed), \@expected, 'validation caches cannot change default text, identity or declaration size');
    my $result = lower(); $result->[2]{parameter_references}[0] = 'WRONG';
    is_deeply(lower(), \@expected, 'nested returned data is isolated');
    is($json->encode($structural), $before, 'entire source-derived structural input stays unchanged');
};
subtest 'each actual structural namespace and generated typedef reserves names' => sub {
    refuses('top module collision', sub {$_[0]{module_name} = 'BASE';
        $_[0]{parameter_environment}{scope}{owner} = 'BASE'}, qr/BASE.*module/);
    for my $case (['ports', 'name', 'port'], ['nets', 'name', 'net'], ['instances', 'instance_name', 'instance']) {
        my ($bucket, $key, $context) = @$case;
        refuses("$context collision", sub {push @{$_[0]{$bucket}}, {$key => 'BASE'}}, qr/BASE.*$context/);
    }
    my ($typedef) = values %$typedefs;
    ok(defined($typedef), 'actual parsed frame port creates a backend typedef');
    my $input = copy($structural);
    $input->{parameter_environment}{parameters}{$typedef} = copy($input->{parameter_environment}{parameters}{BASE});
    $input->{parameter_environment}{default_bindings}{$typedef} = {kind => 'literal', token => '16'};
    push @{$input->{parameter_environment}{declaration_order}}, $typedef;
    my $ok = eval {lower($input);1}; my $error = $@;
    ok(!$ok, 'actual allocated typedef name cannot be shadowed by a parameter');
    like($error, qr/\Q$typedef\E.*typedef/, 'typedef collision names the actual allocation');
    $input = copy($structural); push @{$input->{ports}}, {name => 'base'};
    is_deeply(lower($input), \@expected, 'Verilog namespace remains case-sensitive');
    refuses('unused reserved parameter', sub {
        $_[0]{parameter_environment}{parameters}{wire} = copy($_[0]{parameter_environment}{parameters}{BASE});
        $_[0]{parameter_environment}{default_bindings}{wire} = {kind => 'literal', token => '16'};
        push @{$_[0]{parameter_environment}{declaration_order}}, 'wire';
    }, qr/wire.*reserved/);
};
subtest 'canonical graph and scalar profile refuse invalid prepared callers' => sub {
    refuses('cycle with valid cached numbers', sub {
        $_[0]{parameter_environment}{default_bindings}{BASE} = copy($_[0]{parameter_environment}{default_bindings}{FORWARD});
    }, qr/dependency cycle/);
    refuses('foreign top scope', sub {$_[0]{parameter_environment}{scope}{owner} = 'another_top'}, qr/scope.*module/);
    refuses('foreign binding scope', sub {$_[0]{parameter_environment}{default_bindings}{ALIAS}{scope}{owner} = 'another_top'}, qr/scope/);
    refuses('missing binding', sub {delete $_[0]{parameter_environment}{default_bindings}{BASE}}, qr/default binding/);
    refuses('extra binding', sub {$_[0]{parameter_environment}{default_bindings}{UNKNOWN} = {kind => 'literal', token => '16'}}, qr/default binding/);
    refuses('incomplete order', sub {pop @{$_[0]{parameter_environment}{declaration_order}}}, qr/declaration order/);
    refuses('duplicate order', sub {push @{$_[0]{parameter_environment}{declaration_order}}, 'BASE'}, qr/declaration order/);
    refuses('missing environment', sub {$_[0]{parameter_environment} = undef}, qr/environment/);
    refuses('aggregate parameter', sub {$_[0]{parameter_environment}{parameters}{BASE}{value_kind} = 'list';
        $_[0]{parameter_environment}{parameters}{BASE}{value_payload}{kind} = 'list'}, qr/scalar parameter/);
    refuses('unsupported inferred type', sub {$_[0]{parameter_environment}{parameters}{BASE}{value_type_spec}{kind} = 'record'}, qr/scalar type/);
    refuses('raw default payload', sub {$_[0]{parameter_environment}{default_bindings}{BASE} =
        {kind => 'payload', value => {kind => 'scalar_expr', payload => 'injected'}}}, qr/scalar literal/);
    refuses('unsupported target', sub {$_[0]{target_language} = 'vhdl'}, qr/Verilog-family/);
    refuses('malformed structural namespace', sub {$_[0]{nets} = {}}, qr/nets/);
};
subtest 'declaration preparation preserves static omission and pending emitter boundary' => sub {
    my $static = copy($structural); delete $static->{parameter_environment};
    is_deeply(lower($static), [], 'ordinary structural input adds no parameter declarations');
    my $ok = eval {FSM::Backend::VerilogFamily::StructuralRTLIREmitter->emit_module($structural);1};
    ok(!$ok, 'internal preparation alone does not enable the public emitter');
    like($@, qr/top parameter environment emission is blocked/, 'canonical integration still owns emission');
    ok(!$lowerer->can('emit_module'), 'preparation owns no alternate module-generation entrypoint');
};
done_testing;
