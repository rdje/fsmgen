package FSM::HDL::FlattenedDT::Backend::SystemVerilog::PostFlatteningAssemblySupport;

=head1 NAME

FSM::HDL::FlattenedDT::Backend::SystemVerilog::PostFlatteningAssemblySupport - Own live post-flattening direct SystemVerilog assembly

=head1 DESCRIPTION

Owns the bounded live post-flattening module-assembly family for the older
direct generated-module SystemVerilog backend path. This package centralizes:

=over 4

=item *

full direct SystemVerilog module assembly after decision-tree flattening

=item *

composition of scaffold emission, internal declaration emission,
enable-condition emission, the prescan-aware consolidated intermediate stage,
and post-stage tail closeout

=item *

the deliberate pre-declaration preparation of the consolidated intermediate
stage, so helper/intermediate signals discovered by prescan and factorization
are known before internal declarations are emitted

=back

The paired C<FSM::HDL::FlattenedDT::Orchestrator> now owns per-run reset,
FSM-module attachment, decision-tree flattening, and the final handoff to this
owner. The older
C<FSM::HDL::FlattenedDT::Backend::SystemVerilog::GenerationPipelineSupport>
package survives only as a directly testable compatibility shell over this
live owner.

=cut

use v5.20;
use strict;
use warnings;
use feature qw(signatures);
no warnings 'experimental::signatures';

use FSM::Debug;
use Carp qw(confess);
use JSON::PP ();
use Scalar::Util qw(blessed);
use FSM::DirectDeclaredWidthSupport;
use FSM::Backend::VerilogFamily::DeclarationCapture;

use constant STRUCTURAL_RTLIR_ENABLE_ASSIGNMENTS_BEGIN_MARKER =>
    'FSMGEN_STRUCTURAL_RTLIR_ENABLE_ASSIGNMENTS_BEGIN';
use constant STRUCTURAL_RTLIR_ENABLE_ASSIGNMENTS_END_MARKER =>
    'FSMGEN_STRUCTURAL_RTLIR_ENABLE_ASSIGNMENTS_END';

=head2 new

Construct one post-flattening SystemVerilog assembly owner bound to a specific
C<FSM::HDL::FlattenedDT> backend context.

=cut

sub new ($class, %args) {
    my $flattened_dt = $args{flattened_dt}
      or die "[PostFlatteningAssemblySupport.pm][new()] Missing required 'flattened_dt' argument";

    return bless {
        flattened_dt => $flattened_dt,
    }, $class;
}

=head2 generate_systemverilog_module

Generate the full direct SystemVerilog module after decision-tree flattening.
The live stage prepares and validates once, source ranges are proved, then that
block renders once before scaffold emission. Combined-only injected stage
providers retain their existing ordering and contract.
Symbolic binary helper declarations retain their actual source/allocation proof
in a per-generation ledger. Complete captured target events are independently
reproved against current source and backend state, then compared with the full
emitted records, including range, expression, ordered operands and helper role.

=cut

