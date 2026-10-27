use strict;
use warnings;
use lib 'perl';
use Test::More;
use JSON::PP;
use Lispish;
use FSM::Adapter::FSMGenFull;
use FSM::HDL::FlattenedDT;
use FSM::HDL::FlattenedDT::Backend::VHDL;

my $json = JSON::PP->new->canonical;
open my $in, '<', 't/data/ial0-direct-symbolic-comb.fsm' or die $!;
my $template = do {local $/; <$in>}; close $in or die $!;
sub source {
    my ($width) = @_;
    my $text = $template =~ s/\(W 1\)/(W $width)/r;
    $text =~ s/\(SAME 1\)/(SAME $width)/;
    return $text;
}
sub parse {
    my ($text) = @_;
    return FSM::Adapter::FSMGenFull->new(debug => 0)->parse_fsm(scalar Lispish::multi(\$text));
}
sub captures {
    my ($m) = @_;
    return $json->encode([$m->parameters, $m->parameter_default_sources,
        $m->parameter_default_bindings, {map {my $s = $m->signals->{$_}; $_ => [
            $s->declared_width_source, $s->declared_width_binding, $s->declared_width_requirements]
        } keys %{$m->signals}}]);
}
subtest 'actual source generation joins symbolic ports, assignments and natural generics' => sub {
    for my $width (1, 8) {
        my $m = parse(source($width));
        my $before = captures($m);
        my $dt = FSM::HDL::FlattenedDT->new(debug => 0);
        my $hdl = eval {$dt->generate_vhdl($m)};
        ok(defined($hdl), "direct source returns VHDL at default $width") or diag $@;
        next unless defined($hdl);
        like($hdl, qr/entity direct_symbolic_comb is/, 'physical name is normalized');
        my ($generics) = $hdl =~ /  generic \(\n(.*?)\n  \);/s;
        is($generics, "    SAME : integer := $width;\n    W : natural := $width;\n    COPY : natural := W",
            'complete generic block preserves independent default and actual width roots');
        my ($ports) = $hdl =~ /  port \(\n(.*?)\n  \);/s;
        is($ports, "    clk : in std_logic;\n    rst_n : in std_logic;\n"
            . "    INPUT_PORT : in std_logic_vector((W - 1) downto 0);\n"
            . '    DATA : out std_logic_vector((COPY - 1) downto 0)',
            'complete port block keeps both symbolic source identities and vector rank');
        my $zero = '0' x $width;
        like($hdl, qr/DATA <= std_logic_vector\(resize\(unsigned'\("$zero"\), DATA'length\)\);/,
            'generated mux default uses target length');
        like($hdl, qr/DATA <= std_logic_vector\(resize\(unsigned\(INPUT_PORT\), DATA'length\)\);/,
            'actual mux assignment uses qualified conversion');
        is(captures($m), $before, 'complete original lexical captures and JSON kinds conserve');
        is($dt->generate_vhdl($m), $hdl, 'same backend reuses generation without stale captures');
        my $sv = $dt->generate_systemverilog($m);
        my $raw = FSM::HDL::FlattenedDT::Backend::VHDL->new(flattened_dt => {});
        ok(!eval {$raw->convert_systemverilog_to_vhdl($sv); 1}, 'raw symbolic conversion stays refused');
        like($@, qr/unsupported generated port declaration/, 'raw conversion gains no source authority');
    }
};
subtest 'unqualified generated helper shapes refuse before any artifact returns' => sub {
    for my $text (source(8) =~ s/\(= \(DATA INPUT_PORT\)\)/(\<-= (DATA INPUT_PORT))/r,
        source(8) =~ s/\(= \(DATA INPUT_PORT\)\)/(= (DATA (+ INPUT_PORT INPUT_PORT)))/r,
        source(8) =~ s/ \(-> idle\)//r) {
        my $m = parse($text);
        my $before = captures($m);
        my $hdl = eval {FSM::HDL::FlattenedDT->new(debug => 0)->generate_vhdl($m)};
        ok(!defined($hdl), 'unqualified helper returns no partial VHDL artifact');
        like($@, qr/symbolic.*(?:auxiliary|intermediate|computed|state.hold)/, 'refusal names missing elaborated helper shape');
        is(captures($m), $before, 'refusal preserves complete lexical captures');
    }
};
subtest 'fixed source generation preserves whole raw converter output' => sub {
    my $text = source(8) =~ s/\(param (?:COPY|W)\)/8/gr;
    $text =~ s/^  \(\+params[^\n]+\)\n//m;
    my $m = parse($text);
    my $dt = FSM::HDL::FlattenedDT->new(debug => 0);
    my $sv = $dt->generate_systemverilog($m);
    my $raw = FSM::HDL::FlattenedDT::Backend::VHDL->new(flattened_dt => {})->convert_systemverilog_to_vhdl($sv);
    my $direct = $dt->generate_vhdl($m);
    is($direct, $raw, 'entire fixed body/declaration product preserves raw conversion');
};
subtest 'only complete compiler-owned transition families leave source data-width membership' => sub {
    my $m = parse(source(8));
    my $dt = FSM::HDL::FlattenedDT->new(debug => 0);
    $dt->generate_systemverilog($m);
    my $analysis = $dt->{assignment_analysis};
    my $plan = FSM::DirectDeclaredWidthSupport->prepare_module(fsm_module => $m,
        assignment_analysis => $analysis, target_language => 'systemverilog');
    ok(!exists($plan->{signals}{next_state}), 'fixed compiler state control is not a source data Signal');
    for my $control (
        sub {$_[0]{lhs_ast} = FSM::AST::SignalRef->new('next_state')},
        sub {$_[0]{lhs_ast} = FSM::AST::SignalRef->new('DATA', is_fsm_state_next => 1)},
        sub {$_[0]{assignments} = []},
        sub {$_[0]{assignments}[0]{rhs} = 'FOREIGN'},
        sub {$_[0]{assignments}[0]{source_provenance}{origin} = 'ordinary_assignment'},
        sub {$_[0]{assignments}[0]{is_state_trans} = 0},
        sub {$_[0]{assignments}[0]{operator} = '='},
        sub {$_[0]{assignments}[0]{assignment_intent}{sequencing} = 'combinational'},
    ) {
        my $entry = {%{$analysis->{next_state}}, assignments => [map {
            +{%$_, source_provenance => {%{$_->{source_provenance}}},
                assignment_intent => {%{$_->{assignment_intent}}}}
        } @{$analysis->{next_state}{assignments}}]};
        $control->($entry);
        ok(!eval {FSM::DirectDeclaredWidthSupport->prepare_module(fsm_module => $m,
            assignment_analysis => {%$analysis, next_state => $entry}, target_language => 'systemverilog'); 1},
            'malformed, foreign or mixed state-control contract refuses');
        like($@, qr/normalized SignalRef|state.control/, 'the actual reference/family check owns refusal');
    }
};
done_testing();
