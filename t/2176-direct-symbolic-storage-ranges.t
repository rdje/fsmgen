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
open my $fixture, '<', 't/data/ial0-direct-symbolic-storage.fsm' or die $!;
my $source = do {local $/; <$fixture>};
close $fixture or die $!;
sub parse {
    my ($text) = @_;
    return FSM::Adapter::FSMGenFull->new(debug => 0)->parse_fsm(scalar Lispish::multi(\$text));
}
sub signal_state {
    my ($s) = @_;
    return [$s->width, $s->signed, $s->state_model, $s->declared_type_spec,
        $s->declared_width_source, $s->declared_width_binding, $s->declared_width_requirements];
}
sub snapshot {
    my ($m) = @_;
    return $json->encode([$m->parameters, $m->parameter_default_sources, $m->parameter_default_bindings,
        {map {$_ => signal_state($m->signals->{$_})} sort keys %{$m->signals}}]);
}
subtest 'actual missing-module assignment target and explicit unused internal keep symbolic ranges' => sub {
    for my $value (1, 8) {
        for my $language (qw(systemverilog verilog)) {
            my $text = $source;
            $text =~ s/\(W 1\)/(W $value)/;
            my $m = parse($text);
            ok(!exists($m->signals->{DATA}), 'assignment storage really is absent from module membership');
            my $before = snapshot($m);
            my $dt = FSM::HDL::FlattenedDT->new(debug => 0);
            my $hdl = $language eq 'verilog' ? $dt->generate_verilog($m) : $dt->generate_systemverilog($m);
            like($hdl, qr/^  reg \[\(COPY - 1\):0\] DATA;$/m, 'complete storage declaration keeps actual alias and vector rank');
            like($hdl, qr/^  reg \[\(\(W \+ 1\) - 1\):0\] SPARE;$/m, 'unwritten explicit internal keeps authored arithmetic');
            like($hdl, qr/^  logic signed \[3:0\] TYPED;$/m, 'independent signed four-state named type keeps its declaration');
            like($hdl, qr/^  reg FIXED_VALUE;$/m, 'equal-default fixed scalar stays scalar');
            unlike($hdl, qr/^(?:  input|  output).*\b(?:SPARE|TYPED)\b/m, 'explicit internals do not become ports');
            is(snapshot($m), $before, 'source maps and module Signal snapshots conserve');
            is_deeply($dt->{assignment_analysis}{DATA}{lhs_ast}->signal->declared_width_binding->{expression},
                ['param', ['COPY']], 'actual assignment target preserves authored capture');
            ok(!exists($dt->{direct_declared_width_emitted_signals}), 'emitted storage plans do not survive the generation scope');
        }
    }
};
subtest 'fixed static and typed complete artifacts remain independent of parameter defaults' => sub {
    my $text = $source;
    $text =~ s/\(param COPY\)/1/g;
    $text =~ s/\(param W\)/1/g;
    my $m = parse($text);
    my $hdl = FSM::HDL::FlattenedDT->new(debug => 0)->generate_systemverilog($m);
    like($hdl, qr/^  reg DATA;$/m, 'literal storage stays scalar');
    like($hdl, qr/^  reg \[1:0\] SPARE;$/m, 'proved static arithmetic stays fixed');
    unlike($hdl, qr/\[\([^\]]*(?:W|COPY)/, 'equal numeric defaults invent no dependency');
};
subtest 'a valid same-default late replacement cannot bless old storage ancestry' => sub {
    my $m = parse($source);
    my $text = $source; $text =~ s/\(param COPY\)/(param SAME)/;
    my $replacement_module = parse($text);
    my $replacement_dt = FSM::HDL::FlattenedDT->new(debug => 0);
    $replacement_dt->generate_systemverilog($replacement_module);
    my $replacement = $replacement_dt->{assignment_analysis}{DATA}{lhs_ast};
    my $original = FSM::HDL::FlattenedDT::Backend::SystemVerilog::GenerationTailSupport->can('generate_systemverilog_tail');
    my $capture = FSM::Backend::VerilogFamily::DeclarationCapture->new;
    my $dt = FSM::HDL::FlattenedDT->new(debug => 0);
    {
        no warnings 'redefine';
        local *FSM::HDL::FlattenedDT::Backend::SystemVerilog::GenerationTailSupport::generate_systemverilog_tail = sub {
            my $hdl = $original->(@_);
            $_[0]{flattened_dt}{assignment_analysis}{DATA}{lhs_ast} = $replacement;
            return $hdl;
        };
        local $dt->{declared_width_declaration_capture} = $capture;
        ok(!eval {$dt->generate_systemverilog($m); 1}, 'late internal identity change returns no artifact');
        like($@, qr/captured.*emitted (?:storage|signal)|emitted (?:storage|signal).*captured/, 'storage identity conflict is named');
    }
    ok(!eval {$capture->snapshot; 1}, 'late failed qualification invalidates the caller collector');
};
subtest 'unsupported storage provenance cannot silently freeze selected widths' => sub {
    for my $text (
        $source =~ s/\(DATA \(param COPY\)\)/(DATA (param COPY)) (DATA 1)/r,
        $source =~ s/\(SAME 1\)/(SAME 1) (SPARE 1)/r,
    ) {
        my $m = parse($text);
        ok(!eval {FSM::HDL::FlattenedDT->new(debug => 0)->generate_systemverilog($m); 1}, 'combined or colliding internal shape refuses');
        like($@, qr/combined|collid|duplicate/, 'concrete refusal names the unsupported shape');
    }
};
done_testing();
