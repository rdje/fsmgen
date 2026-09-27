package FSM::Scheduler::ISF::ChildCompletion;

use v5.20;
use strict;
use warnings;
use Exporter qw(import);
use FSM::Support::HDLInstanceIdentifierPolicy;

our @EXPORT_OK = qw(retain_child_completions);

# A generated child's done is a pulse. A join observes its entire current
# activation, including completions that arrive before the parent reaches it.
# Starts rearm the latch; live done bypasses it to preserve the join exit edge.
sub retain_child_completions {
    my ($ir) = @_;
    my %instances = map { ($_->{instance} . '_done') => $_->{instance} }
        @{$ir->{spawn_instances} || []};
    my @joins = grep { ($_->{kind} // '') =~ /\Async_(?:all|any)\z/ }
        @{$ir->{states} || []};
    my %used = map { $_ => 1 } grep { exists $instances{$_} }
        map { @{$_->{done_ports} || []} } @joins;
    return unless %used;
    my %reserved = map { $_ => 1 } grep { defined $_ } (
        keys %{$ir->{signal_widths} || {}}, keys %{$ir->{counters} || {}},
        (map { $_->{name} } @{$ir->{ports} || []}, @{$ir->{constants} || []},
            @{$ir->{params} || []}, @{$ir->{states} || []}, @{$ir->{dt_blocks} || []}),
        $ir->{clock}, (($ir->{reset} || {})->{name} // ()),
    );
    # Capture the producer's actual allocation inputs and typed ownership, so
    # source preparation need not reconstruct helper identities from spellings.
    my $products = {input_names => {%reserved}, instances => {}};
    my %views;
    for my $done (sort keys %used) {
        my $instance = $instances{$done};
        my $start = $instance . '_start';
        my ($seen, $ready) = map {
            FSM::Support::HDLInstanceIdentifierPolicy->allocate_generated_instance_identifier(
                desired => "isf_completion_${instance}_$_", role => 'completion', reserved => \%reserved,
            )
        } qw(seen ready);
        $products->{instances}{$instance} = {
            identity => ['generated_child_instance', $ir->{actor_name}, $instance],
            start_signal => $start, done_signal => $done,
            seen_signal => $seen, ready_signal => $ready,
        };
        $views{$done} = $ready;
        $ir->{counters}{$_} = $ir->{signal_widths}{$_} = 1 for ($seen, $ready);
        $ir->{reset_values}{$seen} = 0;
        $ir->{storage_roles}{$seen} = 'child_completion_seen';
        $ir->{storage_roles}{$ready} = 'child_completion_view';
        push @{$ir->{explicit_internal_signals}}, $seen, $ready;
        push @{$ir->{dt_blocks}}, {
            name => $seen, kind => 'child_completion', assignments => [
                {lhs => $seen, rhs => '0', op => '<-', guard => {port => $start}, source_kind => 'child_completion_rearm'},
                {lhs => $seen, rhs => '1', op => '<-', source_kind => 'child_completion_capture',
                    guard => {expr => "(& (! $start) $done)", expr_ast => ['&', ['!', $start], $done]}},
                {lhs => $ready, rhs => "(| $done $seen)", op => '=', source_kind => 'child_completion_view'},
            ],
        };
    }
    for my $join (@joins) {
        $join->{completion_ports} = [map { $views{$_} // $_ } @{$join->{done_ports} || []}];
        # Dynamic waits can already have materialized a sync predicate into
        # counter-load guards and transition expressions. Rewrite those same
        # operands, leaving handoff metadata and unrelated states untouched.
        for my $condition (
            (map { $_->{condition} } @{$join->{transitions} || []}),
            (map { $_->{guard} } @{$join->{assignments} || []}),
        ) {
            next unless ref($condition) eq 'HASH';
            for my $field (qw(port signal expr)) {
                next unless defined($condition->{$field}) && !ref($condition->{$field});
                $condition->{$field} = _completion_expression($condition->{$field}, \%views);
            }
            $condition->{expr_ast} = _completion_expression($condition->{expr_ast}, \%views)
                if exists $condition->{expr_ast};
        }
    }
    return $products;
}

sub _completion_expression {
    my ($value, $views) = @_;
    return [map { _completion_expression($_, $views) } @$value]
        if ref($value) eq 'ARRAY';
    return $value if !defined($value) || ref($value);
    $value =~ s/\b([A-Za-z_]\w*)\b/$views->{$1} \/\/ $1/ge;
    return $value;
}

1;
