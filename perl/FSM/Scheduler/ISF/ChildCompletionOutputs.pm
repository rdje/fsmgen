package FSM::Scheduler::ISF::ChildCompletionOutputs;

use v5.20;
use strict;
use warnings;
use Carp qw(confess);
use Exporter qw(import);
use FSM::Support::HDLInstanceIdentifierPolicy;

our @EXPORT_OK = qw(prepare_child_completion_outputs connect_child_completion_outputs);

# Authored completion outputs keep their own delayed pulses. Every completion
# also releases the generated activation through its canonical done handshake.
sub prepare_child_completion_outputs {
    my ($ir, $tx, $actor) = @_;
    my %actor_outputs = map { $_->{name} => $_ } @{$actor->{interface}{outputs} || []};
    my %local_ports = map { $_->{name} => 1 }
        map { @{($tx->{ports} || {})->{$_} || []} } qw(inputs outputs);
    my %outputs;
    for my $state (@{$ir->{states} || []}) {
        my @completion = grep { ($_->{source_kind} // '') eq 'complete_pulse' }
            @{$state->{assignments} || []};
        next unless @completion;
        for my $assignment (@completion) {
            my $name = $assignment->{lhs};
            next if $name eq 'done';
            push @{$state->{assignments}}, {
                %$assignment, lhs => 'done', source_kind => 'activation_completion_pulse',
            };
            $outputs{$name} = { %{$actor_outputs{$name}} }
                if exists($actor_outputs{$name}) && !$local_ports{$name};
        }
    }
    $ir->{actor_completion_outputs} = [map { $outputs{$_} } sort keys %outputs];
}

sub _reserved_names {
    my ($ir) = @_;
    return map { $_ => 1 } grep { defined $_ } (
        keys %{$ir->{signal_widths} || {}}, keys %{$ir->{counters} || {}},
        (map { $_->{name} } @{$ir->{ports} || []}, @{$ir->{constants} || []},
            @{$ir->{params} || []}, @{$ir->{states} || []}, @{$ir->{dt_blocks} || []}),
        $ir->{clock}, (($ir->{reset} || {})->{name} // ()),
    );
}

sub connect_child_completion_outputs {
    my ($parent, $children) = @_;
    my %reserved = _reserved_names($parent);
    my $allocate = sub {
        return FSM::Support::HDLInstanceIdentifierPolicy->allocate_generated_instance_identifier(
            desired => $_[0], role => 'completion', reserved => \%reserved);
    };
    my %sources;
    for my $spawn (@{$parent->{spawn_instances} || []}) {
        my $child = $children->{$spawn->{child}} || next;
        for my $output (@{$child->{actor_completion_outputs} || []}) {
            my $name = $output->{name};
            my $width = $output->{width} // 1;
            my $port = $allocate->("isf_child_completion_$spawn->{instance}_$name");
            push @{$parent->{ports}}, {name => $port, direction => 'input', width => $width, isf_handoff => 1};
            $parent->{counters}{$port} = $parent->{signal_widths}{$port} = $width;
            $parent->{signal_type_refs}{$port} = $child->{signal_type_refs}{$name}
                if exists $child->{signal_type_refs}{$name};
            $parent->{storage_roles}{$port} = 'child_completion_output_handoff';
            push @{$spawn->{actor_completion_outputs}}, {parent_port => $port, child_port => $name};
            push @{$sources{$name}}, $port;
        }
    }
    for my $name (sort keys %sources) {
        my @local = grep { $_->{lhs} eq $name }
            map { @{$_->{assignments} || []} } @{$parent->{states} || []}, @{$parent->{dt_blocks} || []};
        for my $assignment (@local) {
            confess "Actor completion output '$name' mixes generated child completion with a non-completion writer\n"
                unless ($assignment->{source_kind} // '') eq 'complete_pulse'
                    && ($assignment->{op} // '') eq '<1' && $assignment->{rhs} eq '1';
        }
        if (@local) {
            my ($output) = grep { $_->{name} eq $name } @{$parent->{ports}};
            my $pulse = $allocate->("isf_local_completion_$name");
            $parent->{counters}{$pulse} = $parent->{signal_widths}{$pulse} = $output->{width} // 1;
            $parent->{signal_type_refs}{$pulse} = $parent->{signal_type_refs}{$name}
                if exists $parent->{signal_type_refs}{$name};
            $parent->{reset_values}{$pulse} = $parent->{reset_values}{$name} // 0;
            $parent->{storage_roles}{$pulse} = 'local_completion_pulse';
            push @{$parent->{explicit_internal_signals}}, $pulse;
            $_->{lhs} = $pulse for @local;
            push @{$sources{$name}}, $pulse;
        }
        my $rhs = @{$sources{$name}} == 1 ? $sources{$name}[0]
            : '(| ' . join(' ', @{$sources{$name}}) . ')';
        push @{$parent->{dt_blocks}}, {
            name => $allocate->("isf_completion_output_$name"), kind => 'child_completion_output',
            assignments => [{lhs => $name, rhs => $rhs, op => '=', source_kind => 'child_completion_output_view'}],
        };
    }
    return scalar keys %sources;
}

1;