sub generate_systemverilog_module ($self, $fsm_module) {
    my $ctx = $self->{flattened_dt};
    my $prepare_widths = _needs_declared_width_preparation($ctx, $fsm_module);
    my $capture = $ctx->{declared_width_declaration_capture}
        // ($prepare_widths ? FSM::Backend::VerilogFamily::DeclarationCapture->new : undef);
    local $ctx->{declared_width_declaration_capture} = $capture;
    local $ctx->{direct_declared_width_source_plan};
    local $ctx->{direct_declared_width_emitted_ports} = {};
    local $ctx->{direct_declared_width_emitted_signals} = {};
    local $ctx->{direct_declared_width_emitted_helper_origins} = {};
    local $ctx->{direct_declared_width_emitted_binary_ranges} = {};
    $capture->begin_module($fsm_module->name) if $capture;
    my $stage = $ctx->{backend_sv_consolidated_intermediate_stage_support};
    my $split_stage = $stage->can('prepare_consolidated_intermediate_block')
        && $stage->can('render_prepared_consolidated_intermediate_block');
    my ($prepared_block, $consolidated_intermediate_hdl);
    if ($split_stage) {
        $prepared_block = $stage->prepare_consolidated_intermediate_block($fsm_module);
    } else {
        # Older injected providers expose only the combined stage contract.
        $consolidated_intermediate_hdl = $self->prepare_consolidated_intermediate_stage($fsm_module);
    }
    if ($prepare_widths) {
        $ctx->{direct_declared_width_source_plan} = FSM::DirectDeclaredWidthSupport->prepare_module(
            fsm_module => $fsm_module, assignment_analysis => $ctx->{assignment_analysis},
            target_language => 'systemverilog');
    }
    $consolidated_intermediate_hdl = $stage->render_prepared_consolidated_intermediate_block($prepared_block)
        if $split_stage;

    my $hdl = $ctx->{backend_sv_scaffold}->generate_header($fsm_module);
    $hdl .= $ctx->{backend_sv_scaffold}->generate_module_declaration($fsm_module);
    $hdl .= $ctx->{backend_sv_scaffold}->generate_state_encoding($fsm_module);
    $hdl .= $ctx->{backend_sv_scaffold}->generate_state_register($fsm_module);
    $hdl .= $ctx->{backend_sv_internal_decl}->generate_internal_signal_declarations($fsm_module);
    fsm_debug("Step 2 - Basic HDL structure generated", 3);
    my $enable_conditions = $ctx->{enable_graph_enable_support}->generate_enable_conditions($fsm_module);
    $hdl .= $ctx->{structural_rtlir_enable_assignment_markers}
        ? $self->marked_structural_rtlir_enable_assignment_block($enable_conditions)
        : $enable_conditions;
    fsm_debug("Step 3 - Enable conditions generated", 3);

    $hdl .= $consolidated_intermediate_hdl;
    fsm_debug("Step 6 - Consolidated intermediate signals generated", 3);

    $hdl .= $ctx->{backend_sv_generation_tail_support}
        ->generate_systemverilog_tail($fsm_module);

    $capture->complete if $capture;
    if ($prepare_widths) {
        my $ok = eval {
            my $snapshot = $capture->snapshot;
            my $qualified = FSM::DirectDeclaredWidthSupport->prepare_declarations(
                fsm_module => $fsm_module, assignment_analysis => $ctx->{assignment_analysis},
                target_language => 'systemverilog', %$snapshot);
            my %expected = map {$_ => $qualified->{ranges}{$_}{width_plan}}
                grep {$qualified->{ranges}{$_}{declaration_kind} eq 'port'} keys %{$qualified->{ranges}};
            my $json = JSON::PP->new->canonical;
            confess "Direct captured widths do not match the actual emitted port identities\n"
                unless $json->encode(\%expected) eq $json->encode($ctx->{direct_declared_width_emitted_ports});
            my %expected_signals = map {$_ => $qualified->{ranges}{$_}{width_plan}}
                grep {$qualified->{ranges}{$_}{declaration_kind} eq 'signal'} keys %{$qualified->{ranges}};
            confess "Direct captured widths do not match the actual emitted storage identities\n"
                unless $json->encode(\%expected_signals) eq $json->encode($ctx->{direct_declared_width_emitted_signals});
            my %expected_origins = map {$_ => $snapshot->{target_declarations}{$_}{width_origin}}
                grep {exists($snapshot->{target_declarations}{$_}{width_origin})} keys %{$snapshot->{target_declarations}};
            confess "Direct captured auxiliary origins do not match the actual emitted helper identities\n"
                unless $json->encode(\%expected_origins) eq $json->encode($ctx->{direct_declared_width_emitted_helper_origins});
            my %expected_binary;
            for my $name (sort keys %{$snapshot->{target_intermediates} || {}}) {
                my $event = $snapshot->{target_intermediates}{$name};
                next unless $event->{width_allocation};
                # Arithmetic events publish allocation only; their range consumer
                # has not yet joined the complete source and target proof.
                next unless $event->{bitwise_origin};
                my $has_symbolic_operand = grep {
                    exists($qualified->{ranges}{$_});
                } @{$event->{width_allocation}{source_names}};
                next unless $has_symbolic_operand;
                $expected_binary{$name} = FSM::DirectDeclaredWidthSupport->prepare_binary_intermediate_range(
                    flattened_dt => $ctx, signal_name => $name,
                    signal_info => $prepared_block->{filtered_signals}{$name},
                    target_language => 'systemverilog', %$snapshot);
            }
            confess "Direct captured binary ranges do not match the actual emitted intermediate identities\n"
                unless $json->encode(\%expected_binary) eq $json->encode($ctx->{direct_declared_width_emitted_binary_ranges});
            1;
        };
        unless ($ok) {
            my $error = $@;
            $capture->invalidate;
            die $error;
        }
    }
    return $hdl;
}

