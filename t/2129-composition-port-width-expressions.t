use strict;
use warnings;
use lib 'perl';
use Test::More;
use JSON::PP;
use Lispish;
use FSM::Composition::Parser;
use FSM::Composition::PackageImportResolver;
use FSM::Composition::PortWidthResolver;
use FSM::Composition::PlanBuilder;
use FSM::SourcePathResolver;
my $json = JSON::PP->new->canonical;
my $path = 't/data/composition-top-port-width-expressions.fsm';
sub parse_text { my $text = $_[0]; FSM::Composition::Parser->new->parse_source(scalar Lispish::multi(\$text)) }
sub resolve {
    FSM::Composition::PackageImportResolver->resolve_imports(composition_spec => $_[0],
        fsm_file => $path, source_path_resolver => FSM::SourcePathResolver->new);
}
sub ports { +{map {$_->name => $_} @{$_[0]->top->ports_blocks->[0]->ports}} }
subtest 'actual source retains declared identities after import and default resolution' => sub {
    my $ast = Lispish::multi($path); my $before = $json->encode($ast);
    my $spec = FSM::Composition::Parser->new->parse_source($ast);
    is(ports($spec)->{data}->width, undef, 'structured width awaits resolved imports/defaults');
    resolve($spec);
    my $p = ports($spec);
    is_deeply([map {$p->{$_}->width} qw(data result explicit_static typed static)], [18,24,17,7,16],
        'independent literal widths include declared alias, mixed package and named-type precedence');
    is($p->{typed}->signed, 1, 'type signedness survives');
    is($p->{typed}->declared_type_name, 'TYPE', 'same-named scalar does not replace type');
    is($p->{clock}->type, 'clock', 'clock role survives');
    is($p->{reset}->type, 'reset', 'reset role survives');
    is_deeply($p->{data}->width_contract, {
        scope => {kind => 'composition_top', owner => 'port_widths'},
        expression => ['+', [['param', ['ALIAS']], 'widths.EXTRA']],
        references => [{kind => 'parameter', token => 'ALIAS'},
            {kind => 'static_symbol', token => 'widths.EXTRA', value_payload => {kind => 'scalar', payload => '2'}}],
    }, 'actual lookup order, alias identity and static cache accompany authored AST');
    is_deeply($p->{result}->width_contract->{references}, [{kind => 'parameter', token => 'W'}],
        'equal-default alias does not replace W');
    is($p->{static}->width_contract, undef, 'ordinary scalar port has no optional contract');
    is($json->encode($ast), $before, 'complete caller source and JSON kinds conserve');
    my $original = $json->encode($p->{data}->width_contract);
    my $contract = $p->{data}->width_contract;
    $contract->{expression}[1][0][1][0] = 'WRONG';
    $contract->{references}[1]{value_payload}{payload} = '99';
    $contract->{scope}{owner} = 'WRONG';
    my $token = $p->{data}->width_token; $token->[0] = 'WRONG';
    is($json->encode($p->{data}->width_contract), $original, 'all returned width products are detached');
    FSM::Composition::PortWidthResolver->resolve_declared_port_widths(top => $spec->top);
    is($json->encode($p->{data}->width_contract), $original, 'repeat resolution uses authored source');
    $spec->top->top_symbols->store_constant('BASE', {kind => 'scalar', payload => '20'});
    resolve($spec);
    is($p->{data}->width, 22, 'retry recomputes from current actual defaults');
    is($p->{data}->width_contract->{references}[0]{token}, 'ALIAS', 'retry preserves authored alias');
    $spec->top->top_symbols->store_constant('BASE', {kind => 'list', items => [{kind => 'scalar', payload => '1'}]});
    my $ok = eval {resolve($spec);1};
    ok(!$ok, 'changed aggregate default refuses width retry');
    is($p->{data}->width, undef, 'failed width retry removes stale positive cache');
    is($p->{data}->width_contract, undef, 'failed width retry removes stale contract');
    is($p->{result}->width, undef, 'failure also clears later expression widths');
    is($p->{result}->width_contract, undef, 'failure also clears later expression contracts');
    $spec->top->top_symbols->store_constant('BASE', {kind => 'scalar', payload => '16'});
    resolve($spec);
    $spec->top->top_symbols->store_constant('BASE', {kind => 'scalar_expr', payload => 'MISSING+1'});
    $ok = eval {resolve($spec);1};
    ok(!$ok, 'default resolution failure refuses before port evaluation');
    is($p->{data}->width, undef, 'failed default retry cannot leave old width');
    is($p->{result}->width_contract, undef, 'failed default retry cannot leave later source cache');
};
subtest 'actual hostile source refuses the selected namespace and bounded arithmetic' => sub {
    for my $case (
        ['(param MISSING)', qr/unknown declared parameter 'MISSING'/],
        ['(param BASE)', qr/unknown declared parameter 'BASE'/],
        ['(+ W 1)', qr/unknown or non-scalar constant symbol 'W'/],
        ['(param GROUP)', qr/aggregate payload kind 'list'/],
        ['(- (param W) 17)', qr/negative width-expression/],
        ['(/ (param W) 0)', qr/divides by zero/],
        ['(- (param W) 16)', qr/positive integer width/],
        ['(<< (param W) 1)', qr/unsupported width expression operator/],
        ['(param W BASE)', qr/exactly one declared parameter/],
    ) {
        my $text = '(?top:bad (+params (W 16) (GROUP (1 2))) (+constants (BASE 16)) (?ports (input data (width '.$case->[0].'))))';
        my $ok = eval {my $spec = parse_text($text); resolve($spec);1};
        ok(!$ok, "$case->[0] refuses"); like($@, $case->[1], 'canonical failure meaning');
        like($@, qr/Composition top 'bad'.*\?ports.*data/s, 'actual top/port context');
    }
};
done_testing;
