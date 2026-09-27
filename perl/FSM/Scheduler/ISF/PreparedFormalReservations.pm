package FSM::Scheduler::ISF::PreparedFormalReservations;

use strict;
use warnings;
use Carp qw(confess);
use FSM::Scheduler::ISF::FormalReservationInventory;

# This is the checked input boundary, not executable-lowering admission or a
# proof about declarations produced after preparation. Keep the partial generic
# collector available to callers that intentionally inspect individual stages.
my %FIELDS = (
    (map {$_ => 'HASH'} qw(actor actor_context deferred_formal_collisions
        domain_source_products generated_child_products generated_children
        parent_activation_products parent_completion_products
        parent_named_completion_products parent_point_products parent_payload_snapshot_products
        parent_storage_read_products parent_storage_write_products
        parent_wiring_products pruned_transactions reusable_child_products
        transaction_products transactions)),
    resource_signal_products => 'ARRAY', domain_partition => 'optional_hash',
    transaction_binding_report_products => 'ARRAY',
);
my @PARENT_PRODUCTS = qw(parent_activation_products parent_completion_products
    parent_named_completion_products parent_point_products parent_payload_snapshot_products
    parent_storage_read_products parent_storage_write_products
    parent_wiring_products resource_signal_products transaction_products
    transaction_binding_report_products);

sub collect {
    my ($class, $prepared) = @_;
    # Traverse first to reject cycles and unsupported references even in fields
    # whose shape or membership is validated later.
    FSM::Scheduler::ISF::FormalReservationInventory->collect($prepared);
    my @scopes;
    _prepare_scopes($prepared, [], \@scopes);
    my $inventory = FSM::Scheduler::ISF::FormalReservationInventory->collect({
        map {$_ => $prepared->{$_}} ('actor', 'domain_partition',
            @PARENT_PRODUCTS, qw(generated_child_products reusable_child_products domain_source_products)),
    });
    return {model => 'isf_prepared_formal_reservations_v1', %$inventory, scopes => \@scopes};
}

