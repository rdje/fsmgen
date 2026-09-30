package FSM::Scheduler::ISF::RecordSamples;

use strict;
use warnings;
use Carp qw(confess);
use Storable qw(dclone);
use FSM::Support::ISFRecordPortSamples qw(actor_has_record_input record_transaction_samples record_sample_type_products);

# Consume finalized record-input facts through the existing transaction products.
# Private sample types and ownership do not change the transaction product ABI.
sub transaction_plan {
    my ($class, $actor, $transaction) = @_;
    return undef unless actor_has_record_input(actor => $actor);
    return record_transaction_samples(actor => $actor, transaction => $transaction, port_only => 1);
}

sub declare_transaction_aliases {
    my ($class, $plan, $counters, $roles, $widths, $transaction) = @_;
    return unless $plan;
    for my $alias (sort keys %{$plan->{record_aliases}}) {
        confess "Transaction '$transaction': record-derived sample alias '$alias' collides with a generated declaration\n"
            if exists $counters->{$alias};
        my $width = $plan->{bindings}{$alias}{type_spec}{width};
        $counters->{$alias} = $width;
        $widths->{$alias} = $width;
        $roles->{$alias} = 'sample_alias';
    }
}

# Run after real module helpers have been built. The same alias cannot borrow
# their roles, widths, reset/default metadata or a different physical owner.
sub apply_to_module {
    my ($class, $ir, $actor, $transactions) = @_;
    return unless actor_has_record_input(actor => $actor);
    my (%bindings, %record_aliases, %owners, %sample_owners);
    for my $transaction (@$transactions) {
        my $plan = $class->transaction_plan($actor, $transaction);
        for my $sample (@{$plan->{samples}}) {
            $sample_owners{$sample->{alias}}{$transaction->{name}} = 1;
        }
        for my $alias (keys %{$plan->{record_aliases}}) {
            confess "Module '$ir->{actor_name}': record-derived sample alias '$alias' has multiple transaction owners\n"
                if exists($owners{$alias}) && $owners{$alias} ne $transaction->{name};
            $owners{$alias} = $transaction->{name};
            $record_aliases{$alias} = 1;
            $bindings{$alias} = dclone($plan->{bindings}{$alias});
        }
    }
    return unless keys %record_aliases;
    my %ports = map {$_->{name} => 1} @{$ir->{ports} || []};
    for my $alias (sort keys %record_aliases) {
        my $label = "Module '$ir->{actor_name}': record-derived sample alias '$alias'";
        confess "$label has multiple sample owners\n" if keys(%{$sample_owners{$alias}}) != 1;
        confess "$label collides with a module port\n" if $ports{$alias};
        confess "$label collides with a generated storage role\n"
            unless ($ir->{storage_roles}{$alias} // '') eq 'sample_alias';
        confess "$label has an inconsistent declared width\n"
            unless exists($ir->{counters}{$alias})
                && $ir->{counters}{$alias} == $bindings{$alias}{type_spec}{width};
        confess "$label cannot inherit reset/default metadata\n"
            if exists(($ir->{reset_values} || {})->{$alias})
                || exists(($ir->{output_defaults} || {})->{$alias});
        confess "$label already has a type reference\n" if exists $ir->{signal_type_refs}{$alias};
        for my $state (@{$ir->{states} || []}) {
            for my $assignment (@{$state->{assignments} || []}) {
                next unless _target_root($assignment->{lhs}) eq $alias;
                confess "$label has a different state writer\n"
                    unless ($state->{transaction} // '') eq $owners{$alias};
            }
        }
        for my $dt (@{$ir->{dt_blocks} || []}) {
            for my $assignment (@{$dt->{assignments} || []}) {
                confess "$label has a decision-tree writer\n" if _target_root($assignment->{lhs}) eq $alias;
            }
        }
    }
    my @reserved = map {$_->[1]} @{$ir->{type_declarations} || []};
    my $products = record_sample_type_products(bindings => \%bindings,
        record_aliases => \%record_aliases, reserved_names => \@reserved);
    push @{$ir->{type_declarations}}, @{$products->{type_declarations}};
    my %internal = map {$_ => 1} @{$ir->{explicit_internal_signals} || []};
    for my $alias (keys %record_aliases) {
        $ir->{signal_type_refs}{$alias} = $products->{signal_type_refs}{$alias};
    }
    push @{$ir->{explicit_internal_signals}}, grep {!$internal{$_}} sort keys %record_aliases;
    return;
}

sub _target_root {
    my ($target) = @_;
    my ($root) = defined($target) && !ref($target) ? $target =~ /\A([A-Za-z_]\w*)/ : ();
    return $root // '';
}

1;
