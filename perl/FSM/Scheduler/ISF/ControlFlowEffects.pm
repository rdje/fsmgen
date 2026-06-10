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
    my @transactions = map {
        _inventory_transaction($_, \%generated_child_targets)
    } @{$actor->{transactions}};

    return {
        model                   => 'isf_control_flow_effects_v1',
        actor_name              => $actor->{actor_name},
        generated_child_targets => [sort keys %generated_child_targets],
        transactions            => \@transactions,
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

sub _inventory_transaction($tx, $generated_child_targets) {
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
        domain         => _domain_from_clause($clause),
        bindings       => _binding_summaries($clause),
    );
}

sub _record_spawn_effect($ctx, $region, $clause, $label) {
    my $child = _format_expr($clause->[1]);
    my $instance = _spawn_instance_name($ctx->{transaction}, $clause);
    my $done_port = "${instance}_done";

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
        domain          => _domain_from_clause($clause),
        bindings        => _binding_summaries($clause),
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
    my $backedge_count = 0;
    for my $region (@$regions) {
        $region_kinds{$region->{kind}}++;
        $backedge_count += scalar @{$region->{backedges} || []};
    }
    for my $effect (@$effects) {
        $effect_kinds{$effect->{kind}}++;
        $activation_kinds{$effect->{activation}}++ if defined $effect->{activation};
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
    };
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

sub _binding_summaries($clause) {
    my @bindings;
    return \@bindings unless ref($clause) eq 'ARRAY' && @$clause >= 3;
    for my $subclause (@{$clause}[2 .. $#$clause]) {
        next unless _is_clause($subclause);
        next unless $subclause->[0] eq 'bind';
        for my $binding (@{$subclause}[1 .. $#$subclause]) {
            next unless ref($binding) eq 'ARRAY' && @$binding >= 3;
            push @bindings, {
                role       => _format_expr($binding->[0]),
                child_port => _format_expr($binding->[1]),
                actor_expr => _format_expr($binding->[2]),
            };
        }
    }
    return \@bindings;
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
