package FSM::Scheduler::ISF::FormalIdentityPlan;

use strict;
use warnings;
use Carp qw(confess);
use FSM::Support::HDLInstanceIdentifierPolicy;

# A detached plan over source declarations. Callers must supply all additional
# physical names from their lowering context before using these allocations.
# This module does not rename operands, validate bindings or switch emission.
sub build {
    my ($class, $actor, %options) = @_;
    confess "Formal identity plan requires an actor and transactions\n"
        unless ref($actor) eq 'HASH' && _identifier($actor->{actor_name})
            && ref($actor->{transactions}) eq 'ARRAY';
    confess "Formal identity plan received an unknown option\n"
        if grep {$_ ne 'generated_children' && $_ ne 'reserved_names'} keys %options;
    for my $key (qw(generated_children reserved_names)) {
        confess "Formal identity plan requires an explicit $key hash\n"
            unless ref($options{$key}) eq 'HASH';
        confess "Formal identity plan $key contains a non-identifier\n"
            if grep {!_identifier($_)} keys %{$options{$key}};
    }

    my %transactions;
    for my $tx (@{$actor->{transactions}}) {
        confess "Formal identity plan has a transaction without a scalar identifier\n"
            unless ref($tx) eq 'HASH' && _identifier($tx->{name});
        confess "Formal identity plan has duplicate transaction '$tx->{name}'\n"
            if exists $transactions{$tx->{name}};
        $transactions{$tx->{name}} = $tx;
    }
    for my $name (keys %{$options{generated_children}}) {
        confess "Formal identity plan has unknown generated transaction '$name'\n"
            unless exists $transactions{$name};
    }

    # Reserve authored identifiers conservatively, without interpreting or
    # rewriting them. Extra reservations are harmless; omitted physical names
    # are not. The caller's complete reserved-name set remains mandatory.
    my %reserved = map {$_ => 1} keys %{$options{reserved_names}};
    _reserve_source_identifiers($actor, \%reserved);
    my (%formals, @ordered);
    for my $owner (sort keys %transactions) {
        my $ports = $transactions{$owner}{ports} // {};
        confess "Transaction '$owner' has malformed formal declarations\n"
            unless ref($ports) eq 'HASH'
                && !grep {$_ ne 'inputs' && $_ ne 'outputs'} keys %$ports;
        my %declarations;
        for my $pair (['inputs', 'input'], ['outputs', 'output']) {
            my ($plural, $direction) = @$pair;
            my $entries = $ports->{$plural} // [];
            confess "Transaction '$owner' has malformed $plural declarations\n"
                unless ref($entries) eq 'ARRAY';
            for my $declaration (@$entries) {
                confess "Transaction '$owner' has a formal without a scalar identifier\n"
                    unless ref($declaration) eq 'HASH' && _identifier($declaration->{name});
                my $name = $declaration->{name};
                confess "Transaction '$owner' has duplicate formal '$name'\n"
                    if exists $declarations{$name};
                $declarations{$name} = {direction => $direction, declaration => $declaration};
            }
        }
        $formals{$owner} = {};
        for my $name (sort keys %declarations) {
            my $declaration = $declarations{$name};
            my $generated = exists $options{generated_children}{$owner};
            my $physical = $generated ? $name
                : FSM::Support::HDLInstanceIdentifierPolicy->allocate_generated_instance_identifier(
                    desired => "isf_port_${owner}_${name}", role => 'formal', reserved => \%reserved);
            my $record = {
                identity => ['transaction_port', $actor->{actor_name}, $owner, $name],
                transaction => $owner, source_name => $name,
                direction => $declaration->{direction},
                placement => $generated ? 'generated_child_interface' : 'direct_private',
                physical_name => $physical,
                declaration => _copy($declaration->{declaration}),
            };
            $formals{$owner}{$name} = $record;
            push @ordered, $record;
        }
    }
    return {
        model => 'isf_formal_identity_plan_v1', actor_name => $actor->{actor_name},
        formals => \%formals, ordered => \@ordered,
    };
}

sub lookup {
    my ($class, $plan, $transaction, $name) = @_;
    confess "Formal identity lookup requires a plan and scalar owner/name\n"
        unless ref($plan) eq 'HASH' && ($plan->{model} // '') eq 'isf_formal_identity_plan_v1'
            && ref($plan->{formals}) eq 'HASH'
            && _identifier($transaction) && _identifier($name);
    confess "Formal identity lookup has unknown transaction '$transaction'\n"
        unless exists $plan->{formals}{$transaction}
            && ref($plan->{formals}{$transaction}) eq 'HASH';
    # Absence is meaningful: a later lexical resolver may then consider locals
    # or actor declarations. It must not search another transaction's formals.
    return _copy($plan->{formals}{$transaction}{$name});
}

sub _identifier {
    return FSM::Support::HDLInstanceIdentifierPolicy->is_simple_identifier($_[0]);
}

sub _reserve_source_identifiers {
    my ($value, $reserved) = @_;
    if (ref($value) eq 'HASH') {
        _reserve_source_identifiers($_, $reserved) for keys %$value, values %$value;
    } elsif (ref($value) eq 'ARRAY') {
        _reserve_source_identifiers($_, $reserved) for @$value;
    } elsif (!ref($value) && _identifier($value)) {
        $reserved->{$value} = 1;
    }
}

sub _copy {
    my ($value) = @_;
    return {map {$_ => _copy($value->{$_})} keys %$value} if ref($value) eq 'HASH';
    return [map {_copy($_)} @$value] if ref($value) eq 'ARRAY';
    confess "Formal declaration contains an unsupported reference\n" if ref($value);
    return $value;
}

1;
