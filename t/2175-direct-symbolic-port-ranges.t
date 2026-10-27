use strict;
use warnings;
use lib 'perl';
use Test::More;
use JSON::PP;
use Lispish;
use FSM::Adapter::FSMGenFull;
use FSM::HDL::FlattenedDT;
use FSM::Backend::VerilogFamily::DeclarationCapture;

my $json = JSON::PP->new->canonical;
sub text {
    my ($value, $data, $input) = @_;
    $data //= '(param COPY)'; $input //= '(param W)';
    return "(?fsm:direct_symbolic_ports (+params (W $value) (COPY W) (SAME $value))"
        ." (+size (DATA $data) (INPUT_PORT $input) (FIXED $value) (FIXED_VALUE $value))"
        .' (idle (<-= (DATA INPUT_PORT)) (= (FIXED_VALUE FIXED))))';
}
sub parse {my ($text) = @_; return FSM::Adapter::FSMGenFull->new(debug => 0)->parse_fsm(scalar Lispish::multi(\$text))}
sub captures {
    my ($m) = @_;
    return $json->encode([$m->parameters, $m->parameter_default_sources, $m->parameter_default_bindings,
        {map {$_ => [$m->signals->{$_}->declared_width_source, $m->signals->{$_}->declared_width_binding,
            $m->signals->{$_}->declared_width_requirements]} sort keys %{$m->signals}}]);
}
subtest 'actual input/output ports keep selected names and one-bit vector rank across Verilog family' => sub {
    for my $value (1, 8) {
        for my $language ('systemverilog', 'verilog') {
            my $m = parse(text($value)); my $before = captures($m);
            my $dt = FSM::HDL::FlattenedDT->new(debug => 0);
            my $hdl = $language eq 'verilog' ? $dt->generate_verilog($m) : $dt->generate_systemverilog($m);
            my ($header) = $hdl =~ /(module direct_symbolic_ports.*?\n\);)/s;
            my $fixed = $value > 1 ? '[7:0] ' : '';
            is($header, "module direct_symbolic_ports #(\n  parameter SAME = $value,\n  parameter W = $value,\n  parameter COPY = W\n) (\n"
                ."  input  wire clk,\n  input  wire rst_n,\n  input  wire ${fixed}FIXED,\n"
                ."  input  wire [(W - 1):0] INPUT_PORT,\n  output reg  [(COPY - 1):0] next_DATA\n);",
                'whole independently expected header retains actual parameter identities and fixed control');
            is(captures($m), $before, 'source/default/actual Signal capture JSON kinds remain unchanged');
            ok(!exists($dt->{direct_declared_width_source_plan}) && !exists($dt->{declared_width_declaration_capture}) && !exists($dt->{direct_declared_width_emitted_ports}), 'per-run private preparation is scoped');
            like($hdl, $language eq 'verilog' ? qr/always @\*/ : qr/always_comb/, 'existing compatibility procedural policy preserves');
        }
    }
};
subtest 'arithmetic zero default and independent fixed/type identities are preserved' => sub {
    my $m = parse(text(0, '(+ (param COPY) 1)', '(+ (param W) 1)') =~ s/\(FIXED 0\) \(FIXED_VALUE 0\)/(FIXED 1) (FIXED_VALUE 1)/r);
    my $hdl = FSM::HDL::FlattenedDT->new(debug => 0)->generate_systemverilog($m);
    like($hdl, qr/input  wire \[\(\(W \+ 1\) - 1\):0\] INPUT_PORT/, 'arithmetic retains selected zero-valued root');
    like($hdl, qr/output reg  \[\(\(COPY \+ 1\) - 1\):0\] next_DATA/, 'arithmetic keeps selected alias with default zero');
    $m = parse(text(8, '8', '8'));
    $hdl = FSM::HDL::FlattenedDT->new(debug => 0)->generate_systemverilog($m);
    like($hdl, qr/input  wire \[7:0\] INPUT_PORT/, 'equal-default literal input stays fixed');
    unlike($hdl, qr/\[\([^\]]*(?:W|COPY)/, 'literal widths infer no mutable ancestry');
    my $typed = '(?fsm:typed_ports (+types (type W (bits 4))) (+constants (W 8)) (+params (W 16))'
        .' (+size (DATA W) (INPUT_PORT W)) (idle (<-= (DATA INPUT_PORT))))';
    $m = parse($typed); $hdl = FSM::HDL::FlattenedDT->new(debug => 0)->generate_systemverilog($m);
    like($hdl, qr/input  wire \[3:0\] INPUT_PORT/, 'named type retains independent precedence');
    unlike($hdl, qr/\[\(W - 1\)/, 'same-name parameter supplies no type ancestry');
};
subtest 'combined stale target collisions and symbolic system widths refuse before artifact success' => sub {
    for my $source (
        text(8) =~ s/\(DATA \(param COPY\)\)/(DATA (param COPY)) (next_DATA 8)/r,
        text(1) =~ s/\(SAME 1\)/(SAME 1) (IDLE 1)/r,
        text(1) =~ s/INPUT_PORT/clk/gr,
    ) {
        my $m = parse($source);
        my $hdl = eval {FSM::HDL::FlattenedDT->new(debug => 0)->generate_systemverilog($m)};
        ok(!defined($hdl), 'unsupported or conflicting actual shape returns no artifact');
        like($@, qr/combined|duplicate|collid|symbolic system/, 'concrete declaration refusal is visible');
    }
    my $m = parse(text(8)); $m->signals->{INPUT_PORT}->clear_declared_width_binding;
    ok(!eval {FSM::HDL::FlattenedDT->new(debug => 0)->generate_systemverilog($m); 1}, 'missing actual captured binding cannot freeze');
    like($@, qr/coherent width binding/, 'missing coherence is explicit');
    $m = parse(text(1));
    ok(!eval {FSM::HDL::FlattenedDT->new(debug => 0)->generate_vhdl($m); 1}, 'symbolic VHDL ports remain refused before source-aware conversion');
    like($@, qr/Unsupported generated SystemVerilog shape/, 'existing bounded direct conversion refusal is preserved');
};
subtest 'a valid same-default source replacement after emission cannot rewrite port ancestry' => sub {
    my $m = parse(text(8)); my $replacement = parse(text(8, undef, '(param SAME)'))->signals->{INPUT_PORT};
    my $original = FSM::HDL::FlattenedDT::Backend::SystemVerilog::GenerationTailSupport->can('generate_systemverilog_tail');
    my $capture = FSM::Backend::VerilogFamily::DeclarationCapture->new;
    my $dt = FSM::HDL::FlattenedDT->new(debug => 0);
    {
        no warnings 'redefine';
        local *FSM::HDL::FlattenedDT::Backend::SystemVerilog::GenerationTailSupport::generate_systemverilog_tail = sub {
            my $hdl = $original->(@_); $_[1]->signals->{INPUT_PORT} = $replacement; return $hdl;
        };
        local $dt->{declared_width_declaration_capture} = $capture;
        ok(!eval {$dt->generate_systemverilog($m); 1}, 'same-default valid replacement cannot bless already emitted old identity');
        like($@, qr/emitted port.*captured|captured.*emitted port/, 'late identity conflict is named');
    }
    ok(!eval {$capture->snapshot; 1}, 'failed final qualification invalidates caller collector');
};
done_testing();