sub _prepare_scopes {
    my ($prepared, $prefix, $scopes) = @_;
    _shape($prepared, \%FIELDS, 'preparation');
    my $actor = $prepared->{actor};
    confess "Prepared formal reservations require an actor name and transactions\n"
        unless _identifier($actor->{actor_name}) && ref($actor->{transactions}) eq 'ARRAY';
    my %transactions;
    for my $tx (@{$actor->{transactions}}) {
        confess "Prepared formal reservations have malformed or duplicate transactions\n"
            unless ref($tx) eq 'HASH' && _identifier($tx->{name}) && !$transactions{$tx->{name}}++;
    }
    for my $kind (qw(generated_children pruned_transactions)) {
        confess "Prepared formal reservations have unknown $kind membership\n"
            if grep {!exists $transactions{$_}} keys %{$prepared->{$kind}};
    }
    my %live = map {$_ => 1} grep {!$prepared->{pruned_transactions}{$_}} keys %transactions;
    _same_keys($prepared->{transactions}, \%live, 'transaction contexts');
    _same_keys($prepared->{transaction_products}, \%live, 'transaction products');
    confess "Prepared formal reservations have malformed transaction contexts\n"
        if grep {ref($_) ne 'HASH'} values %{$prepared->{transactions}};
    confess "Prepared formal reservations have malformed transaction products\n"
        if grep {ref($_) ne 'HASH'} values %{$prepared->{transaction_products}};
    _same_keys($prepared->{generated_child_products}, $prepared->{generated_children}, 'generated children');
    _shape($prepared->{reusable_child_products},
        {children => 'HASH', library_uses => 'ARRAY', atl_top_instances => 'ARRAY'}, 'reusable children');

    my $partition = $prepared->{domain_partition};
    confess "Prepared formal reservations have an unknown domain partition kind\n"
        if $partition && ($partition->{kind} // '') !~ /\A(?:single_domain|multi_domain)\z/;
    my $source_domains = $actor->{clock_domains};
    my %source_domain_names = map {$_->{name} => 1}
        @{ref($source_domains) eq 'HASH' ? ($source_domains->{domains} || []) : []};
    confess "Prepared formal reservations are missing the source domain partition\n"
        if %source_domain_names && !$partition;
    if ($partition) {
        confess "Prepared formal reservations have malformed domain partition\n"
            unless ref($partition->{domains}) eq 'ARRAY';
        my %partition_names;
        for my $domain (@{$partition->{domains}}) {
            confess "Prepared formal reservations have malformed or duplicate domains\n"
                unless ref($domain) eq 'HASH' && _identifier($domain->{name}) && !$partition_names{$domain->{name}}++;
        }
        _same_keys(\%partition_names, \%source_domain_names, 'source domain membership');
        my $kind = keys(%source_domain_names) > 1 ? 'multi_domain' : 'single_domain';
        confess "Prepared formal reservations have mismatched domain partition kind\n"
            unless %source_domain_names && $partition->{kind} eq $kind;
    }
    my %domains;
    if ($partition && ($partition->{kind} // '') eq 'multi_domain') {
        confess "Prepared formal reservations have malformed domain partition\n"
            unless ref($partition->{domains}) eq 'ARRAY' && @{$partition->{domains}};
        for my $domain (@{$partition->{domains}}) {
            confess "Prepared formal reservations have malformed or duplicate domains\n"
                unless ref($domain) eq 'HASH' && _identifier($domain->{name}) && !$domains{$domain->{name}}++;
        }
    }
    _same_keys($prepared->{domain_source_products}, \%domains, 'domain products');
    if (%domains) {
        confess "Prepared formal reservations cannot nest domain partitions\n" if @$prefix;
        for my $name (sort keys %domains) {
            my $domain = $prepared->{domain_source_products}{$name};
            _shape($domain, {identity => 'ARRAY', domain => 'HASH', preparation => 'HASH'}, 'domain product');
            _shape($domain->{preparation}, \%FIELDS, 'preparation');
            my @identity = ('actor_domain', $actor->{actor_name}, $name);
            confess "Prepared formal reservations have mismatched domain identity\n"
                unless _same_identity($domain->{identity}, \@identity)
                    && ($domain->{domain}{name} // '') eq $name
                    && ($domain->{preparation}{actor}{_scheduled_domain_name} // '') eq $name;
            _prepare_scopes($domain->{preparation}, \@identity, $scopes);
        }
        return;
    }

    my @identity = @$prefix ? @$prefix : ('actor_module', $actor->{actor_name});
    my $parent = FSM::Scheduler::ISF::FormalReservationInventory->collect({
        map {$_ => $prepared->{$_}} ('actor', @PARENT_PRODUCTS),
    });
    push @$scopes, {identity => [@identity, 'parent'], %$parent};
    my %children = %{$prepared->{generated_child_products}};
    for my $name (sort keys %{$prepared->{reusable_child_products}{children}}) {
        confess "Prepared formal reservations have duplicate child scope '$name'\n" if exists $children{$name};
        $children{$name} = $prepared->{reusable_child_products}{children}{$name};
    }
    for my $name (sort keys %children) {
        confess "Prepared formal reservations have malformed child scope '$name'\n"
            unless _identifier($name) && ref($children{$name}) eq 'HASH'
                && _identifier($children{$name}{actor_name});
        my $child = FSM::Scheduler::ISF::FormalReservationInventory->collect({child => $children{$name}});
        push @$scopes, {identity => [@identity, 'child', $name], %$child};
    }
}

sub _shape {
    my ($value, $fields, $where) = @_;
    confess "Prepared formal reservations require a $where hash\n" unless ref($value) eq 'HASH';
    _same_keys($value, $fields, $where);
    for my $name (sort keys %$fields) {
        my $type = $fields->{$name};
        next if $type eq 'optional_hash' && !defined($value->{$name});
        $type = 'HASH' if $type eq 'optional_hash';
        confess "Prepared formal reservations have malformed $where field '$name'\n"
            unless ref($value->{$name}) eq $type;
    }
}

sub _same_keys {
    my ($actual, $expected, $where) = @_;
    my @missing = sort grep {!exists $actual->{$_}} keys %$expected;
    my @extra = sort grep {!exists $expected->{$_}} keys %$actual;
    confess "Prepared formal reservations have incomplete $where (missing: "
        . join(', ', @missing) . '; unexpected: ' . join(', ', @extra) . ")\n"
        if @missing || @extra;
}

sub _identifier {defined($_[0]) && !ref($_[0]) && $_[0] =~ /\A[A-Za-z_][A-Za-z0-9_]*\z/}
sub _same_identity {
    my ($left, $right) = @_;
    return 0 unless @$left == @$right;
    for my $i (0 .. $#$right) {return 0 if ref($left->[$i]) || !defined($left->[$i]) || $left->[$i] ne $right->[$i]}
    return 1;
}

1;
