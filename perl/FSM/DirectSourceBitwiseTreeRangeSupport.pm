package FSM::DirectSourceBitwiseTreeRangeSupport;

use v5.20;
use strict;
use warnings;
use Carp qw(confess);
use JSON::PP ();
use Scalar::Util qw(blessed weaken);
use FSM::DirectDeclaredWidthSupport;
use FSM::SourceBitwiseTreePolicySupport;
use FSM::Support::HDLInstanceIdentifierPolicy;

sub _json {return JSON::PP->new->canonical}
sub _fail {confess "Direct source bitwise tree range $_[0]\n"}
sub _equal {return _json()->encode($_[0]) eq _json()->encode($_[1])}

sub _scope {
    my ($args) = @_;
    my $ctx = $args->{flattened_dt};
    _fail('requires an actual backend context')
        unless blessed($ctx) && $ctx->isa('FSM::HDL::FlattenedDT')
            && blessed($ctx->{fsm_module}) && $ctx->{fsm_module}->isa('FSM::CoreAST::FSMModule');
    my $owner = $ctx->{backend_sv_intermediate_width_support};
    my $recovery = $ctx->{backend_sv_intermediate_recovery_support};
    _fail('requires canonical installed width and recovery owners')
        unless ref($owner) eq 'FSM::HDL::FlattenedDT::Backend::SystemVerilog::IntermediateSignalWidthSupport'
            && $owner->{flattened_dt} && $owner->{flattened_dt} == $ctx
            && ref($recovery) eq 'FSM::HDL::FlattenedDT::Backend::SystemVerilog::IntermediateSignalRecoverySupport'
            && $recovery->{flattened_dt} && $recovery->{flattened_dt} == $ctx;
    my $language = $args->{target_language};
    _fail('currently requires a Verilog-family target')
        unless defined($language) && !ref($language) && lc($language) =~ /\A(?:systemverilog|sv|verilog|v)\z/;
    my ($name, $info) = @{$args}{qw(signal_name signal_info)};
    my $rows = $owner->_current_graph_inference_rows;
    _fail('requires actual current collected source-row membership')
        unless FSM::Support::HDLInstanceIdentifierPolicy->is_simple_identifier($name)
            && ref($info) eq 'HASH' && ref($rows) eq 'HASH'
            && ref($rows->{$name}) eq 'HASH' && $rows->{$name} == $info
            && ($info->{source} // '') eq 'fsmgen_parsing';
    return ($ctx, $owner, $recovery, $rows);
}

sub _selection {
    my ($args, $owner, $recovery) = @_;
    my ($name, $info, $expression) = @{$args}{qw(signal_name signal_info expression)};
    my $allocated = $owner->source_bitwise_tree_width_allocation($name, $info);
    my $policy = $recovery->source_bitwise_tree_width_allocation($name, $info, $expression);
    my $origin = $recovery->source_bitwise_tree_origin($name, $info, $expression);
    _fail('requires actual current completed source allocation and selected typed origin/text')
        unless $allocated && $policy && $origin && _equal($allocated, $policy)
            && FSM::SourceBitwiseTreePolicySupport->matches_origin($policy, $origin);
    return ($policy, $origin);
}

sub _original_leaves {
    my ($ctx, $policy) = @_;
    for my $name (@{$policy->{source_names}}) {
        my $signal = $ctx->{fsm_module}->signals->{$name};
        _fail("requires original module leaf '$name'; recursive source-helper proof is pending")
            unless blessed($signal) && $signal->isa('FSM::CoreAST::Signal')
                && !$signal->get_attribute('is_intermediate');
    }
}

sub prepare_declaration {
    my ($class, %args) = @_;
    my ($ctx, $owner, $recovery, $rows) = _scope(\%args);
    # The caller's prepared block owns this map. Proof must not keep an expired
    # row view alive, and returned plans contain no source/backend references.
    weaken($rows);
    my $direct = 'FSM::DirectDeclaredWidthSupport';
    my $before = $direct->_capture_source_state($ctx);
    my ($policy, $origin) = _selection(\%args, $owner, $recovery);
    _original_leaves($ctx, $policy);
    my %source_args = (fsm_module => $ctx->{fsm_module}, assignment_analysis => $ctx->{assignment_analysis},
        target_language => $args{target_language}, source_tree_width_allocation => $policy);
    my $relationship = $direct->prepare_source_tree_operand_relationship(%source_args);
    _fail('disagrees with the independently selected original-leaf maximum')
        unless FSM::SourceBitwiseTreePolicySupport->matches_selected_widths(
            $policy, $args{signal_info}{width}, @{$relationship->{operand_widths}});
    my $again = $direct->prepare_source_tree_operand_relationship(%source_args);
    my $plan = _json()->decode(_json()->encode({profile => $relationship->{profile},
        target_language => $relationship->{target_language}, source_scope => $relationship->{source_scope},
        module_name => $ctx->{fsm_module}->name, target_name => $args{signal_name}, declaration_kind => 'signal',
        allocation_role => 'source_intermediate', source_names => $policy->{source_names},
        operand_targets => $policy->{source_names}, width => $args{signal_info}{width},
        source_tree_width_allocation => $policy, source_tree_origin => $origin, expression => $args{expression},
        expression_tree => $policy->{expression_tree}, leaf_names => $relationship->{source_names},
        width_plan => $relationship->{width_plan}}));
    my ($current, $current_origin) = _selection(\%args, $owner, $recovery);
    _original_leaves($ctx, $current);
    my $after = $direct->_capture_source_state($ctx);
    _fail('complete source or current selected intent changed during declaration preparation')
        unless $before eq $after && _equal($policy, $current) && _equal($origin, $current_origin)
            && _equal($relationship, $again);
    my ($final_ctx, $final_owner, $final_recovery, $final_rows) = _scope(\%args);
    _fail('source ownership changed during declaration preparation')
        unless $final_ctx == $ctx && $final_owner == $owner && $final_recovery == $recovery
            && $rows && $final_rows == $rows;
    return $plan;
}

1;

=head1 NAME

FSM::DirectSourceBitwiseTreeRangeSupport - Prepare private actual source bitwise tree intent

=head1 DESCRIPTION

C<prepare_declaration> takes the actual C<flattened_dt> context, current
C<signal_name>/C<signal_info>, Verilog-family C<target_language> and fresh
selected C<expression>. The direct-width facade exposes the same arguments as
C<prepare_source_tree_declaration>. Only installed canonical owners and the
actual current weak collected-row view may supply completed source-tree
allocation and matching typed origin/text. A copied row, displaced owner,
foreign context, stale policy or independent floor cannot supply intent.

Every ordered original module leaf, including duplicate slots, must satisfy the
canonical plain unsigned frozen width relationship. Fixed leaves retain their
independent selected widths; mutable leaves require identical complete contracts
and preserve vector rank at default one. Exact selected maxima remain separate
from that relationship. Generated source-helper leaves currently refuse with
an explicit pending recursive-proof boundary; their names or numeric widths
cannot substitute for original leaves.

The canonical direct-width owner supplies the same complete source snapshot used
by arithmetic graph preparation. Every source declaration, captured parameter
map and normalized assignment source must remain current, even when the derived
range text is unchanged. Complete canonical relationships, current selection,
installed owners and weak row-view identity recheck at return.

The detached root plan contains profile/language/scope/module/target identity,
source allocation role, current ordered source names and operand targets,
selected width, separate source-tree policy and origin, exact selected expression,
original expression tree/leaf names and canonical range representative. It retains
no caller objects and asserts no selected-target membership or child inventory.
This private prerequisite emits no HDL, changes no live range and broadens no
VHDL, public semantic API, MCP or corpus profile. Recursive source-helper proof
and independently completed selected-target proof remain separate prerequisites.

=cut