sub _needs_declared_width_preparation ($ctx, $module) {
    return 0 unless blessed($module) && $module->isa('FSM::CoreAST::FSMModule');
    for my $map ($module->parameter_default_sources, $module->parameter_default_bindings) {
        return 1 if ref($map) eq 'HASH' && keys %$map;
    }
    my @signals = values %{$module->signals || {}};
    for my $lhs (values %{$ctx->{lhs_ast_map} || {}}) {
        push @signals, $lhs->signal if blessed($lhs) && $lhs->can('signal');
    }
    for my $signal (@signals) {
        next unless blessed($signal) && $signal->can('declared_width_binding');
        my $binding = $signal->declared_width_binding;
        return 1 if $binding && grep {$_->{kind} eq 'parameter'} @{$binding->{observations}};
        my $requirements = $signal->declared_width_requirements;
        if ($requirements) {
            for my $entry (@{$requirements->{requirements}}) {
                my $capture = $entry->{width_capture};
                return 1 if $capture && grep {$_->{kind} eq 'parameter'} @{$capture->{observations}};
            }
        }
        # A revoked source may have lost both current private getters. Declared
        # parameters plus authored width source still require proof, not fallback.
        return 1 if keys(%{$module->parameters}) && defined($signal->declared_width_source);
    }
    return 0;
}

=head2 prepare_consolidated_intermediate_stage

Prepare and render the consolidated intermediate stage before declarations are
emitted. This ordering is intentional: the stage owner runs the direct backend
prescan/factorization side effects that discover helper wires, and the internal
declaration owner must see those helpers before it emits the declaration block.

=cut

sub prepare_consolidated_intermediate_stage ($self, $fsm_module) {
    my $ctx = $self->{flattened_dt};

    return $ctx->{backend_sv_consolidated_intermediate_stage_support}
        ->generate_consolidated_intermediate_block($fsm_module);
}

sub marked_structural_rtlir_enable_assignment_block ($self, $enable_conditions) {
    return ''
        . '  // ' . STRUCTURAL_RTLIR_ENABLE_ASSIGNMENTS_BEGIN_MARKER . "\n"
        . ($enable_conditions // '')
        . '  // ' . STRUCTURAL_RTLIR_ENABLE_ASSIGNMENTS_END_MARKER . "\n";
}

sub structural_rtlir_enable_assignments_begin_marker ($class) {
    return STRUCTURAL_RTLIR_ENABLE_ASSIGNMENTS_BEGIN_MARKER;
}

sub structural_rtlir_enable_assignments_end_marker ($class) {
    return STRUCTURAL_RTLIR_ENABLE_ASSIGNMENTS_END_MARKER;
}

1;

__END__

=head1 METHODS

=head2 new

Constructs one post-flattening SystemVerilog assembly owner bound to a specific
C<FSM::HDL::FlattenedDT> backend context.

=head2 generate_systemverilog_module

Generates the full direct SystemVerilog module after decision-tree flattening.

=head2 prepare_consolidated_intermediate_stage

Runs the prescan-aware consolidated intermediate stage before declaration
emission so declaration planning sees stage-discovered helpers.

=cut
