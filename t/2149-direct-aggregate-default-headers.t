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
my $path = 't/data/ial0-static-aggregate-defaults.fsm';
my $raw = Lispish::multi($path);
my $module = FSM::Adapter::FSMGenFull->new(debug => 0)->parse_fsm($raw);
my $parameters = $module->parameters; my $sources = $module->parameter_default_sources;
my $bindings = $module->parameter_default_bindings;
my $before = $json->encode([$raw, $parameters, $sources, $bindings]);
my %capture;
sub copy {return $json->decode($json->encode($_[0]))}
sub lines_for {return [FSM::HDL::FlattenedDT::Backend::SystemVerilog::ScaffoldEmitter::_render_module_parameter_lines($_[0])]}
sub snapshot {
    return FSM::CoreAST::FSMModule->new(name => 'physical_copy', parameters => $_[0],
        _parameter_default_sources => $_[1], _parameter_default_bindings => $_[2]);
}

subtest 'immutable aggregate headers and executable references preserve actual source meaning' => sub {
    for my $target (qw(systemverilog verilog)) {
        my $generator = FSM::HDL::FlattenedDT->new(debug => 0);
        my $hdl = $target eq 'systemverilog' ? $generator->generate_systemverilog($module)
            : $generator->generate_verilog($module);
        for my $pair ([ITEMS => "16'b1010010100111100"], [FRAME => "10'b1010100011"],
            [STATIC => "16'b1010010100111100"], [SUM => "16'b1010011000111110"],
            [INVERT => "16'b0101101011000011"], [MATCH => "1'b1"], [MIXED => "(1'b1 + W)"]) {
            like($hdl, qr/parameter \Q$pair->[0]\E = \Q$pair->[1]\E(?:,|\n)/, "$target $pair->[0] has independently expected value or relationship");
        }
        ok(index($hdl, 'parameter W =') < index($hdl, 'parameter MIXED ='), "$target orders the remaining mutable scalar dependency");
        like($hdl, qr/\bPACKED_OUT\s*=\s*ITEMS\b/, "$target executable aggregate root remains named");
        $hdl =~ s/^\/\/ Date: .*$/\/\/ Date: <timestamp>/m;
        $capture{hdl}{$target} = $hdl;
    }
    my $changed = copy($parameters);
    $changed->{ITEMS}{value_text} = "16'b0"; $changed->{MIXED}{value_text} = '999';
    my $lines = join("\n", @{lines_for(snapshot($changed, $sources, $bindings))});
    like($lines, qr/parameter ITEMS = 16'b1010010100111100/, 'aggregate output ignores a changed selected result cache');
    like($lines, qr/parameter MIXED = \(1'b1 \+ W\)/, 'scalar result with immutable aggregate operands retains mutable scalar identity');
    is($json->encode([$raw, $module->parameters, $module->parameter_default_sources, $module->parameter_default_bindings]),
        $before, 'complete source and Core caller JSON kinds are conserved');
};

subtest 'actual mutable aggregate and path defaults fail before returning either target' => sub {
    for my $case (
        ['root alias', "(BASE (8'hA5 8'h3C)) (COPY BASE)", 'BASE'],
        ['selected item', "(BASE (8'hA5 8'h3C)) (LEAF BASE[1])", 'BASE'],
        ['scalar comparison', "(BASE (8'hA5 8'h3C)) (MATCH (== BASE BASE))", 'BASE'],
        ['aggregate operator', "(BASE (8'hA5 8'h3C)) (MASK (xor BASE BASE))", 'BASE'],
        ['parameter list member', "(W 8'hA5) (PACKED (W 8'h3C))", 'W'],
        ['parameter record member', "(W 8'hA5) (PACKED ((data W) (flag 1'b1)))", 'W'],
    ) {
        my ($label, $params, $dependency) = @$case;
        my $text = "(?fsm:mutable_default (+system (clock clk)) (+params $params) (+size (OUT 1)) (idle (= (OUT 0))))";
        my $m = FSM::Adapter::FSMGenFull->new(debug => 0)->parse_fsm(Lispish::multi(\$text));
        my $old = $json->encode([$m->parameters, $m->parameter_default_sources, $m->parameter_default_bindings]);
        for my $target (qw(systemverilog verilog)) {
            my $generator = FSM::HDL::FlattenedDT->new(debug => 0);
            my $ok = eval {$target eq 'systemverilog' ? $generator->generate_systemverilog($m) : $generator->generate_verilog($m); 1};
            my $error = $@;
            ok(!$ok, "$target $label refuses selected-default freezing");
            like($error, qr/(?:aggregate|selection).*mutable parameter/i, "$target $label names its unsupported profile");
            like($error, qr/\Q$dependency\E/, "$target $label names its actual dependency");
            $capture{refusals}{$label}{$target} = $error;
        }
        is($json->encode([$m->parameters, $m->parameter_default_sources, $m->parameter_default_bindings]), $old,
            "$label preserves normalized/source/binding products");
    }
};

subtest 'named supported corpus contract binds the actual static aggregate fixture' => sub {
    my ($entry) = grep {$_->{id} eq 'feature.direct_static_aggregate_defaults'} regression_corpus_entries();
    ok($entry, 'static aggregate source has a named corpus contract') or return;
    is($entry->{relpath}, $path, 'catalog names the tested actual source');
    for my $pattern (@{$entry->{expected_hdl_patterns}}) {
        like($capture{hdl}{systemverilog}, $pattern, 'catalog shape matches independently checked actual HDL');
    }
};

if (my $path = $ENV{FSMGEN_AGGREGATE_DEFAULT_HEADER_CAPTURE}) {
    open my $out, '>', $path or die $!;
    print {$out} $json->encode({%capture, parameters => $parameters, sources => $sources, bindings => $bindings}), "\n" or die $!;
    close $out or die $!;
}
done_testing();
