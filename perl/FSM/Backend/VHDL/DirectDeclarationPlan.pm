package FSM::Backend::VHDL::DirectDeclarationPlan;

use v5.20;
use strict;
use warnings;
use Carp qw(confess);
use feature qw(signatures);
no warnings 'experimental::signatures';
use JSON::PP ();
use FSM::DirectDeclaredWidthSupport;
use FSM::Backend::VHDL::DirectParameterEmitter;

sub prepare ($class, %args) {
    my $json = JSON::PP->new->canonical;
    my $inputs = eval {$json->decode($json->encode({
        capture => $args{declaration_capture}, mapping => $args{identifier_map}}))};
    confess "Direct VHDL declaration plan requires JSON-safe capture and mapping: $@" if $@;
    my ($capture, $mapping) = @{$inputs}{qw(capture mapping)};
    confess "Direct VHDL declaration plan requires a complete declaration capture\n"
        unless ref($capture) eq 'HASH' && ref($capture->{target_namespace}) eq 'HASH'
            && ref($capture->{target_declarations}) eq 'HASH';
    confess "Direct VHDL declaration plan requires an explicit identifier mapping\n"
        unless ref($mapping) eq 'HASH';
    my $source_namespace = $capture->{target_namespace};
    confess "Direct VHDL declaration plan requires an unmapped source capture\n"
        unless ref($source_namespace->{identifier_map}) eq 'HASH'
            && !keys(%{$source_namespace->{identifier_map}});
    my %source_args = (fsm_module => $args{fsm_module}, assignment_analysis => $args{assignment_analysis});
    my $source = FSM::DirectDeclaredWidthSupport->prepare_declarations(
        %source_args, target_namespace => $source_namespace,
        target_declarations => $capture->{target_declarations}, target_language => 'systemverilog');

    # Map actual emitted names, never the captured lexical scope or width roots.
    # Both complete namespaces pass the same canonical declaration proof.
    my %target_namespace = (identifier_map => $mapping,
        module_name => $mapping->{$source_namespace->{module_name}} // $source_namespace->{module_name});
    for my $role (qw(parameter_names ports signals constants types)) {
        $target_namespace{$role} = [map {$mapping->{$_} // $_} @{$source_namespace->{$role}}];
    }
    my %target_declarations;
    for my $name (sort keys %{$capture->{target_declarations}}) {
        my $target = $mapping->{$name} // $name;
        confess "Direct VHDL declaration mapping requires scalar target names\n" if ref($target);
        confess "Direct VHDL declaration mapping has duplicate target '$target'\n"
            if exists($target_declarations{$target});
        $target_declarations{$target} = {%{$capture->{target_declarations}{$name}}, name => $target};
    }
    my %target_args = (%source_args, target_namespace => \%target_namespace,
        target_declarations => \%target_declarations, target_language => 'vhdl');
    my $target = FSM::DirectDeclaredWidthSupport->prepare_declarations(%target_args);
    my $generics = FSM::Backend::VHDL::DirectParameterEmitter->lower_declarations(%target_args);
    my %ranges;
    for my $name (sort keys %{$source->{ranges}}) {
        my $target_name = $mapping->{$name} // $name;
        my $from = $source->{ranges}{$name};
        my $to = $target->{ranges}{$target_name};
        confess "Direct VHDL declaration mapping changes symbolic source membership\n"
            unless ref($to) eq 'HASH' && $from->{source_name} eq $to->{source_name}
                && $from->{declaration_kind} eq $to->{declaration_kind};
        my $record = $target_declarations{$target_name};
        my $range = $to->{width_plan}{range_text};
        $ranges{$target_name} = {source_name => $name, declaration_kind => $to->{declaration_kind},
            width => $record->{width}, signed => $record->{signed}, is_vector => 1,
            source_range => $from->{width_plan}{range_text}, target_range => $range,
            target_type => ($record->{signed} ? 'signed' : 'std_logic_vector') . $range};
    }
    confess "Direct VHDL declaration mapping changes symbolic target membership\n"
        unless keys(%ranges) == keys(%{$target->{ranges}});
    return $json->decode($json->encode({profile => $target->{profile}, source_scope => $target->{source_scope},
        target_namespace => \%target_namespace, target_declarations => \%target_declarations,
        generic_plan => $generics, ranges => \%ranges}));
}

1;

=head1 NAME

FSM::Backend::VHDL::DirectDeclarationPlan - Pair actual direct source and VHDL declaration profiles

=head1 DESCRIPTION

C<prepare> consumes an actual Core C<fsm_module>, complete backend
C<assignment_analysis>, a completed emitter C<declaration_capture> snapshot and
an explicit C<identifier_map> from the converter's generated-name normalizer.
The source capture is unmapped and contains complete C<target_namespace> and
C<target_declarations> records. Caller-made captures remain a contract, not an
attestation of emitted HDL provenance.

Canonical direct width preparation proves the original SystemVerilog profile
and the complete mapped VHDL profile independently against the same actual
Signal objects. Original lexical scope is never normalized. Width roots cannot
rename. Complete source and target membership, namespace, numeric width,
signedness and declared type checks precede paired range preparation. The same
target records select natural generic declarations through
C<DirectParameterEmitter>, including captured width-only consumers.

The detached result contains C<profile>, C<source_scope>, mapped
C<target_namespace>, complete selected numeric/type C<target_declarations>,
C<generic_plan> and C<ranges> keyed by target name. Each symbolic row contains
its original emitted C<source_name>, C<declaration_kind>, numeric C<width> and
C<signed>, C<is_vector>, exact canonical C<source_range> spelling (including its
trailing separator), and separate canonical C<target_range> and C<target_type>.
A selected default of one retains vector rank. Fixed/static/type declarations
retain numeric metadata without acquiring a symbolic range.

Missing, stale, foreign, inconsistent, duplicate, conflicting or unsupported
captures and mappings refuse before any result. Inputs are read-only and no
Core, Signal, backend or caller graph is retained. The private VHDL declaration
parser now consumes this result and checks generated text membership and exact
source ranges. The direct source-aware converter consumes it for bounded
combinational and bounded unsigned register-helper declarations/transfers/zero
resets. A separate actual-event guard qualifies scalar whole unsigned reduction
intermediates before paired conversion. Other unproved auxiliary/pulse/intermediate
shapes and no-transition symbolic
FSMs refuse. Raw-text symbolic conversion and public
reports remain unchanged; external compiler, override and
runtime qualification remains pending.

=cut
