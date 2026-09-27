package FSM::Scheduler::ISF::ChildStorageOwnership;

use v5.20;
use strict;
use warnings;
use Carp qw(confess);
use Exporter qw(import);
use Lispish;
use FSM::Adapter::ISF::LispishAdapter;
use FSM::Package::IntegerLiteralSupport;
use FSM::Support::HDLInstanceIdentifierPolicy;

our @EXPORT_OK = qw(prepare_child_storage_writes connect_child_storage_writes select_child_storage_reads connect_child_storage_reads);

# Inspect only emitted operands. Names of states, transactions, messages and
# provenance records are not signal reads. Lispish's public adapter recovers
# prefix-expression structure, so operator and state_active names stay distinct.
sub _references {
    my ($expr) = @_;
    return () unless defined $expr;
    if (ref($expr) eq 'HASH') {
        return map { _references($expr->{$_}) }
            grep { exists $expr->{$_} } qw(port signal expr value condition);
    }
    if (ref($expr) eq 'ARRAY') {
        return () if !@$expr || (!ref($expr->[0]) && $expr->[0] eq 'state_active');
        return map { _references($_) } @{$expr}[1 .. $#$expr];
    }
    confess "ISF child storage: unexpected operand representation\n" if ref($expr);
    if ($expr =~ /\(/) {
        # Keep the public multi-form result in scalar context, as the source
        # parser does; passing multi() as an argument changes its return shape.
        my $raw = Lispish::multi(\$expr);
        my $forms = FSM::Adapter::ISF::LispishAdapter->new->normalize_multi($raw);
        confess "ISF child storage: cannot inspect operand '$expr'\n" unless @$forms;
        return map { _references($_) } @$forms;
    }
    return () if defined FSM::Package::IntegerLiteralSupport->integer_from_scalar($expr)
        || $expr =~ /\A\s*(?:\d+'[sS]?[bBoOdDhH][0-9a-fA-F_xXzZ?]+|const_\d+b[01xXzZ_]+)\s*\z/;
    # Scalar suffix guards may contain comparisons. Member/slice/width suffixes
    # belong to their root signal; identifiers inside those suffixes do not.
    my @roots = $expr =~ /(?<![\w.'])\b([A-Za-z_]\w*)(?:\.[A-Za-z_]\w*)*(?:\[[\d:]+\])?(?:'\d+)?/g;
    return @roots;
}

sub _reserved_names {
    my ($ir) = @_;
    return { map { $_ => 1 } grep { defined $_ } (
        keys %{$ir->{signal_widths} || {}}, keys %{$ir->{counters} || {}},
        (map { $_->{name} } @{$ir->{ports}}, @{$ir->{constants} || []}, @{$ir->{params} || []}),
        (map { $_->{name} } @{$ir->{states} || []}, @{$ir->{dt_blocks} || []}),
        $ir->{clock}, (($ir->{reset} || {})->{name} // ()),
    ) };
}

sub _allocate_port {
    my ($ir, $reserved, $desired, $direction, $width, $type) = @_;
    my $name = FSM::Support::HDLInstanceIdentifierPolicy->allocate_generated_instance_identifier(
        desired => $desired, role => 'storage_write', reserved => $reserved,
    );
    push @{$ir->{ports}}, { name => $name, direction => $direction, width => $width, isf_handoff => 1 };
    $ir->{signal_widths}{$name} = $width;
    $ir->{signal_type_refs}{$name} = $type if defined $type;
    return $name;
}

# The child supplies a combinational write request during the original state.
# Only the owning module clocks the register; no data register or state is added.
sub prepare_child_storage_writes {
    my ($ir, $tx) = @_;
    my %local_ports = map { $_->{name} => 1 }
        map { @{($tx->{ports} || {})->{$_} || []} } qw(inputs outputs);
    my (%storage, %entries);
    for my $entry (@{$ir->{declared_storage} || []}) {
        for my $signal (@{$entry->{signals} || []}) {
            next if $local_ports{$signal->{name}};
            $storage{$signal->{name}} = $signal;
            $entries{$signal->{name}} = $entry;
        }
    }
    my $reserved = _reserved_names($ir);
    my %writes;
    for my $block (@{$ir->{states} || []}, @{$ir->{dt_blocks} || []}) {
        my @assignments;
        for my $assignment (@{$block->{assignments} || []}) {
            my @targets = grep { exists $storage{$_} } _references($assignment->{lhs});
            if (!@targets) { push @assignments, $assignment; next; }
            my $name = $targets[0];
            my $signal = $storage{$name};
            my $entry = $entries{$name};
            confess "Transaction '$tx->{name}': generated child writes actor-owned storage '$name'; only full-width variable sequential writes are qualified\n"
                unless @targets == 1 && $assignment->{lhs} eq $name
                    && ($assignment->{op} // '') eq '<-'
                    && ($entry->{kind} // '') eq 'var'
                    && (!exists($signal->{type_spec})
                        || ($signal->{type_spec}{kind} // '') =~ /\A(?:bits|record|list)\z/);
            if (!exists $writes{$name}) {
                $writes{$name} = {
                    %$signal,
                    data_port => _allocate_port($ir, $reserved, "isf_write_${name}_data", 'output', $signal->{width}, $signal->{type}),
                    enable_port => _allocate_port($ir, $reserved, "isf_write_${name}_enable", 'output', 1, undef),
                };
            }
            push @assignments,
                { %$assignment, lhs => $writes{$name}{data_port}, op => '=', source_kind => 'actor_storage_write_data' },
                { %$assignment, lhs => $writes{$name}{enable_port}, rhs => 1, op => '=', source_kind => 'actor_storage_write_enable' };
        }
        $block->{assignments} = \@assignments;
    }
    $ir->{actor_storage_writes} = [map { $writes{$_} } sort keys %writes];
}

sub connect_child_storage_writes {
    my ($parent, $children) = @_;
    my %writers;
    for my $instance (@{$parent->{spawn_instances} || []}) {
        my $child = $children->{$instance->{child}} || next;
        for my $write (@{$child->{actor_storage_writes} || []}) {
            my $name = $write->{name};
            confess "Actor storage '$name' has competing generated child writers '$writers{$name}{instance}' and '$instance->{instance}'; arbitration is not yet qualified\n"
                if exists $writers{$name};
            $writers{$name} = { instance => $instance->{instance}, write => $write };
        }
    }
    for my $block (@{$parent->{states} || []}, @{$parent->{dt_blocks} || []}) {
        my @targets = (@{$block->{fields} || []},
            map { _references($_->{lhs}) } @{$block->{assignments} || []});
        for my $name (@targets) {
            confess "Actor storage '$name' has a parent writer and generated child writer '$writers{$name}{instance}'; arbitration is not yet qualified\n"
                if exists $writers{$name};
        }
    }
    my $reserved = _reserved_names($parent);
    for my $instance (@{$parent->{spawn_instances} || []}) {
        my $child = $children->{$instance->{child}} || next;
        my @links;
        for my $write (@{$child->{actor_storage_writes} || []}) {
            my $name = $write->{name};
            my $prefix = "isf_write_$instance->{instance}_$name";
            my $data = _allocate_port($parent, $reserved, "${prefix}_data", 'input', $write->{width}, $write->{type});
            my $enable = _allocate_port($parent, $reserved, "${prefix}_enable", 'input', 1, undef);
            push @links,
                { child_port => $write->{data_port}, parent_port => $data },
                { child_port => $write->{enable_port}, parent_port => $enable };
            push @{$parent->{dt_blocks}}, {
                name => $enable, kind => 'actor_storage_write_handoff',
                assignments => [{ lhs => $name, rhs => $data, op => '<-', guard => { port => $enable },
                    source_kind => 'actor_storage_write_handoff' }],
            };
        }
        $instance->{actor_storage_writes} = \@links if @links;
    }
    return scalar keys %writers;
}

sub select_child_storage_reads {
    my ($ir, $tx, $actor) = @_;
    my %local_ports = map { $_->{name} => 1 }
        map { @{($tx->{ports} || {})->{$_} || []} } qw(inputs outputs);
    my %storage = map { $_->{name} => $_ }
        map { @{$_->{signals} || []} } @{$ir->{declared_storage} || []};
    delete @storage{keys %local_ports};
    my (%reads, %writes);
    for my $block (@{$ir->{states} || []}, @{$ir->{dt_blocks} || []}) {
        for my $assignment (@{$block->{assignments} || []}) {
            $writes{$_} = 1 for grep { exists $storage{$_} } _references($assignment->{lhs});
            $reads{$_} = 1 for
                (_references($assignment->{rhs}), _references($assignment->{guard}));
        }
        $writes{$_} = 1 for grep { exists $storage{$_} } @{$block->{fields} || []};
        for my $key (qw(guard dte_guard condition signal word counter)) {
            $reads{$_} = 1 for _references($block->{$key});
        }
        for my $transition (@{$block->{transitions} || []}) {
            $reads{$_} = 1 for _references($transition->{condition});
        }
        for my $branch (@{$block->{branches} || []}) {
            $reads{$_} = 1 for _references($branch->{value});
        }
        $reads{$_} = 1 for @{$block->{done_ports} || []};
    }
    for my $assertion (@{$ir->{immediate_assertions} || []}) {
        $reads{$_} = 1 for _references($assertion->{condition});
    }
    confess "Transaction '$tx->{name}': generated child writes actor-owned storage '"
        . join("', '", sort keys %writes)
        . "'; shared write handoffs are not yet supported; use explicit transaction ports or transaction-local storage\n"
        if %writes;

    # All actor storage remains in the owner, including declarations this child
    # never references. Transaction-local storage and explicit ports stay local.
    for my $entry (@{$ir->{declared_storage} || []}) {
        for my $signal (@{$entry->{signals} || []}) {
            my $name = $signal->{name};
            delete $ir->{reset_values}{$name};
            delete $ir->{storage_roles}{$name};
            delete $ir->{signal_widths}{$name} unless $local_ports{$name};
            delete $ir->{signal_type_refs}{$name} unless $local_ports{$name} || $reads{$name};
        }
    }
    $ir->{declared_storage} = [];
    # Actor inputs are inherited conveniences, not authored transaction ports.
    # Keep only inherited inputs actually read, while retaining explicit local
    # port declarations and the mandatory start handshake even when unused.
    my %actor_inputs = map { $_->{name} => 1 } @{$actor->{interface}{inputs} || []};
    $ir->{ports} = [grep {
        $_->{direction} ne 'input' || $_->{name} eq 'start'
            || !$actor_inputs{$_->{name}} || $local_ports{$_->{name}} || $reads{$_->{name}}
    } @{$ir->{ports}}];
    $ir->{actor_storage_reads} = [
        map { { %{$storage{$_}} } } sort grep { exists $storage{$_} } keys %reads
    ];
    for my $signal (@{$ir->{actor_storage_reads}}) {
        my $name = $signal->{name};
        confess "Transaction '$tx->{name}': actor storage read '$name' conflicts with a child port\n"
            if grep { $_->{name} eq $name } @{$ir->{ports}};
        push @{$ir->{ports}}, { name => $name, direction => 'input', width => $signal->{width}, isf_handoff => 1 };
        $ir->{signal_widths}{$name} = $signal->{width};
    }
}

sub connect_child_storage_reads {
    my ($parent, $children) = @_;
    my %reserved = map { $_ => 1 } grep { defined $_ } (
        keys %{$parent->{signal_widths} || {}}, keys %{$parent->{counters} || {}},
        (map { $_->{name} } @{$parent->{ports}}, @{$parent->{constants} || []}, @{$parent->{params} || []}),
        $parent->{clock}, (($parent->{reset} || {})->{name} // ()),
    );
    my %handoffs;
    for my $spawn (@{$parent->{spawn_instances} || []}) {
        my $child = $children->{$spawn->{child}} || next;
        my @links;
        for my $signal (@{$child->{actor_storage_reads} || []}) {
            my $name = $signal->{name};
            if (!exists $handoffs{$name}) {
                my $port = FSM::Support::HDLInstanceIdentifierPolicy->allocate_generated_instance_identifier(
                    desired => "isf_storage_read_$name", role => 'storage_read', reserved => \%reserved,
                );
                $handoffs{$name} = $port;
                push @{$parent->{ports}}, { name => $port, direction => 'output', width => $signal->{width}, isf_handoff => 1 };
                $parent->{signal_type_refs}{$port} = $signal->{type} if defined $signal->{type};
                push @{$parent->{dt_blocks}}, {
                    name => $port, kind => 'actor_storage_read_handoff',
                    assignments => [{ lhs => $port, rhs => $name, op => '=', source_kind => 'actor_storage_read_handoff' }],
                };
            }
            push @links, { parent_port => $handoffs{$name}, child_port => $name };
        }
        $spawn->{actor_storage_reads} = \@links if @links;
    }
    return scalar keys %handoffs;
}

1;
