package FSM::Scheduler::ISF::ControlFlowEffects;

use v5.20;
use strict;
use warnings;
use feature qw(signatures postderef);
no warnings 'experimental::signatures';
use Carp qw(confess);

sub new($class, %args) {
    confess "FSM::Scheduler::ISF::ControlFlowEffects->new expects a class invocant\n"
        unless defined($class) && !ref($class);
    bless { debug => ($args{debug} // 0) }, $class;
}

sub inventory_actor($self, $actor) {
    _validate_actor($actor);

    my %generated_child_targets = _generated_child_targets($actor);
    my $domain_context = _domain_context($actor);
    my @transactions = map {
        _inventory_transaction($_, \%generated_child_targets, $domain_context)
    } @{$actor->{transactions}};

    return {
        model                   => 'isf_control_flow_effects_v1',
        actor_name              => $actor->{actor_name},
        domain_context          => _public_domain_context($domain_context),
        generated_child_targets => [sort keys %generated_child_targets],
        transactions            => \@transactions,
    };
}

sub check_actor($self, $actor) {
    return $self->check_inventory($self->inventory_actor($actor));
}

sub check_inventory($self, $inventory) {
    confess "ControlFlowEffects checker expects an inventory hash reference\n"
        unless ref($inventory) eq 'HASH';
    confess "ControlFlowEffects checker inventory is missing transactions array\n"
        unless ref($inventory->{transactions}) eq 'ARRAY';

    my @transactions = map { _check_transaction($_) } @{$inventory->{transactions}};
    my $violation_count = 0;
    my $proof_count = 0;
    for my $tx (@transactions) {
        $violation_count += $tx->{summary}{violation_count};
        $proof_count     += $tx->{summary}{proof_count};
    }

    return {
        model           => 'isf_control_flow_effect_checks_v1',
        actor_name      => $inventory->{actor_name},
        ok              => $violation_count == 0 ? 1 : 0,
        proof_count     => $proof_count,
        violation_count => $violation_count,
        transactions    => \@transactions,
    };
}

sub plan_actor($self, $actor) {
    return $self->plan_inventory($self->inventory_actor($actor));
}

sub plan_inventory($self, $inventory) {
    confess "ControlFlowEffects planner expects an inventory hash reference\n"
        unless ref($inventory) eq 'HASH';
    confess "ControlFlowEffects planner inventory is missing transactions array\n"
        unless ref($inventory->{transactions}) eq 'ARRAY';

    my @transactions = map { _plan_transaction($_) } @{$inventory->{transactions}};
    my @generated_instances = map { @{$_->{generated_instances}} } @transactions;
    my @local_child_wires = map { @{$_->{local_child_wires}} } @transactions;
    my @activation_requirements = map { @{$_->{activation_requirements}} } @transactions;
    my @sync_points = map { @{$_->{sync_points}} } @transactions;

    return {
        model                   => 'isf_control_flow_child_plan_v1',
        actor_name              => $inventory->{actor_name},
        generated_child_targets => $inventory->{generated_child_targets} || [],
        generated_instances     => \@generated_instances,
        local_child_wires       => \@local_child_wires,
        activation_requirements => \@activation_requirements,
        sync_points             => \@sync_points,
        transactions            => \@transactions,
        summary                 => {
            transaction_count        => scalar(@transactions),
            generated_instance_count => scalar(@generated_instances),
            local_child_wire_count   => scalar(@local_child_wires),
            activation_requirement_count => scalar(@activation_requirements),
            sync_point_count         => scalar(@sync_points),
        },
    };
}

sub _validate_actor($actor) {
    confess "ControlFlowEffects inventory expects an actor hash reference\n"
        unless ref($actor) eq 'HASH';
    confess "ControlFlowEffects actor is missing scalar actor_name\n"
        unless defined($actor->{actor_name}) && !ref($actor->{actor_name});
    confess "ControlFlowEffects actor '$actor->{actor_name}' is missing transactions array\n"
        unless ref($actor->{transactions}) eq 'ARRAY';
}

sub _inventory_transaction($tx, $generated_child_targets, $domain_context) {
    confess "ControlFlowEffects transaction entry must be a hash reference\n"
        unless ref($tx) eq 'HASH';
    confess "ControlFlowEffects transaction is missing scalar name\n"
        unless defined($tx->{name}) && !ref($tx->{name});
    confess "ControlFlowEffects transaction '$tx->{name}' is missing clauses array\n"
        unless ref($tx->{clauses}) eq 'ARRAY';

    my @regions;
    my @effects;
    my %ctx = (
        transaction                      => $tx->{name},
        generated_child_targets          => $generated_child_targets || {},
        domain_context                   => $domain_context || {},
        transaction_domain               => _domain_for_entry($tx, ($domain_context || {})->{default_domain}),
        regions                          => \@regions,
        effects                          => \@effects,
        region_seq                       => 0,
        effect_seq                       => 0,
        top_do_ordinal                   => 0,
        repeat_do_ordinal                => 0,
        conditional_generated_do_ordinal => 0,
    );

    my $root = _push_region(
        \%ctx,
        kind    => 'transaction',
        label   => 'transaction body',
        path    => ['transaction'],
        entry   => { kind => 'transaction_entry' },
        exits   => [{ kind => 'normal_exit' }],
    );

    _inventory_sequence($tx->{clauses}, \%ctx, $root, 'transaction body', ['transaction']);

    return {
        name        => $tx->{name},
        domain      => $ctx{transaction_domain},
        root_region => $root->{id},
        regions     => \@regions,
        effects     => \@effects,
        summary     => _transaction_summary(\@regions, \@effects),
    };
}

sub _push_region($ctx, %region) {
    my $id = $ctx->{transaction} . '.region.' . $ctx->{region_seq}++;
    my %entry = (
        id          => $id,
        transaction => $ctx->{transaction},
        parent      => $region{parent},
        kind        => $region{kind},
        label       => $region{label},
        path        => $region{path} || [],
        entry       => $region{entry} || { kind => 'implicit' },
        exits       => $region{exits} || [{ kind => 'normal_exit' }],
        backedges   => $region{backedges} || [],
        effects     => [],
    );

    $entry{condition} = $region{condition} if exists $region{condition};
    $entry{selector}  = $region{selector}  if exists $region{selector};
    $entry{case_value} = $region{case_value} if exists $region{case_value};
    $entry{count} = $region{count} if exists $region{count};

    push @{$ctx->{regions}}, \%entry;
    return \%entry;
}

sub _push_effect($ctx, $region, %effect) {
    my $id = $ctx->{transaction} . '.effect.' . $ctx->{effect_seq}++;
    my %entry = (
        id          => $id,
        transaction => $ctx->{transaction},
        region_id   => $region->{id},
        region_kind => $region->{kind},
        context     => $effect{context},
        kind        => $effect{kind},
    );

    for my $key (sort keys %effect) {
        next if $key eq 'context' || $key eq 'kind';
        $entry{$key} = $effect{$key};
    }

    push @{$ctx->{effects}}, \%entry;
    push @{$region->{effects}}, $id;
    return \%entry;
}

sub _inventory_sequence($clauses, $ctx, $region, $label, $path) {
    my @pending_done_ports;

    for my $clause (@$clauses) {
        next unless _is_clause($clause);
        my $keyword = $clause->[0];

        if ($keyword eq 'when') {
            my $condition = _format_expr($clause->[1]);
            my $child_region = _push_region(
                $ctx,
                parent    => $region->{id},
                kind      => 'when',
                label     => 'when body',
                path      => [@$path, 'when'],
                condition => $condition,
                entry     => { kind => 'condition_true', condition => $condition },
                exits     => [
                    { kind => 'condition_false_skip' },
                    { kind => 'body_complete' },
                ],
            );
            my $pending = _inventory_sequence([@{$clause}[2 .. $#$clause]], $ctx, $child_region, 'when body', [@$path, 'when']);
            _record_outstanding_on_exit($child_region, $pending);
            next;
        }

        if ($keyword eq 'switch') {
            my $selector = _format_expr($clause->[1]);
            my $switch_region = _push_region(
                $ctx,
                parent   => $region->{id},
                kind     => 'switch',
                label    => 'switch body',
                path     => [@$path, 'switch'],
                selector => $selector,
                entry    => { kind => 'selector_decode', selector => $selector },
                exits    => [{ kind => 'selected_branch_complete' }],
            );
            my @branch_ids;
            for my $branch (@{$clause}[2 .. $#$clause]) {
                next unless ref($branch) eq 'ARRAY' && @$branch >= 1;
                my $case_value = _format_expr($branch->[0]);
                my $branch_region = _push_region(
                    $ctx,
                    parent     => $switch_region->{id},
                    kind       => 'switch_branch',
                    label      => 'switch branch',
                    path       => [@$path, 'switch', "case:$case_value"],
                    selector   => $selector,
                    case_value => $case_value,
                    entry      => { kind => 'case_match', selector => $selector, value => $case_value },
                    exits      => [{ kind => 'branch_complete' }],
                );
                push @branch_ids, $branch_region->{id};
                my $pending = _inventory_sequence([@{$branch}[1 .. $#$branch]], $ctx, $branch_region, 'switch branch', [@$path, 'switch', "case:$case_value"]);
                _record_outstanding_on_exit($branch_region, $pending);
            }
            $switch_region->{branch_regions} = \@branch_ids;
            next;
        }

        if ($keyword eq 'while' || $keyword eq 'until') {
            my $condition = _format_expr($clause->[1]);
            my $child_region = _push_region(
                $ctx,
                parent    => $region->{id},
                kind      => $keyword,
                label     => "$keyword body",
                path      => [@$path, $keyword],
                condition => $condition,
                entry     => {
                    kind      => $keyword eq 'while' ? 'pre_test_true' : 'body_entry_before_post_test',
                    condition => $condition,
                },
                exits     => [
                    { kind => $keyword eq 'while' ? 'condition_false_exit' : 'condition_true_exit' },
                    { kind => 'body_complete' },
                ],
                backedges => [
                    {
                        kind                       => $keyword eq 'while' ? 'while_retest' : 'until_retest',
                        condition                  => $condition,
                        outstanding_child_lifetime => 'must_be_drained_or_proven',
                    },
                ],
            );
            my $pending = _inventory_sequence([@{$clause}[2 .. $#$clause]], $ctx, $child_region, "$keyword body", [@$path, $keyword]);
            _record_outstanding_on_exit($child_region, $pending);
            next;
        }

        if ($keyword eq 'repeat') {
            my $count = _format_expr($clause->[1]);
            my $child_region = _push_region(
                $ctx,
                parent    => $region->{id},
                kind      => 'repeat',
                label     => 'repeat body',
                path      => [@$path, 'repeat'],
                count     => $count,
                entry     => { kind => 'repeat_init', count => $count },
                exits     => [
                    { kind => 'count_zero_exit' },
                    { kind => 'repeat_complete' },
                ],
                backedges => [
                    {
                        kind                       => 'repeat_check_nonzero',
                        count                      => $count,
                        outstanding_child_lifetime => 'must_be_drained_or_proven',
                    },
                ],
            );
            my $pending = _inventory_sequence([@{$clause}[2 .. $#$clause]], $ctx, $child_region, 'repeat body', [@$path, 'repeat']);
            _record_outstanding_on_exit($child_region, $pending);
            next;
        }

        if ($keyword eq 'do') {
            _record_do_effect($ctx, $region, $clause, $label);
            next;
        }

        if ($keyword eq 'spawn') {
            my $done_port = _record_spawn_effect($ctx, $region, $clause, $label);
            push @pending_done_ports, $done_port if defined $done_port && length $done_port;
            next;
        }

        if ($keyword eq 'await_all') {
            _push_effect(
                $ctx,
                $region,
                context    => $label,
                kind       => 'child_done_drain',
                activation => 'await_all',
                await_port => _format_expr($clause->[1]),
                done_ports => [@pending_done_ports],
                drains_all => 1,
            );
            @pending_done_ports = ();
            next;
        }

        if ($keyword eq 'await_any') {
            my @observed = @pending_done_ports;
            my @remaining = @pending_done_ports > 1 ? @pending_done_ports : ();
            _push_effect(
                $ctx,
                $region,
                context                       => $label,
                kind                          => 'child_done_observe',
                activation                    => 'await_any',
                await_port                    => _format_expr($clause->[1]),
                done_ports                    => \@observed,
                drains_all                    => 0,
                single_pending_equivalent_drain => @observed <= 1 ? 1 : 0,
                remaining_outstanding_after   => [@remaining],
            );
            @pending_done_ports = @remaining;
            next;
        }
    }

    _record_outstanding_on_exit($region, \@pending_done_ports);
    return \@pending_done_ports;
}

sub _record_do_effect($ctx, $region, $clause, $label) {
    my $child = _format_expr($clause->[1]);
    my ($generated_child, $instance) = _do_instance($ctx, $clause, $label, $child);
    my $prefix = $generated_child ? $instance : $child;
    my $domain_contract = _activation_domain_contract($ctx, $clause, $child, 'do');
    my $binding_handoffs = _binding_handoffs($ctx, $clause, $child, 'do', $instance);
    my $generated_top_requirements = _generated_top_requirements(
        'do',
        $generated_child,
        $instance,
        defined($prefix) ? "${prefix}_start" : undef,
        defined($prefix) ? "${prefix}_done" : undef,
        $binding_handoffs,
        $domain_contract,
    );

    _push_effect(
        $ctx,
        $region,
        context        => $label,
        kind           => 'child_start',
        activation     => 'do',
        child          => $child,
        target_kind    => $generated_child ? 'generated_child' : 'local_child',
        generated_child => $generated_child,
        instance       => $instance,
        start_signal   => defined($prefix) ? "${prefix}_start" : undef,
        done_signal    => defined($prefix) ? "${prefix}_done" : undef,
        blocking       => 1,
        done_semantics => 'blocking_child_done_drain',
        parameterized  => _has_subclause($clause, 'params') ? 1 : 0,
        domain         => $domain_contract->{authored_domain},
        domain_contract => $domain_contract,
        bindings       => $binding_handoffs,
        generated_top_requirements => $generated_top_requirements,
    );
}

sub _record_spawn_effect($ctx, $region, $clause, $label) {
    my $child = _format_expr($clause->[1]);
    my $instance = _spawn_instance_name($ctx->{transaction}, $clause);
    my $done_port = "${instance}_done";
    my $domain_contract = _activation_domain_contract($ctx, $clause, $child, 'spawn');
    my $binding_handoffs = _binding_handoffs($ctx, $clause, $child, 'spawn', $instance);
    my $generated_top_requirements = _generated_top_requirements(
        'spawn',
        1,
        $instance,
        "${instance}_start",
        $done_port,
        $binding_handoffs,
        $domain_contract,
    );

    _push_effect(
        $ctx,
        $region,
        context         => $label,
        kind            => 'child_start',
        activation      => 'spawn',
        child           => $child,
        target_kind     => 'generated_child',
        generated_child => 1,
        instance        => $instance,
        start_signal    => "${instance}_start",
        done_signal     => $done_port,
        blocking        => 0,
        done_semantics  => 'nonblocking_outstanding_until_sync',
        parameterized   => _has_subclause($clause, 'params') ? 1 : 0,
        domain          => $domain_contract->{authored_domain},
        domain_contract => $domain_contract,
        bindings        => $binding_handoffs,
        generated_top_requirements => $generated_top_requirements,
    );

    return $done_port;
}

sub _do_instance($ctx, $clause, $label, $child) {
    my $generated_child = _do_is_generated($ctx, $clause, $child);
    if ($label eq 'transaction body') {
        my $ordinal = $ctx->{top_do_ordinal}++;
        return ($generated_child, $generated_child ? _generated_do_instance_name($ctx->{transaction}, $child, $ordinal) : undef);
    }
    if ($label eq 'repeat body') {
        my $ordinal = $ctx->{repeat_do_ordinal}++;
        return ($generated_child, $generated_child ? _generated_repeat_do_instance_name($ctx->{transaction}, $child, $ordinal) : undef);
    }
    if ($generated_child) {
        my $ordinal = $ctx->{conditional_generated_do_ordinal}++;
        return (1, _generated_conditional_do_instance_name($ctx->{transaction}, $child, $ordinal));
    }
    return (0, undef);
}

sub _do_is_generated($ctx, $clause, $child) {
    return 1 if _has_subclause($clause, 'params');
    return 1 if defined($child)
        && ref($ctx->{generated_child_targets}) eq 'HASH'
        && $ctx->{generated_child_targets}{$child};
    return 0;
}

sub _record_outstanding_on_exit($region, $pending) {
    return unless ref($pending) eq 'ARRAY';
    $region->{outstanding_on_exit} = [@$pending];
}

sub _transaction_summary($regions, $effects) {
    my %region_kinds;
    my %effect_kinds;
    my %activation_kinds;
    my %domain_relations;
    my %cdc_requirements;
    my $backedge_count = 0;
    my $binding_handoff_count = 0;
    my $generated_top_requirement_count = 0;
    for my $region (@$regions) {
        $region_kinds{$region->{kind}}++;
        $backedge_count += scalar @{$region->{backedges} || []};
    }
    for my $effect (@$effects) {
        $effect_kinds{$effect->{kind}}++;
        $activation_kinds{$effect->{activation}}++ if defined $effect->{activation};
        if (ref($effect->{domain_contract}) eq 'HASH') {
            $domain_relations{$effect->{domain_contract}{relation}}++
                if defined $effect->{domain_contract}{relation};
            $cdc_requirements{$effect->{domain_contract}{cdc_requirement}}++
                if defined $effect->{domain_contract}{cdc_requirement};
        }
        $binding_handoff_count += scalar @{$effect->{bindings} || []};
        $generated_top_requirement_count += scalar @{$effect->{generated_top_requirements} || []};
    }

    return {
        region_count              => scalar(@$regions),
        effect_count              => scalar(@$effects),
        region_kinds              => \%region_kinds,
        effect_kinds              => \%effect_kinds,
        activation_kinds          => \%activation_kinds,
        backedge_count            => $backedge_count,
        child_start_effects       => ($effect_kinds{child_start} || 0),
        child_done_observe_effects => ($effect_kinds{child_done_observe} || 0),
        child_done_drain_effects  => ($effect_kinds{child_done_drain} || 0),
        domain_relations          => \%domain_relations,
        cdc_requirements          => \%cdc_requirements,
        binding_handoff_count     => $binding_handoff_count,
        generated_top_requirement_count => $generated_top_requirement_count,
    };
}

sub _check_transaction($tx) {
    confess "ControlFlowEffects checker transaction entry must be a hash reference\n"
        unless ref($tx) eq 'HASH';
    confess "ControlFlowEffects checker transaction is missing scalar name\n"
        unless defined($tx->{name}) && !ref($tx->{name});

    my @proofs;
    my @violations;
    my %region_by_id = map { $_->{id} => $_ } @{$tx->{regions} || []};

    for my $region (@{$tx->{regions} || []}) {
        _check_region_lifetime($tx, $region, \@proofs, \@violations);
    }

    my %generated_instance_owner;
    for my $effect (@{$tx->{effects} || []}) {
        _check_effect($tx, $effect, \%region_by_id, \%generated_instance_owner, \@proofs, \@violations);
    }

    return {
        name       => $tx->{name},
        ok         => @violations ? 0 : 1,
        proofs     => \@proofs,
        violations => \@violations,
        summary    => {
            proof_count     => scalar(@proofs),
            violation_count => scalar(@violations),
        },
    };
}

sub _plan_transaction($tx) {
    confess "ControlFlowEffects planner transaction entry must be a hash reference\n"
        unless ref($tx) eq 'HASH';
    confess "ControlFlowEffects planner transaction is missing scalar name\n"
        unless defined($tx->{name}) && !ref($tx->{name});

    my @local_child_wires;
    my @generated_instances;
    my @sync_points;
    my @activation_requirements;

    for my $effect (@{$tx->{effects} || []}) {
        next unless ref($effect) eq 'HASH';
        if (($effect->{kind} // '') eq 'child_start' && ($effect->{target_kind} // '') eq 'local_child') {
            push @local_child_wires, {
                transaction => $tx->{name},
                effect_id   => $effect->{id},
                region_id   => $effect->{region_id},
                region_kind => $effect->{region_kind},
                context     => $effect->{context},
                activation  => $effect->{activation},
                child       => $effect->{child},
                start       => $effect->{start_signal},
                done        => $effect->{done_signal},
                domain_contract => $effect->{domain_contract},
                bindings    => $effect->{bindings} || [],
            };
        }

        if (($effect->{kind} // '') eq 'child_start' && $effect->{generated_child}) {
            push @generated_instances, {
                transaction   => $tx->{name},
                effect_id     => $effect->{id},
                region_id     => $effect->{region_id},
                region_kind   => $effect->{region_kind},
                context       => $effect->{context},
                activation    => $effect->{activation},
                child         => $effect->{child},
                instance      => $effect->{instance},
                start         => $effect->{start_signal},
                done          => $effect->{done_signal},
                parameterized => $effect->{parameterized} ? 1 : 0,
                domain        => $effect->{domain},
                domain_contract => $effect->{domain_contract},
                bindings      => $effect->{bindings} || [],
                generated_top_requirements => $effect->{generated_top_requirements} || [],
            };
        }

        if (($effect->{kind} // '') eq 'child_start') {
            push @activation_requirements, {
                transaction   => $tx->{name},
                effect_id     => $effect->{id},
                region_id     => $effect->{region_id},
                region_kind   => $effect->{region_kind},
                context       => $effect->{context},
                activation    => $effect->{activation},
                child         => $effect->{child},
                target_kind   => $effect->{target_kind},
                domain_contract => $effect->{domain_contract},
                bindings      => $effect->{bindings} || [],
                generated_top_requirements => $effect->{generated_top_requirements} || [],
            };
        }

        if (($effect->{kind} // '') eq 'child_done_observe'
            || ($effect->{kind} // '') eq 'child_done_drain') {
            push @sync_points, {
                transaction => $tx->{name},
                effect_id   => $effect->{id},
                region_id   => $effect->{region_id},
                region_kind => $effect->{region_kind},
                context     => $effect->{context},
                activation  => $effect->{activation},
                kind        => $effect->{kind},
                done_ports  => $effect->{done_ports} || [],
                drains_all  => $effect->{drains_all} ? 1 : 0,
            };
        }
    }

    return {
        name                => $tx->{name},
        local_child_wires   => \@local_child_wires,
        generated_instances => \@generated_instances,
        activation_requirements => \@activation_requirements,
        sync_points         => \@sync_points,
        summary             => {
            local_child_wire_count   => scalar(@local_child_wires),
            generated_instance_count => scalar(@generated_instances),
            activation_requirement_count => scalar(@activation_requirements),
            sync_point_count         => scalar(@sync_points),
        },
    };
}

sub _check_region_lifetime($tx, $region, $proofs, $violations) {
    my @outstanding = @{$region->{outstanding_on_exit} || []};
    my @backedges = @{$region->{backedges} || []};

    if (@outstanding && @backedges) {
        for my $backedge (@backedges) {
            _push_violation(
                $violations,
                transaction            => $tx->{name},
                code                   => 'backedge_has_live_outstanding_children',
                invariant              => 'loop_backedge_dominance',
                region_id              => $region->{id},
                region_kind            => $region->{kind},
                path                   => $region->{path},
                backedge               => $backedge->{kind},
                outstanding_done_ports => [@outstanding],
                message                => 'loop/repeat backedge can re-enter while child completions remain outstanding',
            );
        }
    } elsif (@outstanding) {
        _push_violation(
            $violations,
            transaction            => $tx->{name},
            code                   => 'region_exit_has_live_outstanding_children',
            invariant              => 'child_lifetime',
            region_id              => $region->{id},
            region_kind            => $region->{kind},
            path                   => $region->{path},
            outstanding_done_ports => [@outstanding],
            message                => 'region exits with outstanding child completions and no explicit lifetime proof',
        );
    } elsif (@backedges) {
        for my $backedge (@backedges) {
            _push_proof(
                $proofs,
                transaction => $tx->{name},
                code        => 'backedge_has_no_outstanding_children',
                invariant   => 'loop_backedge_dominance',
                region_id   => $region->{id},
                region_kind => $region->{kind},
                path        => $region->{path},
                backedge    => $backedge->{kind},
                message     => 'loop/repeat backedge is reached with no outstanding child completions in the shadow effect inventory',
            );
        }
    }
}

sub _check_effect($tx, $effect, $region_by_id, $generated_instance_owner, $proofs, $violations) {
    my $activation = $effect->{activation} // '';
    if ($effect->{kind} eq 'child_start') {
        _check_activation_domain_contract($tx, $effect, $proofs, $violations);
        _check_binding_handoffs($tx, $effect, $proofs, $violations);
        _check_generated_top_requirements($tx, $effect, $proofs, $violations);
    }

    if ($effect->{kind} eq 'child_start' && $activation eq 'do') {
        if ($effect->{blocking} && ($effect->{done_semantics} // '') eq 'blocking_child_done_drain') {
            _push_proof(
                $proofs,
                transaction => $tx->{name},
                code        => 'blocking_do_drains_child_done',
                invariant   => 'child_lifetime',
                effect_id   => $effect->{id},
                region_id   => $effect->{region_id},
                child       => $effect->{child},
                done_signal => $effect->{done_signal},
                message     => 'blocking do waits for its child done before control can advance',
            );
        } else {
            _push_violation(
                $violations,
                transaction => $tx->{name},
                code        => 'blocking_do_missing_done_drain',
                invariant   => 'child_lifetime',
                effect_id   => $effect->{id},
                region_id   => $effect->{region_id},
                child       => $effect->{child},
                message     => 'blocking do lacks an explicit child-done drain effect',
            );
        }
    }

    if ($effect->{kind} eq 'child_start' && $effect->{generated_child}) {
        _check_generated_instance_identity($tx, $effect, $generated_instance_owner, $proofs, $violations);
    }

    if ($effect->{kind} eq 'child_done_observe' && $activation eq 'await_any') {
        _push_proof(
            $proofs,
            transaction                  => $tx->{name},
            code                         => 'await_any_observes_without_full_drain',
            invariant                    => 'await_any_observe_not_drain',
            effect_id                    => $effect->{id},
            region_id                    => $effect->{region_id},
            done_ports                   => $effect->{done_ports},
            remaining_outstanding_after  => $effect->{remaining_outstanding_after},
            message                      => 'await_any is modeled as an observation; any multi-pending remainder must be drained by a later effect',
        );
        if ($effect->{single_pending_equivalent_drain}) {
            _push_proof(
                $proofs,
                transaction => $tx->{name},
                code        => 'await_any_single_pending_completes_outstanding_set',
                invariant   => 'child_lifetime',
                effect_id   => $effect->{id},
                region_id   => $effect->{region_id},
                done_ports  => $effect->{done_ports},
                message     => 'single-pending await_any observes the only outstanding child, so no child remains live after the observation',
            );
        } elsif (@{$effect->{remaining_outstanding_after} || []}) {
            _push_proof(
                $proofs,
                transaction                 => $tx->{name},
                code                        => 'await_any_multi_pending_requires_later_drain',
                invariant                   => 'child_lifetime',
                effect_id                   => $effect->{id},
                region_id                   => $effect->{region_id},
                remaining_outstanding_after => $effect->{remaining_outstanding_after},
                message                     => 'multi-pending await_any leaves outstanding children that require a later drain proof before re-entry',
            );
        }
    }

    if ($effect->{kind} eq 'child_done_drain' && $activation eq 'await_all') {
        _push_proof(
            $proofs,
            transaction => $tx->{name},
            code        => 'await_all_drains_outstanding_children',
            invariant   => 'child_lifetime',
            effect_id   => $effect->{id},
            region_id   => $effect->{region_id},
            done_ports  => $effect->{done_ports},
            message     => 'await_all drains the outstanding child completion set visible at that point',
        );
    }
}

sub _check_activation_domain_contract($tx, $effect, $proofs, $violations) {
    my $contract = $effect->{domain_contract};
    if (ref($contract) ne 'HASH') {
        _push_violation(
            $violations,
            transaction => $tx->{name},
            code        => 'activation_missing_domain_contract',
            invariant   => 'explicit_domain_binding_cdc',
            effect_id   => $effect->{id},
            region_id   => $effect->{region_id},
            child       => $effect->{child},
            message     => 'child activation lacks an explicit domain/CDC contract in the effect inventory',
        );
        return;
    }

    if (!defined($contract->{child_domain})) {
        _push_violation(
            $violations,
            transaction => $tx->{name},
            code        => 'activation_target_domain_unknown',
            invariant   => 'explicit_domain_binding_cdc',
            effect_id   => $effect->{id},
            region_id   => $effect->{region_id},
            child       => $effect->{child},
            caller_domain => $contract->{caller_domain},
            message     => 'child activation target has no resolved transaction domain',
        );
        return;
    }

    if (defined($contract->{activation_domain}) && !$contract->{activation_domain_declared}) {
        _push_violation(
            $violations,
            transaction => $tx->{name},
            code        => 'activation_domain_unknown',
            invariant   => 'explicit_domain_binding_cdc',
            effect_id   => $effect->{id},
            region_id   => $effect->{region_id},
            child       => $effect->{child},
            activation_domain => $contract->{activation_domain},
            message     => 'activation domain metadata names a domain that is not declared in the actor domain context',
        );
    }

    if (defined($contract->{authored_domain}) && ($contract->{activation_domain_relation} // '') ne 'same_domain') {
        _push_violation(
            $violations,
            transaction => $tx->{name},
            code        => 'activation_domain_metadata_must_match_caller',
            invariant   => 'explicit_domain_binding_cdc',
            effect_id   => $effect->{id},
            region_id   => $effect->{region_id},
            child       => $effect->{child},
            caller_domain => $contract->{caller_domain},
            activation_domain => $contract->{activation_domain},
            message     => 'activation-site domain metadata is modeled as same-domain placement metadata, not an implicit CDC contract',
        );
    } elsif (defined($contract->{authored_domain})) {
        _push_proof(
            $proofs,
            transaction => $tx->{name},
            code        => 'activation_domain_is_explicit',
            invariant   => 'explicit_domain_binding_cdc',
            effect_id   => $effect->{id},
            region_id   => $effect->{region_id},
            child       => $effect->{child},
            domain      => $contract->{authored_domain},
            message     => 'activation domain metadata is explicit and same-domain in the effect inventory',
        );
    }

    my $relation = $contract->{relation} // '';
    if ($relation eq 'same_domain') {
        _push_proof(
            $proofs,
            transaction => $tx->{name},
            code        => 'activation_target_is_same_domain',
            invariant   => 'explicit_domain_binding_cdc',
            effect_id   => $effect->{id},
            region_id   => $effect->{region_id},
            child       => $effect->{child},
            caller_domain => $contract->{caller_domain},
            child_domain  => $contract->{child_domain},
            message     => 'child activation target is in the same domain as the caller',
        );
        return;
    }

    if ($relation eq 'cross_domain') {
        my $requirement = $contract->{cdc_requirement} // '';
        if ($requirement eq 'activation_crossing_declared') {
            _push_proof(
                $proofs,
                transaction => $tx->{name},
                code        => 'activation_crossing_covers_child_start',
                invariant   => 'explicit_domain_binding_cdc',
                effect_id   => $effect->{id},
                region_id   => $effect->{region_id},
                child       => $effect->{child},
                caller_domain => $contract->{caller_domain},
                child_domain  => $contract->{child_domain},
                cdc_handoffs  => $contract->{cdc_handoffs},
                message     => 'cross-domain blocking child activation is covered by an explicit activation crossing',
            );
        } elsif ($requirement eq 'unsupported_cross_domain_spawn') {
            _push_violation(
                $violations,
                transaction => $tx->{name},
                code        => 'cross_domain_spawn_requires_future_cdc_contract',
                invariant   => 'explicit_domain_binding_cdc',
                effect_id   => $effect->{id},
                region_id   => $effect->{region_id},
                child       => $effect->{child},
                caller_domain => $contract->{caller_domain},
                child_domain  => $contract->{child_domain},
                message     => 'cross-domain spawn has no shipped CDC activation contract and remains fail-closed',
            );
        } else {
            _push_violation(
                $violations,
                transaction => $tx->{name},
                code        => 'cross_domain_activation_requires_activation_crossing',
                invariant   => 'explicit_domain_binding_cdc',
                effect_id   => $effect->{id},
                region_id   => $effect->{region_id},
                child       => $effect->{child},
                caller_domain => $contract->{caller_domain},
                child_domain  => $contract->{child_domain},
                message     => 'cross-domain child activation requires an explicit activation crossing contract',
            );
        }
    }
}

sub _check_binding_handoffs($tx, $effect, $proofs, $violations) {
    for my $binding (@{$effect->{bindings} || []}) {
        my $direction = $binding->{handoff_direction} // '';
        if ($direction eq 'unknown') {
            _push_violation(
                $violations,
                transaction => $tx->{name},
                code        => 'binding_handoff_direction_unknown',
                invariant   => 'explicit_domain_binding_cdc',
                effect_id   => $effect->{id},
                region_id   => $effect->{region_id},
                child       => $effect->{child},
                role        => $binding->{role},
                child_port  => $binding->{child_port},
                message     => 'activation binding role does not map to a typed handoff direction',
            );
            next;
        }
        _push_proof(
            $proofs,
            transaction => $tx->{name},
            code        => 'binding_handoff_is_explicit',
            invariant   => 'explicit_domain_binding_cdc',
            effect_id   => $effect->{id},
            region_id   => $effect->{region_id},
            child       => $effect->{child},
            role        => $binding->{role},
            child_port  => $binding->{child_port},
            actor_expr  => $binding->{actor_expr},
            handoff_direction => $binding->{handoff_direction},
            handoff_timing    => $binding->{handoff_timing},
            parent_port       => $binding->{parent_port},
            message     => 'activation binding is represented as a typed parent/child handoff',
        );
    }
}

sub _check_generated_top_requirements($tx, $effect, $proofs, $violations) {
    for my $requirement (@{$effect->{generated_top_requirements} || []}) {
        my $kind = $requirement->{kind} // '';
        if ($kind eq 'start_done_handoff') {
            _push_proof(
                $proofs,
                transaction => $tx->{name},
                code        => 'generated_top_start_done_handoff_required',
                invariant   => 'static_generated_instance_identity',
                effect_id   => $effect->{id},
                region_id   => $effect->{region_id},
                child       => $effect->{child},
                instance    => $requirement->{instance},
                start_signal => $requirement->{start_signal},
                done_signal  => $requirement->{done_signal},
                message     => 'generated child activation has explicit generated-top start/done handoff requirements',
            );
            next;
        }
        if ($kind eq 'binding_handoff') {
            _push_proof(
                $proofs,
                transaction => $tx->{name},
                code        => 'generated_top_binding_handoff_required',
                invariant   => 'explicit_domain_binding_cdc',
                effect_id   => $effect->{id},
                region_id   => $effect->{region_id},
                child       => $effect->{child},
                instance    => $requirement->{instance},
                child_port  => $requirement->{child_port},
                parent_port => $requirement->{parent_port},
                handoff_direction => $requirement->{handoff_direction},
                handoff_timing    => $requirement->{handoff_timing},
                message     => 'generated child activation has explicit generated-top binding handoff requirements',
            );
            next;
        }
        if ($kind eq 'activation_start_cdc' || $kind eq 'activation_done_cdc') {
            _push_proof(
                $proofs,
                transaction => $tx->{name},
                code        => 'generated_top_activation_cdc_handoff_required',
                invariant   => 'explicit_domain_binding_cdc',
                effect_id   => $effect->{id},
                region_id   => $effect->{region_id},
                child       => $effect->{child},
                cdc_kind    => $kind,
                from_domain => $requirement->{from_domain},
                to_domain   => $requirement->{to_domain},
                signal      => $requirement->{signal},
                instance    => $requirement->{instance},
                message     => 'cross-domain activation has explicit generated-top CDC handoff requirements',
            );
            next;
        }
    }
}

sub _check_generated_instance_identity($tx, $effect, $generated_instance_owner, $proofs, $violations) {
    my $instance = $effect->{instance};
    if (!defined($instance) || ref($instance) || !length($instance)) {
        _push_violation(
            $violations,
            transaction => $tx->{name},
            code        => 'generated_child_missing_static_instance',
            invariant   => 'static_generated_instance_identity',
            effect_id   => $effect->{id},
            region_id   => $effect->{region_id},
            child       => $effect->{child},
            message     => 'generated child activation lacks a deterministic static instance name',
        );
        return;
    }

    if (exists $generated_instance_owner->{$instance}) {
        _push_violation(
            $violations,
            transaction => $tx->{name},
            code        => 'duplicate_generated_child_instance',
            invariant   => 'static_generated_instance_identity',
            effect_id   => $effect->{id},
            previous_effect_id => $generated_instance_owner->{$instance},
            region_id   => $effect->{region_id},
            instance    => $instance,
            child       => $effect->{child},
            message     => 'generated child activation instance names must be unique within a transaction inventory',
        );
        return;
    }

    $generated_instance_owner->{$instance} = $effect->{id};
    _push_proof(
        $proofs,
        transaction => $tx->{name},
        code        => 'generated_child_instance_is_static',
        invariant   => 'static_generated_instance_identity',
        effect_id   => $effect->{id},
        region_id   => $effect->{region_id},
        child       => $effect->{child},
        instance    => $instance,
        message     => 'generated child activation has a deterministic static instance name',
    );
}

sub _push_proof($proofs, %proof) {
    push @$proofs, { kind => 'proof', %proof };
}

sub _push_violation($violations, %violation) {
    push @$violations, { kind => 'violation', %violation };
}

sub _domain_context($actor) {
    my $has_clock_domains = _actor_has_clock_domains($actor);
    my $default_domain = $has_clock_domains ? $actor->{clock_domains}{default} : 'default';
    my %declared_domains = _actor_declared_domain_names($actor, $default_domain);
    my %transaction_domains;
    my %transaction_ports;

    for my $tx (@{$actor->{transactions} || []}) {
        next unless ref($tx) eq 'HASH' && defined($tx->{name}) && !ref($tx->{name});
        $transaction_domains{$tx->{name}} = _domain_for_entry($tx, $default_domain);
        $transaction_ports{$tx->{name}} = _transaction_port_map($tx);
    }

    my %signal_domains = _actor_signal_domain_map($actor, $default_domain);
    my @activation_crossings;
    my %activation_crossing_by_key;
    for my $crossing (@{$actor->{crossings} || []}) {
        next unless ref($crossing) eq 'HASH' && ($crossing->{kind} // '') eq 'activation';
        my $child = $crossing->{child};
        my $src = $crossing->{from}{domain};
        my $dst = $crossing->{to}{domain};
        my $summary = {
            kind               => 'activation',
            child              => $child,
            source_domain      => $src,
            destination_domain => $dst,
            start_signal       => "${child}_start",
            done_signal        => "${child}_done",
            start_instance     => "${child}_activation_start_cdc",
            done_instance      => "${child}_activation_done_cdc",
            outstanding_policy => 'single_outstanding_acknowledged',
            payload            => 'none',
        };
        push @activation_crossings, $summary;
        $activation_crossing_by_key{_activation_crossing_key($child, $src, $dst)} = $summary
            if defined($child) && defined($src) && defined($dst);
    }

    return {
        kind => $has_clock_domains && @{$actor->{clock_domains}{domains} || []} > 1
            ? 'multi_domain'
            : 'single_domain',
        default_domain            => $default_domain,
        declared_domains          => [sort keys %declared_domains],
        declared_domain_map       => \%declared_domains,
        transaction_domains       => \%transaction_domains,
        transaction_ports         => \%transaction_ports,
        signal_domains            => \%signal_domains,
        activation_crossings      => \@activation_crossings,
        activation_crossing_by_key => \%activation_crossing_by_key,
    };
}

sub _public_domain_context($domain_context) {
    return {
        kind                 => $domain_context->{kind},
        default_domain       => $domain_context->{default_domain},
        declared_domains     => $domain_context->{declared_domains} || [],
        transaction_domains  => $domain_context->{transaction_domains} || {},
        activation_crossings => $domain_context->{activation_crossings} || [],
    };
}

sub _actor_has_clock_domains($actor) {
    return ref($actor->{clock_domains}) eq 'HASH'
        && ref($actor->{clock_domains}{domains}) eq 'ARRAY'
        && @{$actor->{clock_domains}{domains}};
}

sub _actor_declared_domain_names($actor, $default_domain) {
    if (_actor_has_clock_domains($actor)) {
        return map { $_->{name} => 1 } @{$actor->{clock_domains}{domains} || []};
    }

    my %domains = (defined($default_domain) ? ($default_domain => 1) : ());
    for my $entry (
        @{$actor->{interface}{inputs} || []},
        @{$actor->{interface}{outputs} || []},
        @{$actor->{storage} || []},
        @{$actor->{transactions} || []},
        @{$actor->{rules} || []},
        @{$actor->{library_uses} || []},
    ) {
        next unless ref($entry) eq 'HASH';
        my $domain = $entry->{domain};
        $domains{$domain} = 1
            if defined($domain) && !ref($domain) && length($domain);
    }
    for my $crossing (@{$actor->{crossings} || []}) {
        next unless ref($crossing) eq 'HASH';
        for my $endpoint (qw(from to)) {
            my $domain = $crossing->{$endpoint}{domain};
            $domains{$domain} = 1
                if defined($domain) && !ref($domain) && length($domain);
        }
    }
    return %domains;
}

sub _domain_for_entry($entry, $default_domain) {
    return ref($entry) eq 'HASH' && defined($entry->{domain})
        ? $entry->{domain}
        : $default_domain;
}

sub _actor_signal_domain_map($actor, $default_domain) {
    my %signals;
    for my $input (@{$actor->{interface}{inputs} || []}) {
        _register_signal_domain(\%signals, $input->{name}, _domain_for_entry($input, $default_domain), 'actor_input');
    }
    for my $output (@{$actor->{interface}{outputs} || []}) {
        _register_signal_domain(\%signals, $output->{name}, _domain_for_entry($output, $default_domain), 'actor_output');
    }
    for my $storage (@{$actor->{storage} || []}) {
        my $domain = _domain_for_entry($storage, $default_domain);
        _register_signal_domain(\%signals, $storage->{name}, $domain, 'actor_storage');
        for my $signal (@{$storage->{signals} || []}) {
            _register_signal_domain(\%signals, $signal->{name}, $domain, 'actor_storage');
        }
    }
    for my $crossing (@{$actor->{crossings} || []}) {
        next unless ref($crossing) eq 'HASH' && ($crossing->{kind} // '') eq 'event';
        _register_signal_domain(\%signals, $crossing->{from}{signal}, $crossing->{from}{domain}, 'crossing_request');
        _register_signal_domain(\%signals, $crossing->{ready}{signal}, $crossing->{from}{domain}, 'crossing_ready');
        _register_signal_domain(\%signals, $crossing->{to}{signal}, $crossing->{to}{domain}, 'crossing_pulse');
    }
    return %signals;
}

sub _register_signal_domain($signals, $name, $domain, $kind) {
    return unless defined($name) && !ref($name) && length($name);
    $signals->{$name} = {
        domain => $domain,
        kind   => $kind,
    };
}

sub _transaction_port_map($tx) {
    my %ports;
    for my $direction (qw(inputs outputs)) {
        my $role = $direction eq 'inputs' ? 'input' : 'output';
        for my $port (@{($tx->{ports} || {})->{$direction} || []}) {
            next unless ref($port) eq 'HASH' && defined($port->{name}) && !ref($port->{name});
            $ports{$port->{name}} = {
                direction => $role,
                width     => $port->{width},
            };
        }
    }
    return \%ports;
}

sub _activation_crossing_key($child, $src, $dst) {
    return join "\0", map { defined($_) ? $_ : '' } ($child, $src, $dst);
}

sub _activation_crossing_for($domain_context, $child, $src, $dst) {
    return undef unless ref($domain_context) eq 'HASH';
    return undef unless defined($child) && defined($src) && defined($dst);
    return $domain_context->{activation_crossing_by_key}{_activation_crossing_key($child, $src, $dst)};
}

sub _activation_domain_contract($ctx, $clause, $child, $activation) {
    my $domain_context = $ctx->{domain_context} || {};
    my $caller_domain = $ctx->{transaction_domain};
    my $child_domain = $domain_context->{transaction_domains}{$child};
    my $authored_domain = _domain_from_clause($clause);
    my $activation_domain = defined($authored_domain) ? $authored_domain : $caller_domain;
    my $relation = !defined($caller_domain) || !defined($child_domain)
        ? 'unknown_child_domain'
        : $caller_domain eq $child_domain
            ? 'same_domain'
            : 'cross_domain';
    my $activation_domain_relation = !defined($caller_domain) || !defined($activation_domain)
        ? 'unknown_activation_domain'
        : $caller_domain eq $activation_domain
            ? 'same_domain'
            : 'cross_domain';
    my $declared_domain_map = $domain_context->{declared_domain_map} || {};
    my $activation_domain_declared = defined($activation_domain) && $declared_domain_map->{$activation_domain} ? 1 : 0;
    my $authored_domain_declared = defined($authored_domain) && $declared_domain_map->{$authored_domain} ? 1 : 0;
    my $activation_crossing = _activation_crossing_for($domain_context, $child, $caller_domain, $child_domain);

    my $cdc_requirement = 'none';
    if ($relation eq 'cross_domain') {
        if (($activation // '') eq 'do') {
            $cdc_requirement = $activation_crossing
                ? 'activation_crossing_declared'
                : 'activation_crossing_required';
        } else {
            $cdc_requirement = 'unsupported_cross_domain_spawn';
        }
    }

    my @cdc_handoffs;
    if ($activation_crossing) {
        @cdc_handoffs = (
            {
                kind        => 'activation_start_cdc',
                from_domain => $activation_crossing->{source_domain},
                to_domain   => $activation_crossing->{destination_domain},
                signal      => $activation_crossing->{start_signal},
                instance    => $activation_crossing->{start_instance},
            },
            {
                kind        => 'activation_done_cdc',
                from_domain => $activation_crossing->{destination_domain},
                to_domain   => $activation_crossing->{source_domain},
                signal      => $activation_crossing->{done_signal},
                instance    => $activation_crossing->{done_instance},
            },
        );
    }

    return {
        caller_domain              => $caller_domain,
        child_domain               => $child_domain,
        authored_domain            => $authored_domain,
        authored_domain_declared   => $authored_domain_declared,
        activation_domain          => $activation_domain,
        activation_domain_declared => $activation_domain_declared,
        relation                   => $relation,
        activation_domain_relation => $activation_domain_relation,
        cdc_requirement            => $cdc_requirement,
        activation_crossing        => $activation_crossing ? { %$activation_crossing } : undef,
        cdc_handoffs               => \@cdc_handoffs,
    };
}

sub _binding_handoffs($ctx, $clause, $child, $activation, $instance) {
    my @bindings;
    return \@bindings unless ref($clause) eq 'ARRAY' && @$clause >= 3;

    my $child_ports = $ctx->{domain_context}{transaction_ports}{$child} || {};
    for my $subclause (@{$clause}[2 .. $#$clause]) {
        next unless _is_clause($subclause);
        next unless $subclause->[0] eq 'bind';
        for my $binding (@{$subclause}[1 .. $#$subclause]) {
            next unless ref($binding) eq 'ARRAY' && @$binding >= 3;
            my $role = _format_expr($binding->[0]);
            my $child_port = _format_expr($binding->[1]);
            my $actor_expr = _format_expr($binding->[2]);
            my $endpoint = _binding_actor_endpoint($ctx, $binding->[2]);
            my $child_port_info = $child_ports->{$child_port} || {};
            push @bindings, {
                role                           => $role,
                child_port                     => $child_port,
                child_port_direction           => $child_port_info->{direction},
                child_port_width               => $child_port_info->{width},
                actor_expr                     => $actor_expr,
                actor_endpoint_domain          => $endpoint->{domain},
                actor_endpoint_kind            => $endpoint->{kind},
                handoff_direction              => $role eq 'input' ? 'actor_to_child'
                    : $role eq 'output' ? 'child_to_actor'
                    : 'unknown',
                handoff_timing                 => $role eq 'input' ? 'activation_region'
                    : ($activation // '') eq 'do' ? 'done_guarded'
                    : 'generated_live_handoff',
                parent_port                    => defined($instance) ? "${instance}_${child_port}" : undef,
                requires_generated_top_handoff => defined($instance) ? 1 : 0,
            };
        }
    }
    return \@bindings;
}

sub _binding_actor_endpoint($ctx, $expr) {
    return {} if ref($expr);
    return {} unless defined($expr);
    my $signal_domains = $ctx->{domain_context}{signal_domains} || {};
    return exists($signal_domains->{$expr})
        ? $signal_domains->{$expr}
        : {};
}

sub _generated_top_requirements($activation, $generated_child, $instance, $start_signal, $done_signal, $bindings, $domain_contract) {
    my @requirements;
    if ($generated_child) {
        push @requirements, {
            kind         => 'start_done_handoff',
            activation   => $activation,
            instance     => $instance,
            start_signal => $start_signal,
            done_signal  => $done_signal,
        };
    }
    for my $binding (@{$bindings || []}) {
        next unless $binding->{requires_generated_top_handoff};
        push @requirements, {
            kind              => 'binding_handoff',
            activation        => $activation,
            instance          => $instance,
            role              => $binding->{role},
            child_port        => $binding->{child_port},
            parent_port       => $binding->{parent_port},
            handoff_direction => $binding->{handoff_direction},
            handoff_timing    => $binding->{handoff_timing},
        };
    }
    for my $handoff (@{($domain_contract || {})->{cdc_handoffs} || []}) {
        push @requirements, {
            kind        => $handoff->{kind},
            activation  => $activation,
            from_domain => $handoff->{from_domain},
            to_domain   => $handoff->{to_domain},
            signal      => $handoff->{signal},
            instance    => $handoff->{instance},
        };
    }
    return \@requirements;
}

sub _generated_child_targets($actor) {
    my %targets;
    for my $tx (@{$actor->{transactions} || []}) {
        _collect_generated_child_targets_from_clauses(\%targets, $tx->{clauses});
    }
    return %targets;
}

sub _collect_generated_child_targets_from_clauses($targets, $clauses) {
    return unless ref($clauses) eq 'ARRAY';
    for my $clause (@$clauses) {
        next unless _is_clause($clause);
        my $keyword = $clause->[0];
        if ($keyword eq 'spawn') {
            my $child = _format_expr($clause->[1]);
            $targets->{$child} = 1 if defined($child) && length($child);
            next;
        }
        if ($keyword eq 'do') {
            my $child = _format_expr($clause->[1]);
            $targets->{$child} = 1 if _has_subclause($clause, 'params')
                && defined($child) && length($child);
            next;
        }
        if ($keyword eq 'when' || $keyword eq 'while' || $keyword eq 'until' || $keyword eq 'repeat') {
            _collect_generated_child_targets_from_clauses($targets, [@{$clause}[2 .. $#$clause]]);
            next;
        }
        if ($keyword eq 'switch') {
            for my $branch (@{$clause}[2 .. $#$clause]) {
                next unless ref($branch) eq 'ARRAY';
                _collect_generated_child_targets_from_clauses($targets, [@{$branch}[1 .. $#$branch]]);
            }
            next;
        }
    }
}

sub _is_clause($value) {
    return ref($value) eq 'ARRAY'
        && @$value
        && defined($value->[0])
        && !ref($value->[0]);
}

sub _has_subclause($clause, $name) {
    return 0 unless ref($clause) eq 'ARRAY' && @$clause >= 3;
    for my $subclause (@{$clause}[2 .. $#$clause]) {
        next unless _is_clause($subclause);
        return 1 if $subclause->[0] eq $name;
    }
    return 0;
}

sub _domain_from_clause($clause) {
    return undef unless ref($clause) eq 'ARRAY' && @$clause >= 3;
    for my $subclause (@{$clause}[2 .. $#$clause]) {
        next unless _is_clause($subclause);
        next unless $subclause->[0] eq 'domain';
        return _format_expr($subclause->[1]);
    }
    return undef;
}

sub _spawn_instance_name($transaction, $clause) {
    return $clause->[3]
        if ref($clause) eq 'ARRAY'
        && defined($clause->[2])
        && !ref($clause->[2])
        && $clause->[2] eq 'as'
        && defined($clause->[3])
        && !ref($clause->[3])
        && length($clause->[3]);
    return "${transaction}_spawn";
}

sub _generated_do_instance_name($owner, $child, $ordinal) {
    return "${owner}_${child}_do_$ordinal";
}

sub _generated_repeat_do_instance_name($owner, $child, $ordinal) {
    return "${owner}_${child}_repeat_do_$ordinal";
}

sub _generated_conditional_do_instance_name($owner, $child, $ordinal) {
    return "${owner}_${child}_cond_do_$ordinal";
}

sub _format_expr($expr) {
    return undef unless defined $expr;
    return "$expr" unless ref($expr) eq 'ARRAY';
    return '(' . join(' ', map { defined($_) ? _format_expr($_) : 'undef' } @$expr) . ')';
}

1;
