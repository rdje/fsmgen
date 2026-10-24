#!/usr/bin/env perl
use strict;
use warnings;
use JSON::PP;
use Digest::SHA qw(sha256_hex);
use FSM::Composition::Plan;
use FSM::Composition::SharedDatapathCandidateBuilder;
use FSM::IR::StructuralRTLIR;
use FSM::IR::StructuralRTLIR::ConnectionExpr qw(concat_expr signal_ref_expr);
use FSM::Support::NormalizedSemanticLoweredRTLIRContract qw(
    normalized_semantic_lowered_rtl_ir_composition_shared_datapath_bound_connection_expr_keys
);

# Explicit public IR inputs only: no source parsing, HDL generation or backend run.
my @cases;
for my $kind (qw(signal_ref concat)) {
    my @instances;
    my @children;
    for my $name (qw(left right)) {
        my $expression = $kind eq 'signal_ref'
            ? signal_ref_expr($name.'_bus')
            : concat_expr(signal_ref_expr($name.'_hi'), signal_ref_expr($name.'_lo'));
        push @instances, {
            kind => 'fsmc', instance_name => $name, module_name => $name.'_module',
            interface_ports => [{name => 'data', width => 8, type => 'flop', direction => 'output'}],
            port_bindings => [{port_name => 'data', connection_expr => $expression}],
        };
        push @children, {
            kind => 'fsmc', instance_name => $name, module_name => $name.'_module',
            source_name => $name.'_input',
            lowered_rtl_ir => {output_drive_families => [{
                signal_name => 'data', multiplexer_type => 'flop',
                reset_value => '0', rhs_enable_families => [],
            }]},
        };
    }
    my $plan = FSM::Composition::Plan->new(lane => 'composition', top_name => 'binding_probe');
    my $structural = FSM::IR::StructuralRTLIR->new(
        module_name => 'binding_probe', source_root_kind => 'top', instances => \@instances,
    );
    my $intent = {composition_children => \@children};
    my $candidates = FSM::Composition::SharedDatapathCandidateBuilder->build_candidates(
        composition_plan => $plan, structural_rtl_ir => $structural,
        intent_hir => $intent, target_language => 'systemverilog',
    );
    push @cases, {kind => $kind, input_instances => \@instances, input_intent => $intent,
        result => $candidates};
}

my %sources;
my @external;
for my $name (sort keys %INC) {
    my $path = $INC{$name};
    if (defined($path) && $path =~ m{\Aperl/FSM/.*[.]pm\z}) {
        open my $input, '<:raw', $path or die "Cannot read own producer $path: $!";
        my $text = do {local $/; <$input>};
        close $input or die "Cannot close own producer $path: $!";
        $sources{$path} = {text => $text, sha256 => sha256_hex($text)};
    } else {
        push @external, $name;
    }
}
print JSON::PP->new->canonical->encode({
    schema => 'fsmgen.shared_binding_probe.v1', cases => \@cases, sources => \%sources,
    advertised_keys => normalized_semantic_lowered_rtl_ir_composition_shared_datapath_bound_connection_expr_keys(),
    perl_version => "$^V", external_read_only_toolchain_modules => \@external,
    limits => 'Direct public structured-IR builder observation only; no original source/compiler/backend epoch or native source availability claim.',
}), "\n";
