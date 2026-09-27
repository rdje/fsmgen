package FSM::Scheduler::ISF::FormalReservationCoverage;

use strict;
use warnings;
use Carp qw(confess);
use JSON::PP;
use FSM::Scheduler::ISF::FormalIdentityPlan;
use FSM::Scheduler::ISF::FormalReservationInventory;
use FSM::Scheduler::ISF::PreparedFormalReservations;

# Verify actual, already admitted LoweringIR modules before handing them to an
# emitter. Callers retain responsibility for source admission and projection;
# this guard neither builds a substitute IR nor makes unlowerable source valid.
sub verify {
    my ($class, $prepared, $plan, $modules) = @_;
    my $inventory = FSM::Scheduler::ISF::PreparedFormalReservations->collect($prepared);
    my $expected = FSM::Scheduler::ISF::FormalIdentityPlan->build($prepared->{actor},
        generated_children => $prepared->{generated_children},
        reserved_names => $inventory->{reserved_names});
    my $json = JSON::PP->new->canonical;
    confess "Formal reservation coverage requires the canonical complete allocation plan\n"
        unless ref($plan) eq 'HASH' && $json->encode($plan) eq $json->encode($expected);
    confess "Formal reservation coverage requires an actual module hash\n" unless ref($modules) eq 'HASH';

    my (%sources, %scopes);
    for my $scope (@{$inventory->{scopes}}) {
        $scopes{$json->encode($scope->{identity})} = $scope;
    }
    if (keys %{$prepared->{domain_source_products}}) {
        for my $name (sort keys %{$prepared->{domain_source_products}}) {
            my $domain = $prepared->{domain_source_products}{$name};
            my $local = $domain->{preparation};
            my $module = $local->{actor}{actor_name};
            confess "Formal reservation coverage has duplicate module '$module'\n" if exists $sources{$module};
            $sources{$module} = [$local, $domain->{identity}];
        }
    } else {
        my $name = $prepared->{actor}{actor_name};
        $sources{$name} = [$prepared, ['actor_module', $name]];
    }
    _same_keys($modules, \%sources, 'parent/domain modules');
    my @verified;
    for my $name (sort keys %sources) {
        my ($local, $identity) = @{$sources{$name}};
        my $ir = $modules->{$name};
        _module($ir, $name);
        my $scope = $scopes{$json->encode([@$identity, 'parent'])};
        my %live = map {$_->{name} => 1} grep {!$local->{pruned_transactions}{$_->{name}}}
            @{$local->{actor}{transactions}};
        my %private = map {$_->{physical_name} => $_}
            grep {$_->{placement} eq 'direct_private' && $live{$_->{transaction}}} @{$plan->{ordered}};
        _verify_scope($ir, $scope, \%private);
        push @verified, [@$identity, 'parent'];

        my %children = (%{$local->{generated_child_products}}, %{$local->{reusable_child_products}{children}});
        confess "Formal reservation coverage requires children for module '$name'\n"
            unless ref($ir->{children}) eq 'HASH';
        _same_keys($ir->{children}, \%children, "children of '$name'");
        for my $child (sort keys %children) {
            my $child_ir = $ir->{children}{$child};
            _module($child_ir, $children{$child}{actor_name});
            confess "Formal reservation coverage has an unplanned nested child scope\n"
                unless ref($child_ir->{children}) eq 'HASH' && !keys %{$child_ir->{children}};
            my $child_identity = [@$identity, 'child', $child];
            _verify_scope($child_ir, $scopes{$json->encode($child_identity)}, {});
            push @verified, $child_identity;
        }
    }
    return {model => 'isf_formal_reservation_coverage_v1', verified_scopes => \@verified};
}

