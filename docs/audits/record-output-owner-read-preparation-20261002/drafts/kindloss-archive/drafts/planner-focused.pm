package FSM::Scheduler::ISF::ChildOutputReads;

use strict;
use warnings;
use Carp qw(confess);
use Storable qw(dclone);
use Scalar::Util qw(refaddr);
use Lispish;
use FSM::Adapter::ISF::LispishAdapter;
use FSM::Package::IntegerLiteralSupport;
use FSM::Package::AggregatePathSupport;
use FSM::Support::HDLInstanceIdentifierPolicy;
use FSM::Support::ISFInterfacePortMetadata qw(capture_interface_port_metadata);

# Detached preparation only. The actual child must already carry its canonical
# start/history handshake. No parent connection or public admission follows.
sub plan {
    my ($class, %args) = @_;
    _require(keys(%args) == 4 && ref($args{actor}) eq 'HASH'
        && ref($args{transaction}) eq 'HASH' && ref($args{ir}) eq 'HASH'
        && ref($args{lowering}), 'requires source actor/transaction, child IR and lowering');
    my ($source_actor, $source_tx, $source) = @args{qw(actor transaction ir)};
    my @indices = grep {refaddr($source_actor->{transactions}[$_]) == refaddr($source_tx)}
        0 .. $#{$source_actor->{transactions} || []};
    _require(@indices == 1, 'requires an actual source transaction');
    my $actor = dclone($source_actor);
    my $tx = $actor->{transactions}[$indices[0]];
    my $scope = $args{lowering}->child_output_read_scope($actor, $tx);
    capture_interface_port_metadata($actor->{interface});
    my $ir = dclone($source);
    _require(!exists($ir->{actor_output_reads}), 'cannot prepare an already prepared child');
    _handshake($ir, $tx);
    my (%outputs, %reserved, %writers, %handshake_writers, %reads);
    for my $port (@{$actor->{interface}{outputs} || []}) {
        _require(!exists $outputs{$port->{name}}, 'requires unique source output names');
        $outputs{$port->{name}} = $port;
    }
    $reserved{$_} = 1 for keys %{$ir->{signal_widths} || {}},
        keys %{$ir->{signal_type_refs} || {}}, keys %{$ir->{counters} || {}},
        keys %{$scope->{locals}}, keys %{$scope->{static_symbols}}, keys %outputs,
        @{$ir->{explicit_internal_signals} || []};
    $reserved{$_->{name}} = 1 for @{$ir->{ports}}, @{$ir->{states}}, @{$ir->{dt_blocks}},
        @{$ir->{constants} || []}, @{$ir->{params} || []};
    $reserved{$ir->{clock}} = 1;
    $reserved{$ir->{reset}{name}} = 1 if $ir->{reset};
    for my $block (@{$ir->{states}}, @{$ir->{dt_blocks}}) {
        for my $assignment (@{$block->{assignments} || []}) {
            my ($root) = ($assignment->{lhs} // '') =~ /\A([A-Za-z_]\w*)/;
            $writers{$root} = 1 if defined $root;
            $handshake_writers{$root} = 1 if defined($root) && ($root eq 'start' || $root eq 'done')
                && ($assignment->{source_kind} // '') !~ /\A(?:complete_pulse|activation_completion_pulse)\z/;
        }
    }
    my $resolve = sub {
        my ($token) = @_;
        return $token if $scope->{static_symbols}{$token};
        my ($root, $path, $suffix) = $token =~ /\A([A-Za-z_]\w*)((?:\.[A-Za-z_]\w*|\[\d+(?::\d+)?\])*)((?:'\d+)?[>]?)\z/;
        return $token unless defined($root) && exists($outputs{$root})
            && !$scope->{locals}{$root} && !$scope->{static_symbols}{$root};
        my $port = $outputs{$root};
        _require(($ir->{signal_type_refs}{$root} // '') eq ($port->{type} // ''),
            "output '$root' disagrees with inherited child type");
        if (length $path) {
            my $spec = $port->{type_spec} || {kind => 'bits', width => $port->{width} // 1, signed => 0};
            my $resolved;
            if ($spec->{kind} eq 'record' || $spec->{kind} eq 'list') {
                $resolved = FSM::Package::AggregatePathSupport->resolve(root_type_spec => $spec, path_text => $path);
            } else {
                # The canonical aggregate walker also checks scalar slices
                # when reached through an aggregate member.
                $resolved = FSM::Package::AggregatePathSupport->resolve(
                    root_type_spec => {kind => 'record', members => {value => $spec}, member_order => ['value']},
                    path_text => ".value$path");
            }
            _require($resolved->{ok}, "output '$root' has invalid read path '$path'");
        }
        if (!exists $reads{$root}) {
            my $alias = FSM::Support::HDLInstanceIdentifierPolicy->allocate_generated_instance_identifier(
                desired => "isf_output_read_$root", role => 'output_read', reserved => \%reserved);
            $reads{$root} = {name => $root, input_port => $alias, width => $port->{width} // 1};
            $reads{$root}{$_} = dclone($port->{$_}) for grep {exists $port->{$_} && ref($port->{$_})} qw(type_spec);
            $reads{$root}{type} = $port->{type} if exists $port->{type};
        }
        return "$reads{$root}{input_port}$path$suffix";
    };
    _slots($ir, sub {my ($container, $key) = @_; $container->{$key} = _operand($container->{$key}, $resolve)});
    for my $name (sort keys %reads) {
        my $read = $reads{$name};
        my $alias = $read->{input_port};
        push @{$ir->{ports}}, {name => $alias, direction => 'input', width => $read->{width}, isf_handoff => 1};
        $ir->{signal_widths}{$alias} = $read->{width};
        $ir->{signal_type_refs}{$alias} = $read->{type} if exists $read->{type};
    }
    for my $name (keys %outputs) {
        next if $scope->{locals}{$name} || $scope->{static_symbols}{$name};
        # Inherited owner facts must not type/reset even an unused handshake.
        # Ordinary data writers keep their separately gated original declarations.
        _require(!$handshake_writers{$name}, "output '$name' writer collides with child handshake");
        next if $writers{$name} && $name ne 'start' && $name ne 'done';
        delete $ir->{$_}{$name} for qw(signal_type_refs reset_values storage_roles);
    }
    $ir->{actor_output_reads} = [map {$reads{$_}} sort keys %reads];
    $ir->{explicit_interface_ports} = [map {{%$_}} @{$ir->{ports}}];
    return $ir;
}

sub _handshake {
    my ($ir, $tx) = @_;
    for my $pair ([start => 'input'], [done => 'output']) {
        my @ports = grep {($_->{name} // '') eq $pair->[0]} @{$ir->{ports} || []};
        _require(@ports == 1 && $ports[0]{direction} eq $pair->[1] && $ports[0]{width} == 1,
            'requires canonical one-bit child handshake ports');
    }
    my @entry = grep {($_->{kind} // '') eq 'entry'} @{$ir->{states} || []};
    my @activation = grep {($_->{kind} // '') eq 'child_activation'} @{$ir->{dt_blocks} || []};
    _require(@entry == 1 && @activation == 1 && $entry[0]{transaction} eq $tx->{name},
        'requires actual transaction entry and activation history');
    my $name = $activation[0]{name};
    my $assignments = $activation[0]{assignments};
    _require(($ir->{storage_roles}{$name} // '') eq 'child_start_history'
        && ($ir->{counters}{$name} // 0) == 1 && ($ir->{reset_values}{$name} // -1) == 0
        && @$assignments == 1 && $assignments->[0]{lhs} eq $name
        && $assignments->[0]{rhs} eq 'start' && $assignments->[0]{op} eq '<-'
        && ($entry[0]{guard}{expr} // '') eq "(& start (! $name))",
        'requires canonical generated handshake history');
    for my $transition (@{$entry[0]{transitions}}) {
        _require(($transition->{condition}{expr} // '') eq $entry[0]{guard}{expr},
            'requires canonical entry handshake transitions');
    }
}

sub _operand {
    my ($value, $resolve) = @_;
    return $value unless defined $value;
    if (ref($value) eq 'ARRAY') {
        return $value if !@$value || $value->[0] eq 'state_active' || $value->[0] eq 'at';
        return [$value->[0], map {_operand($_, $resolve)} @{$value}[1 .. $#$value]];
    }
    _require(!ref($value), 'unexpected emitted operand representation');
    return $value if defined FSM::Package::IntegerLiteralSupport->integer_from_scalar($value)
        || $value =~ /\A(?:\d+'[sS]?[bBoOdDhH][0-9a-fA-F_xXzZ?]+|const_\d+b[01xXzZ_]+)\z/;
    if ($value =~ /\(/) {
        my $raw = Lispish::multi(\$value);
        my $forms = FSM::Adapter::ISF::LispishAdapter->new->normalize_multi($raw);
        _require(@$forms == 1, 'requires one emitted operand expression');
        my $rewritten = _operand($forms->[0], $resolve);
        return $value if _render($rewritten) eq _render($forms->[0]);
        return _render($rewritten);
    }
    $value =~ s/(?<![\w.'])\b([A-Za-z_]\w*(?:\.[A-Za-z_]\w*|\[\d+(?::\d+)?\])*(?:'\d+)?[>]?)/$resolve->($1)/ge;
    return $value;
}
sub _render {return ref($_[0]) eq 'ARRAY' ? '(' . join(' ', map {_render($_)} @{$_[0]}) . ')' : $_[0]}
sub _present {return defined($_[0]) && !ref($_[0]) && length($_[0])}
sub _guard {
    my ($guard, $visit) = @_;
    return unless ref($guard) eq 'HASH';
    return if defined($guard->{port}) && $guard->{port} eq '1';
    if (_present($guard->{port}) && !$guard->{op}) {$visit->($guard, 'port')}
    elsif (_present($guard->{signal}) && $guard->{op}) {$visit->($guard, $_) for qw(signal value)}
    elsif (_present($guard->{expr})) {$visit->($guard, 'expr')}
}
sub _simple {
    my ($transition, $visit) = @_;
    my $c = $transition->{condition};
    return unless ref($c) eq 'HASH';
    if (_present($c->{port})) {$visit->($c, 'port')}
    elsif (_present($c->{expr})) {$visit->($c, 'expr')}
    elsif (_present($c->{signal})) {$visit->($c, $_) for qw(signal value)}
}

# Match Emitter::FSM precedence: losing guard fields and materialized branch
# selectors are not emitted reads. Names, diagnostic strings and metadata stay
# outside this walk. This visitor is not a generic recursive IR search.
sub _slots {
    my ($ir, $visit) = @_;
    for my $a (@{$ir->{immediate_assertions} || []}) {$visit->($a, 'condition')}
    for my $dt (@{$ir->{dt_blocks}}) {
        next if $dt->{kind} eq 'child_activation';
        _guard($dt->{dte_guard}, $visit);
        for my $a (@{$dt->{assignments}}) {
            $visit->($a, 'rhs');
            if ($dt->{kind} eq 'rule' && _present(($a->{guard} || {})->{port}) && $a->{guard}{port} ne '1') {
                $visit->($a->{guard}, 'port');
            } else {_guard($a->{guard}, $visit)}
        }
    }
    for my $s (@{$ir->{states}}) {
        for my $a (@{$s->{assignments}}) {
            next if $a->{op} eq '--';
            $visit->($a, 'rhs'); _guard($a->{guard}, $visit);
        }
        $visit->($s, 'word') if $s->{fields};
        next if $s->{kind} eq 'entry';
        my $kind = $s->{kind};
        my $ts = $s->{transitions};
        if ($kind eq 'repeat_check') {
            my @counter = grep {($_->{condition} || {})->{signal}
                && $_->{condition}{signal} eq $s->{counter}} @$ts;
            $visit->($s, 'counter') if @counter;
            _simple($_, $visit) for grep {!(($_->{condition} || {})->{signal}
                && $_->{condition}{signal} eq $s->{counter})} @$ts;
        } elsif ($kind eq 'await') {
            for my $t (@$ts) {
                my $c = $t->{condition};
                if ($c->{port} && !$c->{op}) {$visit->($c, 'port')}
                elsif ($c->{expr}) {_simple($t, $visit)}
                elsif ($c->{signal}) {$visit->($c, 'signal')}
            }
        } elsif (($kind eq 'sync_all' || $kind eq 'sync_any') && !(grep {$_->{condition}} @$ts)) {
            my $key = exists($s->{completion_ports}) && defined($s->{completion_ports}) ? 'completion_ports' : 'done_ports';
            for my $i (0 .. $#{$s->{$key}}) {
                my $slot = {value => $s->{$key}[$i]}; $visit->($slot, 'value'); $s->{$key}[$i] = $slot->{value};
            }
        } elsif ($kind eq 'switch' && !$s->{switch_transitions_materialized}) {
            $visit->($s, 'signal');
            $visit->($_, 'value') for grep {($_->{value} // '') ne 'default' && ($_->{value} // '') ne '_'} @{$s->{branches}};
        } elsif ($kind eq 'branch' && !(grep {$_->{condition}} @$ts)) {
            $visit->($s, 'condition');
        } elsif ($kind =~ /\Aloop_(?:while|until|exit_when)\z/ && !$s->{loop_transitions_materialized}) {
            $visit->($s, 'condition');
        } else {_simple($_, $visit) for @$ts}
    }
}
sub _require {confess "Invalid child output-read preparation: $_[1]\n" unless $_[0]}
1;
