use strict;
use warnings;
use lib 'perl';
use Test::More;
use JSON::PP;
use Lispish;
use FSM::Adapter::FSMGenFull;
use FSM::CoreAST;
use FSM::HDL::FlattenedDT;
use FSM::HDL::FlattenedDT::Backend::SystemVerilog::ScaffoldEmitter;

my $json = JSON::PP->new->canonical;
my $path = 't/data/ial0-scalar-parameter-aliases.fsm';
my $raw = Lispish::multi($path); my $raw_before = $json->encode($raw);
my $module = FSM::Adapter::FSMGenFull->new(debug => 0)->parse_fsm($raw);
my $parameters = $module->parameters; my $sources = $module->parameter_default_sources;
my $bindings = $module->parameter_default_bindings;
my $before = $json->encode({parameters => $parameters, sources => $sources, bindings => $bindings});
my %capture;
sub copy { $json->decode($json->encode($_[0])) }
sub lines_for { [FSM::HDL::FlattenedDT::Backend::SystemVerilog::ScaffoldEmitter::_render_module_parameter_lines($_[0])] }
sub header_module {
    FSM::CoreAST::FSMModule->new(name => 'copied_physical_module',
        parameters => $_[0], _parameter_default_sources => $_[1],
        _parameter_default_bindings => $_[2] // $bindings);
}

subtest 'actual source emits selected aliases through both Verilog-family backends' => sub {
    for my $target (qw(systemverilog verilog)) {
        my $generator = FSM::HDL::FlattenedDT->new(debug => 0);
        my $hdl = $target eq 'systemverilog' ? $generator->generate_systemverilog($module)
            : $generator->generate_verilog($module);
        for my $pair ([BOUND => 'W'], [CHAIN => 'BOUND'], [OTHER => 'SAME'], [BITS_COPY => 'BITS']) {
            like($hdl, qr/parameter \Q$pair->[0]\E = \Q$pair->[1]\E\b/,
                "$target $pair->[0] retains its actual selected root");
        }
        for my $name (qw(LITERAL STATIC SAME W)) {
            like($hdl, qr/parameter \Q$name\E = 16\b/, "$target $name keeps its independent numeric default");
        }
        like($hdl, qr/parameter BITS = 8'hA5\b/, "$target sized root retains its existing literal");
        like($hdl, qr/parameter SUM = \(W \+ 1\)/, "$target scalar operator default now retains its declared root");
        like($hdl, qr/parameter W = 16,\s+parameter BOUND = W,\s+parameter CHAIN = BOUND/s,
            "$target emits forward alias dependencies before their consumers");
        like($hdl, qr/\bOUT\s*=\s*BOUND\b/, "$target executable parameter reference keeps the R11 contract");
        $capture{hdl}{$target} = $hdl;
    }
    is($json->encode({parameters => $module->parameters, sources => $module->parameter_default_sources,
        bindings => $module->parameter_default_bindings}),
        $before, 'complete parameter/source JSON kinds and values remain unchanged');
    is($json->encode($raw), $raw_before, 'original parsed caller stays unchanged');
};

subtest 'metadata observations select identity independently of cached numeric equality' => sub {
    my $cached = copy($parameters); $cached->{BOUND}{value_text} = '999';
    my $physical = header_module($cached, $sources);
    like(join("\n", @{lines_for($physical)}), qr/parameter BOUND = W\b/,
        'changed alias cache cannot replace actual source identity');
    my $selected = copy($sources);
    $selected->{BOUND}{expression} = ['SAME'];
    $selected->{BOUND}{references} = [{parameter => 'SAME', token => 'SAME', suffix => ''}];
    my $selected_bindings = copy($bindings);
    @{$selected_bindings->{BOUND}}{qw(parameter token)} = ('SAME', 'SAME');
    like(join("\n", @{lines_for(header_module($parameters, $selected, $selected_bindings))}), qr/parameter BOUND = SAME\b/,
        'equal-default independent selection changes the emitted binding');
    my $static = FSM::CoreAST::FSMModule->new(name => 'legacy', parameters => {Z => '32', A => {value_text => '8'}});
    my $static_before = $json->encode($static->parameters);
    is_deeply(lines_for($static), ['  parameter A = 8', '  parameter Z = 32'],
        'legacy programmatic literals keep exact alphabetical formatting');
    is($json->encode($static->parameters), $static_before, 'programmatic metadata stays unchanged');
};

subtest 'inconsistent alias observations and dependency cycles refuse contextually' => sub {
    for my $case (
        ['wrong observation', sub {$_[0]{BOUND}{references}[0]{token} = 'SAME'}, qr/alias.*observation/i],
        ['wrong expression', sub {$_[0]{BOUND}{expression} = ['SAME']}, qr/alias.*(?:observation|expression)/i],
        ['missing target', sub {$_[0]{BOUND}{expression} = ['MISSING']; $_[0]{BOUND}{references} = [{parameter => 'MISSING', token => 'MISSING', suffix => ''}]}, qr/alias.*declared/i],
        ['wrong declaration', sub {$_[0]{BOUND}{parameter} = 'OTHER'}, qr/alias.*declaration/i],
        ['cycle', sub {
            $_[0]{W}{expression} = ['CHAIN'];
            $_[0]{W}{references} = [{parameter => 'CHAIN', token => 'CHAIN', suffix => ''}];
            $_[1]{W} = {kind => 'parameter', scope => copy($bindings->{BOUND}{scope}),
                parameter => 'CHAIN', token => 'CHAIN', suffix => ''};
        }, qr/default.*dependency cycle/i],
    ) {
        my ($label, $change, $pattern) = @$case;
        my $input = copy($sources); my $input_bindings = copy($bindings); $change->($input, $input_bindings);
        my $snapshot = $json->encode([$input, $input_bindings]);
        my $ok = eval {lines_for(header_module($parameters, $input, $input_bindings)); 1};
        ok(!$ok, "$label refuses"); like($@, $pattern, "$label names the actual alias contract");
        is($json->encode([$input, $input_bindings]), $snapshot, "$label preserves caller records");
    }
    my $aggregate = copy($parameters); $aggregate->{W}{value_kind} = 'list';
    my $ok = eval {lines_for(header_module($aggregate, $sources)); 1};
    ok(!$ok, 'scalar alias cannot target an aggregate declaration');
    like($@, qr/alias.*scalar declared target/i, 'target type has an explicit refusal');
    my $missing = copy($parameters); $missing->{W}{value_text} = '';
    $ok = eval {lines_for(header_module($missing, $sources)); 1};
    ok(!$ok, 'alias cannot reference a skipped empty declaration');
    like($@, qr/alias.*emitted declared target/i, 'emission membership is checked before rendering');
};

if (my $path = $ENV{FSMGEN_DIRECT_ALIAS_CAPTURE}) {
    $capture{parameters} = $parameters; $capture{sources} = $sources; $capture{bindings} = $bindings;
    open my $out, '>', $path or die $!; print {$out} $json->encode(\%capture), "\n" or die $!;
    close $out or die $!;
}
done_testing;
