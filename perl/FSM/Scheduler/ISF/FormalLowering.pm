package FSM::Scheduler::ISF::FormalLowering;

use strict;
use warnings;
use Carp qw(confess);
use Storable qw(dclone);
use JSON::PP;
use FSM::Scheduler::ISF::PreparedFormalReservations;
use FSM::Scheduler::ISF::FormalIdentityPlan;
use FSM::Scheduler::ISF::FormalClauseResolver;
use FSM::Scheduler::ISF::FormalReservationCoverage;

sub prepare {
    my ($class, $lowerer, $source) = @_;
    my @ports = map {@{($_->{ports} || {})->{inputs} || []}, @{($_->{ports} || {})->{outputs} || []}}
        @{$source->{transactions}};
    return undef unless @ports;
    my $prepared = $lowerer->prepare_formal_source($source);
    my @live = grep {!$prepared->{pruned_transactions}{$_->{name}}} @{$prepared->{actor}{transactions}};
    my @live_ports = map {@{($_->{ports} || {})->{inputs} || []}, @{($_->{ports} || {})->{outputs} || []}} @live;
    my @projected = grep {exists $_->{_isf_formal_identity}} @live_ports;
    if (@projected) {
        confess "Formal lowering cannot mix projected and unprojected live formal declarations\n"
            unless @projected == @live_ports;
        # Existing private callers can explicitly apply the detached resolver.
        # Their marked declarations have already passed canonical source checks;
        # do not rename those physical endpoints a second time.
        return undef;
    }
    return undef unless grep {!$prepared->{generated_children}{$_->{name}}
        && (@{($_->{ports} || {})->{inputs} || []} || @{($_->{ports} || {})->{outputs} || []})} @live;
    my $inventory = FSM::Scheduler::ISF::PreparedFormalReservations->collect($prepared);
    my $plan = FSM::Scheduler::ISF::FormalIdentityPlan->build($prepared->{actor},
        generated_children => $prepared->{generated_children}, reserved_names => $inventory->{reserved_names});
    my $actor = dclone($prepared->{actor});
    for my $tx (@{$actor->{transactions}}) {
        next if $prepared->{pruned_transactions}{$tx->{name}};
        $tx = FSM::Scheduler::ISF::FormalClauseResolver->transaction($tx,
            plan => $plan, %{$prepared->{transactions}{$tx->{name}}})->{transaction};
    }
    for my $rule (@{$actor->{rules}}) {
        $rule = FSM::Scheduler::ISF::FormalClauseResolver->rule($rule,
            plan => $plan, %{$prepared->{actor_context}})->{rule};
    }
    return {actor => $actor, prepared => $prepared, plan => $plan};
}

sub verify {
    my ($class, $context, $modules) = @_;
    return unless $context;
    return FSM::Scheduler::ISF::FormalReservationCoverage->verify(
        $context->{prepared}, $context->{plan}, $modules);
}

sub report_ir {
    my ($class, $context, $ir, $domain) = @_;
    return $ir unless $context;
    my $prepared = defined($domain)
        ? $context->{prepared}{domain_source_products}{$domain}{preparation}
        : $context->{prepared};
    confess "Formal report projection has no original source preparation\n" unless ref($prepared) eq 'HASH';
    my $view = dclone($ir);
    my $bindings = $prepared->{transaction_binding_report_products};
    _same_record_identity($ir->{transaction_port_bindings}, $bindings,
        [qw(site_kind owner owner_kind target_transaction role width instance parent_port child_port
            start_signal done_signal trigger_source payload_source)], 'binding');
    $view->{transaction_port_bindings} = dclone($bindings);

    # These source-expression fields are also used by executable call/loop
    # wiring. Restore them only in this detached report view, never in the IR
    # that emission or reservation verification consumes.
    my %source_states = map {$_->{name} => $_} @{$prepared->{parent_point_products}{states}};
    for my $state (@{$view->{states}}) {
        for my $field (qw(wait_count_source loop_condition exit_when_condition ready valid)) {
            next unless exists $state->{$field};
            my $original = $source_states{$state->{name}};
            confess "Formal report projection has no source $field for state '$state->{name}'\n"
                unless $original && exists $original->{$field}
                    && ($original->{transaction} // '') eq ($state->{transaction} // '');
            $state->{$field} = _copy($original->{$field});
        }
    }
    my (@contracts, @accesses);
    for my $tx (@{$prepared->{actor}{transactions}}) {
        next if $prepared->{generated_children}{$tx->{name}} || $prepared->{pruned_transactions}{$tx->{name}};
        my $products = $prepared->{transaction_products}{$tx->{name}};
        push @contracts, @{$products->{temporal_contracts}};
        push @accesses, @{$products->{bank_accesses}};
    }
    push @accesses, @{$prepared->{parent_activation_products}{bank_accesses}};
    _same_record_identity($view->{temporal_contracts}, \@contracts, [qw(transaction name kind)], 'temporal contract');
    for my $i (0 .. $#contracts) {
        for my $field (qw(trigger signal)) {
            $view->{temporal_contracts}[$i]{$field} = _copy($contracts[$i]{$field});
        }
    }
    _same_record_identity($view->{bank_accesses}, \@accesses,
        [qw(kind owner owner_kind container_kind container_name bank width depth scalar_entries same_cycle_policy)], 'bank access');
    $view->{bank_accesses} = dclone(\@accesses);
    return $view;
}

sub _same_record_identity {
    my ($physical, $source, $fields, $kind) = @_;
    confess "Formal report projection has mismatched $kind records\n"
        unless ref($physical) eq 'ARRAY' && ref($source) eq 'ARRAY' && @$physical == @$source;
    my $json = JSON::PP->new->canonical;
    for my $i (0 .. $#$source) {
        my @physical = map {$physical->[$i]{$_}} @$fields;
        my @source = map {$source->[$i]{$_}} @$fields;
        confess "Formal report projection has mismatched $kind identity at record $i\n"
            unless $json->encode(\@physical) eq $json->encode(\@source);
    }
}

sub _copy {ref($_[0]) ? dclone($_[0]) : $_[0]}

1;
