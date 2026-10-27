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
use FSM::Support::RegressionCorpus qw(regression_corpus_entries);

my $json = JSON::PP->new->canonical;
my $path = 't/data/ial0-scalar-default-expressions.fsm';
my $raw = Lispish::multi($path); my $raw_before = $json->encode($raw);
my $module = FSM::Adapter::FSMGenFull->new(debug => 0)->parse_fsm($raw);
my $parameters = $module->parameters; my $sources = $module->parameter_default_sources;
my $bindings = $module->parameter_default_bindings;
my $before = $json->encode([$parameters, $sources, $bindings]);
my %capture;
sub copy {return $json->decode($json->encode($_[0]))}
sub lines_for {return [FSM::HDL::FlattenedDT::Backend::SystemVerilog::ScaffoldEmitter::_render_module_parameter_lines($_[0])]}
sub snapshot {
    my ($p, $s, $b) = @_;
    return FSM::CoreAST::FSMModule->new(name => 'renamed_physical_module',
        parameters => $p, _parameter_default_sources => $s, _parameter_default_bindings => $b);
}

subtest 'actual scalar defaults retain operators and selected roots in both target headers' => sub {
    for my $language (qw(systemverilog verilog)) {
        my $generator = FSM::HDL::FlattenedDT->new(debug => 0);
        my $hdl = $language eq 'systemverilog' ? $generator->generate_systemverilog($module)
            : $generator->generate_verilog($module);
        like($hdl, qr/parameter FIRST_PLUS = \(ALIAS \+ 1\)/, "$language retains the immediate alias operand");
        like($hdl, qr/parameter NESTED = \(\(W \+ 16\) - \(SAME \* 2\)\)/, "$language preserves nested mutable and static meaning");
        like($hdl, qr/parameter MASK = \(BITS \^ 8'h0F\)/, "$language shares canonical word-operator normalization");
        like($hdl, qr/parameter STATIC_SUM = \(16 \+ 1\)/, "$language retains immutable static arithmetic");
        like($hdl, qr/parameter OTHER = SAME\b/, "$language keeps distinct equal-default identity");
        like($hdl, qr/parameter LITERAL = 16\b/, "$language equal literal stays independent");
        like($hdl, qr/parameter ZERO = 0\b/, "$language retains zero defaults");
        my $w = index($hdl, 'parameter W ='); my $a = index($hdl, 'parameter ALIAS =');
        my $f = index($hdl, 'parameter FIRST_PLUS =');
        ok($w >= 0 && $w < $a && $a < $f, "$language declares actual forward dependencies before consumers");
        like($hdl, qr/\bOUT\s*=\s*FIRST_PLUS\b/, "$language keeps executable R11 references");
        $hdl =~ s/^\/\/ Date: .*$/\/\/ Date: <timestamp>/m;
        $capture{hdl}{$language} = $hdl;
    }
    is($json->encode([$module->parameters, $module->parameter_default_sources, $module->parameter_default_bindings]),
        $before, 'complete Core snapshots and JSON kinds remain unchanged');
    is($json->encode($raw), $raw_before, 'complete source caller remains unchanged');
};

subtest 'copied lexical bindings ignore validation numbers and preserve static selection' => sub {
    my $changed = copy($parameters);
    $changed->{FIRST_PLUS}{value_text} = '999'; $changed->{STATIC_SUM}{value_text} = '999';
    my $lines = join("\n", @{lines_for(snapshot($changed, $sources, $bindings))});
    like($lines, qr/parameter FIRST_PLUS = \(ALIAS \+ 1\)/, 'changed result cache cannot replace source operands');
    like($lines, qr/parameter STATIC_SUM = \(16 \+ 1\)/, 'changed result cache cannot replace selected static arithmetic');
    like($lines, qr/parameter ALIAS = W\b/, 'physical module rename keeps original local source ownership');
};

subtest 'named corpus contract accounts for the actual scalar header fixture' => sub {
    my ($entry) = grep {$_->{id} eq 'feature.direct_scalar_default_relationships'} regression_corpus_entries();
    ok($entry, 'source has an owning supported corpus contract') or return;
    is($entry->{relpath}, $path, 'catalog names the actual tested source');
    is($entry->{expected_module_name}, $module->name, 'catalog module identity comes from the parsed source');
    for my $pattern (@{$entry->{expected_hdl_patterns}}) {
        like($capture{hdl}{systemverilog}, $pattern, 'catalog shape oracle matches actual emitted source');
    }
};

subtest 'missing, stale, foreign and inconsistent captured snapshots refuse' => sub {
    for my $case (
        ['missing binding', sub {delete $_[1]{FIRST_PLUS}}, qr/binding.*membership|complete.*binding/i],
        ['foreign node', sub {$_[1]{FIRST_PLUS}{operands}[0]{scope}{owner} = 'other_source'}, qr/scope/],
        ['mixed source owners', sub {$_[0]{W}{source_module} = 'other_source'}, qr/source.*scope|source.*owner/i],
        ['discarded observation', sub {$_[0]{FIRST_PLUS}{references} = []}, qr/reference observation/i],
        ['unknown binding tag', sub {$_[1]{ZERO}{kind} = 'raw_hdl'}, qr/canonical binding record/i],
        ['raw payload', sub {$_[1]{W} = {kind => 'payload', value => {kind => 'scalar_expr', payload => '(W + 1)'}}}, qr/scalar literal/],
        ['dependency cycle', sub {
            $_[0]{W}{expression} = ['FIRST_PLUS'];
            $_[0]{W}{references} = [{parameter => 'FIRST_PLUS', token => 'FIRST_PLUS', suffix => ''}];
            $_[1]{W} = {kind => 'parameter', scope => {kind => 'direct_module', owner => 'scalar_default_expressions'},
                parameter => 'FIRST_PLUS', token => 'FIRST_PLUS', suffix => ''};
        }, qr/default.*dependency cycle/i],
    ) {
        my ($name, $change, $reason) = @$case;
        my ($s, $b) = (copy($sources), copy($bindings)); $change->($s, $b);
        my $old = $json->encode([$s, $b]);
        my $ok = eval {lines_for(snapshot($parameters, $s, $b)); 1}; my $error = $@;
        ok(!$ok, "$name refuses"); like($error, $reason, "$name identifies its missing contract");
        is($json->encode([$s, $b]), $old, "$name leaves caller records unchanged");
        $capture{refusals}{$name} = $error;
    }
    my $stale = snapshot($parameters, $sources, $bindings);
    $stale->set_parameter('W', $parameters->{W}, $sources->{W});
    my $ok = eval {lines_for($stale); 1};
    ok(!$ok, 'invalidated source snapshot cannot fall back to normalized defaults');
    like($@, qr/binding.*membership|complete.*binding/i, 'invalidation requires a fresh complete binding snapshot');
    my $bad_info = copy($parameters); $bad_info->{ZERO}{value_kind} = 'unsupported';
    $ok = eval {lines_for(snapshot($bad_info, $sources, $bindings)); 1};
    ok(!$ok, 'unknown captured declaration kind refuses');
    like($@, qr/normalized declaration evidence/, 'captured declaration evidence has a closed kind domain');
    my $text = '(?fsm:reserved_parameter (+params (wire 1)))';
    my $bad = FSM::Adapter::FSMGenFull->new(debug => 0)->parse_fsm(Lispish::multi(\$text));
    $ok = eval {lines_for($bad); 1};
    ok(!$ok, 'unused reserved declaration name also refuses'); like($@, qr/reserved/, 'target declaration guard names reservation');
};

if (my $path = $ENV{FSMGEN_SCALAR_DEFAULT_HEADER_CAPTURE}) {
    open my $out, '>', $path or die $!;
    print {$out} $json->encode({%capture, parameters => $parameters, sources => $sources, bindings => $bindings}), "\n" or die $!;
    close $out or die $!;
}
done_testing();