sub _verify_scope {
    my ($ir, $scope, $private) = @_;
    confess "Formal reservation coverage has no prepared scope\n" unless ref($scope) eq 'HASH';
    my ($names, $fixed) = _declarations($ir);
    my %reserved = (%{$scope->{reserved_names}}, map {$_ => 1} keys %$private);
    my @missing = sort grep {!$reserved{$_}} keys %$names;
    confess "Formal reservation coverage: module '$ir->{actor_name}' has unreserved declarations: "
        . join(', ', @missing) . "\n" if @missing;
    for my $name (sort keys %$private) {
        my $formal = $private->{$name};
        my $width = $formal->{declaration}{width} // 1;
        confess "Formal reservation coverage: private formal '$name' has wrong width or ownership in '$ir->{actor_name}'\n"
            unless exists $ir->{counters}{$name} && $ir->{counters}{$name} eq $width
                && exists $ir->{signal_widths}{$name} && $ir->{signal_widths}{$name} eq $width
                && ($ir->{storage_roles}{$name} // '') eq 'transaction_port' && !$fixed->{$name};
    }
}

sub _declarations {
    my ($ir) = @_;
    my (%names, %fixed);
    for my $field (qw(signal_widths counters storage_roles signal_type_refs reset_values output_defaults)) {
        my $values = $ir->{$field};
        $values //= {} if $field eq 'output_defaults';
        confess "Formal reservation coverage has malformed '$field'\n" unless ref($values) eq 'HASH';
        $names{$_} = 1 for keys %$values;
    }
    for my $field (qw(ports explicit_interface_ports constants params states dt_blocks)) {
        my $entries = $ir->{$field} // [];
        confess "Formal reservation coverage has malformed '$field'\n" unless ref($entries) eq 'ARRAY';
        for my $entry (@$entries) {
            confess "Formal reservation coverage has malformed '$field' declaration\n"
                unless ref($entry) eq 'HASH' && _identifier($entry->{name});
            $names{$entry->{name}} = $fixed{$entry->{name}} = 1;
        }
    }
    for my $name (@{$ir->{explicit_internal_signals} || []}) {
        confess "Formal reservation coverage has malformed internal declaration\n" unless _identifier($name);
        $names{$name} = 1;
    }
    for my $storage (@{$ir->{declared_storage} || []}) {
        for my $signal (@{$storage->{signals} || []}) {
            confess "Formal reservation coverage has malformed storage declaration\n" unless _identifier($signal->{name});
            $names{$signal->{name}} = $fixed{$signal->{name}} = 1;
        }
    }
    # A scalar assignment target can become an implicit declaration in the
    # emitted carrier even when it has no explicit width record.
    for my $block (@{$ir->{states} || []}, @{$ir->{dt_blocks} || []}) {
        for my $assignment (@{$block->{assignments} || []}) {
            my $lhs = $assignment->{lhs};
            confess "Formal reservation coverage has malformed assignment target\n"
                unless defined($lhs) && !ref($lhs);
            $names{$1} = 1 while $lhs =~ /([A-Za-z_][A-Za-z0-9_]*)/g;
        }
    }
    for my $name ($ir->{clock}, (($ir->{reset} || {})->{name})) {
        next unless defined $name;
        confess "Formal reservation coverage has malformed system declaration\n" unless _identifier($name);
        $names{$name} = $fixed{$name} = 1;
    }
    # Enum/type declarations may be nested syntax. Conservative value tokens
    # also cover their type and member names without inventing another parser.
    my $types = FSM::Scheduler::ISF::FormalReservationInventory->collect({
        map {$_ => $ir->{$_}} qw(enum_declarations type_declarations),
    });
    for my $name (keys %{$types->{origins}}) {
        $names{$name} = $fixed{$name} = 1
            if grep {$_->{position} eq 'value'} @{$types->{origins}{$name}};
    }
    return (\%names, \%fixed);
}

sub _module {
    my ($ir, $expected) = @_;
    confess "Formal reservation coverage has a missing or mismatched module '$expected'\n"
        unless ref($ir) eq 'HASH' && ($ir->{actor_name} // '') eq $expected;
}

sub _same_keys {
    my ($actual, $expected, $where) = @_;
    my @missing = sort grep {!exists $actual->{$_}} keys %$expected;
    my @extra = sort grep {!exists $expected->{$_}} keys %$actual;
    confess "Formal reservation coverage has incomplete $where (missing: "
        . join(', ', @missing) . '; unexpected: ' . join(', ', @extra) . ")\n"
        if @missing || @extra;
}

sub _identifier {defined($_[0]) && !ref($_[0]) && $_[0] =~ /\A[A-Za-z_][A-Za-z0-9_]*\z/}

1;
