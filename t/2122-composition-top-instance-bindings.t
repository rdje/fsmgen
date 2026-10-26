use strict;
use warnings;
use lib 'perl', 't/lib';
use Test::More;
use JSON::PP;
use Cwd qw(getcwd);
use Lispish;
use FSM::Composition::Parser;
use FSM::Composition::Top;
use FSM::Composition::Instance;
use FSM::Composition::TopSymbols;
use FSM::Composition::PackageImportResolver;
use FSM::Composition::ParameterOverrideResolver;
use FSM::ParameterDeclarationSupport;
use FSM::SourcePathResolver;
use FSM::Test::SourceQueryRunner qw(run_source_query normalize_repository_paths);

my $json = JSON::PP->new->canonical;
my $path = 't/data/composition-top-instance-bindings.fsm';
my $scope = {kind => 'composition_top', owner => 'top_instance_bindings'};
my %capture;
sub copy {return $json->decode($json->encode($_[0]))}
sub parameter {my ($name, $suffix) = @_;$suffix //= '';return {
    kind => 'parameter', scope => copy($scope), parameter => $name, token => $name.$suffix, suffix => $suffix}}
sub overrides {return {map {($_->name // $_->module_name) => {map {$_->{name} => $_} @{$_->parameter_overrides}}} @{$_[0]->instances}}}
sub resolve_spec {
    my ($spec, $file) = @_;
    FSM::Composition::PackageImportResolver->resolve_imports(composition_spec => $spec,
        fsm_file => ($file // $path), source_path_resolver => FSM::SourcePathResolver->new);
}

subtest 'one declared-root producer serves defaults and resolved aggregate paths' => sub {
    my $method = FSM::ParameterDeclarationSupport->can('declared_reference');
    ok($method, 'shared declared-root identity producer exists') or return;
    my $declared = {W => {}, FRAME => {}};
    for my $case (['W', 'W', ''], ['FRAME.data[1]', 'FRAME', '.data[1]']) {
        is_deeply($method->('FSM::ParameterDeclarationSupport', $declared, $case->[0]),
            {parameter => $case->[1], token => $case->[0], suffix => $case->[2]}, 'actual root and full aggregate suffix remain explicit');
    }
    is($method->('FSM::ParameterDeclarationSupport', $declared, 'shared.W'), undef, 'unrelated package spelling is not guessed to be a parameter');
    is($method->('FSM::ParameterDeclarationSupport', $declared, '16'), undef, 'equal literal values supply no parameter identity');
};

subtest 'all child forms retain actual scoped bindings beside canonical caches' => sub {
    my $raw = Lispish::multi($path);my $before = $json->encode($raw);
    my $spec = FSM::Composition::Parser->new->parse_source($raw);
    $capture{unresolved} = overrides($spec->top);
    my $ok = eval {resolve_spec($spec);1};
    ok($ok, 'actual top defaults resolve and feed each child override form') or do {diag($@);return};
    my $top = $spec->top;my $o = overrides($top);
    is_deeply($o->{u_fsm}{SCALAR}{binding_expression}, parameter('W'), 'scalar references W rather than another equal-default declaration');
    is_deeply($o->{u_fsm}{EQUAL}{binding_expression}, parameter('SAME'), 'distinct equal-default parameter keeps its own identity');
    is_deeply($o->{u_fsm}{ALIAS}{binding_expression}, parameter('ALIAS'), 'alias reference does not expand to its default');
    is_deeply($o->{u_fsm}{PATH}{binding_expression}, parameter('FRAME', '.tag'), 'map path retains actual parameter root/suffix');
    is_deeply($o->{u_dt}{LEAF}{binding_expression}, parameter('LANES', '[1]'), 'DT item path retains actual parameter root/suffix');
    is_deeply($o->{u_fsm}{AGGREGATE}{binding_expression}, parameter('LANES'), 'whole aggregate parameter remains symbolic');
    is_deeply($o->{u_rtl}{WIDTH}{binding_expression}, parameter('W'), 'RTL scalar uses the same actual top scope');
    is_deeply($o->{u_rtl}{LANES}{binding_expression}, parameter('LANES'), 'RTL aggregate uses the same actual top scope');
    is_deeply($o->{u_fsm}{EXPR}{binding_expression}, {kind => 'operator', operator => '+', source_operator => '+', operands => [parameter('W'),
        {kind => 'static_symbol', scope => copy($scope), token => 'C', value_payload => $top->top_symbols->resolve_payload('C')}]}, 'mixed expression retains mutable identity and immutable static value separately');
    is($o->{u_dt}{MASKED}{binding_expression}{source_operator}, 'xor', 'aggregate operator retains authored alias');
    is($o->{u_dt}{MASKED}{binding_expression}{operands}[1]{kind}, 'static_symbol', 'aggregate package operand stays static');
    is($o->{u_fsm}{SCALAR}{value_text}, '16', 'scalar default remains available for existing validation');
    is($o->{u_fsm}{EXPR}{value_text}, '(16 + 16)', 'expression cache keeps canonical existing text');
    is($o->{u_dt}{MASKED}{value_text}, "16'b0101010100110011", 'aggregate cache preserves canonical leafwise result');
    ok(!exists($o->{u_fsm}{STATIC}{binding_expression}) && !exists($o->{u_fsm}{LITERAL}{binding_expression}), 'static/literal-only override records gain no binding extension');
    is($json->encode($raw), $before, 'complete original source caller stays unchanged');
    $capture{resolved} = copy($o);$capture{graph} = $top->parameter_default_graph;
    $o->{u_fsm}{SCALAR}{binding_expression}{scope}{owner} = 'WRONG';
    is(overrides($top)->{u_fsm}{SCALAR}{binding_expression}{scope}{owner}, $scope->{owner}, 'binding getter cannot change owned lexical identity');
};

subtest 'bound overrides refresh from authored source rather than earlier default caches' => sub {
    my $spec = FSM::Composition::Parser->new->parse_source(scalar Lispish::multi($path));
    my $ok = eval {resolve_spec($spec);1};
    ok($ok, 'original parsed override environment resolves') or do {diag($@);return};
    my $original = $spec->top;my $declared = $original->parameter_declarations;
    for my $entry (@$declared) {$entry->{value_ast} = [['+', ['16', '1']]] if $entry->{name} eq 'W'}
    my @instances = map {FSM::Composition::Instance->new(kind => $_->kind, name => $_->name,
        source_name => $_->source_name, module_name => $_->module_name,
        parameter_overrides => $_->parameter_overrides, raw_items => $_->raw_items, raw_ast => $_->raw_ast)} @{$original->instances};
    my $selected = FSM::Composition::Top->new(name => $original->name,
        parameter_declarations => $declared, top_symbols => $original->top_symbols, instances => \@instances);
    $selected->resolve_parameter_defaults;
    FSM::Composition::ParameterOverrideResolver->resolve_deferred_overrides(top => $selected);
    my $view = overrides($selected);
    is($view->{u_fsm}{SCALAR}{value_text}, '(16 + 1)', 'retry uses the actual new canonical top environment');
    is_deeply($view->{u_fsm}{SCALAR}{binding_expression}, parameter('W'), 'new value does not change real lexical identity');
    ok(!exists($view->{u_fsm}{SCALAR}{value_width}) && !exists($view->{u_fsm}{SCALAR}{value_type_spec}), 'undefined new expression width/type clears earlier derived scalar metadata');
    is(overrides($original)->{u_fsm}{SCALAR}{value_text}, '16', 'reusable caller instance records stay isolated');
    is_deeply($view->{u_fsm}{SCALAR}{raw_value_ast}, ['W'], 'retry retains authored source instead of replacing it with a cache');
    $capture{reselected} = copy($view);
    my $bad = copy($view->{u_fsm}{SCALAR});delete @{$bad}{qw(raw_value_ast raw_value)};
    my $valid = eval {FSM::Composition::ParameterOverrideResolver->_resolve_override(top_name => $selected->name,
        top_parameter_graph => $selected->parameter_default_graph, top_symbols => $selected->top_symbols,
        instance => $instances[0], override => $bad);1};
    ok(!$valid, 'a bound record without authored source cannot be reinterpreted as its normalized number');
    like($@, qr/authored.*source|authored.*expression/, 'missing retained source has a concrete refusal');
};

subtest 'ordinary static and literal records conserve their complete existing shape' => sub {
    my $control = 't/data/composition-top-instance-static-control.fsm';
    my $raw = Lispish::multi($control);my $before = $json->encode($raw);
    my $spec = FSM::Composition::Parser->new->parse_source($raw);resolve_spec($spec, $control);
    my $view = overrides($spec->top);
    for my $row (values %$view) {for my $override (values %$row) {ok(!exists($override->{binding_expression}), 'ordinary static/literal records gain no symbolic binding field')}}
    is($view->{u_fsm}{EXPR}{value_text}, '(16 + 1)', 'old static expression still resolves through the canonical helper');
    is($json->encode($raw), $before, 'whole static source caller is unchanged');
    $capture{static_control} = {overrides => $view, raw => $raw};
};

subtest 'unknown operands and bad paths refuse without static namespace fallthrough' => sub {
    for my $case (['UNKNOWN', qr/UNKNOWN/], ['LANES[99]', qr/top parameter path/], ['W.member', qr/top parameter path/]) {
        my ($operand, $expected) = @$case;
        my $text = "(?top:bad_binding (+params (W 16) (LANES (8'hA5 8'h3C))) (?rtl:child (params (N $operand))))";
        my $raw = Lispish::multi(\$text);my $before = $json->encode($raw);
        my $spec = FSM::Composition::Parser->new->parse_source($raw);
        my $ok = eval {resolve_spec($spec);1};my $error = $@;
        ok(!$ok, "$operand refuses");like($error, $expected, "$operand has its actual contract reason");
        is($json->encode($raw), $before, 'refusal does not change the source caller');
        $capture{refusals}{$operand} = {ok => $ok ? 1 : 0, error => $error};
    }
    my $malformed = {parameters => {W => undef}};my $before = $json->encode($malformed);
    my $ok = eval {FSM::Composition::ParameterOverrideResolver->_resolve_override(
        top_parameter_graph => $malformed, top_symbols => FSM::Composition::TopSymbols->new,
        instance => FSM::Composition::Instance->new(kind => 'rtl', name => 'u', module_name => 'uart_tx'),
        override => {name => 'N', value_kind => 'deferred_symbol', raw_value_ast => ['W']});1};my $error = $@;
    ok(!$ok, 'malformed normalized parameter record refuses');
    like($error, qr/resolved value record for top parameter/, 'malformed graph has its actual missing contract');
    is($json->encode($malformed), $before, 'malformed caller graph is not autovivified on refusal');
    $capture{malformed_graph} = {before => $json->decode($before), after => $malformed, error => $error};
};

subtest 'public transports reach the unchanged pending-lowering boundary after symbolic resolution' => sub {
    my $r = run_source_query({repository_root => getcwd(), query_kind => 'check', row => {
        source_id => $path, query_kinds => ['check'], search_path_relpaths => [], strict => 1}});
    is($r->{native}{exit_code}, 1, 'native check still refuses unfinished HDL lowering');
    is($r->{native}{report}{diagnostics}[0]{code}, 'FSMGEN_COMPOSITION_TOP_PARAMETER_LOWERING', 'source now resolves symbolic overrides before the explicit plan guard');
    like($r->{native}{report}{diagnostics}[0]{message}, qr/top parameter lowering is blocked because/, 'refusal remains the real unfinished stage');
    is($r->{stdio}{exit_code}, 0, 'newline source refusal is a normal protocol result');
    is($r->{stdio}{stderr}, '', 'newline protocol stderr stays clean');
    my $api = $r->{adapter_result};ok($api->{isError}, 'source refusal remains a tool error');
    is_deeply($api->{structuredContent}{report}, normalize_repository_paths($r->{native}{report}, getcwd()), 'complete native/API report equality');
    is_deeply($json->decode($api->{content}[0]{text}), $api->{structuredContent}, 'complete text/structured equality');
    is_deeply($r->{stdio}{response}, {jsonrpc => '2.0', id => 1, result => $api}, 'complete actual newline/API equality');
    is($r->{source_sha256_after}, $r->{source_sha256_before}, 'public source bytes stay exact');
    is_deeply($r->{producer_sha256_after}, $r->{producer_sha256_before}, 'selected public producers stay exact');
    $capture{public} = normalize_repository_paths($r, getcwd());
};

if (my $out_path = $ENV{FSMGEN_TOP_INSTANCE_BINDING_CAPTURE}) {
    open my $out, '>', $out_path or die $!;print {$out} $json->encode(\%capture), "\n" or die $!;close $out or die $!;
}
done_testing();
