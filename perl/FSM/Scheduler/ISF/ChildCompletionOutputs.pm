package FSM::Scheduler::ISF::ChildCompletionOutputs;

use v5.20;
use strict;
use warnings;
use Carp qw(confess);
use Exporter qw(import);
use FSM::Support::HDLInstanceIdentifierPolicy;

our @EXPORT_OK = qw(prepare_child_completion_outputs connect_child_completion_outputs plan_child_completion_outputs);

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
    my (%targets, %local_assignments, %local_completions);
    for my $spawn (@{$parent->{spawn_instances} || []}) {
        my $child = $children->{$spawn->{child}} || next;
        $targets{$_->{name}} = 1 for @{$child->{actor_completion_outputs} || []};
    }
    for my $name (sort keys %targets) {
        my @local = grep { $_->{lhs} eq $name }
            map { @{$_->{assignments} || []} } @{$parent->{states} || []}, @{$parent->{dt_blocks} || []};
        for my $assignment (@local) {
            confess "Actor completion output '$name' mixes generated child completion with a non-completion writer\n"
                unless ($assignment->{source_kind} // '') eq 'complete_pulse'
                    && ($assignment->{op} // '') eq '<1' && $assignment->{rhs} eq '1';
        }
        next unless @local;
        my ($output) = grep { $_->{name} eq $name } @{$parent->{ports}};
        $local_completions{$name} = {
            width => $output->{width} // 1,
            reset_value => $parent->{reset_values}{$name} // 0,
            (exists($parent->{signal_type_refs}{$name}) ? (type => $parent->{signal_type_refs}{$name}) : ()),
        };
        $local_assignments{$name} = \@local;
    }
    my $products = plan_child_completion_outputs($parent->{actor_name},
        $parent->{spawn_instances} || [], $children,
        { _reserved_names($parent) }, \%local_completions);
    push @{$parent->{ports}}, @{$products->{ports}};
    push @{$parent->{dt_blocks}}, @{$products->{dt_blocks}};
    push @{$parent->{explicit_internal_signals}}, @{$products->{explicit_internal_signals}};
    for my $field (qw(counters signal_widths signal_type_refs storage_roles reset_values)) {
        $parent->{$field}{$_} = $products->{$field}{$_} for keys %{$products->{$field}};
    }
    for my $spawn (@{$parent->{spawn_instances} || []}) {
        my $record = $products->{instances}{$spawn->{instance}} || next;
        push @{$spawn->{actor_completion_outputs}}, @{$record->{links}};
    }
    for my $name (keys %local_assignments) {
        my $pulse = $products->{outputs}{$name}{local_pulse};
        $_->{lhs} = $pulse for @{$local_assignments{$name}};
    }
    return scalar keys %{$products->{outputs}};
}

# Potential declaration planning is separate from executable writer admission.
# The caller supplies explicit local completion width/type/reset contracts;
# raw formal declarations never become an executable parent here.
sub plan_child_completion_outputs {
    my ($actor_name, $instances, $children, $input_names, $local_completions) = @_;
    my %reserved = %$input_names;
    my $products = {
        input_names => {%reserved},
        local_completions => {map { $_ => {%{$local_completions->{$_}}} } keys %$local_completions},
        ports => [], dt_blocks => [], explicit_internal_signals => [],
        counters => {}, signal_widths => {}, signal_type_refs => {},
        storage_roles => {}, reset_values => {}, instances => {}, outputs => {},
    };
    my $allocate = sub {
        return FSM::Support::HDLInstanceIdentifierPolicy->allocate_generated_instance_identifier(
            desired => $_[0], role => 'completion', reserved => \%reserved);
    };
    my %sources;
    for my $spawn (@$instances) {
        my $child = $children->{$spawn->{child}} || next;
        my @links;
        for my $output (@{$child->{actor_completion_outputs} || []}) {
            my $name = $output->{name};
            my $width = $output->{width} // 1;
            my $port = $allocate->("isf_child_completion_$spawn->{instance}_$name");
            push @{$products->{ports}}, {name => $port, direction => 'input', width => $width, isf_handoff => 1};
            $products->{counters}{$port} = $products->{signal_widths}{$port} = $width;
            $products->{signal_type_refs}{$port} = $child->{signal_type_refs}{$name}
                if exists $child->{signal_type_refs}{$name};
            $products->{storage_roles}{$port} = 'child_completion_output_handoff';
            push @links, {parent_port => $port, child_port => $name};
            push @{$sources{$name}}, $port;
        }
        $products->{instances}{$spawn->{instance}} = {
            child => $spawn->{child}, links => \@links,
        } if @links;
    }
    for my $name (sort keys %sources) {
        my $record = {identity => ['actor_completion_output', $actor_name, $name]};
        if (my $local = $local_completions->{$name}) {
            my $pulse = $allocate->("isf_local_completion_$name");
            $products->{counters}{$pulse} = $products->{signal_widths}{$pulse} = $local->{width};
            $products->{signal_type_refs}{$pulse} = $local->{type} if exists $local->{type};
            $products->{reset_values}{$pulse} = $local->{reset_value};
            $products->{storage_roles}{$pulse} = 'local_completion_pulse';
            push @{$products->{explicit_internal_signals}}, $pulse;
            $record->{local_pulse} = $pulse;
            push @{$sources{$name}}, $pulse;
        }
        my $rhs = @{$sources{$name}} == 1 ? $sources{$name}[0]
            : '(| ' . join(' ', @{$sources{$name}}) . ')';
        my $view = $allocate->("isf_completion_output_$name");
        push @{$products->{dt_blocks}}, {
            name => $view, kind => 'child_completion_output',
            assignments => [{lhs => $name, rhs => $rhs, op => '=', source_kind => 'child_completion_output_view'}],
        };
        $record->{sources} = $sources{$name};
        $record->{view_dt} = $view;
        $products->{outputs}{$name} = $record;
    }
    return $products;
}

1;
