use strict;
use warnings;
use lib 'perl';
use Test::More;
use JSON::PP;
use File::Temp qw(tempdir);
use File::Spec;
use Cwd qw(abs_path);
use Lispish;
use FSM::Adapter::FSMGenFull;
use FSM::CoreAST;
use FSM::HDL::FlattenedDT;
use FSM::IR::IntentHIRBuilder;

my $json = JSON::PP->new->canonical;
my $fixture = 't/data/ial0-parameter-default-sources.fsm';
my $raw = Lispish::multi($fixture);
my $raw_before = $json->encode($raw);
my $adapter = FSM::Adapter::FSMGenFull->new(debug => 0);
my $module = $adapter->parse_fsm($raw);
my $parameters_before = $json->encode($module->parameters);
my $tempdir = tempdir(CLEANUP => 1);

sub sources {return $_[0]->can('parameter_default_sources') ? $_[0]->parameter_default_sources : undef}
sub reference {my ($parameter, $token, $suffix) = @_; return {parameter => $parameter, token => $token, suffix => $suffix // ''}}
sub record {my ($name, $expression, @references) = @_; return {
    parameter => $name, source_module => 'parameter_default_sources',
    expression => $expression, references => \@references,
}}
my $expected = {
    FORWARD => record('FORWARD', ['W'], reference('W', 'W')),
    CHAIN => record('CHAIN', ['FORWARD'], reference('FORWARD', 'FORWARD')),
    W => record('W', ['16']),
    STATIC => record('STATIC', ['FIXED']),
    MODE => record('MODE', ['mode.EIGHT']),
    ITEMS => record('ITEMS', [["8'hA5", ["8'h3C"]]]),
    CONFIG => record('CONFIG', [[['flag', ['W']], [['lanes', ['ITEMS']]]]],
        reference('W', 'W'), reference('ITEMS', 'ITEMS')),
    LEAF => record('LEAF', ['CONFIG.flag'], reference('CONFIG', 'CONFIG.flag', '.flag')),
    LANE => record('LANE', ['CONFIG.lanes[1]'], reference('CONFIG', 'CONFIG.lanes[1]', '.lanes[1]')),
    SUM => record('SUM', [['+', ['W', '1']]], reference('W', 'W')),
    REPEATED => record('REPEATED', [['+', ['W', 'W']]], reference('W', 'W'), reference('W', 'W')),
    COPY => record('COPY', ['CONFIG'], reference('CONFIG', 'CONFIG')),
};

subtest 'authored defaults retain direct parameter identity beside canonical values' => sub {
    is($json->encode(sources($module)), $json->encode($expected),
        'exact authored token trees and successful direct references survive normalization');
    is($module->parameters->{FORWARD}{value_text}, '16', 'forward reference keeps the canonical parameter namespace');
    is($module->parameters->{STATIC}{value_text}, '16', 'equal static value remains static in the source record');
    is($json->encode($raw), $raw_before, 'complete frontend caller is unchanged');
};

subtest 'equal normalized defaults do not erase alias identity' => sub {
    my $alias = parse_text('(?fsm:equal_defaults (+params (W 16) (BOUND W)))');
    my $literal = parse_text('(?fsm:equal_defaults (+params (W 16) (BOUND 16)))');
    is($json->encode($alias->parameters), $json->encode($literal->parameters), 'old complete parameter products stay equal');
    my $a = sources($alias); my $b = sources($literal);
    is($json->encode($a && $a->{BOUND}{expression}), '["W"]', 'alias source stays named');
    is($json->encode($b && $b->{BOUND}{expression}), '["16"]', 'literal source stays a string token');
    is($json->encode($a && $a->{BOUND}{references}),
        $json->encode([reference('W', 'W')]), 'alias dependency is observed at resolution');
    is_deeply($b && $b->{BOUND}{references}, [], 'literal has no invented dependency');
};

subtest 'metadata snapshots cannot mutate source, defaults or sibling records' => sub {
    my $view = sources($module);
    if (!defined $view) {fail('source metadata accessor is required'); return}
    $view->{CONFIG}{expression}[0][0][1][0] = 'WRONG';
    $view->{COPY}{references}[0]{parameter} = 'WRONG';
    is($json->encode(sources($module)), $json->encode($expected), 'nested getter values are detached');
    is($json->encode($module->parameters), $parameters_before, 'source mutations cannot change executable defaults');
    is($json->encode($raw), $raw_before, 'source mutations cannot change the original caller');
    my $fresh = FSM::Adapter::FSMGenFull->new(debug => 0)->parse_fsm(Lispish::multi($fixture));
    is($json->encode(sources($fresh)), $json->encode($expected), 'fresh parse has independent complete records');

    my $input = {A => {parameter => 'A', source_module => 'manual',
        expression => [{kind => 'scalar', payload => '8'}], references => []}};
    my $manual = FSM::CoreAST::FSMModule->new(name => 'manual', parameters => {A => {value_text => '8'}},
        _parameter_default_sources => $input);
    my $sibling = FSM::CoreAST::FSMModule->new(name => 'manual', parameters => {A => {value_text => '8'}},
        _parameter_default_sources => $input);
    $input->{A}{expression}[0]{payload} = 'WRONG';
    is(sources($manual)->{A}{expression}[0]{payload}, '8', 'constructor clones nested source payloads');
    my $replacement = {parameter => 'A', source_module => 'replacement', expression => ['16'], references => []};
    $manual->set_parameter('A', {value_text => '16'}, $replacement);
    $replacement->{expression}[0] = 'WRONG';
    is_deeply(sources($manual)->{A}{expression}, ['16'], 'setter clones its source argument');
    is(sources($sibling)->{A}{expression}[0]{payload}, '8', 'sibling keeps its own source record');
    $manual->set_parameter('A', {value_text => '32'});
    is_deeply(sources($manual), {}, 'replacing a value without source clears stale provenance');
    my $plain = FSM::CoreAST::FSMModule->new(name => 'plain', parameters => {A => {value_text => '8'}});
    is_deeply(sources($plain), {}, 'programmatic values acquire no invented source');
};

subtest 'admitted semantic payload sources retain primitive kinds' => sub {
    my $tree = [['?fsm:payload_source', [['+params', [['VALUE', {kind => 'scalar', payload => '16'}]]]]]];
    my $parsed = FSM::Adapter::FSMGenFull->new(debug => 0)->parse_fsm($tree);
    my $view = sources($parsed);
    is($json->encode($view && $view->{VALUE}{expression}), '{"kind":"scalar","payload":"16"}',
        'semantic hash expression is copied without token-kind coercion');
    $tree->[0][1][0][1][0][1]{payload} = 'WRONG';
    is($json->encode(sources($parsed) && sources($parsed)->{VALUE}{expression}),
        '{"kind":"scalar","payload":"16"}', 'caller hash mutation cannot contaminate the retained source');
    is($parsed->parameters->{VALUE}{value_text}, '16', 'existing canonical payload value remains unchanged');
};

subtest 'canonical graph refusals and public products remain bounded' => sub {
    for my $case (
        ['(?fsm:cycle (+params (A B) (B A)))', qr/parameter dependency cycles are blocked/],
        ['(?fsm:unknown (+params (A UNKNOWN)))', qr/saw 'UNKNOWN'/],
        ['(?fsm:bad_path (+params (A CFG.missing) (CFG ((flag 1)))))', qr/saw 'CFG\.missing'/],
    ) {
        my $ok = eval {parse_text($case->[0]); 1};
        ok(!$ok, 'invalid dependency remains rejected'); like($@, $case->[1], 'canonical refusal is preserved');
    }
    my $intent = FSM::IR::IntentHIRBuilder->build_from_fsm_module(fsm_module => $module)->as_hashref;
    my $hdl = FSM::HDL::FlattenedDT->new(debug => 0)->generate_systemverilog($module);
    unlike($json->encode($intent), qr/"(?:_?parameter_default_sources|source_module|references)"\s*:/, 'private metadata stays out of IntentHIR');
    like($hdl, qr/parameter FORWARD = W\b/, 'direct scalar alias now reaches HDL through retained source observations');
    unlike($hdl, qr/parameter_default_sources\s*[=:]/, 'source metadata is not emitted as HDL declarations');
    if (my $path = $ENV{FSMGEN_PARAMETER_DEFAULT_CAPTURE}) {
        $hdl =~ s/^\/\/ Date: .*$/\/\/ Date: <timestamp>/m;
        my $root = abs_path('.');
        open my $out, '>', $path or die $!;
        print {$out} $json->encode({raw_ast => $raw, parameters => $module->parameters,
            manager_parameters => $adapter->{signal_manager}{params}, intent => $intent, hdl => $hdl,
            sources => sources($module), loaded => {map {$_ => File::Spec->abs2rel(abs_path($INC{$_}), $root)}
                qw(FSM/CoreAST.pm FSM/Adapter/FSMGenFull/Parser.pm FSM/ParameterValueSupport.pm)}}), "\n" or die $!;
        close $out or die $!;
    }
};

done_testing();

sub parse_text {
    my ($text) = @_;
    my ($fh, $path) = File::Temp::tempfile(DIR => $tempdir, SUFFIX => '.fsm');
    print {$fh} $text, "\n" or die $!; close $fh or die $!;
    return FSM::Adapter::FSMGenFull->new(debug => 0)->parse_fsm(Lispish::multi($path));
}
